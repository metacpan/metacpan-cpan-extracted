use strict;
use warnings;
use Test::Most;
use Test::Exception;

use File::Temp qw(tempdir);
use File::Spec;

use lib 't/lib';
use TestSync;

use App::FileSync::Delta;
use App::FileSync::Protocol;

sub write_raw {
	my ($path, $content) = @_;
	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print {$fh} $content;
	close $fh;
	return $path;
}

sub slurp {
	my ($path) = @_;
	open my $fh, '<', $path or die "Cannot read $path: $!";
	binmode $fh;
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

sub text_file {
	my ($lines) = @_;
	return join '', map { sprintf("%05d: the quick brown fox jumps over the lazy dog\n", $_) }
		1 .. $lines;
}

# ------------------------------------------------------------------ signatures

{
	my $dir = tempdir(CLEANUP => 1);
	my $old = write_raw(File::Spec->catfile($dir, 'old.bin'), text_file(8_000));

	my $signature = App::FileSync::Delta::signature($old);
	ok($signature, 'a signature is produced for a large file');
	is($signature->{size}, -s $old, 'the signature records the size');
	ok($signature->{blocklen} >= 1024, 'the block length is usable');
	is(scalar @{ $signature->{blocks} },
		int($signature->{size} / $signature->{blocklen}), 'one block per full block');

	my $encoded = App::FileSync::Delta::encode_signature($signature);
	is(length($encoded), 36 * @{ $signature->{blocks} }, 'each block is a weak sum and a SHA-256');

	my $decoded = App::FileSync::Delta::decode_signature($encoded, scalar @{ $signature->{blocks} });
	is_deeply($decoded, $signature->{blocks}, 'the signature round-trips');

	throws_ok { App::FileSync::Delta::decode_signature($encoded, 1) }
		qr/expected 36/, 'a truncated signature is refused';

	ok(App::FileSync::Delta::block_size(10_000_000) >= 16_384, 'small files keep the base block');
	ok(App::FileSync::Delta::block_size(1_000_000_000) > 16_384,
		'very large files use larger blocks to bound the signature');
}

# ----------------------------------------------------------------------- deltas

{
	my $dir = tempdir(CLEANUP => 1);
	my $old_content = text_file(10_000);
	my $new_content = $old_content;
	substr($new_content, 120_000, 0, "inserted in the middle\n");
	substr($new_content, 250_000, 10, "replaced!!");
	substr($new_content, 350_000, 20, '');

	my $old = write_raw(File::Spec->catfile($dir, 'old.txt'), $old_content);
	my $new = write_raw(File::Spec->catfile($dir, 'new.txt'), $new_content);
	my $spool_path = File::Spec->catfile($dir, 'delta');
	open my $spool, '>', $spool_path or die $!;
	binmode $spool;

	my $signature = App::FileSync::Delta::signature($old);
	my $stats = App::FileSync::Delta::diff($new, $signature, $spool);
	close $spool;

	ok($stats->{copy} > 0, 'unchanged blocks are copied');
	ok($stats->{literal} > 0, 'changed bytes are sent literally');
	ok($stats->{literal} < length($new_content) / 2, 'most of the file is reused');
	ok(-s $spool_path < length($old_content) / 2, 'the delta is much smaller than the file');

	open my $in, '<', $spool_path or die $!;
	binmode $in;
	my $out_path = File::Spec->catfile($dir, 'restored.txt');
	open my $out, '>', $out_path or die $!;
	binmode $out;
	my $applied = App::FileSync::Delta::apply($old, $in, $out);
	close $out;
	close $in;

	is($applied->{size}, length $new_content, 'apply reports the size');
	is(slurp($out_path), $new_content, 'copy and literal records rebuild the file exactly');
}

{
	my $dir = tempdir(CLEANUP => 1);
	my $content = text_file(8_000);
	my $old = write_raw(File::Spec->catfile($dir, 'same.txt'), $content);
	my $spool_path = File::Spec->catfile($dir, 'same.delta');
	open my $spool, '>', $spool_path or die $!;
	binmode $spool;

	my $signature = App::FileSync::Delta::signature($old);
	my $stats = App::FileSync::Delta::diff($old, $signature, $spool);
	close $spool;

	# Only full blocks are described by the signature, so the short final block
	# is sent literally; it is at most one block.
	is($stats->{literal}, length($content) % $signature->{blocklen},
		'only the short final block is literal');
	ok($stats->{copy} > length($content) / 2, 'an unchanged file is nearly all copies');
	ok(-s $spool_path < 32 * 1024, 'an unchanged file produces a tiny delta');

	open my $in, '<', $spool_path or die $!;
	binmode $in;
	my $out_path = File::Spec->catfile($dir, 'copy.txt');
	open my $out, '>', $out_path or die $!;
	binmode $out;
	App::FileSync::Delta::apply($old, $in, $out);
	close $out;
	close $in;
	is(slurp($out_path), $content, 'copy-only deltas restore the file');
}

{
	my $dir = tempdir(CLEANUP => 1);
	my $old = write_raw(File::Spec->catfile($dir, 'a.bin'), join '', map { chr(($_ * 7) % 256) } 1 .. 300_000);
	my $new_content = join '', map { chr(($_ * 13 + 5) % 256) } 1 .. 300_000;
	my $new = write_raw(File::Spec->catfile($dir, 'b.bin'), $new_content);

	open my $spool, '>', File::Spec->catfile($dir, 'diff') or die $!;
	binmode $spool;
	my $stats = App::FileSync::Delta::diff($new, App::FileSync::Delta::signature($old), $spool);
	close $spool;

	is($stats->{copy}, 0, 'an unrelated file reuses no blocks');
	is($stats->{literal}, length $new_content, 'an unrelated file is sent literally');
}

{
	my $dir = tempdir(CLEANUP => 1);
	my $old = write_raw(File::Spec->catfile($dir, 'old.txt'), text_file(8_000));
	my $empty = write_raw(File::Spec->catfile($dir, 'empty.txt'), '');

	open my $spool, '>', File::Spec->catfile($dir, 'empty.delta') or die $!;
	binmode $spool;
	my $stats = App::FileSync::Delta::diff($empty, App::FileSync::Delta::signature($old), $spool);
	close $spool;

	is($stats->{copy}, 0, 'an empty file copies nothing');
	is($stats->{literal}, 0, 'an empty file sends no literal bytes');
}

{
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, 'broken');
	write_raw($path, 'L' . pack('N', 10));

	open my $in, '<', $path or die $!;
	binmode $in;
	throws_ok { App::FileSync::Delta::read_op($in) } qr/Unexpected end/,
		'a truncated literal record is refused';
}

