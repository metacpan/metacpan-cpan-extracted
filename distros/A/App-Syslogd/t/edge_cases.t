#!/usr/bin/env perl

# Edge cases: hostile, pathological, boundary and security tests that try
# to break or subvert App::Syslogd and App::Syslogd::I18N.
#
# Strategy
#	* Everything is judged against the POD: a hostile input must give the
#	  documented error or the documented safe behaviour, never a crash, a
#	  hang, a silent loss, a forged log line or a command run.
#	* Upstream failures are simulated with Test::Mockingbird: a resolver
#	  that times out, a cache that dies or answers nothing, a CSV writer
#	  that refuses, a socket constructor that fails, a socket that drops
#	  the connection, and a disk that fills up part way through a write
#	  (syswrite replaced with mock_core before the module is compiled).
#	* The filesystem is attacked for real: devices, directories, FIFOs,
#	  dangling and live symlinks, unwritable files and hostile file names.
#	* Tests marked "regression" cover bugs found while writing these tests;
#	  each must never come back.
#
# Files are processed one at a time, in this order:
#	1. lib/App/Syslogd.pm
#	2. lib/App/Syslogd/I18N.pm

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Errno qw(ENOSPC EISDIR ENOENT ENXIO ENOTDIR EACCES ECONNREFUSED ENAMETOOLONG ELOOP);
use Fcntl ();
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(weaken);
use Socket qw(pack_sockaddr_in inet_aton);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use Text::CSV;
use Time::HiRes qw(time);

# The disk-full simulation.  CORE::GLOBAL overrides only reach code that is
# compiled after them, so this must be installed before App::Syslogd is
# loaded.  $SYSWRITE_MODE chooses the behaviour; 'real' passes through.
our $SYSWRITE_MODE = 'real';
BEGIN {
	mock_core('syswrite' => sub {
		my ($real, $fh, $buffer, $length, $offset) = @_;
		$length //= length($buffer);
		$offset //= 0;
		if($main::SYSWRITE_MODE eq 'full') {		# nothing fits
			$! = Errno::ENOSPC();
			return undef;
		}
		if($main::SYSWRITE_MODE eq 'half') {		# half fits, then full
			$main::SYSWRITE_MODE = 'full';
			return $real->($fh, $buffer, int($length / 2), $offset);
		}
		if($main::SYSWRITE_MODE eq 'stuck') {		# no progress, no error
			$! = 0;
			return 0;
		}
		return $real->($fh, $buffer, $length, $offset);
	});
}

use App::Syslogd;
use App::Syslogd::I18N;

Readonly my %CONFIG => (
	peer_ip => '192.0.2.1',			# RFC 5737 TEST-NET-1
	unprivileged_port => 5514,
	max_port => 65_535,
	max_datagram => 65_535,
	huge_digits => 1_000_000,		# a PRI far too long to be one
	huge_value => 'v' x 1_000_000,		# a 1 MB message value
	time_limit => 2,			# seconds any single parse may take
	fifo_timeout => 5,			# seconds before a FIFO open is a hang
	header => [qw(Host facility severity msg)],
	long_name_bytes => 1024,		# beyond any NAME_MAX
	read_only_mode => 0400,
	no_access_mode => 0500,
	user_notice => [1, 5],
);

my $PEER = pack_sockaddr_in(514, inet_aton($CONFIG{peer_ip}));
my $dir = tempdir(CLEANUP => 1);
my $serial = 0;
my $WINDOWS = ($^O eq 'MSWin32');
my $ROOT = (!$WINDOWS && $> == 0);	# root ignores file permissions

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub verbose_diag { diag(@_) if($ENV{TEST_VERBOSE}); return }

sub new_path { my $name = shift // ('edge' . ++$serial . '.csv'); return File::Spec->catfile($dir, $name) }

sub errno_text { my $errno = shift; local $! = $errno; return "$!" }

# croak/carp add " at FILE line N."; match the documented message exactly
sub exact { my $message = shift; return qr/\A\Q$message\E at \S.* line \d+\.?\n?\z/s }

# Read a log back with a real CSV parser, as bytes
sub read_csv {
	my $file = shift;
	my $csv = Text::CSV->new({ binary => 1, decode_utf8 => 0 });
	open(my $fh, '<:raw', $file) or die "$file: $!";
	my $rows = $csv->getline_all($fh);
	close($fh);
	return $rows;
}

sub slurp_raw {
	my $file = shift;
	open(my $fh, '<:raw', $file) or die "$file: $!";
	local $/;
	return scalar(<$fh>);
}

# A server writing to a new file, with names off unless asked
sub new_server {
	my (%args) = @_;
	my $file = delete($args{file}) // new_path();
	return (App::Syslogd->new(file => $file, resolve => 0, %args)->reopen_log(), $file);
}

# Collect warnings from $code
sub warnings_from {
	my $code = shift;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };
	$code->();
	verbose_diag(explain(\@warnings)) if(@warnings);
	return \@warnings;
}

