package App::FileSync::Delta;

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

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Digest::SHA ();
use Readonly;
use Sub::Private { mode => 'enforce' };

use App::FileSync::I18N qw(throw os_error);
use App::FileSync::IO qw(open_file);

use version; our $VERSION = version->declare('0.001.5');

# Tunables (package variables so tests can shrink them with "local").
our $MIN_SIZE   = 65_536;
our $BLOCK      = 16_384;
our $MAX_BLOCKS = 4_096;
our $SCAN_LIMIT = 8 * 1024 * 1024;
our $LITERAL    = 262_144;

# Wire format of a signature record: a 32-bit weak sum then a SHA-256.
Readonly my $WEAK_BYTES   => 4;
Readonly my $STRONG_BYTES => 32;
Readonly my $RECORD_BYTES => $WEAK_BYTES + $STRONG_BYTES;

# Delta records: "C" + offset + length, or "L" + length + bytes.
Readonly my $COPY        => 'C';
Readonly my $LIT         => 'L';
Readonly my $COPY_HEADER => 8;
Readonly my $LIT_HEADER  => 4;

# Block sizes are rounded to whole kibibytes.
Readonly my $KIB => 1024;

# Each half of the weak checksum is a 16-bit sum.
Readonly my $HALF => 0xffff;

# rsync's weak checksum: two 16-bit sums, cheap to roll by one byte.  Lexical:
# it runs once per block.
my $weak_parts = sub {
	my ($window) = @_;

	my $length = length $window;
	my ($a, $b) = (0, 0);
	for my $index (0 .. $length - 1) {
		my $value = vec($window, $index, 8);
		$a += $value;
		$b += ($length - $index) * $value;
	}

	return ($a & $HALF, $b & $HALF);
};

my $weak = sub {
	my ($a, $b) = $weak_parts->($_[0]);
	return (($b & $HALF) << 16) | ($a & $HALF);
};

=encoding utf8

=head1 NAME

App::FileSync::Delta - rsync-style block deltas in pure Perl

=head1 SYNOPSIS

	my $signature = App::FileSync::Delta::signature($old_path);
	App::FileSync::Delta::diff($new_path, $signature, $spool);
	seek $spool, 0, 0;
	App::FileSync::Delta::apply($old_path, $spool, $out);

=head1 FUNCTIONS

=head2 block_size

Purpose: the block length for a file of a given size.

Args: C<$size> in bytes.

Returns: C<$BLOCK> (16 KiB) for files up to C<$BLOCK * $MAX_BLOCKS>; above that,
a larger whole-KiB block so the signature stays at most about C<$MAX_BLOCKS>
records.

Side Effects: none.

Usage:

	my $block = App::FileSync::Delta::block_size(-s $path);

=head3 EXAMPLE

	print App::FileSync::Delta::block_size(1_000_000), "\n";	# 16384

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'size', type => 'integer', min => 0, optional => 1 } ]

=head4 OUTPUT

	{ type => 'integer', min => 1024 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	block_size(s) = BLOCK                                   if s ≤ BLOCK × MAX_BLOCKS
	              = (⌈⌈s / MAX_BLOCKS⌉ / 1024⌉ + 1) × 1024    otherwise

=cut

sub block_size {
	my ($size) = @_;

	my $per_block = (defined $size && $size > $BLOCK * $MAX_BLOCKS)
		? int(($size + $MAX_BLOCKS - 1) / $MAX_BLOCKS)
		: undef;

	return defined $per_block ? (int(($per_block + $KIB - 1) / $KIB) + 1) * $KIB : $BLOCK;
}

=head2 signature

Purpose: describe a file the receiver already holds.

Args: C<$path>, optional C<$block> length (default L</block_size>).

Returns: C<{ size, blocklen, blocks =E<gt> [ [ weak, strong ], ... ] }>, one pair
per full block (a short final block is not included; its bytes are simply never
reused), or C<undef> for a missing file or one smaller than C<$MIN_SIZE>.

Side Effects: reads the file.

Usage:

	my $signature = App::FileSync::Delta::signature($abs) or return 0;

=head3 EXAMPLE

	my $sig = App::FileSync::Delta::signature('/tmp/big.iso');
	printf "%d blocks of %d bytes\n", scalar @{ $sig->{blocks} }, $sig->{blocklen} if $sig;

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'path',  type => 'string', optional => 1 },
		{ name => 'block', type => 'integer', min => 1, optional => 1 },
	]

