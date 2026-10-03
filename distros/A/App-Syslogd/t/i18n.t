#!/usr/bin/env perl

# The message catalogue: named arguments, plurals, sprintf, gender, fallback

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::Most;
use App::Syslogd;
use App::Syslogd::I18N;

# A test-only language exercising bracket features no English message
# happens to need yet (sprintf and gender)
{
	package App::Syslogd::I18N::x_test;
	use parent -norequire, 'App::Syslogd::I18N';
	our %Lexicon = (
		listening => '[gender,_1,He,She,They] listen on port [sprintf,%05d,_2]',
	);
	$INC{'App/Syslogd/I18N/x_test.pm'} = __FILE__;
}

subtest 'English messages and named arguments' => sub {
	my $lh = App::Syslogd::I18N->handle('en');

	is($lh->text('listening', { address => '::', port => 514 }),
		'Syslog server listening on :: UDP port 514', 'arguments land in the right slots');
	is($lh->text('open_failed', { error => 'E', file => 'F' }),
		'Could not open log file F: E', 'argument order in the hash is irrelevant');
	like($lh->text('usage', { program => 'syslogd' }), qr/\AUsage: syslogd \[--port/, 'escaped brackets survive');
};

subtest 'pluralisation' => sub {
	my $lh = App::Syslogd::I18N->handle('en');

	like($lh->text('shutdown', { count => 0 }), qr/0 messages\z/, 'zero is plural');
	like($lh->text('shutdown', { count => 1 }), qr/1 message\z/, 'one is singular');
	like($lh->text('shutdown', { count => 2 }), qr/2 messages\z/, 'two is plural');
};

subtest 'sprintf and gender contexts' => sub {
	my $lh = App::Syslogd::I18N::x_test->new();

	is($lh->text('listening', { address => 'female', port => 514 }), 'She listen on port 00514', 'female + sprintf');
	is($lh->text('listening', { address => 'MALE', port => 1 }), 'He listen on port 00001', 'gender is case-insensitive');
	is($lh->text('listening', { address => undef, port => 2 }), 'They listen on port 00002', 'missing gender is neutral');
};

subtest 'graceful failure' => sub {
	my $lh = App::Syslogd::I18N->handle('en');

	is($lh->text('no_such_key'), 'no_such_key', 'unknown key with no args renders as the key');
	is($lh->text('no_such_key', { b => 2, a => 1 }), 'no_such_key (a=1, b=2)', 'unknown key keeps its arguments');
	warnings_are { $lh->text('open_failed', {}) } [], 'missing arguments do not warn';
};

subtest 'language selection' => sub {
	isa_ok(App::Syslogd::I18N->handle('xx-nowhere'), 'App::Syslogd::I18N::en', 'unknown language falls back');
	isa_ok(App::Syslogd::I18N->handle(), 'App::Syslogd::I18N', 'environment detection returns a handle');

	# Two servers in one process keep their own languages
	my $en = App::Syslogd->new(language => 'en');
	my $test = App::Syslogd->new(language => 'x-test');
	like($en->i18n('listening', { address => 'a', port => 1 }), qr/^Syslog server/, 'first instance English');
	like($test->i18n('listening', { address => 'male', port => 1 }), qr/^He listen/, 'second instance test language');

	like(App::Syslogd->i18n('shutdown', { count => 3 }), qr/3 messages/, 'class-method call works');
};

done_testing();
