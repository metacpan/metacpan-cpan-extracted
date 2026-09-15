#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The installers of the deps verb: the package manager of each
# platform, cpanm with the bootstrap, and a bin entry into
# ~/.local/bin (DEPS-INSTALL).
#
# No case installs anything on this host. Each package manager and
# each cpanm is a stub on a temporary PATH, which logs its arguments
# and exits 0. One case takes a second PATH, whose sudo exits 1. PATH
# holds one of those directories alone, so a real package manager and
# a real cpanm answer no case. HOME sits in the temporary tree, so a
# bin entry lands there, and mkdir, tar, gzip, unzip, cp and chmod
# are the commands of this host, which write in that tree alone.
#
# No case asks the network. The bin cases download from a forked
# server over the core IO::Socket::INET, on the loopback address. The
# bootstrap downloads https://cpanmin.us, which no test may ask, so
# its PATH holds a stub downloader that writes the standalone script
# itself.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use Archive::Tar   ();
use Digest::SHA    ();
use File::Basename qw(basename);
use File::Path     qw(make_path);
use File::Temp     qw(tempdir);
use FindBin        qw($RealBin);
use IO::Compress::Zip qw(zip $ZipError);
use IO::Socket::INET  ();
use POSIX             ();
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Process;

my $repo    = "$RealBin/../..";
my $program = "$repo/bin/fugubench";

# Fugu::Process gives a child the named environment alone, and CI
# reaches the installed Fugu through PERL5LIB. Every child of this
# test therefore carries it.
my %LIB = defined $ENV{PERL5LIB} ? ( PERL5LIB => $ENV{PERL5LIB} ) : ();

# A bin entry downloads through Fugu::Curl, and the verb reads
# deps/SHA256.txt through Fugu::Signify.
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
my $tmp  = "$tree/tmp";
my $srv  = "$tree/srv";
my $path = "$tree/bin";
my $bare = "$tree/bare";
my $fail = "$tree/fail";
my $log  = "$tree/commands";
make_path( $tmp, $srv, $path, $bare, $fail );

# The bytes of the fixture release, in a plain file and in each
# archive form.
my $BINARY = "the fixture binary\n";

# _slurp($file):
#	The bytes of one file.
sub _slurp ($file)
{
	open my $fh, '<', $file or die "open $file: $!";
	binmode $fh;
	local $/ = undef;
	my $text = <$fh>;
	close $fh;

	return $text;
}

# _sha256($file):
#	The sha256 digest of one file, in lower-case hexadecimal.
sub _sha256 ($file)
{
	open my $fh, '<', $file or die "open $file: $!";
	binmode $fh;
	my $sha = Digest::SHA->new(256);
	$sha->addfile($fh);
	close $fh;

	return $sha->hexdigest;
}

# _link($dir, $name):
#	One command of this host, as a link in a stub PATH. The method
#	returns 0 for a command that this host does not hold.
sub _link ( $dir, $name )
{
	my $found = Fugu::Process->find_command($name);
	return 0 unless defined $found;
	symlink $found, "$dir/" . basename($found) or die "symlink $found";

	return 1;
}

# _stub($dir, $name, @body):
#	One stub command of a temporary PATH, as a shell script that
#	this test writes.
sub _stub ( $dir, $name, @body )
{
	Fugu::File->write( "$dir/$name", join "\n", '#!/bin/sh', @body, q{} )
	    or die "write $dir/$name";
	chmod 0755, "$dir/$name" or die "chmod $dir/$name";

	return;
}

# _record($name):
#	The line of a stub that appends its own command line to the
#	log. The name leads, because $0 holds the path of the stub.
sub _record ($name)
{
	return q{printf '%s\n' "} . $name . q{ $*" >> '} . $log . q{'};
}

# _log():
#	Each command line that a stub of the last run recorded, in
#	order.
sub _log ()
{
	my $text = -f $log ? _slurp($log) : q{};

	return split /\n/, $text;
}

