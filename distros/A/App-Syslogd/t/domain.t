#!/usr/bin/env perl

# Domain tests: equivalence partitioning and boundary value analysis for
# every input of every public routine, as documented in the "Domains"
# part of each API SPECIFICATION.
#
# Strategy
#	* One subtest per parameter.  From each valid and each invalid
#	  partition one typical value is tested (not every value), then the
#	  exact edges of every range: just below the minimum, the minimum,
#	  the maximum, just above the maximum.
#	* Invalid values must fail with the documented message, and leave the
#	  caller's $_ and $! as they were.
#	* Text inputs are tested with non-ASCII partitions: umlauts, emoji
#	  (including joined emoji), Zalgo text and the right-to-left override,
#	  as UTF-8 bytes (the documented form) and, where documented, as Perl
#	  character strings.
#	* Combinations put several parameters at their limits at once.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Errno qw(EPERM);
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Most;
use Test::Returns;

use App::Syslogd;
use App::Syslogd::I18N;

Readonly my %CONFIG => (
	min_port => 0,
	max_port => 65_535,
	last_privileged_port => 1023,
	unprivileged_port => 5514,
	max_pri => 191,
	min_message_length => 2,
	max_datagram => 65_535,
	facility_size => 8,			# severities per facility
	peer_ip => '192.0.2.1',
	default_facility => 1,			# user.notice, RFC 3164 4.3.3
	default_severity => 5,
	sentinel_underscore => 'caller $_',
	sentinel_errno => EPERM,
);

# Text partitions, as UTF-8 bytes (the form the module documents)
Readonly my %TEXT => (
	'German umlauts' => "Gr\xc3\xbc\xc3\x9fe aus K\xc3\xb6ln",
	'emoji' => "\xf0\x9f\x98\x80",
	'joined emoji (family, with ZWJ)' => "\xf0\x9f\x91\xa8\xe2\x80\x8d\xf0\x9f\x91\xa9\xe2\x80\x8d\xf0\x9f\x91\xa7",
	'Zalgo (combining marks)' => "Z\xcc\x8d\xcc\x8e\xcc\x84\xcd\x9ba\xcc\x80\xcc\x81lgo",
	'right-to-left override' => "user\xe2\x80\xaegpj.exe",
	'invalid UTF-8' => "\xff\xfe\xc3\x28",
	'C1 control byte' => "\x85",
);

my $PEER = pack_sockaddr_in(514, inet_aton($CONFIG{peer_ip}));
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

