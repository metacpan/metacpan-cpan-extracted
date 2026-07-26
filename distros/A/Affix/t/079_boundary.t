use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
use Config;
$|++;
my $lib = compile_ok(<<~'');
    #include "std.h"
    DLLEXPORT int8_t echo_i8(int8_t v) { return v; }
    DLLEXPORT uint8_t echo_u8(uint8_t v) { return v; }
    DLLEXPORT int16_t echo_i16(int16_t v) { return v; }
    DLLEXPORT uint16_t echo_u16(uint16_t v) { return v; }
    DLLEXPORT int32_t echo_i32(int32_t v) { return v; }
    DLLEXPORT uint32_t echo_u32(uint32_t v) { return v; }
    DLLEXPORT int64_t echo_i64(int64_t v) { return v; }
    DLLEXPORT uint64_t echo_u64(uint64_t v) { return v; }
    DLLEXPORT float echo_float(float v) { return v; }
    DLLEXPORT double echo_double(double v) { return v; }
    DLLEXPORT int echo_int(int v) { return v; }
//ext: .c

#
subtest 'Int32 boundaries' => sub {
    my $fn = wrap( $lib, 'echo_i32', [SInt32], SInt32 );
    is $fn->( 0),           0,          'Int32 zero';
    is $fn->( 1),           1,          'Int32 one';
    is $fn->(-1),          -1,          'Int32 negative one';
    is $fn->( 2147483647),  2147483647, 'Int32 max';
    is $fn->(-2147483648), -2147483648, 'Int32 min';
};
#
subtest 'UInt32 boundaries' => sub {
    my $fn = wrap( $lib, 'echo_u32', [UInt32], UInt32 );
    is $fn->(0),          0,          'UInt32 zero';
    is $fn->(4294967295), 4294967295, 'UInt32 max';
    is $fn->(1),          1,          'UInt32 one';
};
#
subtest 'Int8 boundaries' => sub {
    my $fn = wrap( $lib, 'echo_i8', [SInt8], SInt8 );
    is $fn->( 0),    0,   'Int8 zero';
    is $fn->( 127),  127, 'Int8 max';
    is $fn->(-128), -128, 'Int8 min';
};
#
subtest 'UInt8 boundaries' => sub {
    my $fn = wrap( $lib, 'echo_u8', [UInt8], UInt8 );
    is $fn->(0),   0,   'UInt8 zero';
    is $fn->(255), 255, 'UInt8 max';
};
#
subtest 'Int16 boundaries' => sub {
    my $fn = wrap( $lib, 'echo_i16', [SInt16], SInt16 );
    is $fn->( 0),      0,     'Int16 zero';
    is $fn->( 32767),  32767, 'Int16 max';
    is $fn->(-32768), -32768, 'Int16 min';
};
#
subtest 'Float boundaries' => sub {
    my $fn = wrap( $lib, 'echo_float', [Float], Float );
    is $fn->( 0.0), float( 0.0), 'Float zero';
    is $fn->(-0.0), float(-0.0), 'Float negative zero';
    ok abs( $fn->(1.0) - 1.0 ) < 1e-6,  'Float one';
    ok abs( $fn->(-1.0) + 1.0 ) < 1e-6, 'Float negative one';
};
#
subtest 'Double boundaries' => sub {
    my $fn = wrap( $lib, 'echo_double', [Double], Double );
    is $fn->( 0.0), float( 0.0), 'Double zero';
    is $fn->( 1.0), float( 1.0), 'Double one';
    is $fn->(-1.0), float(-1.0), 'Double negative one';
};
#
subtest 'Int64 boundaries' => sub {
    my $fn = wrap( $lib, 'echo_i64', [SInt64], SInt64 );
    is $fn->( 0),                    0,                   'Int64 zero';
    is $fn->( 9223372036854775807),  9223372036854775807, 'Int64 max';
    is $fn->(-9223372036854775808), -9223372036854775808, 'Int64 min';
};
#
subtest 'UInt64 boundaries' => sub {
    my $fn = wrap( $lib, 'echo_u64', [UInt64], UInt64 );
    is $fn->(0),                    0,                    'UInt64 zero';
    is $fn->(18446744073709551615), 18446744073709551615, 'UInt64 max';
};
#
subtest 'sizeof matches expected sizes' => sub {
    is sizeof(SInt8),  1, 'sizeof SInt8 = 1';
    is sizeof(UInt8),  1, 'sizeof UInt8 = 1';
    is sizeof(SInt16), 2, 'sizeof SInt16 = 2';
    is sizeof(UInt16), 2, 'sizeof UInt16 = 2';
    is sizeof(SInt32), 4, 'sizeof SInt32 = 4';
    is sizeof(UInt32), 4, 'sizeof UInt32 = 4';
    is sizeof(SInt64), 8, 'sizeof SInt64 = 8';
    is sizeof(UInt64), 8, 'sizeof UInt64 = 8';
    is sizeof(Float),  4, 'sizeof Float = 4';
    is sizeof(Double), 8, 'sizeof Double = 8';
};
#
subtest 'Struct size and alignment' => sub {
    my $s = Struct [ a => Int8, b => Int32, c => Int8 ];
    ok sizeof($s) >= 6, 'Struct with padding has size >= sum of members';
};
done_testing;
