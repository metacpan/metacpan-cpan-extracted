use strict;
use warnings;
use Test::More;

# LIVE test: a statement the server refuses is a DBIO::Exception::Server that
# names the constraint, the table and the detail (karr k130).
#
# WHY: DBIO::PostgreSQL::Storage::_dbi_error_fields reads them with DBD::Pg's
# pg_error_field from inside the HandleError handler core installs. The
# offline test (t/123-dbi-error-fields.t) holds the mapping on a mock handle;
# only a server tells whether DBD::Pg answers AT THE TIME HandleError runs
# -- the doc says the error information is reset by the next query on the
# connection, and nothing has run yet then, but that is the claim here.
#
# How to read a failure. Each case first checks the exception is a Server with
# the sqlstate (so the failure is not "no exception at all"), then constraint,
# table and detail one by one. Then it asks the SAME handle again after the
# error: the diag line "after the error pg_error_field says: ..." shows
# whether the information was still there later. Reading:
#   sqlstate ok, constraint/table/detail missing, "after the error" has them
#       -> pg_error_field does not answer inside HandleError; the fields have
#          to be read after the statement failed, from the $dbh/$sth.
#   sqlstate ok, constraint/table/detail ok -> it answers; done.
#
# Works in a schema of its own, dbio_k130_error_fields, and drops it.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBIO::Test;

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

use Scalar::Util ();

# A server that is not there fails the file, with a plan (karr k113).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

my $S = 'dbio_k130_error_fields';

my $schema  = DBIO::Test::Schema->connect($dsn, $user, $pass, { AutoCommit => 1 });
my $storage = $schema->storage;
my $dbh     = $storage->dbh;   # connects; driver resolved from here on

isa_ok $storage, 'DBIO::PostgreSQL::Storage', 'the storage, once connected';

END {
  if ($dbh && $dbh->{Active}) {
    local $SIG{__WARN__} = sub { };
    eval { $dbh->do("DROP SCHEMA IF EXISTS $S CASCADE") };
  }
}

{
  local $SIG{__WARN__} = sub { };
  $dbh->do("DROP SCHEMA IF EXISTS $S CASCADE");
}
$dbh->do("CREATE SCHEMA $S");
$dbh->do("CREATE TABLE $S.parent (id int CONSTRAINT parent_pkey PRIMARY KEY, name text CONSTRAINT parent_name_key UNIQUE)");
$dbh->do("CREATE TABLE $S.child (id int PRIMARY KEY, parent_id int CONSTRAINT child_parent_fk REFERENCES $S.parent (id))");
$dbh->do("INSERT INTO $S.parent (id, name) VALUES (1, 'one')");

sub failure_of {
  my ($code) = @_;
  my $ok = eval { $code->(); 1 };
  return $ok ? undef : $@;
}

sub check {
  my ($err, %want) = @_;
  my $name = delete $want{name};

  ok defined $err && Scalar::Util::blessed($err) && $err->isa('DBIO::Exception::Server'),
    "$name: a DBIO::Exception::Server"
    or diag 'got: ' . (defined $err ? (ref($err) || "plain string: $err") : 'no failure');
  return unless defined $err && Scalar::Util::blessed($err) && $err->can('sqlstate');

  is $err->sqlstate, $want{sqlstate}, "$name: sqlstate";
  is $err->constraint, $want{constraint}, "$name: constraint (pg_error_field answered inside HandleError)";
  is $err->table, $want{table}, "$name: table";
  like $err->detail // '', $want{detail}, "$name: detail";

  # the same question, now that the error is out: tells "not at HandleError
  # time" from "not at all" if the above failed
  diag sprintf 'after the error pg_error_field says: constraint=%s table=%s detail=%s',
    map { $dbh->pg_error_field($_) // 'undef' } qw( constraint table detail )
    if grep { !defined $err->$_ } qw( constraint table detail );
}

# --- a unique violation, through do() on the database handle ---------------
check(
  failure_of(sub { $dbh->do("INSERT INTO $S.parent (id, name) VALUES (2, 'one')") }),
  name       => 'unique violation (do)',
  sqlstate   => '23505',
  constraint => 'parent_name_key',
  table      => 'parent',
  detail     => qr/\AKey \(name\)=\(\*\*\*\) already exists/,
);

# --- the same through a statement handle: DBI passes the sth ----------------
check(
  failure_of(sub {
    my $sth = $dbh->prepare("INSERT INTO $S.parent (id, name) VALUES (?, ?)");
    $sth->execute(3, 'one');
  }),
  name       => 'unique violation (sth->execute)',
  sqlstate   => '23505',
  constraint => 'parent_name_key',
  table      => 'parent',
  detail     => qr/\AKey \(name\)=\(\*\*\*\) already exists/,
);

# --- a foreign key violation -------------------------------------------------
check(
  failure_of(sub { $dbh->do("INSERT INTO $S.child (id, parent_id) VALUES (1, 99)") }),
  name       => 'foreign key violation',
  sqlstate   => '23503',
  constraint => 'child_parent_fk',
  table      => 'child',
  detail     => qr/\AKey \(parent_id\)=\(\*\*\*\) is not present in table "parent"/,
);

# --- the connection is usable after, and a refusal without a constraint -----
{
  my $err = failure_of(sub { $dbh->do("SELECT 1 FROM $S.no_such_table") });
  ok Scalar::Util::blessed($err) && $err->isa('DBIO::Exception::Server'),
    'a missing table: a Server exception too';
  is $err->sqlstate, '42P01', '... sqlstate 42P01' if Scalar::Util::blessed($err);
  is $err->constraint, undef, '... no constraint' if Scalar::Util::blessed($err);
}

is $dbh->selectrow_array("SELECT count(*) FROM $S.parent"), 1,
  'the connection is usable after the refusals';

done_testing;
