use v5.40;
use blib;
use Benchmark qw[cmpthese];
use Config;
use ExtUtils::CBuilder ();
use ExtUtils::ParseXS  ();
use File::Path         qw[make_path];
use File::Temp         qw[tempdir];
use Affix              qw[:all];
$|++;

=pod

=head1 NAME

eg/benchmarks/bindings.pl - compare eight ways to call C from Perl

=head1 SYNOPSIS

    perl Build.PL && ./Build
    perl -Mblib eg/benchmarks/bindings.pl

Set C<AFFIX_BENCH_SECONDS> to change the time spent per implementation (default: five CPU seconds).

=head1 DESCRIPTION

Calls C<sin(double) -E<gt> double> from libm/libc eight ways:

=over 4

=item * Affix C<affix(...)>, C<wrap(...)>, C<direct_affix(...)> and C<direct_wrap(...)>

=item * Inline::C

=item * a hand-written XSUB compiled with L<ExtUtils::ParseXS> and L<ExtUtils::CBuilder>

=item * FFI::Platypus C<attach(...)> and C<function(...)>

=back

The C<direct_*> cases use Affix's experimental direct-marshalling backend, whose JIT trampoline reads Perl stack
values straight into CPU registers instead of staging them in an argument buffer. Its performance is ABI-dependent:
it helps on SysV x64 (Linux/macOS) but can be slower on Windows x64.

The XSUB and Inline::C cases are compiled into a temporary directory at startup. Both inherit Perl's own
C<$Config{optimize}> (normally C<-O2>) through L<ExtUtils::CBuilder> and Inline::C, so neither native path gets
special optimization flags. All eight results are checked against Perl's built-in C<sin> before timing, so a broken
binding can't silently skew the numbers.

=cut

my $SECONDS = $ENV{AFFIX_BENCH_SECONDS} // 5;
die "AFFIX_BENCH_SECONDS must be a positive integer\n" unless $SECONDS =~ /^\d+$/ && $SECONDS > 0;
require Inline;
require Inline::C;
require FFI::Platypus;

# Windows keeps the generated DLL mapped until process exit, so leave the directory behind there rather than warning
# during File::Temp's cleanup.
my $tmp = tempdir( CLEANUP => ( $^O eq 'MSWin32' ? 0 : 1 ) );

sub build_xs ($dir) {
    my $xs = "$dir/BenchXS.xs";
    open my $fh, '>', $xs or die "Cannot write $xs: $!";
    print {$fh} <<'END_XS';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <math.h>
#include <string.h>

MODULE = BenchXS    PACKAGE = BenchXS

PROTOTYPES: DISABLE

double
xs_sin(x)
        double x
    CODE:
        RETVAL = sin(x);
    OUTPUT:
        RETVAL

int
xs_abs(x)
        int x
    CODE:
        RETVAL = abs(x);
    OUTPUT:
        RETVAL

int
xs_strlen(s)
        char *s
    CODE:
        RETVAL = (int)strlen(s);
    OUTPUT:
        RETVAL
END_XS
    close $fh;
    my $c = "$dir/BenchXS.c";
    ExtUtils::ParseXS::process_file( filename => $xs, output => $c, module_name => 'BenchXS' );
    my @inc  = grep {-d} map {"$_/CORE"} @Config{qw[archlib sitearch]};
    my $cb   = ExtUtils::CBuilder->new( quiet => 1 );
    my $obj  = $cb->compile( source => $c, include_dirs => \@inc );
    my $auto = "$dir/auto/BenchXS";
    make_path($auto);
    $cb->link(
        objects     => [$obj],
        lib_file    => "$auto/BenchXS.$Config{dlext}",
        module_name => 'BenchXS',

        # libc provides the math symbols on Windows; Unix needs libm.
        extra_link_flags => ( $^O eq 'MSWin32' ? '' : '-lm' )
    );
    unshift @INC, $dir;
    require DynaLoader;
    {

        package BenchXS;
        our @ISA = ('DynaLoader');
        sub dl_load_flags {0}
    }
    BenchXS->bootstrap;
    return ( \&BenchXS::xs_sin, \&BenchXS::xs_abs, \&BenchXS::xs_strlen );
}
my $affix_sin = wrap( libm, 'sin', [Double] => Double );
affix libm, [ sin => 'affix_sin' ], [Double] => Double;
my $direct_sin = direct_wrap( libm, 'sin', [Double] => Double );
direct_affix libm, [ sin => 'direct_affix_sin' ], '(double) -> double';
my $affix_abs = wrap( libm, 'abs', [Int32] => Int32 );
affix libm, [ abs => 'affix_abs_xsub' ], [Int32] => Int32;
my $affix_strlen = wrap( libm, 'strlen', [String] => Int32 );
affix libm, [ strlen => 'affix_strlen_xsub' ], [String] => Int32;
my ( $xs_sin, $xs_abs, $xs_strlen ) = build_xs($tmp);
Inline->bind( C => <<'END_C' );
#include <math.h>
#include <stdlib.h>
#include <string.h>
double inline_sin(double x) { return sin(x); }
int inline_abs(int x) { return abs(x); }
int inline_strlen(const char *s) { return (int)strlen(s); }
END_C
my $inline_sin    = \&main::inline_sin;
my $inline_abs    = \&main::inline_abs;
my $inline_strlen = \&main::inline_strlen;

