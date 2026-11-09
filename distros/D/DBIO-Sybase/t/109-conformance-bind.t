use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Test::Conformance;

# WHY: the declarations of the driver's Bind half of the conformance table are
# checked without a server (karr k97, core ADR 0060): every refusal names a
# case, and the answered table version of the area is the one core has. The
# cases themselves run in t/110-conformance-bind-live.t.

my $class = 'DBIO::Sybase::Test::Conformance';

is_deeply [ $class->check_declarations('Bind') ], [],
  'the Bind declarations are whole';

is scalar(@{ $class->cases('Bind') }), 10, 'the Bind table has its ten cases';

my $through = $class->conformance_answered_through;
is ref $through, 'HASH', 'conformance_answered_through is a hash, one version per area';
is $through->{Bind}, $class->table_version('Bind'),
  'the driver answers the Bind table as it stands';

done_testing;
