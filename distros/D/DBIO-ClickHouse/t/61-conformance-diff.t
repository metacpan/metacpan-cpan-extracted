use strict;
use warnings;
use Test::More;

use DBIO::ClickHouse::Test::Conformance;

# WHY: the declarations of the driver's half of the Diff conformance table are
# checked without a server (karr k43): every refusal names a case, and the
# answered table version is a number. The cases themselves run in
# t/61-conformance-diff-live.t.

my $class = 'DBIO::ClickHouse::Test::Conformance';

is_deeply [ $class->check_declarations('Diff') ], [],
  'the conformance declarations are whole';

is scalar(@{ $class->cases('Diff') }), 23, 'the Diff table has its 23 cases';

my $through = $class->conformance_answered_through;
is $through->{Diff}, 4, 'the driver answers the Diff list through version 4';
ok !grep({ $through->{$_} > $class->table_version($_) } keys %$through),
  'the driver does not claim a table version newer than core has';

done_testing;
