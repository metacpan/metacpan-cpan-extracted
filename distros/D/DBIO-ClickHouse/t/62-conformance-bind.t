use strict;
use warnings;
use Test::More;

use DBIO::ClickHouse::Test::Conformance;

# WHY: the declarations of the driver's half of the Bind conformance table are
# checked without a server (karr k43): every refusal names a case, and the
# answered table version is a number. The cases themselves run in
# t/62-conformance-bind-live.t.

my $class = 'DBIO::ClickHouse::Test::Conformance';

is_deeply [ $class->check_declarations('Bind') ], [],
  'the conformance declarations of the Bind list are whole';

is scalar(@{ $class->cases('Bind') }), 10, 'the Bind table has its ten cases';

my $through = $class->conformance_answered_through;
is $through->{Bind}, 1, 'the driver answers the Bind list through version 1';
ok !grep({ $through->{$_} > $class->table_version($_) } keys %$through),
  'the driver does not claim a table version newer than core has';

done_testing;
