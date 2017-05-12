#!perl
use lib 'lib';
use Test::More tests => 6;

BEGIN {
	use_ok( 'CairoX::CuttingLine' );
}

diag( "Testing CairoX::CuttingLine $CairoX::CuttingLine::VERSION, Perl $], $^X" );

use Cairo;
use CairoX::CuttingLine;

my $surf = Cairo::ImageSurface->create( 'argb32', 300, 300 );
my $cr = Cairo::Context->create($surf);

ok( $surf );
ok( $cr );

my $page = CairoX::CuttingLine->new( $cr );
$page->line_width( 2 );
$page->set( x => 10 , y => 10 );
$page->size( width => 200 , height => 200 );

my $size = $page->size;
is( $size->{width} , 200 );
is( $size->{height} , 200 );

$page->length( 10 );
is( $page->length , 10  );

$page->color( 0,0,1,1 );

$page->stroke;

open FH, '>' , 'test.png';
$surf->write_to_png_stream( sub { 
    print FH $_[1] or die('surface png stream write error'); 
});
close FH;
# system( q{ open 'test.png' } );
