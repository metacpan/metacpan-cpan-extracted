use strict;
use warnings;
use Test::More;

# LIVE measurement (karr k71, point 4): what upsert's affected-row count is on
# MySQL and on MariaDB, through DBD::mysql and DBD::MariaDB, with and without
# CLIENT_FOUND_ROWS -- above all for the DO NOTHING emulation.
#
# WHY IT MATTERS. MySQL has no ON CONFLICT DO NOTHING; this driver renders it
# as ON DUPLICATE KEY UPDATE with an assignment that changes nothing. Whether
# the row was inserted or was already there can then be read off the
# affected-row count only where the server counts CHANGED rows: 1 inserted, 0
# already there. With CLIENT_FOUND_ROWS it counts FOUND rows, and both DBDs ask
# for that flag by default. So upsert(..., { result => 'count' }) -- which
# core's documentation recommends for telling "skipped" from "inserted" on an
# engine without RETURNING -- answers 1 either way on a default connection.
# The POD of this driver said so for MySQL; this file measures it for both
# servers and both DBDs, and pins what it found.
#
# What this file claims, for two tables -- an AUTO_INCREMENT key beside a
# unique name (DO NOTHING is the identity idiom there) and a natural primary
# key alone (DO NOTHING assigns a column to itself):
#   1. on a default connection, DO NOTHING counts 1 for a new row and 1 for a
#      row that was already there, and leaves that row as it was; the upsert
#      proper counts 1 for a new row, 1 for an existing row it did not change
#      and 2 for one it changed;
#   2. the default connection IS a CLIENT_FOUND_ROWS connection: every count
#      equals that of a connection which asks for the flag explicitly;
#   3. without the flag the counts tell the cases apart: 0 for the row that
#      was already there and for the update that changed nothing;
#   4. upsert_async with result => 'count' has no count of its own on the
#      future_io transport: core runs the upsert on the owning storage's
#      connection, and the count is that connection's.
#
# WHAT OF THIS IS THE DRIVER'S. The counting is the server's and the flag is
# the DBD's: claims 2 and 3, and the 1 of an already-present row, are
# measurements, pinned so that a server or a DBD that counts differently is
# noticed. The driver's own part is that DO NOTHING is rendered as an
# assignment that changes nothing -- the row is as it was, and the count is
# never 2.
#
# Runs through whichever DBD the DSN names. Gated like the other live tests:
# needs DBIO_TEST_MYSQL_DSN, _USER and _PASS. Creates and drops two tables of
# its own.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;

# Each DBD's own name for the flag, spelled out here.
my %FLAG = ( mysql => 'mysql_client_found_rows', MariaDB => 'mariadb_client_found_rows' );
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;
plan skip_all => 'DBIO_TEST_MYSQL_DSN names neither dbi:mysql: nor dbi:MariaDB:'
  unless defined $dbd && $FLAG{$dbd};
my $flag = $FLAG{$dbd};

my $AUTO   = "dbio_k71_up_auto_$$";
my $SINGLE = "dbio_k71_up_single_$$";

{
  package K71Up::Result::Auto;
  use base 'DBIO::Core';
  __PACKAGE__->table($AUTO);
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    name    => { data_type => 'varchar', size => 64 },
    payload => { data_type => 'varchar', size => 64, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(auto_name => ['name']);

  package K71Up::Result::Single;
  use base 'DBIO::Core';
  __PACKAGE__->table($SINGLE);
  __PACKAGE__->add_columns(
    k1      => { data_type => 'integer' },
    payload => { data_type => 'varchar', size => 64, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('k1');

  package K71Up::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Auto   => 'K71Up::Result::Auto');
  __PACKAGE__->register_class(Single => 'K71Up::Result::Single');
}

# A schema always declares its driver (core ADR 0067): the component of the
# storage class the DSN's DBD is registered for -- MySQL::MariaDB for
# DBD::MariaDB.
K71Up::Schema->load_components($dbd eq 'MariaDB' ? 'MySQL::MariaDB' : 'MySQL');

my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
note sprintf 'server %s, DBD::%s %s', scalar $raw->selectrow_array('SELECT VERSION()'),
  $dbd, "DBD::$dbd"->VERSION;

sub drop_tables {
  local $raw->{Warn} = 0;
  $raw->do("DROP TABLE IF EXISTS `$_`") for $AUTO, $SINGLE;
}
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_tables() };
  }
}

drop_tables();
$raw->do(<<"SQL");
CREATE TABLE `$AUTO` (
    id      BIGINT      NOT NULL AUTO_INCREMENT
  , name    VARCHAR(64) NOT NULL
  , payload VARCHAR(64)     NULL
  , PRIMARY KEY (id)
  , UNIQUE KEY auto_name (name)
)
SQL
$raw->do(<<"SQL");
CREATE TABLE `$SINGLE` (
    k1      INT         NOT NULL
  , payload VARCHAR(64)     NULL
  , PRIMARY KEY (k1)
)
SQL

