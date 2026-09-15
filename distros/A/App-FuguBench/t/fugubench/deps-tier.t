#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The two download tiers, the signify keys, and the fetch verb
# (DEPS-TIER, DEPS-KEYS, DEPS-FETCH).
#
# Each case runs bin/fugubench as a child with -Ilib. The child takes
# HOME and TMPDIR inside a temporary tree, and it runs in that tree,
# which holds no .toolingrc. PATH holds the downloader of this host
# and the three commands of a bin install, so no case resolves a
# cpanm, and each install lands under HOME.
#
# No case asks the network. One forked server over the core
# IO::Socket::INET answers on the loopback address, and each case
# takes a directory of its own under one document root. The case of a
# refused connection names a port that no server holds.
#
# The fixtures under t/fugubench/deps/fixture/ hold the public half
# of two signify keys, one release directory, and the signature of
# its SHA256 manifest. signify(1) made them one time, and no secret
# half and no organization key is in the repository.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use Digest::SHA    ();
use File::Basename qw(basename);
use File::Copy     qw(copy);
use File::Path     qw(make_path);
use File::Temp     qw(tempdir);
use FindBin        qw($RealBin);
use IO::Socket::INET ();
use POSIX            ();
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Process;

my $repo    = "$RealBin/../..";
my $program = "$repo/bin/fugubench";
my $fixture = "$RealBin/deps/fixture";

# Fugu::Process gives a child the named environment alone, and CI
# reaches the installed Fugu through PERL5LIB. Every child of this
# test therefore carries it.
my %LIB = defined $ENV{PERL5LIB} ? ( PERL5LIB => $ENV{PERL5LIB} ) : ();

# The verb verifies in-process, so the release of Fugu must hold the
# downloader and the perl engine of the verifier.
plan skip_all => 'the installed Fugu holds no Fugu::Curl'
    unless eval { require Fugu::Curl; 1 };
plan skip_all => 'the installed Fugu holds no Fugu::Signify'
    unless eval { require Fugu::Signify; 1 };
my $signify = eval { Fugu::Signify->new( engine => 'perl' ) };
plan skip_all => 'Fugu::Signify holds no perl engine'
    unless $signify && $signify->is_available;

my $downloader = Fugu::Curl->new;
plan skip_all => 'no downloader is on PATH' unless $downloader->is_available;

my $tree = tempdir( CLEANUP => 1 );
my $home = "$tree/home";
my $tmp  = "$tree/tmp";
my $srv  = "$tree/srv";
my $bin  = "$tree/bin";
make_path( $home, $tmp, $bin, "$srv/keys" );

# _link($path):
#	One command of the child PATH, as a link to the command of
#	this host.
sub _link ($path)
{
	symlink $path, "$bin/" . basename($path) or die "symlink $path";

	return;
}

# The PATH of each child: the downloader of this host, and the three
# commands that a bin install runs. A case that passes its check
# installs under HOME, which sits in the temporary tree.
_link( $downloader->command );
for my $name (qw(mkdir cp chmod)) {
	my $found = Fugu::Process->find_command($name);
	plan skip_all => "no $name is on PATH" unless defined $found;
	_link($found);
}

# _slurp($path):
#	The bytes of one file.
sub _slurp ($path)
{
	open my $fh, '<', $path or die "open $path: $!";
	binmode $fh;
	local $/ = undef;
	my $text = <$fh>;
	close $fh;

	return $text;
}

# _sha256($path):
#	The sha256 digest of one file, in lower-case hexadecimal.
sub _sha256 ($path)
{
	open my $fh, '<', $path or die "open $path: $!";
	binmode $fh;
	my $sha = Digest::SHA->new(256);
	$sha->addfile($fh);
	close $fh;

	return $sha->hexdigest;
}

# _body($path):
#	The key body of one signify public key file: the second line,
#	which holds the whole key.
sub _body ($path)
{
	my @lines = split /\n/, _slurp($path);

	return $lines[1];
}

# The key of the fixture release, in both forms, and the key that
# signed nothing.
my $KEY   = _body("$fixture/keys/fugubench-test.pub");
my $OTHER = _body("$fixture/keys/fugubench-other.pub");
copy( "$fixture/keys/fugubench-test.pub", "$srv/keys/fugubench-test.pub" )
    or die 'copy the key';
