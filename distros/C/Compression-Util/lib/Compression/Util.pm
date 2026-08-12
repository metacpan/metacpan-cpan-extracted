package Compression::Util;

use utf8;
use 5.036;
use List::Util qw(min uniq max sum all);
use Carp       qw(confess);

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.17';
our $VERBOSE = 0;        # verbose mode

our $LZ_MIN_LEN         = 4;          # minimum match length in LZ parsing
our $LZ_MAX_LEN         = 1 << 15;    # maximum match length in LZ parsing
our $LZ_MAX_DIST        = ~0;         # maximum allowed back-reference distance in LZ parsing
our $LZ_MAX_CHAIN_LEN   = 32;         # how many recent positions to remember in LZ parsing
our $LZ_MAX_CHAIN_WIDTH = 1024;       # maximum number of positions to remember for each match

# Arithmetic Coding settings
use constant BITS         => 32;
use constant MAX          => oct('0b' . ('1' x BITS));
use constant INITIAL_FREQ => 1;

our %EXPORT_TAGS = (
    'all' => [
        qw(

          crc32
          adler32

          read_bit
          read_bit_lsb

          read_bits
          read_bits_lsb

          int2bits
          int2bits_lsb

          int2bytes
          int2bytes_lsb

          bits2int
          bits2int_lsb

          bytes2int
          bytes2int_lsb

          string2symbols
          symbols2string

          read_null_terminated

          bwt_encode
          bwt_decode

          bwt_encode_symbolic
          bwt_decode_symbolic

          bwt_sort
          bwt_sort_symbolic

          bwt_compress
          bwt_decompress

          bwt_compress_symbolic
          bwt_decompress_symbolic

          bzip2_compress
          bzip2_decompress

          gzip_compress
          gzip_decompress

          mrl_compress
          mrl_decompress

          mrl_compress_symbolic
          mrl_decompress_symbolic

          create_huffman_entry
          decode_huffman_entry

          delta_encode
          delta_decode

          huffman_encode
          huffman_decode

          huffman_from_freq
          huffman_from_symbols
          huffman_from_code_lengths

          mtf_encode
          mtf_decode

          encode_alphabet
          decode_alphabet

          encode_alphabet_256
          decode_alphabet_256

          deltas
          accumulate
          frequencies

          run_length

          binary_vrl_encode
          binary_vrl_decode

          rle4_encode
          rle4_decode

          zrle_encode
          zrle_decode

          lzss_compress
          lzss_decompress

          make_deflate_tables
          find_deflate_index

          deflate_encode
          deflate_decode

          lzss_encode
          lzss_encode_hash4
          lzss_encode_fast
          lzss_encode_fast_symbolic
          lzss_decode

          lzss_encode_symbolic
          lzss_decode_symbolic

          lzss_compress_symbolic
          lzss_decompress_symbolic

          lz77_encode
          lz77_decode

          lz77_encode_symbolic
          lz77_decode_symbolic

          lz77_compress
          lz77_decompress

          lz77_compress_symbolic
          lz77_decompress_symbolic

          lzb_compress
          lzb_decompress

          lz4_compress
          lz4_decompress

          ac_encode
          ac_decode

          create_ac_entry
          decode_ac_entry

          adaptive_ac_encode
          adaptive_ac_decode

          create_adaptive_ac_entry
          decode_adaptive_ac_entry

          abc_encode
          abc_decode

          fibonacci_encode
          fibonacci_decode

          elias_gamma_encode
          elias_gamma_decode

          elias_omega_encode
          elias_omega_decode

          obh_encode
          obh_decode

          lzw_encode
          lzw_decode

          lzw_compress
          lzw_decompress

          zlib_compress
          zlib_decompress

          deflate_create_block_type_0_header
          deflate_create_block_type_1
          deflate_create_block_type_2

          deflate_extract_next_block
          deflate_extract_block_type_0
          deflate_extract_block_type_1
          deflate_extract_block_type_2
          )
    ]
);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}}, '$VERBOSE', '$LZ_MAX_CHAIN_LEN', '$LZ_MAX_CHAIN_WIDTH', '$LZ_MIN_LEN', '$LZ_MAX_LEN', '$LZ_MAX_DIST');
our @EXPORT;

##########################
# Misc low-level functions
##########################

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // confess "can't read bit");
    }

    chop($$bitstring);
}

sub read_bit_lsb ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('B*', getc($fh) // confess "can't read bit");
    }

    chop($$bitstring);
}

sub read_bits ($fh, $bits_len) {

    read($fh, (my $data), $bits_len >> 3) // confess "Read error: $!";
    $data = unpack('B*', $data);

    while (length($data) < $bits_len) {
        $data .= unpack('B*', getc($fh) // confess "can't read bits");
    }

    if (length($data) > $bits_len) {
        $data = substr($data, 0, $bits_len);
    }

    return $data;
}

sub read_bits_lsb ($fh, $bits_len) {

    read($fh, (my $data), $bits_len >> 3) // confess "Read error: $!";
    $data = unpack('b*', $data);

    while (length($data) < $bits_len) {
        $data .= unpack('b*', getc($fh) // confess "can't read bits");
    }

    if (length($data) > $bits_len) {
        $data = substr($data, 0, $bits_len);
    }

    return $data;
}

sub int2bits ($value, $size) {
    sprintf("%0*b", $size, $value);
}

sub int2bits_lsb ($value, $size) {
    scalar reverse sprintf("%0*b", $size, $value);
}

sub int2bytes ($value, $size) {
    pack('B*', sprintf("%0*b", 8 * $size, $value));
}

sub int2bytes_lsb ($value, $size) {
    pack('b*', scalar reverse sprintf("%0*b", 8 * $size, $value));
}

sub bytes2int($fh, $n) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $n);
    }

    my $bytes = '';
    $bytes .= getc($fh) for (1 .. $n);
    oct('0b' . unpack('B*', $bytes));
}

sub bytes2int_lsb ($fh, $n) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $n);
    }

    my $bytes = '';
    $bytes .= getc($fh) for (1 .. $n);
    oct('0b' . reverse unpack('b*', $bytes));
}

sub bits2int ($fh, $size, $buffer) {

    if ($size % 8 == 0 and ($$buffer // '') eq '') {    # optimization
        return bytes2int($fh, $size >> 3);
    }

    my $bitstring = '0b';
    for (1 .. $size) {
        $bitstring .= ($$buffer // '') eq '' ? read_bit($fh, $buffer) : chop($$buffer);
    }
    oct($bitstring);
}

sub bits2int_lsb ($fh, $size, $buffer) {

    if ($size % 8 == 0 and ($$buffer // '') eq '') {    # optimization
        return bytes2int_lsb($fh, $size >> 3);
    }

    my $bitstring = '';
    for (1 .. $size) {
        $bitstring .= ($$buffer // '') eq '' ? read_bit_lsb($fh, $buffer) : chop($$buffer);
    }
    oct('0b' . reverse($bitstring));
}

sub string2symbols ($string) {
    [unpack('C*', $string)];
}

sub symbols2string ($symbols) {
    pack('C*', @$symbols);
}

sub read_null_terminated ($fh) {
    my $string = '';
    while (1) {
        my $c = getc($fh) // confess "can't read character";
        last if $c eq "\0";
        $string .= $c;
    }
    return $string;
}

sub frequencies ($symbols) {
    my %freq;
    ++$freq{$_} for @$symbols;
    return \%freq;
}

sub deltas ($integers) {

    my @deltas;
    my $prev = 0;

    foreach my $n (@$integers) {
        push @deltas, $n - $prev;
        $prev = $n;
    }

    return \@deltas;
}

sub accumulate ($deltas) {

    my @acc;
    my $prev = 0;

    foreach my $d (@$deltas) {
        $prev += $d;
        push @acc, $prev;
    }

    return \@acc;
}

########################
# Fibonacci Coding
########################

sub fibonacci_encode ($symbols) {

    my $bitstring = '';

    foreach my $n (scalar(@$symbols), @$symbols) {
        my ($f1, $f2, $f3) = (0, 1, 1);
        my ($rn, $s, $k) = ($n + 1, '', 2);
        for (; $f3 <= $rn ; ++$k) {
            ($f1, $f2, $f3) = ($f2, $f3, $f2 + $f3);
        }
        foreach my $i (1 .. $k - 2) {
            ($f3, $f2, $f1) = ($f2, $f1, $f2 - $f1);
            if ($f3 <= $rn) {
                $rn -= $f3;
                $s .= '1';
            }
            else {
                $s .= '0';
            }
        }
        $bitstring .= reverse($s) . '1';
    }

    pack('B*', $bitstring);
}

sub fibonacci_decode ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my @symbols;

    my $enc      = '';
    my $prev_bit = '0';

    my $len    = 0;
    my $buffer = '';

    for (my $k = 0 ; $k <= $len ;) {
        my $bit = read_bit($fh, \$buffer);

        if ($bit eq '1' and $prev_bit eq '1') {
            my ($value, $f1, $f2) = (0, 1, 1);
            foreach my $bit (split //, $enc) {
                $value += $f2 if $bit;
                ($f1, $f2) = ($f2, $f1 + $f2);
            }
            push @symbols, $value - 1;
            $len      = pop @symbols if (++$k == 1);
            $enc      = '';
            $prev_bit = '0';
        }
        else {
            $enc .= $bit;
            $prev_bit = $bit;
        }
    }

    return \@symbols;
}

#######################################
# Adaptive Binary Concatenation method
#######################################

sub abc_encode ($integers) {

    my @counts;
    my $count           = 0;
    my $bits_width      = 1;
    my $bits_max_symbol = 1 << $bits_width;
    my $processed_len   = 0;

    foreach my $k (@$integers) {
        while ($k >= $bits_max_symbol) {

            if ($count > 0) {
                push @counts, [$bits_width, $count];
                $processed_len += $count;
            }

            $count = 0;
            $bits_max_symbol *= 2;
            $bits_width      += 1;
        }
        ++$count;
    }

    push @counts, grep { $_->[1] > 0 } [$bits_width, scalar(@$integers) - $processed_len];

    $VERBOSE && say STDERR "Bit sizes: ", join(' ', map { $_->[0] } @counts);
    $VERBOSE && say STDERR "Lengths  : ", join(' ', map { $_->[1] } @counts);
    $VERBOSE && say STDERR '';

    my $compressed = fibonacci_encode([(map { $_->[0] } @counts), (map { $_->[1] } @counts)]);

    my $bits = '';
    my @ints = @$integers;

    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        foreach my $symbol (splice(@ints, 0, $len)) {
            $bits .= sprintf("%0*b", $blen, $symbol);
        }
    }

    $compressed .= pack('B*', $bits);
    return $compressed;
}

sub abc_decode ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my $ints = fibonacci_decode($fh);
    my $half = scalar(@$ints) >> 1;

    my @counts;
    foreach my $i (0 .. ($half - 1)) {
        push @counts, [$ints->[$i], $ints->[$half + $i]];
    }

    my $bits_len = 0;

    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        $bits_len += $blen * $len;
    }

    my $bits = read_bits($fh, $bits_len);

    my @integers;
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        foreach my $chunk (unpack(sprintf('(a%d)*', $blen), substr($bits, 0, $blen * $len, ''))) {
            push @integers, oct('0b' . $chunk);
        }
    }

    return \@integers;
}

###################################
# Arithmetic Coding (in fixed bits)
###################################

sub _create_cfreq ($freq) {

    my @cf;
    my $T = 0;

    foreach my $i (sort { $a <=> $b } keys %$freq) {
        $freq->{$i} // next;
        $cf[$i] = $T;
        $T += $freq->{$i};
        $cf[$i + 1] = $T;
    }

    return (\@cf, $T);
}

sub ac_encode ($symbols) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my $enc        = '';
    my $EOF_SYMBOL = (max(@$symbols) // 0) + 1;
    my @bytes      = (@$symbols, $EOF_SYMBOL);

    my $freq = frequencies(\@bytes);
    my ($cf, $T) = _create_cfreq($freq);

    if ($T > MAX) {
        confess "Too few bits: $T > ${\MAX}";
    }

    my $low      = 0;
    my $high     = MAX;
    my $uf_count = 0;

    foreach my $c (@bytes) {

        my $w = $high - $low + 1;

        $high = ($low + int(($w * $cf->[$c + 1]) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf->[$c]) / $T)) & MAX;

        if ($high > MAX) {
            confess "high > MAX: $high > ${\MAX}";
        }

        if ($low >= $high) { confess "$low >= $high" }

        while (1) {

            if (($high >> (BITS - 1)) == ($low >> (BITS - 1))) {

                my $bit = $high >> (BITS - 1);
                $enc .= $bit;

                if ($uf_count > 0) {
                    $enc .= join('', 1 - $bit) x $uf_count;
                    $uf_count = 0;
                }

                $low <<= 1;
                ($high <<= 1) |= 1;
            }
            elsif (((($low >> (BITS - 2)) & 0x1) == 1) && ((($high >> (BITS - 2)) & 0x1) == 0)) {
                ($high <<= 1) |= (1 << (BITS - 1));
                $high |= 1;
                ($low <<= 1) &= ((1 << (BITS - 1)) - 1);
                ++$uf_count;
            }
            else {
                last;
            }

            $low  &= MAX;
            $high &= MAX;
        }
    }

    $enc .= '0';
    $enc .= '1';

    while (length($enc) % 8 != 0) {
        $enc .= '1';
    }

    return ($enc, $freq);
}

sub ac_decode ($fh, $freq) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $freq);
    }

    my ($cf, $T) = _create_cfreq($freq);

    my @dec;
    my $low  = 0;
    my $high = MAX;
    my $enc  = oct('0b' . join '', map { getc($fh) // 1 } 1 .. BITS);

    my @table;
    foreach my $i (sort { $a <=> $b } keys %$freq) {
        foreach my $j ($cf->[$i] .. $cf->[$i + 1] - 1) {
            $table[$j] = $i;
        }
    }

    my $EOF_SYMBOL = max(keys %$freq) // 0;

    while (1) {

        my $w  = $high - $low + 1;
        my $ss = int((($T * ($enc - $low + 1)) - 1) / $w);

        my $i = $table[$ss] // last;
        last if ($i == $EOF_SYMBOL);

        push @dec, $i;

        $high = ($low + int(($w * $cf->[$i + 1]) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf->[$i]) / $T)) & MAX;

        if ($high > MAX) {
            confess "error";
        }

        if ($low >= $high) { confess "$low >= $high" }

        while (1) {

            if (($high >> (BITS - 1)) == ($low >> (BITS - 1))) {
                ($high <<= 1) |= 1;
                $low <<= 1;
                ($enc <<= 1) |= (getc($fh) // 1);
            }
            elsif (((($low >> (BITS - 2)) & 0x1) == 1) && ((($high >> (BITS - 2)) & 0x1) == 0)) {
                ($high <<= 1) |= (1 << (BITS - 1));
                $high |= 1;
                ($low <<= 1) &= ((1 << (BITS - 1)) - 1);
                $enc = (($enc >> (BITS - 1)) << (BITS - 1)) | (($enc & ((1 << (BITS - 2)) - 1)) << 1) | (getc($fh) // 1);
            }
            else {
                last;
            }

            $low  &= MAX;
            $high &= MAX;
            $enc  &= MAX;
        }
    }

    return \@dec;
}

#############################################
# Adaptive Arithemtic Coding (in fixed bits)
#############################################

sub _create_adaptive_cfreq ($freq_value, $alphabet_size) {

    my $T = 0;
    my (@cf, @freq);

    foreach my $i (0 .. $alphabet_size) {
        $freq[$i] = $freq_value;
        $cf[$i]   = $T;
        $T += $freq_value;
        $cf[$i + 1] = $T;
    }

    return (\@freq, \@cf, $T);
}

sub _increment_freq ($c, $alphabet_size, $freq, $cf) {

    ++$freq->[$c];
    my $T = $cf->[$c];

    foreach my $i ($c .. $alphabet_size) {
        $cf->[$i] = $T;
        $T += $freq->[$i];
        $cf->[$i + 1] = $T;
    }

    return $T;
}

sub adaptive_ac_encode ($symbols) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my $enc        = '';
    my @alphabet   = sort { $a <=> $b } uniq(@$symbols);
    my $EOF_SYMBOL = scalar(@alphabet) ? ($alphabet[-1] + 1) : 1;
    push @alphabet, $EOF_SYMBOL;

    my $alphabet_size = $#alphabet;
    my ($freq, $cf, $T) = _create_adaptive_cfreq(INITIAL_FREQ, $alphabet_size);

    my %table;
    @table{@alphabet} = (0 .. $alphabet_size);

    if ($T > MAX) {
        confess "Too few bits: $T > ${\MAX}";
    }

    my $low      = 0;
    my $high     = MAX;
    my $uf_count = 0;

    foreach my $value (@$symbols, $EOF_SYMBOL) {

        my $c = $table{$value};
        my $w = $high - $low + 1;

        $high = ($low + int(($w * $cf->[$c + 1]) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf->[$c]) / $T)) & MAX;

        $T = _increment_freq($c, $alphabet_size, $freq, $cf);

        if ($high > MAX) {
            confess "high > MAX: $high > ${\MAX}";
        }

        if ($low >= $high) { confess "$low >= $high" }

        while (1) {

            if (($high >> (BITS - 1)) == ($low >> (BITS - 1))) {

                my $bit = $high >> (BITS - 1);
                $enc .= $bit;

                if ($uf_count > 0) {
                    $enc .= join('', 1 - $bit) x $uf_count;
                    $uf_count = 0;
                }

                $low <<= 1;
                ($high <<= 1) |= 1;
            }
            elsif (((($low >> (BITS - 2)) & 0x1) == 1) && ((($high >> (BITS - 2)) & 0x1) == 0)) {
                ($high <<= 1) |= (1 << (BITS - 1));
                $high |= 1;
                ($low <<= 1) &= ((1 << (BITS - 1)) - 1);
                ++$uf_count;
            }
            else {
                last;
            }

            $low  &= MAX;
            $high &= MAX;
        }
    }

    $enc .= '0';
    $enc .= '1';

    while (length($enc) % 8 != 0) {
        $enc .= '1';
    }

    return ($enc, \@alphabet);
}

