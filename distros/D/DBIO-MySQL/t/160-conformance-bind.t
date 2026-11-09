use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Test::Conformance;

# WHY: the declarations of the driver's half of the Bind list are checked
# without a server (karr k120). The cases run in t/161-conformance-bind-live.t.

my $class = 'DBIO::MySQL::Test::Conformance';

is_deeply [ $class->check_declarations('Bind') ], [],
  'the conformance declarations of the Bind list are whole';

ok scalar(@{ $class->cases('Bind') }) > 0, 'the Bind table has cases';

my $through = $class->conformance_answered_through;
is $through->{Bind}, $class->table_version('Bind'),
  'the driver answers the Bind list through the version core has';

done_testing;