my $KEY_SUM = _sha256("$srv/keys/fugubench-test.pub");

# The digest that the signed manifest of the fixture records.
my ($ASSET) = _slurp("$fixture/release/SHA256") =~ /= ([0-9a-f]{64})/;
my $WRONG = 'f' x 64;

# _answer($conn, $path):
#	Write one response of the server. A path that names no file
#	under the document root takes 404, which the probe of the
#	signify tier reads as the normal absent answer.
sub _answer ( $conn, $path )
{
	my $body;
	$body = eval { _slurp("$srv$path") }
	    if defined $path
	    && $path =~ m{\A/[\w./-]+\z}
	    && index( $path, q{..} ) < 0;

	unless ( defined $body ) {
		print {$conn} "HTTP/1.0 404 Not Found\r\n"
		    . "Content-Length: 0\r\nConnection: close\r\n\r\n";
		return;
	}

	print {$conn} "HTTP/1.0 200 OK\r\nContent-Length: "
	    . length($body)
	    . "\r\nContent-Type: application/octet-stream\r\n"
	    . "Connection: close\r\n\r\n"
	    . $body;

	return;
}

# _serve($listen):
#	The body of the server child. It answers one request of each
#	connection, and the parent stops it with a signal. A client
#	that leaves early must not stop the server, so the child
#	ignores the broken pipe and each failure of one answer.
sub _serve ($listen)
{
	local $SIG{PIPE} = 'IGNORE';
	while ( my $conn = $listen->accept ) {
		binmode $conn;
		my $request = <$conn>;
		while ( my $line = <$conn> ) {
			last if $line =~ /\A\r?\n\z/;
		}
		my ($path) = ( $request // q{} ) =~ m{\AGET\s+(\S+)\s+HTTP};
		eval { _answer( $conn, $path ) };
		close $conn;
	}

	return;
}

# _dead_port():
#	One port that no server holds. The socket takes the port from
#	the system and gives it back at once.
sub _dead_port ()
{
	my $socket = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Listen    => 1,
		Proto     => 'tcp',
	) or die "cannot take a port: $!";
	my $dead = $socket->sockport;
	$socket->close;

	return $dead;
}

my $listen = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Listen    => 8,
	ReuseAddr => 1,
	Proto     => 'tcp',
) or plan skip_all => "cannot listen on the loopback address: $!";
my $port = $listen->sockport;

my $server = fork;
plan skip_all => "cannot fork the server: $!" unless defined $server;
unless ($server) {
	local $SIG{TERM} = sub { POSIX::_exit(0) };
	_serve($listen);
	POSIX::_exit(0);
}
$listen->close;

END { kill 'TERM', $server if $server; }

my $case = 0;

# _release($name, %change):
#	One release directory of the server, as a copy of the fixture
#	release, and the URL of that directory. A value of %change
#	replaces the file of that name, and an undefined value removes
#	it.
sub _release ( $name, %change )
{
	my $dir = "$srv/$name";
	make_path($dir);
	for my $file (qw(SHA256 SHA256.sig tool-1.0.0)) {
		copy( "$fixture/release/$file", "$dir/$file" )
		    or die "copy $file";
	}
	for my $file ( sort keys %change ) {
		if ( defined $change{$file} ) {
			Fugu::File->write( "$dir/$file", $change{$file} )
			    or die "write $file";
		}
		else {
			unlink "$dir/$file" or die "unlink $file";
		}
	}

	return "http://127.0.0.1:$port/$name";
}

# _checkout(%file):
#	A checkout that holds one deps/ directory. Each key names a
#	file of that directory, and each value holds its text.
sub _checkout (%file)
{
	my $dir = "$tree/case" . ++$case;
	make_path("$dir/deps");
	for my $name ( sort keys %file ) {
		Fugu::File->write( "$dir/deps/$name", $file{$name} )
		    or die "write $name";
	}

	return $dir;
}

# _child(@argv):
#	Run the program as a child in the temporary tree, which holds
#	no .toolingrc.
sub _child (@argv)
{
	return _child_home( $home, @argv );
}

