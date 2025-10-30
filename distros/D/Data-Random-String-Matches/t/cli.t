#!/usr/bin/env perl

use strict;
use warnings;

use IPC::Run3;
use File::Temp qw(tempfile);
use Test::Most;

# Check if bin/random-string exists
my $cli = 'bin/random-string';
unless (-f $cli) {
	plan skip_all => "CLI script not found at $cli";
}

# Make sure it's executable
chmod 0755, $cli;

sub run_cli {
	my @args = @_;
	my ($out, $err);

	eval {
		run3([$^X, $cli, @args], \undef, \$out, \$err);
	};

	return {
		stdout => $out // '',
		stderr => $err // '',
		exit => $? >> 8,
		error => $@,
	};
}

# Test basic generation
subtest 'Basic generation' => sub {
	my $result = run_cli('\d{4}');

	is($result->{exit}, 0, 'Exits successfully');
	like($result->{stdout}, qr/^\d{4}$/, 'Generates 4 digits');
	is($result->{stderr}, '', 'No error output');
};

# Test multiple generation
subtest 'Multiple generation' => sub {
	my $result = run_cli('-c', '3', '\d{2}');

	is($result->{exit}, 0, 'Exits successfully');
	my @lines = split /\n/, $result->{stdout};
	is(scalar @lines, 3, 'Generates 3 strings');

	for my $line (@lines) {
		like($line, qr/^\d{2}$/, "Line matches pattern: $line");
	}
};

# Test custom separator
subtest 'Custom separator' => sub {
	my $result = run_cli('-c', '3', '-S', ', ', '[A-Z]');

	is($result->{exit}, 0, 'Exits successfully');
	like($result->{stdout}, qr/^[A-Z], [A-Z], [A-Z]/, 'Uses custom separator');
};

# Test smart mode
subtest 'Smart mode' => sub {
	my $result = run_cli('--smart', '[A-Z]{3}\d{4}');

	is($result->{exit}, 0, 'Exits successfully');
	like($result->{stdout}, qr/^[A-Z]{3}\d{4}$/, 'Smart mode works');
};

# Test help option
subtest 'Help option' => sub {
	my $result = run_cli('--help');

	like($result->{stdout}, qr/Usage:/, 'Shows usage');
	like($result->{stdout}, qr/Options:/, 'Shows options');

	$result = run_cli();

	like($result->{stdout}, qr/Usage:/, 'No args shows usage');
};

# Test version option
subtest 'Version option' => sub {
	my $result = run_cli('--version');

	like($result->{stdout}, qr/random-string version/, 'Shows version');
	is($result->{exit}, 0, 'Exits successfully');
};

# Test man option
subtest 'Man option' => sub {
	my $result = run_cli('--man');

	like($result->{stdout}, qr/NAME/, 'Shows man page');
	like($result->{stdout}, qr/SYNOPSIS/, 'Shows man page');
	is($result->{exit}, 0, 'Exits successfully');
};

# Test examples option
subtest 'Examples option' => sub {
	my $result = run_cli('--examples');

	like($result->{stdout}, qr/Examples:/, 'Shows examples header');
	like($result->{stdout}, qr/random-string/, 'Contains example commands');
	is($result->{exit}, 0, 'Exits successfully');
};

# Test error handling - no pattern
subtest 'Error: no pattern' => sub {
	my $result = run_cli();

	isnt($result->{exit}, 0, 'Exits with error');
	like($result->{stderr}, qr/Pattern required/, 'Shows error message');
};

# Test error handling - invalid count
subtest 'Error: invalid count' => sub {
	my $result = run_cli('-c', '0', '\d{4}');

	isnt($result->{exit}, 0, 'Exits with error');
	like($result->{stderr}, qr/count must be at least 1/, 'Shows error message');
};

# Test complex patterns
subtest 'Complex patterns' => sub {
	# Email-like
	my $result1 = run_cli('[a-z]{3}@[a-z]{3}\.com');
	like($result1->{stdout}, qr/^[a-z]{3}@[a-z]{3}\.com$/, 'Email pattern');

	# Phone number
	my $result2 = run_cli('\d{3}-\d{3}-\d{4}');
	like($result2->{stdout}, qr/^\d{3}-\d{3}-\d{4}$/, 'Phone pattern');

	# API key
	my $result3 = run_cli('AIza[0-9A-Za-z_-]{10}');
	like($result3->{stdout}, qr/^AIza[0-9A-Za-z_-]{10}$/, 'API key pattern');
};

# Test alternation
subtest 'Alternation' => sub {
	my $result = run_cli('-c', '5', '(cat|dog|bird)');

	is($result->{exit}, 0, 'Exits successfully');
	my @lines = split /\n/, $result->{stdout};

	for my $line (@lines) {
		like($line, qr/^(cat|dog|bird)$/, "Alternation line: $line");
	}
};

# Test backreferences
subtest 'Backreferences' => sub {
	my $result = run_cli('(\w{3})-\1');

	is($result->{exit}, 0, 'Exits successfully');
	my ($first, $second) = split /-/, $result->{stdout};
	chomp $second if defined $second;
	is($first, $second, 'Backreference repeats correctly');
};

# Test character classes
subtest 'Character classes' => sub {
	my $result = run_cli('[A-Z]{5}');
	like($result->{stdout}, qr/^[A-Z]{5}$/, 'Uppercase pattern');

	my $result2 = run_cli('[0-9]{3}');
	like($result2->{stdout}, qr/^[0-9]{3}$/, 'Digit pattern');
};

# Test escape sequences
subtest 'Escape sequences' => sub {
	my $result = run_cli('\d{3}');
	like($result->{stdout}, qr/^\d{3}$/, '\d pattern');

	my $result2 = run_cli('\w{5}');
	like($result2->{stdout}, qr/^\w{5}$/, '\w pattern');
};

# Test length parameter
subtest 'Length parameter' => sub {
	my $result = run_cli('-l', '20', '[A-Z]+', '-c', '1');

	is($result->{exit}, 0, 'Exits successfully with length param');
	like($result->{stdout}, qr/^[A-Z]+$/, 'Generates matching string');
};

# Test newline in separator
subtest 'Separator escape sequences' => sub {
	my $result = run_cli('-c', '2', '-S', '\t', 'X');

	like($result->{stdout}, qr/X\tX/, 'Tab separator works');
};

subtest 'Bad pattern errors' => sub {
	my $result = run_cli('{');

	isnt($result->{exit}, 0, 'Exits failure with bad arg');
};

done_testing();
