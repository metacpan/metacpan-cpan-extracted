use strict;
use warnings;

use File::Spec;
use FindBin ();
use Test::More;

plan skip_all => 'developer test'
    if not -d '.svn';

plan skip_all => 'requires Test::Perl::Critic'
    if not eval { require Test::Perl::Critic };

my $rcfile = File::Spec->catfile( 't', '04critic.rc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();
