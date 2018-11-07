#!perl

# =========================================================================== #
#
# All these tests are stolen from CSS::Minifier
#
# =========================================================================== #

use Test::More;
use Test::File::Contents;

my $not = 2;

SKIP: {
    eval( 'use CSS::Packer' );

    skip( 'CSS::Packer not installed!', $not ) if ( $@ );

    plan tests => $not;

    minTest( 's1', { compress => 'pretty', indent => 4 } );
    minTest( 's2', { compress => 'pretty', indent => 4 } );
}

sub minTest {
    my $filename    = shift;
    my $opts        = shift || {};

    open(INFILE, "t/stylesheets/$filename.css") or die("couldn't open file");
    open(GOTFILE, ">t/stylesheets/$filename-got.css") or die("couldn't open file");

    my $css = join( '', <INFILE> );

    my $packer = CSS::Packer->init();

    $packer->minify( \$css, $opts );

    print GOTFILE $css;
    close(INFILE);
    close(GOTFILE);

	files_eq_or_diff(
		"t/stylesheets/$filename-got.css",
		"t/stylesheets/$filename-expected-indent.css",
		{ style => 'Unified' }
	);

	return;
}
