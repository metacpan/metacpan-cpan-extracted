#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

# Tests for private functions in bin/test-generator-index.
# The script cannot be require'd directly because it has top-level
# executable code that needs GITHUB_REPOSITORY set.
# Instead we import only the functions under test by compiling them
# in isolation using a minimal stub environment.

# --------------------------------------------------
# Bootstrap: define only what the functions need
# --------------------------------------------------
BEGIN {
	# Stub out modules the script uses at compile time
	# so we don't need the full environment
	$ENV{GITHUB_REPOSITORY} //= 'test/test-repo';
}

# --------------------------------------------------
# Inline the functions under test rather than
# requiring the script — this avoids the top-level
# executable code problem entirely
# --------------------------------------------------

# parse_version — wraps version->parse
sub parse_version {
	my $v = $_[0];
	return eval { version->parse($v) };
}

# extract_perl_versions — extract numeric version objects from reports
sub extract_perl_versions {
	my ($reports) = @_;
	my @v;
	for my $r (@{$reports}) {
		next unless $r->{perl};
		push @v, parse_version($r->{perl});
	}
	return @v;
}

# detect_perl_version_cliff — the function under test
sub detect_perl_version_cliff {
	my ($fail_reports, $pass_reports) = @_;

	my @fail_perls = extract_perl_versions($fail_reports);
	my @pass_perls = extract_perl_versions($pass_reports);

	return unless @fail_perls && @pass_perls;

	my $max_fail = (sort { $b <=> $a } @fail_perls)[0];
	my $min_pass = (sort { $a <=> $b } @pass_perls)[0];

	return unless $min_pass > $max_fail;

	return { fails_up_to => $max_fail, passes_from => $min_pass };
}

# make_key — deduplicate key for CPAN Testers reports
sub make_key {
	my $r = $_[0];
	return lc(join '|',
		$r->{osname}   // '',
		$r->{perl}     // '',
		$r->{arch}     // '',
		$r->{platform} // '',
	);
}

# confidence_score — returns (score, label) pair
sub confidence_score {
	my (%args) = @_;
	my $fail = $args{fail} // 0;
	my $pass = $args{pass} // 0;
	return (0, 'none') if ($fail + $pass) == 0;
	my $score = $fail / ($fail + $pass);
	my $med   = 0.90;
	my $low   = 0.70;
	my $label =
		$score >= $med ? 'strong'   :
		$score >= $low ? 'moderate' :
		'weak';
	return ($score, $label);
}

# perldelta_url — constructs perldoc URL for a version
sub perldelta_url {
	my ($v) = @_;
	my ($maj, $min) = "$v" =~ /^v?(\d+)\.(\d+)/;
	return "https://perldoc.perl.org/perl${maj}${min}0delta";
}

# _resolve_report_path — mirrors the path-traversal guard added to
# _mutant_file_report() in bin/test-generator-index: rejects any '..'
# segment in $file, then confirms the directory-preserving join of
# $dir and $file resolves to somewhere under $dir before returning it.
sub _resolve_report_path {
	my ($dir, $file) = @_;

	die "Refusing to report on suspicious file path: $file\n"
		if grep { $_ eq File::Spec->updir } File::Spec->splitdir($file);

	my $relative_path = File::Spec->catfile($dir, $file . '.html');
	my $out_dir = dirname($relative_path);

	make_path($out_dir) unless -d $out_dir;

	my $resolved_dir = abs_path($dir) // $dir;
	my $resolved_out = abs_path($out_dir) // $out_dir;
	die "Refusing to write report outside $dir: $relative_path\n"
		unless index($resolved_out, $resolved_dir) == 0;

	return $relative_path;
}

# ==================================================================
# parse_version
# ==================================================================

subtest 'parse_version() returns a version object for valid strings' => sub {
	my $v = parse_version('5.036000');
	ok(defined $v, '5.036000 parsed');
	ok($v->stringify, 'version object stringifies');
};

subtest 'parse_version() returns undef for garbage' => sub {
	my $v = parse_version('not_a_version');
	ok(!defined $v, 'garbage returns undef');
};

subtest 'parse_version() supports comparison operators' => sub {
	my $old = parse_version('5.034000');
	my $new = parse_version('5.036000');
	ok($new > $old, '5.036 > 5.034');
	ok($old < $new, '5.034 < 5.036');
};

subtest 'parse_version() handles v-string format' => sub {
	my $v = parse_version('v5.36.0');
	ok(defined $v, 'v-string format parsed');
};

# ==================================================================
# extract_perl_versions
# ==================================================================

subtest 'extract_perl_versions() returns empty list for empty reports' => sub {
	my @v = extract_perl_versions([]);
	is(scalar @v, 0, 'empty reports -> empty list');
};

subtest 'extract_perl_versions() skips reports with no perl field' => sub {
	my @v = extract_perl_versions([
		{ osname => 'linux' },
		{ perl => '5.036000', osname => 'linux' },
	]);
	is(scalar @v, 1, 'one version extracted, no-perl report skipped');
};