#~ undef searches the running perl executable and the C library it is
#~ linked against, so this works without a platform-specific libm name.
my $ffi = FFI::Platypus->new( api => 2, lib => undef );
$ffi->attach( [ sin    => 'platypus_sin' ]    => ['double'] => 'double' );
$ffi->attach( [ abs    => 'platypus_abs' ]    => ['int']    => 'int' );
$ffi->attach( [ strlen => 'platypus_strlen' ] => ['string'] => 'int' );
my $platypus_function = $ffi->function( sin => ['double'] => 'double' );
my $platypus_abs_fn   = $ffi->function( abs => ['int']    => 'int' );
my %impl              = (
    Affix_wrap               => $affix_sin,
    Affix                    => \&main::affix_sin,
    Affix_direct_wrap        => $direct_sin,
    Affix_direct_affix       => \&main::direct_affix_sin,
    XS                       => $xs_sin,
    'Inline::C'              => $inline_sin,
    'FFI::Platypus'          => \&main::platypus_sin,
    'FFI::Platypus function' => sub { $platypus_function->call( $_[0] ) }
);
say "perl $^V ($Config{archname}), $^O";
say "Affix $Affix::VERSION";
say "Inline $Inline::VERSION / Inline::C $Inline::C::VERSION";
say "FFI::Platypus $FFI::Platypus::VERSION";
say '';
say "sin(double) -> double, $SECONDS CPU seconds per implementation";

for my $x ( 0, 0.5, 1, -2.25 ) {
    my $expected = CORE::sin($x);
    for my $name ( sort keys %impl ) {
        my $got = $impl{$name}->($x);
        die "$name: sin($x) returned $got, expected $expected\n" if abs( $got - $expected ) > 1e-12;
    }
}
say 'All implementations agree.';
say 'We can just run benchmarks now...';
cmpthese(
    -$SECONDS,
    {   Affix                => sub { $impl{Affix}->(0.5) },
        'Affix wrap'         => sub { $impl{Affix_wrap}->(0.5) },
        'Affix direct_wrap'  => sub { $impl{Affix_direct_wrap}->(0.5) },
        'Affix direct_affix' => sub { $impl{Affix_direct_affix}->(0.5) },
        XS                   => sub { $impl{XS}->(0.5) },
        'Inline::C'          => sub { $impl{'Inline::C'}->(0.5) },
        'FFI::Platypus'      => sub { $impl{'FFI::Platypus'}->(0.5) },
        'FFI::Platypus fn'   => sub { $impl{'FFI::Platypus function'}->(0.5) }
    }
);

#~ Integer argument marshalling benchmark: abs(int) -> int
say '';
say "abs(int) -> int, $SECONDS CPU seconds per implementation";
my %impl_int = (
    Affix_wrap      => $affix_abs,
    Affix           => \&main::affix_abs_xsub,
    XS              => $xs_abs,
    'Inline::C'     => $inline_abs,
    'FFI::Platypus' => \&main::platypus_abs
);
for my $x ( -7, 0, 42, -12345 ) {
    my $expected = CORE::abs($x);
    for my $name ( sort keys %impl_int ) {
        my $got = $impl_int{$name}->($x);
        die "$name: abs($x) returned $got, expected $expected\n" if $got != $expected;
    }
}
say 'All implementations agree.';
say 'We can just run benchmarks now...';
cmpthese(
    -$SECONDS,
    {   Affix           => sub { $impl_int{Affix}->(-42) },
        'Affix wrap'    => sub { $impl_int{Affix_wrap}->(-42) },
        XS              => sub { $impl_int{XS}->(-42) },
        'Inline::C'     => sub { $impl_int{'Inline::C'}->(-42) },
        'FFI::Platypus' => sub { $impl_int{'FFI::Platypus'}->(-42) }
    }
);

#~ String argument marshalling benchmark: strlen(const char *) -> int
say '';
say "strlen(const char *) -> int, $SECONDS CPU seconds per implementation";
my %impl_str = (
    Affix_wrap      => $affix_strlen,
    Affix           => \&main::affix_strlen_xsub,
    XS              => $xs_strlen,
    'Inline::C'     => $inline_strlen,
    'FFI::Platypus' => \&main::platypus_strlen
);
for my $s ( '', 'a', 'hello', 'abcdefghij' ) {
    my $expected = length($s);
    for my $name ( sort keys %impl_str ) {
        my $got = $impl_str{$name}->($s);
        die "$name: strlen('$s') returned $got, expected $expected\n" if $got != $expected;
    }
}
say 'All implementations agree.';
say 'We can just run benchmarks now...';
cmpthese(
    -$SECONDS,
    {   Affix           => sub { $impl_str{Affix}->('hello world') },
        'Affix wrap'    => sub { $impl_str{Affix_wrap}->('hello world') },
        XS              => sub { $impl_str{XS}->('hello world') },
        'Inline::C'     => sub { $impl_str{'Inline::C'}->('hello world') },
        'FFI::Platypus' => sub { $impl_str{'FFI::Platypus'}->('hello world') }
    }
);
