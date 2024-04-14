#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);
use List::Util        qw(shuffle);

plan tests => 145;

##################################

sub test_array ($arr) {

    my @copy = @$arr;

    is_deeply(mtf_decode(mtf_encode($arr)),                      $arr);
    is_deeply(abc_decode(abc_encode($arr)),                      $arr);
    is_deeply(ac_decode(ac_encode($arr)),                        $arr);
    is_deeply(adaptive_ac_decode(adaptive_ac_encode($arr)),      $arr);
    is_deeply(elias_gamma_decode(elias_gamma_encode($arr)),      $arr);
    is_deeply(elias_omega_decode(elias_omega_encode($arr)),      $arr);
    is_deeply(fibonacci_decode(fibonacci_encode($arr)),          $arr);
    is_deeply(delta_decode(delta_encode($arr)),                  $arr);
    is_deeply(rle4_decode(rle4_encode($arr)),                    $arr);
    is_deeply(zrle_decode(zrle_encode($arr)),                    $arr);
    is_deeply([map { ($_->[0]) x $_->[1] } @{run_length($arr)}], $arr);

    is_deeply(obh_decode(obh_encode($arr)), $arr);
    is_deeply(obh_decode(obh_encode($arr, \&obh_encode),               \&obh_decode),               $arr);
    is_deeply(obh_decode(obh_encode($arr, \&create_ac_entry),          \&decode_ac_entry),          $arr);
    is_deeply(obh_decode(obh_encode($arr, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    is_deeply(mrl_decompress(mrl_compress($arr)),                                                                $arr);
    is_deeply(mrl_decompress(mrl_compress($arr, undef, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic($arr)), $arr);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic($arr, undef, \&create_ac_entry),          \&decode_ac_entry),          $arr);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic($arr, undef, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    is_deeply($arr, \@copy);    # make sure the array has not been modified in-place
}

test_array([]);
test_array([1]);
test_array([0]);
test_array([shuffle((map { int(rand(100)) } 1 .. 20), (map { int(rand(1e6)) } 1 .. 10), 0, 5, 9, 999_999, 1_000_000, 1_000_001, 42, 1)]);

is(bz2_decompress(bz2_compress('a')),   'a');
is(lzss_decompress(lzss_compress('a')), 'a');
is(lzhd_decompress(lzhd_compress('a')), 'a');
is(lzw_decompress(lzw_compress('a')),   'a');

is(bz2_decompress(bz2_compress('')),   '');
is(lzss_decompress(lzss_compress('')), '');
is(lzhd_decompress(lzhd_compress('')), '');
is(lzw_decompress(lzw_compress('')),   '');

is_deeply(mrl_decompress(mrl_compress([])),         []);
is_deeply(mrl_decompress(mrl_compress([0])),        [0]);
is_deeply(mrl_decompress(mrl_compress('a')),        [ord('a')]);
is_deeply(mrl_decompress(mrl_compress([ord('a')])), [ord('a')]);

is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic('a')), [ord('a')]);
is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic([1])), [1]);
is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic([0])), [0]);
is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic([])),  []);

##################################

