use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Oracle::Test::Conformance;
use DBIO::Oracle::Deploy;
use DBIO::Oracle::DDL;

# OFFLINE (karr k56, core ADR 0060). The driver's half of the shared DDL case
# table, as far as it can be checked without a server:
#
#   1. the declarations are whole (every refusal names a case, a regex reason,
#      a card for pending; the answered table version is a number per area);
#   2. every one of the twenty cases is answered: install_ddl returns
#      statements, or it throws the refusal declared for the case -- as a
#      DBIO exception that is not a server error, says "refus", names the
#      table and the column of the declaration and matches the declared reason
#      (the convention the runner checks live). A refusal declared for a case
#      whose DDL goes through is stale, and a case that throws without a
#      declaration is an undeclared refusal; both fail here;
#   3. the Diff area is answered (karr k37: the diff creates a new table), so
#      nothing is declared refused and the diff postcondition is the driver's
#      own; diff and upgrade themselves are not refused either (karr k36).
#
# What the server makes of the DDL, and the facts it shows back, is
# t/73-conformance-ddl-live.t.

my $class = 'DBIO::Oracle::Test::Conformance';

is_deeply [ $class->check_declarations('DDL') ], [],
  'the conformance declarations are whole';

my $cases = $class->cases('DDL');
is scalar(@$cases), 20, 'the DDL table has its twenty cases';

is $class->conformance_answered_through->{DDL}, $class->table_version,
  'every case of the table is answered';

my $refusals = $class->conformance_refusals;

for my $case (@$cases) {
  my $name = $case->{name};
  my $schema_class = $class->_build_schema_class($case);
  my $ddl = eval { DBIO::Oracle::DDL->install_ddl($schema_class) };
  my $error = $@;

  my $declared = $refusals->{$name};

  # ddl-view-declared is answered correctly (karr k57): no refusal is declared
  # and the driver writes the view. The runner fills the identifiers of the
  # definition from conformance_quote_ident (core dbio k349) when the case
  # runs, t/75 and t/73 show it on the server.
  if ($name eq 'ddl-view-declared') {
    ok !$declared, "$name: no refusal is declared, the case is answered correctly";
    ok defined $ddl && $ddl =~ /CREATE VIEW "base_view"/,
      "$name: the driver writes the DDL, it does not refuse the view"
      or diag "got: $error";
    next;
  }

  # ddl-qualified-source-name is answered correctly (karr k58): install_ddl
  # writes the table into the schema 'other'. Where a live server has no user
  # of that name Deploy refuses the install (pending on k58, declared by
  # conformance_refusals on a live run); that refusal is the server-aware
  # install's, never install_ddl's (t/85, t/84 hold both halves).
  if ($name eq 'ddl-qualified-source-name') {
    ok defined $ddl && $ddl =~ /CREATE TABLE "other"\."t" \(/,
      "$name: the driver writes the table into the schema, it does not refuse it"
      or diag "got: $error";
    next;
  }

  if ($declared and $declared->{kind} ne 'deviation') {
    ok !defined $ddl, "$name: install_ddl refuses (declared $declared->{kind})"
      or next;
    my @problem = $class->_refusal_problems($case, $declared, $error);
    is_deeply \@problem, [], "$name: the refusal meets the convention"
      or diag "got: $error";
  }
  else {
    # a deviation is installed like a correct case: the engine differs on the
    # server, in what it reads back
    ok defined $ddl && length $ddl, "$name: install_ddl returns statements"
      or diag "got: $error";
  }
}

{
  my %known = map { $_->{name} => 1 } @$cases;
  # the Diff and Bind refusals are checked by t/86 and t/88
  is_deeply [ sort grep { !$known{$_} } grep { !/\A(?:diff|bind)-/ } keys %$refusals ], [],
    'every declared refusal names a case of the table';
}

# the Diff area
{
  my $areas = $class->conformance_refused_areas;
  is_deeply $areas, {}, 'no area is refused: the Diff area is answered (karr k37)';
  isnt $class->can('conformance_diff_is_empty'),
    DBIO::Test::Conformance->can('conformance_diff_is_empty'),
    '... the diff postcondition is the driver\'s, not the unprovided seam';

  is( DBIO::Oracle::Deploy->can($_), DBIO::Deploy::Base->can($_),
    "$_ is not refused: it is DBIO::Deploy::Base's own" ) for qw(diff upgrade);
}

done_testing;
