#!/usr/bin/env perl

# Tests for the --os option of "ghgen generate"

use v5.36;
use Test::Most;
use IPC::Run3 qw(run3);
use Path::Tiny;
use File::Temp qw(tempdir);

my %C = (
	linux	=> 'ubuntu-latest',
	macos	=> 'macos-latest',
	windows	=> 'windows-latest',
);

my $lib = path(__FILE__)->parent->parent->child('lib')->absolute->stringify;
my $bin = path(__FILE__)->parent->parent->child('bin/ghgen')->absolute->stringify;

# Run ghgen generate --type=perl with extra args; return (yaml, stderr, exit)
sub generate(@args) {
	my $dir = tempdir(CLEANUP => 1);
	my $file = "$dir/out.yml";
	my ($out, $err);
	run3([ $^X, "-I$lib", $bin, 'generate', '--type=perl', "--output=$file", @args ],
		\undef, \$out, \$err);
	my $status = $? >> 8;
	my $yaml = path($file)->exists ? path($file)->slurp_utf8 : '';
	diag "stderr: $err" if $ENV{TEST_VERBOSE} && $err;
	return ($yaml, $err, $status);
}

subtest 'default includes all three operating systems' => sub {
	my ($yaml, undef, $rc) = generate();
	is($rc, 0, 'exit 0');
	like($yaml, qr/-\s+\Q$C{linux}\E/, 'linux present');
	like($yaml, qr/-\s+\Q$C{macos}\E/, 'macos present');
	like($yaml, qr/-\s+\Q$C{windows}\E/, 'windows present');
};

subtest '--os=linux,macos,windows equals the default' => sub {
	my ($default) = generate();
	my ($explicit) = generate('--os=linux,macos,windows');
	is($explicit, $default, 'identical output');
};

subtest '--os=linux,macos omits all Windows content' => sub {
	my ($yaml, undef, $rc) = generate('--os=linux,macos');
	is($rc, 0, 'exit 0');
	like($yaml, qr/-\s+\Q$C{linux}\E/, 'linux present');
	like($yaml, qr/-\s+\Q$C{macos}\E/, 'macos present');
	unlike($yaml, qr/windows-latest/, 'no windows runner');
	unlike($yaml, qr/\bexclude:/, 'no windows/5.40 exclusion emitted');
};

subtest '--os=linux gives a single-OS matrix' => sub {
	my ($yaml, undef, $rc) = generate('--os=linux');
	is($rc, 0, 'exit 0');
	like($yaml, qr/-\s+\Q$C{linux}\E/, 'linux present');
	unlike($yaml, qr/macos-latest|windows-latest/, 'no other runners');
};

subtest '--os=windows keeps the 5.40 exclusion' => sub {
	my ($yaml) = generate('--os=windows');
	like($yaml, qr/-\s+\Q$C{windows}\E/, 'windows present');
	like($yaml, qr/\bexclude:/, 'exclusion present');
};

subtest 'ubuntu alias, case, whitespace and duplicates' => sub {
	my ($yaml, undef, $rc) = generate('--os=Ubuntu, LINUX');
	is($rc, 0, 'exit 0');
	my $count = () = $yaml =~ /^\s+-\s+\Q$C{linux}\E\s*$/mg;
	is($count, 1, 'ubuntu-latest listed once');
};

subtest 'literal runner label is accepted' => sub {
	my ($yaml, undef, $rc) = generate('--os=ubuntu-22.04');
	is($rc, 0, 'exit 0');
	like($yaml, qr/-\s+ubuntu-22\.04/, 'label used verbatim');
};

subtest 'matrix order follows the order given' => sub {
	my ($yaml) = generate('--os=macos,linux');
	like($yaml, qr/\Q$C{macos}\E.*\Q$C{linux}\E/s, 'macos before linux');
};

subtest 'unknown OS is rejected' => sub {
	my ($yaml, $err, $rc) = generate('--os=bsd');
	isnt($rc, 0, 'non-zero exit');
	like($err, qr/Unknown OS 'bsd'/, 'error names the bad value');
	is($yaml, '', 'no file written');
};

subtest 'empty OS list is rejected' => sub {
	my ($yaml, $err, $rc) = generate('--os=,');
	isnt($rc, 0, 'non-zero exit');
	like($err, qr/at least one operating system/, 'error message');
	is($yaml, '', 'no file written');
};

done_testing();