# ------------------------------------------------------------------ compression

{
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, 'frames');
	open my $out, '+>', $path or die $!;
	binmode $out;

	my $writer = App::FileSync::Protocol->new(in => $out, out => $out);
	my $text = ("the quick brown fox jumps over the lazy dog\n" x 500);
	my $random = join '', map { chr(int(rand(256))) } 1 .. 4_000;

	$writer->send_data({ cmd => 'chunk', p => 'text' }, $text);
	$writer->send_data({ cmd => 'chunk', p => 'random' }, $random);
	$writer->send_data({ cmd => 'chunk', p => 'empty' }, '');
	$writer->send_data({ cmd => 'chunk', p => 'tiny' }, 'tiny');
	$writer->send({ cmd => 'control' });

	seek($out, 0, 0) or die $!;
	my $reader = App::FileSync::Protocol->new(in => $out, out => $out);

	my $text_header = $reader->recv();
	is($reader->read_data($text_header), $text, 'compressible bytes survive the wire');
	ok($text_header->{z}, 'compressible bytes are deflated');
	ok($text_header->{len} < length($text) / 4, 'deflate actually shrinks them');

	my $random_header = $reader->recv();
	is($reader->read_data($random_header), $random, 'incompressible bytes survive the wire');
	ok(!$random_header->{z}, 'incompressible bytes are left alone');
	is($random_header->{len}, length($random), 'they are sent at their original size');

	my $empty_header = $reader->recv();
	is($reader->read_data($empty_header), '', 'an empty payload round-trips');
	is($empty_header->{len}, 0, 'an empty payload has no bytes on the wire');

	my $tiny_header = $reader->recv();
	is($reader->read_data($tiny_header), 'tiny', 'a small payload round-trips');
	ok(!$tiny_header->{z}, 'a small payload is not compressed');

	is($reader->recv()->{cmd}, 'control', 'control messages are unaffected');

	my $wire = $text_header->{len} + $random_header->{len}
		+ $empty_header->{len} + $tiny_header->{len};
	is($writer->bytes_sent, $wire, 'sent payload bytes are counted at their wire size');
	is($reader->bytes_received, $wire, 'received payload bytes are counted too');
}

