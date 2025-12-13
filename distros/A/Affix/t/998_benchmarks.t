use v5.40;
no warnings 'experimental';
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix               qw[wrap affix libm Double direct_wrap direct_affix];
use Test2::Tools::Affix qw[:all];
use Config;
use Test2::Require::AuthorTesting;
use Benchmark qw[:all];
$|++;

# Conditionally load FFI::Platypus and Inline::C
my ( $has_platypus, $has_inline_c );

BEGIN {
    try {
        builtin::load_module 'FFI::Platypus';
        FFI::Platypus->import();
        $has_platypus = 1;
        diag 'FFI::Platypus found, including it in benchmarks.';
    }
    catch ($e) {
        diag 'FFI::Platypus not found, skipping its benchmarks.';
    }
    try {
        builtin::load_module 'Inline';
        Inline->import();
        $has_inline_c = 1;
        diag 'Inline::C found, including it in benchmarks.';
    }
    catch ($e) {
        diag 'Inline::C not found, skipping its benchmarks.';
    }
}
my $libm = '' . libm();
diag 'libm: ' . $libm;

# FFI Setup
# Affix / Wrap setup
my $wrap_sin = wrap( $libm, 'sin', '(double)->double' );
affix( $libm, [ sin => 'affix_sin' ], '(double)->double' );
my $direct = direct_wrap( $libm, 'sin', '(double)->double' );
direct_affix( $libm, [ 'sin', 'direct_sin' ], '(double)->double' );

# FFI::Platypus setup (only if available)
my $platypus_sin;
if ($has_platypus) {
    my $ffi = FFI::Platypus->new( api => 2, lib => $libm );

    # Use find_lib with a named argument
    $ffi->attach( [ sin => 'platypus_sin' ], ['double'] => 'double' );
    $platypus_sin = $ffi->function( 'sin', ['double'] => 'double' );
}
my $inline_c_sin;
if ($has_inline_c) {
    Inline->import( C => <<END_OF_C );
#include <math.h>
double inline_sin(double x) { return sin(x); }
END_OF_C
}

# Verification
my $num = rand(time);
my $sin = sin $num;
diag sprintf 'sin( %f ) = %f', $num, $sin;
subtest verify => sub {
    is direct_sin($num),  float( $sin, tolerance => 0.000001 ), 'direct affix correctly calculates sin';
    is $direct->($num),   float( $sin, tolerance => 0.000001 ), 'direct wrap correctly calculates sin';
    is $wrap_sin->($num), float( $sin, tolerance => 0.000001 ), 'wrap correctly calculates sin';
    is affix_sin($num),   float( $sin, tolerance => 0.000001 ), 'affix correctly calculates sin';
    is sin($num),         float( $sin, tolerance => 0.000001 ), 'pure perl correctly calculates sin';

    # Conditionally run Platypus verification
    if ($has_platypus) {
        is $platypus_sin->($num), float( $sin, tolerance => 0.000001 ), 'platypus [function] correctly calculates sin';
        is platypus_sin($num),    float( $sin, tolerance => 0.000001 ), 'platypus [attach] correctly calculates sin';
    }
    if ($has_inline_c) {
        is inline_sin($num), float( $sin, tolerance => 0.000001 ), 'inline correctly calculates sin';
    }
};

# Benchmarks
my $depth = 20;
subtest benchmarks => sub {
    my $todo       = todo 'these are fun but not important; we will not be beating opcodes';
    my %benchmarks = (
        direct_affix => sub {
            my $x = 0;
            while ( $x < $depth ) { my $n = direct_sin($x); $x++; }
        },
        direct_wrap => sub {
            my $x = 0;
            while ( $x < $depth ) { my $n = $direct->($x); $x++; }
        },
        pure => sub {
            my $x = 0;
            while ( $x < $depth ) { my $n = sin($x); $x++ }
        },
        wrap => sub {
            my $x = 0;
            while ( $x < $depth ) { my $n = $wrap_sin->($x); $x++ }
        },
        affix => sub {
            my $x = 0;
            while ( $x < $depth ) { my $n = affix_sin($x); $x++ }
        }, (
            $has_platypus ?

                # Conditionally add Platypus benchmark
                (
                plat_f => sub {
                    my $x = 0;
                    while ( $x < $depth ) { my $n = $platypus_sin->($x); $x++ }
                },
                plat_a => sub {
                    my $x = 0;
                    while ( $x < $depth ) { my $n = platypus_sin($x); $x++ }
                }
                ) :
                ()
        ), (
            $has_inline_c ?

                # Conditionally add Inline::C benchmark
                (
                inline_c => sub {
                    my $x = 0;
                    while ( $x < $depth ) { my $n = inline_sin($x); $x++ }
                }
                ) :
                ()
        )
    );
    isnt fastest( -10, %benchmarks ), 'pure', 'The fastest method should not be pure Perl';
};

# Helper Function
# Cribbed from Test::Benchmark
sub fastest {
    my ( $times, %marks ) = @_;
    note sprintf 'running %s for %s seconds each', join( ', ', keys %marks ), abs($times);
    my @marks;
    my $len = [ map { length $_ } keys %marks ]->[-1];
    for my $name ( sort keys %marks ) {
        my $res = timethis( $times, $marks{$name}, '', 'none' );
        my ( $r, $pu, $ps, $cu, $cs, $n ) = @$res;
        push @marks, { name => $name, res => $res, n => $n, s => ( $pu + $ps ) };
        note sprintf '%' . ( $len + 1 ) . 's - %s', $name, timestr($res);
    }
    my $results = cmpthese {
        map { $_->{name} => $_->{res} } @marks
    }, 'none';
    my $len_1 = [ map { length $_->[1] } @$results ]->[-1];
    note sprintf '%-' . ( $len + 1 ) . 's %' . ( $len_1 + 1 ) . 's' . ( ' %5s' x scalar keys %marks ), @$_ for @$results;
    [ sort { $b->{n} * $a->{s} <=> $a->{n} * $b->{s} } @marks ]->[0]->{name};
}
done_testing;