sub adaptive_ac_decode ($fh, $alphabet) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $alphabet);
    }

    my @dec;
    my $low  = 0;
    my $high = MAX;

    my $alphabet_size = $#{$alphabet};
    my ($freq, $cf, $T) = _create_adaptive_cfreq(INITIAL_FREQ, $alphabet_size);

    my $enc = oct('0b' . join '', map { getc($fh) // 1 } 1 .. BITS);

    while (1) {
        my $w  = ($high + 1) - $low;
        my $ss = int((($T * ($enc - $low + 1)) - 1) / $w);

        my $i = 0;
        foreach my $j (0 .. $alphabet_size) {
            if ($cf->[$j] <= $ss and $ss < $cf->[$j + 1]) {
                $i = $j;
                last;
            }
        }

        last if ($i == $alphabet_size);
        push @dec, $alphabet->[$i];

        $high = ($low + int(($w * $cf->[$i + 1]) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf->[$i]) / $T)) & MAX;

        $T = _increment_freq($i, $alphabet_size, $freq, $cf);

        if ($high > MAX) {
            confess "high > MAX: ($high > ${\MAX})";
        }

        if ($low >= $high) { confess "$low >= $high" }

        while (1) {

            if (($high >> (BITS - 1)) == ($low >> (BITS - 1))) {
                ($high <<= 1) |= 1;
                $low <<= 1;
                ($enc <<= 1) |= (getc($fh) // 1);
            }
            elsif (((($low >> (BITS - 2)) & 0x1) == 1) && ((($high >> (BITS - 2)) & 0x1) == 0)) {
                ($high <<= 1) |= (1 << (BITS - 1));
                $high |= 1;
                ($low <<= 1) &= ((1 << (BITS - 1)) - 1);
                $enc = (($enc >> (BITS - 1)) << (BITS - 1)) | (($enc & ((1 << (BITS - 2)) - 1)) << 1) | (getc($fh) // 1);
            }
            else {
                last;
            }

            $low  &= MAX;
            $high &= MAX;
            $enc  &= MAX;
        }
    }

    return \@dec;
}

#####################
# Generic run-length
#####################

sub run_length ($arr, $max_run = undef) {

    @$arr || return [];

    my @result     = [$arr->[0], 1];
    my $prev_value = $arr->[0];

    foreach my $i (1 .. $#$arr) {

        my $curr_value = $arr->[$i];

        if ($curr_value == $prev_value and (defined($max_run) ? $result[-1][1] < $max_run : 1)) {
            ++$result[-1][1];
        }
        else {
            push(@result, [$curr_value, 1]);
        }

        $prev_value = $curr_value;
    }

    return \@result;
}

######################################
# Binary variable run-length encoding
######################################

sub binary_vrl_encode ($bitstring) {

    my @bits    = split(//, $bitstring);
    my $encoded = $bits[0];

    foreach my $rle (@{run_length(\@bits)}) {
        my ($c, $v) = @$rle;

        if ($v == 1) {
            $encoded .= '0';
        }
        else {
            my $t = sprintf('%b', $v - 1);
            $encoded .= join('', '1' x length($t), '0', substr($t, 1));
        }
    }

    return $encoded;
}

sub binary_vrl_decode ($bitstring) {

    my $decoded = '';
    my $bit     = substr($bitstring, 0, 1, '');

    while ($bitstring ne '') {

        $decoded .= $bit;

        my $bl = 0;
        while (substr($bitstring, 0, 1, '') eq '1') {
            ++$bl;
        }

        if ($bl > 0) {
            $decoded .= $bit x oct('0b1' . join('', map { substr($bitstring, 0, 1, '') } 1 .. $bl - 1));
        }

        $bit = ($bit eq '1' ? '0' : '1');
    }

    return $decoded;
}

############################
# Burrows-Wheeler transform
############################

sub bwt_sort ($s, $LOOKAHEAD_LEN = 128) {    # O(n * LOOKAHEAD_LEN) space (fast)
    my $len      = length($s);
    my $double_s = $s . $s;                  # Pre-compute doubled string

    # Schwartzian transform with optimized sorting
    return [
        map { $_->[1] }
        sort {
            ($a->[0] cmp $b->[0])
              || do {
                my ($cmp, $s_len) = (0, $LOOKAHEAD_LEN << 2);
                while (1) {
                    ($cmp = substr($double_s, $a->[1], $s_len) cmp substr($double_s, $b->[1], $s_len)) && last;
                    $s_len <<= 1;
                }
                $cmp;
            }
        }
        map {
            my $pos = $_;
            my $end = $pos + $LOOKAHEAD_LEN;

            # Handle wraparound efficiently
            my $t =
              ($end <= $len)
              ? substr($s,        $pos, $LOOKAHEAD_LEN)
              : substr($double_s, $pos, $LOOKAHEAD_LEN);

            [$t, $pos]
          } 0 .. $len - 1
    ];
}

sub bwt_encode ($s, $LOOKAHEAD_LEN = 128) {

    if (ref($s) ne '') {
        return bwt_encode_symbolic($s);
    }

    my $bwt = bwt_sort($s, $LOOKAHEAD_LEN);

    my $ret = '';
    my $idx = 0;

    my $i = 0;
    foreach my $pos (@$bwt) {
        $ret .= substr($s, $pos - 1, 1);
        $idx = $i if !$pos;
        ++$i;
    }

    return ($ret, $idx);
}

sub bwt_decode ($bwt, $idx) {
    my @L = unpack('C*', $bwt);
    my $n = scalar @L;

    my @freq = (0) x 256;
    $freq[$_]++ for @L;

    my @cumul = (0) x 257;
    $cumul[$_ + 1] = $cumul[$_] + $freq[$_] for 0 .. 255;

    my @next;
    my @cnt = (0) x 256;
    for my $i (0 .. $n - 1) {
        $next[$cumul[$L[$i]] + $cnt[$L[$i]]++] = $i;
    }

    my @dec;
    my $i = $idx;
    for (1 .. $n) {
        $i = $next[$i];
        push @dec, $L[$i];
    }

    return pack('C*', @dec);
}

##############################################
# Burrows-Wheeler transform (symbolic variant)
##############################################

sub bwt_sort_symbolic ($s) {    # O(n * log(n)^2)
    my @cyclic = @$s;
    my $len    = scalar(@cyclic);
    return [0 .. $len - 1] if $len <= 1;

    my @rank = @cyclic;
    my @sa   = (0 .. $len - 1);
    my $k    = 1;

    while (1) {
        my @tmp_rank = @rank;
        @sa = sort { $tmp_rank[$a] <=> $tmp_rank[$b] || $tmp_rank[($a + $k) % $len] <=> $tmp_rank[($b + $k) % $len] } @sa;

        my @new_rank;
        $new_rank[$sa[0]] = 0;
        for my $i (1 .. $#sa) {
            my ($prev, $cur) = ($sa[$i - 1], $sa[$i]);
            my $same = ($tmp_rank[$prev] == $tmp_rank[$cur])
              && ($tmp_rank[($prev + $k) % $len] == $tmp_rank[($cur + $k) % $len]);
            $new_rank[$cur] = $new_rank[$prev] + ($same ? 0 : 1);
        }
        @rank = @new_rank;

        last if $rank[$sa[-1]] == $len - 1;    # all ranks distinct — done
        last if $k >= $len;                    # full cycle covered — remaining ties are truly equal
        $k *= 2;
    }
    return \@sa;
}

sub bwt_encode_symbolic ($symbols) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my $bwt = bwt_sort_symbolic($symbols);
    my @ret = map { $symbols->[$_ - 1] } @$bwt;

    my $idx = 0;
    foreach my $i (@$bwt) {
        $i || last;
        ++$idx;
    }

    return (\@ret, $idx);
}

sub bwt_decode_symbolic ($bwt, $idx) {    # fast inversion

    my @head = sort { $a <=> $b } @$bwt;

    my %indices;
    foreach my $i (0 .. $#head) {
        push @{$indices{$bwt->[$i]}}, $i;
    }

    my @table;
    foreach my $v (@head) {
        push @table, shift(@{$indices{$v}});
    }

    my @dec;
    my $i = $idx;

    for (1 .. scalar(@head)) {
        push @dec, $head[$i];
        $i = $table[$i];
    }

    return \@dec;
}

#####################
# RLE4 used in Bzip2
#####################

sub rle4_encode ($symbols, $max_run = 255) {    # RLE1

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my $end = $#{$symbols};
    return [] if ($end < 0);

    my $prev = $symbols->[0];
    my $run  = 1;
    my @rle  = ($prev);

    for (my $i = 1 ; $i <= $end ; ++$i) {

        if ($symbols->[$i] == $prev) {
            ++$run;
        }
        else {
            $run  = 1;
            $prev = $symbols->[$i];
        }

        push @rle, $prev;

        if ($run >= 4) {

            $run = 0;
            $i += 1;

            while ($run < $max_run and $i <= $end and $symbols->[$i] == $prev) {
                ++$run;
                ++$i;
            }

            push @rle, $run;
            $run = 1;

            if ($i <= $end) {
                $prev = $symbols->[$i];
                push @rle, $symbols->[$i];
            }
        }
    }

    return \@rle;
}

sub rle4_decode ($symbols) {    # RLE1

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my $end = $#{$symbols};
    return [] if ($end < 0);

    my @dec  = $symbols->[0];
    my $prev = $symbols->[0];
    my $run  = 1;

    for (my $i = 1 ; $i <= $end ; ++$i) {

        if ($symbols->[$i] == $prev) {
            ++$run;
        }
        else {
            $run  = 1;
            $prev = $symbols->[$i];
        }

        push @dec, $prev;

        if ($run >= 4) {
            if (++$i <= $end) {
                $run = $symbols->[$i];
                push @dec, (($prev) x $run);
            }

            $run = 0;
        }
    }

    return \@dec;
}

#######################
# Delta encoding (+RLE)
#######################

sub _compute_elias_costs ($run_length) {

    # Check which method results in better compression
    my $with_rle    = 0;
    my $without_rle = 0;

    my $double_with_rle    = 0;
    my $double_without_rle = 0;

    # Check if there are any negative values or zero values
    my $has_negative = 0;
    my $has_zero     = 0;

    foreach my $pair (@$run_length) {
        my ($c, $v) = @$pair;

        if ($c < 0 and not $has_negative) {
            $has_negative = 1;
        }

        if ($c == 0) {
            $with_rle           += 1;
            $double_with_rle    += 1;
            $without_rle        += $v;
            $double_without_rle += $v;
            $has_zero ||= 1;
        }
        else {

            {    # double
                my $t   = int(log(abs($c) + 1) / log(2) + 1);
                my $l   = int(log($t) / log(2) + 1);
                my $len = 2 * ($l - 1) + ($t - 1) + 3;

                $double_with_rle    += $len;
                $double_without_rle += $len * $v;
            }

            {    # single
                my $t   = int(log(abs($c) + 1) / log(2) + 1);
                my $len = 2 * ($t - 1) + 3;
                $with_rle    += $len;
                $without_rle += $len * $v;
            }
        }

        if ($v == 1) {
            $with_rle        += 1;
            $double_with_rle += 1;
        }
        else {
            my $t   = int(log($v) / log(2) + 1);
            my $len = 2 * ($t - 1) + 1;
            $with_rle        += $len;
            $double_with_rle += $len;
        }
    }

    scalar {
            has_negative => $has_negative,
            has_zero     => $has_zero,
            methods      => {
                        with_rle           => $with_rle,
                        without_rle        => $without_rle,
                        double_with_rle    => $double_with_rle,
                        double_without_rle => $double_without_rle,
                       },
           };
}

sub _find_best_encoding_method ($integers) {
    my $rl            = run_length($integers);
    my $costs         = _compute_elias_costs($rl);
    my ($best_method) = sort { $costs->{methods}{$a} <=> $costs->{methods}{$b} } sort keys(%{$costs->{methods}});
    $VERBOSE && say STDERR "$best_method --> $costs->{methods}{$best_method}";
    return ($rl, $best_method, $costs);
}

sub delta_encode ($integers) {

    my $deltas = deltas($integers);

    my @methods = (
                   [_find_best_encoding_method($integers),                                      0, 0],
                   [_find_best_encoding_method($deltas),                                        1, 0],
                   [_find_best_encoding_method(rle4_encode($integers, scalar(@$integers) + 1)), 0, 1],
                   [_find_best_encoding_method(rle4_encode($deltas, scalar(@$integers) + 1)),   1, 1],
                  );

    my ($best) = sort { $a->[2]{methods}{$a->[1]} <=> $b->[2]{methods}{$b->[1]} } @methods;

    my ($rl, $method, $stats, $with_deltas, $with_rle4) = @$best;

    my $double       = 0;
    my $with_rle     = 0;
    my $has_negative = $stats->{has_negative};

    if ($method eq 'with_rle') {
        $with_rle = 1;
    }
    elsif ($method eq 'without_rle') {
        ## ok
    }
    elsif ($method eq 'double_with_rle') {
        $with_rle = 1;
        $double   = 1;
    }
    elsif ($method eq 'double_without_rle') {
        $double = 1;
    }
    else {
        confess "[BUG] Unknown encoding method: $method";
    }

    my $code      = '';
    my $bitstring = join('', $double, $with_rle, $has_negative, $with_deltas, $with_rle4);
    my $length    = sum(map { $_->[1] } @$rl) // 0;

    foreach my $pair ([$length, 1], @$rl) {
        my ($d, $v) = @$pair;

        if ($d == 0) {
            $code = '0';
        }
        elsif ($double) {
            my $t = sprintf('%b', abs($d) + 1);
            my $l = sprintf('%b', length($t));
            $code = ($has_negative ? ('1' . (($d < 0) ? '0' : '1')) : '') . ('1' x (length($l) - 1)) . '0' . substr($l, 1) . substr($t, 1);
        }
        else {
            my $t = sprintf('%b', abs($d) + ($has_negative ? 0 : 1));
            $code = ($has_negative ? ('1' . (($d < 0) ? '0' : '1')) : '') . ('1' x (length($t) - 1)) . '0' . substr($t, 1);
        }

        $bitstring .= $code;

        if (not $with_rle) {
            if ($v > 1) {
                $bitstring .= $code x ($v - 1);
            }
            next;
        }

        if ($v == 1) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', $v);
            $bitstring .= join('', '1' x (length($t) - 1), '0', substr($t, 1));
        }
    }

    pack('B*', $bitstring);
}

sub delta_decode ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my $buffer       = '';
    my $double       = read_bit($fh, \$buffer);
    my $with_rle     = read_bit($fh, \$buffer);
    my $has_negative = read_bit($fh, \$buffer);
    my $with_deltas  = read_bit($fh, \$buffer);
    my $with_rle4    = read_bit($fh, \$buffer);

    my @deltas;
    my $len = 0;

    for (my $k = 0 ; $k <= $len ; ++$k) {

        my $bit = read_bit($fh, \$buffer);

        if ($bit eq '0') {
            push @deltas, 0;
        }
        elsif ($double) {
            my $bit = $has_negative ? read_bit($fh, \$buffer) : 0;

            my $bl = $has_negative ? 0 : 1;
            ++$bl while (read_bit($fh, \$buffer) eq '1');

            my $bl2 = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl));
            my $int = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bl2 - 1)));

            push @deltas, ($has_negative ? ($bit eq '1' ? 1 : -1) : 1) * ($int - 1);
        }
        else {
            my $bit = $has_negative ? read_bit($fh, \$buffer) : 0;
            my $n   = $has_negative ? 0                       : 1;
            ++$n while (read_bit($fh, \$buffer) eq '1');
            my $d = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $n));
            push @deltas, $has_negative ? ($bit eq '1' ? $d : -$d) : ($d - 1);
        }

        if ($with_rle) {

            my $bl = 0;
            while (read_bit($fh, \$buffer) == 1) {
                ++$bl;
            }

            if ($bl > 0) {
                my $run = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl)) - 1;
                $k += $run;
                push @deltas, ($deltas[-1]) x $run;
            }
        }

        if ($k == 0) {
            $len = pop(@deltas);
        }
    }

    my $decoded = \@deltas;
    $decoded = rle4_decode($decoded) if $with_rle4;
    $decoded = accumulate($decoded)  if $with_deltas;
    return $decoded;
}

