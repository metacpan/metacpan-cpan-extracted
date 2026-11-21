#!/usr/bin/env perl

# Black-box tests for parse_os_list and parse_version_list, plus the
# message table they use.

use v5.36;
use Test::Most;

use_ok('App::GHGen::Generator', qw(generate_workflow parse_os_list parse_version_list));

my %C = (
	linux   => 'ubuntu-latest',
	macos   => 'macos-latest',
	windows => 'windows-latest',
);

subtest 'parse_os_list maps short names to runner labels' => sub {
	is_deeply(parse_os_list('linux,macos,windows'), [@C{qw(linux macos windows)}], 'all three');
	is_deeply(parse_os_list('ubuntu'), [$C{linux}], 'ubuntu alias');
};

subtest 'parse_os_list normalises its input' => sub {
	is_deeply(parse_os_list(' Linux , MACOS '), [@C{qw(linux macos)}], 'case and whitespace');
	is_deeply(parse_os_list('ubuntu,linux,,linux'), [$C{linux}], 'duplicates and empties dropped');
	is_deeply(parse_os_list('windows,linux'), [@C{qw(windows linux)}], 'order preserved');
};

subtest 'parse_os_list passes literal labels through' => sub {
	is_deeply(parse_os_list('ubuntu-22.04,macos-13'), ['ubuntu-22.04', 'macos-13'], 'labels');
	throws_ok { parse_os_list('solaris-11') } qr/Unknown OS 'solaris-11'/, 'other vendors rejected';
};

subtest 'parse_os_list rejects bad input' => sub {
	throws_ok { parse_os_list('bsd') }  qr/Unknown OS 'bsd' for --os/, 'unknown name';
	throws_ok { parse_os_list('') }     qr/at least one operating system/, 'empty string';
	throws_ok { parse_os_list(' , ') }  qr/at least one operating system/, 'only separators';
};

subtest 'parse_version_list normalises its input' => sub {
	is_deeply(parse_version_list('5.40, 5.42'), ['5.40', '5.42'], 'whitespace');
	is_deeply(parse_version_list('20,22,20'), ['20', '22'], 'duplicates dropped');
	is_deeply(parse_version_list('3.10'), ['3.10'], 'trailing zero kept as a string');
	is_deeply(parse_version_list('18.x,stable,1.80+'), ['18.x', 'stable', '1.80+'], 'wildcards and names');
};

subtest 'parse_version_list rejects bad input' => sub {
	throws_ok { parse_version_list('') }       qr/requires at least one version/, 'empty string';
	throws_ok { parse_version_list(',') }      qr/requires at least one version/, 'only separators';
	throws_ok { parse_version_list('5.40 5.42') } qr/Invalid version '5\.40 5\.42'/, 'inner space';
	throws_ok { parse_version_list(q{1'; x}) } qr/Invalid version/, 'quote and semicolon';
	throws_ok { parse_version_list("1\n2") }  qr/Invalid version/, 'newline cannot survive split';
};

subtest 'croak reports the caller, not the library' => sub {
	eval { parse_os_list('bsd') };
	like($@, qr/at \S*options\.t line \d+/, 'location is this test file');
};

subtest 'parsed lists feed generate_workflow' => sub {
	my $yaml = generate_workflow('node', { versions => parse_version_list('20,22') });
	like($yaml, qr/- '20'\n\s+- '22'\n/, 'matrix uses the parsed versions');
};

subtest 'message table can be reworded' => sub {
	local $App::GHGen::Generator::MESSAGES{no_os} = 'Bitte ein Betriebssystem angeben';
	throws_ok { parse_os_list('') } qr/Bitte ein Betriebssystem/, 'override takes effect';
};

subtest 'unknown message key is reported, not hidden' => sub {
	my $text = App::GHGen::Generator::_message('no_such_key');
	like($text, qr/unknown message key 'no_such_key'/, 'fallback text names the key');
};

done_testing();
