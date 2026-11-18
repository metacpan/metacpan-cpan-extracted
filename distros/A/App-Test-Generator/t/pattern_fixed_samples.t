#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/pattern_fixed_samples.t - a string parameter constrained by `matches`
# or `nomatch` is never sent the generator's fixed whitespace, newline or
# BOM samples as a value that is expected to be accepted.
#
# CGI-Info's cookie handling regressed downstream when a pattern-constrained
# field was given values such as ' ', "\n", " \n " and "\x{FEFF}" in cases
# that expected the routine to live: a cookie value cannot contain
# whitespace, so the harness failed for the wrong reason and the cookie
# regression was only noticed downstream.  The routines here reject those
# values, so a generated harness that sends one as valid data fails; the
# generated value set itself is checked by recording what the routine
# receives.
# ======================================================================

use Test::Most;
use Config;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3 qw(run3);
use App::Test::Generator;

my $dir = tempdir(CLEANUP => 1);
my $lib = File::Spec->catdir($dir, 'lib');
make_path(File::Spec->catdir($lib, 'Cookie'));

my $module_file = File::Spec->catfile($lib, 'Cookie', 'Jar.pm');
open(my $fh, '>', $module_file) or die "cannot write $module_file: $!";
print {$fh} <<'MODULE';
package Cookie::Jar;
use strict;
use warnings;

# Record every value the routine is given before deciding whether it is
# valid, so the test can see exactly what the harness sent.
sub _record
{
	my ($value) = @_;

	return unless defined($value) && !ref($value) && $ENV{'COOKIE_VALUE_LOG'};

	# Log code points, not bytes: a BOM has to survive the handle's encoding.
	open(my $log, '>>', $ENV{'COOKIE_VALUE_LOG'}) or die $!;
	print {$log} 'V ', join(',', map { sprintf('%X', ord($_)) } split(//, $value)), "\n";
	close($log);
}

sub _check
{
	my ($value) = @_;

	die 'cookie value must be a string' unless defined($value) && !ref($value);
	_record($value);

	die 'cookie value must be alphanumeric'
		unless $value =~ /\A[A-Za-z0-9]+\z/;

	return $value;
}

# Same rules, plus the 1..4 length the bounded schemas declare.
sub checked_value
{
	my ($value) = @_;

	_check($value);
	die 'cookie value must be 1-4 characters'
		unless (length($value) >= 1) && (length($value) <= 4);

	return $value;
}

sub cookie_value
{
	return _check($_[0]);
}

sub _check_token
{
	my ($value) = @_;

	die 'cookie token must be a string' unless defined($value) && !ref($value);
	_record($value);

	die 'cookie token must not contain whitespace or a BOM'
		if $value =~ /[\s\x{FEFF}]/;

	return $value;
}

sub checked_token
{
	my ($value) = @_;

	_check_token($value);
	die 'cookie token must be 1-4 characters'
		unless (length($value) >= 1) && (length($value) <= 4);

	return $value;
}
1;
MODULE
close($fh) or die "cannot close $module_file: $!";

my @fixed_samples = (
	' ',        # space
	"\n",       # newline
	" \n ",     # whitespace around a newline
	"\x{FEFF}", # byte order marker
);

sub _schema
{
	my ($function, $spec) = @_;

	return {
		module   => 'Cookie::Jar',
		function => $function,
		seed     => 42,
		input    => { value => { %{$spec}, optional => 0, position => 0 } },
		output   => { type => 'string' },
		config   => {
			test_empty     => 0,
			test_nuls      => 0,
			test_non_ascii => 0,
			test_security  => 0,
			test_undef     => 0,
		},
	};
}

sub _harness
{
	my ($name, $schema) = @_;

	my $file = File::Spec->catfile($dir, "$name.t");
	App::Test::Generator->generate(
		schema      => $schema,
		output_file => $file,
		quiet       => 1,
	);

	return $file;
}

sub _run
{
	my ($file) = @_;

	my $log = "$file.log";
	unlink($log);

	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join($Config{path_sep}, grep { defined($_) && length($_) } ($lib, $ENV{PERL5LIB}));
	local $ENV{COOKIE_VALUE_LOG} = $log;
	run3([ $^X, $file ], \undef, \$stdout, \$stderr);

	my @received;
	if(-f $log) {
		open(my $log_fh, '<', $log) or die "cannot read $log: $!";
		while(my $line = <$log_fh>) {
			chomp($line);
			next unless $line =~ /^V (.*)$/;
			push @received, join('', map { chr(hex($_)) } grep { length($_) } split(/,/, $1));
		}
		close($log_fh);
	}

	return ($? >> 8, "$stdout$stderr", \@received);
}

sub _shown
{
	my ($value) = @_;

	$value =~ s/([^\x20-\x7e])/sprintf('\\x{%02X}', ord($1))/ge;

	return $value;
}

sub _pattern_harness_passes
{
	my ($label, $function, $spec) = @_;

	my $file = _harness($label, _schema($function, $spec));
	my ($exit, $output, $received) = _run($file);

	is($exit, 0, "$label: the harness passes against a routine that rejects the fixed samples")
		or diag($output);
	cmp_ok(scalar(@{$received}), '>', 0, "$label: the routine received values");
}

subtest 'matches with bounds: no fixed sample is valid input' => sub {
	# The lower-bound branch would add ' ', "\n" and " \n " when no pattern
	# is declared; the pattern must suppress them.
	_pattern_harness_passes(
		'matches_bounded', 'checked_value',
		{ type => 'string', min => 1, max => 4, matches => qr/\A[A-Za-z0-9]+\z/ },
	);
};

subtest 'matches without bounds: no BOM sample is valid input' => sub {
	# The unbounded branch is the one that adds the byte order marker.
	_pattern_harness_passes(
		'matches_unbounded', 'cookie_value',
		{ type => 'string', matches => qr/\A[A-Za-z0-9]+\z/ },
	);
};

subtest 'nomatch with bounds: no fixed sample is valid input' => sub {
	_pattern_harness_passes(
		'nomatch_bounded', 'checked_token',
		{ type => 'string', min => 1, max => 4, nomatch => qr/[\s\x{FEFF}]/ },
	);
};

subtest 'the same routine is sent those samples when no pattern is declared' => sub {
	# Control: without a pattern the generator's fixed samples are used as
	# valid data, so the subtests above are not passing vacuously.  The only
	# values this routine rejects are the four fixed samples and non-string
	# references (which _record ignores).
	my $file = _harness(
		'unconstrained_harness',
		_schema('cookie_value', { type => 'string', min => 1 }),
	);

	my ($exit, $output, $received) = _run($file);

	isnt($exit, 0, 'a routine that rejects the fixed samples fails without a pattern')
		or diag('the unconstrained harness unexpectedly passed');

	foreach my $sample (@fixed_samples) {
		ok(grep({ $_ eq $sample } @{$received}),
			"'" . _shown($sample) . "' is sent as a value when no pattern is declared");
	}
};

done_testing();
