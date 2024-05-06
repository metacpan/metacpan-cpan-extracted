package Compression::Util;

use utf8;
use 5.036;
use List::Util qw(uniq max sum);

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.06';
our $VERBOSE = 0;        # verbose mode

our $LZ_MAX_CHAIN_LEN = 32;    # how many recent positions to remember in LZ parsing

# Arithmetic Coding settings
use constant BITS         => 32;
use constant MAX          => oct('0b' . ('1' x BITS));
use constant INITIAL_FREQ => 1;

our %EXPORT_TAGS = (
    'all' => [
        qw(
          read_bit
          read_bit_lsb

          read_bits
          read_bits_lsb

          int2bits
          int2bits_lsb

          bits2int
          bits2int_lsb

          string2symbols
          symbols2string

          read_null_terminated

          bwt_encode
          bwt_decode

          bwt_encode_symbolic
          bwt_decode_symbolic

          bwt_sort
          bwt_sort_symbolic

          bz2_compress
          bz2_decompress

          bz2_compress_symbolic
          bz2_decompress_symbolic

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
          lzss_decode

          lz77_encode
          lz77_decode

          lz77_compress
          lz77_decompress

          lz77_encode_symbolic
          lz77_decode_symbolic

          lz77_compress_symbolic
          lz77_decompress_symbolic

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

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});
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

    my $data = '';
    read($fh, $data, $bits_len >> 3);
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

    my $data = '';
    read($fh, $data, $bits_len >> 3);
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

sub bits2int ($fh, $size, $buffer) {

    if ($size % 8 == 0 and ($$buffer // '') eq '') {    # optimization
        return oct('0b' . read_bits($fh, $size));
    }

    my $bitstring = '0b';
    for (1 .. $size) {
        $bitstring .= ($$buffer // '') eq '' ? read_bit($fh, $buffer) : chop($$buffer);
    }
    oct($bitstring);
}

sub bits2int_lsb ($fh, $size, $buffer) {

    if ($size % 8 == 0 and ($$buffer // '') eq '') {    # optimization
        return oct('0b' . reverse(read_bits_lsb($fh, $size)));
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

    if (ref($symbols) eq '') {
        return __SUB__->(string2symbols($symbols));
    }

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
        return __SUB__->(string2symbols($symbols));
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
        return __SUB__->(string2symbols($symbols));
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
        return __SUB__->(string2symbols($symbols));
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

    if (ref($integers) eq '') {
        return __SUB__->(string2symbols($integers));
    }

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

sub _encode_alphabet_256 ($alphabet) {

    my %table;
    @table{@$alphabet} = ();

    my $populated = 0;
    my @marked;

    for (my $i = 0 ; $i <= 255 ; $i += 32) {

        my $enc = 0;
        foreach my $j (0 .. 31) {
            if (exists($table{$i + $j})) {
                $enc |= 1 << $j;
            }
        }

        $populated <<= 1;

        if ($enc > 0) {
            $populated |= 1;
            push @marked, 0xffffffff - $enc;
        }
    }

    my $delta = delta_encode(\@marked);

    $VERBOSE && say STDERR "Populated : ", sprintf('%08b', $populated);
    $VERBOSE && say STDERR "Marked    : @marked";
    $VERBOSE && say STDERR "Delta len : ", length($delta);

    my $encoded = '';
    $encoded .= chr($populated);
    $encoded .= $delta;
    return $encoded;
}

sub _decode_alphabet_256 ($fh) {

    my @populated = split(//, sprintf('%08b', ord(getc($fh))));
    my @marked    = map { 0xffffffff - $_ } @{delta_decode($fh)};

    my @alphabet;
    for (my $i = 0 ; $i <= 255 ; $i += 32) {
        if (shift(@populated)) {
            my $m = shift(@marked);
            foreach my $j (0 .. 31) {
                if ($m & 1) {
                    push @alphabet, $i + $j;
                }
                $m >>= 1;
            }
        }
    }

    return \@alphabet;
}

sub encode_alphabet ($alphabet) {

    my $max_symbol = max(@$alphabet) // -1;

    if ($max_symbol <= 255) {
        return (chr(1) . _encode_alphabet_256($alphabet));
    }

    return (chr(0) . delta_encode($alphabet));
}

sub decode_alphabet ($fh) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2);
    }

    if (ord(getc($fh) // die "error") == 1) {
        return _decode_alphabet_256($fh);
    }

    return delta_decode($fh);
}

##########################
# Move to front transform
##########################

sub mtf_encode ($symbols, $alphabet = undef) {

    if (ref($symbols) eq '') {
        return __SUB__->(string2symbols($symbols), $alphabet);
    }

    if (defined($alphabet) and ref($alphabet) eq '') {
        return __SUB__->($symbols, string2symbols($alphabet));
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
        return __SUB__->(string2symbols($encoded), $alphabet);
    }

    if (ref($alphabet) eq '') {
        return __SUB__->($encoded, string2symbols($alphabet));
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
        return __SUB__->(string2symbols($symbols), $entropy_sub);
    }

    my ($mtf, $alphabet) = mtf_encode($symbols);
    my $rle  = zrle_encode($mtf);
    my $rle4 = rle4_encode($rle, scalar(@$rle));

    encode_alphabet($alphabet) . $entropy_sub->($rle4);
}

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

############################################################
# Bzip2-like compression (BWT + MTF + ZRLE + Huffman coding)
############################################################

sub bz2_compress ($chunk, $entropy_sub = \&create_huffman_entry) {

    if (ref($chunk) eq 'ARRAY') {
        return bz2_compress_symbolic($chunk, $entropy_sub);
    }

    my $rle1 = rle4_encode(string2symbols($chunk));
    my ($bwt, $idx) = bwt_encode(pack('C*', @$rle1));

    $VERBOSE && say STDERR "BWT index = $idx";

    my ($mtf, $alphabet) = mtf_encode(string2symbols($bwt));
    my $rle = zrle_encode($mtf);

    pack('N', $idx) . encode_alphabet($alphabet) . $entropy_sub->($rle);
}

sub bz2_decompress ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2, $entropy_sub);
    }

    my $idx      = bits2int($fh, 32, \my $buffer);
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
# Bzip2-like compression (symbolic variant)
###########################################

sub bz2_compress_symbolic ($symbols, $entropy_sub = \&create_huffman_entry) {

    if (ref($symbols) eq '') {
        return __SUB__->(string2symbols($symbols), $entropy_sub);
    }

    my $rle4 = rle4_encode($symbols);
    my ($bwt, $idx) = bwt_encode_symbolic($rle4);

    my ($mtf, $alphabet) = mtf_encode($bwt);
    my $rle = zrle_encode($mtf);

    $VERBOSE && say STDERR "BWT index = $idx";
    $VERBOSE && say STDERR "Max symbol: ", max(@$alphabet) // 0;

    pack('N', $idx) . encode_alphabet($alphabet) . $entropy_sub->($rle);
}

sub bz2_decompress_symbolic ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2, $entropy_sub);
    }

    my $idx      = bits2int($fh, 32, \my $buffer);
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
        return __SUB__->(string2symbols($symbols));
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
        return __SUB__->(string2symbols($symbols));
    }

    my ($enc, $alphabet) = adaptive_ac_encode($symbols);
    pack('N', length($enc)) . encode_alphabet($alphabet) . pack("B*", $enc);
}

