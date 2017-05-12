use strict;
use warnings;
use Test::More;
use Test::Requires { 'Test::Perl::Critic' => 1.02 };

unless ($ENV{TEST_PERLCRITIC}) {
    plan skip_all => "\$ENV{TEST_PERLCRITIC} is not set.";
    exit;
}

Test::Perl::Critic->import( -profile => 'xt/perlcriticrc');

all_critic_ok('lib');
