#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;
use JSON::MaybeXS qw(encode_json decode_json);

# White-box unit tests for App::Test::Generator::LCSAJ::Coverage.
# Exercises merge() — particularly the if($hits->{$line}) coverage
# check that determines whether each path is marked covered.

BEGIN { use_ok('App::Test::Generator::LCSAJ::Coverage') }

# ---------------------------------------------------------------
# Helper: write a JSON file to a temp dir and return its path
# ---------------------------------------------------------------
sub _write_json {
	my ($dir, $name, $data) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh encode_json($data);
	close $fh;
	return $path;
}

my $dir = tempdir(CLEANUP => 1);

# ---------------------------------------------------------------
# 1. merge() — croaks when lcsaj_file argument is missing
# ---------------------------------------------------------------
subtest 'merge() croaks when lcsaj_file is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::LCSAJ::Coverage::merge(undef, 'hits.json', 'out.json') },
		qr/lcsaj_file required/,
		'croaks with "lcsaj_file required"',
	);
};

# ---------------------------------------------------------------
# 2. merge() — croaks when hits_file argument is missing
# ---------------------------------------------------------------
subtest 'merge() croaks when hits_file is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::LCSAJ::Coverage::merge('lcsaj.json', undef, 'out.json') },
		qr/hits_file required/,
		'croaks with "hits_file required"',
	);
};

# ---------------------------------------------------------------
# 3. merge() — croaks when out_file argument is missing
# ---------------------------------------------------------------
subtest 'merge() croaks when out_file is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::LCSAJ::Coverage::merge('lcsaj.json', 'hits.json', undef) },
		qr/out_file required/,
		'croaks with "out_file required"',
	);
};

# ---------------------------------------------------------------
# 4. merge() — path with a hit in range is marked covered.
#    This kills the COND_INV survivor on if($hits->{$line}) —
#    if inverted to unless, covered paths would be marked 0.
# ---------------------------------------------------------------
subtest 'merge() marks path covered when a line in range was hit' => sub {
	my $lcsaj = _write_json($dir, 'hit.lcsaj.json',
		[ { start => 10, end => 12 } ]
	);
	# Line 11 was hit once
	my $hits = _write_json($dir, 'hit.hits.json', { '11' => 1 });
	my $out  = File::Spec->catfile($dir, 'hit.out.json');

	lives_ok(
		sub { App::Test::Generator::LCSAJ::Coverage::merge($lcsaj, $hits, $out) },
		'merge() lives with valid inputs',
	);

	ok(-f $out, 'output file created');
	open my $fh, '<', $out or die $!;
	my $result = decode_json(do { local $/; <$fh> });
	close $fh;
	is($result->[0]{covered}, 1, 'path with a hit in range is marked covered=1');
};

# ---------------------------------------------------------------
# 5. merge() — path with no hits in range is marked not covered.
#    If COND_INV flips if to unless, this would incorrectly
#    mark the path as covered=1.
# ---------------------------------------------------------------
subtest 'merge() marks path not covered when no line in range was hit' => sub {
	my $lcsaj = _write_json($dir, 'miss.lcsaj.json',
		[ { start => 20, end => 22 } ]
	);
	# Only line 5 was hit — outside the path range
	my $hits = _write_json($dir, 'miss.hits.json', { '5' => 1 });
	my $out  = File::Spec->catfile($dir, 'miss.out.json');

	App::Test::Generator::LCSAJ::Coverage::merge($lcsaj, $hits, $out);

	open my $fh, '<', $out or die $!;
	my $result = decode_json(do { local $/; <$fh> });
	close $fh;
	is($result->[0]{covered}, 0, 'path with no hits in range is marked covered=0');
};

# ---------------------------------------------------------------
# 6. merge() — multiple paths are annotated independently
# ---------------------------------------------------------------
subtest 'merge() annotates multiple paths independently' => sub {
	my $lcsaj = _write_json($dir, 'multi.lcsaj.json', [
		{ start => 1, end => 3 },
		{ start => 7, end => 9 },
	]);
	# Only line 2 hit — covers first path only
	my $hits = _write_json($dir, 'multi.hits.json', { '2' => 1 });
	my $out  = File::Spec->catfile($dir, 'multi.out.json');

	App::Test::Generator::LCSAJ::Coverage::merge($lcsaj, $hits, $out);

	open my $fh, '<', $out or die $!;
	my $result = decode_json(do { local $/; <$fh> });
	close $fh;
	is($result->[0]{covered}, 1, 'first path (hit) marked covered=1');
	is($result->[1]{covered}, 0, 'second path (no hit) marked covered=0');
};

# ---------------------------------------------------------------
# 7. merge() — empty paths list produces empty output
# ---------------------------------------------------------------
subtest 'merge() handles empty paths list' => sub {
	my $lcsaj = _write_json($dir, 'empty.lcsaj.json', []);
	my $hits  = _write_json($dir, 'empty.hits.json',  {});
	my $out   = File::Spec->catfile($dir, 'empty.out.json');

	lives_ok(
		sub { App::Test::Generator::LCSAJ::Coverage::merge($lcsaj, $hits, $out) },
		'merge() lives with empty inputs',
	);
	open my $fh, '<', $out or die $!;
	my $result = decode_json(do { local $/; <$fh> });
	close $fh;
	is(scalar @{$result}, 0, 'empty paths produces empty output array');
};

done_testing();
