use strict;
use warnings;
use Test::More;

# t/39-deploy-class.t — where $schema->deploy actually goes.
#
# Offline: no DBD, no DSN, no server. The storage is a subclass of the real
# DBIO::ClickHouse::Storage with exactly two things stubbed — ensure_connected
# (nothing to connect to) and dbh (a recorder) — so everything core routes on
# is the driver's own.
#
# What this file is really about is a failure mode, not a string. Core's
# DBIO::Schema::deploy asks the storage for dbio_deploy_class and runs
# $class->new(schema => $schema)->install when it gets an answer. When it gets
# none it falls through to DBIO::Storage::DBI::deploy, whose statement loop
# catches the error of every failed statement, carps it as a warning and
# carries on with the next one — then returns success. A ClickHouse CREATE
# TABLE that the server rejects (bad type, unusable sorting key) is a perfectly
# ordinary event, and under that loop the user is handed a true return value
# over a half-created schema.
#
# So the assertions below are about routing and about consequences:
#
#   1. the class core would construct really is constructible the way core
#      constructs it — new(schema => $schema), then install with no arguments;
#   2. $schema->deploy runs the ClickHouse DDL through DBIO::ClickHouse::Deploy
#      and never enters DBIO::Storage::DBI::deploy;
#   3. a statement that fails aborts the deploy — it propagates, the statements
#      behind it do not run, and nothing is downgraded to a warning.
#
# (3) is the one that cannot pass by accident: under core's fallback loop the
# deploy would survive the failure, run the rest and report success. Delete the
# dbio_deploy_class declaration from DBIO::ClickHouse::Storage and this file
# fails on the routing, on the statement trail and on the swallowed error.

use DBIO::ClickHouse::Storage;
use DBIO::ClickHouse::Deploy;
use DBIO::ClickHouse::DDL;
use DBIO::Storage::DBI ();

