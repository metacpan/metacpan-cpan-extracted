use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
#
$|++;
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

#include <stdint.h>
#include <stdbool.h>

typedef enum {
    MODE_READ  = 0,
    MODE_WRITE = 1,
    MODE_EXEC  = 2
} FileMode;

DLLEXPORT int check_mode(FileMode m) { return m; }
DLLEXPORT FileMode next_mode(FileMode m) { return (m + 1) % 3; }

DLLEXPORT char get_char_val(void) { return 42; }
DLLEXPORT int verify_char_range(signed char v) { return (v >= -128 && v <= 127) ? 1 : 0; }

DLLEXPORT unsigned int get_uint_val(void) { return 300; }
DLLEXPORT int verify_uint(unsigned int v) { return (v == 300) ? 1 : 0; }
END_C
#
my $lib = compile_ok($C_CODE);
ok( $lib && -e $lib, 'Compiled shared library' );
#
subtest 'IntEnum -- same as Enum' => sub {
    typedef Mode => Affix::IntEnum [ [ MODE_READ => 0 ], [ MODE_WRITE => 1 ], [ MODE_EXEC => 2 ] ];

    # Use affix to install into current package (avoids bareword issues)
    affix $lib, 'check_mode', ['@Mode'] => Int;
    affix $lib, 'next_mode',  ['@Mode'] => '@Mode';
    is MODE_READ(),                0, 'MODE_READ constant is 0';
    is MODE_WRITE(),               1, 'MODE_WRITE constant is 1';
    is MODE_EXEC(),                2, 'MODE_EXEC constant is 2';
    is check_mode( MODE_READ() ),  0, 'check_mode(MODE_READ) returns 0';
    is check_mode( MODE_WRITE() ), 1, 'check_mode(MODE_WRITE) returns 1';
    is check_mode( MODE_EXEC() ),  2, 'check_mode(MODE_EXEC) returns 2';
    my $next_state = next_mode( MODE_READ() );
    is $next_state + 0, 1, 'next_mode(MODE_READ) numerically equals 1';
};
#
subtest 'CharEnum -- 1-byte signed char' => sub {
    typedef SmallMode => Affix::CharEnum [ [ SM_OFF => 0 ], [ SM_ON => 1 ], [ SM_MAX => 127 ] ];
    is sizeof( SmallMode() ), 1, 'CharEnum is 1 byte';
    affix $lib, 'get_char_val',      []     => Char;
    affix $lib, 'verify_char_range', [Char] => Bool;
    is get_char_val(), 42, 'get_char_val() returns 42 (fits in char)';
    ok verify_char_range( 42),  'char 42 is in range';
    ok verify_char_range(-128), 'char -128 is in range';
    ok verify_char_range( 127), 'char 127 is in range';
};
#
subtest 'UIntEnum -- unsigned int' => sub {
    typedef UMode => Affix::UIntEnum [ [ UOFF => 0 ], [ UON => 1 ], [ UMAX => 4294967295 ] ];
    is sizeof( UMode() ), 4,          'UIntEnum is 4 bytes (unsigned int)';
    is UOFF(),            0,          'UOFF constant is 0';
    is UMAX(),            4294967295, 'UMAX constant is 2^32-1';
    affix $lib, 'get_uint_val', []     => UInt;
    affix $lib, 'verify_uint',  [UInt] => Bool;
    is get_uint_val(), 300, 'get_uint_val() returns 300';
    ok verify_uint(300), 'verify_uint(300) returns true';
};
#
subtest 'CharEnum -- negative values' => sub {
    typedef SByte => Affix::CharEnum [ [ NEG_MAX => -128 ], [ NEG_MID => -1 ], [ ZERO => 0 ], [ POS_MID => 1 ], [ POS_MAX => 127 ] ];
    is NEG_MAX(), -128, 'CharEnum NEG_MAX is -128';
    is NEG_MID(), -1,   'CharEnum NEG_MID is -1';
    is ZERO(),     0,   'CharEnum ZERO is 0';
    is POS_MID(),  1,   'CharEnum POS_MID is 1';
    is POS_MAX(),  127, 'CharEnum POS_MAX is 127';
};
#
done_testing;
