use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Test::Conformance;

my $class = 'DBIO::MySQL::Test::Conformance';

my $through = $class->conformance_answered_through;

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k120): every refusal names a case, and the
# answered table version is a number. The cases themselves run in
# t/157-conformance-ddl-live.t.

subtest 'DDL' => sub {
  is_deeply [ $class->check_declarations('DDL') ], [],
    'the conformance declarations are whole';

  is scalar(@{ $class->cases('DDL') }), 20, 'the DDL table has its twenty cases';

  is $through->{DDL}, 2, 'the driver answers the DDL list through version 2';
  ok !grep({ $through->{$_} > $class->table_version($_) } keys %$through),
    'the driver does not claim a table version newer than core has';

  done_testing;
};

# WHY: the declarations of the driver's half of the Diff list are checked
# without a server (karr k120): every refusal names a case, and the answered
# table version is a number. The cases run in t/159-conformance-diff-live.t.

subtest 'Diff' => sub {
  is_deeply [ $class->check_declarations('Diff') ], [],
    'the conformance declarations of the Diff list are whole';

  ok scalar(@{ $class->cases('Diff') }) > 0, 'the Diff table has cases';

  is $through->{Diff}, $class->table_version('Diff'),
    'the driver answers the Diff list through the version core has';

  done_testing;
};

# WHY: the declarations of the driver's half of the Bind list are checked
# without a server (karr k120). The cases run in t/161-conformance-bind-live.t.

subtest 'Bind' => sub {
  is_deeply [ $class->check_declarations('Bind') ], [],
    'the conformance declarations of the Bind list are whole';

  ok scalar(@{ $class->cases('Bind') }) > 0, 'the Bind table has cases';

  is $through->{Bind}, $class->table_version('Bind'),
    'the driver answers the Bind list through the version core has';

  done_testing;
};

done_testing;