# A cache double whose compute() does whatever $behaviour says
{
	package HostileCache;
	sub new { my ($class, $behaviour) = @_; return bless { behaviour => $behaviour }, $class }
	sub compute { my $self = shift; return $self->{behaviour}->(@_) }
}

# A socket double driven by a list of steps (code refs)
{
	package ScriptedSocket;
	sub new { my ($class, @steps) = @_; return bless { steps => [@steps], closed => 0 }, $class }
	sub recv { my $self = $_[0]; my $step = shift(@{$self->{steps}}) or return undef; return $step->(\$_[1]) }
	sub close { $_[0]{closed}++; return 1 }
}

# An object that turns itself into a string
{
	package StringLike;
	use overload q{""} => sub { ${$_[0]} }, fallback => 1;
	sub new { my ($class, $text) = @_; return bless \$text, $class }
}

# ===========================================================================
# 1. lib/App/Syslogd.pm
# ===========================================================================

subtest 'new: hostile arguments are refused with the documented errors' => sub {
	# Purpose: every wrong type, size or shape is refused by the
	# validator, naming the parameter, before anything is opened
	my $cyclic = {};
	$cyclic->{self} = $cyclic;
	my %bad = (
		'port as an array' => [{ port => [514] }, qr/Parameter 'port'/],
		'port as a hash' => [{ port => {} }, qr/Parameter 'port'/],
		'port as code' => [{ port => sub { 514 } }, qr/Parameter 'port'/],
		'port as a typeglob' => [{ port => \*STDOUT }, qr/Parameter 'port'/],
		'port as a scalar ref' => [{ port => \'514' }, qr/Parameter 'port'/],
		'port 65536' => [{ port => $CONFIG{max_port} + 1 }, qr/Parameter 'port' \(65536\) must be no more than 65535/],
		'port -1' => [{ port => -1 }, qr/Parameter 'port' \(-1\) must be at least 0/],
		'port 1e100' => [{ port => 1e100 }, qr/Parameter 'port' .* must be no more than 65535/],
		'port in hex' => [{ port => '0x10' }, qr/Parameter 'port' \(0x10\) must be an integer/],
		'port with trailing text' => [{ port => '514; rm -rf /' }, qr/Parameter 'port' .* must be an integer/],
		'port NaN' => [{ port => 'NaN' }, qr/Parameter 'port'/],
		'port Inf' => [{ port => 'Inf' }, qr/Parameter 'port'/],
		'empty file name' => [{ file => '' }, qr/Parameter 'file'/],
		'file as a typeglob' => [{ file => \*STDOUT }, qr/Parameter 'file'/],
		'file as an array' => [{ file => ['/tmp/x'] }, qr/Parameter 'file'/],
		'empty address' => [{ address => '' }, qr/Parameter 'address'/],
		'resolve 2' => [{ resolve => 2 }, qr/Parameter 'resolve' \(2\) must be a boolean/],
		'resolve as an array' => [{ resolve => [] }, qr/Parameter 'resolve'/],
		'empty language' => [{ language => '' }, qr/Parameter 'language'/],
		'negative dns_ttl' => [{ dns_ttl => -1 }, qr/Parameter 'dns_ttl'/],
		'zero dns_cache_bytes' => [{ dns_cache_bytes => 0 }, qr/Parameter 'dns_cache_bytes'/],
		'cache without compute' => [{ cache => bless({}, 'NoCompute') }, qr/Parameter 'cache'/],
		'cache as a plain hash' => [{ cache => { compute => 1 } }, qr/Parameter 'cache'/],
		'cache as a cyclic plain hash' => [{ cache => $cyclic }, qr/Parameter 'cache'/],
		'socket as a typeglob' => [{ socket => \*STDIN }, qr/Parameter 'socket'/],
		'socket as code' => [{ socket => sub { } }, qr/Parameter 'socket'/],
		'unknown parameter' => [{ evil => 1 }, qr/Unknown parameter 'evil'/],
	);
	foreach my $case (sort keys %bad) {
		my ($args, $error) = @{$bad{$case}};
		throws_ok { App::Syslogd->new($args) } $error, $case;
	}

	# A list with an odd number of items is not "pairs"
	dies_ok { App::Syslogd->new('port') } 'an odd-length argument list';
	dies_ok { App::Syslogd->new({ port => 1 }, 'extra') } 'a hashref followed by more arguments';
};