# --------------------------------------------------------------- through a sync

{
	my $env = TestSync->new_env();

	my $base = text_file(8_000);
	$env->write_file('client', 'big.txt', $base, 1_700_000_000);

	my $initial = $env->sync();
	is($initial->{summary}{pushed}, 1, 'the first push has no old blocks to reuse');
	is($initial->{summary}{delta_pushed}, 0, 'a new file is sent whole');
	ok($initial->{summary}{bytes_sent} > 0, 'the first push accounts for the bytes it sent');
	is($initial->{summary}{bytes_received}, 0, 'and for the nothing it received');

	my $edited = $base;
	substr($edited, 180_000, 30, 'EDITED-IN-THE-MIDDLE-OF-FILE!!');
	$env->write_file('client', 'big.txt', $edited, 1_700_000_100);

	my $push = $env->sync();
	is($push->{summary}{pushed}, 1, 'the edited file is pushed');
	is($push->{summary}{delta_pushed}, 1, 'the push sends only the changed blocks');
	ok($push->{summary}{bytes_sent} < length($edited) / 4,
		'the delta push puts far fewer bytes on the wire than the file holds');
	is($env->read_file('server', 'big.txt'), $edited, 'the master is rebuilt exactly');

	my $server_edit = $edited;
	substr($server_edit, 40_000, 25, 'CHANGED-ON-THE-SERVER!!!');
	$env->write_file('server', 'big.txt', $server_edit, 1_700_000_200);

	my $pull = $env->sync();
	is($pull->{summary}{pulled}, 1, 'the master edit is pulled');
	is($pull->{summary}{delta_pulled}, 1, 'the pull receives only the changed blocks');
	ok($pull->{summary}{bytes_received} < length($server_edit) / 4,
		'the delta pull receives far fewer bytes than the file holds');
	is($env->read_file('client', 'big.txt'), $server_edit, 'the client is rebuilt exactly');

	my $stable = $env->sync();
	is($stable->{summary}{pulled}, 0, 'nothing is pulled once both sides agree');
	is($stable->{summary}{pushed}, 0, 'nothing is pushed once both sides agree');
	is($stable->{summary}{delta_pulled}, 0, 'no delta is attempted for an unchanged file');
	is($stable->{summary}{bytes_sent}, 0, 'a settled run sends no payload');
	is($stable->{summary}{bytes_received}, 0, 'and receives none');

	my @journal = glob(File::Spec->catfile($env->{server}, '.filesync', 'repos', 'docs',
		'journal', '*.jsonl'));
	my $text = slurp($journal[0]);
	like($text, qr/"delta":1/, 'the journal records that the push was a delta');

	# A small file still takes the whole-file path and arrives intact.
	# --no-delta still converges, just with whole files.
	my $whole = $server_edit;
	substr($whole, 90_000, 20, 'FORCED-WHOLE-FILE!!');
	$env->write_file('client', 'big.txt', $whole, 1_700_000_400);
	my $forced = $env->sync(no_delta => 1);
	is($forced->{summary}{pushed}, 1, 'the edited file is still pushed');
	is($forced->{summary}{delta_pushed}, 0, '--no-delta sends the whole file');
	cmp_ok($forced->{summary}{bytes_sent}, '>', $push->{summary}{bytes_sent},
		'the whole file costs more on the wire than the delta did');
	is($env->read_file('server', 'big.txt'), $whole, 'the whole-file path delivers the edit');

	my $small = "small\r\nfile\r\n";
	$env->write_file('client', 'small.txt', $small, 1_700_000_300);
	$env->sync();
	$env->write_file('client', 'small.txt', "small\r\nchanged\r\n", 1_700_000_310);
	my $small_result = $env->sync();
	is($small_result->{summary}{delta_pushed}, 0, 'a small file is not delta-scanned');
	is($small_result->{summary}{bytes_sent}, length("small\r\nchanged\r\n"),
		'a small file is accounted for byte for byte');
	is($env->read_file('server', 'small.txt'), "small\r\nchanged\r\n",
		'the small file still syncs');
}

