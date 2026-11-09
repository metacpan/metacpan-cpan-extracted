use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Test::Conformance;

# WHY: the declarations of the driver's half of the Diff list are checked
# without a server (karr k120): every refusal names a case, and the answered
# table version is a number. The cases run in t/159-conformance-diff-live.t.

my $class = 'DBIO::MySQL::Test::Conformance';

is_deeply [ $class->check_declarations('Diff') ], [],
  'the conformance declarations of the Diff list are whole';

ok scalar(@{ $class->cases('Diff') }) > 0, 'the Diff table has cases';

my $through = $class->conformance_answered_through;
is $through->{Diff}, $class->table_version('Diff'),
  'the driver answers the Diff list through the version core has';

done_testing;
