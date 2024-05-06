#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);
use List::Util        qw(shuffle);

plan tests => 523;

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

    is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic($arr)), $arr);
    is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic($arr, \&delta_encode),             \&delta_decode),             $arr);
    is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic($arr, \&obh_encode),               \&obh_decode),               $arr);
    is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic($arr, \&create_ac_entry),          \&decode_ac_entry),          $arr);
    is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic($arr, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    is_deeply(lz77_decode_symbolic(lz77_encode_symbolic($arr)), $arr);
    is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic($arr, \&delta_encode),             \&delta_decode),             $arr);
    is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic($arr, \&obh_encode),               \&obh_decode),               $arr);
    is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic($arr, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    my ($mtf, $alphabet) = mtf_encode($arr);
    is_deeply(mtf_decode(lz77_decompress_symbolic(lz77_compress_symbolic($mtf)), $alphabet), $arr);

    is_deeply(obh_decode(obh_encode($arr)), $arr);
    is_deeply(obh_decode(obh_encode($arr, \&obh_encode),               \&obh_decode),               $arr);
    is_deeply(obh_decode(obh_encode($arr, \&create_ac_entry),          \&decode_ac_entry),          $arr);
    is_deeply(obh_decode(obh_encode($arr, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic($arr)),                                                         $arr);
    is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic($arr, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic($arr)), $arr);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic($arr, \&create_ac_entry),          \&decode_ac_entry),          $arr);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic($arr, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    is_deeply($arr, \@copy);    # make sure the array has not been modified in-place
}

test_array([]);
test_array([1]);
test_array([0]);
test_array([shuffle((map { int(rand(100)) } 1 .. 20), (map { int(rand(1e6)) } 1 .. 10), 0, 5, 9, 999_999, 1_000_000, 1_000_001, 42, 1)]);

foreach my $str (
                 "abbaabbaabaabaaaa",     "abbaabbaabaabaaaaz",     "abbaabbaabaabaaaazz",     "abbaabbaabaabaaaazzz",
                 "abbaabbaabaabaaaazzzz", "abbaabbaabaabaaaazzzzz", "abbaabbaabaabaaaazzzzzz", 'a' x 291,
                 join('', 'a' x 280, 'b' x 301),
  ) {
    test_array(string2symbols($str));

    is(lzss_decompress(lzss_compress($str)),                                             $str);
    is(lzss_decompress(lzss_compress($str, \&create_huffman_entry, \&lzss_encode_fast)), $str);
    is(lzw_decompress(lzw_compress($str)),                                               $str);
    is(bz2_decompress(bz2_compress($str)),                                               $str);
    is(symbols2string(mrl_decompress_symbolic(mrl_compress_symbolic($str))),             $str);
}

is(bz2_decompress(bz2_compress('a')),                                               'a');
is(lzss_decompress(lzss_compress('a')),                                             'a');
is(lzss_decompress(lzss_compress('a', \&create_huffman_entry, \&lzss_encode_fast)), 'a');
is(lzw_decompress(lzw_compress('a')),                                               'a');

is(bz2_decompress(bz2_compress('')),                                               '');
is(lzss_decompress(lzss_compress('')),                                             '');
is(lzss_decompress(lzss_compress('', \&create_huffman_entry, \&lzss_encode_fast)), '');
is(lzw_decompress(lzw_compress('')),                                               '');

is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic([])),         []);
is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic([0])),        [0]);
is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic('a')),        [ord('a')]);
is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic([ord('a')])), [ord('a')]);

is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic('a')), [ord('a')]);
is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic([1])), [1]);
is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic([0])), [0]);
is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic([])),  []);

is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic('a')), [ord('a')]);
is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic([1])), [1]);
is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic([0])), [0]);
is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic([])),  []);

##################################

