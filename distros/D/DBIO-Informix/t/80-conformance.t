use strict;
use warnings;
use Test::More;

use DBIO::Informix::Test::Conformance;

my $class = 'DBIO::Informix::Test::Conformance';

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k24): every refusal names a case, and the
# answered table version is a number. The cases themselves run in
# t/80-conformance-ddl-live.t.
subtest 'DDL' => sub {
  is_deeply [ $class->check_declarations('DDL') ], [],
    'the conformance declarations are whole';

  # Not an exact count (ADR 0060 section 6): core adds cases with a higher
  # `since`, and a released driver must not turn red for a case it never claimed
  # to answer. The cases of the table version this driver answered through are
  # the ones it is held to; there were twenty at table version 2 (nineteen at version 1).
  my $through = $class->conformance_answered_through->{DDL};
  my @cases   = @{ $class->cases('DDL') };
  my @answered = grep { $_->{since} <= $through } @cases;

  cmp_ok scalar(@answered), '>=', 20,
    "the DDL cases of table version $through are at least the twenty this driver was written against";

  my %refused = %{ $class->conformance_refusals };
  my %by_name = map { $_->{name} => $_ } @cases;
  is_deeply [ sort grep { /^ddl-/ and (!$by_name{$_} || $by_name{$_}{since} > $through) } keys %refused ], [],
    'every declared refusal names a case of the table version the driver answered through';

  ok $through <= $class->table_version('DDL'),
    'the driver does not claim a table version newer than core has';
};

# WHY: the declarations of the driver's half of the Diff case table are
# checked without a server (karr k24): the declarations are whole, every
# refusal names a Diff case of the table version the driver answered through.
# The cases themselves run in t/89-conformance-diff-live.t.
subtest 'Diff' => sub {
  is_deeply [ $class->check_declarations('Diff') ], [],
    'the Diff conformance declarations are whole';

  my $through = $class->conformance_answered_through->{Diff};
  my @cases   = @{ $class->cases('Diff') };
  my @answered = grep { $_->{since} <= $through } @cases;

  cmp_ok scalar(@answered), '>=', 23,
    "the Diff cases of table version $through are at least the twenty-three this driver was written against";

  is $through, 4, 'the driver answers the Diff table through version 4, the deploy cases (ADR 0080)';
  isnt $class->can('conformance_deploy'), DBIO::Test::Conformance->can('conformance_deploy'),
    'the driver provides conformance_deploy of its own';

  my %by_name = map { $_->{name} => $_ } @cases;
  my %refused = %{ $class->conformance_refusals };
  is_deeply [ sort grep { /^diff-/ and (!$by_name{$_} || $by_name{$_}{since} > $through) } keys %refused ], [],
    'every declared Diff refusal names a case of the table version the driver answered through';

  is_deeply [ grep { ($refused{$_}{kind} // '') eq 'pending' } keys %refused ], [],
    'no Diff case is pending any more';

  ok $through <= $class->table_version('Diff'),
    'the driver does not claim a Diff table version newer than core has';
};

# WHY: the declarations of the driver's half of the Bind case table are
# checked without a server (karr k24). The cases themselves run in
# t/90-conformance-bind-live.t.
subtest 'Bind' => sub {
  is_deeply [ $class->check_declarations('Bind') ], [],
    'the Bind conformance declarations are whole';

  my $through = $class->conformance_answered_through->{Bind};
  my @cases   = @{ $class->cases('Bind') };
  my @answered = grep { $_->{since} <= $through } @cases;

  cmp_ok scalar(@answered), '>=', 10,
    "the Bind cases of table version $through are at least the ten this driver was written against";

  my %by_name = map { $_->{name} => $_ } @cases;
  my %refused = %{ $class->conformance_refusals };
  is_deeply [ sort grep { /^bind-/ and (!$by_name{$_} || $by_name{$_}{since} > $through) } keys %refused ], [],
    'every declared Bind refusal names a case of the table version the driver answered through';

  ok $through <= $class->table_version('Bind'),
    'the driver does not claim a Bind table version newer than core has';
};

done_testing;
