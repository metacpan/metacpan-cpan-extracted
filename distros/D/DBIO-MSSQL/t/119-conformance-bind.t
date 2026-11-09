use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Test::Conformance;

# WHY: the declarations of the driver's Bind half of the conformance table are
# checked without a server (karr k81, core ADR 0060): every refusal names a
# case, and the answered table version of the area is no newer than core's.
# The cases themselves run in t/120-conformance-bind-live.t.

my $class = 'DBIO::MSSQL::Test::Conformance';

is_deeply [ $class->check_declarations('Bind') ], [],
  'the Bind declarations are whole';

is scalar(@{ $class->cases('Bind') }), 10, 'the Bind table has its ten cases';

my $through = $class->conformance_answered_through;
is ref $through, 'HASH', 'conformance_answered_through is a hash, one version per area';
ok $through->{Bind} <= $class->table_version('Bind'),
  'the driver does not claim a Bind table version newer than core has';

done_testing;
