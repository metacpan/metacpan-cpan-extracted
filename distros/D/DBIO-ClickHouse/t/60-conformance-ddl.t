use strict;
use warnings;
use Test::More;

use DBIO::ClickHouse::Test::Conformance;

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k43): every refusal names a case, and the
# answered table version is a number. The cases themselves run in
# t/60-conformance-ddl-live.t.

my $class = 'DBIO::ClickHouse::Test::Conformance';

is_deeply [ $class->check_declarations('DDL') ], [],
  'the conformance declarations are whole';

is scalar(@{ $class->cases('DDL') }), 20, 'the DDL table has its twenty cases';

my $through = $class->conformance_answered_through;
is $through->{DDL}, 2, 'the driver answers the DDL list through version 2';
ok !grep({ $through->{$_} > $class->table_version($_) } keys %$through),
  'the driver does not claim a table version newer than core has';

done_testing;
