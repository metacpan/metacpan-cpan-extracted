use strict;
use warnings;
use Test::More;

use DBIO::DB2::Test::Conformance;

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k57, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/87-conformance-bind-live.t.

my $class = 'DBIO::DB2::Test::Conformance';

is_deeply [ $class->check_declarations('Bind') ], [],
  'the conformance declarations are whole';

ok $class->conformance_answered_through->{Bind} <= $class->table_version('Bind'),
  'the driver does not claim a Bind table version newer than core has';

is $class->conformance_answered_through->{Bind}, $class->table_version('Bind'),
  'the driver answers the Bind table as it stands';

done_testing;
