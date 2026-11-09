use strict;
use warnings;
use Test::More;

# LIVE (karr k35): a commit the server refuses comes back as the server's
# error. CREATE UNIQUE INDEX over duplicate rows is accepted as a statement and
# refused at the commit. DBD::Firebird fails that commit and DBI then reports
# "DBD driver has not implemented the AutoCommit attribute" instead -- the
# server's text is only on $dbh->errstr. Storage::InterBase::_exec_txn_commit
# raises that text.
#
# What this file claims, through $storage->txn_do on a real handle:
#   1. the exception names the unique index and the duplicate value;
#   2. it does not carry DBI's AutoCommit text;
#   3. the storage is usable afterwards (a select answers);
#   4. it is a DBIO::Exception::Server with "DBI Exception: " text and the
#      same sqlstate as a unique violation raised by a statement (core's
#      _dbi_handle_error contract).
#
# Skipped unless DBIO_TEST_FIREBIRD_DSN / _USER / _PASS are set.
# WARNING: creates and drops the tables "k35_t" and "k35_s".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live commit-error test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

{
  package DBIO::Firebird::Test::K35Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Firebird');
}

my $schema  = DBIO::Firebird::Test::K35Schema->connect($dsn, $user, $pass, { quote_names => 1 });
my $storage = $schema->storage;
eval { $storage->dbh->do('SELECT 1 FROM rdb$database'); 1 }
  or plan skip_all => "Cannot reach Firebird server: $@";

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /rollback ineffective with AutoCommit/ };

sub cleanup {
  my $d = DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0, AutoCommit => 1, ib_dialect => 3 });
  $d->do('DROP TABLE "k35_t"');
  $d->do('DROP TABLE "k35_s"');
  $d->disconnect;
}
$storage->disconnect;
cleanup();

$storage->dbh_do(sub { $_[1]->do($_) }, $_) for
  'CREATE TABLE "k35_t" ("b" INTEGER)',
  'INSERT INTO "k35_t" VALUES (5)',
  'INSERT INTO "k35_t" VALUES (5)';

my $ok = eval {
  $storage->txn_do(sub {
    $storage->dbh_do(sub { $_[1]->do('CREATE UNIQUE INDEX "k35_u" ON "k35_t" ("b")') });
  });
  1;
};
my $err_obj = $@;
my $err = "$err_obj";
ok(!$ok, 'txn_do around CREATE UNIQUE INDEX over duplicates dies');
like($err, qr/duplicate value/i, '... with the server\'s text about the duplicate');
like($err, qr/k35_u/i, '... naming the index');
unlike($err, qr/has not implemented the AutoCommit/, '... not DBI\'s AutoCommit text');

isa_ok($err_obj, 'DBIO::Exception::Server', 'the commit error');
like($err, qr/DBI Exception: /, '... with the text a statement error has');

# the same kind of error from a statement
my $stmt_obj;
eval {
  $storage->dbh_do(sub {
    $_[1]->do('CREATE TABLE "k35_s" ("b" INTEGER NOT NULL PRIMARY KEY)');
    $_[1]->do('INSERT INTO "k35_s" VALUES (1)');
    $_[1]->do('INSERT INTO "k35_s" VALUES (1)');
  });
  1;
} or $stmt_obj = $@;
isa_ok($stmt_obj, 'DBIO::Exception::Server', 'the statement error');
# DBD::Firebird reports DBI's general S1000, which core reads as no SQLSTATE:
# both are undef today; the claim is that the commit error is read the same
# way as the statement error, whatever the DBD says
is($err_obj->sqlstate, $stmt_obj->sqlstate, 'the commit error carries the sqlstate of a unique violation by statement');

my ($one) = eval { $storage->dbh_do(sub { $_[1]->selectrow_array('SELECT 1 FROM rdb$database') }) };
is($one, 1, 'the storage answers afterwards') or diag $@;

$storage->disconnect;
cleanup();
done_testing;