=head4 OUTPUT

	{ type => 'hashref', optional => 1 }

=head3 MESSAGES

	Key        Meaning                    Resolution
	io.read    the file cannot be read    check permissions

=head3 FORMAL SPECIFICATION

	signature(p, b) = ⊥                                    if p ∉ dom FS ∨ #FS(p) < MIN_SIZE
	                = ⟨size ↦ #F, blocklen ↦ b,
	                   blocks ↦ ⟨(weak(F[i]), sha256(F[i])) | i ∈ 0 .. ⌊#F / b⌋ − 1⟩⟩
	                  where F = FS(p), F[i] = bytes i×b .. (i+1)×b − 1

=cut

sub signature {
	my ($path, $block) = @_;

	return undef unless defined $path && length $path && -f $path;	## no critic (Subroutines::ProhibitExplicitReturnUndef)
	my $size = -s _;
	return undef unless $size >= $MIN_SIZE;	## no critic (Subroutines::ProhibitExplicitReturnUndef)

	$block = block_size($size) unless defined $block && $block > 0;

	my $fh = open_file($path, '<');
	my @blocks;
	for (1 .. int($size / $block)) {
		my $data = read_exact($fh, $block, $path);
		push @blocks, [ $weak->($data), Digest::SHA::sha256($data) ];
	}
	close $fh;

	return { size => $size, blocklen => $block, blocks => \@blocks };
}

=head2 encode_signature

Documented with L</decode_signature> below.

=head2 decode_signature

Purpose: put a signature's blocks on the wire and take them off again.

Args: C<encode_signature($signature)>; C<decode_signature($bytes, $count)>.

Returns: the encoded bytes (36 per block: a big-endian weak sum then the
32-byte SHA-256); the decoded arrayref of C<[ weak, strong ]> pairs.

Side Effects: none.

Usage:

	my $bytes = App::FileSync::Delta::encode_signature($signature);
	my $blocks = App::FileSync::Delta::decode_signature($bytes, $count);

=head3 EXAMPLE

	my $blocks = App::FileSync::Delta::decode_signature(
		App::FileSync::Delta::encode_signature($sig), scalar @{ $sig->{blocks} });

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'bytes', type => 'string', optional => 1 },
		{ name => 'count', type => 'integer', min => 0, optional => 1 },
	]

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	Key               Meaning                              Resolution
	delta.bad_count   the block count is not a number      a peer bug; resync with --no-delta
	delta.bad_length  the bytes do not match the count     a peer bug; resync with --no-delta

=head3 FORMAL SPECIFICATION

	encode(⟨(w₁,s₁), …, (wₙ,sₙ)⟩) = be32(w₁) ⁀ s₁ ⁀ … ⁀ be32(wₙ) ⁀ sₙ
	decode(encode(bs), #bs) = bs
	pre decode: #bytes = 36 × count

=cut

sub encode_signature {
	my ($signature) = @_;

	return join '', map { pack('N', $_->[0]) . $_->[1] } @{ $signature->{blocks} || [] };
}

sub decode_signature {
	my ($bytes, $count) = @_;

	$count = 0 unless defined $count;
	throw('delta.bad_count', { count => $count }) unless $count =~ /\A\d+\z/;

	my $length = defined $bytes ? length $bytes : 0;
	throw('delta.bad_length', { length => $length, expected => $count * $RECORD_BYTES })
		unless $length == $count * $RECORD_BYTES;

	my @blocks = map {
		my $record = substr($bytes, $_ * $RECORD_BYTES, $RECORD_BYTES);
		[ unpack('N', substr($record, 0, $WEAK_BYTES)), substr($record, $WEAK_BYTES, $STRONG_BYTES) ];
	} 0 .. $count - 1;

	return \@blocks;
}

=head2 diff

Purpose: write the delta that turns the receiver's file into C<$path>.

Args: C<$path> (the new content), C<$signature> (of what the receiver has;
C<blocklen> and C<blocks> are used), C<$out> (a writable handle).

Returns: C<{ literal, copy, ops }>: bytes sent literally, bytes copied, and
records written, so the caller can decide whether the delta beats the file.

Side Effects: reads C<$path>; writes copy and literal records to C<$out>.

Usage:

	my $stats = App::FileSync::Delta::diff($abs, $signature, $spool);

=head3 EXAMPLE

	open my $spool, '+>', undef;
	my $stats = App::FileSync::Delta::diff('/tmp/new.bin', $sig, $spool);
	printf "%d literal bytes in %d records\n", $stats->{literal}, $stats->{ops};

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'path',      type => 'string', min => 1 },
		{ name => 'signature', type => 'hashref' },
		{ name => 'out',       type => 'handle' },
	]

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			literal => { type => 'integer', min => 0 },
			copy    => { type => 'integer', min => 0 },
			ops     => { type => 'integer', min => 0 },
		},
	}