{
	my $env = TestSync->new_env();

	my $base = text_file(6_000);
	$env->write_file('client', 'gone.txt', $base, 1_700_000_000);
	$env->sync();

	# The client deleted its copy, so there is no old content to reuse.
	unlink $env->client_path('gone.txt');
	my $server_edit = $base;
	substr($server_edit, 20_000, 10, 'server-edit');
	$env->write_file('server', 'gone.txt', $server_edit, 1_700_000_100);

	my $result = $env->sync();
	is($result->{summary}{pulled}, 1, 'the master edit is pulled');
	is($result->{summary}{delta_pulled}, 0, 'a missing local file falls back to a whole pull');
	is($env->read_file('client', 'gone.txt'), $server_edit, 'the fallback still delivers the file');
}

# ------------------------------------------------- weak sums and literal runs

# The weak sum is on the wire, so it must stay rsync's definition however it
# is computed: a = sum of the bytes, b = sum of (length - i) * byte[i], each
# mod 2**16.  The 200,000-byte block is longer than the slice the sum unpacks
# at a time, and the 0xff block makes b as large as it can be.
{
	my $reference = sub {
		my ($bytes) = @_;
		my ($a, $b, $length) = (0, 0, length $bytes);
		for my $index (0 .. $length - 1) {
			my $value = ord substr($bytes, $index, 1);
			$a = ($a + $value) % 65_536;
			$b = ($b + ($length - $index) * $value) % 65_536;
		}
		return $b * 65_536 + $a;
	};

	my $dir = tempdir(CLEANUP => 1);
	srand 11;
	my %contents = (
		random => join('', map { chr int rand 256 } 1 .. 400_000),
		ff     => "\xff" x 400_000,
		text   => text_file(8_000),
	);
	for my $name (sort keys %contents) {
		my $path = write_raw(File::Spec->catfile($dir, "$name.bin"), $contents{$name});
		for my $block (1_024, 200_000) {
			my $signature = App::FileSync::Delta::signature($path, $block);
			my @expected = map { $reference->(substr($contents{$name}, $_ * $block, $block)) }
				0 .. $#{ $signature->{blocks} };
			is_deeply([ map { $_->[0] } @{ $signature->{blocks} } ], \@expected,
				"$name, $block-byte blocks: the weak sums follow rsync's definition");
		}
	}
}

# The rolling scan queues each unmatched run in one piece; it must still be
# written as records of at most $LITERAL bytes, and rebuild exactly.
{
	my $dir = tempdir(CLEANUP => 1);
	srand 12;
	my $old_content = join '', map { chr int rand 256 } 1 .. 300_000;
	my $new_content = substr($old_content, 0, 5_000) . ('XYZ' x 3_000) . substr($old_content, 9_000) . ('tail' x 10);
	my $old = write_raw(File::Spec->catfile($dir, 'old.bin'), $old_content);
	my $new = write_raw(File::Spec->catfile($dir, 'new.bin'), $new_content);

	for my $limit (7, 1_000) {
		local $App::FileSync::Delta::LITERAL = $limit;
		my $signature = App::FileSync::Delta::signature($old, 1_024);
		my $spool_path = File::Spec->catfile($dir, "spool-$limit");
		open my $spool, '+>', $spool_path or die "Cannot write $spool_path: $!";
		binmode $spool;
		my $stats = App::FileSync::Delta::diff($new, $signature, $spool);

		seek $spool, 0, 0;
		my ($largest, $literal) = (0, 0);
		while (my ($type, @rest) = App::FileSync::Delta::read_op($spool)) {
			next unless $type eq 'literal';
			$literal += length $rest[0];
			$largest = length $rest[0] if length $rest[0] > $largest;
		}
		is($largest, $limit, "LITERAL=$limit: no literal record is longer than \$LITERAL");
		is($literal, $stats->{literal}, 'the records carry every literal byte the stats count');
		ok($stats->{copy} > 250_000, 'the blocks after the edit are still found');

		seek $spool, 0, 0;
		my $out_path = File::Spec->catfile($dir, "out-$limit");
		open my $out, '>', $out_path or die "Cannot write $out_path: $!";
		binmode $out;
		App::FileSync::Delta::apply($old, $spool, $out);
		close $out;
		close $spool;
		is(slurp($out_path), $new_content, 'the delta rebuilds the new file');
	}
}

