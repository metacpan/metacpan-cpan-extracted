use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Test::Conformance;

# WHY: the declarations of the driver's half of the Bind case table are
# checked without a server (karr k60). The cases themselves run in
# t/90-conformance-bind-live.t.

my $class = 'DBIO::Firebird::Test::Conformance';

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

done_testing;
