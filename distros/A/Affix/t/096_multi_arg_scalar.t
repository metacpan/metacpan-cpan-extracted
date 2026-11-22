use v5.40;
use blib;
use B ();
use Config;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
my $lib = compile_ok(<<~'');
    #include "std.h"
    static double   g_last_double = 0.0;
    static int32_t  g_last_i32    = 0;
    static uint32_t g_last_u32    = 0;
    static int32_t  g_void_calls  = 0;
    DLLEXPORT int32_t add_i32(int32_t a, int32_t b) { return a + b; }
    DLLEXPORT int32_t sub_i32(int32_t a, int32_t b) { return a - b; }
    DLLEXPORT double add_double(double a, double b) { return a + b; }
    DLLEXPORT double mul_double(double a, double b) { return a * b; }
    DLLEXPORT uint32_t twice_u32(uint32_t a) { return a * 2u; }
    DLLEXPORT float twice_f32(float a) { return a * 2.0f; }
    DLLEXPORT uint32_t add_u32(uint32_t a, uint32_t b) { return a + b; }
    DLLEXPORT float add_f32(float a, float b) { return a + b; }
    DLLEXPORT double scale_i32_double(int32_t a, double b) { return a * b; }
    DLLEXPORT double scale_double_i32(double a, int32_t b) { return a * b; }
    DLLEXPORT int32_t add3_i32(int32_t a, int32_t b, int32_t c) { return a + b + c; }
    DLLEXPORT double add3_double(double a, double b, double c) { return a + b + c; }
    DLLEXPORT uint32_t add3_u32(uint32_t a, uint32_t b, uint32_t c) { return a + b + c; }
    DLLEXPORT float add3_f32(float a, float b, float c) { return a + b + c; }
    DLLEXPORT void note_double(double a) { g_last_double = a; g_void_calls++; }
    DLLEXPORT void note_i32_pair(int32_t a, int32_t b) { g_last_i32 = a + b; g_void_calls++; }
    DLLEXPORT void note_u32_triple(uint32_t a, uint32_t b, uint32_t c) {
        g_last_u32 = a + b + c;
        g_void_calls++;
    }
    DLLEXPORT double last_double(void) { return g_last_double; }
    DLLEXPORT int32_t last_i32(void) { return g_last_i32; }
    DLLEXPORT uint32_t last_u32(void) { return g_last_u32; }
    DLLEXPORT int32_t void_calls(void) { return g_void_calls; }
//ext: .c


