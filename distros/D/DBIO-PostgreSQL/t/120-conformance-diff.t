use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Test::Conformance;
use DBIO::Test::Conformance;

# WHY: the declarations of the driver's half of the Diff list are checked
# without a server (karr k150): every refusal names a case, and the answered
# table version is a number. The cases themselves run in
# t/120-conformance-diff-live.t.

my $class = 'DBIO::PostgreSQL::Test::Conformance';

is_deeply [ $class->check_declarations('Diff') ], [],
  'the conformance declarations are whole';

my %name = map { $_->{name} => 1 } @{ $class->cases('Diff') };
my @deploy = qw( diff-deploy-inherited diff-deploy-dry-run diff-deploy-destructive-guard );
ok scalar(grep { $name{$_} } @deploy) == @deploy, 'the table holds the three deploy cases';
ok scalar(keys %name) >= 23, 'the Diff table has its cases (23 in table version 4), none dropped';

my $through = $class->conformance_answered_through;
is $through->{Diff}, $class->table_version('Diff'),
  'the driver answers the Diff list through the version core has';

ok $class->can('conformance_deploy') && $class->can('conformance_deploy') != DBIO::Test::Conformance->can('conformance_deploy'),
  'the seam of the deploy cases is bound: they run, they are not "not applicable"';
my $refused = $class->conformance_refusals;
is_deeply [ grep { $refused->{$_} } @deploy ], [],
  'none of the deploy cases is declared refused: they run';

done_testing;
