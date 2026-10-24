package App::FileSync::Delta;

use strict;
use warnings;

use Digest::SHA ();

# rsync-style block matching.  The receiver describes the file it already has as
# one strong hash per fixed-size block; the sender scans the new file with a
# rolling checksum and emits either a copy of a block the receiver already has
# or the literal bytes that changed.
#
# The scanner is pure Perl, so it is deliberately bounded: only files of at
# least $MIN_SIZE are worth a signature, and at most $SCAN_LIMIT bytes per file
# are examined for matches.  Whatever lies beyond that is sent literally, which
# is still correct, just not smaller.  A small edit in a large file is cheap
# because the unchanged leading blocks are matched without scanning.
our $MIN_SIZE   = 65_536;
our $BLOCK      = 16_384;
our $MAX_BLOCKS = 4_096;
our $SCAN_LIMIT = 8 * 1024 * 1024;
our $LITERAL    = 262_144;

sub block_size {
    my ($size) = @_;

    return $BLOCK unless defined $size && $size > $BLOCK * $MAX_BLOCKS;

    my $block = int(($size + $MAX_BLOCKS - 1) / $MAX_BLOCKS);
    return (int(($block + 1023) / 1024) + 1) * 1024;
}

# Describe a file the receiver already holds: the size, the fixed block length
# and one [weak, strong] pair per full block.  A short final block is not
# included; its bytes are simply never reused.
sub signature {
    my ($path, $block) = @_;

    return undef unless defined $path && length $path && -f $path;

    $block = block_size(-s $path) unless defined $block && $block > 0;
    my $size = -s _;
    return undef unless $size >= $MIN_SIZE;

    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    binmode $fh;

    my @blocks;
    my $offset = 0;
    while ($offset + $block <= $size) {
        my $data = read_exact($fh, $block, $path);
        push @blocks, [ _weak($data), Digest::SHA::sha256($data) ];
        $offset += $block;
    }
    close $fh;

    return {
        size     => $size,
        blocklen => $block,
        blocks   => \@blocks,
    };
}

# One record per block: a big-endian weak checksum then the 32-byte SHA-256.
sub encode_signature {
    my ($signature) = @_;

    return join '', map { pack('N', $_->[0]) . $_->[1] }
        @{ $signature->{blocks} || [] };
}

sub decode_signature {
    my ($bytes, $count) = @_;

    $count = 0 unless defined $count;
    die "Bad signature block count\n" unless $count =~ /\A\d+\z/;

    my $length = defined $bytes ? length $bytes : 0;
    die "Signature is $length bytes, expected " . ($count * 36) . "\n"
        unless $length == $count * 36;

    my @blocks;
    for my $index (0 .. $count - 1) {
        my $record = substr($bytes, $index * 36, 36);
        push @blocks, [ unpack('N', substr($record, 0, 4)), substr($record, 4, 32) ];
    }

    return \@blocks;
}

# Compare $path (the new content) with a signature of what the receiver has and
# write copy/literal records to $out.  Returns byte counts, so the caller can
# decide whether the delta is smaller than sending the file.
sub diff {
    my ($path, $signature, $out) = @_;

    die "Delta: no output handle\n" unless $out;

    my $block = $signature->{blocklen} or die "Delta: signature has no block length\n";
    my $blocks = $signature->{blocks} || [];

    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    binmode $fh;
    my $size = -s $path;

    my $stats = { literal => 0, copy => 0, ops => 0 };
    my $literal = '';

    my $flush = sub {
        return unless length $literal;
        print {$out} 'L' . pack('N', length $literal) . $literal
            or die "Cannot write the delta: $!\n";
        $stats->{literal} += length $literal;
        $stats->{ops}++;
        $literal = '';
        return 1;
    };

    my $copy = sub {
        my ($offset, $length) = @_;
        $flush->();
        print {$out} 'C' . pack('NN', $offset, $length)
            or die "Cannot write the delta: $!\n";
        $stats->{copy} += $length;
        $stats->{ops}++;
        return 1;
    };

    my %by_weak;
    for my $index (0 .. $#{$blocks}) {
        push @{ $by_weak{ $blocks->[$index][0] } }, [ $index, $blocks->[$index][1] ];
    }

    # The leading blocks are usually untouched: compare them directly, which
    # avoids scanning terabyte-sized prefixes a byte at a time.
    my $offset = 0;
    my $prefix = 0;
    my $pending = '';
    while ($prefix < @{$blocks} && $offset + $block <= $size) {
        my $data = read_exact($fh, $block, $path);
        if (Digest::SHA::sha256($data) eq $blocks->[$prefix][1]) {
            $copy->($offset, $block);
            $prefix++;
            $offset += $block;
            next;
        }
        $pending = $data;
        last;
    }

    # Scan at most $SCAN_LIMIT bytes after the prefix.  Reading the window into
    # one string lets the rolling loop use vec() without copying it.
    my $buffer = $pending;
    my $want   = $SCAN_LIMIT + $block;
    while (length($buffer) < $want) {
        my $read = read($fh, my $chunk, $want - length($buffer));
        die "Cannot read $path: $!\n" unless defined $read;
        last if $read == 0;
        $buffer .= $chunk;
    }

    my $limit = length($buffer) - $block;
    if ($limit >= 0) {
        my $last = $limit > $SCAN_LIMIT ? $SCAN_LIMIT : $limit;
        my ($a, $b) = _weak_parts(substr($buffer, 0, $block));
        my $position = 0;

        while ($position <= $last) {
            my $weak = (($b & 0xffff) << 16) | ($a & 0xffff);
            my $winner;

            if (my $candidates = $by_weak{$weak}) {
                my $strong = Digest::SHA::sha256(substr($buffer, $position, $block));
                for my $candidate (@{$candidates}) {
                    next unless $candidate->[1] eq $strong;
                    $winner = $candidate->[0];
                    last;
                }
            }

            if (defined $winner) {
                $copy->($winner * $block, $block);
                $position += $block;
                if ($position <= $last) {
                    ($a, $b) = _weak_parts(substr($buffer, $position, $block));
                }
                next;
            }

            $literal .= substr($buffer, $position, 1);
            $flush->() if length($literal) >= $LITERAL;

            # Roll the window forward one byte, unless this was the last full
            # window in the buffer.  The byte entering the window is the one
            # just past its end.
            if ($position < $last) {
                my $out_byte = vec($buffer, $position, 8);
                my $in_byte  = vec($buffer, $position + $block, 8);
                $a = ($a - $out_byte + $in_byte) & 0xffff;
                $b = ($b - $block * $out_byte + $a) & 0xffff;
            }
            $position++;
        }

        $literal .= substr($buffer, $position) if $position < length($buffer);
        $flush->();
    } else {
        $literal .= $buffer;
        $flush->();
    }

    while (my $read = read($fh, my $chunk, $LITERAL)) {
        $literal .= $chunk;
        $flush->();
    }
    close $fh;

    $stats->{ops} = 0 + $stats->{ops};
    return $stats;
}

