use strict;
use warnings;
use Test::More;

# t/37-deployment-statements.t — the wiring between the DDL layer and the
# storage: DBIO::ClickHouse::Storage::deployment_statements.
#
# Offline: no DBD, no DSN, no server. Nothing here connects — the storage is
# instantiated bare and told the driver is already determined (same trick as
# t/12-txn.t), because core wraps deployment_statements in a
# "determine the driver first" guard that would otherwise want a handle.
#
# Two things this pins down:
#
#   1. A schema with the ClickHouse component loaded deploys the DDL layer's
#      output — the same string install_ddl produces, ENGINE and sorting key
#      included. This is the SQL-inspection entry point ($schema->deployment_
#      statements); $schema->deploy takes the dbio_deploy_class route instead
#      (t/39-deploy-class.t) and renders the same DDL there.
#   2. A schema WITHOUT the component throws, and throws something that says
#      what to do about it. It must never fall through to the generic path:
#      sqlt_type is the DBD driver name, which is MariaDB/mysql over the
#      ClickHouse wire protocol, so the generic path deploys MySQL DDL —
#      InnoDB, FOREIGN KEY, AUTO_INCREMENT — at a server that rejects all
#      three. A silent wrong deploy is worse than a loud refusal.

use DBIO::ClickHouse::Storage;
use DBIO::ClickHouse::DDL;

{
  package My::CH::Deploy::Result::Artist;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uuid',    is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 255, is_nullable => 0 }
  );
  __PACKAGE__->set_primary_key('id');
}

# Schema WITH the component: gains clickhouse_install_ddl.
{
  package My::CH::Deploy::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';

  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->register_class(Artist => 'My::CH::Deploy::Result::Artist');
}

# Schema WITHOUT it: a plain DBIO::Schema, exactly what a user gets when they
# forget load_components('ClickHouse') / the -ch shortcut.
{
  package My::CH::Deploy::PlainSchema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';

  __PACKAGE__->register_class(Artist => 'My::CH::Deploy::Result::Artist');
}

my $storage = DBIO::ClickHouse::Storage->new;
$storage->_driver_determined(1);

# --- the component is what provides the method ------------------------------
can_ok 'My::CH::Deploy::Schema', 'clickhouse_install_ddl';
ok !My::CH::Deploy::PlainSchema->can('clickhouse_install_ddl'),
  'a schema without the ClickHouse component has no clickhouse_install_ddl';

# --- with the component: deployment_statements IS the DDL layer -------------
my $ddl = $storage->deployment_statements('My::CH::Deploy::Schema');
ok length $ddl, 'deployment_statements returns DDL for a ClickHouse schema';

like $ddl, qr/^ENGINE = MergeTree$/m,
  'the table carries an explicit ENGINE = MergeTree — ClickHouse has no default';
like $ddl, qr/^ORDER BY /m,
  '... and an explicit sorting key';
like $ddl, qr/^CREATE TABLE `artist` \(/m,
  '... with backtick-quoted identifiers';

is $ddl, DBIO::ClickHouse::DDL->install_ddl('My::CH::Deploy::Schema'),
  'deployment_statements returns exactly what DBIO::ClickHouse::DDL renders';
is $ddl, My::CH::Deploy::Schema->clickhouse_install_ddl,
  '... routed through the component method, not a private copy of the logic';

# The MySQL producer would emit all three of these. None may appear.
unlike $ddl, qr/AUTO_INCREMENT/i, 'no AUTO_INCREMENT — this is not the MySQL path';
unlike $ddl, qr/InnoDB/i,         'no InnoDB engine';
unlike $ddl, qr/FOREIGN\s+KEY/i,  'no FOREIGN KEY';

# --- without the component: a loud, actionable refusal ----------------------
my $sql = eval { $storage->deployment_statements('My::CH::Deploy::PlainSchema') };
my $err = $@;

ok !defined $sql, 'deployment_statements produces no SQL without the component';
ok $err, '... it throws instead of silently falling back';
isa_ok $err, 'DBIO::Exception';

like $err, qr/clickhouse_install_ddl/,
  'the exception names the missing method';
like $err, qr/My::CH::Deploy::PlainSchema/,
  '... and the schema class that is missing it';
like $err, qr/load_components\('ClickHouse'\)/,
  '... and tells the user to load the component';
like $err, qr/-ch/,
  '... or to use the -ch shortcut';
like $err, qr/sqlt_type/,
  '... and explains why there is no fallback: sqlt_type is the DBD name';

# Whatever the generic DBIO::Storage::DBI path would have done, we did not do
# it — neither its DDL-file lookup nor its own error.
unlike $err, qr/pre-existing DDL file/,
  'the refusal is ours, not core generic deployment_statements falling through';

done_testing;
