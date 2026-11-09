use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Oracle::Test::Conformance;
use DBIO::Oracle::DDL;

# LIVE (karr k56, core ADR 0060). The twenty cases of the shared DDL table
# run against a real Oracle: each is installed with $schema->deploy into the
# connected user's schema, what it must show is read back through
# DBIO::Oracle::Introspect and the ResultSet API, and what the case created is
# dropped again (DBIO::Oracle::Test::Conformance::conformance_cleanup drops the
# objects the user owns afterwards and did not before; nothing else).
#
# A case is correct or refused as declared; there is no third answer. The Diff
# postcondition is asked (karr k37): after the install the diff against the
# same declaration holds nothing of the case.
#
# Without DBIO_TEST_ORA_DSN (and DBD::Oracle) only the declarations are
# checked and the number of cases not run is said. One run per database: two
# runs against the same user drop each other's objects.

my $objects = sub {
  my $dbh = DBI->connect(@ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)},
    { RaiseError => 1, PrintError => 0 });
  my $rows = $dbh->selectall_arrayref(
    q{SELECT object_type || ' ' || object_name FROM user_objects
      WHERE object_name NOT LIKE 'BIN$%' ORDER BY 1});
  $dbh->disconnect;
  return [ map { $_->[0] } @$rows ];
};

my $live = DBIO::Oracle::Test::Conformance->conformance_live_available;
my $before = $live ? $objects->() : undef;

DBIO::Oracle::Test::Conformance->run('DDL');

# the cleanup drops what the cases created and nothing else
is_deeply $objects->(), $before,
  'the user owns exactly the objects it owned before the run'
  if $live;

# The postcondition is not vacuous (karr k37): a table that differs from its
# declaration is told, one that equals it is not.
SKIP: {
  skip 'no Oracle to ask', 3 unless $live;

  my $class  = 'DBIO::Oracle::Test::Conformance';
  my ($case) = grep { $_->{name} eq 'ddl-unique-constraint' } @{ $class->cases('DDL') };
  my $schema = $class->conformance_connect($class->_build_schema_class($case));
  my $mark   = $class->conformance_namespace($schema, $case);

  my $ok = eval {
    $class->conformance_install($schema, $case);
    ok $class->conformance_diff_is_empty($schema, $case),
      'the diff of an installed case against its declaration is empty';

    my ($table) = @{ DBIO::Oracle::DDL->declared_objects($schema)->{table} };
    $schema->storage->dbh->do(qq{ALTER TABLE "$table" ADD (k37_extra NUMBER)});

    my $told = '';
    my $tb = Test::More->builder;
    open my $fh, '>', \$told or die $!;
    my $was = $tb->failure_output;
    $tb->failure_output($fh);
    my $empty = eval { $class->conformance_diff_is_empty($schema, $case) };
    $tb->failure_output($was);

    ok !$empty, 'a column the declaration does not have: the diff is not empty';
    like $told, qr/-column: \Q$table\E\.k37_extra/i, '... and tells the operation';
    1;
  };
  my $error = $@;
  $class->conformance_cleanup($schema, $case, $mark);
  die $error unless $ok;
}

done_testing;
