use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
use Config;
#
$|++;
#
my $c_source = <<'END_C';
#include "std.h"
//ext: .c

#include <stdio.h>
#include <stdint.h>

DLLEXPORT long double add_ld(long double a, long double b) {
    return a + b;
}

DLLEXPORT double ld_to_d(long double a) {
    return (double)a;
}
END_C

# On FreeBSD/ARM64, 128-bit float runtime support might be missing in shared libs?
skip_all 'Skipping Long Double on FreeBSD ARM64 due to missing runtime symbols' if $^O eq 'freebsd' && $Config{archname} =~ /aarch64/;
#
my $lib = compile_ok($c_source);
#
isa_ok my $add = wrap( $lib, 'add_ld', [ LongDouble, LongDouble ] => LongDouble ), ['Affix'];
my $res = $add->( 1.5, 2.5 );

# Perl's internal NV might be double or long double depending on Configure.
# Affix handles the conversion.
is $res, float(4.0), 'Long Double addition (small values)';

# Precision Check
# Verify that we can pass something > DBL_MAX or with high precision if Perl supports it
# For now, just ensure it roundtrips through C correctly.
isa_ok my $convert = wrap( $lib, 'ld_to_d', [LongDouble] => Double ), ['Affix'];
my $val = 3.14159;
is $convert->($val), float(3.14159), 'LongDouble -> C -> Double roundtrip';
#
done_testing;