subtest 'extract_perl_versions() returns version objects' => sub {
	my @v = extract_perl_versions([
		{ perl => '5.036000' },
		{ perl => '5.034003' },
	]);
	is(scalar @v, 2, 'two versions extracted');
	ok($v[0]->stringify, 'first is a version object');
	ok($v[1]->stringify, 'second is a version object');
};

# ==================================================================
# detect_perl_version_cliff
# ==================================================================

subtest 'detect_perl_version_cliff() returns undef for empty reports' => sub {
	ok(!defined detect_perl_version_cliff([], []),
		'empty inputs -> undef');
};

subtest 'detect_perl_version_cliff() returns undef when only fail reports' => sub {
	my @fails = ({ perl => '5.034003' });
	ok(!defined detect_perl_version_cliff(\@fails, []),
		'no pass reports -> undef');
};

subtest 'detect_perl_version_cliff() returns undef when only pass reports' => sub {
	my @passes = ({ perl => '5.036000' });
	ok(!defined detect_perl_version_cliff([], \@passes),
		'no fail reports -> undef');
};

subtest 'detect_perl_version_cliff() detects cliff when fails all below passes' => sub {
	my @fails = (
		{ perl => '5.034003' },
		{ perl => '5.032001' },
		{ perl => '5.030003' },
	);
	my @passes = (
		{ perl => '5.036000' },
		{ perl => '5.038000' },
	);
	my $cliff = detect_perl_version_cliff(\@fails, \@passes);
	ok(defined $cliff,               'cliff detected');
	ok(defined $cliff->{fails_up_to}, 'fails_up_to present');
	ok(defined $cliff->{passes_from}, 'passes_from present');
	ok($cliff->{passes_from} > $cliff->{fails_up_to},
		'passes_from > fails_up_to');
};

subtest 'detect_perl_version_cliff() fails_up_to is max of fail versions' => sub {
	my @fails = (
		{ perl => '5.030003' },
		{ perl => '5.034003' },	# max fail
		{ perl => '5.032001' },
	);
	my @passes = ({ perl => '5.036000' });
	my $cliff  = detect_perl_version_cliff(\@fails, \@passes);
	ok(defined $cliff, 'cliff detected');
	my $expected = parse_version('5.034003');
	is("$cliff->{fails_up_to}", "$expected",
		'fails_up_to is max of fail versions');
};

subtest 'detect_perl_version_cliff() passes_from is min of pass versions' => sub {
	my @fails  = ({ perl => '5.034003' });
	my @passes = (
		{ perl => '5.040000' },
		{ perl => '5.036000' },	# min pass
		{ perl => '5.038000' },
	);
	my $cliff = detect_perl_version_cliff(\@fails, \@passes);
	ok(defined $cliff, 'cliff detected');
	my $expected = parse_version('5.036000');
	is("$cliff->{passes_from}", "$expected",
		'passes_from is min of pass versions');
};

subtest 'detect_perl_version_cliff() returns undef when pass and fail overlap' => sub {
	# Max fail (5.036) >= min pass (5.034) — no clean cliff
	my @fails  = ({ perl => '5.036000' });
	my @passes = ({ perl => '5.034003' });
	my $cliff  = detect_perl_version_cliff(\@fails, \@passes);
	ok(!defined $cliff, 'no cliff when versions overlap');
};

subtest 'detect_perl_version_cliff() returns undef when max_fail equals min_pass' => sub {
	my @fails  = ({ perl => '5.036000' });
	my @passes = ({ perl => '5.036000' });
	my $cliff  = detect_perl_version_cliff(\@fails, \@passes);
	ok(!defined $cliff, 'no cliff when max_fail equals min_pass');
};

subtest 'detect_perl_version_cliff() skips reports with no perl field' => sub {
	my @fails = (
		{ osname => 'linux' },	# no perl field
		{ perl => '5.034003' },
	);
	my @passes = ({ perl => '5.036000' });
	my $cliff = detect_perl_version_cliff(\@fails, \@passes);
	ok(defined $cliff, 'cliff detected despite no-perl report');
};

subtest 'detect_perl_version_cliff() handles single fail and single pass' => sub {
	my @fails  = ({ perl => '5.034003' });
	my @passes = ({ perl => '5.036000' });
	my $cliff  = detect_perl_version_cliff(\@fails, \@passes);
	ok(defined $cliff,             'cliff detected for single pair');
	ok($cliff->{passes_from} > $cliff->{fails_up_to},
		'ordering correct');
};

# ==================================================================
# make_key
# ==================================================================

subtest 'make_key() returns lowercase string' => sub {
	my $key = make_key({ osname => 'Linux', perl => '5.036', arch => 'x86_64', platform => 'linux' });
	is($key, lc($key), 'key is lowercase');
};

subtest 'make_key() handles missing fields with empty string' => sub {
	my $key = make_key({});
	ok(defined $key, 'empty report: key defined');
	is($key, '|||', 'empty report: key is |||');
};

subtest 'make_key() includes all four fields' => sub {
	my $key = make_key({
		osname   => 'linux',
		perl     => '5.036',
		arch     => 'x86_64',
		platform => 'linux-gnu',
	});
	like($key, qr/linux/,   'osname in key');
	like($key, qr/5\.036/,  'perl in key');
	like($key, qr/x86_64/,  'arch in key');
	like($key, qr/linux-gnu/, 'platform in key');
};

