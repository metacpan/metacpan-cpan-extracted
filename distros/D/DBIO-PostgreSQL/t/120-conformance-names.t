use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Test::Conformance;

# WHY: the declarations of the driver's half of the Names list (core ADR 0077,
# karr dbio k391) are checked without a server: the kinds the driver has are
# declared, the answered table version is the one core has, and no refusal is
# declared for the list (a refusal is one of its answers). The cases run in
# t/120-conformance-names-live.t.

my $class = 'DBIO::PostgreSQL::Test::Conformance';

is_deeply [ $class->check_declarations('Names') ], [],
  'the conformance declarations are whole';

my $cases = $class->cases('Names');
my %kinds = map { $_->{input}{kind} => 1 } @$cases;
ok scalar(@$cases) >= 18, 'the Names table has its cases (six names for each of three kinds in table version 1)';

my $declared = $class->conformance_name_kinds;
is_deeply [ sort keys %$declared ], [qw( extension schema )],
  'the driver has the schema and the extension; no library (a library is a file, and nothing lists a loaded one)';
ok !grep({ !$kinds{$_} } keys %$declared), 'both are kinds of the table';

is $class->conformance_answered_through->{Names}, $class->table_version('Names'),
  'the driver answers the Names list through the version core has';

ok $class->can('conformance_apply_name') != DBIO::Test::Conformance->can('conformance_apply_name'),
  'the seam of the list is bound';

done_testing;
