use strict;
use warnings;
use Test::More;

use DBIO::DB2::Test::Conformance;

my $class = 'DBIO::DB2::Test::Conformance';

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k57, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/83-conformance-ddl-live.t.

subtest 'DDL' => sub {
  is_deeply [ $class->check_declarations('DDL') ], [],
    'the conformance declarations are whole';

  ok $class->conformance_answered_through->{DDL} <= $class->table_version('DDL'),
    'the driver does not claim a DDL table version newer than core has';

  is $class->conformance_answered_through->{DDL}, $class->table_version('DDL'),
    'the driver answers the DDL table as it stands';
};

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k57, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/85-conformance-diff-live.t.

subtest 'Diff' => sub {
  is_deeply [ $class->check_declarations('Diff') ], [],
    'the conformance declarations are whole';

  ok $class->conformance_answered_through->{Diff} <= $class->table_version('Diff'),
    'the driver does not claim a Diff table version newer than core has';

  is $class->conformance_answered_through->{Diff}, $class->table_version('Diff'),
    'the driver answers the Diff table as it stands';
};

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k57, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/87-conformance-bind-live.t.

subtest 'Bind' => sub {
  is_deeply [ $class->check_declarations('Bind') ], [],
    'the conformance declarations are whole';

  ok $class->conformance_answered_through->{Bind} <= $class->table_version('Bind'),
    'the driver does not claim a Bind table version newer than core has';

  is $class->conformance_answered_through->{Bind}, $class->table_version('Bind'),
    'the driver answers the Bind table as it stands';
};

done_testing;
