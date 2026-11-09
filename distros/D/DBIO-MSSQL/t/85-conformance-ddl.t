use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Test::Conformance;

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k71, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/86-conformance-ddl-live.t.

my $class = 'DBIO::MSSQL::Test::Conformance';

is_deeply [ $class->check_declarations('DDL') ], [],
  'the conformance declarations are whole';

is scalar(@{ $class->cases('DDL') }), 20, q{the DDL table has its twenty cases (D15 is two since table version 2)};

ok $class->conformance_answered_through->{DDL} <= $class->table_version('DDL'),
  'the driver does not claim a DDL table version newer than core has';

done_testing;
