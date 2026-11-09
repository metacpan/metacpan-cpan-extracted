use strict;
use warnings;

use Test::More;
use DBIO::Optional::Dependencies ();

# Install, compare and upgrade against a real Informix server through the
# throwaway database (karr k21). Creates and drops the tables "zz_ix_dep_a" and
# "zz_ix_dep_b" in the database of the DSN; the throwaway database is created
# and dropped by the deploy itself, and the test asserts it is gone.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run this test'
  unless $dsn;

use DBI;
use DBIO::Informix::Deploy;

{
  package T::A;
  use base 'DBIO::Core';
  __PACKAGE__->table('zz_ix_dep_a');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    code => { data_type => 'varchar', size => 20, is_unique => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T::B;
  use base 'DBIO::Core';
  __PACKAGE__->table('zz_ix_dep_b');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 50, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('DBIO::Informix::Storage');
  __PACKAGE__->register_class(A => 'T::A');
  __PACKAGE__->register_class(B => 'T::B');
}

my $schema = T::Schema->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
my $dbh    = $schema->storage->dbh;

sub cleanup { eval { $dbh->do("DROP TABLE $_") } for qw(zz_ix_dep_a zz_ix_dep_b) }
cleanup();
END { cleanup() if $dbh }

sub tables {
  my $m = DBIO::Informix::Introspect->new(dbh => $dbh)->model;
  return join ',', grep { /^zz_ix_dep_/ } sort keys %{ $m->{tables} };
}

# every database whose name is a throwaway of this process
sub leftovers {
  my $s = DBI->connect($dsn =~ s/\A(dbi:Informix:)[^@;]+/${1}sysmaster/ir, $user, $pass,
    { RaiseError => 1, PrintError => 0 });
  my $pat = '\_dbio\_tmp\_' . $$ . '\_%';
  my $r = $s->selectcol_arrayref(
    q{SELECT TRIM(name) FROM sysmaster:sysdatabases WHERE name LIKE ? ESCAPE '\'}, undef, $pat);
  $s->disconnect;
  return @$r;
}

my $deploy = DBIO::Informix::Deploy->new(schema => $schema);

$deploy->install;
is(tables(), 'zz_ix_dep_a,zz_ix_dep_b', 'install created the tables in the live database');
is_deeply([ leftovers() ], [], 'no throwaway database after install');

my $diff = $deploy->diff;
ok(!$diff->has_changes, 'compare: installed schema equals desired schema')
  or diag $diff->summary;
is_deeply([ leftovers() ], [], 'no throwaway database after the compare');

$dbh->do('DROP TABLE zz_ix_dep_b');
$diff = $deploy->diff;
ok($diff->has_changes, 'compare: a dropped table is a change');
is_deeply([ leftovers() ], [], 'no throwaway database after the second compare');

$deploy->upgrade;
is(tables(), 'zz_ix_dep_a,zz_ix_dep_b', 'upgrade recreated the dropped table');
ok(!$deploy->diff->has_changes, 'compare after the upgrade: no changes');
is_deeply([ leftovers() ], [], 'no throwaway database after the upgrade');

# a deploy that dies leaves no throwaway database either
{
  my $bad = DBIO::Informix::Deploy->new(schema => $schema);
  no warnings 'redefine';
  local *DBIO::Informix::DDL::install_ddl = sub { "CREATE TABLE zz_ix_dep_bad (id INTEGER);\nNO SUCH STATEMENT;" };
  ok(!eval { $bad->diff; 1 }, 'a failing deploy raises');
  is_deeply([ leftovers() ], [], 'no throwaway database after a failed deploy');
}

done_testing;