subtest 'new: boundaries that are allowed' => sub {
	# Purpose: the edges of every range are accepted, undef means
	# "default", and duplicate keys follow Perl's last-one-wins rule
	is(App::Syslogd->new(port => 0)->port(), 0, 'port 0 (the kernel chooses)');
	is(App::Syslogd->new(port => $CONFIG{max_port})->port(), $CONFIG{max_port}, 'port 65535');
	is(App::Syslogd->new(port => undef)->port(), 514, 'port undef: the default');
	is(App::Syslogd->new(port => 1, port => 2)->port(), 2, 'duplicate keys: the last one wins');
	lives_ok { App::Syslogd->new(dns_ttl => 0) } 'dns_ttl 0 (do not remember names)';
	lives_ok { App::Syslogd->new(dns_cache_bytes => 1) } 'a one-byte DNS cache';
	my $cyclic = HostileCache->new(sub { 'x' });
	$cyclic->{self} = $cyclic;
	lives_ok { App::Syslogd->new(cache => $cyclic) } 'a cache object that refers to itself';
	weaken($cyclic->{self});
};

subtest 'new: hostile settings from the environment are refused' => sub {
	# Purpose: Object::Configure lets the environment set options; a
	# hostile value there must be refused like an argument
	foreach my $value ('514; rm -rf /', '$(reboot)', '70000', '-1', '') {
		local $ENV{App__Syslogd__port} = $value;
		next if($value eq '');	# an empty variable is ignored by Object::Configure
		throws_ok { App::Syslogd->new() } qr/Parameter 'port'/, "App__Syslogd__port='$value'";
	}
};

subtest 'security: the language tag cannot load code or files' => sub {
	# Purpose: Locale::Maketext turns the tag into a module name and loads
	# it; a hostile tag must not run code or reach outside the lexicons
	my $sentinel = new_path('pwned');
	foreach my $tag (qq{en; system("touch $sentinel")}, '../../../../etc/passwd', 'en::Evil', 'x' x 10_000) {
		my $server = App::Syslogd->new(language => $tag);
		isa_ok($server->{lh}, 'App::Syslogd::I18N::en', 'falls back to English');
	}
	# A NUL would be cut off by the C library; it is refused outright
	throws_ok { App::Syslogd->new(language => "en\0x") } qr/Parameter 'language' .*must match pattern/, 'a NUL in the tag is refused';
	ok(!-e $sentinel, 'no command was run');
};