=head3 MESSAGES

	Key                  Meaning                              Resolution
	delta.no_output      no output handle                     a caller bug
	delta.no_block       the signature has no block length    a peer bug
	delta.write          the delta cannot be written          check space for the spool
	io.read              the new file cannot be read          check permissions

=head3 FORMAL SPECIFICATION

	let R = records written to out
	apply(old, R) = FS(path)                (correctness)
	literal = Σ { #l | L(l) ∈ R } ; copy = Σ { n | C(o, n) ∈ R } ; ops = #R
	literal + copy = #FS(path)

=head3 PSEUDOCODE

	index the receiver's blocks by weak checksum
	while the next full block equals the receiver's block at the same index:
		emit a copy of it (no rolling needed for an unchanged prefix)
	read up to SCAN_LIMIT more bytes into a window buffer
	slide a one-block window through the buffer:
		if its weak sum is indexed and the strong hash matches a block:
			emit a copy, jump a whole block
		else: add one byte to the literal run, roll the sums forward one byte
	flush the rest of the buffer and the unscanned tail as literals

=cut

sub diff {
	my ($path, $signature, $out) = @_;

	throw('delta.no_output') unless $out;
	my $block = $signature->{blocklen} or throw('delta.no_block');
	my $blocks = $signature->{blocks} || [];

	my $fh = open_file($path, '<');
	my $state = {
		out     => $out,
		path    => $path,
		block   => $block,
		literal => '',
		stats   => { literal => 0, copy => 0, ops => 0 },
	};

	my $pending = _match_prefix($state, $fh, $blocks, -s $path);
	my $buffer  = _fill_window($fh, $pending, $SCAN_LIMIT + $block, $path);
	_rolling_scan($state, $buffer, $blocks);

	# Everything past the scanned window goes literally.
	# length(), not truth: a final chunk of "0" is still data.
	while (length(my $chunk = _read_some($fh, $LITERAL, $path))) {
		_add_literal($state, $chunk);
	}
	_flush($state);
	close $fh;

	return $state->{stats};
}

=head2 write_copy

Documented with L</write_literal> below.

=head2 write_literal

Purpose: write one delta record.

Args: C<write_copy($out, $offset, $length)>; C<write_literal($out, $bytes)>
(an empty literal writes nothing).

Returns: 1.

Side Effects: writes to C<$out>.

Usage:

	App::FileSync::Delta::write_copy($spool, $offset, $length);
	App::FileSync::Delta::write_literal($spool, $bytes);

=head3 EXAMPLE

	App::FileSync::Delta::write_literal($out, "new text\n");

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'out',    type => 'handle' },
		{ name => 'offset', type => 'integer', min => 0 },
		{ name => 'length', type => 'integer', min => 0 },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

	Key           Meaning                      Resolution
	delta.write   the record cannot be written  check space for the spool