sub new_path { my $name = shift // ('domain' . ++$serial . '.csv'); return File::Spec->catfile($dir, $name) }

# The documented validator message for an invalid option.  The validator
# puts its own line number first, so only the documented part is matched.
sub invalid { my ($name, $why) = @_; return qr/validate_strict: Parameter '\Q$name\E' .*\Q$why\E/ }

# An invalid value must fail as documented and leave $_ and $! alone
sub rejects {
	my ($code, $error, $name) = @_;
	local $_ = $CONFIG{sentinel_underscore};
	local $! = $CONFIG{sentinel_errno};
	throws_ok { $code->() } $error, $name;
	is($_, $CONFIG{sentinel_underscore}, "$name: \$_ untouched");
	is($! + 0, $CONFIG{sentinel_errno}, "$name: \$! untouched");
	return;
}

sub accepts { my ($code, $name) = @_; my $result; lives_ok { $result = $code->() } $name; return $result }

sub slurp_raw { my $file = shift; open(my $fh, '<:raw', $file) or die "$file: $!"; local $/; return scalar(<$fh>) }

# The longest file name this file system allows, if the system says
sub name_max {
	return undef if($^O eq 'MSWin32');
	require POSIX;
	my $max = eval { POSIX::pathconf($dir, POSIX::_PC_NAME_MAX()) };
	return ($max && $max > 0) ? $max : undef;
}

# ===========================================================================
# App::Syslogd::new
# ===========================================================================

subtest 'new: port' => sub {
	# Partitions: 0 (kernel chooses), 1-1023, 1024-65535, numeric strings;
	# invalid: fractions, hex, underscores, text, "", references
	foreach my $port ($CONFIG{min_port}, 1, $CONFIG{last_privileged_port}, $CONFIG{last_privileged_port} + 1,
		$CONFIG{unprivileged_port}, $CONFIG{max_port} - 1, $CONFIG{max_port}) {
		is(accepts(sub { App::Syslogd->new(port => $port)->port() }, "port $port"), $port, "port $port kept");
	}
	my %numeric = (' 514 ' => 514, '+514' => 514, '0514' => 514, '5e2' => 500, '5.0' => 5);
	foreach my $text (sort keys %numeric) {
		is(App::Syslogd->new(port => $text)->port(), $numeric{$text}, "numeric string '$text' is $numeric{$text}");
	}

	rejects(sub { App::Syslogd->new(port => $CONFIG{min_port} - 1) }, invalid('port', 'must be at least 0'), 'just below the minimum');
	rejects(sub { App::Syslogd->new(port => $CONFIG{max_port} + 1) }, invalid('port', 'must be no more than 65535'), 'just above the maximum');
	foreach my $bad ('514.5', '0x10', '1_000', 'syslog', '', "\x{661}") {
		# Shown escaped: a non-ASCII test name would print as a wide character
		my $shown = join('', map { /[\x20-\x7e]/ ? $_ : sprintf('\\x{%x}', ord) } split //, $bad);
		rejects(sub { App::Syslogd->new(port => $bad) }, invalid('port', 'must be an integer'), "not a whole number: '$shown'");
	}
	rejects(sub { App::Syslogd->new(port => [514]) }, invalid('port', ''), 'a reference');
};

subtest 'new and open_socket: address' => sub {
	# Partitions: IPv4 literal, IPv6 literal, host name (any non-empty
	# string passes new()); invalid: "" (new), not this machine's address
	# (open_socket)
	foreach my $address ('0.0.0.0', '127.0.0.1', '::', '::1', 'localhost', 'a') {
		is(accepts(sub { App::Syslogd->new(address => $address)->address() }, "new() accepts '$address'"), $address, "'$address' kept");
	}
	rejects(sub { App::Syslogd->new(address => '') }, invalid('address', ''), 'the empty string');

	# TEST-NET-1 is never configured on a real interface
	rejects(sub { App::Syslogd->new(address => $CONFIG{peer_ip}, port => $CONFIG{min_port})->open_socket() },
		qr/\A\QCould not create a UDP socket on $CONFIG{peer_ip} port 0: \E/, 'an address this machine does not have');

	my $server = App::Syslogd->new(address => '127.0.0.1', port => $CONFIG{min_port})->open_socket();
	returns_ok($server->port(), { type => 'integer', min => 1, max => $CONFIG{max_port} }, 'after open_socket() with port 0: 1-65535');
};

subtest 'new and reopen_log: file' => sub {
	# Partitions: any non-empty byte string, including UTF-8 names;
	# boundaries: a one-byte name, the system's longest name and one byte
	# more; invalid: "", references
	my $short = new_path('a');
	accepts(sub { App::Syslogd->new(file => $short)->reopen_log() }, 'a one-byte name');
	ok(-s $short, '...is created');

	foreach my $case (sort grep { !/invalid|C1/ } keys %TEXT) {
		my $path = new_path($TEXT{$case} . '.csv');
		accepts(sub { App::Syslogd->new(file => $path)->reopen_log() }, "a name in $case (UTF-8 bytes)");
		ok(-s $path, "...is created under exactly that name");
	}

	SKIP: {
		my $max = name_max() or skip('the system does not report its longest file name', 4);
		my $longest = new_path('n' x ($max - length('.csv')) . '.csv');
		accepts(sub { App::Syslogd->new(file => $longest)->reopen_log() }, "a $max-byte name (the longest allowed)");
		ok(-s $longest, '...is created');
		my $too_long = new_path('n' x ($max + 1 - length('.csv')) . '.csv');
		rejects(sub { App::Syslogd->new(file => $too_long)->reopen_log() }, qr/\A\QCould not open log file $too_long: \E/, 'one byte too long');
	}

	rejects(sub { App::Syslogd->new(file => '') }, invalid('file', ''), 'the empty string');
	rejects(sub { App::Syslogd->new(file => [$short]) }, invalid('file', ''), 'a reference');
};

subtest 'new: resolve' => sub {
	# Partitions: the true words, the false words, every other spelling
	foreach my $true (qw(1 true TRUE yes on)) {
		is(App::Syslogd->new(resolve => $true)->{resolve}, 1, "'$true' is true");
	}
	foreach my $false (qw(0 false FALSE no off)) {
		is(App::Syslogd->new(resolve => $false)->{resolve}, 0, "'$false' is false");
	}
	foreach my $bad ('', 2, -1, 'Yes', 'On', ' 1', 't', 'maybe') {
		rejects(sub { App::Syslogd->new(resolve => $bad) }, invalid('resolve', 'must be a boolean'), "'$bad'");
	}
};

subtest 'new: dns_ttl and dns_cache_bytes' => sub {
	# Partitions: whole numbers from the minimum up (no upper limit);
	# invalid: below the minimum, fractions, text
	foreach my $ttl (0, 1, 1e9) {
		is(App::Syslogd->new(dns_ttl => $ttl)->{dns_ttl}, $ttl, "dns_ttl $ttl");
	}
	rejects(sub { App::Syslogd->new(dns_ttl => -1) }, invalid('dns_ttl', 'must be at least 0'), 'dns_ttl just below the minimum');
	rejects(sub { App::Syslogd->new(dns_ttl => 1.5) }, invalid('dns_ttl', 'must be an integer'), 'dns_ttl a fraction');

	foreach my $bytes (1, 2, 1e9) {
		lives_ok { App::Syslogd->new(dns_cache_bytes => $bytes) } "dns_cache_bytes $bytes";
	}
	rejects(sub { App::Syslogd->new(dns_cache_bytes => 0) }, invalid('dns_cache_bytes', 'must be a positive number'), 'dns_cache_bytes just below the minimum');
	rejects(sub { App::Syslogd->new(dns_cache_bytes => 'lots') }, invalid('dns_cache_bytes', 'must be an integer'), 'dns_cache_bytes text');
};

subtest 'new: language' => sub {
	# Partitions: supported tags, unsupported or malformed tags (English),
	# and "" (refused)
	foreach my $tag ('en', 'EN', 'en-gb', 'en_GB', 'fr', 'x', 'i-klingon', '../x', 'en;x') {
		isa_ok(App::Syslogd->new(language => $tag)->{lh}, 'App::Syslogd::I18N::en', "tag '$tag'");
	}
	rejects(sub { App::Syslogd->new(language => '') }, invalid('language', ''), 'the empty string');
};

subtest 'new: cache and socket' => sub {
	# Partitions: an object with the method, and everything else
	my $cache = bless {}, 'DomainCache';
	{ no strict 'refs'; *{'DomainCache::compute'} = sub { return } }
	my $socket = bless {}, 'DomainSocket';
	{ no strict 'refs'; *{'DomainSocket::recv'} = sub { return } }
	lives_ok { App::Syslogd->new(cache => $cache, socket => $socket) } 'objects with compute() and recv()';
	foreach my $bad ({ compute => 1 }, sub { }, \*STDOUT, bless({}, 'NoMethods')) {
		rejects(sub { App::Syslogd->new(cache => $bad) }, invalid('cache', ''), 'cache: ' . ref($bad));
		rejects(sub { App::Syslogd->new(socket => $bad) }, invalid('socket', ''), 'socket: ' . ref($bad));
	}
};

subtest 'new: options at their limits together' => sub {
	# Purpose: limits combine without interfering, and one invalid option
	# among limits is still the one reported
	my $server = accepts(sub {
		App::Syslogd->new(port => $CONFIG{max_port}, address => 'a', file => new_path('b'),
			resolve => 0, dns_ttl => 0, dns_cache_bytes => 1, language => 'x')
	}, 'every option at a limit');
	is($server->port(), $CONFIG{max_port}, 'port at its maximum');
	is($server->{dns_ttl}, 0, 'dns_ttl at its minimum');

	rejects(sub { App::Syslogd->new(port => $CONFIG{min_port}, dns_ttl => 0, dns_cache_bytes => 0) },
		invalid('dns_cache_bytes', 'must be a positive number'), 'minimum port and TTL, cache one below its minimum');
	rejects(sub { App::Syslogd->new(port => $CONFIG{max_port} + 1, dns_cache_bytes => 1) },
		invalid('port', 'must be no more than 65535'), 'port one above its maximum, cache at its minimum');

	SKIP: {
		my $ipv6 = eval { App::Syslogd->new(address => '::1', port => $CONFIG{min_port})->open_socket() }
			or skip('no IPv6 loopback here', 1);
		returns_ok($ipv6->port(), { type => 'integer', min => 1, max => $CONFIG{max_port} }, 'IPv6 address with port 0');
	}
};

# ===========================================================================
# App::Syslogd::parse_message
# ===========================================================================

subtest 'parse_message: length' => sub {
	# Partitions: too short (undef), long enough; boundaries: 1 and 2
	# characters after trailing CR/LF/NUL are removed, and the largest
	# UDP datagram
	is(App::Syslogd->parse_message('x' x ($CONFIG{min_message_length} - 1)), undef, 'one character below the minimum: undef');
	ok(App::Syslogd->parse_message('x' x $CONFIG{min_message_length}), 'the minimum length: a record');
	is(App::Syslogd->parse_message("x\r\n\0"), undef, 'the minimum is counted after removing terminators');
	is(App::Syslogd->parse_message(undef), undef, 'undef');
	is(App::Syslogd->parse_message(''), undef, 'the empty string');

	my $largest = '<13>' . ('m' x ($CONFIG{max_datagram} - length('<13>')));
	is(length(App::Syslogd->parse_message($largest)->{message}), $CONFIG{max_datagram} - length('<13>'), 'the largest datagram, whole');
};

subtest 'parse_message: PRI' => sub {
	# Partitions: valid PRI (0-191, no extra leading zeros), invalid PRI,
	# no PRI.  Boundaries: 0, 191 and 192, and the edges between
	# facilities (PRI 7/8 ... 183/184)
	my $schema = {
		type => 'hashref',
		schema => {
			facility => { type => 'integer', min => 0, max => 23 },
			severity => { type => 'integer', min => 0, max => 7 },
			message => { type => 'string' },
			valid => { type => 'boolean' },
		},
	};
	foreach my $pri (0, 1, 7, 8, 15, 16, 183, 184, 190, $CONFIG{max_pri}) {
		my $record = App::Syslogd->parse_message("<$pri>m");
		returns_ok($record, $schema, "PRI $pri: the record schema");
		is_deeply([@{$record}{qw(facility severity valid)}],
			[int($pri / $CONFIG{facility_size}), $pri % $CONFIG{facility_size}, 1], "PRI $pri splits correctly");
	}
	foreach my $bad ($CONFIG{max_pri} + 1, 999, 1000, '00', '013', '-1', '', '1a') {
		my $record = App::Syslogd->parse_message("<$bad>m");
		is_deeply([@{$record}{qw(facility severity message valid)}],
			[$CONFIG{default_facility}, $CONFIG{default_severity}, "<$bad>m", 0], "invalid PRI '$bad': user.notice, whole text");
	}
};

subtest 'parse_message: formats' => sub {
	# Partitions: RFC 3164 and RFC 5424 bodies are both kept verbatim
	# after the PRI; only the PRI is decoded
	my %formats = (
		'RFC 3164' => 'Oct 11 22:14:15 mymachine su: failed for lonvick',
		'RFC 5424' => '1 2003-10-11T22:14:15.003Z mymachine.example.com su - ID47 [exampleSDID@32473 iut="3"] BOM',
	);
	foreach my $format (sort keys %formats) {
		is(App::Syslogd->parse_message("<34>$formats{$format}")->{message}, $formats{$format}, "$format: body kept verbatim");
	}
};

subtest 'parse_message: characters' => sub {
	# Partitions: control bytes (escaped) and every other byte (kept,
	# length unchanged); character strings are returned as characters
	foreach my $case (sort keys %TEXT) {
		my $record = App::Syslogd->parse_message("<13>$TEXT{$case}");
		is($record->{message}, $TEXT{$case}, "$case: unchanged");
		is(length($record->{message}), length($TEXT{$case}), "$case: same length");
	}
	is(App::Syslogd->parse_message("<13>a\x00b\x1fc\x7fd")->{message}, 'a\x00b\x1Fc\x7Fd', 'control bytes: \xNN');

	my $characters = "Gr\x{fc}\x{df}e \x{1F600} \x{202E}";
	my $record = App::Syslogd->parse_message("<13>$characters");
	is($record->{message}, $characters, 'a character string: unchanged characters');
	is(length($record->{message}), length($characters), '...same length in characters');
};

# ===========================================================================
# App::Syslogd::process
# ===========================================================================

subtest 'process: sender' => sub {
	# Partitions: packed IPv4, packed IPv6, everything else (empty host)
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file, resolve => 0)->reopen_log();
	my @expected;

	$server->process('<13>v4', $PEER);
	push @expected, $CONFIG{peer_ip};
	SKIP: {
		my $v6 = eval { Socket::pack_sockaddr_in6(514, Socket::inet_pton(Socket::AF_INET6(), '2001:db8::1')) }
			or skip('no IPv6 address packing here', 1);
		$server->process('<13>v6', $v6);
		push @expected, '2001:db8::1';
		pass('IPv6 sender written');
	}
	foreach my $other (undef, '', 'short', [$PEER]) {
		$server->process('<13>other', $other);
		push @expected, '';
	}
	open(my $fh, '<:raw', $file) or die;
	my @hosts = map { /\A"([^"]*)"/ ? $1 : '?' } (<$fh>)[1 .. @expected];
	is_deeply(\@hosts, \@expected, 'IPv4 and IPv6 give the address; everything else an empty Host');
};

