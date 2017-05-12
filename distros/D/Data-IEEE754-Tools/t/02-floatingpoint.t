########################################################################
# Verifies the following functions:
#   :floatingpoint
#       to_hex_floatingpoint(v)
#       to_dec_floatingpoint(v)
########################################################################
use 5.006;
use warnings;
use strict;
use Test::More;
use Data::IEEE754::Tools qw/:raw754 :floatingpoint/;

sub fptest {
    local $\ = "\n";
    my $h = shift;
    my $val = hexstr754_to_double($h->{src});
    my ($got, $exp, $name);
    $exp = quotemeta( $h->{exp_hex} );
    $exp =~ s/SNAN/[SQ]NAN/;
    like( $got = to_hex_floatingpoint($val), qr/$exp/, $name = sprintf('to_hex_floatingpoint(ieee754(%-16.16s) = %-+24.16e)', $h->{src}, $val) );
    print( "$name() = $got" );
    $exp = quotemeta( $h->{exp_dec} );
    $exp =~ s/SNAN/[SQ]NAN/;
    like( $got = to_dec_floatingpoint($val), qr/$exp/, $name = sprintf('to_dec_floatingpoint(ieee754(%-16.16s) = %-+24.16e)', $h->{src}, $val) );
    print( "$name() = $got" );
}