=head3 FORMAL SPECIFICATION

	write_copy(o, n): out' = out ⁀ "C" ⁀ be32(o) ⁀ be32(n)
	write_literal(b): out' = out ⁀ "L" ⁀ be32(#b) ⁀ b    if b ≠ ⟨⟩

=cut

sub write_copy {
	my ($out, $offset, $length) = @_;

	print {$out} $COPY . pack('NN', $offset, $length) or throw('delta.write', { error => "$!" });
	return 1;
}

sub write_literal {
	my ($out, $bytes) = @_;

	if (defined $bytes && length $bytes) {
		print {$out} $LIT . pack('N', length $bytes) . $bytes or throw('delta.write', { error => "$!" });
	}
	return 1;
}

=head2 read_op

Purpose: read the next delta record.

Args: C<$in>, a handle positioned at a record.

Returns: C<('copy', $offset, $length)>, C<('literal', $bytes)>, or the empty
list at the end.  A list because callers loop with
C<while (my ($type, @rest) = read_op($in))>.

Side Effects: advances C<$in>.

Usage:

	while (my ($type, @rest) = App::FileSync::Delta::read_op($spool)) { ... }

=head3 EXAMPLE

	my ($type, $offset, $length) = App::FileSync::Delta::read_op($spool);

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'in', type => 'handle' } ]

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	Key                 Meaning                         Resolution
	delta.read          the delta cannot be read        check the spool
	delta.bad_record    an unknown record type          a peer bug; resync with --no-delta
	io.short            the delta ends mid-record       a peer bug; resync with --no-delta

=head3 FORMAL SPECIFICATION

	read_op("C" ⁀ be32(o) ⁀ be32(n) ⁀ rest) = (copy, o, n)
	read_op("L" ⁀ be32(k) ⁀ b ⁀ rest) = (literal, b)    where #b = k
	read_op(⟨⟩) = ⟨⟩

=cut

sub read_op {
	my ($in) = @_;

	my $type = _read_some($in, 1, 'delta', 'delta.read');
	return () unless length $type;
	throw('delta.bad_record', { type => $type }) unless $type eq $COPY || $type eq $LIT;

	return ('copy', unpack('NN', read_exact($in, $COPY_HEADER, 'delta'))) if $type eq $COPY;

	my $length = unpack('N', read_exact($in, $LIT_HEADER, 'delta'));
	return ('literal', $length ? read_exact($in, $length, 'delta') : '');
}

=head2 apply

Purpose: rebuild a file from the old copy and a spooled delta.

Args: C<$old_path>, C<$in> (the delta), C<$out> (where the new content goes).

Returns: C<{ size }>, the bytes written.

Side Effects: reads C<$old_path> and C<$in>; writes C<$out>.

Usage:

	my $result = App::FileSync::Delta::apply($old, $spool, $out);

=head3 EXAMPLE

	open my $out, '>', '/tmp/rebuilt.bin';
	App::FileSync::Delta::apply('/tmp/old.bin', $spool, $out);

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'old_path', type => 'string', min => 1 },
		{ name => 'in',       type => 'handle' },
		{ name => 'out',      type => 'handle' },
	]

=head4 OUTPUT

	{ type => 'hashref', schema => { size => { type => 'integer', min => 0 } } }

=head3 MESSAGES

	Key                   Meaning                            Resolution
	io.read               the old file cannot be read        check permissions
	io.seek               a copy points outside the file     the delta does not fit this file
	delta.write_restored  the output cannot be written       check space

=head3 FORMAL SPECIFICATION

	apply(old, R) = ⁀/ ⟨ bytes(r) | r ← R ⟩
	  where bytes(C(o, n)) = FS(old)[o .. o + n − 1], bytes(L(b)) = b

=cut

sub apply {
	my ($old_path, $in, $out) = @_;

	my $old = open_file($old_path, '<');
	my $written = 0;

	while (my ($type, @rest) = read_op($in)) {
		my $bytes = $type eq 'copy' ? _copy_from($old, @rest, $old_path) : $rest[0];
		print {$out} $bytes or throw('delta.write_restored', { error => "$!" });
		$written += length $bytes;
	}

	close $old;
	return { size => $written };
}

=head2 read_exact

