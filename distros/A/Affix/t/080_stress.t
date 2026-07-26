use v5.40;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
use Config;
use Time::HiRes qw[tv_interval time];
$|++;
my $lib = compile_ok(<<~'');
    #include "std.h"
    typedef struct { int id; double value; char name[32]; } Record;
    DLLEXPORT int add_ints(int a, int b) { return a + b; }
    DLLEXPORT double echo_double(double x) { return x; }
    DLLEXPORT int echo_int(int x) { return x; }
    DLLEXPORT void noop(void) {}
    DLLEXPORT Record make_record(int id, double val, const char *name) {
        Record r; r.id = id; r.value = val;
        strncpy(r.name, name, 31); r.name[31] = '\0';
        return r;
    }
    DLLEXPORT int sum_records(Record *recs, int n) {
        int sum = 0;
        for (int i = 0; i < n; i++) sum += recs[i].id;
        return sum;
    }
    DLLEXPORT int call_twice(int (*fn)(int, int), int a, int b) {
        return fn(a, b) + fn(a, b);
    }
    DLLEXPORT int identity_int(int x) { return x; }
    DLLEXPORT int read_from_ptr(int *p) { return p ? *p : -1; }
//ext: .c

typedef Record => Struct [ id => Int, value => Double, name => Array [ Char, 32 ] ];
#
subtest 'Rapid alloc/free: 10000 cycles' => sub {
    my $t0    = [Time::HiRes::gettimeofday];
    my $count = 10_000;
    for ( 1 .. $count ) {
        my $ptr = Affix::malloc( sizeof(Int) );
        ok is_pin($ptr), 'malloc returns a pin' if $_ == 1;
    }
    my $elapsed = tv_interval($t0);
    pass("Completed $count alloc cycles in ${elapsed}s");
};
#
subtest 'Many simultaneous pins: 1000 pins' => sub {
    my @pins;
    for ( 1 .. 1000 ) {
        push @pins, Affix::malloc( sizeof(Int) );
    }
    my $valid = grep { defined $_ && is_pin($_) } @pins;
    is $valid, 1000, 'All 1000 pins are valid';
    pass('Allocated 1000 pins without crash');
};
#
subtest 'Many simultaneous string pins' => sub {
    my @strings;
    for my $i ( 1 .. 500 ) {
        push @strings, Affix::strdup("string_$i");
    }
    my $valid = grep { defined $_ && is_pin($_) } @strings;
    is $valid, 500, 'All 500 string pins are valid';
    for my $i ( 0 .. 49 ) {
        my $view = $strings[ $i * 10 ];
        ok defined $view, "String pin $i is accessible";
    }
    pass('String pin array accessible');
};
#
subtest 'Callback stress: 5000 calls' => sub {
    my $call_count = 0;
    my $cb         = sub { $call_count++; return $_[0] + $_[1]; };
    my $fn         = wrap( $lib, 'call_twice', [ Callback [ [ Int, Int ], Int ], Int, Int ], Int );
    for ( 1 .. 5000 ) {
        my $result = $fn->( $cb, 1, 2 );
        is $result, 6, 'callback result correct' if $_ % 1000 == 0;
    }
    is $call_count, 10000, 'Callback was called 10000 times (5000 x 2)';
};
#
subtest 'Rapid struct creation: 5000 structs' => sub {
    my $fn = wrap( $lib, 'make_record', [ Int, Double, String ], Record() );
    for my $i ( 1 .. 5000 ) {
        my $rec = $fn->( $i, $i * 1.5, "record_$i" );
        is $rec->{id}, $i, "Record $i id correct" if $i == 1 || $i == 5000;
    }
    pass('Created 5000 structs without crash');
};
#
subtest 'Sum array of 1000 structs' => sub {
    my $sum = wrap( $lib, 'sum_records', [ Pointer [ Record() ], Int ], Int );
    my $ptr = calloc( 1000, sizeof( Record() ) );
    for my $i ( 0 .. 999 ) {
        my $offset = Affix::ptr_add( $ptr, $i * sizeof( Record() ) );
        my $view   = cast( $offset, Record() );
        $view->{id}    = $i + 1;
        $view->{value} = $i * 0.1;
    }
    my $total = $sum->( $ptr, 1000 );
    is $total, 500500, 'sum_records([1..1000]) = 500500';
};
#
subtest 'Deeply nested struct allocation' => sub {
    my $outer = calloc( 1, sizeof( Record() ) );
    my $view  = cast( $outer, Record() );
    $view->{id}    = 42;
    $view->{value} = 3.14;
    my $inner_ptr = Affix::ptr_add( $outer, offsetof( Record(), 'name' ) );
    my $inner     = cast( $inner_ptr, Record() );
    $inner->{id}    = 99;
    $inner->{value} = 2.71;
    is $view->{id},     42,          'outer id preserved';
    is $inner->{id},    99,          'inner id written';
    is $view->{value},  float(3.14), 'outer value preserved';
    is $inner->{value}, float(2.71), 'inner value written';
};
#
subtest 'Stress test: timing baseline' => sub {
    my $fn     = wrap( $lib, 'add_ints', [ Int, Int ], Int );
    my $t0     = [Time::HiRes::gettimeofday];
    my $count  = 50_000;
    my $result = 0;
    for ( 1 .. $count ) {
        $result = $fn->( 1, 2 );
    }
    my $elapsed = tv_interval($t0);
    is $result, 3, 'Final result correct';
    pass("Completed $count FFI calls in ${elapsed}s");
};
done_testing;
