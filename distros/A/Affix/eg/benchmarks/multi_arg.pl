use v5.40;
use blib;
use Config;
use ExtUtils::CBuilder ();
use ExtUtils::ParseXS  ();
use File::Path         qw[make_path];
use File::Temp         qw[tempdir];
use Time::HiRes        qw[time];
use Affix              qw[:all];
$|++;

=pod

=head1 NAME

eg/benchmarks/multi_arg.pl - compare Affix scalar specializations with XS

=head1 SYNOPSIS

    perl Build.PL && ./Build
    perl -Mblib eg/benchmarks/multi_arg.pl

Set C<AFFIX_BENCH_SECONDS> to change the CPU seconds spent on each implementation per case (default: five).

=head1 DESCRIPTION

Builds one temporary shared library containing plain C functions and hand-written XSUB wrappers around those same
functions, then times Affix against XS for the scalar signatures that have monolithic XSUB specializations:

=over

=item * arity 1, 2 and 3 for C<double>, C<float>, C<int32_t> and C<uint32_t>

=item * mixed C<double, int32_t> and C<int32_t, double>

=item * C<void> returns

=back

Each case runs two alternating rounds so a single burst of runner noise cannot decide the ratio. The reported number is
the median of calls/second for each implementation and their ratio.

The C<direct_*> forms are deliberately omitted: they exist for diagnosis and lack Affix's pointer, lvalue, enum,
struct, out-parameter and variadic support.

=cut

my $SECONDS = $ENV{AFFIX_BENCH_SECONDS} // 5;
die "AFFIX_BENCH_SECONDS must be a positive number\n" unless $SECONDS =~ /^\d+(?:\.\d+)?$/ && $SECONDS > 0;
my $ROUNDS = 2;
my $SLICE  = $SECONDS / $ROUNDS;
my $CHUNK  = 1024;

# Windows keeps the generated DLL mapped until process exit, so leave the
# directory behind there rather than warning during File::Temp's cleanup.
my $tmp = tempdir( CLEANUP => ( $^O eq 'MSWin32' ? 0 : 1 ) );

sub build_bench_lib ($dir) {
    my $xs = "$dir/BenchMulti.xs";
    open my $fh, '>', $xs or die "Cannot write $xs: $!";
    print {$fh} <<'END_XS';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdint.h>

#ifdef _WIN32
#define BENCH_EXPORT __declspec(dllexport)
#else
#define BENCH_EXPORT
#endif

/* Keep the C functions real calls in the XS wrappers. Otherwise the compiler
 * inlines them and XS gets a shortcut Affix cannot use: a C function pointer. */
#if defined(_MSC_VER)
#define BENCH_NOINLINE __declspec(noinline)
#elif defined(__GNUC__)
#define BENCH_NOINLINE __attribute__((noinline))
#else
#define BENCH_NOINLINE
#endif

BENCH_EXPORT BENCH_NOINLINE double bench_one_d(double a) { return a; }
BENCH_EXPORT BENCH_NOINLINE double bench_pair_d(double a, double b) { return a + b; }
BENCH_EXPORT BENCH_NOINLINE double bench_triple_d(double a, double b, double c) { return a + b + c; }
BENCH_EXPORT BENCH_NOINLINE int32_t bench_pair_i(int32_t a, int32_t b) { return a + b; }
BENCH_EXPORT BENCH_NOINLINE int32_t bench_triple_i(int32_t a, int32_t b, int32_t c) { return a + b + c; }
BENCH_EXPORT BENCH_NOINLINE uint32_t bench_pair_u(uint32_t a, uint32_t b) { return a + b; }
BENCH_EXPORT BENCH_NOINLINE float bench_pair_f(float a, float b) { return a + b; }
BENCH_EXPORT BENCH_NOINLINE double bench_mixed_di(double a, int32_t b) { return a + b; }
BENCH_EXPORT BENCH_NOINLINE void bench_void_d(double a) { (void)a; }

MODULE = BenchMulti    PACKAGE = BenchMulti

PROTOTYPES: DISABLE

double
xs_one_d(a)
        double a
    CODE:
        RETVAL = bench_one_d(a);
    OUTPUT:
        RETVAL

double
xs_pair_d(a, b)
        double a
        double b
    CODE:
        RETVAL = bench_pair_d(a, b);
    OUTPUT:
        RETVAL

double
xs_triple_d(a, b, c)
        double a
        double b
        double c
    CODE:
        RETVAL = bench_triple_d(a, b, c);
    OUTPUT:
        RETVAL

int
xs_pair_i(a, b)
        int a
        int b
    CODE:
        RETVAL = bench_pair_i(a, b);
    OUTPUT:
        RETVAL

int
xs_triple_i(a, b, c)
        int a
        int b
        int c
    CODE:
        RETVAL = bench_triple_i(a, b, c);
    OUTPUT:
        RETVAL

unsigned int
xs_pair_u(a, b)
        unsigned int a
        unsigned int b
    CODE:
        RETVAL = bench_pair_u(a, b);
    OUTPUT:
        RETVAL

float
xs_pair_f(a, b)
        float a
        float b
    CODE:
        RETVAL = bench_pair_f(a, b);
    OUTPUT:
        RETVAL

double
xs_mixed_di(a, b)
        double a
        int b
    CODE:
        RETVAL = bench_mixed_di(a, b);
    OUTPUT:
        RETVAL

SV *
xs_void_d(a)
        double a
    CODE:
        bench_void_d(a);
        RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL
END_XS
    close $fh;
    my $c = "$dir/BenchMulti.c";
    ExtUtils::ParseXS::process_file( filename => $xs, output => $c, module_name => 'BenchMulti' );
    my @inc  = grep {-d} map {"$_/CORE"} @Config{qw[archlib sitearch]};
    my $cb   = ExtUtils::CBuilder->new( quiet => 1 );
    my $obj  = $cb->compile( source => $c, include_dirs => \@inc );
    my $auto = "$dir/auto/BenchMulti";
    make_path($auto);
    my $lib_file = "$auto/BenchMulti.$Config{dlext}";
    $cb->link( objects => [$obj], lib_file => $lib_file, module_name => 'BenchMulti' );
    unshift @INC, $dir;
    require DynaLoader;
    {

        package BenchMulti;
        our @ISA = ('DynaLoader');
        sub dl_load_flags {0}
    }
    BenchMulti->bootstrap;
    return $lib_file;
}

