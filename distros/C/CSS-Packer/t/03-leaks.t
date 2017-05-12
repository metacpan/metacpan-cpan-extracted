#!perl

use strict;
use warnings;

use Test::More;
use CSS::Packer; 

if (! eval "use Test::Memory::Cycle; 1;" ) {
	plan skip_all => 'Test::Memory::Cycle required for this test';
}

my $packer = CSS::Packer->init;
memory_cycle_ok( $packer );

my $css = '
html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, b, u, i, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td, article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, menu, nav, output, ruby, section, summary, time, mark, audio, video {
margin : 0;
padding : 0;
border : 0;
font-size : 100%;
font : inherit;
vertical-align : baseline;
}
';

for ( 1 .. 5 ) { 
	ok( $packer->minify( \$css,{} ),'minify' );
}

memory_cycle_ok( $packer );
done_testing();
