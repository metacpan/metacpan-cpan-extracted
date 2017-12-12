use strict;
use warnings;

use File::Spec;
use Test::More;

use English qw(-no_match_vars);

eval { require Test::PerlTidy; };

if ( $EVAL_ERROR ) {
   plan( skip_all => 'Test::PerlTidy required to test code style' );
}

my $rcfile = File::Spec->catfile( 'xt', 'perltidyrc' );
Test::PerlTidy::run_tests( perltidyrc => $rcfile, path => './lib' );