sub median (@values) {
    my @sorted = sort { $a <=> $b } @values;
    my $n      = @sorted;
    return $n % 2 ? $sorted[ int( $n / 2 ) ] : ( $sorted[ $n / 2 - 1 ] + $sorted[ $n / 2 ] ) / 2;
}
my $lib_file = build_bench_lib($tmp);
my $lib      = Affix::find_library($lib_file) or die "Cannot load $lib_file: $!\n";
my %cases    = (
    'double(double)'         => [ wrap( $lib, 'bench_one_d', [Double] => Double ), \&BenchMulti::xs_one_d, [0.5], sub { $_[0] } ],
    'double(double, double)' =>
        [ wrap( $lib, 'bench_pair_d', [ Double, Double ] => Double ), \&BenchMulti::xs_pair_d, [ 0.5, 1.25 ], sub { $_[0] + $_[1] } ],
    'double(double, double, double)' => [
        wrap( $lib, 'bench_triple_d', [ Double, Double, Double ] => Double ),
        \&BenchMulti::xs_triple_d,
        [ 0.5, 1.25, 2.0 ],
        sub { $_[0] + $_[1] + $_[2] }
    ],
    'int32(int32, int32)' => [ wrap( $lib, 'bench_pair_i', [ Int32, Int32 ] => Int32 ), \&BenchMulti::xs_pair_i, [ 2, 10 ], sub { $_[0] + $_[1] } ],
    'int32(int32, int32, int32)' =>
        [ wrap( $lib, 'bench_triple_i', [ Int32, Int32, Int32 ] => Int32 ), \&BenchMulti::xs_triple_i, [ 2, 10, 30 ], sub { $_[0] + $_[1] + $_[2] } ],
    'uint32(uint32, uint32)' =>
        [ wrap( $lib, 'bench_pair_u', [ UInt32, UInt32 ] => UInt32 ), \&BenchMulti::xs_pair_u, [ 1, 2 ], sub { $_[0] + $_[1] } ],
    'float(float, float)' =>
        [ wrap( $lib, 'bench_pair_f', [ Float, Float ] => Float ), \&BenchMulti::xs_pair_f, [ 1.5, 2.25 ], sub { $_[0] + $_[1] } ],
    'double(double, int32)' =>
        [ wrap( $lib, 'bench_mixed_di', [ Double, Int32 ] => Double ), \&BenchMulti::xs_mixed_di, [ 2.5, 3 ], sub { $_[0] + $_[1] } ],
    'void(double)' => [ wrap( $lib, 'bench_void_d', [Double] => Void ), \&BenchMulti::xs_void_d, [0.5], sub {undef} ]
);
say "scalar specialization showdown, $SECONDS CPU seconds per implementation (2 alternating rounds)";
say "perl $^V ($Config{archname}), $^O";
say "Affix $Affix::VERSION";
say '';

for my $label ( sort keys %cases ) {
    my ( $affix, $xs, $args, $expected ) = @{ $cases{$label} };
    for my $pair ( [ 'Affix', $affix ], [ 'XS', $xs ] ) {
        my ( $name, $fn ) = @$pair;
        my $got  = $fn->(@$args);
        my $want = $expected->(@$args);
        if ( defined $want ) {
            my $tol = $label =~ /float/i ? 1e-5 : 1e-12;
            die "$label: $name returned $got, expected $want\n" if abs( $got - $want ) > $tol;
        }
        elsif ( defined $got ) {
            die "$label: $name returned $got, expected undef\n";
        }
    }
}
say 'Affix and XS agree on every case.';
say 'We can just run benchmarks now...';
my @ratios;
for my $label ( sort keys %cases ) {
    my ( $affix, $xs, $args ) = @{ $cases{$label} };
    my %impl = ( Affix => $affix, XS => $xs );
    my %samples;
    for my $round ( 1 .. $ROUNDS ) {
        my @order = sort keys %impl;
        push @order, shift @order if $round % 2;
        for my $name (@order) {
            my $fn    = $impl{$name};
            my $start = time;
            my $count = 0;
            while (1) {
                $fn->(@$args) for 1 .. $CHUNK;
                $count += $CHUNK;
                last if time - $start >= $SLICE;
            }
            my $elapsed = time - $start;
            push @{ $samples{$name} }, $count / $elapsed;
        }
    }
    my $affix_rate = median( @{ $samples{Affix} } );
    my $xs_rate    = median( @{ $samples{XS} } );
    my $ratio      = $affix_rate / $xs_rate;
    push @ratios, $ratio;
    say '';
    say $label;
    printf "  Affix %11.0f calls/s  XS %11.0f calls/s  Affix/XS %.3fx\n", $affix_rate, $xs_rate, $ratio;
}
say '';
my $min_ratio = $ratios[0];
$min_ratio = $_ for @ratios[ 1 .. $#ratios ];
printf "Minimum Affix/XS ratio: %.3fx\n", $min_ratio;
