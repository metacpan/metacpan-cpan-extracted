#!perl

# =========================================================================== #
#
# All these tests are stolen from CSS::Minifier
#
# =========================================================================== #

use Test::More;
use Test::File::Contents;

my $not = 17;

SKIP: {
    eval( 'use CSS::Packer' );

    skip( 'CSS::Packer not installed!', $not ) if ( $@ );

    plan tests => $not;

    minTest( 's1', { compress => 'pretty' } );
    minTest( 's2', { compress => 'pretty' } );
    minTest( 's3', { compress => 'minify' } );
    minTest( 's4', { compress => 'minify' } );
    minTest( 's5', { compress => 'minify' } );
    minTest( 's6', { compress => 'minify' } );
    minTest( 's7', { compress => 'minify', no_compress_comment => 1 } );
    minTest( 's8', { compress => 'minify' } );

    my $packer = CSS::Packer->init();

    my $var = "foo {\na : b;\n}";
    $packer->minify( \$var, { 'compress' => 'minify' } );
    is( $var, 'foo{a:b;}', 'string literal input and ouput (minify)' );
    $var = "foo {\na : b;\n}";
    $packer->minify( \$var, { 'compress' => 'pretty' } );
    is( $var, "foo{\na:b;\n}\n", 'string literal input and ouput (pretty)' );
    $var = "foo {\nborder:0;\nmargin:1;\npadding:0\n}";
    $packer->minify( \$var, { 'compress' => 'minify' } );
    is( $var, "foo{border:0;margin:1;padding:0;}", 'string literal input and ouput (minify)' );

    $var = "foo {\nborder:0;\nmargin:1;\npadding:0\n}";
    $packer->compress( 'pretty' );
    $packer->copyright( 'BSD' );
    $packer->minify( \$var );
    is( $var, '/* BSD */' . "\nfoo{\nborder:0;\nmargin:1;\npadding:0;\n}\n", 'copyright option compression level "pretty"' );
    $packer->compress( 'minify' );
    $packer->minify( \$var );
    is( $var, '/* BSD */' . "\n" . 'foo{border:0;margin:1;padding:0;}', 'copyright option compression level "minify"' );

    $packer = CSS::Packer->init();

    $var = "/* Copyright BSD */foo {\nborder:0;\nmargin:1;\npadding:0\n}";
    $packer->minify( \$var, { remove_copyright => 1 } );
    is( $var, "foo{\nborder:0;\nmargin:1;\npadding:0;\n}\n", 'copyright comment with remove_copyright option');

    $var = "/* Copyright BSD */foo {\nborder:0;\nmargin:1;\npadding:0\n}";
    $packer->minify( \$var, { remove_copyright => 0 } );
    is( $var, '/* Copyright BSD */' . "\n" . "foo{\nborder:0;\nmargin:1;\npadding:0;\n}\n", 'copyright comment without remove_copyright option');

    $packer = CSS::Packer->init();

    $var = "/* CSS::Packer _no_compress_ */\nfoo {\nborder:0;\nmargin:1;\npadding:0\n}";
    $packer->minify( \$var );
    is( $var, "/* CSS::Packer _no_compress_ */\nfoo {\nborder:0;\nmargin:1;\npadding:0\n}", '_no_compress_ comment');

    $var = "/* CSS::Packer _no_compress_ */\nfoo {\nborder:0;\nmargin:1;\npadding:0\n}";
    $packer->minify( \$var, { no_compress_comment => 1 } );
    is( $var, "foo{\nborder:0;\nmargin:1;\npadding:0;\n}\n", '_no_compress_ comment with no_compress_comment option');
}

sub minTest {
    my $filename    = shift;
    my $opts        = shift || {};

    open(INFILE, 't/stylesheets/' . $filename . '.css') or die("couldn't open file");
    open(GOTFILE, '>t/stylesheets/' . $filename . '-got.css') or die("couldn't open file");

    my $css = join( '', <INFILE> );

    my $packer = CSS::Packer->init();

    $packer->minify( \$css, $opts );

    print GOTFILE $css;
    close(INFILE);
    close(GOTFILE);

	files_eq_or_diff(
		't/stylesheets/' . $filename . '-got.css',
		't/stylesheets/' . $filename . '-expected.css',
		{ style => 'Unified' }
	);

	return;
}