{
    my $str     = join('', 'a' x 13, 'b' x 14, 'c' x 10, 'd' x 3, 'e' x 1, 'f' x 1, 'g' x 4);
    my @symbols = unpack('C*', $str);
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

    is(lz77_decode(lz77_encode($str)), $str);
    is_deeply(lz77_decode_symbolic(lz77_encode_symbolic(\@symbols)), \@symbols);

    is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic(\@symbols)),                                       \@symbols);
    is_deeply(mrl_decompress_symbolic(mrl_compress_symbolic(\@symbols, \&create_ac_entry), \&decode_ac_entry), \@symbols);

    is(lzw_decompress(lzw_compress($str)), $str);
    is(lzw_decompress(lzw_compress($str, \&delta_encode),             \&delta_decode),             $str);
    is(lzw_decompress(lzw_compress($str, \&elias_omega_encode),       \&elias_omega_decode),       $str);
    is(lzw_decompress(lzw_compress($str, \&fibonacci_encode),         \&fibonacci_decode),         $str);
    is(lzw_decompress(lzw_compress($str, \&elias_gamma_encode),       \&elias_gamma_decode),       $str);
    is(lzw_decompress(lzw_compress($str, \&create_ac_entry),          \&decode_ac_entry),          $str);
    is(lzw_decompress(lzw_compress($str, \&create_huffman_entry),     \&decode_huffman_entry),     $str);
    is(lzw_decompress(lzw_compress($str, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $str);

    is(lz77_decompress(lz77_compress($str)), $str);
    is(lz77_decompress(lz77_compress($str, \&create_ac_entry),          \&decode_ac_entry),          $str);
    is(lz77_decompress(lz77_compress($str, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $str);

    is(lzss_decompress(lzss_compress($str)), $str);
    is(lzss_decompress(lzss_compress($str, \&create_ac_entry),          \&decode_ac_entry),          $str);
    is(lzss_decompress(lzss_compress($str, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $str);

    is(bz2_decompress(bz2_compress($str)), $str);
    is(bz2_decompress(bz2_compress($str, \&create_ac_entry),          \&decode_ac_entry),          $str);
    is(bz2_decompress(bz2_compress($str, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $str);

    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic(\@symbols)), \@symbols);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic(\@symbols, \&create_ac_entry),          \&decode_ac_entry),          \@symbols);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic(\@symbols, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), \@symbols);

    is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic(\@symbols)), \@symbols);
    is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic(\@symbols, \&create_ac_entry),          \&decode_ac_entry),          \@symbols);
    is_deeply(lz77_decompress_symbolic(lz77_compress_symbolic(\@symbols, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), \@symbols);

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
        my $encoded = mtf_encode(string2symbols($str), [ord('A') .. ord('Z')]);
        my $decoded = mtf_decode($encoded, [ord('A') .. ord('Z')]);

        is(join(' ', @$encoded), '8 13 6 7 3 6 1 3 4 3 3 3 18');
        is($str,                 symbols2string($decoded));
    }

    {
        my ($encoded, $alphabet) = mtf_encode(string2symbols($str));
        my $decoded = mtf_decode($encoded, $alphabet);

        is(join(' ', @$encoded), '3 4 3 4 3 4 1 3 4 3 3 3 5');
        is($str,                 symbols2string($decoded));
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
    my $int1 = int(rand(1 << 5));
    my $int2 = int(rand(1 << 6));
    my $int3 = int(rand(1e6));

    my $binary = pack('b*', int2bits_lsb($int1, 5) . int2bits_lsb($int2, 6) . int2bits_lsb($int3, 32));
    open my $fh, '<:raw', \$binary;

    my $buffer = '';
    my $dec1   = bits2int_lsb($fh, 5,  \$buffer);
    my $dec2   = bits2int_lsb($fh, 6,  \$buffer);
    my $dec3   = bits2int_lsb($fh, 32, \$buffer);

    is($int1, $dec1);
    is($int2, $dec2);
    is($int3, $dec3);
}

{
    my $int    = int(rand(1e6));
    my $binary = pack('b*', int2bits_lsb($int, 32));
    open my $fh, '<:raw', \$binary;
    my $dec = oct('0b' . scalar reverse read_bits_lsb($fh, 32));
    is($int, $dec);
}

{
    my $int    = int(rand(1e6));
    my $binary = pack('B*', int2bits($int, 32));
    open my $fh, '<:raw', \$binary;
    my $dec = bits2int($fh, 32, \my $buffer);
    is($int, $dec);
}

{
    my $int1 = int(rand(1 << 5));
    my $int2 = int(rand(1 << 6));
    my $int3 = int(rand(1e6));

    my $binary = pack('B*', int2bits($int1, 5) . int2bits($int2, 6) . int2bits($int3, 32));
    open my $fh, '<:raw', \$binary;

    my $buffer = '';
    my $dec1   = bits2int($fh, 5,  \$buffer);
    my $dec2   = bits2int($fh, 6,  \$buffer);
    my $dec3   = bits2int($fh, 32, \$buffer);

    is($int1, $dec1);
    is($int2, $dec2);
    is($int3, $dec3);
}

{
    my $int    = int(rand(1e6));
    my $binary = pack('B*', int2bits($int, 32));
    open my $fh, '<:raw', \$binary;
    my $dec = oct('0b' . read_bits($fh, 32));
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