################################
# Alphabet encoding (from Bzip2)
################################

sub encode_alphabet_256 ($alphabet) {

    my %table;
    @table{@$alphabet} = ();

    my $populated = 0;
    my @marked;

    for (my $i = 0 ; $i <= 255 ; $i += 16) {

        my $enc = 0;
        foreach my $j (0 .. 15) {
            if (exists($table{$i + $j})) {
                $enc |= 1 << $j;
            }
        }

        $populated <<= 1;

        if ($enc > 0) {
            $populated |= 1;
            push @marked, $enc;
        }
    }

    my $bitstring = join('', map { int2bits_lsb($_, 16) } @marked);

    $VERBOSE && say STDERR "Populated : ", sprintf('%016b', $populated);
    $VERBOSE && say STDERR "Marked    : @marked";
    $VERBOSE && say STDERR "Bits len  : ", length($bitstring);

    my $encoded = '';
    $encoded .= int2bytes($populated, 2);
    $encoded .= pack('B*', $bitstring);
    return $encoded;
}

sub decode_alphabet_256 ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my @alphabet;
    my $l1 = bytes2int($fh, 2);

    for my $i (0 .. 15) {
        if ($l1 & (0x8000 >> $i)) {
            my $l2 = bytes2int($fh, 2);
            for my $j (0 .. 15) {
                if ($l2 & (0x8000 >> $j)) {
                    push @alphabet, 16 * $i + $j;
                }
            }
        }
    }

    return \@alphabet;
}

sub encode_alphabet ($alphabet) {

    my $max_symbol = $alphabet->[-1] // -1;

    if ($max_symbol <= 255) {

        my $delta = delta_encode($alphabet);
        my $enc   = encode_alphabet_256($alphabet);

        if (length($delta) < length($enc)) {
            return (chr(0) . $delta);
        }

        return (chr(1) . $enc);
    }

    return (chr(0) . delta_encode($alphabet));
}

sub decode_alphabet ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    if (ord(getc($fh) // confess "error") == 1) {
        return decode_alphabet_256($fh);
    }

    return delta_decode($fh);
}

##########################
# Move to front transform
##########################

sub mtf_encode ($symbols, $alphabet = undef) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    if (defined($alphabet) and ref($alphabet) eq '') {
        $alphabet = string2symbols($alphabet);
    }

    my (@C, @table);

    my @alphabet;
    my @alphabet_copy;
    my $return_alphabet = 0;

    if (defined($alphabet)) {
        @alphabet = @$alphabet;
    }
    else {
        @alphabet        = sort { $a <=> $b } uniq(@$symbols);
        $return_alphabet = 1;
        @alphabet_copy   = @alphabet;
    }

    my $index;
    my @indices = (0 .. $#alphabet);

    foreach my $c (@$symbols) {

        foreach my $i (@indices) {
            if ($alphabet[$i] == $c) {
                $index = $i;
                last;
            }
        }

        push @C, $index;
        unshift(@alphabet, splice(@alphabet, $index, 1));
    }

    $return_alphabet || return \@C;
    return (\@C, \@alphabet_copy);
}

sub mtf_decode ($encoded, $alphabet) {

    if (ref($encoded) eq '') {
        $encoded = string2symbols($encoded);
    }

    if (ref($alphabet) eq '') {
        $alphabet = string2symbols($alphabet);
    }

    my @S;
    my @alpha = @$alphabet;

    foreach my $p (@$encoded) {
        push @S, $alpha[$p];
        unshift(@alpha, splice(@alpha, $p, 1));
    }

    return \@S;
}

###########################
# Zero Run-length encoding
###########################

sub zrle_encode ($symbols) {    # RLE2

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my @rle;
    my $end = $#{$symbols};

    for (my $i = 0 ; $i <= $end ; ++$i) {

        my $run = 0;
        while ($i <= $end and $symbols->[$i] == 0) {
            ++$run;
            ++$i;
        }

        if ($run >= 1) {
            my $t = sprintf('%b', $run + 1);
            push @rle, split(//, substr($t, 1));
        }

        if ($i <= $end) {
            push @rle, $symbols->[$i] + 1;
        }
    }

    return \@rle;
}

sub zrle_decode ($rle) {    # RLE2

    if (ref($rle) eq '') {
        $rle = string2symbols($rle);
    }

    my @dec;
    my $end = $#{$rle};

    for (my $i = 0 ; $i <= $end ; ++$i) {
        my $k = $rle->[$i];

        if ($k == 0 or $k == 1) {
            my $run = 1;
            while (($i <= $end) and ($k == 0 or $k == 1)) {
                ($run <<= 1) |= $k;
                $k = $rle->[++$i];
            }
            push @dec, (0) x ($run - 1);
        }

        if ($i <= $end) {
            push @dec, $k - 1;
        }
    }

    return \@dec;
}

################################################################
# Move-to-front compression (MTF + RLE4 + ZRLE + Huffman coding)
################################################################

sub mrl_compress_symbolic ($symbols, $entropy_sub = \&create_huffman_entry) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my ($mtf, $alphabet) = mtf_encode($symbols);
    my $rle  = zrle_encode($mtf);
    my $rle4 = rle4_encode($rle, scalar(@$rle));

    encode_alphabet($alphabet) . $entropy_sub->($rle4);
}

*mrl_compress = \&mrl_compress_symbolic;

sub mrl_decompress_symbolic ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $entropy_sub);
    }

    my $alphabet = decode_alphabet($fh);

    $VERBOSE && say STDERR "Alphabet size: ", scalar(@$alphabet);

    my $rle4    = $entropy_sub->($fh);
    my $rle     = rle4_decode($rle4);
    my $mtf     = zrle_decode($rle);
    my $symbols = mtf_decode($mtf, $alphabet);

    return $symbols;
}

sub mrl_decompress($fh, $entropy_sub = \&decode_huffman_entry) {
    symbols2string(mrl_decompress_symbolic($fh, $entropy_sub));
}

############################################################
# BWT-based compression (BWT + MTF + ZRLE + Huffman coding)
############################################################

sub bwt_compress ($chunk, $entropy_sub = \&create_huffman_entry) {

    if (ref($chunk) ne '') {
        return bwt_compress_symbolic($chunk, $entropy_sub);
    }

    my $rle1 = rle4_encode(string2symbols($chunk));
    my ($bwt, $idx) = bwt_encode(pack('C*', @$rle1));

    $VERBOSE && say STDERR "BWT index = $idx";

    my ($mtf, $alphabet) = mtf_encode(string2symbols($bwt));
    my $rle = zrle_encode($mtf);

    pack('N', $idx) . encode_alphabet($alphabet) . $entropy_sub->($rle);
}

sub bwt_decompress ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $entropy_sub);
    }

    my $idx      = bytes2int($fh, 4);
    my $alphabet = decode_alphabet($fh);

    $VERBOSE && say STDERR "BWT index = $idx";
    $VERBOSE && say STDERR "Alphabet size: ", scalar(@$alphabet);

    my $rle  = $entropy_sub->($fh);
    my $mtf  = zrle_decode($rle);
    my $bwt  = mtf_decode($mtf, $alphabet);
    my $rle4 = bwt_decode(pack('C*', @$bwt), $idx);
    my $data = rle4_decode(string2symbols($rle4));

    pack('C*', @$data);
}

###########################################
# BWT-based compression (symbolic variant)
###########################################

sub bwt_compress_symbolic ($symbols, $entropy_sub = \&create_huffman_entry) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my $rle4 = rle4_encode($symbols);
    my ($bwt, $idx) = bwt_encode_symbolic($rle4);

    my ($mtf, $alphabet) = mtf_encode($bwt);
    my $rle = zrle_encode($mtf);

    $VERBOSE && say STDERR "BWT index = $idx";
    $VERBOSE && say STDERR "Max symbol: ", max(@$alphabet) // 0;

    pack('N', $idx) . encode_alphabet($alphabet) . $entropy_sub->($rle);
}

sub bwt_decompress_symbolic ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $entropy_sub);
    }

    my $idx      = bytes2int($fh, 4);
    my $alphabet = decode_alphabet($fh);

    $VERBOSE && say STDERR "BWT index = $idx";
    $VERBOSE && say STDERR "Alphabet size: ", scalar(@$alphabet);

    my $rle  = $entropy_sub->($fh);
    my $mtf  = zrle_decode($rle);
    my $bwt  = mtf_decode($mtf, $alphabet);
    my $rle4 = bwt_decode_symbolic($bwt, $idx);
    my $data = rle4_decode($rle4);

    return $data;
}

###########################
# Arithmetic Coding entries
###########################

sub create_ac_entry ($symbols) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my ($enc, $freq) = ac_encode($symbols);
    my $max_symbol = max(keys %$freq) // 0;

    my @freqs;
    foreach my $k (0 .. $max_symbol) {
        push @freqs, $freq->{$k} // 0;
    }

    push @freqs, length($enc) >> 3;

    delta_encode(\@freqs) . pack("B*", $enc);
}

sub decode_ac_entry ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my @freqs    = @{delta_decode($fh)};
    my $bits_len = pop(@freqs);

    my %freq;
    foreach my $i (0 .. $#freqs) {
        if ($freqs[$i]) {
            $freq{$i} = $freqs[$i];
        }
    }

    $VERBOSE && say STDERR "Encoded length: $bits_len";
    my $bits = read_bits($fh, $bits_len << 3);

    if ($bits_len > 0) {
        open my $bits_fh, '<:raw', \$bits;
        return ac_decode($bits_fh, \%freq);
    }

    return [];
}

####################################
# Adaptive Arithmetic Coding entries
####################################

sub create_adaptive_ac_entry ($symbols) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my ($enc, $alphabet) = adaptive_ac_encode($symbols);
    delta_encode([@$alphabet, length($enc) >> 3]) . pack('B*', $enc);
}

sub decode_adaptive_ac_entry ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my $alphabet = delta_decode($fh);
    my $enc_len  = pop(@$alphabet);

    if ($enc_len > 0) {
        my $bits = read_bits($fh, $enc_len << 3);
        open my $bits_fh, '<:raw', \$bits;
        return adaptive_ac_decode($bits_fh, $alphabet);
    }

    return [];
}

###########################
# Huffman Coding algorithm
###########################

sub huffman_encode ($symbols, $dict) {
    join('', @{$dict}{@$symbols});
}

sub _build_trie ($rev_dict) {
    my $root = {};
    for my $code (keys %$rev_dict) {
        my $node = $root;
        for my $bit (split //, $code) {
            $node->{$bit} //= {};
            $node = $node->{$bit};
        }
        $node->{sym} = $rev_dict->{$code};
    }
    return $root;
}

sub huffman_decode ($bits, $rev_dict) {
    my $root = _build_trie($rev_dict);
    my @result;
    my $node = $root;
    foreach my $i (0 .. length($bits) - 1) {
        $node = $node->{substr($bits, $i, 1)};
        if (exists $node->{sym}) {
            push @result, $node->{sym};
            $node = $root;
        }
    }
    return \@result;
}

# produce encode and decode dictionary from a tree
sub _huffman_walk_tree ($node, $code, $h) {

    my $c = $node->[0] // return $h;
    if (ref $c) { __SUB__->($c->[$_], $code . $_, $h) for ('0', '1') }
    else        { $h->{$c} = $code }

    return $h;
}

sub huffman_from_code_lengths ($code_lengths_table) {

    if (ref($code_lengths_table) eq 'ARRAY') {
        my %table = map { (($code_lengths_table->[$_] > 0) ? ($_, $code_lengths_table->[$_]) : ()) } 0 .. $#{$code_lengths_table};
        return __SUB__->(\%table);
    }

    # This algorithm is based on the pseudocode in RFC 1951 (Section 3.2.2)
    # (Steps are numbered as in the RFC)

    my @code_lengths = map { [$_, $code_lengths_table->{$_}] } sort { $a <=> $b } keys %$code_lengths_table;

    # Step 1: Count the number of codes for each length
    my $max_length    = max(map { $_->[1] } @code_lengths) // 0;
    my @length_counts = (0) x ($max_length + 1);

    foreach my $length (map { $_->[1] } @code_lengths) {

        # Treat undef or negative lengths as 0 (unused)
        if (defined($length) and $length > 0) {
            ++$length_counts[$length];
        }
    }

    # Step 2: Generate the starting numerical value for each length
    my $code = 0;
    $length_counts[0] = 0;
    my @next_code = (0) x ($max_length + 1);

    foreach my $bits (1 .. $max_length) {
        $code = ($code + $length_counts[$bits - 1]) << 1;
        $next_code[$bits] = $code;
    }

    # Step 3: Assign numerical values to all codes
    my %dict;
    my %rev_dict;
    foreach my $pair (@code_lengths) {
        my ($key, $length) = @$pair;

        # Skip zero-length codes (unused symbols)
        if (defined($length) and $length != 0) {

            # Format the integer code as a binary string with $length bits
            my $binary_code = sprintf('%0*b', $length, $next_code[$length]);

            $dict{$key}             = $binary_code;
            $rev_dict{$binary_code} = $key;

            # Increment the code for the next symbol of this length
            ++$next_code[$length];
        }
    }

    return (wantarray ? (\%dict, \%rev_dict) : \%dict);
}

sub _heap_push ($heap, $item) {
    push @$heap, $item;
    my $i = $#$heap;
    while ($i > 0) {
        my $p = ($i - 1) >> 1;
        last if ($heap->[$p][1] <= $heap->[$i][1]);
        @{$heap}[$p, $i] = @{$heap}[$i, $p];
        $i = $p;
    }
}

sub _heap_pop ($heap) {
    return pop @$heap if (@$heap == 1);
    my $top = $heap->[0];
    $heap->[0] = pop @$heap;
    my $n = scalar @$heap;
    my $i = 0;
    while (1) {
        my $s = $i;
        my $l = 2 * $i + 1;
        my $r = $l + 1;
        $s = $l if ($l < $n && $heap->[$l][1] < $heap->[$s][1]);
        $s = $r if ($r < $n && $heap->[$r][1] < $heap->[$s][1]);
        last if $s == $i;
        @{$heap}[$i, $s] = @{$heap}[$s, $i];
        $i = $s;
    }
    return $top;
}