Purpose: read exactly C<$length> bytes.

Args: C<$fh>, C<$length>, C<$what> (named in errors).

Returns: the bytes.

Side Effects: advances C<$fh>.

Usage:

	my $data = App::FileSync::Delta::read_exact($fh, $block, $path);

=head3 EXAMPLE

	my $header = App::FileSync::Delta::read_exact($spool, 8, 'delta');

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'fh',     type => 'handle' },
		{ name => 'length', type => 'integer', min => 0 },
		{ name => 'what',   type => 'string' },
	]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

	Key        Meaning                         Resolution
	io.read    the read failed                 check the device
	io.short   fewer bytes than required       the file was truncated

=head3 FORMAL SPECIFICATION

	read_exact(fh, n, w) = take(n, rest(fh))   if #rest(fh) ≥ n
	                     ↑ io.short           otherwise

=cut

sub read_exact {
	my ($fh, $length, $what) = @_;

	my $bytes = '';
	while (length($bytes) < $length) {
		my $chunk = _read_some($fh, $length - length($bytes), $what);
		throw('io.short', { path => $what }) unless length $chunk;
		$bytes .= $chunk;
	}

	return $bytes;
}

# _read_some
# Purpose:     one read() that reports failure with a catalogued message.
# Entry:       $fh is readable; $want > 0.
# Exit:        returns the bytes read ('' at end of file).
# Side effects: advances $fh; raises $key (default io.read) on error.
sub _read_some :Private {
	my ($fh, $want, $what, $key) = @_;

	my $chunk;
	eval { read($fh, $chunk, $want); 1 }
		or throw($key || 'io.read', { path => $what, error => os_error($@) });

	return defined $chunk ? $chunk : '';
}

# _copy_from
# Purpose:     the bytes a copy record refers to in the old file.
# Entry:       $old is the old file's handle.
# Exit:        returns $length bytes from $offset.
# Side effects: moves $old's position; raises io.seek or io.short.
sub _copy_from :Private {
	my ($old, $offset, $length, $old_path) = @_;

	eval { seek($old, $offset, 0); 1 }
		or throw('io.seek', { path => $old_path, error => os_error($@) });

	return $length ? read_exact($old, $length, $old_path) : '';
}

# _match_prefix
# Purpose:     copy the unchanged leading blocks without rolling a checksum.
# Entry:       $fh is at offset 0 of the new file; $size is its length.
# Exit:        returns the first block that did not match ('' if none), which
#              the rolling scan must start from.
# Side effects: writes copy records; advances $fh.
sub _match_prefix :Private {
	my ($state, $fh, $blocks, $size) = @_;

	my $block = $state->{block};
	my $offset = 0;

	# The leading blocks are usually untouched: compare them directly, which
	# avoids scanning terabyte-sized prefixes a byte at a time.
	for my $index (0 .. $#{$blocks}) {
		last if $offset + $block > $size;
		my $data = read_exact($fh, $block, $state->{path});
		return $data unless Digest::SHA::sha256($data) eq $blocks->[$index][1];

		_add_copy($state, $offset, $block);
		$offset += $block;
	}

	return '';
}

# _fill_window
# Purpose:     read the region the rolling scan examines into one string.
# Entry:       $pending is data already read; $want the window size.
# Exit:        returns up to $want bytes (less at end of file).
# Side effects: advances $fh.  One string lets the loop use vec() without
#              copying.
sub _fill_window :Private {
	my ($fh, $pending, $want, $path) = @_;

	my $buffer = $pending;
	while (length($buffer) < $want) {
		my $chunk = _read_some($fh, $want - length($buffer), $path);
		last unless length $chunk;
		$buffer .= $chunk;
	}

	return $buffer;
}