subtest 'make_key() produces same key for same report regardless of hash order' => sub {
	my $r = { osname => 'linux', perl => '5.036', arch => 'x86_64', platform => 'gnu' };
	is(make_key($r), make_key($r), 'idempotent');
};

subtest 'make_key() distinguishes different perl versions' => sub {
	my $k1 = make_key({ osname => 'linux', perl => '5.034', arch => 'x86_64', platform => 'gnu' });
	my $k2 = make_key({ osname => 'linux', perl => '5.036', arch => 'x86_64', platform => 'gnu' });
	isnt($k1, $k2, 'different perl versions produce different keys');
};

# ==================================================================
# confidence_score
# ==================================================================

subtest 'confidence_score() returns (0, none) for zero reports' => sub {
	my ($score, $label) = confidence_score(fail => 0, pass => 0);
	is($score, 0,      'score is 0');
	is($label, 'none', 'label is none');
};

subtest 'confidence_score() all fails -> strong confidence' => sub {
	my ($score, $label) = confidence_score(fail => 100, pass => 0);
	is($score, 1,        'score is 1.0');
	is($label, 'strong', 'label is strong');
};

subtest 'confidence_score() all passes -> weak confidence' => sub {
	my ($score, $label) = confidence_score(fail => 0, pass => 100);
	is($score, 0,      'score is 0.0');
	is($label, 'weak', 'label is weak');
};

subtest 'confidence_score() 90% fail -> strong' => sub {
	my ($score, $label) = confidence_score(fail => 90, pass => 10);
	is($label, 'strong', '90% fail -> strong');
};

subtest 'confidence_score() 80% fail -> moderate' => sub {
	my ($score, $label) = confidence_score(fail => 80, pass => 20);
	is($label, 'moderate', '80% fail -> moderate');
};

subtest 'confidence_score() 50% fail -> weak' => sub {
	my ($score, $label) = confidence_score(fail => 50, pass => 50);
	is($label, 'weak', '50% fail -> weak');
};

subtest 'confidence_score() score is between 0 and 1' => sub {
	for my $f (0, 1, 10, 50, 99, 100) {
		my $p = 100 - $f;
		my ($score) = confidence_score(fail => $f, pass => $p);
		ok($score >= 0 && $score <= 1,
			"fail=$f pass=$p: score $score in [0,1]");
	}
};

# ==================================================================
# perldelta_url
# ==================================================================

subtest 'perldelta_url() returns a perldoc URL' => sub {
	my $url = perldelta_url('5.36.0');
	like($url, qr{https://perldoc\.perl\.org/perl}, 'contains perldoc domain');
	like($url, qr/delta$/, 'ends with delta');
};

subtest 'perldelta_url() extracts major and minor correctly' => sub {
	my $url = perldelta_url('5.36.0');
	like($url, qr/perl5360delta/, 'perl5360delta in URL');
};

subtest 'perldelta_url() handles version object input' => sub {
	my $v   = parse_version('5.038000');
	my $url = perldelta_url($v);
	like($url, qr/perl5/, 'URL contains perl5');
	like($url, qr/delta/, 'URL contains delta');
};

subtest 'perldelta_url() different versions produce different URLs' => sub {
	my $u1 = perldelta_url('5.034000');
	my $u2 = perldelta_url('5.036000');
	isnt($u1, $u2, 'different versions produce different URLs');
};

# ==================================================================
# _resolve_report_path (path-traversal guard regression tests)
# ==================================================================

subtest '_resolve_report_path() accepts a normal lib/ path, preserving structure' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = _resolve_report_path($dir, 'lib/Foo/Bar.pm');
	is($path, File::Spec->catfile($dir, 'lib/Foo/Bar.pm.html'), 'directory structure preserved under $dir');
	ok(-d dirname($path), 'intermediate directories created');
};

subtest '_resolve_report_path() rejects a file containing a ".." segment' => sub {
	my $container = tempdir(CLEANUP => 1);
	my $dir = File::Spec->catdir($container, 'reportdir');
	mkdir $dir or die $!;

	throws_ok(
		sub { _resolve_report_path($dir, '../../etc/cron.d/evil') },
		qr/Refusing to report on suspicious file path/,
		'.. segment is rejected before any path is built'
	);

	# Nothing besides the pre-existing reportdir/ should have been
	# created in $container — confirms the guard fires before any
	# make_path/open touches the filesystem.
	opendir(my $dh, $container) or die $!;
	my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;
	is_deeply(\@entries, ['reportdir'], 'no sibling directory created outside $dir');
};

subtest '_resolve_report_path() rejects a ".." segment buried mid-path' => sub {
	my $dir = tempdir(CLEANUP => 1);
	throws_ok(
		sub { _resolve_report_path($dir, 'lib/../../escaped') },
		qr/Refusing to report on suspicious file path/,
		'.. anywhere in the path is rejected, not just a leading one'
	);
};

done_testing();
