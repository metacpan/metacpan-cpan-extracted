use strict;
use Test::More;

eval q{
    use Test::Perl::Critic -exclude => [
        'TestingAndDebugging::ProhibitNoStrict',
    ]
};
plan skip_all => "Test::Perl::Critic is not installed." if $@;
all_critic_ok('lib');
