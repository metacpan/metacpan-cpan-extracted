use strict;
use warnings;
use Test::More;

use DBIO::ClickHouse::Test::Conformance;

my $class = 'DBIO::ClickHouse::Test::Conformance';

subtest 'DDL' => sub {

  # WHY: the declarations of the driver's half of the conformance table are
  # checked without a server (karr k43): every refusal names a case, and the
  # answered table version is a number. The cases themselves run in
  # t/60-conformance-ddl-live.t.

  is_deeply [ $class->check_declarations('DDL') ], [],
    'the conformance declarations are whole';

  is scalar(@{ $class->cases('DDL') }), 20, 'the DDL table has its twenty cases';

  my $through = $class->conformance_answered_through;
  is $through->{DDL}, 2, 'the driver answers the DDL list through version 2';
  ok !grep({ $through->{$_} > $class->table_version($_) } keys %$through),
    'the driver does not claim a table version newer than core has';
};

subtest 'Diff' => sub {

  # WHY: the declarations of the driver's half of the Diff conformance table are
  # checked without a server (karr k43): every refusal names a case, and the
  # answered table version is a number. The cases themselves run in
  # t/61-conformance-diff-live.t.

  is_deeply [ $class->check_declarations('Diff') ], [],
    'the conformance declarations are whole';

  is scalar(@{ $class->cases('Diff') }), 23, 'the Diff table has its 23 cases';

  my $through = $class->conformance_answered_through;
  is $through->{Diff}, 4, 'the driver answers the Diff list through version 4';
  ok !grep({ $through->{$_} > $class->table_version($_) } keys %$through),
    'the driver does not claim a table version newer than core has';
};

subtest 'Bind' => sub {

  # WHY: the declarations of the driver's half of the Bind conformance table are
  # checked without a server (karr k43): every refusal names a case, and the
  # answered table version is a number. The cases themselves run in
  # t/62-conformance-bind-live.t.

  is_deeply [ $class->check_declarations('Bind') ], [],
    'the conformance declarations of the Bind list are whole';

  is scalar(@{ $class->cases('Bind') }), 10, 'the Bind table has its ten cases';

  my $through = $class->conformance_answered_through;
  is $through->{Bind}, 1, 'the driver answers the Bind list through version 1';
  ok !grep({ $through->{$_} > $class->table_version($_) } keys %$through),
    'the driver does not claim a table version newer than core has';
};

done_testing;
