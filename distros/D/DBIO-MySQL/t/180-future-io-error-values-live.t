use strict;
use warnings;
use Test::More;

# LIVE: the future_io transport answers a refused statement with a failed Future
# whose text holds no bound value (ADR 0075), as the synchronous storage does
# (t/179). The server writes the offending value into its message; the transport
# takes it out where it sends the statement and where it reads the result, and
# leaves the type, the column and the key. Works in a database of its own, on
# MySQL and on MariaDB.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::MySQL::Storage::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async, IO::Async and Future::IO::Impl::IOAsync required for the future_io transport';
}

use DBI;
use Time::HiRes ();

my $DB = "fw_errv_async_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
my @schemas;
END {
  local ($@, $?);
  eval { $_->storage->disconnect } for @schemas;
  eval { drop_database() } if $raw;
}

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}

my $loop = IO::Async::Loop->new;
sub settle {
  my ($f) = @_;
  my $deadline = Time::HiRes::time() + 30;
  until ($f->is_ready) {
    die "a Future did not settle\n" if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return $f;
}

my $dbd = $dsn =~ /\Adbi:(\w+):/i ? lc $1 : 'mysql';

$raw->do(<<"SQL");
CREATE TABLE `$DB`.fw_item (
  id VARCHAR(40) NOT NULL,
  n INT NULL,
  d DATE NULL,
  a VARCHAR(40) NULL,
  b VARCHAR(40) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY fw_item_ab (a, b)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL

my $class = 'FwErrvAsync::Schema';
eval "package $class; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
my $rc = "$class\::Result::Item";
eval "package $rc; use DBIO 'Core', -mysql; 1" or die $@;
$rc->table('fw_item');
$rc->add_columns(
  id => { data_type => 'varchar', size => 40 },
  n  => { data_type => 'integer', is_nullable => 1 },
  d  => { data_type => 'date', is_nullable => 1 },
  a  => { data_type => 'varchar', size => 40, is_nullable => 1 },
  b  => { data_type => 'varchar', size => 40, is_nullable => 1 },
);
$rc->set_primary_key('id');
$class->register_class(Item => $rc);

my $schema = $class->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
  async => 'future_io', pool_size => 2,
  on_connect_do => ["USE `$DB`"],
});
push @schemas, $schema;
my $rs = $schema->resultset('Item');

my $MARKER = 'geheim42';

# One case: the Future fails, with the type and what the marker was written
# into, and nothing of the values.
sub refused {
  my ($label, $future, %want) = @_;
  settle($future);
  unless ($future->is_failed) {
    fail "$label: the Future failed";
    return;
  }
  my $err = join '', map { "$_" } $future->failure;
  unlike $err, qr/\Q$_\E/, "$label: no '$_' in the text" for @{ $want{absent} };
  like $err, $_, "$label: $_" for @{ $want{present} };
  return $err;
}

# INT
refused('int',
  $rs->create_async({ id => 'i1', n => $MARKER }),
  absent  => [$MARKER],
  present => [qr/Incorrect integer value: '\*\*\*' for column/, qr/\bn\b/],
);

# DATE
refused('date',
  $rs->create_async({ id => 'd1', d => $MARKER }),
  absent  => [$MARKER],
  present => [qr/Incorrect date value/, qr/\bd\b/],
);

# Duplicate entry, PRIMARY
settle($rs->create_async({ id => $MARKER }))->get;
refused('duplicate primary key',
  $rs->create_async({ id => $MARKER }),
  absent  => [$MARKER],
  present => [qr/Duplicate entry '\*\*\*' for key '(?:fw_item\.)?PRIMARY'/],
);

# Duplicate entry, composite unique key
settle($rs->create_async({ id => 'ab1', a => "${MARKER}A", b => "${MARKER}B" }))->get;
refused('duplicate composite key',
  $rs->create_async({ id => 'ab2', a => "${MARKER}A", b => "${MARKER}B" }),
  absent  => [$MARKER, "${MARKER}A", "${MARKER}B"],
  present => [qr/Duplicate entry '\*\*\*' for key '(?:fw_item\.)?fw_item_ab'/],
);

# Syntax error after a bind; the transport's text has no statement, only the
# excerpt of the server, which holds no value
my $err = refused('syntax error',
  $rs->search(\[ q{id = ? AND BROKEN 'stmtliteral' ((}, $MARKER ])->all_async,
  absent  => [$MARKER],
  present => [qr/You have an error in your SQL syntax/],
);
unlike $err // '', qr/stmtliteral/, 'syntax error: a literal of the statement is not in the excerpt either';

# Short values
settle($rs->create_async({ id => '7' }))->get;
refused('short duplicate',
  $rs->create_async({ id => '7' }),
  present => [qr/Duplicate entry '\*\*\*' for key/],
);
$err = refused('short integer',
  $rs->create_async({ id => 's2', n => 'ab' }),
  present => [qr/Incorrect integer value: '\*\*\*' for column/],
);
unlike $err // '', qr/value: 'ab'/, "short integer: 'ab' is not quoted";

# The connection that took the errors serves the next statement
my $row = settle($rs->create_async({ id => 'after' }))->get;
ok $row, 'the pool still runs statements after the refusals';

done_testing;