subtest 'process: characters reach the file byte for byte' => sub {
	# Partitions: each UTF-8 text partition is written unchanged
	my $file = new_path();
	my $server = App::Syslogd->new(file => $file, resolve => 0)->reopen_log();
	my @cases = sort keys %TEXT;
	$server->process("<13>$TEXT{$_}", $PEER) foreach(@cases);
	my @lines = split(/\n/, slurp_raw($file));
	foreach my $i (0 .. $#cases) {
		is($lines[$i + 1], qq{"$CONFIG{peer_ip}","1","5","$TEXT{$cases[$i]}"}, "$cases[$i]: written byte for byte");
	}
};

# ===========================================================================
# App::Syslogd::i18n and App::Syslogd::I18N
# ===========================================================================

subtest 'i18n and text: key' => sub {
	# Partitions: known keys, unknown keys (returned as text), and
	# undef/""/references (refused)
	my $server = App::Syslogd->new(language => 'en');
	like($server->i18n('listening', { address => 'a', port => 1 }), qr/\ASyslog server listening/, 'a known key');
	is($server->i18n('no_such_key'), 'no_such_key', 'an unknown key');
	foreach my $bad (undef, '', ['listening']) {
		rejects(sub { $server->i18n($bad) }, qr/\AA message key is needed at /, 'key: ' . (defined($bad) ? (ref($bad) || "''") : 'undef'));
	}
};