# The five counts of one table on one connection, and what DO NOTHING left of
# the row that was already there.
sub counts {
  my ($schema, $source, $key, $extra, $call) = @_;
  $call //= sub { my ($rs, @args) = @_; $rs->upsert(@args) };
  my $rs = $schema->resultset($source);
  $raw->do('DELETE FROM `' . $rs->result_source->name . '`');

  my $count = sub {
    my ($value, $payload, %opts) = @_;
    return $call->($rs, { $key => $value, payload => $payload }, { %$extra, %opts, result => 'count' });
  };
  my %got;
  $got{nothing_new}      = $count->(1, 'first',  on_conflict => 'nothing');
  $got{nothing_existing} = $count->(1, 'second', on_conflict => 'nothing');
  ($got{nothing_left})   = $raw->selectrow_array(
    'SELECT payload FROM `' . $rs->result_source->name . "` WHERE `$key` = ?", undef, 1,
  );
  $got{update_new}       = $count->(2, 'first');
  $got{update_unchanged} = $count->(2, 'first');
  $got{update_changed}   = $count->(2, 'second');
  return \%got;
}

my %FOUND   = ( nothing_new => 1, nothing_existing => 1, nothing_left => 'first',
                update_new  => 1, update_unchanged => 1, update_changed => 2 );
my %CHANGED = ( %FOUND, nothing_existing => 0, update_unchanged => 0 );

my @TABLES = (
  [ Auto   => 'name', { conflict_target => 'any' }, 'an AUTO_INCREMENT key beside a unique name' ],
  [ Single => 'k1',   {},                           'a natural primary key alone' ],
);

my %measured;
for my $mode (
  [ default => 'the DBD\'s default connection',  {},             \%FOUND ],
  [ on      => "$flag => 1",                     { $flag => 1 }, \%FOUND ],
  [ off     => "$flag => 0",                     { $flag => 0 }, \%CHANGED ],
) {
  my ($name, $label, $attrs, $expected) = @$mode;
  my $schema = K71Up::Schema->connect($dsn, $user, $pass, { %$attrs });

  # The flag, seen without any upsert: an UPDATE that finds its row and
  # changes nothing.
  $raw->do("DELETE FROM `$SINGLE`");
  $raw->do("INSERT INTO `$SINGLE` (k1, payload) VALUES (7, 'same')");
  my $control = $schema->storage->dbh_do(sub {
    0 + $_[1]->do("UPDATE `$SINGLE` SET payload = 'same' WHERE k1 = 7");
  });
  is $control, $expected->{update_unchanged},
    "$label: an UPDATE that changes nothing counts $expected->{update_unchanged} -- "
    . ($expected->{update_unchanged} ? 'found rows' : 'changed rows');

  for my $table (@TABLES) {
    my ($source, $key, $extra, $what) = @$table;
    my $got = counts($schema, $source, ($key eq 'name' ? 'name' : 'k1'), $extra);
    $measured{$name}{$source} = $got;
    is_deeply $got, $expected, "$label, $what: the counts"
      or diag explain $got;
    note sprintf '%s, %s: DO NOTHING new=%s existing=%s; upsert new=%s unchanged=%s changed=%s',
      $label, $source, @$got{qw( nothing_new nothing_existing update_new update_unchanged update_changed )};
  }
  $schema->storage->disconnect;
}

# 2. the default is the flag
is_deeply $measured{default}, $measured{on},
  "DBD::$dbd asks for CLIENT_FOUND_ROWS by default: every count is that of a connection asking for it";

# 1., said once more for what it means to a caller
is $measured{default}{Single}{nothing_existing}, 1,
  'on a default connection the count of DO NOTHING does not tell an existing row from a new one';

# 4. future_io
SKIP: {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::MySQL::Storage::Async;
    1;
  } or skip 'no future_io transport here (dbio-async, IO::Async, Future::IO::Impl::IOAsync)', 2;

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $async_call = sub { my ($rs, @args) = @_; $rs->upsert_async(@args)->get };

  for my $mode ([ 'the default connection', {}, \%FOUND ], [ "$flag => 0", { $flag => 0 }, \%CHANGED ]) {
    my ($label, $attrs, $expected) = @$mode;
    my $schema = K71Up::Schema->connect($dsn, $user, $pass, { %$attrs, async => 'future_io' });
    my $got = eval { counts($schema, 'Single', 'k1', {}, $async_call) };
    is_deeply $got, $expected, "upsert_async with result => 'count', $label: the counts of the sync path"
      or diag $@ || explain $got;
    $schema->storage->async->disconnect;
    $schema->storage->disconnect;
  }
  note 'upsert_async with result => count warned: ' . (@warnings ? $warnings[0] =~ s/ at \S+ line.*//sr : 'nothing');
}

drop_tables();
$raw->disconnect;
undef $raw;

done_testing;
