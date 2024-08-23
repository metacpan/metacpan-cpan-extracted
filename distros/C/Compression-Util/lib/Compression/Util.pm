package Compression::Util;

use utf8;
use 5.036;
use List::Util qw(min uniq max sum all);

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.11';
our $VERBOSE = 0;        # verbose mode

our $LZ_MIN_LEN       = 4;          # minimum match length in LZ parsing
our $LZ_MAX_LEN       = 1 << 15;    # maximum match length in LZ parsing
our $LZ_MAX_DIST      = ~0;         # maximum allowed back-reference distance in LZ parsing
our $LZ_MAX_CHAIN_LEN = 32;         # how many recent positions to remember in LZ parsing

# Arithmetic Coding settings
use constant BITS         => 32;
use constant MAX          => oct('0b' . ('1' x BITS));
use constant INITIAL_FREQ => 1;

our %EXPORT_TAGS = (
    'all' => [
        qw(

          crc32

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
          )
    ]
);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}}, '$VERBOSE', '$LZ_MAX_CHAIN_LEN', '$LZ_MIN_LEN', '$LZ_MAX_LEN', '$LZ_MAX_DIST');
our @EXPORT;

##########################
# Misc low-level functions
##########################

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // die "can't read bit");
    }

    chop($$bitstring);
}

sub read_bit_lsb ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('B*', getc($fh) // die "can't read bit");
    }

    chop($$bitstring);
}

sub read_bits ($fh, $bits_len) {

    read($fh, (my $data), $bits_len >> 3) // die "Read error: $!";
    $data = unpack('B*', $data);

    while (length($data) < $bits_len) {
        $data .= unpack('B*', getc($fh) // die "can't read bits");
    }

    if (length($data) > $bits_len) {
        $data = substr($data, 0, $bits_len);
    }

    return $data;
}

sub read_bits_lsb ($fh, $bits_len) {

    read($fh, (my $data), $bits_len >> 3) // die "Read error: $!";
    $data = unpack('b*', $data);

    while (length($data) < $bits_len) {
        $data .= unpack('b*', getc($fh) // die "can't read bits");
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
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2, $n);
    }

    my $bytes = '';
    $bytes .= getc($fh) for (1 .. $n);
    oct('0b' . unpack('B*', $bytes));
}

sub bytes2int_lsb ($fh, $n) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
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
        my $c = getc($fh) // die "can't read character";
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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
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
        die "Too few bits: $T > ${\MAX}";
    }

    my $low      = 0;
    my $high     = MAX;
    my $uf_count = 0;

    foreach my $c (@bytes) {

        my $w = $high - $low + 1;

        $high = ($low + int(($w * $cf->[$c + 1]) / $T) - 1) & MAX;
        $low  = ($low + int(($w * $cf->[$c]) / $T)) & MAX;

        if ($high > MAX) {
            die "high > MAX: $high > ${\MAX}";
        }

        if ($low >= $high) { die "$low >= $high" }

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
        open my $fh2, '<:raw', \$fh;
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
            die "error";
        }

        if ($low >= $high) { die "$low >= $high" }

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
        die "Too few bits: $T > ${\MAX}";
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
            die "high > MAX: $high > ${\MAX}";
        }

        if ($low >= $high) { die "$low >= $high" }

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
        open my $fh2, '<:raw', \$fh;
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
            die "high > MAX: ($high > ${\MAX})";
        }

        if ($low >= $high) { die "$low >= $high" }

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
#<<<
    [
     map { $_->[1] } sort {
              ($a->[0] cmp $b->[0])
           || ((substr($s, $a->[1]) . substr($s, 0, $a->[1])) cmp (substr($s, $b->[1]) . substr($s, 0, $b->[1])))
     }
     map {
         my $t = substr($s, $_, $LOOKAHEAD_LEN);

         if (length($t) < $LOOKAHEAD_LEN) {
             $t .= substr($s, 0, ($_ < $LOOKAHEAD_LEN) ? $_ : ($LOOKAHEAD_LEN - length($t)));
         }

         [$t, $_]
       } 0 .. length($s) - 1
    ];
#>>>
}

sub bwt_encode ($s, $LOOKAHEAD_LEN = 128) {

    if (ref($s) eq 'ARRAY') {
        return bwt_encode_symbolic($s);
    }

    my $bwt = bwt_sort($s, $LOOKAHEAD_LEN);
    my $ret = join('', map { substr($s, $_ - 1, 1) } @$bwt);

    my $idx = 0;
    foreach my $i (@$bwt) {
        $i || last;
        ++$idx;
    }

    return ($ret, $idx);
}

