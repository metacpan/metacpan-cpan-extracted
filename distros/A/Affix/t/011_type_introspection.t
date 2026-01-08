use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
#
my $size_of_int = sizeof(Int32);
is $size_of_int, 4, 'sizeof(int32)';
#
ok typedef( Point => Struct [ x => Int, y => Int ] ), 'typedef Point => Struct[ ... ]';
ok typedef( Rect => Struct [ x => Int, y => Int, w => Int, h => Int ] ), 'typedef Rect => Struct[ ... ]';
#
is sizeof( Rect() ),         $size_of_int * 4, 'sizeof works correctly on complex named types';
is alignof(Int32),           4,                'alignof(Int32)';
is alignof( Point() ),       4,                'alignof(Point)';
is offsetof( Point(), 'x' ), 0,                'offsetof(Point, x)';
is offsetof( Point(), 'y' ), 4,                'offsetof(Point, y)';

# Test with Affix::Type object directly
my $struct = Struct [ a => SInt8, b => SInt32 ];    # { int8, pad(3), int32 } -> size 8, align 4
is sizeof($struct),          8, 'sizeof(Struct object) with padding';
is alignof($struct),         4, 'alignof(Struct object)';
is offsetof( $struct, 'a' ), 0, 'offsetof(object, a)';
is offsetof( $struct, 'b' ), 4, 'offsetof(object, b)';
like warning { offsetof( $struct, 'missing' ) }, qr/Member 'missing' not found/, 'offsetof missing member';
like warning { offsetof( Int,     'x' ) },       qr/expects a Struct or Union/,  'offsetof invalid type';
#
done_testing;
