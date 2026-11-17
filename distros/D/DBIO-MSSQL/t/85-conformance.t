use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Test::Conformance;

my $class = 'DBIO::MSSQL::Test::Conformance';

# WHY: the declarations of the driver's DDL half of the conformance table are
# checked without a server (karr k71, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/86-conformance-ddl-live.t.
subtest 'DDL' => sub {
  is_deeply [ $class->check_declarations('DDL') ], [],
    'the conformance declarations are whole';

  is scalar(@{ $class->cases('DDL') }), 20, q{the DDL table has its twenty cases (D15 is two since table version 2)};

  ok $class->conformance_answered_through->{DDL} <= $class->table_version('DDL'),
    'the driver does not claim a DDL table version newer than core has';
};

# WHY: the declarations of the driver's Diff half of the conformance table are
# checked without a server (karr k81, core ADR 0060): every refusal names a
# case, and the answered table version of the area is no newer than core's.
# The cases themselves run in t/118-conformance-diff-live.t.
subtest 'Diff' => sub {
  is_deeply [ $class->check_declarations('Diff') ], [],
    'the Diff declarations are whole';

  is scalar(@{ $class->cases('Diff') }), 23, 'the Diff table has its 23 cases';

  my $through = $class->conformance_answered_through;
  is ref $through, 'HASH', 'conformance_answered_through is a hash, one version per area';
  ok $through->{Diff} <= $class->table_version('Diff'),
    'the driver does not claim a Diff table version newer than core has';
};

# WHY: the declarations of the driver's Bind half of the conformance table are
# checked without a server (karr k81, core ADR 0060): every refusal names a
# case, and the answered table version of the area is no newer than core's.
# The cases themselves run in t/120-conformance-bind-live.t.
subtest 'Bind' => sub {
  is_deeply [ $class->check_declarations('Bind') ], [],
    'the Bind declarations are whole';

  is scalar(@{ $class->cases('Bind') }), 10, 'the Bind table has its ten cases';

  my $through = $class->conformance_answered_through;
  is ref $through, 'HASH', 'conformance_answered_through is a hash, one version per area';
  ok $through->{Bind} <= $class->table_version('Bind'),
    'the driver does not claim a Bind table version newer than core has';
};

done_testing;