sub huffman_from_freq($freq) {

    # Initialize Heap
    # Structure: [ [symbol_or_children], frequency ]
    my @heap;
    foreach my $k (sort { $a <=> $b } keys %$freq) {
        _heap_push(\@heap, [$k, $freq->{$k}]);
    }

    # Build Huffman Tree
    while (@heap > 1) {
        my $x = _heap_pop(\@heap);
        my $y = _heap_pop(\@heap);
        _heap_push(\@heap, [[$x, $y], $x->[1] + $y->[1]]);
    }

    if (@heap == 1 && !ref $heap[0][0]) {
        @heap = ([[$heap[0]], $heap[0][1]]);
    }

    # Generate Codes
    my $h = _huffman_walk_tree($heap[0], '', {});

    my %code_lengths;
    foreach my $i (keys %$freq) {
        $code_lengths{$i} = length($h->{$i});
    }

    huffman_from_code_lengths(\%code_lengths);
}

sub huffman_from_symbols ($symbols) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    huffman_from_freq(frequencies($symbols));
}

########################
# Huffman Coding entries
########################

sub create_huffman_entry ($symbols) {

    if (ref($symbols) eq '') {
        $symbols = string2symbols($symbols);
    }

    my $dict = huffman_from_symbols($symbols);
    my $enc  = huffman_encode($symbols, $dict);

    my $max_symbol = max(keys %$dict) // 0;
    $VERBOSE && say STDERR "Max symbol: $max_symbol\n";

    my @code_lengths;
    foreach my $i (0 .. $max_symbol) {
        if (exists($dict->{$i})) {
            $code_lengths[$i] = length($dict->{$i});
        }
        else {
            $code_lengths[$i] = 0;
        }
    }

    delta_encode(\@code_lengths) . pack("N", length($enc)) . pack("B*", $enc);
}

sub decode_huffman_entry ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my $code_lengths = delta_decode($fh);
    my (undef, $rev_dict) = huffman_from_code_lengths($code_lengths);

    my $enc_len = bytes2int($fh, 4);
    $VERBOSE && say STDERR "Encoded length: $enc_len\n";

    if ($enc_len > 0) {
        return huffman_decode(read_bits($fh, $enc_len), $rev_dict);
    }

    return [];
}

###################################################################################
# DEFLATE-like encoding of literals and backreferences produced by the LZSS methods
###################################################################################

sub make_deflate_tables ($max_dist = $LZ_MAX_DIST, $max_len = $LZ_MAX_LEN) {

    # [distance value, offset bits]
    my @DISTANCE_SYMBOLS = map { [$_, 0] } (0 .. 4);

    until ($DISTANCE_SYMBOLS[-1][0] > $max_dist) {
        push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
        push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
    }

    # [length, offset bits]
    my @LENGTH_SYMBOLS = ((map { [$_, 0] } (1 .. 10)));

    {
        my $delta = 1;
        until ($LENGTH_SYMBOLS[-1][0] > $max_len) {
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1] + 1];
            $delta *= 2;
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
        }
        while (@LENGTH_SYMBOLS and $LENGTH_SYMBOLS[-1][0] >= $max_len) {
            pop @LENGTH_SYMBOLS;
        }
        push @LENGTH_SYMBOLS, [$max_len, 0];
    }

    my @LENGTH_INDICES;

    foreach my $i (0 .. $#LENGTH_SYMBOLS) {
        my ($min, $bits) = @{$LENGTH_SYMBOLS[$i]};
        foreach my $k ($min .. $min + (1 << $bits) - 1) {
            $LENGTH_INDICES[$k] = $i;
        }
    }

    return (\@DISTANCE_SYMBOLS, \@LENGTH_SYMBOLS, \@LENGTH_INDICES);
}

sub find_deflate_index ($value, $table) {
    foreach my $i (0 .. $#{$table}) {
        if ($table->[$i][0] > $value) {
            return $i - 1;
        }
    }
    confess "error";
}

sub deflate_encode ($literals, $distances, $lengths, $entropy_sub = \&create_huffman_entry) {

    my $max_dist   = max(@$distances) // 0;
    my $max_len    = max(@$lengths)   // 0;
    my $max_symbol = (max(grep { defined($_) } @$literals) // -1) + 1;

    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables($max_dist, $max_len);

    my @len_symbols;
    my @dist_symbols;
    my $offset_bits = '';

    foreach my $k (0 .. $#$literals) {

        if ($lengths->[$k] == 0) {
            push @len_symbols, $literals->[$k];
            next;
        }

        my $len  = $lengths->[$k];
        my $dist = $distances->[$k];

        {
            my $len_idx = $LENGTH_INDICES->[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};

            push @len_symbols, $len_idx + $max_symbol;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $len - $min);
            }
        }

        {
            my $dist_idx = find_deflate_index($dist, $DISTANCE_SYMBOLS);
            my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};

            push @dist_symbols, $dist_idx;

            if ($bits > 0) {
                $offset_bits .= sprintf('%0*b', $bits, $dist - $min);
            }
        }
    }

    fibonacci_encode([$max_symbol, $max_dist, $max_len]) . $entropy_sub->(\@len_symbols) . $entropy_sub->(\@dist_symbols) . pack('B*', $offset_bits);
}

sub deflate_decode ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $entropy_sub);
    }

    my ($max_symbol, $max_dist, $max_len) = @{fibonacci_decode($fh)};
    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS) = make_deflate_tables($max_dist, $max_len);

    my $len_symbols  = $entropy_sub->($fh);
    my $dist_symbols = $entropy_sub->($fh);

    my $bits_len = 0;

    foreach my $i (@$dist_symbols) {
        $bits_len += $DISTANCE_SYMBOLS->[$i][1];
    }

    foreach my $i (@$len_symbols) {
        if ($i >= $max_symbol) {
            $bits_len += $LENGTH_SYMBOLS->[$i - $max_symbol][1];
        }
    }

    my $bits = read_bits($fh, $bits_len);

    my @literals;
    my @lengths;
    my @distances;

    my $j = 0;

    foreach my $i (@$len_symbols) {
        if ($i >= $max_symbol) {
            my $dist = $dist_symbols->[$j++];
            push @literals,  undef;
            push @lengths,   $LENGTH_SYMBOLS->[$i - $max_symbol][0] + oct('0b' . substr($bits, 0, $LENGTH_SYMBOLS->[$i - $max_symbol][1], ''));
            push @distances, $DISTANCE_SYMBOLS->[$dist][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS->[$dist][1], ''));
        }
        else {
            push @literals,  $i;
            push @lengths,   0;
            push @distances, 0;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

#####################
# Elias gamma coding
#####################

sub elias_gamma_encode ($integers) {

    my $bitstring = '';
    foreach my $k (scalar(@$integers), @$integers) {
        my $t = sprintf('%b', $k + 1);
        $bitstring .= ('1' x (length($t) - 1)) . '0' . substr($t, 1);
    }

    pack('B*', $bitstring);
}

sub elias_gamma_decode ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my @ints;
    my $len    = 0;
    my $buffer = '';

    for (my $k = 0 ; $k <= $len ; ++$k) {

        my $n = 0;
        ++$n while (read_bit($fh, \$buffer) eq '1');

        push @ints, oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $n)) - 1;

        if ($k == 0) {
            $len = pop(@ints);
        }
    }

    return \@ints;
}

#####################
# Elias omega coding
#####################

sub elias_omega_encode ($integers) {

    my $bitstring = '';
    foreach my $k (scalar(@$integers), @$integers) {
        if ($k == 0) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', $k + 1);
            my $l = length($t);
            my $L = sprintf('%b', $l);
            $bitstring .= ('1' x (length($L) - 1)) . '0' . substr($L, 1) . substr($t, 1);
        }
    }

    pack('B*', $bitstring);
}

sub elias_omega_decode ($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my @ints;
    my $len    = 0;
    my $buffer = '';

    for (my $k = 0 ; $k <= $len ; ++$k) {

        my $bl = 0;
        ++$bl while (read_bit($fh, \$buffer) eq '1');

        if ($bl > 0) {

            my $bl2 = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl));
            my $int = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bl2 - 1))) - 1;

            push @ints, $int;
        }
        else {
            push @ints, 0;
        }

        if ($k == 0) {
            $len = pop(@ints);
        }
    }

    return \@ints;
}

###################
# LZSS SYMBOLIC
###################

