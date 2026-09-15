#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The digest refresh of the deps verb (DEPS-SUMS).
#
# Each case runs bin/fugubench as a child with -Ilib. The child takes
# HOME and TMPDIR inside a temporary tree, and it runs in that tree,
# which holds no .toolingrc. PATH holds the downloader of this host
# alone, because a refresh installs nothing.
#
# No case asks the network. One forked server over the core
# IO::Socket::INET answers on the loopback address, and each release
# takes a directory of its own under one document root.
#
# The fixtures under t/fugubench/deps/fixture/ hold the public half of
# one signify key, one release directory, and the signature of its
# SHA256 manifest. signify(1) made them one time, and no secret half
# is in the repository.

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

# The refresh verifies a signed manifest in-process, so the release of
# Fugu must hold the downloader and the perl engine of the verifier.
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
make_path( $home, $tmp, $bin, $srv );

# The PATH of each child holds the downloader of this host alone. A
# refresh runs no other command.
symlink $downloader->command, "$bin/" . basename( $downloader->command )
    or die 'symlink the downloader';

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

# The key of the fixture release, in the body form: the second line of
# the public key file holds the whole key.
my $KEY = ( split /\n/, _slurp("$fixture/keys/fugubench-test.pub") )[1];

# The digest that the signed manifest of the fixture records, and one
# digest that no file holds.
my ($ASSET) = _slurp("$fixture/release/SHA256") =~ /= ([0-9a-f]{64})/;
my $WRONG = 'f' x 64;

# _answer($conn, $path):
#	Write one response of the server. A path that names no file
#	under the document root takes 404, which a probe of the refresh
#	reads as the absent answer.
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
#	connection, and the parent stops it with a signal. A client that
#	leaves early must not stop the server, so the child ignores the
#	broken pipe and each failure of one answer.
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

my $host = "http://127.0.0.1:$port";

# _release($name, @file):
#	One release directory of the server, as a copy of the named
#	files of the fixture release, and the URL of that directory.
sub _release ( $name, @file )
{
	my $dir = "$srv/$name";
	make_path($dir);
	for my $file (@file) {
		copy( "$fixture/release/$file", "$dir/$file" )
		    or die "copy $file";
	}

	return "$host/$name";
}

# _asset($path, $text):
#	One download of the server that no manifest covers, and its
#	URL.
sub _asset ( $path, $text )
{
	my $file = "$srv/$path";
	make_path( substr $file, 0, rindex( $file, q{/} ) );
	Fugu::File->write( $file, $text ) or die "write $path";

	return "$host/$path";
}

# The downloads of the server. The signed release and the per-system
# release carry the signature of the fixture, and the third release
# withholds it. The plain name, the stable name and the two candidates
# carry no manifest at all.
my @RELEASE = qw(SHA256 SHA256.sig tool-1.0.0);
my $SIGNED   = _release( 'signed',         @RELEASE );
my $DARWIN   = _release( 'darwin-release', @RELEASE );
my $LATE     = _release( 'osx-late',       @RELEASE );
my $UNSIGNED = _release( 'unsigned', qw(SHA256 tool-1.0.0) );
my $PLAIN  = _asset( 'plain/tool-1.0.0', "the plain bytes\n" );
my $STABLE = _asset( 'stable/tool',      "the stable bytes\n" );
my $AMD64  = _asset( 'multi/tool-amd64', "the amd64 bytes\n" );
my $X64    = _asset( 'multi/tool-x64',   "the x64 bytes\n" );
my $MULTI  = "$host/multi/tool-{arch}";

my $PLAIN_SUM = _sha256("$srv/plain/tool-1.0.0");
my $AMD64_SUM = _sha256("$srv/multi/tool-amd64");

my $case = 0;

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