# _rolling_scan
# Purpose:     find the receiver's blocks anywhere in the window.
# Entry:       $buffer is the window; $blocks the receiver's signature.
# Exit:        returns 1.
# Side effects: writes copy and literal records for the whole buffer.
sub _rolling_scan :Private {
	my ($state, $buffer, $blocks) = @_;

	my $block = $state->{block};
	my $limit = length($buffer) - $block;

	# Shorter than one block: nothing can match.
	if ($limit < 0) {
		_add_literal($state, $buffer);
		return 1;
	}

	my %by_weak;
	push @{ $by_weak{ $blocks->[$_][0] } }, [ $_, $blocks->[$_][1] ] for 0 .. $#{$blocks};

	my $last = $limit > $SCAN_LIMIT ? $SCAN_LIMIT : $limit;
	my ($a, $b) = $weak_parts->(substr($buffer, 0, $block));
	my $position = 0;

	while ($position <= $last) {
		my $winner = _strong_match(\%by_weak, (($b & $HALF) << 16) | ($a & $HALF), $buffer, $position, $block);

		if (defined $winner) {
			_add_copy($state, $winner * $block, $block);
			$position += $block;
			($a, $b) = $weak_parts->(substr($buffer, $position, $block)) if $position <= $last;
			next;
		}

		_add_literal($state, substr($buffer, $position, 1));

		# Roll the window forward one byte, unless this was the last full
		# window in the buffer.  The byte entering the window is the one just
		# past its end.
		if ($position < $last) {
			my $out_byte = vec($buffer, $position, 8);
			my $in_byte  = vec($buffer, $position + $block, 8);
			$a = ($a - $out_byte + $in_byte) & $HALF;
			$b = ($b - $block * $out_byte + $a) & $HALF;
		}
		$position++;
	}

	_add_literal($state, substr($buffer, $position)) if $position < length($buffer);
	return 1;
}

# _strong_match
# Purpose:     confirm a weak-checksum hit with the strong hash.
# Entry:       $by_weak maps weak sums to [ index, sha256 ] candidates.
# Exit:        returns the matching block index, or undef.
# Side effects: none.
sub _strong_match :Private {
	my ($by_weak, $weak_sum, $buffer, $position, $block) = @_;

	my $candidates = $by_weak->{$weak_sum} or return undef;	## no critic (Subroutines::ProhibitExplicitReturnUndef)
	my $strong = Digest::SHA::sha256(substr($buffer, $position, $block));
	my ($hit) = grep { $_->[1] eq $strong } @{$candidates};

	return $hit ? $hit->[0] : undef;
}

# _add_copy
# Purpose:     emit a copy record, flushing any pending literal first.
# Entry:       $offset/$length name bytes in the receiver's file.
# Exit:        returns 1.
# Side effects: writes to the output; updates the stats.
sub _add_copy :Private {
	my ($state, $offset, $length) = @_;

	_flush($state);
	write_copy($state->{out}, $offset, $length);
	$state->{stats}{copy} += $length;
	$state->{stats}{ops}++;

	return 1;
}

# _add_literal
# Purpose:     queue literal bytes, writing a record once enough accumulate.
# Entry:       $bytes may be empty.
# Exit:        returns 1.
# Side effects: may write to the output.
sub _add_literal :Private {
	my ($state, $bytes) = @_;

	$state->{literal} .= $bytes;
	_flush($state) if length($state->{literal}) >= $LITERAL;

	return 1;
}

# _flush
# Purpose:     write the queued literal bytes as one record.
# Entry:       $state->{literal} may be empty.
# Exit:        returns 1.
# Side effects: writes to the output; updates the stats.
sub _flush :Private {
	my ($state) = @_;

	my $length = length $state->{literal};
	if ($length) {
		write_literal($state->{out}, $state->{literal});
		$state->{stats}{literal} += $length;
		$state->{stats}{ops}++;
		$state->{literal} = '';
	}

	return 1;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Pure Perl: the rolling loop runs at a few MB/s, which is why only
C<$SCAN_LIMIT> bytes after the matched prefix are scanned.  An edit near the
end of a large file whose earlier blocks also shifted is sent mostly
literally.

=item * A block that moved by a whole number of blocks is found; a block that
occurs twice in the receiver's file is matched to its first occurrence.

=item * Offsets and lengths are 32-bit on the wire, so a delta cannot refer
beyond 4 GiB into the receiver's file; larger files fall back to whole-file
transfer of the remainder as literals.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
