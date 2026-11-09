use strict;
use warnings;
use Test::More;

use DBIO::DB2::Test::Conformance;

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k57, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/83-conformance-ddl-live.t.

my $class = 'DBIO::DB2::Test::Conformance';

is_deeply [ $class->check_declarations('DDL') ], [],
  'the conformance declarations are whole';

ok $class->conformance_answered_through->{DDL} <= $class->table_version('DDL'),
  'the driver does not claim a DDL table version newer than core has';

is $class->conformance_answered_through->{DDL}, $class->table_version('DDL'),
  'the driver answers the DDL table as it stands';

done_testing;