subtest 'parse_message: hostile and boundary datagrams' => sub {
	# Purpose: nothing a sender can put in a datagram crashes the parser,
	# escapes the escaping, or takes long
	my %cases = (
		'00' => [1, 5, '00', 0],			# two characters: the minimum
		'<' => undef,					# too short
		'<>' => [1, 5, '<>', 0],
		'<1' => [1, 5, '<1', 0],
		'1>' => [1, 5, '1>', 0],
		'<<13>>x' => [1, 5, '<<13>>x', 0],
		'<13' => [1, 5, '<13', 0],
		'<13>' => [1, 5, '', 1],
		'<0013>x' => [1, 5, '<0013>x', 0],
		"<13>\x1b[2J\x1b[31mred" => [1, 5, '\x1B[2J\x1B[31mred', 1],	# terminal escapes neutralised
		"<13>a\rb" => [1, 5, 'a\x0Db', 1],
		"\x00\x01" => [1, 5, '\x00\x01', 0],
		"<13>\xff\xfe\xc3\x28" => [1, 5, "\xff\xfe\xc3\x28", 1],	# invalid UTF-8 kept as bytes
		"<13>\x85\xc2\x85" => [1, 5, "\x85\xc2\x85", 1],		# C1 controls are not escaped
	);
	foreach my $datagram (sort keys %cases) {
		my $shown = join('', map { /[\x20-\x7e]/ ? $_ : sprintf('\\x%02X', ord) } split //, $datagram);
		my $want = $cases{$datagram};
		my $got = App::Syslogd->parse_message($datagram);
		if(!defined($want)) {
			is($got, undef, "'$shown': too short");
			next;
		}
		is_deeply($got, { facility => $want->[0], severity => $want->[1], message => $want->[2], valid => $want->[3] }, "'$shown'");
	}

	foreach my $terminators ("\r\n\0\n", "\0\0\0", "\n") {
		is(App::Syslogd->parse_message($terminators), undef, 'only terminators: too short');
	}

	# Huge inputs: bounded time, no truncation
	my $start = time();
	my $record = App::Syslogd->parse_message('<' . ('9' x $CONFIG{huge_digits}) . '>x');
	is($record->{valid}, 0, 'a million-digit PRI is invalid, not a huge number');
	my $max = App::Syslogd->parse_message('<13>' . ('m' x ($CONFIG{max_datagram} - 4)));
	is(length($max->{message}), $CONFIG{max_datagram} - 4, 'a maximum-size datagram is kept whole');
	App::Syslogd->parse_message('<' x $CONFIG{max_datagram});
	# Long runs of line ends or NULs not at the end: the worst case for the
	# trailing-terminator strip, which must stay linear
	App::Syslogd->parse_message(("\n" x ($CONFIG{max_datagram} - 1)) . 'x');
	App::Syslogd->parse_message(("\0" x ($CONFIG{max_datagram} - 1)) . 'x');
	App::Syslogd->parse_message(("\r\n" x ($CONFIG{max_datagram} / 2)) . "\x01");
	cmp_ok(time() - $start, '<', $CONFIG{time_limit}, 'pathological datagrams parse quickly (no ReDoS)');

	# Characters above 255 are not escaped: the POD asks callers to encode
	is(App::Syslogd->parse_message("<13>\x{263A}")->{message}, "\x{263A}", 'a character string is returned as characters');
};

subtest 'parse_message: references and context' => sub {
	# Purpose: a reference is refused (it would be logged as "ARRAY(0x..)");
	# an object that stringifies is accepted; context and the caller's
	# variables are left alone
	my %refs = (ARRAY => [1], HASH => {}, CODE => sub { }, GLOB => \*STDOUT, SCALAR => \'<13>x', Regexp => qr/x/);
	foreach my $type (sort keys %refs) {
		throws_ok { App::Syslogd->parse_message($refs{$type}) }
			exact("A datagram must be a string (the type given was $type)"), "a $type reference";
	}
	is(App::Syslogd->parse_message(StringLike->new('<13>overloaded'))->{message}, 'overloaded', 'a string-like object');

	my @list = App::Syslogd->parse_message('x');
	is(scalar(@list), 1, 'list context, too short: exactly one value (undef)');
	is($list[0], undef, '...which is undef');
	my @record = App::Syslogd->parse_message('<13>x');
	is(scalar(@record), 1, 'list context: one hash reference');

	my $original = "<13>keep\n";
	App::Syslogd->parse_message($original);
	is($original, "<13>keep\n", "the caller's string is not changed");

	# $_ aliased to a read-only constant: any assignment to $_ would die
	foreach ('read-only') {
		lives_ok { App::Syslogd->parse_message("<13>x\n") } '$_ is not modified';
	}
};

subtest 'security: log injection through the message' => sub {
	# Purpose: a sender cannot forge a log line, break the CSV, or reach
	# the terminal of whoever reads the log
	my ($server, $file) = new_server();
	my $forged = qq{<13>real\n"10.0.0.1","0","0","forged line"\r\n\x1b]0;owned\x07};
	$server->process($forged, $PEER);
	$server->process(q{<13>said "hi", then ""left"""}, $PEER);

	my $rows = read_csv($file);
	verbose_diag(explain($rows));
	is(scalar(@{$rows}), 3, 'two datagrams, two rows: no forged row');
	is($rows->[1][3], 'real\x0A"10.0.0.1","0","0","forged line"\x0D\x0A\x1B]0;owned\x07', 'newlines and escapes are written as \xNN');
	is($rows->[2][3], q{said "hi", then ""left"""}, 'quotes round-trip exactly');
	unlike(slurp_raw($file), qr/[\x00-\x09\x0B-\x1F\x7F]/, 'no control character reaches the file');

	# Spreadsheet formulas are kept as they are (documented in LIMITATIONS)
	$server->process('<13>=cmd|"/c calc"!A1', $PEER);
	is(read_csv($file)->[3][3], '=cmd|"/c calc"!A1', 'formula text stored unchanged, as documented');
};

subtest 'security (regression): hostile reverse-DNS names are escaped' => sub {
	# Purpose: whoever controls an address controls its PTR name.  A name
	# with a newline or a terminal escape went into the Host column raw.
	my $g = mock_scoped('App::Syslogd::getnameinfo' => sub {
		my (undef, $flags) = @_;
		return ('', $CONFIG{peer_ip}) if($flags & Socket::NI_NUMERICHOST());
		return ('', "evil\nhost\x1b[31m");
	});
	my ($server, $file) = new_server(resolve => 1, cache => HostileCache->new(sub { $_[2]->() }));
	$server->process('<13>x', $PEER);
	my $rows = read_csv($file);
	is(scalar(@{$rows}), 2, 'one row');
	is($rows->[1][0], 'evil\x0Ahost\x1B[31m', 'the host name is escaped');

	# A subclass that returns a hostile name is covered too
	{
		package HostileSubclass;
		our @ISA = ('App::Syslogd');
		sub _peer_name { return "sub\nclass" }
	}
	my $file2 = new_path();
	HostileSubclass->new(file => $file2, resolve => 0)->reopen_log()->process('<13>x', $PEER);
	is(read_csv($file2)->[1][0], 'sub\x0Aclass', "a subclass's host name is escaped as well");
};