sub decode_adaptive_ac_entry ($fh) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2);
    }

    my $enc_len  = bits2int($fh, 32, \my $buffer);
    my $alphabet = decode_alphabet($fh);

    if ($enc_len > 0) {
        my $bits = read_bits($fh, $enc_len);
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
        return __SUB__->(string2symbols($symbols));
    }

    huffman_from_freq(frequencies($symbols));
}

########################
# Huffman Coding entries
########################

sub create_huffman_entry ($symbols) {

    if (ref($symbols) eq '') {
        return __SUB__->(string2symbols($symbols));
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

    my $enc_len = bits2int($fh, 32, \my $buffer);
    $VERBOSE && say STDERR "Encoded length: $enc_len\n";

    if ($enc_len > 0) {
        return huffman_decode(read_bits($fh, $enc_len), $rev_dict);
    }

    return [];
}

###################################################################################
# DEFLATE-like encoding of literals and backreferences produced by the LZSS methods
###################################################################################

sub make_deflate_tables ($size) {

    # [distance value, offset bits]
    my @DISTANCE_SYMBOLS = map { [$_, 0] } (0 .. 4);

    until ($DISTANCE_SYMBOLS[-1][0] > $size) {
        push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (4 / 3)), $DISTANCE_SYMBOLS[-1][1] + 1];
        push @DISTANCE_SYMBOLS, [int($DISTANCE_SYMBOLS[-1][0] * (3 / 2)), $DISTANCE_SYMBOLS[-1][1]];
    }

    # [length, offset bits]
    my @LENGTH_SYMBOLS = ((map { [$_, 0] } (1 .. 10)));

    {
        my $delta = 1;
        until ($LENGTH_SYMBOLS[-1][0] > 163) {
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1] + 1];
            $delta *= 2;
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
            push @LENGTH_SYMBOLS, [$LENGTH_SYMBOLS[-1][0] + $delta, $LENGTH_SYMBOLS[-1][1]];
        }
        push @LENGTH_SYMBOLS, [258, 0];
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

    my $size = max(@$distances) // 0;
    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables($size);

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

            push @len_symbols, $len_idx + 256;

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

    pack('N', $size) . $entropy_sub->(\@len_symbols) . $entropy_sub->(\@dist_symbols) . pack('B*', $offset_bits);
}

