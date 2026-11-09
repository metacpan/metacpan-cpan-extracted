use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Test::Conformance;

# WHY: the declarations of the driver's half of the Diff case table are
# checked without a server (karr k60): the declarations are whole, every
# refusal names a Diff case of the table version the driver answered through.
# The cases themselves run in t/89-conformance-diff-live.t.

my $class = 'DBIO::Firebird::Test::Conformance';

is_deeply [ $class->check_declarations('Diff') ], [],
  'the Diff conformance declarations are whole';

my $through = $class->conformance_answered_through->{Diff};
my @cases   = @{ $class->cases('Diff') };
my @answered = grep { $_->{since} <= $through } @cases;

cmp_ok scalar(@answered), '>=', 20,
  "the Diff cases of table version $through are at least the twenty this driver was written against";

my %by_name = map { $_->{name} => $_ } @cases;
my %refused = %{ $class->conformance_refusals };
is_deeply [ sort grep { /^diff-/ and (!$by_name{$_} || $by_name{$_}{since} > $through) } keys %refused ], [],
  'every declared Diff refusal names a case of the table version the driver answered through';

# karr k62: the constraint cases of an existing table are answered, not
# declared pending or refused (the diff writes DROP / ADD CONSTRAINT).
is_deeply [ grep { exists $refused{$_} } qw(
    diff-indexed-column-dropped diff-fk-dropped diff-fk-added-to-new-unique
    diff-constraint-changed diff-fk-action-changed) ], [],
  'the five constraint cases of karr k62 are answered, none declared';
is_deeply [ grep { ($refused{$_}{kind} // '') eq 'pending' } keys %refused ], [],
  'no Diff case is pending any more';

ok $through <= $class->table_version('Diff'),
  'the driver does not claim a Diff table version newer than core has';

done_testing;
