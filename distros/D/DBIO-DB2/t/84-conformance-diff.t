use strict;
use warnings;
use Test::More;

use DBIO::DB2::Test::Conformance;

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k57, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/85-conformance-diff-live.t.

my $class = 'DBIO::DB2::Test::Conformance';

is_deeply [ $class->check_declarations('Diff') ], [],
  'the conformance declarations are whole';

ok $class->conformance_answered_through->{Diff} <= $class->table_version('Diff'),
  'the driver does not claim a Diff table version newer than core has';

is $class->conformance_answered_through->{Diff}, $class->table_version('Diff'),
  'the driver answers the Diff table as it stands';

done_testing;