# ------------------------------------------------------- past the scan window

# Only $SCAN_LIMIT bytes after the matched prefix are scanned; the rest of the
# file goes through diff's literal tail loop.  A shrunken window puts most of
# a small file there.
{
	my $dir = tempdir(CLEANUP => 1);
	my $delta = sub {
		my ($old, $new, $name) = @_;
		my $signature = App::FileSync::Delta::signature($old, 1_024);
		my $spool_path = File::Spec->catfile($dir, "$name.delta");
		open my $spool, '+>', $spool_path or die "Cannot write $spool_path: $!";
		binmode $spool;
		my $stats = App::FileSync::Delta::diff($new, $signature, $spool);

		seek $spool, 0, 0;
		my %seen = (copy => 0, literal => 0, records => 0, largest => 0);
		while (my ($type, @rest) = App::FileSync::Delta::read_op($spool)) {
			$seen{records}++;
			if ($type eq 'copy') {
				$seen{copy} += $rest[1];
			} else {
				$seen{literal} += length $rest[0];
				$seen{largest} = length $rest[0] if length $rest[0] > $seen{largest};
			}
		}

		seek $spool, 0, 0;
		my $out_path = File::Spec->catfile($dir, "$name.out");
		open my $out, '>', $out_path or die "Cannot write $out_path: $!";
		binmode $out;
		App::FileSync::Delta::apply($old, $spool, $out);
		close $out;
		close $spool;
		return ($stats, \%seen, slurp($out_path));
	};

	srand 13;
	my $old_content = join '', map { chr int rand 256 } 1 .. 300_000;
	my $new_content = $old_content;
	substr($new_content, 2_048, 0, '!');	# shifts every block after the second
	my $old = write_raw(File::Spec->catfile($dir, 'old.bin'), $old_content);
	my $new = write_raw(File::Spec->catfile($dir, 'new.bin'), $new_content);

	# With the whole file in the window, the shifted blocks are all found.
	my ($whole) = $delta->($old, $new, 'whole');
	ok($whole->{copy} > 290_000, 'a full scan finds the shifted blocks');

	{
		local $App::FileSync::Delta::SCAN_LIMIT = 8 * 1_024;
		local $App::FileSync::Delta::LITERAL = 100_000;
		my ($stats, $seen, $rebuilt) = $delta->($old, $new, 'window');

		# The prefix copies blocks 0 and 1.  The window is the next 9 KiB
		# ($SCAN_LIMIT plus a block); the shifted blocks start one byte into it,
		# so it holds eight whole blocks (at 1, 1025, ... 7169).  Nothing after
		# it is matched, though every block there is in the old file.
		is($stats->{copy}, 2 * 1_024 + 8 * 1_024, 'only the prefix and the window are copied');
		is($stats->{literal}, length($new_content) - $stats->{copy}, 'everything past the window is literal');
		is_deeply([ @{$seen}{qw(copy literal)} ], [ @{$stats}{qw(copy literal)} ], 'the records carry what the stats count');
		is($seen->{records}, $stats->{ops}, 'one op per record');
		is($seen->{largest}, 100_000, 'the tail is cut into $LITERAL records');
		is($rebuilt, $new_content, 'and the delta rebuilds the new file');
	}

	# A last tail chunk of "0" is still data: the loop tests length, not truth.
	{
		my $small_old = join '', map { chr int rand 256 } 1 .. 70_000;
		my $small_new = "X$small_old" . '0';
		my $from = write_raw(File::Spec->catfile($dir, 'small-old.bin'), $small_old);
		my $to   = write_raw(File::Spec->catfile($dir, 'small-new.bin'), $small_new);

		local $App::FileSync::Delta::SCAN_LIMIT = 2 * 1_024;
		# No prefix matches, so the window is the first 3 KiB; the tail is read
		# in chunks of $LITERAL, leaving a final chunk of the single "0".
		local $App::FileSync::Delta::LITERAL = length($small_new) - 3 * 1_024 - 1;
		my ($stats, undef, $rebuilt) = $delta->($from, $to, 'zero');
		is($stats->{literal} + $stats->{copy}, length $small_new, 'every byte is accounted for');
		is(substr($rebuilt, -1), '0', 'the final "0" chunk is written');
		is($rebuilt, $small_new, 'and the file rebuilds exactly');
	}
}

