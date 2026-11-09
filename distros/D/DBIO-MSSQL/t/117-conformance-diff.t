use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Test::Conformance;

# WHY: the declarations of the driver's Diff half of the conformance table are
# checked without a server (karr k81, core ADR 0060): every refusal names a
# case, and the answered table version of the area is no newer than core's.
# The cases themselves run in t/118-conformance-diff-live.t.

my $class = 'DBIO::MSSQL::Test::Conformance';

is_deeply [ $class->check_declarations('Diff') ], [],
  'the Diff declarations are whole';

is scalar(@{ $class->cases('Diff') }), 23, 'the Diff table has its 23 cases';

my $through = $class->conformance_answered_through;
is ref $through, 'HASH', 'conformance_answered_through is a hash, one version per area';
ok $through->{Diff} <= $class->table_version('Diff'),
  'the driver does not claim a Diff table version newer than core has';

done_testing;