sub lzss_encode_symbolic($symbols, %params) {

    if (ref($symbols) eq '') {
        return lzss_encode($symbols, %params);
    }

    my $min_len         = $params{min_len}         // $LZ_MIN_LEN;
    my $max_len         = $params{max_len}         // $LZ_MAX_LEN;
    my $max_dist        = $params{max_dist}        // $LZ_MAX_DIST;
    my $max_chain_len   = $params{max_chain_len}   // $LZ_MAX_CHAIN_LEN;
    my $max_chain_width = $params{max_chain_width} // $LZ_MAX_CHAIN_WIDTH;

    $min_len = 1 if $min_len < 1;

    my $end = $#$symbols;
    my (@literals, @distances, @lengths, %table);

    for (my $la = 0 ; $la <= $end ;) {
        my $best_n = 1;
        my $best_p = $la;

        my $upto      = $la + $min_len - 1;
        my $lookahead = join(' ', @{$symbols}[$la .. ($upto > $end ? $end : $upto)]);

        if (exists $table{$lookahead}) {

            foreach my $p (@{$table{$lookahead}}) {

                last if ($la - $p > $max_dist);

                my $n = $min_len;

                ++$n while ($la + $n <= $end and $symbols->[$la + $n - 1] == $symbols->[$p + $n - 1] and $n <= $max_len);

                if ($n > $best_n) {
                    $best_n = $n;
                    $best_p = $p;
                    last if ($n > $max_len);
                }
            }
        }

        if ($best_n == 1) {
            $table{$lookahead} = [$la];
        }
        else {
            my @matched = @{$symbols}[$la .. $la + $best_n - 1];
            my @key_arr = @matched[0 .. $min_len - 1];

            my $insert_limit = $best_n - $min_len;
            $insert_limit = $best_n - 2      if $insert_limit > $best_n - 2;
            $insert_limit = $max_chain_width if $insert_limit > $max_chain_width;

            my %seen;
            foreach my $i (0 .. $insert_limit) {

                my $key = join(' ', @key_arr);

                if (!$seen{$key}++) {    # prefer earlier matches
                    unshift @{$table{$key}}, $la + $i;
                    pop @{$table{$key}} if (@{$table{$key}} > $max_chain_len);
                }

                shift(@key_arr);
                push @key_arr, $matched[$i + $min_len];
            }
        }

        if ($best_n > $min_len) {

            push @lengths,   $best_n - 1;
            push @distances, $la - $best_p;
            push @literals,  undef;

            $la += $best_n - 1;
        }
        elsif ($best_n == 1) {
            push @lengths,   0;
            push @distances, 0;
            push @literals,  $symbols->[$la++];
        }
        else {

            push @lengths,   (0) x $best_n;
            push @distances, (0) x $best_n;
            push @literals, @{$symbols}[$la .. $la + $best_n - 1];

            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lzss_decode_symbolic ($literals, $distances, $lengths) {

    my @data;
    my $data_len = 0;

    foreach my $i (0 .. $#$lengths) {

        if ($lengths->[$i] == 0) {
            push @data, $literals->[$i];
            $data_len += 1;
            next;
        }

        my $length = $lengths->[$i]   // confess "bad input";
        my $dist   = $distances->[$i] // confess "bad input";

        if ($dist >= $length) {    # non-overlapping matches
            push @data, @data[$data_len - $dist .. $data_len - $dist + $length - 1];
        }
        elsif ($dist == 1) {       # run-length of last character
            push @data, ($data[-1]) x $length;
        }
        else {                     # overlapping matches
            foreach my $j (1 .. $length) {
                push @data, $data[$data_len + $j - $dist - 1];
            }
        }

        $data_len += $length;
    }

    return \@data;
}

###################
# LZSS Encoding
###################

sub lzss_encode ($str, %params) {

    if (ref($str) ne '') {
        return lzss_encode_symbolic($str, %params);
    }

    my $min_len         = $params{min_len}         // $LZ_MIN_LEN;
    my $max_len         = $params{max_len}         // $LZ_MAX_LEN;
    my $max_dist        = $params{max_dist}        // $LZ_MAX_DIST;
    my $max_chain_len   = $params{max_chain_len}   // $LZ_MAX_CHAIN_LEN;
    my $max_chain_width = $params{max_chain_width} // $LZ_MAX_CHAIN_WIDTH;

    $min_len = 1 if $min_len < 1;

    my @symbols = unpack('C*', $str);
    my $end     = $#symbols;

    my (@literals, @distances, @lengths, %table);

    for (my $la = 0 ; $la <= $end ;) {

        my $best_n = 1;
        my $best_p = $la;

        my $lookahead = substr($str, $la, $min_len);

        if (exists $table{$lookahead}) {
            foreach my $p (@{$table{$lookahead}}) {

                last if ($la - $p > $max_dist);

                my $n = $min_len;

                ++$n while ($la + $n <= $end and $symbols[$la + $n - 1] == $symbols[$p + $n - 1] and $n <= $max_len);

                if ($n > $best_n) {
                    $best_p = $p;
                    $best_n = $n;
                    last if ($best_n > $max_len);
                }
            }
        }

        if ($best_n == 1) {
            $table{$lookahead} = [$la];
        }
        else {

            my $matched      = substr($str, $la, $best_n);
            my $insert_limit = min($best_n - $min_len, $best_n - 2);
            $insert_limit = $max_chain_width if $insert_limit > $max_chain_width;

            my %seen;
            foreach my $i (0 .. $insert_limit) {
                my $key = substr($matched, $i, $min_len);
                next if $seen{$key}++;    # prefer earlier matches
                unshift @{$table{$key}}, $la + $i;
                pop(@{$table{$key}}) if (@{$table{$key}} > $max_chain_len);
            }
        }

        if ($best_n > $min_len) {

            push @lengths,   $best_n - 1;
            push @distances, $la - $best_p;
            push @literals,  undef;

            $la += $best_n - 1;
        }
        elsif ($best_n == 1) {
            push @lengths,   0;
            push @distances, 0;
            push @literals,  $symbols[$la++];
        }
        else {

            push @lengths,   (0) x $best_n;
            push @distances, (0) x $best_n;
            push @literals, @symbols[$la .. $la + $best_n - 1];

            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lzss_decode ($literals, $distances, $lengths) {

    my $data     = '';
    my $data_len = 0;

    foreach my $i (0 .. $#$lengths) {

        if ($lengths->[$i] == 0) {
            $data .= chr($literals->[$i]);
            ++$data_len;
            next;
        }

        my $length = $lengths->[$i]   // confess "bad input";
        my $dist   = $distances->[$i] // confess "bad input";

        if ($dist >= $length) {    # non-overlapping matches
            $data .= substr($data, $data_len - $dist, $length) // confess "bad input";
        }
        elsif ($dist == 1) {       # run-length of last character
            $data .= substr($data, -1) x $length;
        }
        else {                     # overlapping matches
            my $pattern   = substr($data, $data_len - $dist, $dist) // confess "bad input";
            my $full_reps = int(($length + $dist - 1) / $dist) + 1;
            $data .= substr($pattern x $full_reps, 0, $length) // confess "bad input";
        }

        $data_len += $length;
    }

    return $data;
}

###################
# LZSSF Compression
###################

sub lzss_encode_fast_symbolic ($symbols, %params) {

    if (ref($symbols) eq '') {
        return lzss_encode_fast($symbols, %params);
    }

    my $la  = 0;
    my $end = $#$symbols;

    my $min_len  = $params{min_len}  // $LZ_MIN_LEN;     # minimum match length
    my $max_len  = $params{max_len}  // $LZ_MAX_LEN;     # maximum match length
    my $max_dist = $params{max_dist} // $LZ_MAX_DIST;    # maximum offset distance

    $min_len = 1 if $min_len < 1;

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $upto      = $la + $min_len - 1;
        my $lookahead = join(' ', @{$symbols}[$la .. ($upto > $end ? $end : $upto)]);

        if (exists($table{$lookahead}) and $la - $table{$lookahead} <= $max_dist) {

            my $p = $table{$lookahead};
            my $n = $min_len;

            ++$n while ($la + $n <= $end and $symbols->[$la + $n - 1] == $symbols->[$p + $n - 1] and $n <= $max_len);

            $best_p = $p;
            $best_n = $n;
        }

        $table{$lookahead} = $la;

        if ($best_n > $min_len) {

            push @lengths,   $best_n - 1;
            push @distances, $la - $best_p;
            push @literals,  undef;

            $la += $best_n - 1;
        }
        elsif ($best_n == 1) {
            push @lengths,   0;
            push @distances, 0;
            push @literals,  $symbols->[$la++];
        }
        else {

            push @lengths,   (0) x $best_n;
            push @distances, (0) x $best_n;
            push @literals, @{$symbols}[$la .. $la + $best_n - 1];

            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lzss_encode_fast($str, %params) {

    if (ref($str) ne '') {
        return lzss_encode_fast_symbolic($str, %params);
    }

    my @symbols = unpack('C*', $str);

    my $la  = 0;
    my $end = $#symbols;

    my $min_len  = $params{min_len}  // $LZ_MIN_LEN;     # minimum match length
    my $max_len  = $params{max_len}  // $LZ_MAX_LEN;     # maximum match length
    my $max_dist = $params{max_dist} // $LZ_MAX_DIST;    # maximum offset distance

    $min_len = 1 if $min_len < 1;

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $lookahead = substr($str, $la, $min_len);

        if (exists($table{$lookahead}) and $la - $table{$lookahead} <= $max_dist) {

            my $p = $table{$lookahead};
            my $n = $min_len;

            ++$n while ($la + $n <= $end and $symbols[$la + $n - 1] == $symbols[$p + $n - 1] and $n <= $max_len);

            $best_p = $p;
            $best_n = $n;
        }

        $table{$lookahead} = $la;

        if ($best_n > $min_len) {

            push @lengths,   $best_n - 1;
            push @distances, $la - $best_p;
            push @literals,  undef;

            $la += $best_n - 1;
        }
        elsif ($best_n == 1) {
            push @lengths,   0;
            push @distances, 0;
            push @literals,  $symbols[$la++];
        }
        else {

            push @lengths,   (0) x $best_n;
            push @distances, (0) x $best_n;
            push @literals, @symbols[$la .. $la + $best_n - 1];

            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

##################################################################
# LZSS encoding via O(1) flat-array hashing, LZ4-style.
##################################################################

sub lzss_encode_hash4 ($str, %params) {

    state $LZ4_HASH_BITS = 16;            # hash table has 2**this slots
    state $LZ4_HASH_MUL  = 0x9E3779B1;    # Fibonacci hashing multiplier, scrambles the 4-byte window's bits

    if (ref($str) ne '') {
        confess "lzss_encode_hash4: symbolic-array input isn't supported (fixed 4-byte hashing needs a byte string)";
    }

    my $min_len  = 4;
    my $max_len  = $params{max_len}  // $LZ_MAX_LEN;
    my $max_dist = $params{max_dist} // $LZ_MAX_DIST;

    my @symbols = unpack('C*', $str);

    my $end = $#symbols;
    my (@literals, @distances, @lengths);

    if ($end + 1 < $min_len) {    # fewer than 4 bytes total: nothing to hash, every byte is a literal
        for my $la (0 .. $end) {
            push @lengths,   0;
            push @distances, 0;
            push @literals,  $symbols[$la];
        }
        return (\@literals, \@distances, \@lengths);
    }

    my $hash_size = 1 << $LZ4_HASH_BITS;
    my @hash_table;

    my $shift = 32 - $LZ4_HASH_BITS;
    my $la    = 0;

    while ($la + $min_len - 1 <= $end) {

        my $seq = substr($str, $la, 4);
        my $val = unpack('N', $seq);
        my $h   = (($val * $LZ4_HASH_MUL) & 0xFFFFFFFF) >> $shift;

        my $p = $hash_table[$h];
        $hash_table[$h] = $la;

        if (defined($p) and $la - $p <= $max_dist and substr($str, $p, $min_len) eq $seq) {

            my $n = $min_len;

            ++$n while ($la + $n <= $end and $symbols[$la + $n - 1] == $symbols[$p + $n - 1] and $n <= $max_len);

            push @lengths,   $n - 1;
            push @distances, $la - $p;
            push @literals,  undef;

            $la += $n - 1;    # the "jump": intermediate match bytes are never indexed
            next;
        }

        push @lengths,   0;
        push @distances, 0;
        push @literals,  $symbols[$la];
        $la++;
    }

    while ($la <= $end) {    # trailing <4 bytes: no room left to hash, always literals
        push @lengths,   0;
        push @distances, 0;
        push @literals,  $symbols[$la];
        $la++;
    }

    return (\@literals, \@distances, \@lengths);
}

################################
# LZ77 encoding, inspired by LZ4
################################

sub lz77_encode($chunk, $lzss_encoding_sub = \&lzss_encode) {

    local $LZ_MAX_LEN = ~0;    # maximum match length

    my ($literals, $distances, $lengths) = $lzss_encoding_sub->($chunk);

    my $literals_end = $#{$literals};
    my (@symbols, @len_symbols, @match_symbols, @dist_symbols);

    for (my $i = 0 ; $i <= $literals_end ; ++$i) {

        my $j = $i;
        while ($i <= $literals_end and defined($literals->[$i])) {
            ++$i;
        }

        my $literals_length = $i - $j;
        my $match_len       = $lengths->[$i] // 0;

        push @match_symbols, (($literals_length >= 7 ? 7 : $literals_length) << 5) | ($match_len >= 31 ? 31 : $match_len);

        $literals_length -= 7;
        $match_len       -= 31;

        while ($literals_length >= 0) {
            push @len_symbols, ($literals_length >= 255 ? 255 : $literals_length);
            $literals_length -= 255;
        }

        if ($i > $j) {
            push @symbols, @{$literals}[$j .. $i - 1];
        }

        while ($match_len >= 0) {
            push @match_symbols, ($match_len >= 255 ? 255 : $match_len);
            $match_len -= 255;
        }

        push @dist_symbols, $distances->[$i] // 0;
    }

    return (\@symbols, \@dist_symbols, \@len_symbols, \@match_symbols);
}

*lz77_encode_symbolic = \&lz77_encode;

sub lz77_decode($symbols, $dist_symbols, $len_symbols, $match_symbols) {

    my $data     = '';
    my $data_len = 0;

    my @symbols       = @$symbols;
    my @len_symbols   = @$len_symbols;
    my @match_symbols = @$match_symbols;
    my @dist_symbols  = @$dist_symbols;

    while (@symbols) {

        my $len_byte = shift(@match_symbols) // confess "bad input";

        my $literals_length = $len_byte >> 5;
        my $match_len       = $len_byte & 0b11111;

        if ($literals_length == 7) {
            while (1) {
                my $byte_len = shift(@len_symbols) // confess "bad input";
                $literals_length += $byte_len;
                last if $byte_len != 255;
            }
        }

        if ($literals_length > 0) {
            $data .= pack("C*", splice(@symbols, 0, $literals_length));
            $data_len += $literals_length;
        }

        if ($match_len == 31) {
            while (1) {
                my $byte_len = shift(@match_symbols) // confess "bad input";
                $match_len += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $dist = shift(@dist_symbols) // confess "bad input";

        if ($dist >= $match_len) {    # non-overlapping matches
            $data .= substr($data, $data_len - $dist, $match_len) // confess "bad input";
        }
        elsif ($dist == 1) {          # run-length of last character
            $data .= substr($data, -1) x $match_len;
        }
        else {                        # overlapping matches
            foreach my $i (1 .. $match_len) {
                $data .= substr($data, $data_len + $i - $dist - 1, 1) // confess "bad input";
            }
        }

        $data_len += $match_len;
    }

    return $data;
}

sub lz77_decode_symbolic($symbols, $dist_symbols, $len_symbols, $match_symbols) {

    my @data;
    my $data_len = 0;

    my @symbols       = @$symbols;
    my @len_symbols   = @$len_symbols;
    my @match_symbols = @$match_symbols;
    my @dist_symbols  = @$dist_symbols;

    while (@symbols) {

        my $len_byte = shift(@match_symbols) // confess "bad input";

        my $literals_length = $len_byte >> 5;
        my $match_len       = $len_byte & 0b11111;

        if ($literals_length == 7) {
            while (1) {
                my $byte_len = shift(@len_symbols) // confess "bad input";
                $literals_length += $byte_len;
                last if $byte_len != 255;
            }
        }

        if ($literals_length > 0) {
            push @data, splice(@symbols, 0, $literals_length);
            $data_len += $literals_length;
        }

        if ($match_len == 31) {
            while (1) {
                my $byte_len = shift(@match_symbols) // confess "bad input";
                $match_len += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $dist = shift(@dist_symbols) // confess "bad input";

        if ($dist >= $match_len) {    # non-overlapping matches
            push @data, @data[scalar(@data) - $dist .. scalar(@data) - $dist + $match_len - 1];
        }
        elsif ($dist == 1) {          # run-length of last character
            push @data, ($data[-1]) x $match_len;
        }
        else {                        # overlapping matches
            foreach my $j (1 .. $match_len) {
                push @data, $data[$data_len + $j - $dist - 1];
            }
        }

        $data_len += $match_len;
    }

    return \@data;
}

sub lz77_compress($chunk, $entropy_sub = \&create_huffman_entry, $lzss_encoding_sub = \&lzss_encode) {
    my ($symbols, $dist_symbols, $len_symbols, $match_symbols) = lz77_encode($chunk, $lzss_encoding_sub);
    $entropy_sub->($symbols) . $entropy_sub->($len_symbols) . $entropy_sub->($match_symbols) . obh_encode($dist_symbols, $entropy_sub);
}

*lz77_compress_symbolic = \&lz77_compress;

sub lz77_decompress($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $entropy_sub);
    }

    my $symbols       = $entropy_sub->($fh);
    my $len_symbols   = $entropy_sub->($fh);
    my $match_symbols = $entropy_sub->($fh);
    my $dist_symbols  = obh_decode($fh, $entropy_sub);

    lz77_decode($symbols, $dist_symbols, $len_symbols, $match_symbols);
}

sub lz77_decompress_symbolic($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $entropy_sub);
    }

    my $symbols       = $entropy_sub->($fh);
    my $len_symbols   = $entropy_sub->($fh);
    my $match_symbols = $entropy_sub->($fh);
    my $dist_symbols  = obh_decode($fh, $entropy_sub);

    lz77_decode_symbolic($symbols, $dist_symbols, $len_symbols, $match_symbols);
}

#########################
# LZSS + DEFLATE encoding
#########################

sub lzss_compress($chunk, $entropy_sub = \&create_huffman_entry, $lzss_encoding_sub = \&lzss_encode) {
    my ($literals, $distances, $lengths) = $lzss_encoding_sub->($chunk);
    deflate_encode($literals, $distances, $lengths, $entropy_sub);
}

*lzss_compress_symbolic = \&lzss_compress;

sub lzss_decompress($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $entropy_sub);
    }

    my ($literals, $distances, $lengths) = deflate_decode($fh, $entropy_sub);
    lzss_decode($literals, $distances, $lengths);
}

sub lzss_decompress_symbolic($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $entropy_sub);
    }

    my ($literals, $distances, $lengths) = deflate_decode($fh, $entropy_sub);
    lzss_decode_symbolic($literals, $distances, $lengths);
}

#########################################
# LZB -- LZSS with byte-oriented encoding
#########################################

sub lzb_compress ($chunk, $lzss_encoding_sub = \&lzss_encode) {

    my ($literals, $distances, $lengths) = do {
        local $LZ_MAX_DIST = (1 << 16) - 1;
        local $LZ_MAX_LEN  = ~0;
        $lzss_encoding_sub->($chunk);
    };

    my $literals_end = $#{$literals};
    my $data         = '';

    for (my $i = 0 ; $i <= $literals_end ; ++$i) {

        my $j = $i;
        while ($i <= $literals_end and defined($literals->[$i])) {
            ++$i;
        }

        my $literals_length = $i - $j;
        my $match_len       = $lengths->[$i] // 0;

        $data .= chr((($literals_length >= 7 ? 7 : $literals_length) << 5) | ($match_len >= 31 ? 31 : $match_len));

        $literals_length -= 7;
        $match_len       -= 31;

        while ($literals_length >= 0) {
            $data .= $literals_length >= 255 ? "\xff" : chr($literals_length);
            $literals_length -= 255;
        }

        if ($i > $j) {
            $data .= pack('C*', @{$literals}[$j .. $i - 1]);
        }

        while ($match_len >= 0) {
            $data .= $match_len >= 255 ? "\xff" : chr($match_len);
            $match_len -= 255;
        }

        $data .= pack('B*', sprintf('%016b', $distances->[$i] // 0));
    }

    return fibonacci_encode([length $data]) . $data;
}

sub lzb_decompress($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my $data               = '';
    my $search_window      = '';
    my $search_window_size = 1 << 16;

    my $block_size = fibonacci_decode($fh)->[0] // confess "decompression error";

    read($fh, (my $block), $block_size) // confess "Read error: $!";

    while ($block ne '') {

        my $len_byte = ord substr($block, 0, 1, '');

        my $literals_length = $len_byte >> 5;
        my $match_len       = $len_byte & 0b11111;

        if ($literals_length == 7) {
            while (1) {
                my $byte_len = ord substr($block, 0, 1, '');
                $literals_length += $byte_len;
                last if $byte_len != 255;
            }
        }

        if ($literals_length > 0) {
            $search_window .= substr($block, 0, $literals_length, '');
        }

        if ($match_len == 31) {
            while (1) {
                my $byte_len = ord substr($block, 0, 1, '');
                $match_len += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $offset = oct('0b' . unpack('B*', substr($block, 0, 2, '')));

        if ($offset >= $match_len) {    # non-overlapping matches
            $search_window .= substr($search_window, length($search_window) - $offset, $match_len);
        }
        elsif ($offset == 1) {          # run-length of last character
            $search_window .= substr($search_window, -1) x $match_len;
        }
        else {                          # overlapping matches
            foreach my $i (1 .. $match_len) {
                $search_window .= substr($search_window, length($search_window) - $offset, 1);
            }
        }

        $data .= substr($search_window, -($match_len + $literals_length));
        $search_window = substr($search_window, -$search_window_size) if (length($search_window) > 2 * $search_window_size);
    }

    return $data;
}

################################################################
# Encode a list of symbols, using offset bits and huffman coding
################################################################

sub obh_encode ($distances, $entropy_sub = \&create_huffman_entry) {

    my $max_dist = max(@$distances) // 0;
    my ($DISTANCE_SYMBOLS) = make_deflate_tables($max_dist, 0);

    my @symbols;
    my $offset_bits = '';

    foreach my $dist (@$distances) {

        my $i = find_deflate_index($dist, $DISTANCE_SYMBOLS);
        my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$i]};

        push @symbols, $i;

        if ($bits > 0) {
            $offset_bits .= sprintf('%0*b', $bits, $dist - $min);
        }
    }

    fibonacci_encode([$max_dist]) . $entropy_sub->(\@symbols) . pack('B*', $offset_bits);
}

sub obh_decode ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $entropy_sub);
    }

    my $max_dist = fibonacci_decode($fh)->[0];
    my ($DISTANCE_SYMBOLS) = make_deflate_tables($max_dist, 0);

    my $symbols  = $entropy_sub->($fh);
    my $bits_len = 0;

    foreach my $i (@$symbols) {
        $bits_len += $DISTANCE_SYMBOLS->[$i][1];
    }

    my $bits = read_bits($fh, $bits_len);

    my @distances;
    foreach my $i (@$symbols) {
        push @distances, $DISTANCE_SYMBOLS->[$i][0] + oct('0b' . substr($bits, 0, $DISTANCE_SYMBOLS->[$i][1], ''));
    }

    return \@distances;
}

#################
# LZW Compression
#################

sub lzw_encode ($uncompressed) {

    # Build the dictionary
    my $dict_size = 256;
    my %dictionary;

    foreach my $i (0 .. $dict_size - 1) {
        $dictionary{chr($i)} = $i;
    }

    my $w = '';
    my @result;

    foreach my $c (split(//, $uncompressed)) {
        my $wc = $w . $c;
        if (exists $dictionary{$wc}) {
            $w = $wc;
        }
        else {
            push @result, $dictionary{$w};

            # Add wc to the dictionary
            $dictionary{$wc} = $dict_size++;
            $w = $c;
        }
    }

    # Output the code for w
    if ($w ne '') {
        push @result, $dictionary{$w};
    }

    return \@result;
}

sub lzw_decode ($compressed) {

    @$compressed || return '';

    # Build the dictionary
    my $dict_size  = 256;
    my @dictionary = map { chr($_) } 0 .. $dict_size - 1;

    my $w      = $dictionary[$compressed->[0]];
    my $result = $w;

    foreach my $j (1 .. $#$compressed) {
        my $k = $compressed->[$j];

        my $entry =
            ($k < $dict_size)  ? $dictionary[$k]
          : ($k == $dict_size) ? ($w . substr($w, 0, 1))
          :                      confess "Bad compressed k: $k";

        $result .= $entry;

        # Add w+entry[0] to the dictionary
        push @dictionary, $w . substr($entry, 0, 1);
        ++$dict_size;
        $w = $entry;
    }

    return $result;
}

sub lzw_compress ($chunk, $enc_method = \&abc_encode) {
    $enc_method->(lzw_encode($chunk));
}

sub lzw_decompress ($fh, $dec_method = \&abc_decode) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $dec_method);
    }

    lzw_decode($dec_method->($fh));
}

###################################
# CRC-32 Pure Perl implementation
###################################

sub _create_crc32_table {
    my @table;
    for my $i (0 .. 255) {
        my $k = $i;
        for (0 .. 7) {
            if ($k & 1) {
                $k >>= 1;
                $k ^= 0xedb88320;
            }
            else {
                $k >>= 1;
            }
        }
        push(@table, $k & 0xffffffff);
    }
    return \@table;
}

sub crc32($str, $crc = 0) {
    state $crc_table = _create_crc32_table();
    $crc &= 0xffffffff;
    $crc ^= 0xffffffff;
    foreach my $c (unpack("C*", $str)) {
        $crc = (($crc >> 8) ^ $crc_table->[($crc & 0xff) ^ $c]);
    }
    return (($crc & 0xffffffff) ^ 0xffffffff);
}

sub adler32($str, $adler = 1) {

    # Reference:
    #   https://datatracker.ietf.org/doc/html/rfc1950#section-9

    my $s1 = $adler & 0xffff;
    my $s2 = ($adler >> 16) & 0xffff;

    foreach my $c (unpack('C*', $str)) {
        $s1 = ($s1 + $c) % 65521;
        $s2 = ($s2 + $s1) % 65521;
    }
    return (($s2 << 16) + $s1);
}

#############################
# Bzip2 compression
#############################

sub _bzip2_encode_code_lengths($dict) {
    my @lengths;

    foreach my $symbol (0 .. max(keys %$dict) // 0) {
        if (exists($dict->{$symbol})) {
            push @lengths, length($dict->{$symbol});
        }
        else {
            confess "Incomplete Huffman tree not supported";
            push @lengths, 0;
        }
    }

    my $deltas = deltas(\@lengths);

    $VERBOSE && say STDERR "Code lengths: (@lengths)";
    $VERBOSE && say STDERR "Code lengths deltas: (@$deltas)";

    my $bitstring = int2bits(shift(@$deltas), 5) . '0';

    foreach my $d (@$deltas) {
        $bitstring .= (($d > 0) ? ('10' x $d) : ('11' x abs($d))) . '0';
    }

    $VERBOSE && say STDERR "Deltas bitstring: $bitstring";

    return $bitstring;
}

sub bzip2_compress($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my $level = 9;

    # There is a CRC32 issue on some non-compressible inputs, when using very large chunk sizes
    ## my $CHUNK_SIZE = 100_000 * $level;
    my $CHUNK_SIZE = 1 << 17;

    my $compressed = "BZh" . $level;

    state $block_header_bitstring = unpack("B48", "1AY&SY");
    state $block_footer_bitstring = unpack("B48", "\27rE8P\x90");

    my $bitstring    = '';
    my $stream_crc32 = 0;

    while (read($fh, (my $chunk), $CHUNK_SIZE)) {

        $bitstring .= $block_header_bitstring;

        my $crc32 = crc32(pack('b*', unpack('B*', $chunk)));
        $VERBOSE && say STDERR "CRC32: $crc32";

        $crc32 = oct('0b' . int2bits_lsb($crc32, 32));
        $VERBOSE && say STDERR "Bzip2-CRC32: $crc32";

        $stream_crc32 = ($crc32 ^ (0xffffffff & ((0xffffffff & ($stream_crc32 << 1)) | (($stream_crc32 >> 31) & 0x1)))) & 0xffffffff;

        $bitstring .= int2bits($crc32, 32);
        $bitstring .= '0';                    # not randomized

        my $rle4 = rle4_encode($chunk);
        my ($bwt, $bwt_idx) = bwt_encode(symbols2string($rle4));

        $bitstring .= int2bits($bwt_idx, 24);

        my ($mtf, $alphabet) = mtf_encode($bwt);
        $VERBOSE && say STDERR "Alphabet: (@$alphabet)";

        $bitstring .= unpack('B*', encode_alphabet_256($alphabet));

        my @zrle = reverse @{zrle_encode([reverse @$mtf])};

        my $eob = scalar(@$alphabet) + 1;    # end-of-block symbol
        $VERBOSE && say STDERR "EOB symbol: $eob";
        push @zrle, $eob;

        my ($dict) = huffman_from_symbols([@zrle, 0 .. $eob - 1]);
        my $num_sels = int(sprintf('%.0f', 0.5 + (scalar(@zrle) / 50)));    # ceil(|zrle| / 50)
        $VERBOSE && say STDERR "Number of selectors: $num_sels";

        $bitstring .= int2bits(2,         3);
        $bitstring .= int2bits($num_sels, 15);
        $bitstring .= '0' x $num_sels;

        $bitstring .= _bzip2_encode_code_lengths($dict) x 2;
        $bitstring .= join('', @{$dict}{@zrle});

        $compressed .= pack('B*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));
    }

    $bitstring  .= $block_footer_bitstring;
    $bitstring  .= int2bits($stream_crc32, 32);
    $compressed .= pack('B*', $bitstring);

    return $compressed;
}

#################################
# Bzip2 decompression
#################################

sub bzip2_decompress($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    state $MaxHuffmanBits = 20;
    my $decompressed = '';

    while (!eof($fh)) {

        my $buffer = '';

        (bytes2int($fh, 2) == 0x425a and getc($fh) eq 'h')
          or confess "Not a valid Bzip2 archive";

        my $level = getc($fh);

        if ($level !~ /^[1-9]\z/) {
            confess "Invalid level: $level";
        }

        $VERBOSE && say STDERR "Compression level: $level";

        my $stream_crc32 = 0;

        while (!eof($fh)) {

            my $block_magic = pack "B48", join('', map { read_bit($fh, \$buffer) } 1 .. 48);

            if ($block_magic eq "1AY&SY") {    # BlockHeader
                $VERBOSE && say STDERR "Block header detected";

                my $crc32 = bits2int($fh, 32, \$buffer);
                $VERBOSE && say STDERR "CRC32 = $crc32";

                $stream_crc32 = ($crc32 ^ (0xffffffff & ((0xffffffff & ($stream_crc32 << 1)) | (($stream_crc32 >> 31) & 0x1)))) & 0xffffffff;

                my $randomized = read_bit($fh, \$buffer);
                $randomized == 0 or confess "randomized not supported";

                my $bwt_idx = bits2int($fh, 24, \$buffer);
                $VERBOSE && say STDERR "BWT index: $bwt_idx";

                my @alphabet;
                my $l1 = bits2int($fh, 16, \$buffer);
                for my $i (0 .. 15) {
                    if ($l1 & (0x8000 >> $i)) {
                        my $l2 = bits2int($fh, 16, \$buffer);
                        for my $j (0 .. 15) {
                            if ($l2 & (0x8000 >> $j)) {
                                push @alphabet, 16 * $i + $j;
                            }
                        }
                    }
                }

                $VERBOSE && say STDERR "MTF alphabet: (@alphabet)";

                my $num_trees = bits2int($fh, 3, \$buffer);
                $VERBOSE && say STDERR "Number or trees: $num_trees";

                my $num_sels = bits2int($fh, 15, \$buffer);
                $VERBOSE && say STDERR "Number of selectors: $num_sels";

                my @idxs;
                for (1 .. $num_sels) {
                    my $i = 0;
                    while (read_bit($fh, \$buffer)) {
                        $i += 1;
                        ($i < $num_trees) or confess "error";
                    }
                    push @idxs, $i;
                }

                my $sels = mtf_decode(\@idxs, [0 .. $num_trees - 1]);
                $VERBOSE && say STDERR "Selectors: (@$sels)";

                my $num_syms = scalar(@alphabet) + 2;

                my @trees;
                for (1 .. $num_trees) {
                    my @clens;
                    my $clen = bits2int($fh, 5, \$buffer);
                    for (1 .. $num_syms) {
                        while (1) {

                            ($clen > 0 and $clen <= $MaxHuffmanBits) or confess "invalid code length: $clen";

                            if (not read_bit($fh, \$buffer)) {
                                last;
                            }

                            $clen -= read_bit($fh, \$buffer) ? 1 : -1;
                        }

                        push @clens, $clen;
                    }
                    push @trees, \@clens;
                    $VERBOSE && say STDERR "Code lengths: (@clens)";
                }

                foreach my $tree (@trees) {
                    my $maxLen = max(@$tree);
                    my $sum    = 1 << $maxLen;
                    for my $clen (@$tree) {
                        $sum -= (1 << $maxLen) >> $clen;
                    }
                    $sum == 0 or confess "incomplete tree not supported: (@$tree)";
                }

                my @huffman_trees = map { (huffman_from_code_lengths($_))[1] } @trees;

                my $eob = @alphabet + 1;

                my @zrle;
                my $code = '';

                my $sel_idx = 0;
                my $tree    = $huffman_trees[$sels->[$sel_idx]];
                my $decoded = 50;

                while (!eof($fh)) {
                    $code .= read_bit($fh, \$buffer);

                    if (length($code) > $MaxHuffmanBits) {
                        confess "[!] Something went wrong: length of code `$code` is > $MaxHuffmanBits.";
                    }

                    if (exists($tree->{$code})) {

                        my $sym = $tree->{$code};

                        if ($sym == $eob) {    # end of block marker
                            $VERBOSE && say STDERR "EOB detected: $sym";
                            last;
                        }

                        push @zrle, $sym;
                        $code = '';

                        if (--$decoded <= 0) {
                            if (++$sel_idx <= $#$sels) {
                                $tree = $huffman_trees[$sels->[$sel_idx]];
                            }
                            else {
                                confess "No more selectors";    # should not happen
                            }
                            $decoded = 50;
                        }
                    }
                }

                my @mtf = reverse @{zrle_decode([reverse @zrle])};
                my $bwt = symbols2string mtf_decode(\@mtf, \@alphabet);

                my $rle4 = string2symbols bwt_decode($bwt, $bwt_idx);
                my $data = rle4_decode($rle4);
                my $dec  = symbols2string($data);

                my $new_crc32 = oct('0b' . int2bits_lsb(crc32(pack('b*', unpack('B*', $dec))), 32));

                $VERBOSE && say STDERR "Computed CRC32: $new_crc32";

                if ($crc32 != $new_crc32) {
                    confess "CRC32 error: $crc32 (stored) != $new_crc32 (actual)";
                }

                $decompressed .= $dec;
            }
            elsif ($block_magic eq "\27rE8P\x90") {    # BlockFooter
                $VERBOSE && say STDERR "Block footer detected";
                my $stored_stream_crc32 = bits2int($fh, 32, \$buffer);
                $VERBOSE && say STDERR "Stream CRC: $stored_stream_crc32";

                if ($stored_stream_crc32 != $stream_crc32) {
                    confess "Stream CRC32 error: $stored_stream_crc32 (stored) != $stream_crc32 (actual)";
                }

                $buffer = '';
                last;
            }
            else {
                confess "Unknown block magic: $block_magic";
            }
        }

        $VERBOSE && say STDERR "End of container";
    }

    return $decompressed;
}

########################################
# GZIP compressor
########################################

sub _code_length_encoding ($dict) {

    my @lengths;

    foreach my $symbol (0 .. max(keys %$dict) // 0) {
        if (exists($dict->{$symbol})) {
            push @lengths, length($dict->{$symbol});
        }
        else {
            push @lengths, 0;
        }
    }

    my $size        = scalar(@lengths);
    my $rl          = run_length(\@lengths);
    my $offset_bits = '';

    my @CL_symbols;

    foreach my $pair (@$rl) {
        my ($v, $run) = @$pair;

        while ($v == 0 and $run >= 3) {

            if ($run >= 11) {
                push @CL_symbols, 18;
                $run -= 11;
                $offset_bits .= int2bits_lsb(min($run, 127), 7);
                $run -= 127;
            }

            if ($run >= 3 and $run < 11) {
                push @CL_symbols, 17;
                $run -= 3;
                $offset_bits .= int2bits_lsb(min($run, 7), 3);
                $run -= 7;
            }
        }

        if ($v == 0) {
            push(@CL_symbols, (0) x $run) if ($run > 0);
            next;
        }

        push @CL_symbols, $v;
        $run -= 1;

        while ($run >= 3) {
            push @CL_symbols, 16;
            $run -= 3;
            $offset_bits .= int2bits_lsb(min($run, 3), 2);
            $run -= 3;
        }

        push(@CL_symbols, ($v) x $run) if ($run > 0);
    }

    return (\@CL_symbols, $size, $offset_bits);
}

sub _cl_encoded_bitstring ($cl_dict, $cl_symbols, $offset_bits) {

    my $bitstring = '';
    foreach my $cl_symbol (@$cl_symbols) {
        $bitstring .= $cl_dict->{$cl_symbol};
        if ($cl_symbol == 16) {
            $bitstring .= substr($offset_bits, 0, 2, '');
        }
        elsif ($cl_symbol == 17) {
            $bitstring .= substr($offset_bits, 0, 3, '');
        }
        elsif ($cl_symbol == 18) {
            $bitstring .= substr($offset_bits, 0, 7, '');
        }
    }

    return $bitstring;
}

sub _create_cl_dictionary (@cl_symbols) {

    my @keys;
    my $freq = frequencies(\@cl_symbols);

    while (1) {
        my ($cl_dict) = huffman_from_freq($freq);

        # The CL codes must have at most 7 bits
        return $cl_dict if all { length($_) <= 7 } values %$cl_dict;

        if (scalar(@keys) == 0) {
            @keys = sort { $freq->{$b} <=> $freq->{$a} } keys %$freq;
        }

        # Scale down the frequencies and try again
        foreach my $k (@keys) {
            if ($freq->{$k} > 1) {
                $freq->{$k} >>= 1;
            }
            else {
                last;
            }
        }
    }
}

sub deflate_create_block_type_2 ($literals, $distances, $lengths) {

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = (1 << 15) - 1;             # maximum allowed back-reference distance in LZ parsing

    state $deflate_tables = [make_deflate_tables()];
    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = @$deflate_tables;

    my @CL_order = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

    my $bitstring = '01';

    my @len_symbols;
    my @dist_symbols;
    my $offset_bits = '';

    foreach my $k (0 .. $#$literals) {

        if ($lengths->[$k] == 0) {
            push @len_symbols, $literals->[$k];
            next;
        }

        my $len  = $lengths->[$k];
        my $dist = $distances->[$k];

        {
            my $len_idx = $LENGTH_INDICES->[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};

            push @len_symbols, [$len_idx + 256 - 1, $bits];
            $offset_bits .= int2bits_lsb($len - $min, $bits) if ($bits > 0);
        }

        {
            my $dist_idx = find_deflate_index($dist, $DISTANCE_SYMBOLS);
            my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};

            push @dist_symbols, [$dist_idx - 1, $bits];
            $offset_bits .= int2bits_lsb($dist - $min, $bits) if ($bits > 0);
        }
    }

    push @len_symbols, 256;    # end-of-block marker

    my ($dict)      = huffman_from_symbols([map { ref($_) eq 'ARRAY' ? $_->[0] : $_ } @len_symbols]);
    my ($dist_dict) = huffman_from_symbols([map { $_->[0] } @dist_symbols]);

    my ($LL_code_lengths,       $LL_cl_len,       $LL_offset_bits)       = _code_length_encoding($dict);
    my ($distance_code_lengths, $distance_cl_len, $distance_offset_bits) = _code_length_encoding($dist_dict);

    my $cl_dict = _create_cl_dictionary(@$LL_code_lengths, @$distance_code_lengths);

    my @CL_code_lenghts;
    foreach my $symbol (0 .. 18) {
        if (exists($cl_dict->{$symbol})) {
            push @CL_code_lenghts, length($cl_dict->{$symbol});
        }
        else {
            push @CL_code_lenghts, 0;
        }
    }

    # Put the CL codes in the required order
    @CL_code_lenghts = @CL_code_lenghts[@CL_order];

    while (scalar(@CL_code_lenghts) > 4 and $CL_code_lenghts[-1] == 0) {
        pop @CL_code_lenghts;
    }

    my $CL_code_lengths_bitstring = join('', map { int2bits_lsb($_, 3) } @CL_code_lenghts);

    my $LL_code_lengths_bitstring       = _cl_encoded_bitstring($cl_dict, $LL_code_lengths,       $LL_offset_bits);
    my $distance_code_lengths_bitstring = _cl_encoded_bitstring($cl_dict, $distance_code_lengths, $distance_offset_bits);

    # (5 bits) HLIT = (number of LL code entries present) - 257
    my $HLIT = $LL_cl_len - 257;

    # (5 bits) HDIST = (number of distance code entries present) - 1
    my $HDIST = $distance_cl_len - 1;

    # (4 bits) HCLEN = (number of CL code entries present) - 4
    my $HCLEN = scalar(@CL_code_lenghts) - 4;

    $bitstring .= int2bits_lsb($HLIT,  5);
    $bitstring .= int2bits_lsb($HDIST, 5);
    $bitstring .= int2bits_lsb($HCLEN, 4);

    $bitstring .= $CL_code_lengths_bitstring;
    $bitstring .= $LL_code_lengths_bitstring;
    $bitstring .= $distance_code_lengths_bitstring;

    foreach my $symbol (@len_symbols) {
        if (ref($symbol) eq 'ARRAY') {

            my ($len, $len_offset) = @$symbol;
            $bitstring .= $dict->{$len};
            $bitstring .= substr($offset_bits, 0, $len_offset, '') if ($len_offset > 0);

            my ($dist, $dist_offset) = @{shift(@dist_symbols)};
            $bitstring .= $dist_dict->{$dist};
            $bitstring .= substr($offset_bits, 0, $dist_offset, '') if ($dist_offset > 0);
        }
        else {
            $bitstring .= $dict->{$symbol};
        }
    }

    return $bitstring;
}

sub deflate_create_block_type_1 ($literals, $distances, $lengths) {

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = (1 << 15) - 1;             # maximum allowed back-reference distance in LZ parsing

    state $deflate_tables = [make_deflate_tables()];
    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = @$deflate_tables;

    state $dict;
    state $dist_dict;

    if (!defined($dict)) {

        my @code_lengths = (0) x 288;
        foreach my $i (0 .. 143) {
            $code_lengths[$i] = 8;
        }
        foreach my $i (144 .. 255) {
            $code_lengths[$i] = 9;
        }
        foreach my $i (256 .. 279) {
            $code_lengths[$i] = 7;
        }
        foreach my $i (280 .. 287) {
            $code_lengths[$i] = 8;
        }

        ($dict)      = huffman_from_code_lengths(\@code_lengths);
        ($dist_dict) = huffman_from_code_lengths([(5) x 32]);
    }

    my $bitstring = '10';

    foreach my $k (0 .. $#$literals) {

        if ($lengths->[$k] == 0) {
            $bitstring .= $dict->{$literals->[$k]};
            next;
        }

        my $len  = $lengths->[$k];
        my $dist = $distances->[$k];

        {
            my $len_idx = $LENGTH_INDICES->[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};

            $bitstring .= $dict->{$len_idx + 256 - 1};
            $bitstring .= int2bits_lsb($len - $min, $bits) if ($bits > 0);
        }

        {
            my $dist_idx = find_deflate_index($dist, $DISTANCE_SYMBOLS);
            my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};

            $bitstring .= $dist_dict->{$dist_idx - 1};
            $bitstring .= int2bits_lsb($dist - $min, $bits) if ($bits > 0);
        }
    }

    $bitstring .= $dict->{256};    # end-of-block symbol

    return $bitstring;
}

sub deflate_create_block_type_0_header($chunk) {

    my $chunk_len = length($chunk);
    my $len       = int2bits_lsb($chunk_len,             16);
    my $nlen      = int2bits_lsb((~$chunk_len) & 0xffff, 16);

    $len . $nlen;
}

sub gzip_compress ($in_fh, $lzss_encoding_sub = \&lzss_encode) {

    if (ref($in_fh) eq '') {
        open(my $fh2, '<:raw', \$in_fh) or confess "error: $!";
        return __SUB__->($fh2, $lzss_encoding_sub);
    }

    my $compressed = '';

    open my $out_fh, '>:raw', \$compressed;

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = (1 << 15) - 1;             # maximum allowed back-reference distance in LZ parsing

    state $MAGIC  = pack('C*', 0x1f, 0x8b);         # magic MIME type
    state $CM     = chr(0x08);                      # 0x08 = DEFLATE
    state $FLAGS  = chr(0x00);                      # flags
    state $MTIME  = pack('C*', (0x00) x 4);         # modification time
    state $XFLAGS = chr(0x00);                      # extra flags
    state $OS     = chr(0x03);                      # 0x03 = Unix

    print $out_fh $MAGIC, $CM, $FLAGS, $MTIME, $XFLAGS, $OS;

    my $total_length = 0;
    my $crc32        = 0;

    my $bitstring = '';

    if (eof($in_fh)) {                              # empty file
        $bitstring = '1' . '10' . '0000000';
    }

    state $CHUNK_SIZE = (1 << 15) - 1;

    while (read($in_fh, (my $chunk), $CHUNK_SIZE)) {

        $crc32 = crc32($chunk, $crc32);
        $total_length += length($chunk);
        $bitstring .= eof($in_fh) ? '1' : '0';

        my ($literals, $distances, $lengths) = $lzss_encoding_sub->($chunk);

        my $bt1_bitstring = deflate_create_block_type_1($literals, $distances, $lengths);

        # When block type 1 is larger than the input, then we have random uncompressible data: use block type 0
        if ((length($bt1_bitstring) >> 3) > length($chunk) + 5) {

            $VERBOSE && say STDERR ":: Using block type: 0";

            $bitstring .= '00';

            print $out_fh pack('b*', $bitstring);                                   # pads to a byte
            print $out_fh pack('b*', deflate_create_block_type_0_header($chunk));
            print $out_fh $chunk;

            $bitstring = '';
            next;
        }

        my $bt2_bitstring = deflate_create_block_type_2($literals, $distances, $lengths);

        # When block type 2 is larger than block type 1, then we may have very small data
        if (length($bt2_bitstring) > length($bt1_bitstring)) {
            $VERBOSE && say STDERR ":: Using block type: 1";
            $bitstring .= $bt1_bitstring;
        }
        else {
            $VERBOSE && say STDERR ":: Using block type: 2";
            $bitstring .= $bt2_bitstring;
        }

        print $out_fh pack('b*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));
    }

    if ($bitstring ne '') {
        print $out_fh pack('b*', $bitstring);
    }

    print $out_fh int2bytes_lsb($crc32,        4);
    print $out_fh int2bytes_lsb($total_length, 4);

    return $compressed;
}

###################
# GZIP DECOMPRESSOR
###################

sub deflate_extract_block_type_0 ($in_fh, $buffer, $search_window) {

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = 32768;                     # maximum allowed back-reference distance in LZ parsing

    $$buffer = '';

    my $len           = bytes2int_lsb($in_fh, 2);
    my $nlen          = bytes2int_lsb($in_fh, 2);
    my $expected_nlen = (~$len) & 0xffff;

    if ($expected_nlen != $nlen) {
        confess "[!] The ~length value is not correct: $nlen (actual) != $expected_nlen (expected)";
    }
    else {
        $VERBOSE && print STDERR ":: Chunk length: $len\n";
    }

    read($in_fh, (my $chunk), $len) // confess "Read error: $!";
    $$search_window .= $chunk;

    $$search_window = substr($$search_window, -$LZ_MAX_DIST)
      if (length($$search_window) > 2 * $LZ_MAX_DIST);

    return $chunk;
}

sub _deflate_decode_huffman($in_fh, $buffer, $rev_dict, $dist_rev_dict, $search_window) {

    state $deflate_tables = [make_deflate_tables()];
    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = @$deflate_tables;

    my $data = '';
    my $code = '';

    my $max_ll_code_len   = max(map { length($_) } keys %$rev_dict);
    my $max_dist_code_len = max(map { length($_) } keys %$dist_rev_dict);

    while (1) {
        $code .= read_bit_lsb($in_fh, $buffer);

        if (length($code) > $max_ll_code_len) {
            confess "[!] Something went wrong: length of LL code `$code` is > $max_ll_code_len.";
        }

        if (exists($rev_dict->{$code})) {

            my $symbol = $rev_dict->{$code};

            if ($symbol <= 255) {
                $data           .= chr($symbol);
                $$search_window .= chr($symbol);
            }
            elsif ($symbol == 256) {    # end-of-block marker
                $code = '';
                last;
            }
            else {                      # LZSS decoding
                my ($length, $LL_bits) = @{$LENGTH_SYMBOLS->[$symbol - 256 + 1]};
                $length += bits2int_lsb($in_fh, $LL_bits, $buffer) if ($LL_bits > 0);

                my $dist_code = '';

                while (1) {
                    $dist_code .= read_bit_lsb($in_fh, $buffer);

                    if (length($dist_code) > $max_dist_code_len) {
                        confess "[!] Something went wrong: length of distance code `$dist_code` is > $max_dist_code_len.";
                    }

                    if (exists($dist_rev_dict->{$dist_code})) {
                        last;
                    }
                }

                my ($dist, $dist_bits) = @{$DISTANCE_SYMBOLS->[$dist_rev_dict->{$dist_code} + 1]};
                $dist += bits2int_lsb($in_fh, $dist_bits, $buffer) if ($dist_bits > 0);

                if ($dist == 1) {
                    $$search_window .= substr($$search_window, -1) x $length;
                }
                elsif ($dist >= $length) {    # non-overlapping matches
                    $$search_window .= substr($$search_window, length($$search_window) - $dist, $length);
                }
                else {                        # overlapping matches
                    foreach my $i (1 .. $length) {
                        $$search_window .= substr($$search_window, length($$search_window) - $dist, 1);
                    }
                }

                $data .= substr($$search_window, -$length);
            }

            $code = '';
        }
    }

    if ($code ne '') {
        confess "[!] Something went wrong: code `$code` is not empty!";
    }

    $$search_window = substr($$search_window, -$LZ_MAX_DIST)
      if (length($$search_window) > 2 * $LZ_MAX_DIST);

    return $data;
}

sub deflate_extract_block_type_1 ($in_fh, $buffer, $search_window) {

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = 32768;                     # maximum allowed back-reference distance in LZ parsing

    state $rev_dict;
    state $dist_rev_dict;

    if (!defined($rev_dict)) {

        my @code_lengths = (0) x 288;
        foreach my $i (0 .. 143) {
            $code_lengths[$i] = 8;
        }
        foreach my $i (144 .. 255) {
            $code_lengths[$i] = 9;
        }
        foreach my $i (256 .. 279) {
            $code_lengths[$i] = 7;
        }
        foreach my $i (280 .. 287) {
            $code_lengths[$i] = 8;
        }

        (undef, $rev_dict)      = huffman_from_code_lengths(\@code_lengths);
        (undef, $dist_rev_dict) = huffman_from_code_lengths([(5) x 32]);
    }

    _deflate_decode_huffman($in_fh, $buffer, $rev_dict, $dist_rev_dict, $search_window);
}

sub _decode_CL_lengths($in_fh, $buffer, $CL_rev_dict, $size) {

    my @lengths;
    my $code = '';

    while (1) {
        $code .= read_bit_lsb($in_fh, $buffer);

        if (length($code) > 7) {
            confess "[!] Something went wrong: length of CL code `$code` is > 7.";
        }

        if (exists($CL_rev_dict->{$code})) {
            my $CL_symbol = $CL_rev_dict->{$code};

            if ($CL_symbol <= 15) {
                push @lengths, $CL_symbol;
            }
            elsif ($CL_symbol == 16) {
                push @lengths, ($lengths[-1]) x (3 + bits2int_lsb($in_fh, 2, $buffer));
            }
            elsif ($CL_symbol == 17) {
                push @lengths, (0) x (3 + bits2int_lsb($in_fh, 3, $buffer));
            }
            elsif ($CL_symbol == 18) {
                push @lengths, (0) x (11 + bits2int_lsb($in_fh, 7, $buffer));
            }
            else {
                confess "Unknown CL symbol: $CL_symbol";
            }

            $code = '';
            last if (scalar(@lengths) >= $size);
        }
    }

    if (scalar(@lengths) != $size) {
        confess "Something went wrong: size $size (expected) != ", scalar(@lengths);
    }

    if ($code ne '') {
        confess "Something went wrong: code `$code` is not empty!";
    }

    return @lengths;
}

sub deflate_extract_block_type_2 ($in_fh, $buffer, $search_window) {

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = 32768;                     # maximum allowed back-reference distance in LZ parsing

    # (5 bits) HLIT = (number of LL code entries present) - 257
    my $HLIT = bits2int_lsb($in_fh, 5, $buffer) + 257;

    # (5 bits) HDIST = (number of distance code entries present) - 1
    my $HDIST = bits2int_lsb($in_fh, 5, $buffer) + 1;

    # (4 bits) HCLEN = (number of CL code entries present) - 4
    my $HCLEN = bits2int_lsb($in_fh, 4, $buffer) + 4;

    $VERBOSE && say STDERR ":: Number of LL codes: $HLIT";
    $VERBOSE && say STDERR ":: Number of dist codes: $HDIST";
    $VERBOSE && say STDERR ":: Number of CL codes: $HCLEN";

    my @CL_code_lenghts = (0) x 19;
    my @CL_order        = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

    foreach my $i (0 .. $HCLEN - 1) {
        $CL_code_lenghts[$CL_order[$i]] = bits2int_lsb($in_fh, 3, $buffer);
    }

    $VERBOSE && say STDERR ":: CL code lengths: @CL_code_lenghts";

    my (undef, $CL_rev_dict) = huffman_from_code_lengths(\@CL_code_lenghts);

    my @LL_CL_lengths   = _decode_CL_lengths($in_fh, $buffer, $CL_rev_dict, $HLIT);
    my @dist_CL_lengths = _decode_CL_lengths($in_fh, $buffer, $CL_rev_dict, $HDIST);

    my (undef, $LL_rev_dict)   = huffman_from_code_lengths(\@LL_CL_lengths);
    my (undef, $dist_rev_dict) = huffman_from_code_lengths(\@dist_CL_lengths);

    _deflate_decode_huffman($in_fh, $buffer, $LL_rev_dict, $dist_rev_dict, $search_window);
}

sub deflate_extract_next_block ($in_fh, $buffer, $search_window) {

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = 32768;                     # maximum allowed back-reference distance in LZ parsing

    my $block_type = bits2int_lsb($in_fh, 2, $buffer);

    my $chunk = '';

    if ($block_type == 0) {
        $VERBOSE && say STDERR "\n:: Extracting block of type 0";
        $chunk = deflate_extract_block_type_0($in_fh, $buffer, $search_window);
    }
    elsif ($block_type == 1) {
        $VERBOSE && say STDERR "\n:: Extracting block of type 1";
        $chunk = deflate_extract_block_type_1($in_fh, $buffer, $search_window);
    }
    elsif ($block_type == 2) {
        $VERBOSE && say STDERR "\n:: Extracting block of type 2";
        $chunk = deflate_extract_block_type_2($in_fh, $buffer, $search_window);
    }
    else {
        confess "[!] Unknown block of type: $block_type";
    }

    return $chunk;
}

sub gzip_decompress ($in_fh) {

    if (ref($in_fh) eq '') {
        open(my $fh2, '<:raw', \$in_fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my $decompressed = '';

    open my $out_fh, '>:raw', \$decompressed;

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = (1 << 15) - 1;             # maximum allowed back-reference distance in LZ parsing

    my $MAGIC = (getc($in_fh) // confess "error") . (getc($in_fh) // confess "error");

    if ($MAGIC ne pack('C*', 0x1f, 0x8b)) {
        confess "Not a valid GZIP container!";
    }

    my $CM     = getc($in_fh) // confess "error";                             # 0x08 = DEFLATE
    my $FLAGS  = ord(getc($in_fh) // confess "error");                        # flags
    my $MTIME  = join('', map { getc($in_fh) // confess "error" } 1 .. 4);    # modification time
    my $XFLAGS = getc($in_fh) // confess "error";                             # extra flags
    my $OS     = getc($in_fh) // confess "error";                             # 0x03 = Unix

    if ($CM ne chr(0x08)) {
        confess "Only DEFLATE compression method is supported (0x08)! Got: 0x", sprintf('%02x', ord($CM));
    }

    # Reference:
    #   https://web.archive.org/web/20240221024029/https://forensics.wiki/gzip/

    my $has_filename        = 0;
    my $has_comment         = 0;
    my $has_header_checksum = 0;
    my $has_extra_fields    = 0;

    if ($FLAGS & 0x08) {
        $has_filename = 1;
    }

    if ($FLAGS & 0x10) {
        $has_comment = 1;
    }

    if ($FLAGS & 0x02) {
        $has_header_checksum = 1;
    }

    if ($FLAGS & 0x04) {
        $has_extra_fields = 1;
    }

    if ($has_extra_fields) {
        my $size = bytes2int_lsb($in_fh, 2);
        read($in_fh, (my $extra_field_data), $size) // confess "can't read extra field data: $!";
        $VERBOSE && say STDERR ":: Extra field data: $extra_field_data";
    }

    if ($has_filename) {
        my $filename = read_null_terminated($in_fh);    # filename
        $VERBOSE && say STDERR ":: Filename: $filename";
    }

    if ($has_comment) {
        my $comment = read_null_terminated($in_fh);     # comment
        $VERBOSE && say STDERR ":: Comment: $comment";
    }

    # TODO: verify the header checksum
    if ($has_header_checksum) {
        my $header_checksum = bytes2int_lsb($in_fh, 2);
        $VERBOSE && say STDERR ":: Header checksum: $header_checksum";
    }

    my $crc32         = 0;
    my $actual_length = 0;
    my $buffer        = '';
    my $search_window = '';

    while (1) {

        my $is_last = read_bit_lsb($in_fh, \$buffer);
        my $chunk   = deflate_extract_next_block($in_fh, \$buffer, \$search_window);

        print $out_fh $chunk;
        $crc32 = crc32($chunk, $crc32);
        $actual_length += length($chunk);

        last if $is_last;
    }

    $buffer = '';    # discard any padding bits

    my $stored_crc32 = bits2int_lsb($in_fh, 32, \$buffer);
    my $actual_crc32 = $crc32;

    if ($stored_crc32 != $actual_crc32) {
        confess "[!] The CRC32 does not match: $actual_crc32 (actual) != $stored_crc32 (stored)";
    }
    else {
        $VERBOSE && print STDERR ":: CRC32 value: $actual_crc32\n";
    }

    my $stored_length = bits2int_lsb($in_fh, 32, \$buffer);

    if ($stored_length != $actual_length) {
        confess "[!] The length does not match: $actual_length (actual) != $stored_length (stored)";
    }
    else {
        $VERBOSE && print STDERR ":: Total length: $actual_length\n";
    }

    if (eof($in_fh)) {
        $VERBOSE && print STDERR "\n:: Reached the end of the file.\n";
    }
    else {
        $VERBOSE && print STDERR "\n:: There is something else in the container! Trying to recurse!\n\n";
        return ($decompressed . __SUB__->($in_fh));
    }

    return $decompressed;
}

###############################
# ZLIB compressor
###############################

sub zlib_compress ($in_fh, $lzss_encoding_sub = \&lzss_encode) {

    if (ref($in_fh) eq '') {
        open(my $fh2, '<:raw', \$in_fh) or confess "error: $!";
        return __SUB__->($fh2, $lzss_encoding_sub);
    }

    my $compressed = '';

    open my $out_fh, '>:raw', \$compressed;

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = (1 << 15) - 1;             # maximum allowed back-reference distance in LZ parsing

    my $CMF = (7 << 4) | 8;
    my $FLG = 2 << 6;

    while (($CMF * 256 + $FLG) % 31 != 0) {
        ++$FLG;
    }

    my $bitstring = '';
    my $adler32   = 1;

    print $out_fh chr($CMF);
    print $out_fh chr($FLG);

    if (eof($in_fh)) {    # empty file
        $bitstring = '1' . '10' . '0000000';
    }

    state $CHUNK_SIZE = (1 << 15) - 1;

    while (read($in_fh, (my $chunk), $CHUNK_SIZE)) {

        $adler32 = adler32($chunk, $adler32);
        $bitstring .= eof($in_fh) ? '1' : '0';

        my ($literals, $distances, $lengths) = $lzss_encoding_sub->($chunk);

        my $bt1_bitstring = deflate_create_block_type_1($literals, $distances, $lengths);

        # When block type 1 is larger than the input, then we have random uncompressible data: use block type 0
        if ((length($bt1_bitstring) >> 3) > length($chunk) + 5) {

            $VERBOSE && say STDERR ":: Using block type: 0";

            $bitstring .= '00';

            print $out_fh pack('b*', $bitstring);                                   # pads to a byte
            print $out_fh pack('b*', deflate_create_block_type_0_header($chunk));
            print $out_fh $chunk;

            $bitstring = '';
            next;
        }

        my $bt2_bitstring = deflate_create_block_type_2($literals, $distances, $lengths);

        # When block type 2 is larger than block type 1, then we may have very small data
        if (length($bt2_bitstring) > length($bt1_bitstring)) {
            $VERBOSE && say STDERR ":: Using block type: 1";
            $bitstring .= $bt1_bitstring;
        }
        else {
            $VERBOSE && say STDERR ":: Using block type: 2";
            $bitstring .= $bt2_bitstring;
        }

        print $out_fh pack('b*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));
    }

    if ($bitstring ne '') {
        print $out_fh pack('b*', $bitstring);
    }

    print $out_fh int2bytes($adler32, 4);

    return $compressed;
}

###############################
# ZLIB decompressor
###############################

sub zlib_decompress($in_fh) {

    if (ref($in_fh) eq '') {
        open(my $fh2, '<:raw', \$in_fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my $decompressed = '';

    open my $out_fh, '>:raw', \$decompressed;

    local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);    # minimum match length in LZ parsing
    local $LZ_MAX_LEN  = 258;                       # maximum match length in LZ parsing
    local $LZ_MAX_DIST = (1 << 15) - 1;             # maximum allowed back-reference distance in LZ parsin

    my $adler32 = 1;

    my $CMF = ord(getc($in_fh));
    my $FLG = ord(getc($in_fh));

    if (($CMF * 256 + $FLG) % 31 != 0) {
        confess "Invalid header checksum!\n";
    }

    my $CINFO = $CMF >> 4;

    if ($CINFO > 7) {
        confess "Values of CINFO above 7 are not supported!\n";
    }

    my $method = $CMF & 0b1111;

    if ($method != 8) {
        confess "Only method 8 (DEFLATE) is supported!\n";
    }

    my $buffer        = '';
    my $search_window = '';

    while (1) {

        my $is_last = read_bit_lsb($in_fh, \$buffer);
        my $chunk   = deflate_extract_next_block($in_fh, \$buffer, \$search_window);

        print $out_fh $chunk;
        $adler32 = adler32($chunk, $adler32);

        last if $is_last;
    }

    my $stored_adler32 = bytes2int($in_fh, 4);

    if ($adler32 != $stored_adler32) {
        confess "Adler32 checksum does not match: $adler32 (actual) != $stored_adler32 (stored)\n";
    }

    if (eof($in_fh)) {
        $VERBOSE && print STDERR "\n:: Reached the end of the file.\n";
    }
    else {
        $VERBOSE && print STDERR "\n:: There is something else in the container! Trying to recurse!\n\n";
        return ($decompressed . __SUB__->($in_fh));
    }

    return $decompressed;
}

###############################
# LZ4 compressor
###############################

sub lz4_compress($fh, $lzss_encoding_sub = \&lzss_encode) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2, $lzss_encoding_sub);
    }

    my $compressed = '';

    $compressed .= int2bytes_lsb(0x184D2204, 4);    # LZ4 magic number

    my $fd = '';                                    # frame description
    $fd .= chr(0b01_10_00_00);                      # flags (FLG)
    $fd .= chr(0b0_111_0000);                       # block description (BD)

    $compressed .= $fd;
    $compressed .= chr(115);                        # header checksum

    state $CHUNK_SIZE = 1 << 17;

    while (read($fh, (my $chunk), $CHUNK_SIZE)) {

        my ($literals, $distances, $lengths) = do {
            local $LZ_MIN_LEN  = 4 if ($LZ_MIN_LEN < 4);
            local $LZ_MAX_LEN  = ~0;
            local $LZ_MAX_DIST = (1 << 16) - 1;
            $lzss_encoding_sub->(substr($chunk, 0, -5));
        };

        # The last 5 bytes of each block must be literals
        # https://github.com/lz4/lz4/issues/1495
        push @$literals, unpack('C*', substr($chunk, -5));

        my $literals_end = $#{$literals};

        my $block = '';

        for (my $i = 0 ; $i <= $literals_end ; ++$i) {

            my @uncompressed;
            while ($i <= $literals_end and defined($literals->[$i])) {
                push @uncompressed, $literals->[$i];
                ++$i;
            }

            my $literals_string = pack('C*', @uncompressed);
            my $literals_length = scalar(@uncompressed);

            my $match_len = $lengths->[$i] ? ($lengths->[$i] - 4) : 0;

            $block .= chr((($literals_length >= 15 ? 15 : $literals_length) << 4) | ($match_len >= 15 ? 15 : $match_len));

            $literals_length -= 15;
            $match_len       -= 15;

            while ($literals_length >= 0) {
                $block .= ($literals_length >= 255 ? "\xff" : chr($literals_length));
                $literals_length -= 255;
            }

            $block .= $literals_string;

            my $dist = $distances->[$i] // last;
            $block .= pack('b*', scalar reverse sprintf('%016b', $dist));

            while ($match_len >= 0) {
                $block .= ($match_len >= 255 ? "\xff" : chr($match_len));
                $match_len -= 255;
            }
        }

        if ($block ne '') {
            $compressed .= int2bytes_lsb(length($block), 4);
            $compressed .= $block;
        }
    }

    $compressed .= int2bytes_lsb(0x00000000, 4);    # EndMark
    return $compressed;
}

###############################
# LZ4 decompressor
###############################

sub lz4_decompress($fh) {

    if (ref($fh) eq '') {
        open(my $fh2, '<:raw', \$fh) or confess "error: $!";
        return __SUB__->($fh2);
    }

    my $decompressed = '';

    while (!eof($fh)) {

        bytes2int_lsb($fh, 4) == 0x184D2204 or confess "Incorrect LZ4 Frame magic number";

        my $FLG = ord(getc($fh));
        my $BD  = ord(getc($fh));

        my $version    = $FLG & 0b11_00_00_00;
        my $B_indep    = $FLG & 0b00_10_00_00;
        my $B_checksum = $FLG & 0b00_01_00_00;
        my $C_size     = $FLG & 0b00_00_10_00;
        my $C_checksum = $FLG & 0b00_00_01_00;
        my $DictID     = $FLG & 0b00_00_00_01;

        my $Block_MaxSize = $BD & 0b0_111_0000;

        $VERBOSE && say STDERR "Maximum block size: $Block_MaxSize";

        if ($version != 0b01_00_00_00) {
            confess "Error: Invalid version number";
        }

        if ($C_size) {
            my $content_size = bytes2int_lsb($fh, 8);
            $VERBOSE && say STDERR "Content size: ", $content_size;
        }

        if ($DictID) {
            my $dict_id = bytes2int_lsb($fh, 4);
            $VERBOSE && say STDERR "Dictionary ID: ", $dict_id;
        }

        my $header_checksum = ord(getc($fh));

        # TODO: compute and verify the header checksum
        $VERBOSE && say STDERR "Header checksum: ", $header_checksum;

        my $decoded = '';

        while (!eof($fh)) {

            my $block_size = bytes2int_lsb($fh, 4);

            if ($block_size == 0x00000000) {    # signifies an EndMark
                $VERBOSE && say STDERR "Block size == 0";
                last;
            }

            $VERBOSE && say STDERR "Block size: $block_size";

            if ($block_size >> 31) {
                $VERBOSE && say STDERR "Highest bit set: ", $block_size;
                $block_size &= ((1 << 31) - 1);
                $VERBOSE && say STDERR "Block size: ", $block_size;
                my $uncompressed = '';
                read($fh, $uncompressed, $block_size);
                $decoded .= $uncompressed;
            }
            else {

                my $compressed = '';
                read($fh, $compressed, $block_size);

                while ($compressed ne '') {
                    my $len_byte = ord(substr($compressed, 0, 1, ''));

                    my $literals_length = $len_byte >> 4;
                    my $match_len       = $len_byte & 0b1111;

                    ## say STDERR "Literal: ",   $literals_length;
                    ## say STDERR "Match len: ", $match_len;

                    if ($literals_length == 15) {
                        while (1) {
                            my $byte_len = ord(substr($compressed, 0, 1, ''));
                            $literals_length += $byte_len;
                            last if $byte_len != 255;
                        }
                    }

                    ## say STDERR "Total literals length: ", $literals_length;

                    my $literals = '';

                    if ($literals_length > 0) {
                        $literals = substr($compressed, 0, $literals_length, '');
                    }

                    if ($compressed eq '') {    # end of block
                        $decoded .= $literals;
                        last;
                    }

                    my $offset = oct('0b' . reverse unpack('b16', substr($compressed, 0, 2, '')));

                    if ($offset == 0) {
                        confess "Corrupted block";
                    }

                    ## say STDERR "Offset: $offset";

                    if ($match_len == 15) {
                        while (1) {
                            my $byte_len = ord(substr($compressed, 0, 1, ''));
                            $match_len += $byte_len;
                            last if $byte_len != 255;
                        }
                    }

                    $decoded .= $literals;
                    $match_len += 4;

                    ## say STDERR "Total match len: $match_len\n";

                    if ($offset >= $match_len) {    # non-overlapping matches
                        $decoded .= substr($decoded, length($decoded) - $offset, $match_len);
                    }
                    elsif ($offset == 1) {
                        $decoded .= substr($decoded, -1) x $match_len;
                    }
                    else {                          # overlapping matches
                        foreach my $i (1 .. $match_len) {
                            $decoded .= substr($decoded, length($decoded) - $offset, 1);
                        }
                    }
                }
            }

            if ($B_checksum) {
                my $content_checksum = bytes2int_lsb($fh, 4);
                $VERBOSE && say STDERR "Block checksum: $content_checksum";
            }

            if ($B_indep) {    # blocks are independent of each other
                $decompressed .= $decoded;
                $decoded = '';
            }
            elsif (length($decoded) > 2**16) {    # blocks are dependent
                $decompressed .= substr($decoded, 0, -(2**16), '');
            }
        }

        # TODO: compute and verify checksum
        if ($C_checksum) {
            my $content_checksum = bytes2int_lsb($fh, 4);
            $VERBOSE && say STDERR "Content checksum: $content_checksum";
        }

        $decompressed .= $decoded;
    }

    return $decompressed;
}

1;