# ------------------------------------------------------ signature: no signature

# A missing path, and a file below $MIN_SIZE, have no signature: deltas are
# not worth it there.  $MIN_SIZE itself is the smallest file that gets one.
{
	my $dir = tempdir(CLEANUP => 1);
	my $min = $App::FileSync::Delta::MIN_SIZE;

	is(App::FileSync::Delta::signature(File::Spec->catfile($dir, 'missing')), undef, 'a missing file has no signature');
	is(App::FileSync::Delta::signature($dir), undef, 'nor does a directory');
	is(App::FileSync::Delta::signature(write_raw(File::Spec->catfile($dir, 'short'), 'x' x ($min - 1))), undef,
		'nor a file one byte below $MIN_SIZE');

	my $signature = App::FileSync::Delta::signature(write_raw(File::Spec->catfile($dir, 'least'), 'x' x $min), 1_024);
	ok($signature, 'a file of exactly $MIN_SIZE has one');
	is(scalar @{ $signature->{blocks} }, $min / 1_024, 'with a block for every 1 KiB');
}

# ------------------------------------------------- a match in the last window

# Inserting one byte at the front shifts every block by one, so the rolling
# scan finds them all, the last at the last window position in the buffer:
# both the loop and the checksum restart after a match must reach it.
{
	my $dir = tempdir(CLEANUP => 1);
	srand 17;
	my $old_content = join '', map { chr int rand 256 } 1 .. $App::FileSync::Delta::MIN_SIZE;
	my $new_content = "X$old_content";
	my $old = write_raw(File::Spec->catfile($dir, 'old.bin'), $old_content);
	my $new = write_raw(File::Spec->catfile($dir, 'new.bin'), $new_content);

	my $spool_path = File::Spec->catfile($dir, 'spool');
	open my $spool, '+>', $spool_path or die "Cannot write $spool_path: $!";
	binmode $spool;
	my $stats = App::FileSync::Delta::diff($new, App::FileSync::Delta::signature($old, 1_024), $spool);
	is($stats->{copy}, length $old_content, 'every block is copied, including the one in the last window');
	is($stats->{literal}, 1, 'only the inserted byte is literal');

	seek $spool, 0, 0;
	my @ops;
	while (my ($type, @rest) = App::FileSync::Delta::read_op($spool)) {
		push @ops, $type eq 'copy' ? "copy $rest[0]" : 'literal ' . length $rest[0];
	}
	is_deeply(\@ops, [ 'literal 1', map { 'copy ' . $_ * 1_024 } 0 .. 63 ], 'one literal byte, then the 64 blocks in order');

	seek $spool, 0, 0;
	my $out_path = File::Spec->catfile($dir, 'out');
	open my $out, '>', $out_path or die "Cannot write $out_path: $!";
	binmode $out;
	App::FileSync::Delta::apply($old, $spool, $out);
	close $out;
	close $spool;
	is(slurp($out_path), $new_content, 'and the file rebuilds exactly');
}

# ------------------------------------------------- the record writers' contract

