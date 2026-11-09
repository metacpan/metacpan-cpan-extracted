use strict;
use warnings;
use Test::More;

use DBIO::Oracle::Test::Conformance;

# OFFLINE (karr k63, core ADR 0060). The driver's half of the shared Bind case
# table, as far as it can be checked without a server: the declarations are
# whole, the answered table version of the Bind area is the core's, and the
# Bind list is declared by deviations only -- a Bind case is a value that goes
# through the bind path and comes back, so there is no refusal the driver
# throws before the server is asked. Two cases are declared (bind-empty-string,
# bind-numeric-exact); the other eight run correctly. What the server makes of
# the values is t/89-conformance-bind-live.t.

my $class = 'DBIO::Oracle::Test::Conformance';

is_deeply [ $class->check_declarations('Bind') ], [],
  'the conformance declarations are whole';

my $cases = $class->cases('Bind');
is scalar(@$cases), 10, 'the Bind table has its ten cases';

is $class->conformance_answered_through->{Bind}, $class->table_version('Bind'),
  'every case of the Bind table is answered';

is_deeply $class->conformance_answered_through,
  { DDL => 2, Diff => $class->table_version('Diff'), Bind => $class->table_version('Bind') },
  'the answers are given per area';

my $refusals = $class->conformance_refusals;
my %known    = map { $_->{name} => 1 } @$cases;
my @bind     = grep { /\Abind-/ } sort keys %$refusals;

is_deeply [ grep { !$known{$_} } @bind ], [],
  'every declared Bind answer names a case of the table';

is_deeply [ grep { $refusals->{$_}{kind} ne 'deviation' } @bind ], [],
  'the Bind answers are deviations (the server\'s behaviour, taken as it is)';

is_deeply [ @bind ], [qw(bind-empty-string bind-numeric-exact)],
  'two Bind cases are declared; bind-non-ascii and bind-question-mark-in-literal are not (they run)';

for my $name (@bind) {
  like $refusals->{$name}{reason}, qr/\S/, "$name: the deviation says why";
}

done_testing;
