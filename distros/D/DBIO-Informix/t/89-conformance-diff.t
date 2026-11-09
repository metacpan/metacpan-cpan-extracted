use strict;
use warnings;
use Test::More;

use DBIO::Informix::Test::Conformance;

# WHY: the declarations of the driver's half of the Diff case table are
# checked without a server (karr k24): the declarations are whole, every
# refusal names a Diff case of the table version the driver answered through.
# The cases themselves run in t/89-conformance-diff-live.t.

my $class = 'DBIO::Informix::Test::Conformance';

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

done_testing;