my @tests = ();
push @tests, { src => '0000000000000000', exp_hex => '+0x0.0000000000000p+0000', exp_dec => '+0d0.0000000000000000p+0000' };
push @tests, { src => '8000000000000000', exp_hex => '-0x0.0000000000000p+0000', exp_dec => '-0d0.0000000000000000p+0000' };
push @tests, { src => '0000000000000001', exp_hex => '+0x0.0000000000001p-1022', exp_dec => '+0d0.0000000000000002p-1022' };
push @tests, { src => '8000000000000001', exp_hex => '-0x0.0000000000001p-1022', exp_dec => '-0d0.0000000000000002p-1022' };
push @tests, { src => '000FFFFFFFFFFFFF', exp_hex => '+0x0.fffffffffffffp-1022', exp_dec => '+0d0.9999999999999998p-1022' };
push @tests, { src => '800FFFFFFFFFFFFF', exp_hex => '-0x0.fffffffffffffp-1022', exp_dec => '-0d0.9999999999999998p-1022' };
push @tests, { src => '0010000000000000', exp_hex => '+0x1.0000000000000p-1022', exp_dec => '+0d1.0000000000000000p-1022' };
push @tests, { src => '8010000000000000', exp_hex => '-0x1.0000000000000p-1022', exp_dec => '-0d1.0000000000000000p-1022' };
push @tests, { src => '0010000000000001', exp_hex => '+0x1.0000000000001p-1022', exp_dec => '+0d1.0000000000000002p-1022' };
push @tests, { src => '8010000000000001', exp_hex => '-0x1.0000000000001p-1022', exp_dec => '-0d1.0000000000000002p-1022' };
push @tests, { src => '001FFFFFFFFFFFFF', exp_hex => '+0x1.fffffffffffffp-1022', exp_dec => '+0d1.9999999999999998p-1022' };
push @tests, { src => '801FFFFFFFFFFFFF', exp_hex => '-0x1.fffffffffffffp-1022', exp_dec => '-0d1.9999999999999998p-1022' };
push @tests, { src => '3FF0000000000000', exp_hex => '+0x1.0000000000000p+0000', exp_dec => '+0d1.0000000000000000p+0000' };
push @tests, { src => 'BFF0000000000000', exp_hex => '-0x1.0000000000000p+0000', exp_dec => '-0d1.0000000000000000p+0000' };
push @tests, { src => '3FF0000000000001', exp_hex => '+0x1.0000000000001p+0000', exp_dec => '+0d1.0000000000000002p+0000' };
push @tests, { src => 'BFF0000000000001', exp_hex => '-0x1.0000000000001p+0000', exp_dec => '-0d1.0000000000000002p+0000' };
push @tests, { src => '3FF0000000000008', exp_hex => '+0x1.0000000000008p+0000', exp_dec => '+0d1.0000000000000018p+0000' };
push @tests, { src => 'BFF0000000000008', exp_hex => '-0x1.0000000000008p+0000', exp_dec => '-0d1.0000000000000018p+0000' };
push @tests, { src => '3FF0000000000080', exp_hex => '+0x1.0000000000080p+0000', exp_dec => '+0d1.0000000000000284p+0000' };
push @tests, { src => 'BFF0000000000080', exp_hex => '-0x1.0000000000080p+0000', exp_dec => '-0d1.0000000000000284p+0000' };
push @tests, { src => '3FF0000000000800', exp_hex => '+0x1.0000000000800p+0000', exp_dec => '+0d1.0000000000004547p+0000' };
push @tests, { src => 'BFF0000000000800', exp_hex => '-0x1.0000000000800p+0000', exp_dec => '-0d1.0000000000004547p+0000' };
push @tests, { src => '3FF0000000008000', exp_hex => '+0x1.0000000008000p+0000', exp_dec => '+0d1.0000000000072760p+0000' };
push @tests, { src => 'BFF0000000008000', exp_hex => '-0x1.0000000008000p+0000', exp_dec => '-0d1.0000000000072760p+0000' };
push @tests, { src => '3FF0000000080000', exp_hex => '+0x1.0000000080000p+0000', exp_dec => '+0d1.0000000001164153p+0000' };
push @tests, { src => 'BFF0000000080000', exp_hex => '-0x1.0000000080000p+0000', exp_dec => '-0d1.0000000001164153p+0000' };
push @tests, { src => '3FF0000000800000', exp_hex => '+0x1.0000000800000p+0000', exp_dec => '+0d1.0000000018626451p+0000' };
push @tests, { src => 'BFF0000000800000', exp_hex => '-0x1.0000000800000p+0000', exp_dec => '-0d1.0000000018626451p+0000' };
push @tests, { src => '3FF0000008000000', exp_hex => '+0x1.0000008000000p+0000', exp_dec => '+0d1.0000000298023224p+0000' };
push @tests, { src => 'BFF0000008000000', exp_hex => '-0x1.0000008000000p+0000', exp_dec => '-0d1.0000000298023224p+0000' };
push @tests, { src => '3FF0000080000000', exp_hex => '+0x1.0000080000000p+0000', exp_dec => '+0d1.0000004768371582p+0000' };
push @tests, { src => 'BFF0000080000000', exp_hex => '-0x1.0000080000000p+0000', exp_dec => '-0d1.0000004768371582p+0000' };
push @tests, { src => '3FF0000800000000', exp_hex => '+0x1.0000800000000p+0000', exp_dec => '+0d1.0000076293945312p+0000' };
push @tests, { src => 'BFF0000800000000', exp_hex => '-0x1.0000800000000p+0000', exp_dec => '-0d1.0000076293945312p+0000' };
push @tests, { src => '3FF0008000000000', exp_hex => '+0x1.0008000000000p+0000', exp_dec => '+0d1.0001220703125000p+0000' };
push @tests, { src => 'BFF0008000000000', exp_hex => '-0x1.0008000000000p+0000', exp_dec => '-0d1.0001220703125000p+0000' };
push @tests, { src => '3FF0080000000000', exp_hex => '+0x1.0080000000000p+0000', exp_dec => '+0d1.0019531250000000p+0000' };
push @tests, { src => 'BFF0080000000000', exp_hex => '-0x1.0080000000000p+0000', exp_dec => '-0d1.0019531250000000p+0000' };
push @tests, { src => '3FF0800000000000', exp_hex => '+0x1.0800000000000p+0000', exp_dec => '+0d1.0312500000000000p+0000' };
push @tests, { src => 'BFF0800000000000', exp_hex => '-0x1.0800000000000p+0000', exp_dec => '-0d1.0312500000000000p+0000' };
push @tests, { src => '3FF8000000000000', exp_hex => '+0x1.8000000000000p+0000', exp_dec => '+0d1.5000000000000000p+0000' };
push @tests, { src => 'BFF8000000000000', exp_hex => '-0x1.8000000000000p+0000', exp_dec => '-0d1.5000000000000000p+0000' };
push @tests, { src => '3FFFFFFFFFFFFFFF', exp_hex => '+0x1.fffffffffffffp+0000', exp_dec => '+0d1.9999999999999998p+0000' };
push @tests, { src => 'BFFFFFFFFFFFFFFF', exp_hex => '-0x1.fffffffffffffp+0000', exp_dec => '-0d1.9999999999999998p+0000' };
push @tests, { src => '4000000000000000', exp_hex => '+0x1.0000000000000p+0001', exp_dec => '+0d1.0000000000000000p+0001' };
push @tests, { src => 'C000000000000000', exp_hex => '-0x1.0000000000000p+0001', exp_dec => '-0d1.0000000000000000p+0001' };
push @tests, { src => '4000000000000001', exp_hex => '+0x1.0000000000001p+0001', exp_dec => '+0d1.0000000000000002p+0001' };
push @tests, { src => 'C000000000000001', exp_hex => '-0x1.0000000000001p+0001', exp_dec => '-0d1.0000000000000002p+0001' };
push @tests, { src => '400FFFFFFFFFFFFF', exp_hex => '+0x1.fffffffffffffp+0001', exp_dec => '+0d1.9999999999999998p+0001' };
push @tests, { src => 'C00FFFFFFFFFFFFF', exp_hex => '-0x1.fffffffffffffp+0001', exp_dec => '-0d1.9999999999999998p+0001' };
push @tests, { src => '7FE0000000000000', exp_hex => '+0x1.0000000000000p+1023', exp_dec => '+0d1.0000000000000000p+1023' };
push @tests, { src => 'FFE0000000000000', exp_hex => '-0x1.0000000000000p+1023', exp_dec => '-0d1.0000000000000000p+1023' };
push @tests, { src => '7FE0000000000001', exp_hex => '+0x1.0000000000001p+1023', exp_dec => '+0d1.0000000000000002p+1023' };
push @tests, { src => 'FFE0000000000001', exp_hex => '-0x1.0000000000001p+1023', exp_dec => '-0d1.0000000000000002p+1023' };
push @tests, { src => '7FEFFFFFFFFFFFFF', exp_hex => '+0x1.fffffffffffffp+1023', exp_dec => '+0d1.9999999999999998p+1023' };
push @tests, { src => 'FFEFFFFFFFFFFFFF', exp_hex => '-0x1.fffffffffffffp+1023', exp_dec => '-0d1.9999999999999998p+1023' };
push @tests, { src => '7FF0000000000000', exp_hex => '+0x1.#INF000000000p+0000', exp_dec => '+0d1.#INF000000000000p+0000' };
push @tests, { src => 'FFF0000000000000', exp_hex => '-0x1.#INF000000000p+0000', exp_dec => '-0d1.#INF000000000000p+0000' };
push @tests, { src => '7FF0000000000001', exp_hex => '+0x1.#SNAN00000000p+0000', exp_dec => '+0d1.#SNAN00000000000p+0000' };
push @tests, { src => 'FFF0000000000001', exp_hex => '-0x1.#SNAN00000000p+0000', exp_dec => '-0d1.#SNAN00000000000p+0000' };
push @tests, { src => '7FF7FFFFFFFFFFFF', exp_hex => '+0x1.#SNAN00000000p+0000', exp_dec => '+0d1.#SNAN00000000000p+0000' };
push @tests, { src => 'FFF7FFFFFFFFFFFF', exp_hex => '-0x1.#SNAN00000000p+0000', exp_dec => '-0d1.#SNAN00000000000p+0000' };
push @tests, { src => '7FF8000000000000', exp_hex => '+0x1.#QNAN00000000p+0000', exp_dec => '+0d1.#QNAN00000000000p+0000' };
push @tests, { src => 'FFF8000000000000', exp_hex => '-0x1.#IND000000000p+0000', exp_dec => '-0d1.#IND000000000000p+0000' };
push @tests, { src => '7FF8000000000001', exp_hex => '+0x1.#QNAN00000000p+0000', exp_dec => '+0d1.#QNAN00000000000p+0000' };
push @tests, { src => 'FFF8000000000001', exp_hex => '-0x1.#QNAN00000000p+0000', exp_dec => '-0d1.#QNAN00000000000p+0000' };
push @tests, { src => '7FFFFFFFFFFFFFFF', exp_hex => '+0x1.#QNAN00000000p+0000', exp_dec => '+0d1.#QNAN00000000000p+0000' };
push @tests, { src => 'FFFFFFFFFFFFFFFF', exp_hex => '-0x1.#QNAN00000000p+0000', exp_dec => '-0d1.#QNAN00000000000p+0000' };

plan tests => 2 * scalar @tests;


fptest( $_ ) foreach (@tests);
exit;