subtest 'process: hostile sender addresses' => sub {
	# Purpose: anything that is not a packed address gives an empty Host
	# and never kills the server
	my ($server, $file) = new_server(resolve => 1, cache => HostileCache->new(sub { $_[2]->() }));
	my @peers = (undef, '', '0', 'x', 'garbage' x 1000, [$PEER], {}, \*STDIN, sub { $PEER });
	foreach my $peer (@peers) {
		lives_ok { $server->process('<13>p', $peer) } 'sender: ' . (defined($peer) ? (ref($peer) || 'string') : 'undef');
	}
	is_deeply([map { $_->[0] } @{read_csv($file)}[1 .. @peers]], [('') x @peers], 'every Host is empty');
};

subtest 'upstream (regression): the resolver and cache fail' => sub {
	# Purpose: a DNS timeout, a cache that dies (a remote cache timing
	# out) or a cache that answers nothing must fall back to the address.
	# A dying cache used to kill process() and with it the server.
	my $numeric_only = sub {
		my (undef, $flags) = @_;
		return ('', $CONFIG{peer_ip}) if($flags & Socket::NI_NUMERICHOST());
		return ('Temporary failure in name resolution', undef);	# EAI_AGAIN
	};
	my $g = mock_scoped('App::Syslogd::getnameinfo' => $numeric_only);

	my %caches = (
		'a DNS timeout' => HostileCache->new(sub { $_[2]->() }),
		'a cache that dies' => HostileCache->new(sub { die "Redis server went away\n" }),
		'a cache that returns undef' => HostileCache->new(sub { undef }),
		'a cache that returns ""' => HostileCache->new(sub { '' }),
	);
	foreach my $case (sort keys %caches) {
		my ($server, $file) = new_server(resolve => 1, cache => $caches{$case});
		my $warnings = warnings_from(sub { lives_ok { $server->process('<13>x', $PEER) } "$case: process() survives" });
		is(read_csv($file)->[1][0], $CONFIG{peer_ip}, "$case: the address is logged");
		is_deeply($warnings, [], "$case: no warnings");
	}

	# The numeric lookup failing too: an empty host, still no crash
	my $g2 = mock_scoped('App::Syslogd::getnameinfo' => sub { return ('Address family not supported', undef) });
	my ($server, $file) = new_server(resolve => 1);
	$server->process('<13>x', $PEER);
	is(read_csv($file)->[1][0], '', 'an undecodable address: an empty host');
};

