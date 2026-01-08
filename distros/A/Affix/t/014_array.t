use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
#
# This C code will be compiled into a temporary library for many of the tests.
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

DLLEXPORT char get_char_at(char s[20], int index) {
    // warn("# get_char_at('%s', %d);", s, index);
    if (index >= 20 || index < 0) return '!';
    return s[index];
}

DLLEXPORT float sum_float_array(float* arr, int len) {
    float total = 0.0f;
    for (int i = 0; i < len; i++)
        total += arr[i];
    return total;
}

DLLEXPORT int sum_array_static(int arr[5]) {
    int sum = 0;
    for(int i=0; i<5; i++) sum += arr[i];
    return sum;
}

END_C
#
my $lib_path = compile_ok($C_CODE);
ok( $lib_path && -e $lib_path, 'Compiled a test shared library successfully' );
#
affix $lib_path, 'get_char_at', '([20:char], int)->char';
my $str = "Perl";
is( chr( get_char_at( $str, 0 ) ), 'P', 'Passing string to char[N] works (char 0)' );
is( get_char_at( $str, 4 ),        0,   'Passing string to char[N] is null-terminated' );
my $long_str = "This is a very long string that will be truncated";
is( chr( get_char_at( $long_str, 18 ) ), 'g', 'Truncated string char 18 is correct' );
is( get_char_at( $long_str, 19 ),        0,   'Truncated string is null-terminated at the boundary' );
ok affix( $lib_path, 'sum_float_array', '(*float, int)->float' ), 'affix sum_float_array';
my $floats = [ 1.1, 2.2, 3.3 ];
is( sum_float_array( $floats, 3 ), float( 6.6, tolerance => 0.01 ), 'Correctly summed an array of floats' );
#
isa_ok my $sum_arr = wrap( $lib_path, 'sum_array_static', [ Array [ Int, 5 ] ] => Int ), ['Affix'];
is $sum_arr->( [ 1, 2, 3, 4, 5 ] ), 15, 'Fixed size array passed by value';
#
subtest 'Fixed Array Binary Safety' => sub {
    my $ptr = calloc( 5, Int8 );                   # Allocate 5 bytes
    my $mem = cast( $ptr, Array [ Int8, 5 ] );     # Write: "A \0 B \0 C"
    $$mem = [ 65, 0, 66, 0, 67 ];                  # We can write using an array ref (slow path, verify write works)
    my $view = cast( $ptr, Array [ Char, 5 ] );    # Now read it back as a char array (fast path)
    my $data = $$view;
    is length($data), 5,         'Binary string has correct length (5)';
    is $data,         "A\0B\0C", 'Binary content preserved (nulls included)';
    free($ptr);
};
done_testing;