# Three tables, so "the deploy stopped" and "the deploy carried on" are
# distinguishable: a failure on the second statement must leave the third
# unexecuted.
{
  package My::CH::Route::Result::Artist;
  use strict;
  use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('a_artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uuid',    is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 255, is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package My::CH::Route::Result::Event;
  use strict;
  use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('b_event');
  __PACKAGE__->add_columns(
    id => { data_type => 'uuid',     is_auto_increment => 1, is_nullable => 0 },
    ts => { data_type => 'datetime', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package My::CH::Route::Result::Venue;
  use strict;
  use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('c_venue');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uuid',    is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 255, is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package My::CH::Route::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->register_class(Artist => 'My::CH::Route::Result::Artist');
  __PACKAGE__->register_class(Event  => 'My::CH::Route::Result::Event');
  __PACKAGE__->register_class(Venue  => 'My::CH::Route::Result::Venue');
}

# Records every statement it is handed, and can be told to refuse the Nth one
# the way a server refuses DDL it cannot execute.
{
  package My::CH::Route::FakeDbh;
  sub new { my ($class, %args) = @_; bless { stmts => [], %args }, $class }
  sub stmts { $_[0]->{stmts} }
  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{stmts} }, $sql;
    die "fake dbh refused statement $self->{fail_on}\n"
      if ($self->{fail_on} || 0) == @{ $self->{stmts} };
    return 1;
  }
}

# The real driver storage, offline. dbio_deploy_class is inherited, not
# redeclared — this subclass must not be able to answer for the driver.
{
  package My::CH::Route::Storage;
  use strict;
  use warnings;
  our @ISA = ('DBIO::ClickHouse::Storage');
  sub ensure_connected { 1 }
  sub dbh      { $_[0]->{fake_dbh} }
  sub _get_dbh { $_[0]->{fake_dbh} }
  sub fake_dbh { @_ > 1 ? ($_[0]{fake_dbh} = $_[1]) : $_[0]{fake_dbh} }
}

sub fresh_schema {
  my (%args) = @_;
  my $storage = My::CH::Route::Storage->new;
  $storage->_driver_determined(1);
  $storage->fake_dbh(My::CH::Route::FakeDbh->new(%args));
  my $schema = My::CH::Route::Schema->clone;
  $schema->storage($storage);
  return $schema;
}

# --- 1. the constructor call core makes --------------------------------------
# DBIO::Schema::deploy does exactly this: new(schema => $schema), then install
# with no further arguments. The Deploy class was written for the
# install/diff/apply/upgrade entry points, so this pins the one shape core uses.

# Probed the way core probes it, and never called blind: with the declaration
# gone this file must still reach the routing assertions below and fail THERE,
# rather than dying here on a missing method.
my $declared = DBIO::ClickHouse::Storage->can('dbio_deploy_class');
ok $declared, 'DBIO::ClickHouse::Storage answers can(dbio_deploy_class) -- core probes exactly that';
is(($declared ? DBIO::ClickHouse::Storage->dbio_deploy_class : undef),
  'DBIO::ClickHouse::Deploy',
  '... and names DBIO::ClickHouse::Deploy as its native deploy class');
is(($declared ? My::CH::Route::Storage->can('dbio_deploy_class') : undef), $declared,
  '... which the test storage below inherits rather than declaring its own');

{
  my $schema = fresh_schema();
  my $deploy = DBIO::ClickHouse::Deploy->new(schema => $schema);
  isa_ok $deploy, 'DBIO::ClickHouse::Deploy';
  isa_ok $deploy, 'DBIO::Deploy::Base';
  is $deploy->schema, $schema, 'new(schema => ...) is the constructor core calls';
  can_ok $deploy, 'install';
}

# --- 2. $schema->deploy routes there, and nowhere near core's loop -----------

{
  my $schema = fresh_schema();
  my $dbh    = $schema->storage->fake_dbh;

  my (@fell_through, @installed_by, @warnings);
  my $real_install = DBIO::ClickHouse::Deploy->can('install');
  my $rv;
  {
    no warnings 'redefine', 'once';
    local *DBIO::Storage::DBI::deploy      = sub { push @fell_through, 1; 1 };
    local *DBIO::ClickHouse::Deploy::install = sub {
      push @installed_by, ref $_[0];
      goto &$real_install;
    };
    # core carps once that a non-transactional DDL loop is not atomic; that is
    # the expected companion of _use_transactional_ddl(0), not noise.
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $rv = $schema->deploy;
  }

  ok $rv, '$schema->deploy succeeds';
  is_deeply \@fell_through, [],
    'it never enters DBIO::Storage::DBI::deploy — the carp-and-continue loop';
  is_deeply \@installed_by, ['DBIO::ClickHouse::Deploy'],
    '... it calls install on a DBIO::ClickHouse::Deploy instead';

  is scalar @{ $dbh->stmts }, 3, 'all three CREATE TABLE statements reached the dbh';

  my $ddl = DBIO::ClickHouse::DDL->install_ddl($schema);
  my $verbatim = 0;
  $verbatim++ for grep { index($ddl, $_) >= 0 } @{ $dbh->stmts };
  is $verbatim, 3,
    '... each one verbatim from DBIO::ClickHouse::DDL, not a generic producer';

  like $dbh->stmts->[0], qr/ENGINE = MergeTree/,
    'the DDL that reached the server is ClickHouse DDL (explicit ENGINE)';
  like $dbh->stmts->[0], qr/ORDER BY /, '... with an explicit sorting key';
}

# --- 3. a failing statement aborts the deploy -------------------------------
# The whole point of the declaration. Under core's fallback loop this deploy
# would warn, run the third statement anyway and return true.

{
  my $schema = fresh_schema(fail_on => 2);
  my $dbh    = $schema->storage->fake_dbh;

  my (@fell_through, @warnings, $rv);
  my $err = do {
    no warnings 'redefine';
    local *DBIO::Storage::DBI::deploy = sub { push @fell_through, 1; 1 };
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    local $@;
    eval { $rv = $schema->deploy; 1 };
    $@;
  };

  ok $err, 'a statement the server refuses makes $schema->deploy throw';
  like "$err", qr/fake dbh refused statement 2/,
    '... and the failure that reaches the caller is the one the server raised';
  ok !$rv, '... deploy does not report success';

  is scalar @{ $dbh->stmts }, 2,
    'the deploy stopped at the failing statement — the third never ran';

  is_deeply \@fell_through, [],
    'the failure came from the native Deploy class, not from core falling through';

  my @carped = grep { /\(running "/ } @warnings;
  is_deeply \@carped, [],
    'no statement error was downgraded to a warning (core\'s carp shape)';
}

# --- 4. diff hands the schema's storage to the Diff --------------------------
# DBIO::Deploy::Base::diff builds the Diff with source and target only. The
# Diff reads its storage from the constructor arguments and hands it to the
# ops, which ask it the F12 question (should_emit_if_exists) before they emit
# IF [NOT] EXISTS. On the productive path (Deploy->diff) that storage was
# always undef, so upgrade/apply rendered bare DROP/ADD/CREATE statements and
# re-applying a diff after a partial failure errored instead of being a no-op
# (karr k29). t/44 pins the guards with a storage handed to the Diff by hand;
# this pins that Deploy->diff does the handing.
#
# The two models are built by hand and stubbed in for _introspect_current and
# _build_target_model, so no server is involved: what is under test is only
# which storage the Diff ends up holding.

{
  my $schema  = fresh_schema();
  my $storage = $schema->storage;

  my $live = {
    tables => {
      gone => {
        table_name => 'gone', kind => 'table', engine => 'MergeTree',
        engine_expression => 'MergeTree', sorting_key_entries => ['id'],
        primary_key_entries => ['id'], partition_key => '',
        partition_key_entries => [],
      },
    },
    columns => { gone => [ { column_name => 'id', data_type => 'UInt64' } ] },
    data_skipping_indexes => {}, indexes => {}, foreign_keys => {},
  };
  my $desired = {
    tables => {}, columns => {}, data_skipping_indexes => {},
    indexes => {}, foreign_keys => {},
  };

  my $diff = do {
    no warnings 'redefine';
    local *DBIO::ClickHouse::Deploy::_introspect_current     = sub { $live };
    local *DBIO::ClickHouse::Deploy::_build_target_model     = sub { $desired };
    DBIO::ClickHouse::Deploy->new(schema => $schema)->diff;
  };

  is $diff->{storage}, $storage,
    'Deploy->diff gives the Diff the schema\'s own storage';
  like $diff->as_sql, qr/DROP TABLE IF EXISTS `gone`/,
    '... so the statement it renders carries the IF EXISTS guard the storage declares';
}

done_testing;