subtest 'upstream (regression): the CSV writer refuses a row' => sub {
	# Purpose: if Text::CSV cannot build a line the row must be reported,
	# not silently written as nothing (or as the previous row)
	my ($server, $file) = new_server();
	$server->process('<13>before', $PEER);
	{
		my $g = mock_scoped(
			'Text::CSV::combine' => sub { 0 },
			'Text::CSV::error_diag' => sub { '2023 - EIQ - QUO character not allowed' },
		);
		my $warnings = warnings_from(sub { $server->process('<13>refused', $PEER) });
		is(scalar(@{$warnings}), 1, 'exactly one warning');
		like($warnings->[0] // '', exact("Could not write to log file $file: 2023 - EIQ - QUO character not allowed"), 'the documented message');
	}
	$server->process('<13>after', $PEER);
	is_deeply([map { $_->[3] } @{read_csv($file)}], ['msg', 'before', 'after'], 'no row lost after, none duplicated');
};

subtest 'I/O: the disk fills up part way through' => sub {
	# Purpose: ENOSPC during a write is a warning, the server goes on, a
	# half-written line is removed, and a write that makes no progress
	# cannot loop for ever.  Strategy: the syswrite mock_core set up above.
	my ($server, $file) = new_server();
	my $full = "Could not write to log file $file: " . errno_text(ENOSPC);

	foreach my $mode ('full', 'half') {
		local $SYSWRITE_MODE = $mode;
		my $warnings = warnings_from(sub { lives_ok { $server->process('<13>' . ('z' x 200), $PEER) } "$mode: survives" });
		is(scalar(@{$warnings}), 1, "$mode: one warning");
		like($warnings->[0] // '', exact($full), "$mode: says the disk is full");
	}

	{
		local $SYSWRITE_MODE = 'stuck';
		my $start = time();
		my $warnings = warnings_from(sub { $server->process('<13>stuck', $PEER) });
		cmp_ok(time() - $start, '<', $CONFIG{time_limit}, 'a write that makes no progress gives up');
		like($warnings->[0] // '', qr/\A\QCould not write to log file $file: \E/, 'and is reported');
	}

	$server->process('<13>recovered', $PEER);
	is_deeply(read_csv($file), [$CONFIG{header}, [$CONFIG{peer_ip}, 1, 5, 'recovered']], 'no half line left; writing resumes');

	# A new file whose header cannot be written is refused
	local $SYSWRITE_MODE = 'full';
	my $new_file = new_path();
	throws_ok { App::Syslogd->new(file => $new_file)->reopen_log() }
		exact("Could not write to log file $new_file: " . errno_text(ENOSPC)), 'header on a full disk: dies';
};

subtest 'filesystem: devices, directories and links are refused' => sub {
	# Purpose: the log must be a plain file of our own; anything else is
	# refused before a byte is written, and nothing outside is touched
	foreach my $device ('/dev/null', '/dev/urandom', '/dev/zero') {
		SKIP: {
			skip("$device does not exist here", 1) unless(-e $device);
			throws_ok { App::Syslogd->new(file => $device)->reopen_log() }
				exact("Refusing to log to $device: it must be a regular file, owned by this user, with exactly one link"),
				"character device $device";
		}
	}

	throws_ok { App::Syslogd->new(file => $dir)->reopen_log() } qr/\A\QCould not open log file $dir: \E/, 'a directory';

	my $not_a_dir = new_path();
	open(my $fh, '>', $not_a_dir) or die;
	close($fh);
	my $inside = File::Spec->catfile($not_a_dir, 'x.csv');
	throws_ok { App::Syslogd->new(file => $inside)->reopen_log() } qr/\A\QCould not open log file $inside: \E/, 'a path through a file';

	my $long = new_path('l' x $CONFIG{long_name_bytes});
	throws_ok { App::Syslogd->new(file => $long)->reopen_log() } qr/\ACould not open log file /, 'a name longer than the system allows';

	SKIP: {
		# Use the value: a bare constant in void context draws a warning
		skip('this system has no O_NOFOLLOW', 4) unless(defined(eval { Fcntl::O_NOFOLLOW() }));
		my $target = new_path('target');
		my $dangling = new_path('dangling');
		skip("cannot make a symbolic link: $!", 4) unless(eval { symlink($target, $dangling) });
		throws_ok { App::Syslogd->new(file => $dangling)->reopen_log() } qr/\A\QCould not open log file $dangling: \E/, 'a dangling symlink';
		ok(!-e $target, '...and its target is not created');

		open(my $t, '>', $target) or die;
		print {$t} "precious\n";
		close($t);
		throws_ok { App::Syslogd->new(file => $dangling)->reopen_log() } qr/\A\QCould not open log file $dangling: \E/, 'a live symlink';
		is(slurp_raw($target), "precious\n", '...and its target is untouched');
	}
};

subtest 'filesystem (regression): a FIFO does not hang the server' => sub {
	# Purpose: opening a FIFO for writing waits for a reader for ever.
	# Anyone could create one where a log in a shared directory (/tmp) goes and stop the
	# server starting.  It must be refused at once.  Strategy: a child
	# process with an alarm, so a regression fails instead of hanging.
	plan(skip_all => 'no FIFOs on Windows') if($WINDOWS);
	require POSIX;
	my $fifo = new_path('fifo');
	POSIX::mkfifo($fifo, 0600) or plan(skip_all => "cannot make a FIFO: $!");

	my $pid = fork();
	die "fork: $!" unless(defined($pid));
	if($pid == 0) {
		alarm($CONFIG{fifo_timeout});
		my $ok = eval { App::Syslogd->new(file => $fifo)->reopen_log(); 1 };
		# Either refusal is fine: the open itself (no reader), or the
		# check that the log is a regular file (systems where it opens)
		exit($ok ? 1 : ($@ =~ /\A(?:\QCould not open log file $fifo: \E|\QRefusing to log to $fifo: \E)/ ? 0 : 2));
	}
	waitpid($pid, 0);
	isnt($? & 127, 14, 'did not hang (no alarm)');
	is($? >> 8, 0, 'refused with a documented message');
};

subtest 'filesystem: permissions' => sub {
	# Purpose: an unwritable file or directory is refused with the
	# system's reason, not ignored
	plan(skip_all => 'root ignores permissions') if($ROOT);
	plan(skip_all => 'no Unix permissions on Windows') if($WINDOWS);

	my $read_only = new_path();
	open(my $fh, '>', $read_only) or die;
	close($fh);
	chmod($CONFIG{read_only_mode}, $read_only);
	throws_ok { App::Syslogd->new(file => $read_only)->reopen_log() }
		exact("Could not open log file $read_only: " . errno_text(EACCES)), 'a read-only file';

	my $locked = File::Spec->catdir($dir, 'locked' . ++$serial);
	mkdir($locked, $CONFIG{no_access_mode}) or die;
	my $inside = File::Spec->catfile($locked, 'x.csv');
	throws_ok { App::Syslogd->new(file => $inside)->reopen_log() }
		exact("Could not open log file $inside: " . errno_text(EACCES)), 'an unwritable directory';
	chmod(0700, $locked);
};

subtest 'filesystem: odd existing files' => sub {
	# Purpose: an empty file gets the header; a file with content must
	# already start with the header, or it is refused and left exactly as
	# it was (it is not ours to append to)
	my $header = qq{"Host","facility","severity","msg"};
	my %contents = (
		'an empty file' => ['', 1],
		'our header, LF' => ["$header\n", 1],
		'our header, CRLF (written on Windows)' => ["$header\r\n", 1],
		'a single newline' => ["\n", 0],
		'a single CRLF' => ["\r\n", 0],
		'the header without a line end' => [$header, 0],
		'the header, but not first' => ["\n$header\n", 0],
		'someone else\'s file' => ["root:x:0:0:root:/root:/bin/sh\n", 0],
	);
	foreach my $case (sort keys %contents) {
		my ($content, $ours) = @{$contents{$case}};
		my $file = new_path();
		open(my $fh, '>:raw', $file) or die;
		print {$fh} $content;
		close($fh);
		if($ours) {
			my ($server) = new_server(file => $file);
			$server->process('<13>x', $PEER);
			my $expected = ($content eq '') ? "$header\n" : $content;
			is(slurp_raw($file), $expected . qq{"$CONFIG{peer_ip}","1","5","x"\n}, "$case: accepted, appended to");
		} else {
			throws_ok { new_server(file => $file) }
				exact("Refusing to log to $file: it is not empty and does not start with the syslog header line"), "$case: refused";
			is(slurp_raw($file), $content, "$case: left exactly as it was");
		}
	}
};

subtest 'security: hostile file names are used literally' => sub {
	# Purpose: the name is passed to the system as it is, never to a
	# shell: metacharacters cannot run commands, and spaces, leading or
	# trailing blanks and newlines name exactly that file
	# The command in these names would create "injected" if a shell ever
	# saw them; it must exist neither here nor in the current directory
	my $sentinel = new_path('injected');
	my @names = ('with space.csv', ' leading.csv', 'trailing.csv ', 'semi;colon.csv', 'x; touch injected; .csv',
		'dollar$(touch x).csv', 'back`tick`.csv');
	push(@names, 'pipe|.csv', 'gt>lt<.csv', "new\nline.csv", "tab\t.csv") unless($WINDOWS);	# invalid on Windows
	foreach my $name (@names) {
		my $path = new_path($name);
		my $shown = $name =~ s/\n/\\n/gr =~ s/\t/\\t/gr;
		lives_ok { (new_server(file => $path))[0]->process('<13>x', $PEER) } "'$shown': works";
		ok(-s $path, "'$shown': that exact file was written");
	}
	ok(!-e $sentinel && !-e 'injected', 'no command was run');
	ok(!-e 'x', 'no stray file was created');
};

subtest 'run: upstream socket failures' => sub {
	# Purpose: a socket constructor that fails in odd ways, a socket that
	# throws, one that returns empty answers, and a refused connection
	foreach my $failure ([undef, 'undef'], [0, '0'], ['', 'an empty string']) {
		my ($value, $name) = @{$failure};
		my $g = mock_scoped('IO::Socket::IP::new' => sub { $IO::Socket::errstr = ''; $! = 0; return $value });
		throws_ok { App::Syslogd->new(port => $CONFIG{unprivileged_port}, address => '127.0.0.1')->open_socket() }
			qr/\A\QCould not create a UDP socket on 127.0.0.1 port $CONFIG{unprivileged_port}: \E/,
			"constructor returns $name: refused";
	}

	# The socket dies (a dropped connection, a broken driver)
	my $outer = sub { 'caller handler' };
	local $SIG{TERM} = $outer;
	my ($server) = new_server(socket => ScriptedSocket->new(sub { die "connection reset by peer\n" }));
	throws_ok { $server->run() } qr/\Aconnection reset by peer\n\z/, 'an exception from recv() is passed on';
	is($SIG{TERM}, $outer, "the caller's handler is restored");
	ok(!$server->{running}, 'not left running');

	# Empty answers and refused connections are not fatal
	my $stopper;
	my ($quiet) = new_server(socket => ScriptedSocket->new(
		sub { return '' },					# defined but empty sender
		sub { ${$_[0]} = undef; return $PEER },			# a sender but no data
		sub { $! = ECONNREFUSED; return undef },		# ICMP port unreachable
		sub { $stopper->stop(); $! = Errno::EINTR(); return undef },	# as a signal would
	));
	$stopper = $quiet;
	my $warnings = warnings_from(sub { lives_ok { $quiet->run() } 'odd recv() results do not kill run()' });
	is($quiet->count(), 0, 'nothing recorded');
	is(scalar(@{$warnings}), 1, 'one warning');
	like($warnings->[0] // '', exact('Error receiving a datagram: ' . errno_text(ECONNREFUSED)), 'for the refused connection');
};

subtest 'globals: nothing touches a read-only $_' => sub {
	# Purpose: with $_ aliased to a constant, any routine that assigned to
	# $_ without localising it would die
	my ($server) = new_server();
	foreach ('read-only') {
		lives_ok {
			$server->process("<13>x\n", $PEER);
			$server->port();
			$server->address();
			$server->count();
			$server->i18n('shutdown', { count => 1 });
			$server->reopen_log();
			$server->stop();
			App::Syslogd::I18N->handle('en')->text('listening', { address => 'a', port => 1 });
		} 'every public routine';
	}
};

# ===========================================================================
# 2. lib/App/Syslogd/I18N.pm
# ===========================================================================

subtest 'text: hostile keys and values' => sub {
	# Purpose: missing or wrong-type keys and values give the documented
	# errors; values are never interpreted as bracket notation
	my $lh = App::Syslogd::I18N->handle('en');
	foreach my $key (undef, '', [], {}) {
		throws_ok { $lh->text($key) } exact('A message key is needed'), 'key: ' . (defined($key) ? (ref($key) || "'$key'") : 'undef');
	}
	my %values = (ARRAY => [1], CODE => sub { }, GLOB => \*STDOUT, SCALAR => 'port=1');
	foreach my $type (sort keys %values) {
		throws_ok { $lh->text('listening', $values{$type}) }
			exact("Message values must be a hash reference (the type given was $type)"), "values: $type";
	}

	is($lh->text('open_failed', { file => '[_9][sprintf,%n,_1]~[', error => '[quant,_1,x]' }),
		'Could not open log file [_9][sprintf,%n,_1]~[: [quant,_1,x]', 'bracket notation in values is plain text');
	is(length($lh->text('recv_failed', { error => $CONFIG{huge_value} })),
		length('Error receiving a datagram: ') + length($CONFIG{huge_value}), 'a 1 MB value');

	my $cyclic = { file => 'F' };
	$cyclic->{error} = $cyclic;
	like($lh->text('open_failed', $cyclic), qr/\ACould not open log file F: HASH\(0x[0-9a-f]+\)\z/, 'a cyclic value does not hang');

	is($lh->text('shutdown', { count => 'many' }), 'Syslog server shutting down after recording 0 messages', 'a non-number count');
	is($lh->text('shutdown', { count => -1 }), 'Syslog server shutting down after recording -1 messages', 'a negative count');
	like($lh->text('shutdown', { count => 1e300 }), qr/recording 1e\+300 messages\z/i, 'a huge count');
};

subtest 'handle and gender: hostile input' => sub {
	# Purpose: any tag gives a working handle; gender never dies
	foreach my $tag (undef, '', '../x', "en\n", 'x' x 10_000, '*') {
		isa_ok(App::Syslogd::I18N->handle($tag), 'App::Syslogd::I18N', 'tag: ' . (defined($tag) ? length($tag) . ' characters' : 'undef'));
	}
	my $lh = App::Syslogd::I18N->handle('en');
	foreach my $gender ([], {}, \*STDOUT, 'MALE ', "female\n", "\x{263A}") {
		is($lh->gender($gender, 'M', 'F', 'N'), 'N', 'gender: ' . (ref($gender) || 'odd string') . ' is neutral');
	}
	is($lh->gender('male'), undef, 'missing forms: undef, not a crash');
};

done_testing();
