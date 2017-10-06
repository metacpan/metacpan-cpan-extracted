#!perl

use Test::More;
use Authen::U2F u2f_challenge;

my $challenge = u2f_challenge;

ok $challenge, "generated a challenge";

done_testing;
