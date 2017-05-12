use strict;
use Test::More;

#plan skip_all => 'set TEST_CRITIC to enable this test' unless $ENV{TEST_CRITIC};
eval{
    require Test::Perl::Critic;
    Test::Perl::Critic->import(-profile => "xt/perlcriticrc");
};

plan skip_all => "Test::Perl::Critic is not installed." if $@;

all_critic_ok('lib');
