use strict;
use warnings;

use File::Spec;
use FindBin;
use English qw(-no_match_vars);
use Test::More;

plan skip_all => 'Author test.  Set AUTHOR_TESTING=1 to run.'
    unless $ENV{AUTHOR_TESTING};

eval "use Test::Perl::Critic";
plan skip_all => 'Test::Perl::Critic required for author critic test' if $@;

my $rcfile = File::Spec->catfile( $FindBin::RealBin, 'etc', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok( "$FindBin::RealBin/../lib", "$FindBin::RealBin/unit" );