# Write one record pair; used by callers that spool a delta themselves.
sub write_copy {
    my ($out, $offset, $length) = @_;
    print {$out} 'C' . pack('NN', $offset, $length)
        or die "Cannot write the delta: $!\n";
    return 1;
}

sub write_literal {
    my ($out, $bytes) = @_;
    return 1 unless defined $bytes && length $bytes;
    print {$out} 'L' . pack('N', length $bytes) . $bytes
        or die "Cannot write the delta: $!\n";
    return 1;
}

# Returns ('copy', offset, length), ('literal', bytes) or () at the end.
sub read_op {
    my ($in) = @_;

    my $type;
    my $read = read($in, $type, 1);
    die "Cannot read the delta: $!\n" unless defined $read;
    return () if $read == 0;
    die "Bad delta record '$type'\n" unless $type eq 'C' || $type eq 'L';

    if ($type eq 'C') {
        my $header = read_exact($in, 8, 'delta');
        my ($offset, $length) = unpack('NN', $header);
        return ('copy', $offset, $length);
    }

    my $header = read_exact($in, 4, 'delta');
    my $length = unpack('N', $header);
    my $bytes  = $length ? read_exact($in, $length, 'delta') : '';
    return ('literal', $bytes);
}

# Apply a spooled delta to a local file, mainly for tests and tools.
sub apply {
    my ($old_path, $in, $out) = @_;

    open my $old, '<', $old_path or die "Cannot read $old_path: $!\n";
    binmode $old;

    my $written = 0;
    while (my ($type, @rest) = read_op($in)) {
        my $bytes;
        if ($type eq 'copy') {
            my ($offset, $length) = @rest;
            seek($old, $offset, 0) or die "Cannot seek in $old_path: $!\n";
            $bytes = $length ? read_exact($old, $length, $old_path) : '';
        } else {
            $bytes = $rest[0];
        }

        print {$out} $bytes or die "Cannot write the restored file: $!\n";
        $written += length $bytes;
    }

    close $old;
    return { size => $written };
}

# rsync's weak checksum: two 16-bit sums, cheap to roll by one byte.
sub _weak_parts {
    my ($window) = @_;

    my $length = length $window;
    my ($a, $b) = (0, 0);
    for my $index (0 .. $length - 1) {
        my $value = vec($window, $index, 8);
        $a += $value;
        $b += ($length - $index) * $value;
    }

    return ($a & 0xffff, $b & 0xffff);
}

sub _weak {
    my ($window) = @_;
    my ($a, $b) = _weak_parts($window);
    return (($b & 0xffff) << 16) | ($a & 0xffff);
}

sub read_exact {
    my ($fh, $length, $what) = @_;

    my $bytes = '';
    while (length($bytes) < $length) {
        my $read = read($fh, my $chunk, $length - length($bytes));
        die "Cannot read $what: $!\n" unless defined $read;
        die "Unexpected end of $what\n" if $read == 0;
        $bytes .= $chunk;
    }

    return $bytes;
}

1;
