#!perl -T

use Algorithm::Bayesian;
use Test::More;

my %hash;
my $s = Algorithm::Bayesian->new(\%hash);

my @hams = qw/ham1 ham2 ham3 ham4 ham5 ham6 ham7 ham8 ham9 ham10/;
my @spams = qw/spam1 spam2 spam3 spam4 spam5 spam6 spam7 spam8 spam9 spam10/;

$s->ham(@hams);
$s->spam(@spams);

ok($s->testWord('spam1') > 0.5);
ok($s->testWord('ham1') < 0.5);

ok($s->test(@spams) != 0);
ok($s->test(@hams) != 0);

done_testing;