{
    my @symbols = unpack('C*', join('', 'a' x 13, 'b' x 14, 'c' x 10, 'd' x 3, 'e' x 1, 'f' x 1, 'g' x 4));
    my @copy    = @symbols;

    my $rl  = run_length(\@symbols);
    my $rl2 = run_length(\@symbols, 10);

    is(scalar(@$rl),  7);
    is(scalar(@$rl2), 9);

    is_deeply([map { ($_->[0]) x $_->[1] } @$rl],  \@symbols);
    is_deeply([map { ($_->[0]) x $_->[1] } @$rl2], \@symbols);

    is_deeply(rle4_decode(rle4_encode(\@symbols)), \@symbols);

    is_deeply(decode_huffman_entry(create_huffman_entry(\@symbols)),         \@symbols);
    is_deeply(decode_ac_entry(create_ac_entry(\@symbols)),                   \@symbols);
    is_deeply(decode_adaptive_ac_entry(create_adaptive_ac_entry(\@symbols)), \@symbols);

    is_deeply(mrl_decompress(mrl_compress(\@symbols)),                                              \@symbols);
    is_deeply(mrl_decompress(mrl_compress(\@symbols, undef, \&create_ac_entry), \&decode_ac_entry), \@symbols);

    is_deeply(lzw_decompress(lzw_compress(pack('C*', @symbols))), pack('C*', @symbols));
    is_deeply(lzw_decompress(lzw_compress(pack('C*', @symbols), undef, \&delta_encode),             undef, \&delta_decode),             pack('C*', @symbols));
    is_deeply(lzw_decompress(lzw_compress(pack('C*', @symbols), undef, \&elias_omega_encode),       undef, \&elias_omega_decode),       pack('C*', @symbols));
    is_deeply(lzw_decompress(lzw_compress(pack('C*', @symbols), undef, \&fibonacci_encode),         undef, \&fibonacci_decode),         pack('C*', @symbols));
    is_deeply(lzw_decompress(lzw_compress(pack('C*', @symbols), undef, \&elias_gamma_encode),       undef, \&elias_gamma_decode),       pack('C*', @symbols));
    is_deeply(lzw_decompress(lzw_compress(pack('C*', @symbols), undef, \&create_ac_entry),          undef, \&decode_ac_entry),          pack('C*', @symbols));
    is_deeply(lzw_decompress(lzw_compress(pack('C*', @symbols), undef, \&create_huffman_entry),     undef, \&decode_huffman_entry),     pack('C*', @symbols));
    is_deeply(lzw_decompress(lzw_compress(pack('C*', @symbols), undef, \&create_adaptive_ac_entry), undef, \&decode_adaptive_ac_entry), pack('C*', @symbols));

    is_deeply(lz77_decompress(lz77_compress(pack('C*', @symbols))), pack('C*', @symbols));
    is_deeply(lz77_decompress(lz77_compress(pack('C*', @symbols), undef, \&create_ac_entry),          undef, \&decode_ac_entry),          pack('C*', @symbols));
    is_deeply(lz77_decompress(lz77_compress(pack('C*', @symbols), undef, \&create_adaptive_ac_entry), undef, \&decode_adaptive_ac_entry), pack('C*', @symbols));

    is_deeply(lzss_decompress(lzss_compress(pack('C*', @symbols))), pack('C*', @symbols));
    is_deeply(lzss_decompress(lzss_compress(pack('C*', @symbols), undef, \&create_ac_entry),          undef, \&decode_ac_entry),          pack('C*', @symbols));
    is_deeply(lzss_decompress(lzss_compress(pack('C*', @symbols), undef, \&create_adaptive_ac_entry), undef, \&decode_adaptive_ac_entry), pack('C*', @symbols));

    is_deeply(lzhd_decompress(lzhd_compress(pack('C*', @symbols))), pack('C*', @symbols));
    is_deeply(lzhd_decompress(lzhd_compress(pack('C*', @symbols), undef, \&create_ac_entry),          undef, \&decode_ac_entry),          pack('C*', @symbols));
    is_deeply(lzhd_decompress(lzhd_compress(pack('C*', @symbols), undef, \&create_adaptive_ac_entry), undef, \&decode_adaptive_ac_entry), pack('C*', @symbols));

    is_deeply(bz2_decompress(bz2_compress(pack('C*', @symbols))), pack('C*', @symbols));
    is_deeply(bz2_decompress(bz2_compress(pack('C*', @symbols), undef, \&create_ac_entry),          undef, \&decode_ac_entry),          pack('C*', @symbols));
    is_deeply(bz2_decompress(bz2_compress(pack('C*', @symbols), undef, \&create_adaptive_ac_entry), undef, \&decode_adaptive_ac_entry), pack('C*', @symbols));

    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic(\@symbols)), \@symbols);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic(\@symbols, undef, \&create_ac_entry),          \&decode_ac_entry),          \@symbols);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic(\@symbols, undef, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), \@symbols);

    is_deeply(\@symbols, \@copy);    # make sure the array has not been modified in-place
}

##################################

{
    my $bitstring = "101000010000000010000000100000000001001100010000000000000010010100000000000000001";

    my $encoded = binary_vrl_encode($bitstring);
    my $decoded = binary_vrl_decode($encoded);

    is($decoded, $bitstring);
    is($encoded, "1000110101110110111010011110001010101100011110101010000111101110");
}

##############################################

{
    my $str = "INEFICIENCIES";

    {
        my $encoded = mtf_encode([unpack('C*', $str)], [ord('A') .. ord('Z')]);
        my $decoded = mtf_decode($encoded, [ord('A') .. ord('Z')]);

        is(join(' ', @$encoded), '8 13 6 7 3 6 1 3 4 3 3 3 18');
        is($str,                 pack('C*', @$decoded));
    }

    {
        my ($encoded, $alphabet) = mtf_encode([unpack('C*', $str)]);
        my $decoded = mtf_decode($encoded, $alphabet);

        is(join(' ', @$encoded), '3 4 3 4 3 4 1 3 4 3 3 3 5');
        is($str,                 pack('C*', @$decoded));
    }
}

##############################################

{
    my $int    = int(rand(1e6));
    my $binary = pack('b*', int2bits_lsb($int, 32));
    open my $fh, '<:raw', \$binary;
    my $dec = bits2int_lsb($fh, 32, \my $buffer);
    is($int, $dec);
}

{
    my $int    = int(rand(1e6));
    my $binary = pack('B*', int2bits($int, 32));
    open my $fh, '<:raw', \$binary;
    my $dec = bits2int($fh, 32, \my $buffer);
    is($int, $dec);
}

##############################################

{
    my $str = "foo\0bar\0abracadabra\0";
    open my $fh, '<:raw', \$str;

    my $word1 = read_null_terminated($fh);
    my $word2 = read_null_terminated($fh);
    my $word3 = read_null_terminated($fh);

    is($word1, "foo");
    is($word2, "bar");
    is($word3, "abracadabra");
}