# _child_home($where, @argv):
#	Run the program with $where as HOME. A case that asserts the
#	state of the install directory takes a HOME of its own, because
#	the shared one holds the installs of every other case.
sub _child_home ( $where, @argv )
{
	my $result = Fugu::Process->run(
		cmd => [ $^X, "-I$repo/lib", $program, @argv ],
		env => { PATH => $bin, HOME => $where, TMPDIR => $tmp, %LIB },
		cwd => $tree,
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# _deps($dir, @argv):
#	Run the deps verb against one checkout.
sub _deps ( $dir, @argv )
{
	# --verbose is a global option, so it sits ahead of the verb.
	my @global = grep { $_ eq '--verbose' } @argv;
	my @option = grep { $_ ne '--verbose' } @argv;

	return _child( @global, '-C', $dir, 'deps', @option );
}

# _bin($url, %file):
#	Run the deps verb over one bin entry, with no --dry-run, so
#	the run downloads the file and checks it.
sub _bin ( $url, %file )
{
	return _bin_opt( $url, [], %file );
}

# _bin_opt($url, $opt, %file):
#	The same run, with the options of $opt ahead of the
#	environment. A case that asserts a progress line passes
#	--verbose, because the verb is silent on success without it
#	(CLI-PROGRAM-7).
sub _bin_opt ( $url, $opt, %file )
{
	my $dir = _checkout( 'Darwin.txt' => "test bin tool $url\n", %file );

	return _deps( $dir, @$opt, '--os', 'Darwin', 'test' );
}

# The recorded tier holds the download to the digest of
# deps/SHA256.txt (DEPS-TIER-6). The install then runs, and its
# result line is the answer of a check that passed.
{
	my $url = _release('recorded') . '/tool-1.0.0';
	my $r = _bin( $url, 'SHA256.txt' => "SHA256 ($url) = $ASSET\n" );
	is( $r->{exit_code}, 0, 'the recorded tier installs the entry' );
	like(
		$r->{stdout}, qr/^installed the dependencies of test$/m,
		'the recorded digest passes its check'
	);
	unlike( $r->{stderr}, qr/does not match/, 'the check reports nothing' );
}

# A recorded digest that the bytes do not match stops the run, and
# the message names the repair of that tier (DEPS-TIER-10)
{
	my $url = _release('recorded-bad') . '/tool-1.0.0';
	my $r = _bin( $url, 'SHA256.txt' => "SHA256 ($url) = $WRONG\n" );
	is( $r->{exit_code}, 1, 'a recorded mismatch exits 1' );
	like(
		$r->{stderr}, qr/\Q$url\E does not match its recorded digest/,
		'the message names the URL and the tier'
	);
	like(
		$r->{stderr}, qr/deps --update-sums --force/,
		'the message names the repair of the recorded tier'
	);
	unlike(
		$r->{stdout}, qr/installed the dependencies/,
		'a failed check stops the run'
	);
}

# The signify tier verifies the signed manifest in-process and holds
# the download to it (DEPS-TIER-7, DEPS-TIER-8)
{
	my $url = _release('signed') . '/tool-1.0.0';
	my $r = _bin_opt( $url, ['--verbose'],
		'KEYS.txt' => "fugubench-test $KEY\n" );
	is( $r->{exit_code}, 0, 'the signify tier installs the entry' );
	like(
		$r->{stderr}, qr/verified the manifest with the key fugubench-test/,
		'the message names the key that verified the manifest'
	);
	like(
		$r->{stdout}, qr/^installed the dependencies of test$/m,
		'the signed digest passes its check'
	);
}

# A signed digest that the served bytes do not match names the
# upstream report, and not a digest refresh (DEPS-TIER-10)
{
	my $url =
	    _release( 'signed-bad', 'tool-1.0.0' => "the served bytes\n" )
	    . '/tool-1.0.0';
	my $r = _bin( $url, 'KEYS.txt' => "fugubench-test $KEY\n" );
	is( $r->{exit_code}, 1, 'a signed mismatch exits 1' );
	like(
		$r->{stderr}, qr/tool-1\.0\.0 does not match its signed digest/,
		'the message names the file name and the tier'
	);
	like(
		$r->{stderr}, qr/report it upstream/,
		'the message names the upstream report'
	);
	unlike(
		$r->{stdout}, qr/installed the dependencies/,
		'a failed check stops the run'
	);
}

# A release that answers no signed manifest stops the run, and the
# 404 of the probe reaches no message (DEPS-FETCH-3)
{
	my %absent = (
		'SHA256'     => [ 'no-sums', { 'SHA256' => undef, 'SHA256.sig' => undef } ],
		'SHA256.sig' => [ 'no-sig',  { 'SHA256.sig' => undef } ],
	);
	for my $name ( sort keys %absent ) {
		my ( $dir, $change ) = @{ $absent{$name} };
		my $base = _release( $dir, %$change );
		my $r = _bin( "$base/tool-1.0.0",
			'KEYS.txt' => "fugubench-test $KEY\n" );
		is( $r->{exit_code}, 1, "an absent $name exits 1" );
		like(
			$r->{stderr},
			qr{the signify tier needs \Q$base/$name\E, and the server does not answer it},
			"the message names the absent $name"
		);
		unlike( $r->{stderr}, qr/404/,
			"the 404 of the $name probe reaches no message" );
	}
}

# A refused connection is a failure of the run, and never the absent
# answer of the probe (DEPS-FETCH-3)
{
	my $dead = _dead_port();
	my $base = "http://127.0.0.1:$dead/signed";
	my $r = _bin( "$base/tool-1.0.0",
		'KEYS.txt' => "fugubench-test $KEY\n" );
	is( $r->{exit_code}, 1, 'a refused connection exits 1' );
	like(
		$r->{stderr}, qr{\Q$base/SHA256\E},
		'the message names the URL of the probe'
	);
	unlike(
		$r->{stderr}, qr/does not answer it/,
		'a refused connection is no absent manifest'
	);
}

# An empty key set is valid, and the signify tier then stops before
# the first download (DEPS-KEYS-5, DEPS-TIER-9)
{
	my $dead = _dead_port();
	my $r = _bin("http://127.0.0.1:$dead/signed/tool-1.0.0");
	is( $r->{exit_code}, 1, 'an empty key set exits 1' );
	like(
		$r->{stderr},
		qr/has no recorded digest, and no key is declared/,
		'the message names the empty key set'
	);
	unlike( $r->{stderr}, qr{/SHA256}, 'the run asks for no manifest' );
}

# The URL form downloads the key file and holds it to the recorded
# digest (DEPS-KEYS-2, DEPS-KEYS-6)
{
	my $url = _release('url-key') . '/tool-1.0.0';
	my $key = "http://127.0.0.1:$port/keys/fugubench-test.pub";
	my $r = _bin_opt( $url, ['--verbose'],
		'KEYS.txt' => "fugubench-test $key $KEY_SUM\n" );
	like(
		$r->{stderr}, qr/verified the manifest with the key fugubench-test/,
		'a key of the URL form verifies the manifest'
	);
}

# A key that fails its digest leaves the trust order, and the next
# key verifies. The second key sits in deps/KEYS.local.txt, which the
# verb reads after deps/KEYS.txt (DEPS-KEYS-1, DEPS-KEYS-7)
{
	my $url = _release('next-key') . '/tool-1.0.0';
	my $key = "http://127.0.0.1:$port/keys/fugubench-test.pub";
	my $r   = _bin_opt(
		$url, ['--verbose'],
		'KEYS.txt'       => "fugubench-old $key $WRONG\n",
		'KEYS.local.txt' => "fugubench-test $KEY\n",
	);
	like(
		$r->{stderr}, qr/the key fugubench-old did not load/,
		'the message names the key that failed its digest'
	);
	like(
		$r->{stderr}, qr/verified the manifest with the key fugubench-test/,
		'the next key of the trust order verifies the manifest'
	);
}

# No declared key loads, so the run stops and the message reports
# each failure (DEPS-KEYS-7)
{
	my $url  = _release('no-key') . '/tool-1.0.0';
	my $key  = "http://127.0.0.1:$port/keys/fugubench-test.pub";
	my $gone = "http://127.0.0.1:$port/keys/absent.pub";
	my $r    = _bin(
		$url,
		'KEYS.txt' => "fugubench-old $key $WRONG\n"
		    . "fugubench-gone $gone $WRONG\n",
	);
	is( $r->{exit_code}, 1, 'a key set that does not load exits 1' );
	like(
		$r->{stderr}, qr/no declared key loaded, so no signature/,
		'the message names the key set that did not load'
	);
	like(
		$r->{stderr}, qr/^\S+ \S+ ERROR:\s+fugubench-old: /m,
		'the tail names the key that failed its digest'
	);
	like(
		$r->{stderr}, qr/^\S+ \S+ ERROR:\s+fugubench-gone: /m,
		'the tail names the key that no server answers'
	);
	unlike(
		$r->{stdout}, qr/installed the dependencies/,
		'a key set that does not load stops the run'
	);
}

# A key that signed nothing verifies nothing, and the run stops
# (DEPS-KEYS-3)
{
	my $url = _release('other-key') . '/tool-1.0.0';
	my $r = _bin( $url, 'KEYS.txt' => "fugubench-other $OTHER\n" );
	is( $r->{exit_code}, 1, 'a key that verifies nothing exits 1' );
	like(
		$r->{stderr}, qr/no declared key verifies the signature/,
		'the message names the failed verification'
	);
	unlike(
		$r->{stdout}, qr/installed the dependencies/,
		'a failed verification stops the run'
	);
}

# A key that the file name names, a blank line, and each bad key line
# are configuration errors (DEPS-TIER-5, DEPS-TIER-4, DEPS-KEYS-4,
# DEPS-FETCH-4)
{
	my $url = 'https://example.com/tool-1.0.0';
	my %bad = (
		'a key of the file name' => [
			{ 'SHA256.txt' => "SHA256 (tool-1.0.0) = $ASSET\n" },
			qr/keys on the file name/
		],
		'a blank line of the digest file' => [
			{
				'SHA256.txt' => "SHA256 ($url) = $ASSET\n\n"
				    . "SHA256 (https://example.com/other) = $ASSET\n"
			},
			qr{deps/SHA256\.txt: }
		],
		'a key name with a slash' =>
		    [ { 'KEYS.txt' => "../evil $KEY\n" }, qr/a key name holds/ ],
		'a body that is no key' => [
			{ 'KEYS.txt' => "fugubench-test notakeybody\n" },
			qr/not a signify key body/
		],
		'a digest of the wrong length' => [
			{ 'KEYS.txt' => "fugubench-test https://example.com/k ff\n" },
			qr/not a sha256 digest/
		],
		'a key line of four fields' => [
			{ 'KEYS.txt' => "fugubench-test a b c\n" },
			qr/two or three fields/
		],

		# The key file downloads through the downloader of every
		# other file, which takes no '--' separator.
		'a key URL that starts with a dash' => [
			{ 'KEYS.txt' => "fugubench-test -K/tmp/evilrc $WRONG\n" },
			qr/the URL must start with a scheme/
		],
		'a key URL with no scheme' => [
			{ 'KEYS.txt' => "fugubench-test keys/test.pub $WRONG\n" },
			qr/the URL must start with a scheme/
		],
		'a duplicate key name' => [
			{
				'KEYS.txt'       => "fugubench-test $KEY\n",
				'KEYS.local.txt' => "fugubench-test $OTHER\n",
			},
			qr/duplicate key name/
		],
	);
	for my $name ( sort keys %bad ) {
		my ( $file, $re ) = @{ $bad{$name} };
		my $dir =
		    _checkout( 'Darwin.txt' => "test bin tool $url\n", %$file );

		# The dry run reads each consumer file, and it asks no
		# network.
		my $r = _deps( $dir, '--dry-run', '--os', 'Darwin', 'test' );
		is( $r->{exit_code}, 3, "$name exits 3" );
		like( $r->{stderr}, $re, "$name names the fault" );
		is( $r->{stdout}, q{}, "$name writes no trace" );
	}
}

# The verb makes the install directory after the tier check, so a bin
# entry that no tier covers leaves no directory behind
# (DEPS-INSTALL-9, DEPS-TIER-2)
{
	my $own = "$tree/home-bare";
	make_path($own);

	# The checkout declares no key and records no digest, so the
	# entry reaches no tier. The check asks no network.
	my $dir = _checkout(
		'Darwin.txt' => "test bin tool http://127.0.0.1:$port/"
		    . "bare/tool-1.0.0\n" );
	my $r =
	    _child_home( $own, '-C', $dir, 'deps', '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 1, 'an entry that no tier covers exits 1' );
	ok( !-e "$own/.local",
		'a failed tier check leaves no install directory' );
}

# The digest of an entry takes its check at the download of that
# entry, so a mismatch on a later entry leaves an earlier one
# installed (DEPS-TIER-2)
{
	my $own = "$tree/home-two";
	make_path($own);

	my $first  = _release('two-first') . '/tool-1.0.0';
	my $second = _release('two-second') . '/tool-1.0.0';
	my $dir    = _checkout(
		'Darwin.txt' => "test bin first $first\n"
		    . "test bin second $second\n",
		'SHA256.txt' => "SHA256 ($first) = $ASSET\n"
		    . "SHA256 ($second) = $WRONG\n",
	);
	my $r =
	    _child_home( $own, '-C', $dir, 'deps', '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 1, 'a digest mismatch on a later entry exits 1' );
	like(
		$r->{stderr}, qr/does not match its recorded digest/,
		'the message names the failed check'
	);
	ok( -e "$own/.local/bin/first",
		'the entry ahead of the mismatch stays installed' );
	ok( !-e "$own/.local/bin/second",
		'the entry of the failed check installs nothing' );
}

# The verb makes the install directory before the first download, so
# a digest mismatch on the first bin entry leaves that directory
# behind (DEPS-TIER-2)
{
	my $own = "$tree/home-mismatch";
	make_path($own);

	my $url = _release('mismatch-first') . '/tool-1.0.0';
	my $dir = _checkout(
		'Darwin.txt' => "test bin tool $url\n",
		'SHA256.txt' => "SHA256 ($url) = $WRONG\n",
	);
	my $r =
	    _child_home( $own, '-C', $dir, 'deps', '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 1, 'a digest mismatch on the first entry exits 1' );
	ok( -d "$own/.local/bin",
		'a mismatch on the first entry leaves the install directory' );
	ok( !-e "$own/.local/bin/tool", 'the entry installs nothing' );
}

# The fetch verb takes the file and then the URL, and it is silent on
# success (DEPS-FETCH-2)
{
	my $base = _release('fetch');
	my $out  = "$tree/fetched";
	my $r    = _child( 'fetch', $out, "$base/tool-1.0.0" );
	is( $r->{exit_code}, 0,   'a fetch that lands exits 0' );
	is( $r->{stdout},    q{}, 'the fetch verb writes no result line' );
	is(
		_slurp($out), _slurp("$fixture/release/tool-1.0.0"),
		'the first argument is the file, and the second is the URL'
	);
}

# A failed fetch reports the reason and leaves no file
{
	my $base = "http://127.0.0.1:$port/fetch";
	my $out  = "$tree/absent";
	my $r    = _child( 'fetch', $out, "$base/nosuch" );
	is( $r->{exit_code}, 1, 'a 404 exits 1' );
	ok( !-e $out, 'a failed fetch leaves no file' );
	like( $r->{stderr}, qr{\Q$base/nosuch\E}, 'the message names the URL' );
}

# The fetch verb holds its URL to the shape that the downloader
# allows, because Fugu::Curl writes no '--' separator. A URL that
# fails the check is a usage error (DEPS-FETCH-4, CLI-PROGRAM-6,
# CLI-PROGRAM-3)
{
	# The dispatcher reads a leading dash as an option, so '--'
	# ends the option parsing and the URL reaches the body.
	my $out  = "$tree/unwanted";
	my @case = (
		[ 'a URL that starts with a dash', '-K/tmp/evilrc', '--' ],
		[ 'a URL with no scheme',          'not-a-url' ],
	);
	for my $case (@case) {
		my ( $want, $url, @lead ) = @$case;
		my $r = _child( 'fetch', @lead, $out, $url );
		is( $r->{exit_code}, 2, "$want exits 2" );
		like(
			$r->{stderr},
			qr/the command line: the URL must start with a scheme/,
			"$want names its source and the rule"
		);
		like( $r->{stderr}, qr/\Q$url\E/,
			"$want names the URL" );
		like(
			$r->{stderr}, qr/^usage: fugubench fetch /m,
			"$want prints the usage"
		);
		ok( !-e $out, "$want downloads nothing" );
	}
}

# Other than two arguments is a usage error (CLI-PROGRAM-3)
{
	for my $argv ( ["$tree/one"], [ "$tree/one", 'http://a/b', 'extra' ] ) {
		my $r = _child( 'fetch', @$argv );
		is( $r->{exit_code}, 2, 'a wrong argument count exits 2' );
		like(
			$r->{stderr}, qr/^usage: fugubench fetch /m,
			'the usage names the verb'
		);
	}
}

done_testing();
