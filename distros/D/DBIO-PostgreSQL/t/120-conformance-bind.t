use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Test::Conformance;

# WHY: the declarations of the driver's half of the Bind list are checked
# without a server (karr k150): every refusal names a case, and the answered
# table version is a number. The cases themselves run in
# t/120-conformance-bind-live.t.

my $class = 'DBIO::PostgreSQL::Test::Conformance';

is_deeply [ $class->check_declarations('Bind') ], [],
  'the conformance declarations are whole';

is scalar(@{ $class->cases('Bind') }), 10, 'the Bind table has its ten cases';

my $through = $class->conformance_answered_through;
is $through->{Bind}, 1, 'the driver answers the Bind list through version 1';
ok $through->{Bind} <= $class->table_version('Bind'),
  'the driver does not claim a Bind table version newer than core has';

done_testing;
