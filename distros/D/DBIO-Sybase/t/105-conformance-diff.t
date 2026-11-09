use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Test::Conformance;

# WHY: the declarations of the driver's Diff half of the conformance table are
# checked without a server (karr k97, core ADR 0060): every refusal names a
# case, and the answered table version of the area is the one core has. The
# cases themselves run in t/106-conformance-diff-live.t.

my $class = 'DBIO::Sybase::Test::Conformance';

is_deeply [ $class->check_declarations('Diff') ], [],
  'the Diff declarations are whole';

is scalar(@{ $class->cases('Diff') }), 23, 'the Diff table has its twenty-three cases';

my $through = $class->conformance_answered_through;
is ref $through, 'HASH', 'conformance_answered_through is a hash, one version per area';
is $through->{Diff}, $class->table_version('Diff'),
  'the driver answers the Diff table as it stands';

done_testing;
