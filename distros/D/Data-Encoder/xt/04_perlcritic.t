use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_PERLCRITIC}) {
    plan skip_all => "\$ENV{TEST_PERLCRITIC} is not set.";
    exit;
}

eval {
    require Test::Perl::Critic;
    Test::Perl::Critic->import( -profile => 'xt/perlcriticrc');
};
plan skip_all => "Test::Perl::Critic is not installed." if $@;

all_critic_ok('lib');
