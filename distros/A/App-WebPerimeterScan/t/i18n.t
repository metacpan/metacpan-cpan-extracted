use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use File::Find qw(find);
use Test::More;

use App::WebPerimeterScan;
use App::WebPerimeterScan::I18N;
use App::WebPerimeterScan::Messages;

my $I18N = 'App::WebPerimeterScan::I18N';
my $catalogue = \%App::WebPerimeterScan::Messages::CATALOGUE;

# Test messages, removed again at the end so other tests are unaffected.
local $catalogue->{en}{'test.plain'}  = 'Hello {name}, {missing} stays';
local $catalogue->{en}{'test.format'} = 'Took {seconds:%.1f}s';
local $catalogue->{en}{'test.plural'} = { plural => 'count', forms => { one => '{count} file', other => '{count} files' } };
local $catalogue->{en}{'test.gender'} = {
	select => 'gender',
	forms  => {
		female => 'her report',
		male   => 'his report',
		other  => { plural => 'count', forms => { one => 'their report', other => 'their {count} reports' } },
	},
};

# Pin the language to English for these subtests, whatever the machine's.
local $ENV{LANGUAGE};
local $ENV{LC_ALL} = 'C';
local $ENV{LC_MESSAGES};
local $ENV{LANG};

subtest 'placeholders' => sub {
	is($I18N->i18n('test.plain', { name => 'Ann' }), 'Hello Ann, {missing} stays', 'a missing argument is left visible');
	is($I18N->i18n('test.plain', { name => '{missing}' }), 'Hello {missing}, {missing} stays', 'a value is never expanded again');
	is($I18N->i18n('test.plain', { name => undef }), 'Hello {name}, {missing} stays', 'an undefined value counts as missing');
	is($I18N->i18n('test.format', { seconds => 1.25 }), 'Took 1.2s', 'a sprintf format is applied');
	is($I18N->i18n('test.plain'), 'Hello {name}, {missing} stays', 'no arguments at all is not fatal');
};

subtest 'plural forms' => sub {
	is($I18N->i18n('test.plural', { count => 1 }), '1 file', 'one');
	is($I18N->i18n('test.plural', { count => 0 }), '0 files', 'zero is plural in English');
	is($I18N->i18n('test.plural', { count => 2 }), '2 files', 'two');
	is($I18N->i18n('test.plural', { count => 'many' }), 'many files', 'a non-number falls back to other');
	is($I18N->i18n('test.plural', {}), '{count} files', 'a missing count falls back to other');
};

subtest 'select (gender) forms' => sub {
	is($I18N->i18n('test.gender', { gender => 'female' }), 'her report', 'female');
	is($I18N->i18n('test.gender', { gender => 'male' }), 'his report', 'male');
	is($I18N->i18n('test.gender', { gender => 'nonbinary', count => 1 }), 'their report', 'unknown falls back to other');
	is($I18N->i18n('test.gender', { count => 3 }), 'their 3 reports', 'a nested plural inside a select');
};

subtest 'missing keys' => sub {
	my $error = do { local $@; eval { $I18N->i18n('no.such.key') }; $@ };
	like($error, qr/No message is defined for "no\.such\.key"/, 'a missing key is fatal, with a catalogued message');
	like($error, qr/called at/, '... and a stack trace (confess)');
	ok(!eval { $I18N->i18n(undef); 1 }, 'an undefined key is fatal');
	ok($I18N->has_message('csp-missing.title'), 'has_message: present');
	ok(!$I18N->has_message('csp-missing.nope'), 'has_message: absent');
	ok(!$I18N->has_message(undef), 'has_message: undef');
};

subtest 'language selection' => sub {
	local $catalogue->{de} = { 'test.plain' => 'Hallo {name}' };
	local $App::WebPerimeterScan::I18N::PLURAL_RULE{de};

	local $ENV{LC_ALL} = 'de_DE.UTF-8';
	is($I18N->language, 'de', 'LC_ALL selects a language that has a catalogue');
	is($I18N->i18n('test.plain', { name => 'Ann' }), 'Hallo Ann', 'its text is used');
	is($I18N->i18n('test.plural', { count => 1 }), '1 file', 'a key it lacks falls back to English');

	local $ENV{LC_ALL} = 'ja_JP.UTF-8';
	is($I18N->language, 'en', 'a language with no catalogue falls back to English');

	local $ENV{LANGUAGE} = 'fr:de';
	is($I18N->language, 'de', 'LANGUAGE is a preference list');

	local $ENV{LANGUAGE};
	local $ENV{LC_ALL} = 'POSIX';
	local $ENV{LANG} = 'de_AT';
	is($I18N->language, 'de', 'POSIX means no preference, so LANG decides');

	local $App::WebPerimeterScan::I18N::config{language} = 'en';
	is($I18N->language, 'en', 'a configured language wins over the environment');
};

subtest 'clean_error' => sub {
	is(App::WebPerimeterScan::I18N::clean_error("Bad thing at lib/X.pm line 12.\n"), 'Bad thing', 'location removed');
	is(App::WebPerimeterScan::I18N::clean_error("Bad at a.pl line 3, <\$fh> line 7.\n"), 'Bad', 'handle position removed');
	is(App::WebPerimeterScan::I18N::clean_error("No location here\n"), 'No location here', 'newline removed');
	is(App::WebPerimeterScan::I18N::clean_error(undef), '', 'undef');

	my $object = bless {}, 'Stringy';
	{ package Stringy; use overload '""' => sub { "From an object at x.pm line 1.\n" }; }
	is(App::WebPerimeterScan::I18N::clean_error($object), 'From an object', 'an exception object is stringified');
};

subtest 'every key used in the code exists' => sub {
	# Literal keys passed to the catalogue helpers.  A typo here would only
	# surface when that message was first needed, mid-scan.
	my $calls = qr/(?:i18n|_t|msg|_throw|_warn|_say|has_message)\(\s*'([\w.-]+)'/;
	my (%keys, %rules);

	my $root = "$FindBin::Bin/..";
	find({ no_chdir => 1, wanted => sub {
		return unless /\.pm\z/ || m{/bin/webperimeter\z};
		open my $fh, '<', $_ or die "$_: $!";
		my $code = do { local $/; <$fh> };
		close $fh;
		$code =~ s/^__END__.*//ms;
		# POD examples are documentation, not calls.
		$code =~ s/^=\w+.*?^=cut\b//msg;

		$keys{$1} = $_ while $code =~ /$calls/g;
		# Rule ids: _flag/_page_flag/_report/report calls and the probe table.
		$rules{$1} = $_ while $code =~ /(?:_flag\(\$\w+, |_page_flag\(\$page, |_report\(|->report\()'([\w-]+)'/g;
		$rules{$1} = $_ while $code =~ /\{ id => '([\w-]+)',\s+path =>/g;
	} }, "$root/lib", "$root/bin");

	ok(scalar(keys %keys) > 50, 'found the message keys') or diag join ', ', sort keys %keys;
	ok(scalar(keys %rules) > 50, 'found the rule ids') or diag join ', ', sort keys %rules;

	for my $key (sort keys %keys) {
		ok(exists $catalogue->{en}{$key}, "message '$key' exists") or diag "used in $keys{$key}";
	}
	for my $id (sort keys %rules) {
		ok(exists $catalogue->{en}{"$id.title"} && exists $catalogue->{en}{"$id.detail"},
			"rule '$id' has a title and a detail") or diag "used in $rules{$id}";
	}
};

done_testing();