# _deps($dir, @argv):
#	Run the deps verb against one checkout, in the temporary tree,
#	which holds no .toolingrc.
sub _deps ( $dir, @argv )
{
	# --verbose is a global option, so it sits ahead of the verb.
	my @global = grep { $_ eq '--verbose' } @argv;
	my @option = grep { $_ ne '--verbose' } @argv;
	my $result = Fugu::Process->run(
		cmd => [
			$^X,  "-I$repo/lib", $program, @global,
			'-C', $dir,          'deps',   @option
		],
		env => { PATH => $bin, HOME => $home, TMPDIR => $tmp, %LIB },
		cwd => $tree,
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# _refresh($dir, @argv):
#	Run one refresh over the Darwin manifest of one checkout.
sub _refresh ( $dir, @argv )
{
	return _deps( $dir, '--update-sums', '--os', 'Darwin', @argv );
}

# _sums($dir):
#	The text of the digest file of one checkout, or undef when the
#	refresh wrote none.
sub _sums ($dir)
{
	my $file = "$dir/deps/SHA256.txt";

	return -f $file ? _slurp($file) : undef;
}

# A refresh records the digest of a versioned download, and it reads
# every environment of the one manifest (DEPS-SUMS-1)
{
	my $dir = _checkout( 'Darwin.txt' => "develop dist $PLAIN\n" );
	my $r = _refresh($dir);
	is( $r->{exit_code}, 0, 'a refresh that records exits 0' );
	like(
		$r->{stdout}, qr/^recorded \Q$PLAIN\E$/m,
		'the report names the recorded URL'
	);
	like( $r->{stdout}, qr{^wrote \Q$dir\E/deps/SHA256\.txt$}m,
		'the report names the file that it wrote' );
	is(
		_sums($dir), "SHA256 ($PLAIN) = $PLAIN_SUM\n",
		'the file holds the digest of the download, keyed on the URL'
	);
}

# A URL that the file records already stays, and a run that records
# nothing leaves the file as it was (DEPS-SUMS-1, DEPS-SUMS-12)
{
	my $text = "SHA256 ($PLAIN) = $WRONG\n";
	my $dir  = _checkout(
		'Darwin.txt' => "test dist $PLAIN\n",
		'SHA256.txt' => $text,
	);
	my $r = _refresh($dir);
	is( $r->{exit_code}, 0, 'a run that records nothing exits 0' );
	like( $r->{stdout}, qr/^kept \Q$PLAIN\E$/m,
		'the report names the URL that it kept' );
	like(
		$r->{stdout},
		qr{^recorded nothing, and \Q$dir\E/deps/SHA256\.txt stays as it was$}m,
		'the report names the file that stays as it was'
	);
	unlike( $r->{stdout}, qr/^wrote /m, 'the run writes no file' );
	is( _sums($dir), $text, 'the recorded digest stays as it was' );
}

# A stable name stays on the signify tier, and the test reads the
# manifest and never the network (DEPS-SUMS-2, DEPS-SUMS-3)
{
	# The second URL carries a version, and /releases/latest/ makes
	# it a stable name. No file of the server answers it.
	my $latest = "$host/releases/latest/tool-1.0.0";
	my $dir    = _checkout(
		'Darwin.txt' => "test dist $STABLE\ntest dist $latest\n" );
	my $r = _refresh($dir);
	is( $r->{exit_code}, 0, 'a skipped stable name exits 0' );
	like(
		$r->{stdout}, qr/^skipped the stable name: \Q$STABLE\E$/m,
		'the report names the URL with no digit in its path'
	);
	like(
		$r->{stdout}, qr/^skipped the stable name: \Q$latest\E$/m,
		'the report names the URL of the latest release'
	);
	is( _sums($dir), undef, 'the run writes no digest file' );
}

# A URL that a signed manifest covers keeps no recorded digest, which
# would outrank the signature (DEPS-SUMS-5)
{
	my $url = "$SIGNED/tool-1.0.0";
	my $dir = _checkout(
		'Darwin.txt' => "test dist $url\n",
		'KEYS.txt'   => "fugubench-test $KEY\n",
	);
	my $r = _refresh($dir);
	is( $r->{exit_code}, 0, 'a skipped signed entry exits 0' );
	like(
		$r->{stdout}, qr/^skipped the signed entry: \Q$url\E$/m,
		'the report names the signed entry'
	);
	is( _sums($dir), undef, 'the run writes no digest file' );
}

# The signed-manifest test is a probe, so an empty key set is a
# warning there, and never an error (DEPS-SUMS-6, DEPS-KEYS-5)
{
	my $url = "$SIGNED/tool-1.0.0";
	my $dir = _checkout( 'Darwin.txt' => "test dist $url\n" );
	my $r   = _refresh($dir);
	is( $r->{exit_code}, 0, 'a probe with no declared key exits 0' );
	like(
		$r->{stdout}, qr/^skipped the signed entry: \Q$url\E$/m,
		'the manifest that answers keeps the entry off the tier'
	);
	like(
		$r->{stderr}, qr/^\S+ \S+ WARNING: no key is declared/m,
		'the empty key set of a probe reports at warning level'
	);
	unlike( $r->{stderr}, qr/ ERROR: /,
		'a normal outcome reports no error' );
}

# A server that answers the manifest and withholds the signature
# keeps the entry off the digest tier (DEPS-SUMS-3)
{
	my $url = "$UNSIGNED/tool-1.0.0";
	my $dir = _checkout(
		'Darwin.txt' => "test dist $url\n",
		'KEYS.txt'   => "fugubench-test $KEY\n",
	);
	my $r = _refresh($dir);
	is( $r->{exit_code}, 0, 'a release with no signature exits 0' );
	like(
		$r->{stdout}, qr/^skipped the signed entry: \Q$url\E$/m,
		'the report names the entry that the manifest covers'
	);
	is( _sums($dir), undef, 'the run pins no byte that the server serves' );
}

# An entry with a placeholder takes its digest from the signed
# manifest of the directory that answers (DEPS-SUMS-4, DEPS-SUMS-6)
{
	my $url = "$host/{os}-release/tool-1.0.0";
	my $dir = _checkout(
		'Darwin.txt' => "test dist $url\n",
		'KEYS.txt'   => "fugubench-test $KEY\n",
	);
	# --verbose adds the progress lines, because the verb is silent
	# on success without it (CLI-PROGRAM-7).
	my $r = _refresh( $dir, '--verbose' );
	is( $r->{exit_code}, 0, 'a placeholder entry that records exits 0' );
	like(
		$r->{stderr}, qr/verified the manifest with the key fugubench-test/,
		'the declared key verifies the signed manifest'
	);
	like(
		$r->{stdout},
		qr{^recorded \Q$DARWIN\E/tool-1\.0\.0 from the signed manifest$}m,
		'the report names the candidate and the signed manifest'
	);
	is(
		_sums($dir), "SHA256 ($DARWIN/tool-1.0.0) = $ASSET\n",
		'the recorded digest comes from the signed manifest'
	);
}

# The refresh records a candidate of the directory that answers, and
# never one of a directory that holds no release (DEPS-SUMS-6)
{
	my $url = "$host/{os}-late/tool-1.0.0";
	my $dir = _checkout(
		'Darwin.txt' => "test dist $url\n",
		'KEYS.txt'   => "fugubench-test $KEY\n",
	);
	my $r = _refresh($dir);
	is( $r->{exit_code}, 0, 'a release of the third spelling exits 0' );
	is(
		_sums($dir), "SHA256 ($LATE/tool-1.0.0) = $ASSET\n",
		'the recorded URL names the directory that answered'
	);
}

# Two candidates that answer give one recorded line and one warning
# (DEPS-SUMS-8, DEPS-SUMS-9)
{
	my $dir = _checkout( 'Darwin.txt' => "test bin tool $MULTI\n" );
	my $r = _refresh( $dir, '--arch', 'x86_64' );
	is( $r->{exit_code}, 0, 'two candidates that answer exit 0' );
	my @recorded = $r->{stdout} =~ /^recorded (\S+)$/mg;
	is_deeply( \@recorded, [$AMD64],
		'the refresh records the first candidate that answers' );
	like(
		$r->{stderr}, qr/more than one candidate answers for \Q$MULTI\E/,
		'the warning names the entry'
	);
	my @named = $r->{stderr} =~ /^\S+ \S+ WARNING:\s+(\S+)$/mg;
	is_deeply( \@named, [$X64],
		'the warning names each candidate that stays out of the file' );
	is(
		_sums($dir), "SHA256 ($AMD64) = $AMD64_SUM\n",
		'each candidate downloads on its own, and the first one records'
	);
}

# --force rewrites a recorded digest, drops every other recorded
# candidate of the entry, and drops the file-name key that the
# recorded URL replaces (DEPS-SUMS-10, DEPS-SUMS-11)
{
	my $dir = _checkout(
		'Darwin.txt' => "test bin tool $MULTI\n",
		'SHA256.txt' => "SHA256 ($AMD64) = $WRONG\n"
		    . "SHA256 ($X64) = $WRONG\n"
		    . "SHA256 (tool-amd64) = $WRONG\n"
		    . "SHA256 (tool-other) = $WRONG\n",
	);
	my $r = _refresh( $dir, '--arch', 'x86_64', '--force' );
	is( $r->{exit_code}, 0, 'a forced refresh exits 0' );
	like( $r->{stdout}, qr/^removed \Q$X64\E$/m,
		'the report names the sibling that it removed' );
	like(
		$r->{stdout}, qr/^dropped the file-name key tool-amd64$/m,
		'the report names the file-name key that it dropped'
	);
	is(
		_sums($dir),
		"SHA256 ($AMD64) = $AMD64_SUM\n" . "SHA256 (tool-other) = $WRONG\n",
		'the file keeps the file-name key that this run cannot replace'
	);
}

# --force pins a stable name, and it overrides the signed-manifest
# test with a warning first (DEPS-SUMS-10)
{
	my $url = "$SIGNED/tool-1.0.0";
	my $dir = _checkout(
		'Darwin.txt' => "test dist $STABLE\ntest dist $url\n",
		'KEYS.txt'   => "fugubench-test $KEY\n",
	);
	my $r = _refresh( $dir, '--force' );
	is( $r->{exit_code}, 0, 'a forced refresh of two skips exits 0' );
	like(
		$r->{stderr},
		qr/--force pins a URL that a signed manifest covers.*\Q$url\E/s,
		'the warning names the URL of the signed entry'
	);
	like(
		_sums($dir), qr/^SHA256 \(\Q$STABLE\E\) = [0-9a-f]{64}$/m,
		'--force pins the stable name'
	);
	like(
		_sums($dir), qr/^SHA256 \(\Q$url\E\) = \Q$ASSET\E$/m,
		'--force pins the URL that the signed manifest covers'
	);
}

# An entry that reaches no candidate fails the run, and the file stays
# as it was (DEPS-SUMS-7, DEPS-SUMS-12)
{
	my $text = "SHA256 ($host/keep-1.0.0) = $WRONG\n";
	my $url  = "$SIGNED/tool-{arch}";
	my $dir  = _checkout(
		'Darwin.txt' => "test dist $url\ntest dist $PLAIN\n",
		'KEYS.txt'   => "fugubench-test $KEY\n",
		'SHA256.txt' => $text,
	);
	my $r = _refresh($dir);
	is( $r->{exit_code}, 1, 'an entry that reaches no candidate exits 1' );
	like(
		$r->{stderr},
		qr/the signed manifest beside \Q$url\E names no candidate/,
		'the warning names the entry that the manifest does not name'
	);
	like(
		$r->{stderr},
		qr{1 entry of the manifest reached no candidate, and \Q$dir\E/deps/SHA256\.txt stays as it was},
		'the message counts the entries that reached no candidate'
	);
	unlike( $r->{stdout}, qr/^recorded /m,
		'a run that writes no file reports no recorded URL' );
	is( _sums($dir), $text, 'the digest file stays as it was' );
}

# A URL that no candidate answers fails the run (DEPS-SUMS-7)
{
	my $url = "$host/plain/nosuch-1.0.0";
	my $dir = _checkout( 'Darwin.txt' => "test dist $url\n" );
	my $r = _refresh($dir);
	is( $r->{exit_code}, 1, 'a URL that no server answers exits 1' );
	like( $r->{stderr}, qr/no candidate answers for \Q$url\E/,
		'the warning names the entry' );
	is( _sums($dir), undef, 'the run writes no digest file' );
}

# --update-sums takes no environment word and no --dry-run, and
# --force belongs to it (DEPS-SUMS-13)
{
	my $dir = _checkout( 'Darwin.txt' => "test dist $PLAIN\n" );
	my %usage = (
		'an environment word with --update-sums' => [
			[ '--update-sums', 'test' ],
			qr/--update-sums reads every environment/
		],
		'--dry-run with --update-sums' => [
			[ '--update-sums', '--dry-run' ],
			qr/--update-sums writes the digest file/
		],
		'--force without --update-sums' =>
		    [ [ '--force', 'test' ], qr/--force belongs to/ ],
	);
	for my $name ( sort keys %usage ) {
		my ( $argv, $re ) = @{ $usage{$name} };
		my $r = _deps( $dir, '--os', 'Darwin', @$argv );
		is( $r->{exit_code}, 2, "$name exits 2" );
		like( $r->{stderr}, $re, "$name names the fault" );
		like(
			$r->{stderr}, qr/^usage: fugubench deps /m,
			"$name prints the usage to standard error"
		);
		is( $r->{stdout}, q{}, "$name writes no report" );
		is( _sums($dir), undef, "$name writes no digest file" );
	}
}

done_testing();
