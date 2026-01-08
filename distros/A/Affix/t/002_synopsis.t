use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
#
ok my $libm = libm(),                                   'my $libm = libm()';
ok affix( $libm, 'pow', [ Double, Double ] => Double ), q[affix $libm, 'pow', [Double, Double] => Double];
is pow( 2.0, 10.0 ), 1024, 'pow(2.0, 10.0)';
#
ok typedef( xRect => Struct [ x => Int, y => Int, w => Int, h => Int ] ), 'typedef Rect => Struct[ ... ]';
note 'we skip `draw_rect( { x => 10, y => 10, w => 100, h => 50 } );` because we do not build libs here (yet) to affix';
ok my $rect_ptr = calloc( 1, xRect() ),             'my $rect_ptr = calloc(1, Rect())';
ok my $ptr_x    = cast( $rect_ptr, Pointer [Int] ), 'my $ptr_x = cast( $rect_ptr, Pointer[Int] )';
note 'we also skip the dereference stuff because, yeah, yeah... no lib is built here';
#
done_testing;