sub bwt_decode ($bwt, $idx) {    # fast inversion

    my @tail = split(//, $bwt);
    my @head = sort @tail;

    my %indices;
    foreach my $i (0 .. $#tail) {
        push @{$indices{$tail[$i]}}, $i;
    }

    my @table;
    foreach my $v (@head) {
        push @table, shift(@{$indices{$v}});
    }

    my $dec = '';
    my $i   = $idx;

    for (1 .. scalar(@head)) {
        $dec .= $head[$i];
        $i = $table[$i];
    }

    return $dec;
}

##############################################
# Burrows-Wheeler transform (symbolic variant)
##############################################

sub bwt_sort_symbolic ($s) {    # O(n) space (slowish)

    my @cyclic = @$s;
    my $len    = scalar(@cyclic);

    my $rle = 1;
    foreach my $i (1 .. $len - 1) {
        if ($cyclic[$i] != $cyclic[$i - 1]) {
            $rle = 0;
            last;
        }
    }

    $rle && return [0 .. $len - 1];

    [
     sort {
         my ($i, $j) = ($a, $b);

         while ($cyclic[$i] == $cyclic[$j]) {
             $i %= $len if (++$i >= $len);
             $j %= $len if (++$j >= $len);
         }

         $cyclic[$i] <=> $cyclic[$j];
       } 0 .. $len - 1
    ];
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
        die "[BUG] Unknown encoding method: $method";
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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2);
    }

    if (ord(getc($fh) // die "error") == 1) {
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

    @table[@alphabet] = (0 .. $#alphabet);

    foreach my $c (@$symbols) {
        push @C, (my $index = $table[$c]);
        unshift(@alphabet, splice(@alphabet, $index, 1));
        @table[@alphabet[0 .. $index]] = (0 .. $index);
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
        open my $fh2, '<:raw', \$fh;
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

    if (ref($chunk) eq 'ARRAY') {
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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
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

sub huffman_decode ($bits, $rev_dict) {
    local $" = '|';
    [
     split(
         ' ', $bits =~ s{(@{[
        map  { $_->[1] }
        sort { $a->[0] <=> $b->[0] }
        map  { [length($_), $_] }
        keys %$rev_dict]
    })}{$rev_dict->{$1} }gr
          )
    ];
}

# produce encode and decode dictionary from a tree
sub _huffman_walk_tree ($node, $code, $h) {

    my $c = $node->[0] // return $h;
    if (ref $c) { __SUB__->($c->[$_], $code . $_, $h) for ('0', '1') }
    else        { $h->{$c} = $code }

    return $h;
}

sub huffman_from_code_lengths ($code_lengths) {

    # This algorithm is based on the pseudocode in RFC 1951 (Section 3.2.2)
    # (Steps are numbered as in the RFC)

    # Step 1
    my $max_length    = max(@$code_lengths) // 0;
    my @length_counts = (0) x ($max_length + 1);
    foreach my $length (@$code_lengths) {
        ++$length_counts[$length];
    }

    # Step 2
    my $code = 0;
    $length_counts[0] = 0;
    my @next_code = (0) x ($max_length + 1);
    foreach my $bits (1 .. $max_length) {
        $code = ($code + $length_counts[$bits - 1]) << 1;
        $next_code[$bits] = $code;
    }

    # Step 3
    my @code_table;
    foreach my $n (0 .. $#{$code_lengths}) {
        my $length = $code_lengths->[$n];
        if ($length != 0) {
            $code_table[$n] = sprintf('%0*b', $length, $next_code[$length]);
            ++$next_code[$length];
        }
    }

    my %dict;
    my %rev_dict;

    foreach my $i (0 .. $#{$code_lengths}) {
        my $code = $code_table[$i];
        if (defined($code)) {
            $dict{$i}        = $code;
            $rev_dict{$code} = $i;
        }
    }

    return (wantarray ? (\%dict, \%rev_dict) : \%dict);
}

# make a tree, and return resulting dictionaries
sub huffman_from_freq ($freq) {

    my @nodes      = map { [$_, $freq->{$_}] } sort { $a <=> $b } keys %$freq;
    my $max_symbol = scalar(@nodes) ? $nodes[-1][0] : -1;

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice(@nodes, 0, 2);
        if (defined($x)) {
            if (defined($y)) {
                push @nodes, [[$x, $y], $x->[1] + $y->[1]];
            }
            else {
                push @nodes, [[$x], $x->[1]];
            }
        }
    } while (@nodes > 1);

    my $h = _huffman_walk_tree($nodes[0], '', {});

    my @code_lengths;
    foreach my $i (0 .. $max_symbol) {
        if (exists $h->{$i}) {
            $code_lengths[$i] = length($h->{$i});
        }
        else {
            $code_lengths[$i] = 0;
        }
    }

    huffman_from_code_lengths(\@code_lengths);
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
        open my $fh2, '<:raw', \$fh;
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
    die "error";
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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
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

sub lzss_encode_symbolic ($symbols) {

    if (ref($symbols) eq '') {
        return lzss_encode($symbols);
    }

    my $la  = 0;
    my $end = $#$symbols;

    my $min_len       = $LZ_MIN_LEN;          # minimum match length
    my $max_len       = $LZ_MAX_LEN;          # maximum match length
    my $max_dist      = $LZ_MAX_DIST;         # maximum offset distance
    my $max_chain_len = $LZ_MAX_CHAIN_LEN;    # how many recent positions to keep track of

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $upto      = $la + $min_len - 1;
        my $lookahead = join(' ', @{$symbols}[$la .. ($upto > $end ? $end : $upto)]);

        if (exists($table{$lookahead})) {

            foreach my $p (@{$table{$lookahead}}) {

                last if ($la - $p > $max_dist);

                my $n = $min_len;

                while ($la + $n <= $end and $symbols->[$la + $n - 1] == $symbols->[$p + $n - 1] and $n <= $max_len) {
                    ++$n;
                }

                if ($n > $best_n) {
                    $best_p = $p;
                    $best_n = $n;
                }
            }

            my @matched = @{$symbols}[$la .. $la + $best_n - 1];
            my @key_arr = @matched[0 .. $min_len - 1];

            foreach my $i (0 .. scalar(@matched) - $min_len) {

                my $key = join(' ', @key_arr);
                unshift @{$table{$key}}, $la + $i;

                if (scalar(@{$table{$key}}) > $max_chain_len) {
                    pop @{$table{$key}};
                }

                shift(@key_arr);
                push @key_arr, $matched[$i + $min_len];
            }
        }

        if ($best_n == 1) {
            $table{$lookahead} = [$la];
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

        my $length = $lengths->[$i]   // die "bad input";
        my $dist   = $distances->[$i] // die "bad input";

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

sub lzss_encode ($str) {

    if (ref($str) eq 'ARRAY') {
        return lzss_encode_symbolic($str);
    }

    my $la      = 0;
    my @symbols = unpack('C*', $str);
    my $end     = $#symbols;

    my $min_len       = $LZ_MIN_LEN;          # minimum match length
    my $max_len       = $LZ_MAX_LEN;          # maximum match length
    my $max_dist      = $LZ_MAX_DIST;         # maximum offset distance
    my $max_chain_len = $LZ_MAX_CHAIN_LEN;    # how many recent positions to keep track of

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $lookahead = substr($str, $la, $min_len);

        if (exists($table{$lookahead})) {

            foreach my $p (@{$table{$lookahead}}) {

                last if ($la - $p > $max_dist);

                my $n = $min_len;

                while ($la + $n <= $end and $symbols[$la + $n - 1] == $symbols[$p + $n - 1] and $n <= $max_len) {
                    ++$n;
                }

                if ($n > $best_n) {
                    $best_p = $p;
                    $best_n = $n;
                }
            }

            my $matched = substr($str, $la, $best_n);

            foreach my $i (0 .. length($matched) - $min_len) {

                my $key = substr($matched, $i, $min_len);
                unshift @{$table{$key}}, $la + $i;

                if (scalar(@{$table{$key}}) > $max_chain_len) {
                    pop @{$table{$key}};
                }
            }
        }

        if ($best_n == 1) {
            $table{$lookahead} = [$la];
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

        my $length = $lengths->[$i]   // die "bad input";
        my $dist   = $distances->[$i] // die "bad input";

        if ($dist >= $length) {    # non-overlapping matches
            $data .= substr($data, $data_len - $dist, $length) // die "bad input";
        }
        elsif ($dist == 1) {       # run-length of last character
            $data .= substr($data, -1) x $length;
        }
        else {                     # overlapping matches
            foreach my $i (1 .. $length) {
                $data .= substr($data, $data_len + $i - $dist - 1, 1) // die "bad input";
            }
        }

        $data_len += $length;
    }

    return $data;
}

###################
# LZSSF Compression
###################

sub lzss_encode_fast_symbolic ($symbols) {

    if (ref($symbols) eq '') {
        return lzss_encode_fast($symbols);
    }

    my $la  = 0;
    my $end = $#$symbols;

    my $min_len  = $LZ_MIN_LEN;     # minimum match length
    my $max_len  = $LZ_MAX_LEN;     # maximum match length
    my $max_dist = $LZ_MAX_DIST;    # maximum offset distance

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $upto      = $la + $min_len - 1;
        my $lookahead = join(' ', @{$symbols}[$la .. ($upto > $end ? $end : $upto)]);

        if (exists($table{$lookahead}) and $la - $table{$lookahead} <= $max_dist) {

            my $p = $table{$lookahead};
            my $n = $min_len;

            while ($la + $n <= $end and $symbols->[$la + $n - 1] == $symbols->[$p + $n - 1] and $n <= $max_len) {
                ++$n;
            }

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

sub lzss_encode_fast($str) {

    if (ref($str) eq 'ARRAY') {
        return lzss_encode_fast_symbolic($str);
    }

    my @symbols = unpack('C*', $str);

    my $la  = 0;
    my $end = $#symbols;

    my $min_len  = $LZ_MIN_LEN;     # minimum match length
    my $max_len  = $LZ_MAX_LEN;     # maximum match length
    my $max_dist = $LZ_MAX_DIST;    # maximum offset distance

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $lookahead = substr($str, $la, $min_len);

        if (exists($table{$lookahead}) and $la - $table{$lookahead} <= $max_dist) {

            my $p = $table{$lookahead};
            my $n = $min_len;

            while ($la + $n <= $end and $symbols[$la + $n - 1] == $symbols[$p + $n - 1] and $n <= $max_len) {
                ++$n;
            }

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

        my $len_byte = shift(@match_symbols) // die "bad input";

        my $literals_length = $len_byte >> 5;
        my $match_len       = $len_byte & 0b11111;

        if ($literals_length == 7) {
            while (1) {
                my $byte_len = shift(@len_symbols) // die "bad input";
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
                my $byte_len = shift(@match_symbols) // die "bad input";
                $match_len += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $dist = shift(@dist_symbols) // die "bad input";

        if ($dist >= $match_len) {    # non-overlapping matches
            $data .= substr($data, $data_len - $dist, $match_len) // die "bad input";
        }
        elsif ($dist == 1) {          # run-length of last character
            $data .= substr($data, -1) x $match_len;
        }
        else {                        # overlapping matches
            foreach my $i (1 .. $match_len) {
                $data .= substr($data, $data_len + $i - $dist - 1, 1) // die "bad input";
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

        my $len_byte = shift(@match_symbols) // die "bad input";

        my $literals_length = $len_byte >> 5;
        my $match_len       = $len_byte & 0b11111;

        if ($literals_length == 7) {
            while (1) {
                my $byte_len = shift(@len_symbols) // die "bad input";
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
                my $byte_len = shift(@match_symbols) // die "bad input";
                $match_len += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $dist = shift(@dist_symbols) // die "bad input";

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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
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
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2, $entropy_sub);
    }

    my ($literals, $distances, $lengths) = deflate_decode($fh, $entropy_sub);
    lzss_decode($literals, $distances, $lengths);
}

sub lzss_decompress_symbolic($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2, $entropy_sub);
    }

    my ($literals, $distances, $lengths) = deflate_decode($fh, $entropy_sub);
    lzss_decode_symbolic($literals, $distances, $lengths);
}

#########################################
# LZB -- LZSS with byte-oriented encoding
#########################################

sub lzb_compress ($chunk, $lzss_encoding_sub = \&lzss_encode) {

    local $LZ_MAX_DIST = (1 << 16) - 1;
    local $LZ_MAX_LEN  = ~0;

    my ($literals, $distances, $lengths) = $lzss_encoding_sub->($chunk);

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
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2);
    }

    my $data               = '';
    my $search_window      = '';
    my $search_window_size = 1 << 16;

    my $block_size = fibonacci_decode($fh)->[0] // die "decompression error";

    read($fh, (my $block), $block_size) // die "Read error: $!";

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
        open my $fh2, '<:raw', \$fh;
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
          :                      die "Bad compressed k: $k";

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
        open my $fh2, '<:raw', \$fh;
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
            die "Incomplete Huffman tree not supported";
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
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2);
    }

    my $level = 1;

    # There is a CRC32 issue on some (binary) inputs, when using large chunk sizes
    ## my $CHUNK_SIZE = 100_000 * $level;
    my $CHUNK_SIZE = 1 << 16;

    my $compressed .= "BZh" . $level;

    state $block_header_bitstring = unpack("B48", "1AY&SY");
    state $block_footer_bitstring = unpack("B48", "\27rE8P\x90");

    my $bitstring    = '';
    my $stream_crc32 = 0;

    while (read($fh, (my $chunk), $CHUNK_SIZE)) {

        $bitstring .= $block_header_bitstring;

        # FIXME: there may be a bug in the computation of crc32
        my $crc32 = crc32(pack('b*', unpack('B*', $chunk)));
        $VERBOSE && say STDERR "CRC32: $crc32";

        $crc32 = oct('0b' . int2bits_lsb($crc32, 32));
        $VERBOSE && say STDERR "Bzip2-CRC32: $crc32";

        # FIXME: there may be a bug in the computation of stream_crc32
        $stream_crc32 = ($crc32 ^ (0xffffffff & (($stream_crc32 << 1) | ($stream_crc32 >> 31))));

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
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2);
    }

    state $MaxHuffmanBits = 20;
    my $decompressed = '';

    while (!eof($fh)) {

        my $buffer = '';

        (bytes2int($fh, 2) == 0x425a and getc($fh) eq 'h')
          or die "Not a valid Bzip2 archive";

        my $level = getc($fh);

        if ($level !~ /^[1-9]\z/) {
            die "Invalid level: $level";
        }

        $VERBOSE && say STDERR "Compression level: $level";

        my $stream_crc32 = 0;

        while (!eof($fh)) {

            my $block_magic = pack "B48", join('', map { read_bit($fh, \$buffer) } 1 .. 48);

            if ($block_magic eq "1AY&SY") {    # BlockHeader
                $VERBOSE && say STDERR "Block header detected";

                my $crc32 = bits2int($fh, 32, \$buffer);
                $VERBOSE && say STDERR "CRC32 = $crc32";

                $stream_crc32 = ($crc32 ^ (0xffffffff & (($stream_crc32 << 1) | ($stream_crc32 >> 31))));

                my $randomized = read_bit($fh, \$buffer);
                $randomized == 0 or die "randomized not supported";

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
                        ($i < $num_trees) or die "error";
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

                            ($clen > 0 and $clen <= $MaxHuffmanBits) or die "invalid code length: $clen";

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
                    $sum == 0 or die "incomplete tree not supported: (@$tree)";
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
                        die "[!] Something went wrong: length of code `$code` is > $MaxHuffmanBits.\n";
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
                                die "No more selectors";    # should not happen
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
                    die "CRC32 error: $crc32 (stored) != $new_crc32 (actual)";
                }

                $decompressed .= $dec;
            }
            elsif ($block_magic eq "\27rE8P\x90") {    # BlockFooter
                $VERBOSE && say STDERR "Block footer detected";
                my $stored_stream_crc32 = bits2int($fh, 32, \$buffer);
                $VERBOSE && say STDERR "Stream CRC: $stored_stream_crc32";

                if ($stored_stream_crc32 != $stream_crc32) {
                    die "Stream CRC32 error: $stored_stream_crc32 (stored) != $stream_crc32 (actual)";
                }

                $buffer = '';
                last;
            }
            else {
                die "Unknown block magic: $block_magic";
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

sub _create_block_type_2 ($literals, $distances, $lengths) {

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

sub _create_block_type_1 ($literals, $distances, $lengths) {

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

sub _create_block_type_0($chunk) {

    my $chunk_len = length($chunk);
    my $len       = int2bits_lsb($chunk_len,             16);
    my $nlen      = int2bits_lsb((~$chunk_len) & 0xffff, 16);

    $len . $nlen;
}

sub gzip_compress ($in_fh, $lzss_encoding_sub = \&lzss_encode) {

    if (ref($in_fh) eq '') {
        open my $fh2, '<:raw', \$in_fh;
        return __SUB__->($fh2);
    }

    my $compressed = '';

    open my $out_fh, '>:raw', \$compressed;

    local $Compression::Util::LZ_MIN_LEN       = 4;                # minimum match length in LZ parsing
    local $Compression::Util::LZ_MAX_LEN       = 258;              # maximum match length in LZ parsing
    local $Compression::Util::LZ_MAX_DIST      = (1 << 15) - 1;    # maximum allowed back-reference distance in LZ parsing
    local $Compression::Util::LZ_MAX_CHAIN_LEN = 64;               # how many recent positions to remember in LZ parsing

    state $MAGIC  = pack('C*', 0x1f, 0x8b);                        # magic MIME type
    state $CM     = chr(0x08);                                     # 0x08 = DEFLATE
    state $FLAGS  = chr(0x00);                                     # flags
    state $MTIME  = pack('C*', (0x00) x 4);                        # modification time
    state $XFLAGS = chr(0x00);                                     # extra flags
    state $OS     = chr(0x03);                                     # 0x03 = Unix

    print $out_fh $MAGIC, $CM, $FLAGS, $MTIME, $XFLAGS, $OS;

    my $total_length = 0;
    my $crc32        = 0;

    my $bitstring = '';

    if (eof($in_fh)) {                                             # empty file
        $bitstring = '1' . '10' . '0000000';
    }

    state $CHUNK_SIZE = (1 << 15) - 1;

    while (read($in_fh, (my $chunk), $CHUNK_SIZE)) {

        $crc32 = crc32($chunk, $crc32);
        $total_length += length($chunk);

        my ($literals, $distances, $lengths) = $lzss_encoding_sub->($chunk);

        $bitstring .= eof($in_fh) ? '1' : '0';

        my $bt1_bitstring = _create_block_type_1($literals, $distances, $lengths);

        # When block type 1 is larger than the input, then we have random uncompressible data: use block type 0
        if ((length($bt1_bitstring) >> 3) > length($chunk) + 5) {

            $VERBOSE && say STDERR ":: Using block type: 0";

            $bitstring .= '00';

            print $out_fh pack('b*', $bitstring);                     # pads to a byte
            print $out_fh pack('b*', _create_block_type_0($chunk));
            print $out_fh $chunk;

            $bitstring = '';
            next;
        }

        my $bt2_bitstring = _create_block_type_2($literals, $distances, $lengths);

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

    print $out_fh pack('b*', int2bits_lsb($crc32,        32));
    print $out_fh pack('b*', int2bits_lsb($total_length, 32));

    return $compressed;
}

###################
# GZIP DECOMPRESSOR
###################

sub _extract_block_type_0 ($in_fh, $buffer) {

    my $len           = bits2int_lsb($in_fh, 16, $buffer);
    my $nlen          = bits2int_lsb($in_fh, 16, $buffer);
    my $expected_nlen = (~$len) & 0xffff;

    if ($expected_nlen != $nlen) {
        die "[!] The ~length value is not correct: $nlen (actual) != $expected_nlen (expected)\n";
    }
    else {
        $VERBOSE && print STDERR ":: Chunk length: $len\n";
    }

    read($in_fh, (my $chunk), $len) // die "Read error: $!";
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
            die "[!] Something went wrong: length of LL code `$code` is > $max_ll_code_len.\n";
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
                        die "[!] Something went wrong: length of distance code `$dist_code` is > $max_dist_code_len.\n";
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
        die "[!] Something went wrong: code `$code` is not empty!\n";
    }

    return $data;
}

sub _extract_block_type_1 ($in_fh, $buffer, $search_window) {

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
            die "[!] Something went wrong: length of CL code `$code` is > 7.\n";
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
                die "Unknown CL symbol: $CL_symbol\n";
            }

            $code = '';
            last if (scalar(@lengths) >= $size);
        }
    }

    if (scalar(@lengths) != $size) {
        die "Something went wrong: size $size (expected) != ", scalar(@lengths);
    }

    if ($code ne '') {
        die "Something went wrong: code `$code` is not empty!";
    }

    return @lengths;
}

sub _extract_block_type_2 ($in_fh, $buffer, $search_window) {

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

sub gzip_decompress ($in_fh) {

    if (ref($in_fh) eq '') {
        open my $fh2, '<:raw', \$in_fh;
        return __SUB__->($fh2);
    }

    my $decompressed = '';

    open my $out_fh, '>:raw', \$decompressed;

    local $Compression::Util::LZ_MIN_LEN       = 4;                # minimum match length in LZ parsing
    local $Compression::Util::LZ_MAX_LEN       = 258;              # maximum match length in LZ parsing
    local $Compression::Util::LZ_MAX_DIST      = (1 << 15) - 1;    # maximum allowed back-reference distance in LZ parsing
    local $Compression::Util::LZ_MAX_CHAIN_LEN = 64;               # how many recent positions to remember in LZ parsing

    my $MAGIC = (getc($in_fh) // die "error") . (getc($in_fh) // die "error");

    if ($MAGIC ne pack('C*', 0x1f, 0x8b)) {
        die "Not a valid Gzip container!\n";
    }

    my $CM     = getc($in_fh) // die "error";                             # 0x08 = DEFLATE
    my $FLAGS  = getc($in_fh) // die "error";                             # flags
    my $MTIME  = join('', map { getc($in_fh) // die "error" } 1 .. 4);    # modification time
    my $XFLAGS = getc($in_fh) // die "error";                             # extra flags
    my $OS     = getc($in_fh) // die "error";                             # 0x03 = Unix

    if ($CM ne chr(0x08)) {
        die "Only DEFLATE compression method is supported (0x08)! Got: 0x", sprintf('%02x', ord($CM));
    }

    # TODO: add support for more attributes
    my $has_filename = 0;
    my $has_comment  = 0;

    if ((ord($FLAGS) & 0b0000_1000) != 0) {
        $has_filename = 1;
    }

    if ((ord($FLAGS) & 0b0001_0000) != 0) {
        $has_comment = 1;
    }

    if ($has_filename) {
        my $filename = read_null_terminated($in_fh);    # filename
        $VERBOSE && say STDERR ":: Filename: ", $filename;
    }

    if ($has_comment) {
        $VERBOSE && say STDERR ":: Comment: ", read_null_terminated($in_fh);
    }

    my $crc32         = 0;
    my $actual_length = 0;
    my $buffer        = '';
    my $search_window = '';
    my $window_size   = $Compression::Util::LZ_MAX_DIST;

    while (1) {

        my $is_last    = read_bit_lsb($in_fh, \$buffer);
        my $block_type = bits2int_lsb($in_fh, 2, \$buffer);

        my $chunk = '';

        if ($block_type == 0) {
            $VERBOSE && say STDERR "\n:: Extracting block of type 0";
            $buffer = '';                                        # pad to a byte
            $chunk  = _extract_block_type_0($in_fh, \$buffer);
            $search_window .= $chunk;
        }
        elsif ($block_type == 1) {
            $VERBOSE && say STDERR "\n:: Extracting block of type 1";
            $chunk = _extract_block_type_1($in_fh, \$buffer, \$search_window);
        }
        elsif ($block_type == 2) {
            $VERBOSE && say STDERR "\n:: Extracting block of type 2";
            $chunk = _extract_block_type_2($in_fh, \$buffer, \$search_window);
        }
        else {
            die "[!] Unknown block of type: $block_type";
        }

        print $out_fh $chunk;
        $crc32 = crc32($chunk, $crc32);
        $actual_length += length($chunk);
        $search_window = substr($search_window, -$window_size) if (length($search_window) > 2 * $window_size);

        last if $is_last;
    }

    $buffer = '';    # discard any padding bits

    my $stored_crc32 = bits2int_lsb($in_fh, 32, \$buffer);
    my $actual_crc32 = $crc32;

    if ($stored_crc32 != $actual_crc32) {
        die "[!] The CRC32 does not match: $actual_crc32 (actual) != $stored_crc32 (stored)\n";
    }
    else {
        $VERBOSE && print STDERR ":: CRC32 value: $actual_crc32\n";
    }

    my $stored_length = bits2int_lsb($in_fh, 32, \$buffer);

    if ($stored_length != $actual_length) {
        die "[!] The length does not match: $actual_length (actual) != $stored_length (stored)\n";
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

1;

__END__

=encoding utf-8

=head1 NAME

Compression::Util - Implementation of various techniques used in data compression.

=head1 SYNOPSIS

    use 5.036;
    use Getopt::Std       qw(getopts);
    use Compression::Util qw(:all);

    use constant {CHUNK_SIZE => 1 << 17};

    local $Compression::Util::VERBOSE = 0;

    getopts('d', \my %opts);

    sub compress ($fh, $out_fh) {
        while (read($fh, (my $chunk), CHUNK_SIZE)) {
            print $out_fh bwt_compress($chunk);
        }
    }

    sub decompress ($fh, $out_fh) {
        while (!eof($fh)) {
            print $out_fh bwt_decompress($fh);
        }
    }

    $opts{d} ? decompress(\*STDIN, \*STDOUT) : compress(\*STDIN, \*STDOUT);

=head1 DESCRIPTION

B<Compression::Util> is a function-based module, implementing various techniques used in data compression, such as:

    * Burrows-Wheeler transform
    * Move-to-front transform
    * Huffman Coding
    * Arithmetic Coding (in fixed bits)
    * Run-length encoding
    * Fibonacci coding
    * Elias gamma/omega coding
    * Delta coding
    * BWT-based compression
    * LZ77/LZSS compression
    * LZW compression
    * Bzip2 (de)compression
    * Gzip (de)compression

The provided techniques can be easily combined in various ways to create powerful compressors, such as the Bzip2 compressor, which is a pipeline of the following methods:

    1. Run-length encoding (RLE4)
    2. Burrows-Wheeler transform (BWT)
    3. Move-to-front transform (MTF)
    4. Zero run-length encoding (ZRLE)
    5. Huffman coding

A simple BWT-based compression method (similar to Bzip2) is provided by the function C<bwt_compress()>, which can be explicitly implemented as:

    use 5.036;
    use Compression::Util qw(:all);

    my $data = do { open my $fh, '<:raw', $^X; local $/; <$fh> };
    my $rle4 = rle4_encode(string2symbols($data));
    my ($bwt, $idx) = bwt_encode(symbols2string($rle4));

    my ($mtf, $alphabet) = mtf_encode(string2symbols($bwt));
    my $rle = zrle_encode($mtf);

    my $enc = pack('N', $idx)
            . encode_alphabet($alphabet)
            . create_huffman_entry($rle);

    say "Original size  : ", length($data);
    say "Compressed size: ", length($enc);

    # Decompress the result
    bwt_decompress($enc) eq $data or die "decompression error";

=head2 TERMINOLOGY

=head3 bit

A bit value is either C<1> or C<0>.

=head3 bitstring

A bitstring is a string containing only 1s and 0s.

=head3 byte

A byte value is an integer between C<0> and C<255>, inclusive.

=head3 string

A string means a binary (non-UTF*) string.

=head3 symbols

An array of symbols means an array of non-negative integer values.

=head3 filehandle

A filehandle is denoted by C<$fh>.

The encoding of file-handles must be set to C<:raw>.

=head1 PACKAGE VARIABLES

B<Compression::Util> provides the following package variables:

    $Compression::Util::VERBOSE = 0;           # true to enable verbose/debug mode

    $Compression::Util::LZ_MIN_LEN = 4;        # minimum match length in LZ parsing
    $Compression::Util::LZ_MAX_LEN = 1 << 15;  # maximum match length in LZ parsing

    $Compression::Util::LZ_MAX_DIST = ~0;      # maximum back-reference distance allowed
    $Compression::Util::LZ_MAX_CHAIN_LEN = 32; # how many recent positions to remember for each match in LZ parsing

These package variables can also be imported as:

    use Compression::Util qw(
        $LZ_MIN_LEN
        $LZ_MAX_LEN
        $LZ_MAX_DIST
        $LZ_MAX_CHAIN_LEN
    );

=head2 $LZ_MIN_LEN

Minimum length of a match in LZ parsing. The value must be an integer greater than or equal to C<2>. Larger values will result in faster parsing, but lower compression ratio.

By default, C<$LZ_MIN_LEN> is set to C<4>.

B<NOTE:> for C<lzss_encode_fast()> is recommended to set C<$LZ_MIN_LEN = 5>, which will result in slightly better compression ratio.

=head2 $LZ_MAX_LEN

Maximum length of a match in LZ parsing. The value must be an integer greater than or equal to C<0>.

By default, C<$LZ_MAX_LEN> is set to C<32768>.

B<NOTE:> the functions C<lz77_encode()> and C<lzb_compress()> will ignore this value and will always use unlimited match lengths.

=head2 $LZ_MAX_DIST

Maximum back-reference distance allowed in LZ parsing. Smaller values will result in faster parsing, but lower compression ratio.

By default, the value is unlimited, meaning that arbitrarily large back-references will be generated.

B<NOTE:> the function C<lzb_compress()> will ignore this value and will always use the value C<2**16 - 1> as the maximum back-reference distance.

=head2 $LZ_MAX_CHAIN_LEN

The value of C<$LZ_MAX_CHAIN_LEN> controls the amount of recent positions to remember for each matched prefix. A larger value results in better compression, finding longer matches, at the expense of speed.

By default, C<$LZ_MAX_CHAIN_LEN> is set to C<32>.

B<NOTE:> the function C<lzss_encode_fast()> will ignore this value, always using a value of C<1>.

=head1 HIGH-LEVEL FUNCTIONS

      create_huffman_entry(\@symbols)      # Create a Huffman Coding block
      decode_huffman_entry($fh)            # Decode a Huffman Coding block

      create_ac_entry(\@symbols)           # Create an Arithmetic Coding block
      decode_ac_entry($fh)                 # Decode an Arithmetic Coding block

      create_adaptive_ac_entry(\@symbols)  # Create an Adaptive Arithmetic Coding block
      decode_adaptive_ac_entry($fh)        # Decode an Adaptive Arithmetic Coding block

      mrl_compress($string)                # MRL compression (MTF+ZRLE+RLE4+Huffman coding)
      mrl_decompress($fh)                  # Inverse of the above method

      mrl_compress_symbolic(\@symbols)     # Symbolic MRL compression (MTF+ZRLE+RLE4+Huffman coding)
      mrl_decompress_symbolic($fh)         # Inverse of the above method

      bwt_compress($string)                # BWT-based compression (RLE4+BWT+MTF+ZRLE+Huffman coding)
      bwt_decompress($fh)                  # Inverse of the above method

      bwt_compress_symbolic(\@symbols)     # Symbolic BWT-based compression (RLE4+sBWT+MTF+ZRLE+Huffman coding)
      bwt_decompress_symbolic($fh)         # Inverse of the above method

      bzip2_compress($string)              # Compress a given string using the Bzip2 format
      bzip2_decompress($fh)                # Inverse of the above method

      gzip_compress($string)               # Compress a given string using the Gzip format
      gzip_decompress($fh)                 # Inverse of the above method

      lzss_compress($string)               # LZSS + DEFLATE-like encoding of lengths and distances
      lzss_decompress($fh)                 # Inverse of the above method

      lzss_compress_symbolic(\@symbols)    # Symbolic LZSS + DEFLATE-like encoding of lengths and distances
      lzss_decompress_symbolic($fh)        # Inverse of the above method

      lz77_compress($string)               # LZ77 + Huffman coding of lengths and literals + OBH for distances
      lz77_decompress($fh)                 # Inverse of the above method

      lz77_compress_symbolic(\@symbols)    # Symbolic LZ77 + Huffman coding of lengths and literals + OBH for distances
      lz77_decompress_symbolic($fh)        # Inverse of the above method

      lzb_compress($string)                # LZSS compression, using a byte-aligned encoding method, similar to LZ4
      lzb_decompress($fh)                  # Inverse of the above method

      lzw_compress($string)                # LZW + abc_encode() compression
      lzw_decompress($fh)                  # Inverse of the above method

=head1 MEDIUM-LEVEL FUNCTIONS

      deltas(\@ints)                       # Computes the differences between integers
      accumulate(\@deltas)                 # Inverse of the above method

      delta_encode(\@ints)                 # Delta+RLE encoding of an array-ref of integers
      delta_decode($fh)                    # Inverse of the above method

      fibonacci_encode(\@symbols)          # Fibonacci coding of an array-ref of symbols
      fibonacci_decode($fh)                # Inverse of the above method

      elias_gamma_encode(\@symbols)        # Elias Gamma coding method of an array-ref of symbols
      elias_gamma_decode($fh)              # Inverse of the above method

      elias_omega_encode(\@symbols)        # Elias Omega coding method of an array-ref of symbols
      elias_omega_decode($fh)              # Inverse of the above method

      abc_encode(\@symbols)                # Adaptive Binary Concatenation method of an array-ref of symbols
      abc_decode($fh)                      # Inverse of the above method

      obh_encode(\@symbols)                # Offset bits + Huffman coding of an array-ref of symbols
      obh_decode($fh)                      # Inverse of the above method

      bwt_encode($string)                  # Burrows-Wheeler transform
      bwt_decode($bwt, $idx)               # Inverse of Burrows-Wheeler transform

      bwt_encode_symbolic(\@symbols)       # Burrows-Wheeler transform over an array-ref of symbols
      bwt_decode_symbolic(\@bwt, $idx)     # Inverse of symbolic Burrows-Wheeler transform

      mtf_encode(\@symbols)                # Move-to-front transform
      mtf_decode(\@mtf, \@alphabet)        # Inverse of the above method

      encode_alphabet(\@alphabet)          # Encode an alphabet of symbols into a binary string
      decode_alphabet($fh)                 # Inverse of the above method

      encode_alphabet_256(\@alphabet)      # Encode an alphabet of symbols (limited to [0..255]) into a binary string
      decode_alphabet_256($fh)             # Inverse of the above method

      frequencies(\@symbols)               # Returns a dictionary with symbol frequencies
      run_length(\@symbols, $max=undef)    # Run-length encoding, returning a 2D array-ref

      rle4_encode(\@symbols, $max=255)     # Run-length encoding with 4 or more consecutive characters
      rle4_decode(\@rle4)                  # Inverse of the above method

      zrle_encode(\@symbols)               # Run-length encoding of zeros
      zrle_decode(\@zrle)                  # Inverse of the above method

      ac_encode(\@symbols)                 # Arithmetic Coding applied on an array-ref of symbols
      ac_decode($bitstring, \%freq)        # Inverse of the above method

      adaptive_ac_encode(\@symbols)               # Adaptive Arithmetic Coding applied on an array-ref of symbols
      adaptive_ac_decode($bitstring, \@alphabet)  # Inverse of the above method

      lzw_encode($string)                  # LZW encoding of a given string
      lzw_decode(\@symbols)                # Inverse of the above method

=head1 LOW-LEVEL FUNCTIONS

      crc32($string, $prev_crc = 0)        # Compute the CRC32 value of a given string

      read_bit($fh, \$buffer)              # Read one bit from file-handle (MSB)
      read_bit_lsb($fh, \$buffer)          # Read one bit from file-handle (LSB)

      read_bits($fh, $len)                 # Read `$len` bits from file-handle (MSB)
      read_bits_lsb($fh, $len)             # Read `$len` bits from file-handle (LSB)

      int2bits($symbol, $size)             # Convert an integer to bits of width `$size` (MSB)
      int2bits_lsb($symbol, $size)         # Convert an integer to bits of width `$size` (LSB)

      bits2int($fh, $size, \$buffer)       # Inverse of `int2bits()`
      bits2int_lsb($fh, $size, \$buffer)   # Inverse of `int2bits_lsb()`

      bytes2int($fh, $n)                   # Read `$n` bytes from file-handle as an integer (MSB)
      bytes2int_lsb($fh, $n)               # Read `$n` bytes from file-handle as an integer (LSB)

      int2bytes($symbol, $size)            # Convert an integer into `$size` bytes. (MSB)
      int2bytes_lsb($symbol, $size)        # Convert an integer into `$size` bytes. (LSB)

      string2symbols($string)              # Returns an array-ref of code points
      symbols2string(\@symbols)            # Returns a string, given an array-ref of code points

      read_null_terminated($fh)            # Read a binary string that ends with NULL ("\0")

      binary_vrl_encode($bitstring)        # Binary variable run-length encoding
      binary_vrl_decode($bitstring)        # Binary variable run-length decoding

      bwt_sort($string)                    # Burrows-Wheeler sorting
      bwt_sort_symbolic(\@symbols)         # Burrows-Wheeler sorting, applied on an array-ref of symbols

      huffman_encode(\@symbols, \%dict)    # Huffman encoding
      huffman_decode($bitstring, \%dict)   # Huffman decoding, given a string of bits

      huffman_from_freq(\%freq)            # Create Huffman dictionaries, given an hash-ref of frequencies
      huffman_from_symbols(\@symbols)      # Create Huffman dictionaries, given an array-ref of symbols
      huffman_from_code_lengths(\@lens)    # Create canonical Huffman codes, given an array-ref of code lengths

      make_deflate_tables($max_dist, $max_len) # Returns the DEFLATE tables for distance and length symbols
      find_deflate_index($value, \@table)      # Returns the index in a DEFLATE table, given a numerical value

      lzss_encode($string)                     # LZSS encoding into literals, distances and lengths
      lzss_encode_symbolic(\@symbols)          # LZSS encoding into literals, distances and lengths (symbolic)

      lzss_encode_fast($string)                # Fast-LZSS encoding into literals, distances and lengths
      lzss_encode_fast_symbolic(\@symbols)     # Fast-LZSS encoding into literals, distances and lengths (symbolic)

      lzss_decode(\@lits, \@dist, \@lens)          # Inverse of lzss_encode() and lzss_encode_fast()
      lzss_decode_symbolic(\@lits, \@dist, \@lens) # Inverse of lzss_encode_symbolic() and lzss_encode_fast_symbolic()

      lz77_encode($string)                         # LZ77 encoding into literals, distances, lengths and matches
      lz77_encode_symbolic(\@symbols)              # LZ77 encoding into literals, distances, lengths and matches (symbolic)

      lz77_decode(\@lits, \@dist, \@lens, \@matches)           # Inverse of lz77_encode()
      lz77_decode_symbolic(\@lits, \@dist, \@lens, \@matches)  # Inverse of lz77_encode_symbolic()

      deflate_encode(\@lits, \@dist, \@lens)   # DEFLATE-like encoding of values returned by lzss_encode()
      deflate_decode($fh)                      # Inverse of the above method

=head1 INTERFACE FOR HIGH-LEVEL FUNCTIONS

=head2 create_huffman_entry

    my $string = create_huffman_entry(\@symbols);

High-level function that generates a Huffman coding block, given an array-ref of symbols.

=head2 decode_huffman_entry

    my $symbols = decode_huffman_entry($fh);
    my $symbols = decode_huffman_entry($string);

Inverse of C<create_huffman_entry()>.

=head2 create_ac_entry

    my $string = create_ac_entry(\@symbols);

High-level function that generates an Arithmetic Coding block, given an array-ref of symbols.

=head2 decode_ac_entry

    my $symbols = decode_ac_entry($fh);
    my $symbols = decode_ac_entry($string);

Inverse of C<create_ac_entry()>.

=head2 create_adaptive_ac_entry

    my $string = create_adaptive_ac_entry(\@symbols);

High-level function that generates an Adaptive Arithmetic Coding block, given an array-ref of symbols.

=head2 decode_adaptive_ac_entry

    my $symbols = decode_adaptive_ac_entry($fh);
    my $symbols = decode_adaptive_ac_entry($string);

Inverse of C<create_adaptive_ac_entry()>.

=head2 lz77_compress / lz77_compress_symbolic

    # With Huffman coding
    my $string = lz77_compress($data);
    my $string = lz77_compress(\@symbols);

    # With Arithmetic Coding
    my $string = lz77_compress($data, \&create_ac_entry);

    # Using Fast-LZSS parsing + Huffman coding
    my $string = lz77_compress($data, \&create_huffman_entry, \&lzss_encode_fast);

High-level function that performs LZ77 compression on the provided data, using the pipeline:

    1. lz77_encode
    2. create_huffman_entry(literals)
    3. create_huffman_entry(lengths)
    4. create_huffman_entry(matches)
    5. obh_encode(distances)

The function accepts either a string or an array-ref of symbols as the first argument.

=head2 lz77_decompress / lz77_decompress_symbolic

    # With Huffman coding
    my $data = lz77_decompress($fh);
    my $data = lz77_decompress($string);

    # With Arithemtic coding
    my $data = lz77_decompress($fh, \&decode_ac_entry);
    my $data = lz77_decompress($string, \&decode_ac_entry);

    # Symbolic, with Huffman coding
    my $symbols = lz77_decompress_symbolic($fh);
    my $symbols = lz77_decompress_symbolic($string);

Inverse of C<lz77_compress()> and C<lz77_compress_symbolic()>, respectively.

=head2 lzss_compress / lzss_compress_symbolic

    # With Huffman coding
    my $string = lzss_compress($data);
    my $string = lzss_compress(\@symbols);

    # With Arithmetic Coding
    my $string = lzss_compress($data, \&create_ac_entry);

    # Using Fast-LZSS parsing + Huffman coding
    my $string = lzss_compress($data, \&create_huffman_entry, \&lzss_encode_fast);

High-level function that performs LZSS (Lempel-Ziv-Storer-Szymanski) compression on the provided data, using the pipeline:

    1. lzss_encode
    2. deflate_encode

The function accepts either a string or an array-ref of symbols as the first argument.

=head2 lzss_decompress / lzss_decompress_symbolic

    # With Huffman coding
    my $data = lzss_decompress($fh);
    my $data = lzss_decompress($string);

    # With Arithmetic coding
    my $data = lzss_decompress($fh, \&decode_ac_entry);
    my $data = lzss_decompress($string, \&decode_ac_entry);

    # Symbolic, with Huffman coding
    my $symbols = lzss_decompress_symbolic($fh);
    my $symbols = lzss_decompress_symbolic($string);

Inverse of C<lzss_compress()> and C<lzss_compress_symbolic()>, respectively.

=head2 lzb_compress

    my $string = lzb_compress($data);
    my $string = lzb_compress($data, \&lzss_encode_fast);   # with fast-LZ parsing

High-level function that performs byte-oriented LZSS compression, inspired by LZ4.

=head2 lzb_decompress

    my $data = lzb_decompress($fh);
    my $data = lzb_decompress($string);

Inverse of C<lzb_compress()>.

=head2 lzw_compress

    my $string = lzw_compress($data);

High-level function that performs LZW (Lempel-Ziv-Welch) compression on the provided data, using the pipeline:

    1. lzw_encode
    2. abc_encode

=head2 lzw_decompress

    my $data = lzw_decompress($fh);
    my $data = lzw_decompress($string);

Performs Lempel-Ziv-Welch (LZW) decompression on the provided string or file-handle. Inverse of C<lzw_compress()>.

=head2 bwt_compress

    # Using Huffman Coding
    my $string = bwt_compress($data);

    # Using Arithmetic Coding
    my $string = bwt_compress($data, \&create_ac_entry);

High-level function that performs BWT-based compression on the provided data, using the pipeline:

    1. rle4_encode
    2. bwt_encode
    3. mtf_encode
    4. zrle_encode
    5. create_huffman_entry

=head2 bwt_decompress

    # With Huffman coding
    my $data = bwt_decompress($fh);
    my $data = bwt_decompress($string);

    # With Arithmetic coding
    my $data = bwt_decompress($fh, \&decode_ac_entry);
    my $data = bwt_decompress($string, \&decode_ac_entry);

Inverse of C<bwt_compress()>.

=head2 bwt_compress_symbolic

    # Does Huffman coding
    my $string = bwt_compress_symbolic(\@symbols);

    # Does Arithmetic coding
    my $string = bwt_compress_symbolic(\@symbols, \&create_ac_entry);

Similar to C<bwt_compress()>, except that it accepts an arbitrary array-ref of non-negative integer values as input. It is also a bit slower on large inputs.

=head2 bwt_decompress_symbolic

    # Using Huffman coding
    my $symbols = bwt_decompress_symbolic($fh);
    my $symbols = bwt_decompress_symbolic($string);

    # Using Arithmetic coding
    my $symbols = bwt_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = bwt_decompress_symbolic($string, \&decode_ac_entry);

Inverse of C<bwt_compress_symbolic()>.

=head2 bzip2_compress

    my $string = bzip2_compress($data);
    my $string = bzip2_compress($fh);

Valid Bzip2 compressor, given a string or an input file-handle.

=head2 bzip2_decompress

    my $data = bzip2_decompress($string);
    my $data = bzip2_decompress($fh);

Valid Bzip2 decompressor, given a string or an input file-handle.

=head2 gzip_compress

    my $string = gzip_compress($fh);
    my $string = gzip_compress($data);
    my $string = gzip_compress($data, \&lzss_encode_fast);  # using fast LZ-parsing

Valid Gzip compressor, given a string or an input file-handle.

=head2 gzip_decompress

    my $data = gzip_decompress($string);
    my $data = gzip_decompress($fh);

Valid Bzip2 decompressor, given a string or an input file-handle.

=head2 mrl_compress / mrl_compress_symbolic

    # Does Huffman coding
    my $enc = mrl_compress($str);
    my $enc = mrl_compress(\@symbols);

    # Does Arithmetic coding
    my $enc = mrl_compress($str, \&create_ac_entry);
    my $enc = mrl_compress(\@symbols, \&create_ac_entry);

A fast compression method, using the following pipeline:

    1. mtf_encode
    2. zrle_encode
    3. rle4_encode
    4. create_huffman_entry

It accepts an arbitrary array-ref of non-negative integer values as input.

=head2 mrl_decompress / mrl_decompress_symbolic

    # With Huffman coding
    my $data = mrl_decompress($fh);
    my $data = mrl_decompress($string);

    # Symbolic, with Huffman coding
    my $symbols = mrl_decompress_symbolic($fh);
    my $symbols = mrl_decompress_symbolic($string);

    # Symbolic, with Arithmetic coding
    my $symbols = mrl_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = mrl_decompress_symbolic($string, \&decode_ac_entry);

Inverse of C<mrl_decompress()> and C<mrl_compress_symbolic()>.

=head1 INTERFACE FOR MEDIUM-LEVEL FUNCTIONS

=head2 frequencies

    my $freq = frequencies(\@symbols);

Returns an hash ref dictionary with frequencies, given an array-ref of symbols.

=head2 deltas

    my $deltas = deltas(\@integers);

Computes the differences between consecutive integers, returning an array.

=head2 accumulate

    my $integers = accumulate(\@deltas);

Inverse of C<deltas()>.

=head2 delta_encode

    my $string = delta_encode(\@integers);

Encodes a sequence of integers (including negative integers) using Delta + Run-length + Elias omega coding, returning a binary string.

Delta encoding calculates the difference between consecutive integers in the sequence and encodes these differences using Elias omega coding. When it's beneficial, runs of identical symbols are collapsed with RLE.

This method supports both positive and negative integers.

=head2 delta_decode

    # Given a file-handle
    my $integers = delta_decode($fh);

    # Given a string
    my $integers = delta_decode($string);

Inverse of C<delta_encode()>.

=head2 fibonacci_encode

    my $string = fibonacci_encode(\@symbols);

Encodes a sequence of non-negative integers using Fibonacci coding, returning a binary string.

=head2 fibonacci_decode

    # Given a file-handle
    my $symbols = fibonacci_decode($fh);

    # Given a binary string
    my $symbols = fibonacci_decode($string);

Inverse of C<fibonacci_encode()>.

=head2 elias_gamma_encode

    my $string = elias_gamma_encode(\@symbols);

Encodes a sequence of non-negative integers using Elias Gamma coding, returning a binary string.

=head2 elias_gamma_decode

    # Given a file-handle
    my $symbols = elias_gamma_decode($fh);

    # Given a binary string
    my $symbols = elias_gamma_decode($string);

Inverse of C<elias_gamma_encode()>.

=head2 elias_omega_encode

    my $string = elias_omega_encode(\@symbols);

Encodes a sequence of non-negative integers using Elias Omega coding, returning a binary string.

=head2 elias_omega_decode

    # Given a file-handle
    my $symbols = elias_omega_decode($fh);

    # Given a binary string
    my $symbols = elias_omega_decode($string);

Inverse of C<elias_omega_encode()>.

=head2 abc_encode

    my $string = abc_encode(\@symbols);

Encodes a sequence of non-negative integers using the Adaptive Binary Concatenation encoding method.

This method is particularly effective in encoding a sequence of integers that are in ascending order or have roughly the same size in binary.

=head2 abc_decode

    # Given a file-handle
    my $symbols = abc_decode($fh);

    # Given a binary string
    my $symbols = abc_decode($string);

Inverse of C<abc_encode()>.

=head2 obh_encode

    # With Huffman Coding
    my $string = obh_encode(\@symbols);

    # With Arithmetic Coding
    my $string = obh_encode(\@symbols, \&create_ac_entry);

Encodes a sequence of non-negative integers using offset bits and Huffman coding.

This method is particularly effective in encoding a sequence of moderately large random integers, such as the list of distances returned by C<lzss_encode()>.

=head2 obh_decode

    # Given a file-handle
    my $symbols = obh_decode($fh);                        # Huffman decoding
    my $symbols = obh_decode($fh, \&decode_ac_entry);     # Arithmetic decoding

    # Given a binary string
    my $symbols = obh_decode($string);                    # Huffman decoding
    my $symbols = obh_decode($string, \&decode_ac_entry); # Arithmetic decoding

Inverse of C<obh_encode()>.

=head2 bwt_encode

    my ($bwt, $idx) = bwt_encode($string);
    my ($bwt, $idx) = bwt_encode($string, $lookahead_len);

Applies the Burrows-Wheeler Transform (BWT) to a given string.

=head2 bwt_decode

    my $string = bwt_decode($bwt, $idx);

Reverses the Burrows-Wheeler Transform (BWT) applied to a string.

The function returns the original string.

=head2 bwt_encode_symbolic

    my ($bwt_symbols, $idx) = bwt_encode_symbolic(\@symbols);

Applies the Burrows-Wheeler Transform (BWT) to a sequence of symbolic elements.

=head2 bwt_decode_symbolic

    my $symbols = bwt_decode_symbolic(\@bwt_symbols, $idx);

Reverses the Burrows-Wheeler Transform (BWT) applied to a sequence of symbolic elements.

=head2 mtf_encode

    my $mtf = mtf_encode(\@symbols, \@alphabet);
    my ($mtf, $alphabet) = mtf_encode(\@symbols);

Performs Move-To-Front (MTF) encoding on a sequence of symbols.

The function returns the encoded MTF sequence and the sorted list of unique symbols in the input data, representing the alphabet.

Optionally, the alphabet can be provided as a second argument. When two arguments are provided, only the MTF sequence is returned.

=head2 mtf_decode

    my $symbols = mtf_decode(\@mtf, \@alphabet);

Inverse of C<mtf_encode()>.

=head2 encode_alphabet / encode_alphabet_256

    my $string = encode_alphabet(\@alphabet);        # supports arbitrarily large symbols
    my $string = encode_alphabet_256(\@alphabet);    # limited to symbols [0..255]

Encode a sorted alphabet of symbols into a binary string.

=head2 decode_alphabet / decode_alphabet_256

    my $alphabet = decode_alphabet($fh);
    my $alphabet = decode_alphabet($string);

    my $alphabet = decode_alphabet_256($fh);
    my $alphabet = decode_alphabet_256($string);

Decodes an encoded alphabet, given a file-handle or a binary string, returning an array-ref of symbols. Inverse of C<encode_alphabet()>.

=head2 run_length

    my $rl = run_length(\@symbols);
    my $rl = run_length(\@symbols, $max_run);

Performs Run-Length Encoding (RLE) on a sequence of symbolic elements.

It takes two parameters: C<\@symbols>, representing an array of symbols, and C<$max_run>, indicating the maximum run length allowed.

The function returns a 2D-array, with pairs: C<[symbol, run_length]>, such that the following code reconstructs the C<\@symbols> array:

    my @symbols = map { ($_->[0]) x $_->[1] } @$rl;

By default, the maximum run-length is unlimited.

=head2 rle4_encode

    my $rle4 = rle4_encode($string);
    my $rle4 = rle4_encode(\@symbols);
    my $rle4 = rle4_encode(\@symbols, $max_run);

Performs Run-Length Encoding (RLE) on a sequence of symbolic elements, specifically designed for runs of four or more consecutive symbols.

It takes two parameters: C<\@symbols>, representing an array of symbols, and C<$max_run>, indicating the maximum run length allowed during encoding.

The function returns the encoded RLE sequence as an array-ref of symbols.

By default, the maximum run-length is limited to C<255>.

=head2 rle4_decode

    my $symbols = rle4_decode(\@rle4);
    my $symbols = rle4_decode($rle4_string);

Inverse of C<rle4_encode()>.

=head2 zrle_encode

    my $zrle = zrle_encode(\@symbols);

Performs Zero-Run-Length Encoding (ZRLE) on a sequence of symbolic elements, returning the encoded ZRLE sequence as an array-ref of symbols.

This function efficiently encodes runs of zeros, but also increments each symbol by C<1>.

=head2 zrle_decode

    my $symbols = zrle_decode($zrle);

Inverse of C<zrle_encode()>.

=head2 ac_encode

    my ($bitstring, $freq) = ac_encode(\@symbols);

Performs Arithmetic Coding on the provided symbols.

It takes a single parameter, C<\@symbols>, representing the symbols to be encoded.

The function returns two values: C<$bitstring>, which is a string of 1s and 0s, and C<$freq>, representing the frequency table used for encoding.

=head2 ac_decode

    my $symbols = ac_decode($bits_fh, \%freq);
    my $symbols = ac_decode($bitstring, \%freq);

Performs Arithmetic Coding decoding using the provided frequency table and a string of 1s and 0s. Inverse of C<ac_encode()>.

It takes two parameters: C<$bitstring>, representing a string of 1s and 0s containing the arithmetic coded data, and C<\%freq>, representing the frequency table used for encoding.

The function returns the decoded sequence of symbols.

=head2 adaptive_ac_encode

    my ($bitstring, $alphabet) = adaptive_ac_encode(\@symbols);

Performs Adaptive Arithmetic Coding on the provided symbols.

It takes a single parameter, C<\@symbols>, representing the symbols to be encoded.

The function returns two values: C<$bitstring>, which is a string of 1s and 0s, and C<$alphabet>, which is an array-ref of distinct sorted symbols.

=head2 adaptive_ac_decode

    my $symbols = adaptive_ac_decode($bits_fh, \@alphabet);
    my $symbols = adaptive_ac_decode($bitstring, \@alphabet);

Performs Adaptive Arithmetic Coding decoding using the provided frequency table and a string of 1s and 0s.

It takes two parameters: C<$bitstring>, representing a string of 1s and 0s containing the adaptive arithmetic coded data, and C<\@alphabet>, representing the array of distinct sorted symbols that appear in the encoded data.

The function returns the decoded sequence of symbols.

=head2 lzw_encode

    my $symbols = lzw_encode($string);

Performs Lempel-Ziv-Welch (LZW) encoding on the provided string.

It takes a single parameter, C<$string>, representing the data to be encoded.

The function returns an array-ref of symbols.

=head2 lzw_decode

    my $string = lzw_decode(\@symbols);

Performs Lempel-Ziv-Welch (LZW) decoding on the provided symbols. Inverse of C<lzw_encode()>.

The function returns the decoded string.

=head1 INTERFACE FOR LOW-LEVEL FUNCTIONS

=head2 crc32

    my $int32 = crc32($data);
    my $int32 = crc32($data, $prev_crc32);

Compute the CRC32 of a given string.

=head2 read_bit

    my $bit = read_bit($fh, \$buffer);

Reads a single bit from a file-handle C<$fh> (MSB order).

The function stores the extra bits inside the C<$buffer>, reading one character at a time from the file-handle.

=head2 read_bit_lsb

    my $bit = read_bit_lsb($fh, \$buffer);

Reads a single bit from a file-handle C<$fh> (LSB order).

The function stores the extra bits inside the C<$buffer>, reading one character at a time from the file-handle.

=head2 read_bits

    my $bitstring = read_bits($fh, $bits_len);

Reads a specified number of bits (C<$bits_len>) from a file-handle (C<$fh>) and returns them as a string, in MSB order.

=head2 read_bits_lsb

    my $bitstring = read_bits_lsb($fh, $bits_len);

Reads a specified number of bits (C<$bits_len>) from a file-handle (C<$fh>) and returns them as a string, in LSB order.

=head2 int2bits

    my $bitstring = int2bits($symbol, $size)

Convert a non-negative integer to a bitstring of width C<$size>, in MSB order.

=head2 int2bits_lsb

    my $bitstring = int2bits_lsb($symbol, $size)

Convert a non-negative integer to a bitstring of width C<$size>, in LSB order.

=head2 int2bytes

    my $string = int2bytes($symbol, $size);

Convert a non-negative integer to a byte-string of width C<$size>, in MSB order.

=head2 int2bytes_lsb

    my $string = int2bytes_lsb($symbol, $size);

Convert a non-negative integer to a byte-string of width C<$size>, in LSB order.

=head2 bits2int

    my $integer = bits2int($fh, $size, \$buffer);

Read C<$size> bits from a file-handle C<$fh> and convert them to an integer, in MSB order. Inverse of C<int2bits()>.

The function stores the extra bits inside the C<$buffer>, reading one character at a time from the file-handle.

=head2 bits2int_lsb

    my $integer = bits2int_lsb($fh, $size, \$buffer);

Read C<$size> bits from a file-handle C<$fh> and convert them to an integer, in LSB order. Inverse of C<int2bits_lsb()>.

The function stores the extra bits inside the C<$buffer>, reading one character at a time from the file-handle.

=head2 bytes2int

    my $integer = bytes2int($fh, $n);
    my $integer = bytes2int($str, $n);

Read C<$n> bytes from a file-handle C<$fh> or from a string C<$str> and convert them to an integer, in MSB order.

=head2 bytes2int_lsb

    my $integer = bytes2int_lsb($fh, $n);
    my $integer = bytes2int_lsb($str, $n);

Read C<$n> bytes from a file-handle C<$fh> or from a string C<$str> and convert them to an integer, in LSB order.

=head2 string2symbols

    my $symbols = string2symbols($string)

Returns an array-ref of code points, given a string.

=head2 symbols2string

    my $string = symbols2string(\@symbols)

Returns a string, given an array-ref of code points.

=head2 read_null_terminated

    my $string = read_null_terminated($fh)

Read a string from file-handle C<$fh> that ends with a NULL character ("\0").

=head2 binary_vrl_encode

    my $bitstring_enc = binary_vrl_encode($bitstring);

Given a string of 1s and 0s, returns back a bitstring of 1s and 0s encoded using variable run-length encoding.

=head2 binary_vrl_decode

    my $bitstring = binary_vrl_decode($bitstring_enc);

Given an encoded bitstring, returned by C<binary_vrl_encode()>, gives back the decoded string of 1s and 0s.

=head2 bwt_sort

    my $indices = bwt_sort($string);
    my $indices = bwt_sort($string, $lookahead_len);

Low-level function that sorts the rotations of a given string using the Burrows-Wheeler Transform (BWT) algorithm.

It takes two parameters: C<$string>, which is the input string to be transformed, and C<$LOOKAHEAD_LEN> (optional), representing the length of look-ahead during sorting.

The function returns an array-ref of indices.

There is probably no need to call this function explicitly. Use C<bwt_encode()> instead!

=head2 bwt_sort_symbolic

    my $indices = bwt_sort_symbolic(\@symbols);

Low-level function that sorts the rotations of a sequence of symbolic elements using the Burrows-Wheeler Transform (BWT) algorithm.

It takes a single parameter C<\@symbols>, which represents the input sequence of symbolic elements. The function returns an array of indices.

There is probably no need to call this function explicitly. Use C<bwt_encode_symbolic()> instead!

=head2 huffman_from_freq

    my $dict = huffman_from_freq(\%freq);
    my ($dict, $rev_dict) = huffman_from_freq(\%freq);

Low-level function that constructs Huffman prefix codes, based on the frequency of symbols provided in a hash table.

It takes a single parameter, C<\%freq>, representing the hash table where keys are symbols, and values are their corresponding frequencies.

The function returns two values: C<$dict>, which is the mapping of symbols to Huffman codes, and C<$rev_dict>, which holds the reverse mapping of Huffman codes to symbols.

The prefix codes are in canonical form, as defined in RFC 1951 (Section 3.2.2).

=head2 huffman_from_symbols

    my $dict = huffman_from_symbols(\@symbols);
    my ($dict, $rev_dict) = huffman_from_symbols(\@symbols);

Low-level function that constructs Huffman prefix codes, given an array-ref of symbols.

It takes a single parameter, C<\@symbols>, from which it computes the frequency of each symbol and generates the corresponding Huffman prefix codes.

The function returns two values: C<$dict>, which is the mapping of symbols to Huffman codes, and C<$rev_dict>, which holds the reverse mapping of Huffman codes to symbols.

The prefix codes are in canonical form, as defined in RFC 1951 (Section 3.2.2).

=head2 huffman_from_code_lengths

    my $dict = huffman_from_code_lengths(\@code_lengths);
    my ($dict, $rev_dict) = huffman_from_code_lengths(\@code_lengths);

Low-level function that constructs a dictionary of canonical prefix codes, given an array of code lengths, as defined in RFC 1951 (Section 3.2.2).

It takes a single parameter, C<\@code_lengths>, where entry C<$i> in the array corresponds to the code length for symbol C<$i>.

The function returns two values: C<$dict>, which is the mapping of symbols to Huffman codes, and C<$rev_dict>, which holds the reverse mapping of Huffman codes to symbols.

=head2 huffman_encode

    my $bitstring = huffman_encode(\@symbols, $dict);

Low-level function that performs Huffman encoding on a sequence of symbols using a provided dictionary, returned by C<huffman_from_freq()>.

It takes two parameters: C<\@symbols>, representing the sequence of symbols to be encoded, and C<$dict>, representing the Huffman dictionary mapping symbols to their corresponding Huffman codes.

The function returns a concatenated string of 1s and 0s, representing the Huffman-encoded sequence of symbols.

=head2 huffman_decode

    my $symbols = huffman_decode($bitstring, $rev_dict);

Low-level function that decodes a Huffman-encoded binary string into a sequence of symbols using a provided reverse dictionary.

It takes two parameters: C<$bitstring>, representing the Huffman-encoded string of 1s and 0s, as returned by C<huffman_encode()>, and C<$rev_dict>, representing the reverse dictionary mapping Huffman codes to their corresponding symbols.

The function returns the decoded sequence of symbols as an array-ref.

=head2 lz77_encode / lz77_encode_symbolic

    my ($literals, $distances, $lengths, $matches) = lz77_encode($string);
    my ($literals, $distances, $lengths, $matches) = lz77_encode(\@symbols);

Low-level function that combines LZSS with ideas from the LZ4 method.

The function returns four values:

    $literals   # array-ref of uncompressed symbols
    $distances  # array-ref of back-reference distances
    $lengths    # array-ref of literal lengths
    $matches    # array-ref of match lengths

The output can be decoded with C<lz77_decode()> and C<lz77_decode_symbolic()>, respectively.

=head2 lz77_decode / lz77_decode_symbolic

    my $string  = lz77_decode(\@literals, \@distances, \@lengths, \@matches);
    my $symbols = lz77_decode_symbolic(\@literals, \@distances, \@lengths, \@matches);

Low-level function that performs decoding using the provided literals, distances, lengths and matches, returned by LZ77 encoding.

Inverse of C<lz77_encode()> and C<lz77_encode_symbolic()>, respectively.

=head2 lzss_encode / lzss_encode_fast / lzss_encode_symbolic / lzss_encode_fast_symbolic

    # Standard version
    my ($literals, $distances, $lengths) = lzss_encode($data);
    my ($literals, $distances, $lengths) = lzss_encode(\@symbols);

    # Faster version
    my ($literals, $distances, $lengths) = lzss_encode_fast($data);
    my ($literals, $distances, $lengths) = lzss_encode_fast(\@symbols);

Low-level function that applies the LZSS (Lempel-Ziv-Storer-Szymanski) algorithm on the provided data.

The function returns three values:

    $literals   # array-ref of uncompressed symbols
    $distances  # array-ref of back-reference distances
    $lengths    # array-ref of match lengths

The output can be decoded with C<lzss_decode()> and C<lzss_decode_symbolic()>, respectively.

=head2 lzss_decode / lzss_decode_symbolic

    my $string  = lzss_decode(\@literals, \@distances, \@lengths);
    my $symbols = lzss_decode_symbolic(\@literals, \@distances, \@lengths);

Low-level function that decodes the LZSS encoding, using the provided literals, distances, and lengths of matched sub-strings.

Inverse of C<lzss_encode()> and C<lzss_encode_fast()>.

=head2 deflate_encode

    # Returns a binary string
    my $string = deflate_encode(\@literals, \@distances, \@lengths);
    my $string = deflate_encode(\@literals, \@distances, \@lengths, \&create_ac_entry);

Low-level function that encodes the results returned by C<lzss_encode()> and C<lzss_encode_fast()>, using a DEFLATE-like approach, combined with Huffman coding.

=head2 deflate_decode

    # Huffman decoding
    my ($literals, $distances, $lengths) = deflate_decode($fh);
    my ($literals, $distances, $lengths) = deflate_decode($string);

    # Arithmetic decoding
    my ($literals, $distances, $lengths) = deflate_decode($fh, \&decode_ac_entry);
    my ($literals, $distances, $lengths) = deflate_decode($string, \&decode_ac_entry);

Inverse of C<deflate_encode()>.

=head2 make_deflate_tables

    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables($max_dist, $max_len);

Low-level function that returns a list of tables used in encoding the relative back-reference distances and lengths returned by C<lzss_encode()> and C<lzss_encode_fast()>.

When no arguments are provided:

    $max_dist = $Compression::Util::LZ_MAX_DIST
    $max_len  = $Compression::Util::LZ_MAX_LEN

There is no need to call this function explicitly. Use C<deflate_encode()> instead!

=head2 find_deflate_index

    my $index = find_deflate_index($value, $DISTANCE_SYMBOLS);

Low-level function that returns the index inside the DEFLATE tables for a given value.

=head1 EXPORT

Each function can be exported individually, as:

    use Compression::Util qw(bwt_compress);

By specifying the B<:all> keyword, will export all the exportable functions:

    use Compression::Util qw(:all);

Nothing is exported by default.

=head1 EXAMPLES

The functions can be combined in various ways, easily creating novel compression methods, as illustrated in the following examples.

=head2 Combining LZSS + MRL compression:

    my $enc = lzss_compress($str, \&mrl_compress_symbolic);
    my $dec = lzss_decompress($enc, \&mrl_decompress_symbolic);

=head2 Combining LZ77 + OBH encoding:

    my $enc = lz77_compress($str, \&obh_encode);
    my $dec = lz77_decompress($enc, \&obh_decode);

=head2 Combining LZSS + symbolic BWT compression:

    my $enc = lzss_compress($str, \&bwt_compress_symbolic);
    my $dec = lzss_decompress($enc, \&bwt_decompress_symbolic);

=head2 Combining BWT + symbolic LZSS:

    my $enc = bwt_compress($str, \&lzss_compress_symbolic);
    my $dec = bwt_decompress($enc, \&lzss_decompress_symbolic);

=head2 Combining LZW + Fibonacci encoding:

    my $enc = lzw_compress($str, \&fibonacci_encode);
    my $dec = lzw_decompress($enc, \&fibonacci_decode);

=head2 Combining BWT + symbolic LZ77 + symbolic MRL:

    my $enc = bwt_compress($str, sub ($s) { lz77_compress_symbolic($s, \&mrl_compress_symbolic) });
    my $dec = bwt_decompress($enc, sub ($s) { lz77_decompress_symbolic($s, \&mrl_decompress_symbolic) });

=head2 Combining LZ77 + BWT compression + Fibonacci encoding + Huffman coding + OBH encoding + MRL compression:

    # Compression
    my $enc = do {
        my ($literals, $distances, $lengths, $matches) = lz77_encode($str);
        bwt_compress(symbols2string($literals))
          . fibonacci_encode($lengths)
          . create_huffman_entry($matches)
          . obh_encode($distances, \&mrl_compress_symbolic);
    };

    # Decompression
    my $dec = do {
        open my $fh, '<:raw', \$enc;
        my $literals  = string2symbols(bwt_decompress($fh));
        my $lengths   = fibonacci_decode($fh);
        my $matches   = decode_huffman_entry($fh);
        my $distances = obh_decode($fh, \&mrl_decompress_symbolic);
        lz77_decode($literals, $distances, $lengths, $matches);
    };

=head1 REFERENCES

=over 4

=item * DEFLATE Compressed Data Format Specification
        L<https://datatracker.ietf.org/doc/html/rfc1951>

=item * GZIP file format specification
        L<https://datatracker.ietf.org/doc/html/rfc1952>

=item * BZIP2 Format Specification, by Joe Tsai:
        L<https://github.com/dsnet/compress/blob/master/doc/bzip2-format.pdf>

=item * Data Compression (Summer 2023) - Lecture 4 - The Unix 'compress' Program:
        L<https://youtube.com/watch?v=1cJL9Va80Pk>

=item * Data Compression (Summer 2023) - Lecture 5 - Basic Techniques:
        L<https://youtube.com/watch?v=TdFWb8mL5Gk>

=item * Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip):
        L<https://youtube.com/watch?v=SJPvNi4HrWQ>

=item * Data Compression (Summer 2023) - Lecture 12 - The Burrows-Wheeler Transform (BWT):
        L<https://youtube.com/watch?v=rQ7wwh4HRZM>

=item * Data Compression (Summer 2023) - Lecture 13 - BZip2:
        L<https://youtube.com/watch?v=cvoZbBZ3M2A>

=item * Data Compression (Summer 2023) - Lecture 15 - Infinite Precision in Finite Bits:
        L<https://youtube.com/watch?v=EqKbT3QdtOI>

=item * Information Retrieval WS 17/18, Lecture 4: Compression, Codes, Entropy:
        L<https://youtube.com/watch?v=A_F94FV21Ek>

=item * COMP526 7-5 SS7.4 Run length encoding:
        L<https://youtube.com/watch?v=3jKLjmV1bL8>

=item * COMP526 Unit 7-6 2020-03-24 Compression - Move-to-front transform:
        L<https://youtube.com/watch?v=Q2pinaj3i9Y>

=item * Basic arithmetic coder in C++:
        L<https://github.com/billbird/arith32>

=back

=head1 REPOSITORY

=over 4

=item * GitHub: L<https://github.com/trizen/Compression-Util>

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to: L<https://github.com/trizen/Compression-Util>.

=head1 AUTHOR

Daniel "Trizen" Șuteu  C<< <trizen@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Special thanks to professor Bill Bird for the awesome YouTube lectures on data compression.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