# The stub package managers and the stub cpanm. Each one records its
# command line and installs nothing. brew also writes one line to
# each of its streams, for the channel of a child (CLI-PROGRAM-4).
_stub( $path, 'brew', _record('brew'),
	q{echo 'the child standard output'},
	q{echo 'the child standard error' >&2} );
_stub( $path, 'pkg_add', _record('pkg_add') );
_stub( $path, 'sudo',    _record('sudo') );
_stub( $path, 'cpanm',   _record('cpanm') );

# The commands of a bin install, and the downloader of this host.
# PATH holds the stub directory alone, so each one needs a link.
#
# gzip is a command of `tar -xzf`. The GNU tar of Linux and the tar
# of OpenBSD each run gzip(1) as a child, and they find it on PATH
# alone. The bsdtar of macOS decompresses in-process and asks for no
# such child, so an absent gzip fails on two platforms and passes on
# the third.
_link( $path, basename( $downloader->command ) ) or die 'link the downloader';
for my $name (qw(mkdir cp chmod tar gzip)) {
	plan skip_all => "no $name is on PATH" unless _link( $path, $name );
}
my $UNZIP = _link( $path, 'unzip' );

# The PATH of the bootstrap: a stub downloader, and no cpanm. The
# stub writes the standalone script that the verb then runs under
# this perl, so the case reaches no network. The stub takes the name
# curl, so Fugu::Curl takes the curl dialect, which names the
# destination after --output.
_stub(
	$bare, 'curl',
	'out=',
	'while [ $# -gt 0 ]; do',
	'	if [ "$1" = "--output" ]; then out=$2; fi',
	'	shift',
	'done',
	q{printf '%s\n'}
	    . q{ 'open my $fh, ">>", "}
	    . $log
	    . q{" or exit 1;'}
	    . q{ 'print {$fh} "cpanm @ARGV\n";'}
	    . q{ 'exit 0;' > "$out"},
	q{printf '200'}
);

# The PATH of the failed child: a sudo that records its command line,
# writes one line to standard error, and exits 1.
_stub( $fail, 'sudo', _record('sudo'),
	q{echo 'the failed child said this' >&2}, 'exit 1' );

# _answer($conn, $file):
#	Write one response of the server. A path that names no file
#	under the document root takes 404.
sub _answer ( $conn, $file )
{
	my $body;
	$body = eval { _slurp("$srv$file") }
	    if defined $file
	    && $file =~ m{\A/[\w./-]+\z}
	    && index( $file, q{..} ) < 0;

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
		my ($file) = ( $request // q{} ) =~ m{\AGET\s+(\S+)\s+HTTP};
		eval { _answer( $conn, $file ) };
		close $conn;
	}

	return;
}

# The three downloads of the bin cases: a plain file, a tar archive,
# and a zip archive. Each archive holds the one file bin/tool, and
# the core modules build both, so no case needs an archiver on this
# host.
#
# The server also answers the file `other`, which the digest file
# does not record. The set that holds it must install nothing, and a
# server that answers it proves that the tier check stopped the run.
make_path("$srv/release");
Fugu::File->write( "$srv/release/$_", $BINARY ) or die 'write the binary'
    for qw(tool other);
my $tar = Archive::Tar->new;
$tar->add_data( 'bin/tool', $BINARY );
$tar->write( "$srv/release/tool.tar.gz", 1 ) or die 'write the tar archive';
zip( \$BINARY => "$srv/release/tool.zip", Name => 'bin/tool' )
    or die "write the zip archive: $ZipError";

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

# The URL of each download, and the digest line of the recorded tier.
my $BASE = "http://127.0.0.1:$port/release";
my %URL  = map { $_ => "$BASE/$_" } qw(tool tool.tar.gz tool.zip);
my $SUMS = join q{},
    map { "SHA256 ($URL{$_}) = " . _sha256("$srv/release/$_") . "\n" }
    sort keys %URL;

my $case = 0;

# _checkout(%file):
#	A checkout that holds one deps/ directory, and the home of
#	that case. Each key names a file of the directory, and each
#	value holds its text.
sub _checkout (%file)
{
	my $dir = "$tree/case" . ++$case;
	make_path( "$dir/deps", "$dir/home" );
	for my $name ( sort keys %file ) {
		Fugu::File->write( "$dir/deps/$name", $file{$name} )
		    or die "write $name";
	}

	return $dir;
}

# _deps($dir, $bin, $env, @argv):
#	Run the deps verb against one checkout, with the stub PATH of
#	$bin and the home of that checkout. The method empties the log
#	first, so _log holds the commands of this run alone.
#
#	--verbose is a global option of the program, and Fugu::CLI
#	parses the global options in front of the verb. The method
#	takes it in @argv and moves it there.
sub _deps ( $dir, $bin, $env, @argv )
{
	unlink $log;
	my @global = grep { $_ eq '--verbose' } @argv;
	my @option = grep { $_ ne '--verbose' } @argv;
	my $result = Fugu::Process->run(
		cmd => [
			$^X,  "-I$repo/lib", $program, @global,
			'-C', $dir,          'deps',   @option
		],
		env => {
			PATH   => $bin,
			HOME   => "$dir/home",
			TMPDIR => $tmp,
			%LIB, %$env
		},
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# _installed($dir, $name):
#	The bytes and the mode of one installed command, in that
#	order. An absent file gives the empty list.
sub _installed ( $dir, $name )
{
	my $file = "$dir/home/.local/bin/$name";
	return unless -f $file;

	return ( _slurp($file), sprintf '%04o', ( stat $file )[2] & 07777 );
}

# The package manager of each platform takes every package of the
# environment in one command, and an apt-get update comes first
# (DEPS-INSTALL-1)
{
	my %want = (
		Darwin => ['brew install one two'],
		Linux  => [ 'sudo apt-get update',
			'sudo apt-get install -y one two' ],
		OpenBSD => ['pkg_add one two'],
	);
	for my $os ( sort keys %want ) {
		my $dir =
		    _checkout( "$os.txt" => "test pkg one\ntest pkg two\n" );
		my $r = _deps( $dir, $path, {}, '--os', $os, 'test' );
		is( $r->{exit_code}, 0, "the packages of $os exit 0" );
		is_deeply( [ _log() ], $want{$os},
			"the package manager of $os ran with both packages" );
	}
}

# The result line is the whole standard output of a real run, and
# both streams of a child are the standard error (CLI-PROGRAM-4,
# CLI-PROGRAM-7, DEPS-INSTALL-10)
{
	my $dir = _checkout( 'Darwin.txt' => "test pkg one\n" );
	my $r = _deps( $dir, $path, {}, '--os', 'Darwin', 'test' );
	is(
		$r->{stdout},
		"installed the dependencies of test\n",
		'the standard output holds the result line alone'
	);
	unlike(
		$r->{stderr}, qr/\brun: /,
		'a run without --verbose traces no command'
	);
	like(
		$r->{stderr}, qr/^the child standard output$/m,
		'the standard output of a child reaches standard error'
	);
	like(
		$r->{stderr}, qr/^the child standard error$/m,
		'the standard error of a child reaches standard error'
	);
}

# --verbose traces each command on standard error, and it adds no
# line to standard output (CLI-PROGRAM-4, CLI-PROGRAM-7)
{
	my $dir = _checkout( 'Darwin.txt' => "test pkg one\n" );
	my $r =
	    _deps( $dir, $path, {}, '--verbose', '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 0, 'a verbose install exits 0' );
	is(
		$r->{stdout},
		"installed the dependencies of test\n",
		'--verbose leaves the standard output as it was'
	);
	like(
		$r->{stderr}, qr/^\S+ \S+ INFO: run: brew install one$/m,
		'--verbose traces the command on standard error'
	);
}

# --dry-run prints the trace on standard output, and it runs no
# command (DEPS-MANIFEST-6)
{
	my $dir = _checkout( 'Darwin.txt' => "test pkg one\n" );
	my $r = _deps( $dir, $path, {}, '--dry-run', '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 0, 'a dry run exits 0' );
	is(
		$r->{stdout}, "+ brew install one\n",
		'the trace of a dry run is the whole standard output'
	);
	is_deeply( [ _log() ], [], 'a dry run runs no command' );
}

# A cpan entry reaches cpanm --notest, and PERL_LOCAL_LIB_ROOT adds
# the local library (DEPS-INSTALL-2)
{
	my $dir = _checkout( 'Darwin.txt' => "test cpan Some::Module\n" );
	my $r = _deps( $dir, $path, {}, '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 0, 'a cpan entry exits 0' );
	is_deeply(
		[ _log() ],
		['cpanm --notest Some::Module'],
		'the cpan entry reaches the cpanm of PATH'
	);

	$r = _deps( $dir, $path, { PERL_LOCAL_LIB_ROOT => "$tree/local" },
		'--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 0, 'a local library exits 0' );
	is_deeply(
		[ _log() ],
		["cpanm --notest --local-lib=$tree/local Some::Module"],
		'the cpanm run names the local library'
	);
}

# Without a cpanm on PATH, the bootstrap downloads the standalone
# script and runs it under this perl (DEPS-INSTALL-3, DEPS-INSTALL-4)
{
	my $dir = _checkout( 'Darwin.txt' => "test cpan Some::Module\n" );
	my $r =
	    _deps( $dir, $bare, {}, '--verbose', '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 0, 'the bootstrap exits 0' );
	is(
		$r->{stdout},
		"installed the dependencies of test\n",
		'the download of the script reaches no standard output'
	);
	like(
		$r->{stderr},
		qr{^\S+ \S+ INFO: run: fugubench fetch \S+ \Qhttps://cpanmin.us\E$}m,
		'--verbose names the download of the standalone script'
	);
	is_deeply(
		[ _log() ],
		['cpanm --notest Some::Module'],
		'the standalone script runs with the options of the entry'
	);
}

# One run writes one form of the verbose trace. An in-process
# download and a child command take the same lead, and both join
# their words raw (CLI-PROGRAM-7)
{
	# A temporary directory with a space tells the two forms
	# apart. The shell quoting of the dry-run trace would wrap the
	# path of the download in single quotes.
	my $room = "$tree/with a space";
	make_path($room);
	my $dir = _checkout( 'Darwin.txt' => "test cpan Some::Module\n" );
	my $r   = _deps(
		$dir, $bare, { TMPDIR => $room }, '--verbose',
		'--os', 'Darwin', 'test'
	);
	is( $r->{exit_code}, 0, 'a spaced temporary directory exits 0' );
	like(
		$r->{stderr},
		qr{^\S+ \S+ INFO: run: fugubench fetch \Q$room\E/\S+/cpanm }m,
		'the verbose line of a download joins its words raw'
	);
	unlike(
		$r->{stderr}, qr{run: fugubench fetch '},
		'the verbose line of a download takes no shell quoting'
	);
}

# A dist entry downloads its tarball into a temporary directory,
# holds it to the recorded digest, and gives the file to cpanm
# (DEPS-INSTALL-2, DEPS-INSTALL-5)
{
	my $dir = _checkout(
		'Darwin.txt' => "test dist $URL{'tool.tar.gz'}\n",
		'SHA256.txt' => $SUMS,
	);
	my $r = _deps( $dir, $path, {}, '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 0, 'a dist entry exits 0' );
	my @ran = _log();
	is( scalar @ran, 1, 'the dist entry runs one command' );
	like(
		$ran[0], qr{\Acpanm --notest \Q$tmp\E/\S+/tool\.tar\.gz\z},
		'cpanm reads the checked download, and not the URL'
	);
}

# A dist entry that no tier covers stops the run before the first
# download, so no earlier entry of the type reaches cpanm
# (DEPS-INSTALL-9, DEPS-TIER-9)
{
	my $dir = _checkout(
		'Darwin.txt' => "test dist $URL{'tool.tar.gz'}\n"
		    . "test dist $BASE/other\n",
		'SHA256.txt' => $SUMS,
	);
	my $r = _deps( $dir, $path, {}, '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 1, 'a dist entry that no tier covers exits 1' );
	like(
		$r->{stderr}, qr{\Q$BASE/other\E has no recorded digest},
		'the message names the entry that no tier covers'
	);
	is_deeply( [ _log() ], [],
		'no dist entry of the set reaches cpanm' );
}

# A bin entry installs into ~/.local/bin with mode 755, from a plain
# file and from a tar archive (DEPS-INSTALL-6, DEPS-INSTALL-7)
{
	my $dir = _checkout(
		'Darwin.txt' => "test bin plain $URL{'tool'}\n"
		    . "test bin tarred $URL{'tool.tar.gz'} bin/tool\n",
		'SHA256.txt' => $SUMS,
	);
	my $r = _deps( $dir, $path, {}, '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 0, 'the two bin entries exit 0' );
	is_deeply(
		[ _installed( $dir, 'plain' ) ],
		[ $BINARY, '0755' ],
		'a plain file installs under its command name, with mode 755'
	);
	is_deeply(
		[ _installed( $dir, 'tarred' ) ],
		[ $BINARY, '0755' ],
		'tar unpacks the one named file, with mode 755'
	);
}

# unzip unpacks the one named file of a zip archive
# (DEPS-INSTALL-7)
SKIP: {
	skip 'no unzip is on PATH', 2 unless $UNZIP;

	my $dir = _checkout(
		'Darwin.txt' => "test bin zipped $URL{'tool.zip'} bin/tool\n",
		'SHA256.txt' => $SUMS,
	);
	my $r = _deps( $dir, $path, {}, '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 0, 'the zip entry exits 0' );
	is_deeply(
		[ _installed( $dir, 'zipped' ) ],
		[ $BINARY, '0755' ],
		'unzip unpacks the one named file, with mode 755'
	);
}

# A set that one entry cannot verify installs nothing
# (DEPS-INSTALL-9)
{
	my $dir = _checkout(
		'Darwin.txt' => "test bin plain $URL{'tool'}\n"
		    . "test bin other $BASE/other\n",
		'SHA256.txt' => $SUMS,
	);
	my $r = _deps( $dir, $path, {}, '--os', 'Darwin', 'test' );
	is( $r->{exit_code}, 1, 'an entry that no tier covers exits 1' );
	like(
		$r->{stderr}, qr{\Q$BASE/other\E has no recorded digest},
		'the message names the entry that no tier covers'
	);
	is_deeply(
		[ _installed( $dir, 'plain' ) ],
		[], 'the entry before it installs nothing'
	);
}

# A child that exits non-zero stops the run, and no later command of
# the environment runs
{
	my $dir = _checkout( 'Linux.txt' => "test pkg one\n" );
	my $r = _deps( $dir, $fail, {}, '--os', 'Linux', 'test' );
	is( $r->{exit_code}, 1, 'a child that exits non-zero exits 1' );
	is_deeply(
		[ _log() ],
		['sudo apt-get update'],
		'the install after the failed command does not run'
	);
	like(
		$r->{stderr}, qr/sudo exited 1/,
		'the message names the child and its exit code'
	);
	like(
		$r->{stderr}, qr/^the failed child said this$/m,
		'the standard error of a failed child reaches standard error'
	);
	unlike(
		$r->{stdout}, qr/installed the dependencies/,
		'a failed child writes no result line'
	);
}

done_testing();