# The writers return 1; the queue keeps fewer than $LITERAL bytes, so a run of
# exactly $LITERAL bytes is written at once.  The private helpers are callable
# here because Sub::Private is bypassed under HARNESS_ACTIVE.
{
	my $records = sub {
		my ($bytes) = @_;
		open my $in, '<', \$bytes or die $!;
		my @ops;
		while (my ($type, @rest) = App::FileSync::Delta::read_op($in)) {
			push @ops, $type eq 'copy' ? "copy @rest" : 'literal ' . length $rest[0];
		}
		return \@ops;
	};
	my $state = sub {
		my ($buffer) = @_;
		open my $out, '>', $buffer or die $!;
		return { out => $out, block => 4, literal => '', stats => { literal => 0, copy => 0, ops => 0 } };
	};

	my $bytes = '';
	open my $out, '>', \$bytes or die $!;
	is(App::FileSync::Delta::write_copy($out, 8, 4), 1, 'write_copy returns 1');
	is(App::FileSync::Delta::write_literal($out, 'abc'), 1, 'write_literal returns 1');
	is(App::FileSync::Delta::write_literal($out, ''), 1, 'and 1 when there is nothing to write');
	close $out;
	is_deeply($records->($bytes), [ 'copy 8 4', 'literal 3' ], 'an empty literal writes no record');

	local $App::FileSync::Delta::LITERAL = 10;
	my $written = '';
	my $s = $state->(\$written);
	is(App::FileSync::Delta::_add_literal($s, 'x' x 9), 1, '_add_literal returns 1');
	is($s->{literal}, 'x' x 9, 'fewer than $LITERAL bytes stay queued');
	App::FileSync::Delta::_add_literal($s, 'x');
	is($s->{literal}, '', 'reaching exactly $LITERAL writes them');
	is(App::FileSync::Delta::_add_literal($s, 'y' x 25), 1, 'a long run');
	is($s->{literal}, 'y' x 5, 'is cut into $LITERAL records, keeping the remainder');

	is(App::FileSync::Delta::_add_copy($s, 4, 4), 1, '_add_copy returns 1');
	is($s->{literal}, '', 'after flushing the queue first');
	is(App::FileSync::Delta::_flush($s), 1, '_flush returns 1 with nothing queued');
	App::FileSync::Delta::_add_literal($s, 'z');
	is(App::FileSync::Delta::_flush($s), 1, 'and with something queued');
	close $s->{out};
	is_deeply($records->($written), [ 'literal 10', 'literal 10', 'literal 10', 'literal 5', 'copy 4 4', 'literal 1' ],
		'the records come out in order');
	is_deeply($s->{stats}, { literal => 36, copy => 4, ops => 6 }, 'and the stats count them');

	my $scanned = '';
	my $short = $state->(\$scanned);
	is(App::FileSync::Delta::_rolling_scan($short, 'abc', []), 1, '_rolling_scan returns 1 for a buffer shorter than a block');
	is(App::FileSync::Delta::_rolling_scan($short, 'abcdefgh', []), 1, 'and for a longer one');
}

# ------------------------------------- the smallest delta, through a sync

# A master file of exactly $MIN_SIZE bytes is the smallest the server offers
# a signature for.  It is a whole number of blocks, so when the client appends
# to it, the last copy record ends exactly at the end of the old file, which
# the server must accept.
{
	my $env = TestSync->new_env();
	srand 19;
	my $old = join '', map { chr int rand 256 } 1 .. $App::FileSync::Delta::MIN_SIZE;
	$env->write_file('client', 'least.bin', $old, 1_700_000_000);
	$env->sync();

	my $new = $old . 'appended';
	$env->write_file('client', 'least.bin', $new, 1_700_000_100);
	my $push = $env->sync();
	is($push->{summary}{delta_pushed}, 1, 'a master file of exactly $MIN_SIZE bytes is updated by delta');
	ok($push->{summary}{bytes_sent} < 1_024, 'sending little more than the appended bytes');
	is($env->read_file('server', 'least.bin'), $new, 'and the master is rebuilt exactly');
}

done_testing();
