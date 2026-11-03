#!perl -w

# Tests for init(): checking its options, turning the cache off, chaining, and
# replacing the messages

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Most;
use Test::CGIBuffer qw(run_script header);

my $have_chi = eval { require CHI; 1 };

subtest 'Unknown and invalid options' => sub {
	my $r = run_script(code => q{
		CGI::Buffer::init(colour => 'blue');
		CGI::Buffer::init(cache => 'not an object');
		CGI::Buffer::init(optimise_content => 'lots');
		CGI::Buffer::init(lingua => bless({}, 'NotLingua'));
		CGI::Buffer::init(messages => 'not a hash');
		print "Content-Type: text/plain\n\n", (defined($CGI::Buffer::cache) ? 'cache' : 'no cache'), " $CGI::Buffer::optimise_content";
	});
	like($r->{stderr}, qr/CGI::Buffer: init: unknown option colour ignored/, 'unknown option');
	like($r->{stderr}, qr/CGI::Buffer: init: cache must be an object, ignored/, 'cache that is not an object');
	like($r->{stderr}, qr/CGI::Buffer: init: optimise_content must be a number, 0 or more, ignored/, 'optimise_content that is not a number');
	like($r->{stderr}, qr/CGI::Buffer: init: lingua must understand language, ignored/, 'lingua without language()');
	like($r->{stderr}, qr/CGI::Buffer: init: messages must be a hash reference, ignored/, 'messages that are not a hash');
	is($r->{body}, 'no cache 0', 'invalid options are not used');
	like($r->{stderr}, qr/at \S+script\.pl line \d+/, 'warnings say where init() was called');
};

subtest 'A logger without all of the methods is ignored' => sub {
	my $r = run_script(code => q{
		package HalfLogger;
		sub new { bless {}, shift }
		sub debug { print STDERR "DEBUG\n" }
		package main;
		CGI::Buffer::init(logger => HalfLogger->new());
		print "Content-Type: text/plain\n\n", (defined($CGI::Buffer::logger) ? 'logger' : 'no logger');
	});
	like($r->{stderr}, qr/The logger doesn't understand trace\(\)/, 'warning');
	is($r->{body}, 'no logger', 'logger is not used');
};

subtest 'init() can be chained, and the cache can be turned off' => sub {
	plan skip_all => 'CHI not installed' unless($have_chi);

	my $r = run_script(code => q{
		use CHI;
		my $rc = CGI::Buffer::init(cache => CHI->new(driver => 'Memory', global => 1));
		my $chained = CGI::Buffer::init(generate_304 => 1)->is_cached();
		my $on = defined($CGI::Buffer::cache) ? 'on' : 'off';
		CGI::Buffer::set_options(cache => undef);
		my $off = defined($CGI::Buffer::cache) ? 'on' : 'off';
		print "Content-Type: text/plain\n\n$rc $chained $on $off";
	});
	is($r->{body}, 'CGI::Buffer 0 on off', 'returns the package name, and cache => undef turns it off');
	like((header($r, 'X-Cache-Lookup'))[0], qr/^MISS/, 'nothing is stored once the cache is off');
};

subtest 'Messages can be replaced, with plurals' => sub {
	my $r = run_script(code => q{
		CGI::Buffer::init(messages => {
			unknown_option => 'init: option inconnue %{option}s',
			too_late => { one => '%{count}d caractere', other => '%{count}d caracteres' },
		});
		CGI::Buffer::init(couleur => 'bleu');
		print 'x';
		CGI::Buffer::init(generate_304 => 1);
		print 'y';
		CGI::Buffer::init(generate_304 => 1);
		print "\n\n";
	});
	like($r->{stderr}, qr/CGI::Buffer: init: option inconnue couleur/, 'replaced message');
	like($r->{stderr}, qr/CGI::Buffer: 1 caractere at/, 'singular');
	like($r->{stderr}, qr/CGI::Buffer: 2 caracteres at/, 'plural');
};

subtest 'The default too_late message' => sub {
	my $r = run_script(code => q{
		print 'x';
		CGI::Buffer::init(generate_304 => 1);
		print "y\n\n";
	});
	like($r->{stderr}, qr/Too late to call init, 1 character has been printed/, 'singular');
};

subtest 'Messages with missing values, and unknown keys, are still given' => sub {
	my $r = run_script(code => q{
		print "Content-Type: text/plain\n\n", CGI::Buffer::_i18n('bad_option', { option => 'x' }), '|',
			CGI::Buffer::_i18n('no_such_message');
	});
	is($r->{body}, 'CGI::Buffer: init: x , ignored|CGI::Buffer: no_such_message', 'no warnings, nothing lost');
	is($r->{stderr}, '', 'no warnings');
};

subtest 'CGI::Info is only loaded when needed' => sub {
	# This END block is compiled before CGI::Buffer's, so runs after it
	my $r = run_script(
		preamble => q{END { print STDERR 'CGI::Info ', ($INC{'CGI/Info.pm'} ? 'loaded' : 'not loaded'), "\n" }} . "\n",
		code => q{print "Content-Type: text/html\n\n<html><body>hello</body></html>";},
		env => { HTTP_ACCEPT_ENCODING => 'gzip' },
	);
	like($r->{stderr}, qr/CGI::Info not loaded/, 'not loaded for an ETag and compression');

	$r = run_script(
		preamble => q{END { print STDERR 'CGI::Info ', ($INC{'CGI/Info.pm'} ? 'loaded' : 'not loaded'), "\n" }} . "\n",
		init => 'optimise_content => 1',
		code => q{print "Content-Type: text/html\n\n<html><body>hello</body></html>";},
	);
	like($r->{stderr}, qr/CGI::Info loaded/, 'loaded by optimise_content, which needs the host name');
};

done_testing();
