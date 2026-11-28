use strict;
use Test::More;
eval {
    require Test::Perl::Critic;
    Test::Perl::Critic->import( -profile => 'xt/perlcriticrc');
};
if ( my $error = $@ ) {
    # In CI (the author job of ci.yml), Test::Perl::Critic is installed on purpose: fail instead of
    # skipping, so that the job does not pass without running Perl::Critic.
    die "Test::Perl::Critic cannot be loaded: $error" if $ENV{CI};
    plan skip_all => "Test::Perl::Critic is not installed.";
}
all_critic_ok('lib');
