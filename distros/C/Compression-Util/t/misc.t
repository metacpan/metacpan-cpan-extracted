#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);
use List::Util        qw(shuffle);

plan tests => 70;

##################################

sub test_array ($arr) {

    my @copy = @$arr;

    is_deeply(abc_decode(abc_encode($arr)),                      $arr);
    is_deeply(ac_decode(ac_encode($arr)),                        $arr);
    is_deeply(adaptive_ac_decode(adaptive_ac_encode($arr)),      $arr);
    is_deeply(elias_gamma_decode(elias_gamma_encode($arr)),      $arr);
    is_deeply(elias_omega_decode(elias_omega_encode($arr)),      $arr);
    is_deeply(fibonacci_decode(fibonacci_encode($arr)),          $arr);
    is_deeply(delta_decode(delta_encode($arr)),                  $arr);
    is_deeply(rle4_decode(rle4_decode($arr)),                    $arr);
    is_deeply([map { ($_->[0]) x $_->[1] } @{run_length($arr)}], $arr);

    is_deeply(obh_decode(obh_encode($arr)), $arr);
    is_deeply(obh_decode(obh_encode($arr, \&create_ac_entry),          \&decode_ac_entry),          $arr);
    is_deeply(obh_decode(obh_encode($arr, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic($arr)), $arr);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic($arr, undef, \&create_ac_entry),          \&decode_ac_entry),          $arr);
    is_deeply(bz2_decompress_symbolic(bz2_compress_symbolic($arr, undef, \&create_adaptive_ac_entry), \&decode_adaptive_ac_entry), $arr);

    is_deeply($arr, \@copy);    # make sure the array has not been modified in-place
}

#test_array([]); # FIXME
test_array([1]);
test_array([shuffle((map { int(rand(100)) } 1 .. 20), (map { int(rand(1e6)) } 1 .. 10), 0, 5, 9, 999_999, 1_000_000, 1_000_001, 42, 1)]);

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