subtest 'i18n and text: values' => sub {
	# Partitions: a hash reference (any text, including non-ASCII), undef
	# (no values), and anything else (refused)
	my $lh = App::Syslogd::I18N->handle('en');
	my %characters = ('umlauts' => "K\x{f6}ln", 'emoji' => "\x{1F600}", 'RTL' => "\x{202E}txt", 'Zalgo' => "Z\x{30d}\x{30e}");
	foreach my $case (sort keys %characters) {
		my $text = $lh->text('open_failed', { file => $characters{$case}, error => 'E' });
		is($text, "Could not open log file $characters{$case}: E", "$case: copied unchanged");
	}
	is($lh->text('open_failed'), 'Could not open log file : ', 'undef: missing values are empty');
	foreach my $bad ([1], sub { }, 'port') {
		rejects(sub { $lh->text('listening', $bad) }, qr/\AMessage values must be a hash reference/, 'values: ' . (ref($bad) || 'plain string'));
	}
};

subtest 'i18n and text: count' => sub {
	# Partitions: exactly 1 (singular), every other number (plural), and
	# text (counts as 0)
	my $lh = App::Syslogd::I18N->handle('en');
	my %counts = (1 => '1 message', 0 => '0 messages', 2 => '2 messages', -1 => '-1 messages', 1.5 => '1.5 messages', many => '0 messages');
	foreach my $count (sort keys %counts) {
		like($lh->text('shutdown', { count => $count }), qr/recording \Q$counts{$count}\E\z/, "count $count: $counts{$count}");
	}
};

subtest 'handle: tag' => sub {
	# Partitions: supported, unsupported, malformed, very long, undef/""
	foreach my $tag ('en', 'en-gb', 'EN', 'fr', '../x', 'en;x', 'x' x 1000, undef, '') {
		isa_ok(App::Syslogd::I18N->handle($tag), 'App::Syslogd::I18N::en', 'tag ' . (defined($tag) ? "'" . substr($tag, 0, 10) . "'" : 'undef'));
	}
};

subtest 'gender' => sub {
	# Partitions: male (any case), female (any case), everything else
	my $lh = App::Syslogd::I18N->handle('en');
	my %forms = (male => 'M', MALE => 'M', Male => 'M', female => 'F', FeMaLe => 'F', m => 'N', f => 'N', '' => 'N', other => 'N');
	foreach my $gender (sort keys %forms) {
		is($lh->gender($gender, 'M', 'F', 'N'), $forms{$gender}, "'$gender'");
	}
	is($lh->gender(undef, 'M', 'F', 'N'), 'N', 'undef');
	is($lh->gender([], 'M', 'F', 'N'), 'N', 'a reference');
};

done_testing();
