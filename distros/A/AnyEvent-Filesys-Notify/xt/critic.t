use strict;
use warnings;
use Test::More;
use File::Spec;

# plan( skip_all => 'Author test. Set TEST_AUTHOR to a true value to run.' )
#   unless $ENV{TEST_AUTHOR};

eval { require Test::Perl::Critic; };
plan( skip_all => ' Test::Perl::Critic required to criticise code ' ) if $@;

my $rcfile = File::Spec->catfile( 'xt', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile, -severity => 3 );
all_critic_ok();