sub xsub_addr ($cv) {
    my $obj = eval { B::svref_2object($cv) } or return;
    return eval { $obj->XSUB };
}
subtest 'two-argument int specialization' => sub {
    my $add = wrap( $lib, 'add_i32', [ Int32, Int32 ] => Int32 );
    is $add->(  2, 10 ), 12, 'positive integers';
    is $add->( -7, 3 ),  -4, 'negative integer';
    is $add->(  0, 0 ),   0, 'zero';
    like dies { $add->(1) },         qr/Wrong number of arguments/, 'too few arguments';
    like dies { $add->( 1, 2, 3 ) }, qr/Wrong number of arguments/, 'too many arguments';
};
subtest 'two-argument double specialization' => sub {
    my $add = wrap( $lib, 'add_double', [ Double, Double ] => Double );
    is $add->( 1.25, 2.5 ), 3.75, 'doubles';
    is $add->( -1.5, 0.5 ), -1.0, 'negative double';
    like dies { $add->(1.0) }, qr/Wrong number of arguments/, 'too few arguments';
};
subtest 'three-argument int specialization' => sub {
    my $add = wrap( $lib, 'add3_i32', [ Int32, Int32, Int32 ] => Int32 );
    is $add->(  2, 10, 30 ), 42, 'positive integers';
    is $add->( -7, 3,  1 ),  -3, 'negative integer';
    like dies { $add->( 1, 2 ) }, qr/Wrong number of arguments/, 'too few arguments';
    like dies { $add->( 1, 2, 3, 4 ) }, qr/Wrong number of arguments/, 'too many arguments';
};
subtest 'three-argument double specialization' => sub {
    my $add = wrap( $lib, 'add3_double', [ Double, Double, Double ] => Double );
    is $add->( 1.25, 2.5, 0.5 ), 4.25, 'doubles';
    like dies { $add->( 1.0, 2.0 ) }, qr/Wrong number of arguments/, 'too few arguments';
};
subtest 'unsigned scalar specializations' => sub {
    my $twice = wrap( $lib, 'twice_u32', [UInt32] => UInt32 );
    is $twice->(21), 42, 'one argument';
    my $add = wrap( $lib, 'add_u32', [ UInt32, UInt32 ] => UInt32 );
    is $add->( 4294967295, 2 ), 1, 'two arguments wrap as unsigned';
    like dies { $add->(1) }, qr/Wrong number of arguments/, 'two-argument arity';
    my $add3 = wrap( $lib, 'add3_u32', [ UInt32, UInt32, UInt32 ] => UInt32 );
    is $add3->( 1, 2, 3 ), 6, 'three arguments';
    like dies { $add3->( 1, 2, 3, 4 ) }, qr/Wrong number of arguments/, 'three-argument arity';
};
subtest 'float scalar specializations' => sub {
    my $twice = wrap( $lib, 'twice_f32', [Float] => Float );
    is $twice->(1.5), 3.0, 'one argument';
    my $add = wrap( $lib, 'add_f32', [ Float, Float ] => Float );
    is $add->( 1.25, 2.5 ), 3.75, 'two arguments';
    like dies { $add->( 1.0, 2.0, 3.0 ) }, qr/Wrong number of arguments/, 'two-argument arity';
    my $add3 = wrap( $lib, 'add3_f32', [ Float, Float, Float ] => Float );
    is $add3->( 1.25, 2.5, 0.5 ), 4.25, 'three arguments';
};
subtest 'mixed numeric specializations' => sub {
    my $scale = wrap( $lib, 'scale_i32_double', [ Int32, Double ] => Double );
    is $scale->( 3, 2.5 ), 7.5, 'int then double';
    like dies { $scale->(3) }, qr/Wrong number of arguments/, 'arity';
    my $scale_rev = wrap( $lib, 'scale_double_i32', [ Double, Int32 ] => Double );
    is $scale_rev->( 2.5, 3 ), 7.5, 'double then int';
};
subtest 'void scalar specializations' => sub {
    my $note   = wrap( $lib, 'note_double', [Double] => Void );
    my $last   = wrap( $lib, 'last_double', []       => Double );
    my $calls  = wrap( $lib, 'void_calls',  []       => Int32 );
    my $before = $calls->();
    is $note->(2.5), undef,       'one argument returns undef';
    is $last->(),    2.5,         'one argument side effect';
    is $calls->(),   $before + 1, 'one argument call counted';
    like dies { $note->() }, qr/Wrong number of arguments/, 'one-argument arity';
    my $note_pair = wrap( $lib, 'note_i32_pair', [ Int32, Int32 ] => Void );
    my $last_i32  = wrap( $lib, 'last_i32',      []               => Int32 );
    $before = $calls->();
    is $note_pair->( -7, 3 ), undef,       'two arguments return undef';
    is $last_i32->(),         -4,          'two arguments side effect';
    is $calls->(),            $before + 1, 'two arguments call counted';
    like dies { $note_pair->(1) }, qr/Wrong number of arguments/, 'two-argument arity';
    my $note_triple = wrap( $lib, 'note_u32_triple', [ UInt32, UInt32, UInt32 ] => Void );
    my $last_u32    = wrap( $lib, 'last_u32',        []                         => UInt32 );
    $before = $calls->();
    is $note_triple->( 1, 2, 3 ), undef,       'three arguments return undef';
    is $last_u32->(),             6,           'three arguments side effect';
    is $calls->(),                $before + 1, 'three arguments call counted';
    like dies { $note_triple->( 1, 2 ) }, qr/Wrong number of arguments/, 'three-argument arity';
};
subtest 'specialized XSUB selection' => sub {
    my $generic = xsub_addr( wrap( libc(), 'strlen', [String] => Int32 ) );
    my @cases   = (
        [ 'Int32 pair'      => wrap( $lib, 'add_i32',          [ Int32, Int32 ]           => Int32 ) ],
        [ 'Double pair'     => wrap( $lib, 'add_double',       [ Double, Double ]         => Double ) ],
        [ 'Int32 triple'    => wrap( $lib, 'add3_i32',         [ Int32, Int32, Int32 ]    => Int32 ) ],
        [ 'UInt32 triple'   => wrap( $lib, 'add3_u32',         [ UInt32, UInt32, UInt32 ] => UInt32 ) ],
        [ 'Float pair'      => wrap( $lib, 'add_f32',          [ Float, Float ]           => Float ) ],
        [ 'mixed numeric'   => wrap( $lib, 'scale_i32_double', [ Int32, Double ]          => Double ) ],
        [ 'void Int32 pair' => wrap( $lib, 'note_i32_pair',    [ Int32, Int32 ]           => Void ) ]
    );
SKIP: {
        skip 'B::CV->XSUB is unavailable', 1 + @cases unless defined $generic;
        for my $case (@cases) {
            my ( $label, $fn ) = @$case;
            my $addr = xsub_addr($fn);
            skip "$label: B::CV->XSUB is unavailable", 1 unless defined $addr;
            isnt $addr, $generic, "$label uses a specialized XSUB";
        }
        my $add = xsub_addr( wrap( $lib, 'add_i32', [ Int32, Int32 ] => Int32 ) );
        my $sub = xsub_addr( wrap( $lib, 'sub_i32', [ Int32, Int32 ] => Int32 ) );
        is $add, $sub, 'same signature shares one specialized XSUB';
    }
};
subtest 'ithread clones keep specialization' => sub {
    skip_all 'No ithreads', 1 unless $Config{useithreads};
    require threads;
    my $add3    = wrap( $lib, 'add3_i32',   [ Int32,  Int32, Int32 ] => Int32 );
    my $mul     = wrap( $lib, 'mul_double', [ Double, Double ] => Double );
    my @threads = map {
        my $tid = $_;
        threads->create(
            sub {
                $add3->( $tid, $tid * 2, $tid * 3 ) == 6 * $tid && $mul->( $tid, 2.5 ) == ( 2.5 * $tid );
            }
        )
    } 1 .. 3;
    for my $thr (@threads) {
        my $tid = $thr->tid();
        ok $thr->join(), "thread $tid: specialized XSUB worked after cloning";
    }
};
done_testing;