sub deflate_decode ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2, $entropy_sub);
    }

    my $size = bits2int($fh, 32, \my $buffer);
    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS) = make_deflate_tables($size);

    my $len_symbols  = $entropy_sub->($fh);
    my $dist_symbols = $entropy_sub->($fh);

    my $bits_len = 0;

    foreach my $i (@$dist_symbols) {
        $bits_len += $DISTANCE_SYMBOLS->[$i][1];
    }

    foreach my $i (@$len_symbols) {
        if ($i >= 256) {
            $bits_len += $LENGTH_SYMBOLS->[$i - 256][1];
        }
    }

    my $bits = read_bits($fh, $bits_len);

    my @literals;
    my @lengths;
    my @distances;

    my $j = 0;

    foreach my $i (@$len_symbols) {
        if ($i >= 256) {
            my $dist = $dist_symbols->[$j++];
            push @literals,  undef;
            push @lengths,   $LENGTH_SYMBOLS->[$i - 256][0] + oct('0b' . substr($bits, 0, $LENGTH_SYMBOLS->[$i - 256][1], ''));
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

    if (ref($integers) eq '') {
        return __SUB__->(string2symbols($integers));
    }

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

    if (ref($integers) eq '') {
        return __SUB__->(string2symbols($integers));
    }

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
# LZ77 Encoding
###################

sub lz77_encode_symbolic ($symbols) {

    if (ref($symbols) eq '') {
        return __SUB__->(string2symbols($symbols));
    }

    my $la  = 0;
    my $end = $#$symbols;

    my $min_len       = 4;      # minimum match length
    my $max_len       = 255;    # maximum match length
    my $max_chain_len = 32;     # how many recent positions to keep track of

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my @lookahead_symbols;
        if ($la + $min_len - 1 <= $end) {
            push @lookahead_symbols, @{$symbols}[$la .. $la + $min_len - 1];
        }
        else {
            for (my $j = 0 ; ($j < $min_len and $la + $j <= $end) ; ++$j) {
                push @lookahead_symbols, $symbols->[$la + $j];
            }
        }

        my $lookahead = join(' ', @lookahead_symbols);

        if (exists($table{$lookahead})) {

            foreach my $p (@{$table{$lookahead}}) {

                my $n = $min_len;

                while ($n <= $max_len and $la + $n <= $end and $symbols->[$la + $n - 1] == $symbols->[$p + $n - 1]) {
                    ++$n;
                }

                if ($n > $best_n) {
                    $best_p = $p;
                    $best_n = $n;
                }
            }

            my @matched = @{$symbols}[$la .. $la + $best_n - 1];

            foreach my $i (0 .. scalar(@matched) - $min_len) {

                my $key = join(' ', @matched[$i .. $i + $min_len - 1]);
                unshift @{$table{$key}}, $la + $i;

                if (scalar(@{$table{$key}}) > $max_chain_len) {
                    pop @{$table{$key}};
                }
            }
        }
        else {
            $table{$lookahead} = [$la];
        }

        --$best_n;

        if ($best_n >= $min_len) {

            push @lengths,   $best_n;
            push @distances, $la - $best_p;
            push @literals,  $symbols->[$la + $best_n];

            $la += $best_n + 1;
        }
        else {
            my @bytes = @{$symbols}[$best_p .. $best_p + $best_n];

            push @lengths,   (0) x scalar(@bytes);
            push @distances, (0) x scalar(@bytes);
            push @literals, @bytes;

            $la += $best_n + 1;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lz77_decode_symbolic ($literals, $distances, $lengths) {

    my @data;
    my $data_len = 0;

    foreach my $i (0 .. $#$lengths) {

        if ($lengths->[$i] != 0) {
            my $length = $lengths->[$i];
            my $dist   = $distances->[$i];

            foreach my $j (1 .. $length) {
                push @data, $data[$data_len + $j - $dist - 1];
            }

            $data_len += $length;
        }

        push @data, $literals->[$i];
        $data_len += 1;
    }

    return \@data;
}

sub lz77_encode ($str) {

    if (ref($str) eq 'ARRAY') {
        return lz77_encode_symbolic($str);
    }

    my $la     = 0;
    my $prefix = '';
    my @chars  = split(//, $str);
    my $end    = $#chars;

    my (@literals, @distances, @lengths);

    while ($la <= $end) {

        my $n = 1;
        my $p = length($prefix);

        my $tmp;
        my $token = $chars[$la];

        while (    $n <= 255
               and $la + $n <= $end
               and ($tmp = rindex($prefix, $token, $p)) >= 0) {
            $p = $tmp;
            $token .= $chars[$la + $n];
            ++$n;
        }

        --$n;
        push @distances, $la - $p;
        push @lengths,   $n;
        push @literals,  ord($chars[$la + $n]);
        $la += $n + 1;
        $prefix .= $token;
    }

    return (\@literals, \@distances, \@lengths);
}

sub lz77_decode ($literals, $distances, $lengths) {
    symbols2string(lz77_decode_symbolic($literals, $distances, $lengths));
}

###################
# LZSS Encoding
###################

sub lzss_encode ($str) {

    my $la      = 0;
    my @symbols = unpack('C*', $str);
    my $end     = $#symbols;

    my $min_len       = 4;                    # minimum match length
    my $max_len       = 258;                  # maximum match length
    my $max_chain_len = $LZ_MAX_CHAIN_LEN;    # how many recent positions to keep track of

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $lookahead = substr($str, $la, $min_len);

        if (exists($table{$lookahead})) {

            foreach my $p (@{$table{$lookahead}}) {

                my $n = $min_len;

                while ($n <= $max_len and $la + $n <= $end and $symbols[$la + $n - 1] == $symbols[$p + $n - 1]) {
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
        else {
            $table{$lookahead} = [$la];
        }

        if ($best_n > $min_len) {

            push @lengths,   $best_n - 1;
            push @distances, $la - $best_p;
            push @literals,  undef;

            $la += $best_n - 1;
        }
        else {

            push @lengths,   (0) x $best_n;
            push @distances, (0) x $best_n;
            push @literals, @symbols[$best_p .. $best_p + $best_n - 1];

            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

sub lzss_decode ($literals, $distances, $lengths) {

    my @data;
    my $data_len = 0;

    foreach my $i (0 .. $#$lengths) {

        if ($lengths->[$i] == 0) {
            push @data, $literals->[$i];
            $data_len += 1;
            next;
        }

        my $length = $lengths->[$i];
        my $dist   = $distances->[$i];

        foreach my $j (1 .. $length) {
            push @data, $data[$data_len + $j - $dist - 1];
        }

        $data_len += $length;
    }

    pack('C*', @data);
}

###################
# LZSSF Compression
###################

sub lzss_encode_fast($str) {

    my $la      = 0;
    my @symbols = unpack('C*', $str);
    my $end     = $#symbols;

    my $min_len = 4;      # minimum match length
    my $max_len = 258;    # maximum match length

    my (@literals, @distances, @lengths, %table);

    while ($la <= $end) {

        my $best_n = 1;
        my $best_p = $la;

        my $lookahead = substr($str, $la, $min_len);

        if (exists($table{$lookahead})) {

            my $p = $table{$lookahead};
            my $n = $min_len;

            while ($n <= $max_len and $la + $n <= $end and $symbols[$la + $n - 1] == $symbols[$p + $n - 1]) {
                ++$n;
            }

            $best_p = $p;
            $best_n = $n;

            $table{$lookahead} = $la;
        }
        else {
            $table{$lookahead} = $la;
        }

        if ($best_n > $min_len) {

            push @lengths,   $best_n - 1;
            push @distances, $la - $best_p;
            push @literals,  undef;

            $la += $best_n - 1;
        }
        else {

            push @lengths,   (0) x $best_n;
            push @distances, (0) x $best_n;
            push @literals, @symbols[$best_p .. $best_p + $best_n - 1];

            $la += $best_n;
        }
    }

    return (\@literals, \@distances, \@lengths);
}

#########################
# LZSS + DEFLATE encoding
#########################

sub lzss_compress($chunk, $entropy_sub = \&create_huffman_entry, $lzss_encoding_sub = \&lzss_encode) {

    if (ref($chunk) eq 'ARRAY') {
        die "lzss_compress: compression of arbitrary symbols is not supported!";
    }

    my ($literals, $distances, $lengths) = $lzss_encoding_sub->($chunk);
    deflate_encode($literals, $distances, $lengths, $entropy_sub);
}

sub lzss_decompress($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2, $entropy_sub);
    }

    my ($literals, $distances, $lengths) = deflate_decode($fh, $entropy_sub);
    lzss_decode($literals, $distances, $lengths);
}

################################################################
# Encode a list of symbols, using offset bits and huffman coding
################################################################

sub obh_encode ($distances, $entropy_sub = \&create_huffman_entry) {

    my $size = max(@$distances) // 0;
    my ($DISTANCE_SYMBOLS) = make_deflate_tables($size);

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

    pack('N', $size) . $entropy_sub->(\@symbols) . pack('B*', $offset_bits);
}

sub obh_decode ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2, $entropy_sub);
    }

    my $size = bits2int($fh, 32, \my $buffer);
    my ($DISTANCE_SYMBOLS) = make_deflate_tables($size);

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

##################
# LZ77 Compression
##################

sub lz77_compress ($chunk, $entropy_sub = \&create_huffman_entry) {
    my ($literals, $distances, $lengths) = lz77_encode($chunk);
    $entropy_sub->($literals) . $entropy_sub->($lengths) . obh_encode($distances, $entropy_sub);
}

sub lz77_compress_symbolic ($symbols, $entropy_sub = \&create_huffman_entry) {
    my ($literals, $distances, $lengths) = lz77_encode_symbolic($symbols);
    $entropy_sub->($literals) . $entropy_sub->($lengths) . obh_encode($distances, $entropy_sub);
}

sub lz77_decompress_symbolic ($fh, $entropy_sub = \&decode_huffman_entry) {

    if (ref($fh) eq '') {
        open my $fh2, '<:raw', \$fh;
        return __SUB__->($fh2, $entropy_sub);
    }

    my $literals  = $entropy_sub->($fh);
    my $lengths   = $entropy_sub->($fh);
    my $distances = obh_decode($fh, $entropy_sub);

    lz77_decode_symbolic($literals, $distances, $lengths);
}

sub lz77_decompress($fh, $entropy_sub = \&decode_huffman_entry) {
    symbols2string(lz77_decompress_symbolic($fh, $entropy_sub));
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
            print $out_fh bz2_compress($chunk);
        }
    }

    sub decompress ($fh, $out_fh) {
        while (!eof($fh)) {
            print $out_fh bz2_decompress($fh);
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
    * Bzip2-like compression
    * LZ77/LZSS compression
    * LZW compression

The provided techniques can be easily combined in various ways to create powerful compressors, such as the Bzip2 compressor, which is a pipeline of the following methods:

    1. Run-length encoding (RLE4)
    2. Burrows-Wheeler transform (BWT)
    3. Move-to-front transform (MTF)
    4. Zero run-length encoding (ZRLE)
    5. Huffman coding

This functionality is provided by the function C<bz2_compress()>, which can be explicitly implemented as:

    use 5.036;
    use List::Util qw(uniq);
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
    bz2_decompress($enc) eq $data or die "decompression error";

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
    $Compression::Util::LZ_MAX_CHAIN_LEN = 32; # how many recent positions to remember for each match

=head2 $LZ_MAX_CHAIN_LEN

The value of C<$LZ_MAX_CHAIN_LEN> controls the amount of recent positions to remember for each matched prefix. A larger value results in better compression, finding longer matches, at the expense of speed.

By default, <$LZ_MAX_CHAIN_LEN> is set to C<32>.

=head1 HIGH-LEVEL FUNCTIONS

      create_huffman_entry(\@symbols)      # Create a Huffman Coding block
      decode_huffman_entry($fh)            # Decode a Huffman Coding block

      create_ac_entry(\@symbols)           # Create an Arithmetic Coding block
      decode_ac_entry($fh)                 # Decode an Arithmetic Coding block

      create_adaptive_ac_entry(\@symbols)  # Create an Adaptive Arithmetic Coding block
      decode_adaptive_ac_entry($fh)        # Decode an Adaptive Arithmetic Coding block

      mrl_compress_symbolic(\@symbols)     # MRL compression (MTF+ZRLE+RLE4+Huffman coding)
      mrl_decompress_symbolic($fh)         # Inverse of the above method

      bz2_compress($string)                # Bzip2-like compression (RLE4+BWT+MTF+ZRLE+Huffman coding)
      bz2_decompress($fh)                  # Inverse of the above method

      bz2_compress_symbolic(\@symbols)     # Bzip2-like compression (RLE4+sBWT+MTF+ZRLE+Huffman coding)
      bz2_decompress_symbolic($fh)         # Inverse of the above method

      lzss_compress($string)               # LZSS + DEFLATE-like encoding of distances and lengths
      lzss_decompress($fh)                 # Inverse of the above two methods

      lz77_compress($string)               # LZ77 + Huffman coding of lengths and literals + OBH for distances
      lz77_decompress($fh)                 # Inverse of the above method

      lz77_compress_symbolic(\@symbols)    # Symbolic LZ77 + Huffman coding of lengths and literals + OBH for distances
      lz77_decompress_symbolic($fh)        # Inverse of the above method

      lzw_compress($string)                # LZW + abc_encode() compression
      lzw_decompress($fh)                  # Inverse of the above method

=head1 MEDIUM-LEVEL FUNCTIONS

      deltas(\@ints)                       # Computes the differences between integers
      accumulate(\@deltas)                 # Inverse of the above method

      delta_encode(\@ints)                 # Delta+RLE encoding of an array of ints
      delta_decode($fh)                    # Inverse of the above method

      fibonacci_encode(\@symbols)          # Fibonacci coding of an array of symbols
      fibonacci_decode($fh)                # Inverse of the above method

      elias_gamma_encode(\@symbols)        # Elias Gamma coding method of an array of symbols
      elias_gamma_decode($fh)              # Inverse of the above method

      elias_omega_encode(\@symbols)        # Elias Omega coding method of an array of symbols
      elias_omega_decode($fh)              # Inverse of the above method

      abc_encode(\@symbols)                # Adaptive Binary Concatenation method of an array of symbols
      abc_decode($fh)                      # Inverse of the above method

      obh_encode(\@symbols)                # Offset bits + Huffman coding of an array of symbols
      obh_decode($fh)                      # Inverse of the above method

      bwt_encode($string)                  # Burrows-Wheeler transform
      bwt_decode($bwt, $idx)               # Inverse of Burrows-Wheeler transform

      bwt_encode_symbolic(\@symbols)       # Burrows-Wheeler transform over an array of symbols
      bwt_decode_symbolic(\@bwt, $idx)     # Inverse of symbolic Burrows-Wheeler transform

      mtf_encode(\@symbols)                # Move-to-front transform
      mtf_decode(\@mtf, \@alphabet)        # Inverse of the above method

      encode_alphabet(\@alphabet)          # Encode an alphabet of symbols into a binary string
      decode_alphabet($fh)                 # Inverse of the above method

      frequencies(\@symbols)               # Returns a dictionary with symbol frequencies
      run_length(\@symbols, $max=undef)    # Run-length encoding, returning a 2D array

      rle4_encode(\@symbols, $max=255)     # Run-length encoding with 4 or more consecutive characters
      rle4_decode(\@rle4)                  # Inverse of the above method

      zrle_encode(\@symbols)               # Run-length encoding of zeros
      zrle_decode(\@zrle)                  # Inverse of the above method

      ac_encode(\@symbols)                 # Arithmetic Coding applied on an array of symbols
      ac_decode($bitstring, \%freq)        # Inverse of the above method

      adaptive_ac_encode(\@symbols)               # Adaptive Arithmetic Coding applied on an array of symbols
      adaptive_ac_decode($bitstring, \@alphabet)  # Inverse of the above method

      lzw_encode($string)                  # LZW encoding of a given string
      lzw_decode(\@symbols)                # Inverse of the above method

=head1 LOW-LEVEL FUNCTIONS

      read_bit($fh, \$buffer)              # Read one bit from file-handle (MSB)
      read_bit_lsb($fh, \$buffer)          # Read one bit from file-handle (LSB)

      read_bits($fh, $len)                 # Read `$len` bits from file-handle (MSB)
      read_bits_lsb($fh, $len)             # Read `$len` bits from file-handle (LSB)

      int2bits($symbol, $size)             # Convert an integer to bits of width `$size` (MSB)
      int2bits_lsb($symbol, $size)         # Convert an integer to bits of width `$size) (LSB)

      bits2int($fh, $size, \$buffer)       # Inverse of `int2bits()`
      bits2int_lsb($fh, $size, \$buffer)   # Inverse of `int2bits_lsb()`

      string2symbols($string)              # Returns an array-ref of code points
      symbols2string(\@symbols)            # Returns a string, given an array of code points

      read_null_terminated($fh)            # Read a binary string that ends with NULL ("\0")

      binary_vrl_encode($bitstring)        # Binary variable run-length encoding
      binary_vrl_decode($bitstring)        # Binary variable run-length decoding

      bwt_sort($string)                    # Burrows-Wheeler sorting
      bwt_sort_symbolic(\@symbols)         # Burrows-Wheeler sorting, applied on an array of symbols

      huffman_encode(\@symbols, \%dict)    # Huffman encoding
      huffman_decode($bitstring, \%dict)   # Huffman decoding, given a string of bits

      huffman_from_freq(\%freq)            # Create Huffman dictionaries, given an hash of frequencies
      huffman_from_symbols(\@symbols)      # Create Huffman dictionaries, given an array of symbols
      huffman_from_code_lengths(\@lens)    # Create canonical Huffman codes, given an array of code lengths

      make_deflate_tables($size)           # Returns the DEFLATE tables for distance and length symbols
      find_deflate_index($value, \@table)  # Returns the index in a DEFLATE table, given a numerical value

      lzss_encode($string)                 # LZSS encoding of a string into literals, distances and lengths
      lzss_encode_fast($string)            # Fast-LZSS encoding of a string into literals, distances and lengths
      lzss_decode(\@lits, \@idxs, \@lens)  # Inverse of the above two methods

      deflate_encode(\@lits, \@idxs, \@lens)  # DEFLATE-like encoding of values returned by lzss_encode()
      deflate_decode($fh)                     # Inverse of the above method

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

=head2 lzss_compress

    # With Huffman coding
    my $string = lzss_compress($data);

    # With Arithmetic Coding
    my $string = lzss_compress($data, \&create_ac_entry);

    # Using Fast-LZSS parsing + Huffman coding
    my $string = lzss_compress($data, \&create_huffman_entry, \&lzss_encode_fast);

High-level function that performs LZSS (Lempel-Ziv-Storer-Szymanski) compression on the provided data, using the pipeline:

    1. lzss_encode
    2. deflate_encode

=head2 lzss_decompress

    # With Huffman coding
    my $data = lzss_decompress($fh);
    my $data = lzss_decompress($string);

    # With Arithemtic coding
    my $data = lzss_decompress($fh, \&decode_ac_entry);
    my $data = lzss_decompress($string, \&decode_ac_entry);

Inverse of C<lzss_compress()>.

=head2 lz77_compress

    # With Huffman coding
    my $string = lz77_compress($data);

    # With Arithmetic Coding
    my $string = lz77_compress($data, \&create_ac_entry);

High-level function that performs LZ77 (Lempel-Ziv 1977) compression on the provided data, using the pipeline:

    1. lz77_encode
    2. create_huffman_entry(literals)
    3. create_huffman_entry(lengths)
    4. obh_encode(distances)

=head2 lz77_decompress

    # With Huffman coding
    my $data = lz77_decompress($fh);
    my $data = lz77_decompress($string);

    # With Arithmetic Coding
    my $data = lz77_decompress($fh, \&decode_ac_entry);
    my $data = lz77_decompress($string, \&decode_ac_entry);

Inverse of C<lz77_compress()>.

=head2 lz77_compress_symbolic

    # Does Huffman coding
    my $string = lz77_compress_symbolic(\@symbols);

    # Does Arithmetic coding
    my $string = lz77_compress_symbolic(\@symbols, \&create_ac_entry);

Similar to C<lz77_compress()>, except that it accepts an arbitrary array-ref of non-negative integer values as input.

=head2 lz77_decompress_symbolic

    # Using Huffman coding
    my $symbols = lz77_decompress_symbolic($fh);
    my $symbols = lz77_decompress_symbolic($string);

    # Using Arithmetic coding
    my $symbols = lz77_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = lz77_decompress_symbolic($string, \&decode_ac_entry);

Inverse of C<lz77_compress_symbolic()>.

=head2 lzw_compress

    my $string = lzw_compress($data);

High-level function that performs LZW (Lempel-Ziv-Welch) compression on the provided data, using the pipeline:

    1. lzw_encode
    2. abc_encode

=head2 lzw_decompress

    my $data = lzw_decompress($fh);
    my $data = lzw_decompress($string);

Performs Lempel-Ziv-Welch (LZW) decompression on the provided string or file-handle. Inverse of C<lzw_compress()>.

=head2 bz2_compress

    # Using Huffman Coding
    my $string = bz2_compress($data);

    # Using Arithmetic Coding
    my $string = bz2_compress($data, \&create_ac_entry);

High-level function that performs Bzip2-like compression on the provided data, using the pipeline:

    1. rle4_encode
    2. bwt_encode
    3. mtf_encode
    4. zrle_encode
    5. create_huffman_entry

=head2 bz2_decompress

    # With Huffman coding
    my $data = bz2_decompress($fh);
    my $data = bz2_decompress($string);

    # With Arithmetic coding
    my $data = bz2_decompress($fh, \&decode_ac_entry);
    my $data = bz2_decompress($string, \&decode_ac_entry);

Inverse of C<bz2_compress()>.

=head2 bz2_compress_symbolic

    # Does Huffman coding
    my $string = bz2_compress_symbolic(\@symbols);

    # Does Arithmetic coding
    my $string = bz2_compress_symbolic(\@symbols, \&create_ac_entry);

Similar to C<bz2_compress()>, except that it accepts an arbitrary array-ref of non-negative integer values as input. It is also a bit slower on large inputs.

=head2 bz2_decompress_symbolic

    # Using Huffman coding
    my $symbols = bz2_decompress_symbolic($fh);
    my $symbols = bz2_decompress_symbolic($string);

    # Using Arithmetic coding
    my $symbols = bz2_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = bz2_decompress_symbolic($string, \&decode_ac_entry);

Inverse of C<bz2_compress_symbolic()>.

=head2 mrl_compress_symbolic

    # Does Huffman coding
    my $string = mrl_compress_symbolic(\@symbols);

    # Does Arithmetic coding
    my $string = mrl_compress_symbolic(\@symbols, \&create_ac_entry);

A fast compression method, using the following pipeline:

    1. mtf_encode
    2. zrle_encode
    3. rle4_encode
    4. create_huffman_entry

It accepts an arbitrary array-ref of non-negative integer values as input.

=head2 mrl_decompress_symbolic

    # Using Huffman coding
    my $symbols = mrl_decompress_symbolic($fh);
    my $symbols = mrl_decompress_symbolic($string);

    # Using Arithmetic coding
    my $symbols = mrl_decompress_symbolic($fh, \&decode_ac_entry);
    my $symbols = mrl_decompress_symbolic($string, \&decode_ac_entry);

Inverse of C<mrl_compress_symbolic()>.

=head1 INTERFACE FOR MEDIUM-LEVEL FUNCTIONS

=head2 frequencies

    my $freq = frequencies(\@symbols);

Returns an hash ref dictionary with frequencies, given an array of symbols.

=head2 deltas

    my $deltas = deltas(\@integers);

Computes the differences between consecutive integers, returning an array.

=head2 accumulate

    my $integers = accumulate(\@deltas);

Inverse of C<deltas()>.

=head2 delta_encode

    my $string = delta_encode(\@integers);

Encodes a sequence of integers (including negative integers) using Delta + Run-length + Elias omega coding, returning a binary string.

Delta encoding calculates the difference between consecutive integers in the sequence and encodes these differences using Elias omega coding. When it's beneficial, runs of identitical symbols are collapsed with RLE.

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

This method is particularly effective in encoding a sequence of integers that are in ascending order.

=head2 abc_decode

    # Given a filehandle
    my $symbols = abc_decode($fh);

    # Given a binary string
    my $symbols = abc_decode($string);

Inverse of C<abc_encode()>.

=head2 obh_encode

    # With Huffman Coding
    my $string = obh_encode(\@symbols);

    # With Arithemtic Coding
    my $string = obh_encode(\@symbols, \&create_ac_entry);

Encodes a sequence of non-negative integers using offset bits and Huffman coding.

This method is particularly effective in encoding a sequence of moderately large random integers, such as the list of distances returned by C<lzss_encode()>.

=head2 obh_decode

    # Given a filehandle
    my $symbols = obh_decode($fh);                        # Huffman decoding
    my $symbols = obh_decode($fh, \&decode_ac_entry);     # Arithemtic decoding

    # Given a binary string
    my $symbols = obh_decode($string);                    # Huffman decoding
    my $symbols = obh_decode($string, \&decode_ac_entry); # Arithemtic decoding

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

=head2 encode_alphabet

    my $string = encode_alphabet(\@alphabet);

Efficienlty encodes an alphabet of symbols into a binary string.

=head2 decode_alphabet

    my $alphabet = decode_alphabet($fh);
    my $alphabet = decode_alphabet($string);

Decodes an encoded alphabet, given a file-handle or a binary string, returning an array of symbols. Inverse of C<encode_alphabet()>.

=head2 run_length

    my $rl = run_length(\@symbols);
    my $rl = run_length(\@symbols, $max_run);

Performs Run-Length Encoding (RLE) on a sequence of symbolic elements.

It takes two parameters: C<\@symbols>, representing an array of symbols, and C<$max_run>, indicating the maximum run length allowed.

The function returns a 2D-array, with pairs: C<[symbol, run_length]>, such that the following code reconstructs the C<\@symbols> array:

    my @symbols = map { ($_->[0]) x $_->[1] } @$rl;

By default, the maximum run-length is unlimited.

=head2 rle4_encode

    my $rle4 = rle4_encode(\@symbols);
    my $rle4 = rle4_encode(\@symbols, $max_run);

Performs Run-Length Encoding (RLE) on a sequence of symbolic elements, specifically designed for runs of four or more consecutive symbols.

It takes two parameters: C<\@symbols>, representing an array of symbols, and C<$max_run>, indicating the maximum run length allowed during encoding.

The function returns the encoded RLE sequence as an array-ref of symbols.

By default, the maximum run-length is limited to C<255>.

=head2 rle4_decode

    my $symbols = rle4_decode($rle4);

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

=head2 read_bit

    my $bit = read_bit($fh, \$buffer);

Reads a single bit from a file-handle C<$fh> (MSB order).

The function stores the extra bits inside the C<$buffer>, reading one character at a time from the filehandle.

=head2 read_bit_lsb

    my $bit = read_bit_lsb($fh, \$buffer);

Reads a single bit from a file-handle C<$fh> (LSB order).

The function stores the extra bits inside the C<$buffer>, reading one character at a time from the filehandle.

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

=head2 bits2int

    my $integer = bits2int($fh, $size, \$buffer)

Read C<$size> bits from file-handle C<$fh> and convert them to an integer, in MSB order. Inverse of C<int2bits()>.

The function stores the extra bits inside the C<$buffer>, reading one character at a time from the filehandle.

=head2 bits2int_lsb

    my $integer = bits2int_lsb($fh, $size, \$buffer)

Read C<$size> bits from file-handle C<$fh> and convert them to an integer, in LSB order. Inverse of C<int2bits_lsb()>.

The function stores the extra bits inside the C<$buffer>, reading one character at a time from the filehandle.

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

Low-level function that constructs Huffman prefix codes, given an array of symbols.

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

    my ($literals, $distances, $lengths) = lz77_encode($string);
    my ($literals, $distances, $lengths) = lz77_encode_symbolic(\@symbols);

Low-level function that applies the LZ77 (Lempel-Ziv 1977) algorithm on the provided data.

The function returns three values: C<$literals>, which is an array-ref of uncompressed bytes, C<$distances>, which contains the relative back-reference distances of the matched sub-strings, and C<$lengths>, which holds the lengths of the matched sub-strings.

The function C<lz77_encode_symbolic()> accepts an array-ref of arbitrarily large non-negative integers as input.

Lengths are limited to C<255>. The output can be decoded with C<lz77_decode()> and C<lz77_encode_symbolic()>, respectively.

=head2 lz77_decode / lz77_decode_symbolic

    my $string  = lz77_decode($literals, $distances, $lengths);
    my $symbols = lz77_decode_symbolic($literals, $distances, $lengths);

Low-level function that performs LZ77 (Lempel-Ziv 1977) decoding using the provided literals, distances, and lengths of matched sub-strings.

It takes three parameters: C<$literals>, representing the array-ref of uncompressed bytes, C<$distances>, containing the relative back-reference distances of the matched sub-strings, and C<$lengths>, holding the lengths of the matched sub-strings.

Inverse of C<lz77_encode()> and C<lz77_encode_symbolic()>, respectively.

=head2 lzss_encode

    my ($literals, $distances, $lengths) = lzss_encode($data);

Low-level function that applies the LZSS (Lempel-Ziv-Storer-Szymanski) algorithm on the provided data.

The function returns three values: C<$literals>, which is an array-ref of uncompressed bytes, C<$distances>, which contains the relative back-reference distances, and C<$lengths>, which holds the lengths of the matched sub-strings.

The output can be decoded with C<lzss_decode()>.

=head2 lzss_encode_fast

    my ($literals, $distances, $lengths) = lzss_encode_fast($data);

Low-level function that applies a fast variant of LZSS on the provided data.

The function returns three values: C<$literals>, which is an array-ref of uncompressed symbols, C<$distances>, which contains the relative back-reference distances, and C<$lengths>, which holds the lengths of the matched sub-strings.

The output can be decoded with C<lzss_decode()>.

=head2 lzss_decode

    my $string = lzss_decode($literals, $distances, $lengths);

Low-level function that decodes the LZSS encoding, using the provided literals, distances, and lengths of matched sub-strings.

It takes three parameters: C<$literals>, representing the array-ref of uncompressed bytes, C<$distances>, containing the relative back-reference distances of the matched sub-strings, and C<$lengths>, holding the lengths of the matched sub-strings.

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

    my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables($size);

Low-level function that returns a list of tables used in encoding the relative back-reference distances and lengths returned by C<lzss_encode()> and C<lzss_encode_fast()>.

There is no need to call this function explicitly. Use C<deflate_encode()> instead!

=head2 find_deflate_index

    my $index = find_deflate_index($value, $DISTANCE_SYMBOLS);

Low-level function that returns the index inside the DEFLATE tables for a given value.

=head1 EXPORT

Each function can be exported individually, as:

    use Compression::Util qw(bz2_compress);

By specifying the B<:all> keyword, will export all the exportable functions:

    use Compression::Util qw(:all);

Nothing is exported by default.

=head1 SEE ALSO

=over 4

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

=item * My blog post on "Lossless Data Compression":
        L<https://trizenx.blogspot.com/2023/09/lossless-data-compression.html>

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
