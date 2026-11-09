use strict;
use warnings;
use Test::More;

# LIVE (karr k55): every connection of the native storage reads dates and
# timestamps in the ISO formats, without anybody asking for it.
#
# WHY: DBD::Firebird hands a TIMESTAMP back in the locale's %c format unless
# ib_time_all is 'ISO', and the driver's DateTime parser, the ORM and every
# string comparison of a user expect ISO. It used to be a connect_call
# (datetime_setup) each user had to know to ask for: without it a timestamp
# read as "Mon Oct 19 04:43:18 2026", silently. Now the storage sets it on each
# connection; datetime_setup stays and does the same (idempotent), so a
# connect_info that still asks for it is unchanged.
#
# NO on_connect_call => 'datetime_setup' anywhere below, on purpose.
#
# WARNING: creates and drops the table "k55_stamp".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live datetime test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Deploy;

{
  package K55Stamp::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('Firebird');

  package K55Stamp::Schema::Result::Stamp;
  use DBIO 'Core';
  __PACKAGE__->table('k55_stamp');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    at => { data_type => 'timestamp', is_nullable => 1 },
    d  => { data_type => 'date', is_nullable => 1 },
    t  => { data_type => 'time', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package main;
  K55Stamp::Schema->register_class(Stamp => 'K55Stamp::Schema::Result::Stamp');
}

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my %attrs = (quote_names => 1, on_connect_call => 'use_softcommit');
my $schema = K55Stamp::Schema->connect($dsn, $user, $pass, { %attrs });
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach Firebird server: $@";

# the handle is asked for each time: the test reconnects in between
sub cleanup { eval { $schema->storage->dbh->do('DROP TABLE "k55_stamp"') } }
cleanup();

ok eval { DBIO::Firebird::Deploy->new(schema => $schema)->install; 1 },
  'install' or diag $@;

my $rs = $schema->resultset('Stamp');
ok eval {
  $rs->create({ id => 1, at => '2026-10-19 04:43:18', d => '2026-10-19', t => '04:43:18' });
  1;
}, 'create with ISO values' or diag $@;

my $row = $rs->find(1);
like $row->at, qr/\A2026-10-19 04:43:18/, 'timestamp reads back as YYYY-MM-DD HH:MM:SS, not in the locale format';
is $row->d, '2026-10-19', 'date reads back as YYYY-MM-DD';
like $row->t, qr/\A04:43:18/, 'time reads back as HH:MM:SS';

# the same with the connect call asked for: idempotent
my $again = K55Stamp::Schema->connect($dsn, $user, $pass,
  { %attrs, on_connect_call => [ 'use_softcommit', 'datetime_setup' ] });
like $again->resultset('Stamp')->find(1)->at, qr/\A2026-10-19 04:43:18/,
  'with datetime_setup asked for as well, the format is the same';
$again->storage->disconnect;

# a reconnect is configured like the first connection
$schema->storage->disconnect;
like $schema->resultset('Stamp')->find(1)->at, qr/\A2026-10-19 04:43:18/,
  'after a reconnect the format is the same';

cleanup();
$schema->storage->disconnect;
done_testing;
