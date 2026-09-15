#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The shim verb, the install verb, and the install script (DIST-SHIM,
# DIST-INSTALL, DIST-VERSION, CLI-SANDBOX).
#
# The shim pins one release, so a checkout prints none. The file
# therefore builds one pack with a version that no release holds, and
# the shim cases run that pack. The build runs at the repository
# root, as t/fugubench/pack.t does. That build writes install.sh
# beside the pack, and one case runs that script.
#
# A stub downloader on a temporary PATH serves the pack. It reads the
# output flag, `-o` or `-O`, and it discards every other flag. One
# case serves the pack from a loopback server behind a redirect, and
# that case runs the downloader of the host, so it reads the real
# flags. No case reaches the network.
#
# Each case sets HOME to its own temporary tree, reads no operator
# home, and writes nowhere else. A child that loads the checkout
# carries PERL5LIB, because CI installs Fugu in a tree that PERL5LIB
# alone names. No run of the packed file carries it: the packed file
# must need no installed Fugu.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use Cwd              ();
use Digest::SHA      ();
use File::Basename   ();
use File::Copy       qw(copy);
use File::Path       qw(make_path);
use File::Spec       ();
use File::Temp       qw(tempdir);
use FindBin          qw($RealBin);
use IO::Socket::INET ();
use lib "$RealBin/../../lib";

use Fugu;
use Fugu::Log;
use Fugu::Process;
use Fugu::Sandbox;

use App::FuguBench;
use App::FuguBench::Checkout;

my $root    = "$RealBin/../..";
my $program = "$root/bin/fugubench";

# The version of the pack under test. No release holds it, so no
# stamp of a checkout passes a case by accident.
my $VERSION = '9.9.9';

# Fugu::Process gives a child the named environment alone, and CI
# reaches the installed Fugu through PERL5LIB. Every child that loads
# the checkout therefore carries it. Without it such a child fails to
# compile, and perl exits 2, which is the usage code of the program.
my %LIB = defined $ENV{PERL5LIB} ? ( PERL5LIB => $ENV{PERL5LIB} ) : ();

# The perl of the suite, and its directory. The packed file starts
# with `#!/usr/bin/env perl`, so the PATH of a shim run must name a
# perl.
my $PERL    = Cwd::abs_path($^X) // $^X;
my $PERLDIR = File::Basename::dirname($PERL);

# The stub downloader. It serves one file, and it records each call,
# so a case reads how many times the shim reached for the network.
# curl and ftp take -o, and wget takes -O.
my $STUB = <<'STUB';
#!/bin/sh
echo "$0 $*" >> '%s'
out=
while [ $# -gt 0 ]; do
	case $1 in
	-o|-O)	out=$2; shift 2 ;;
	*)	shift ;;
	esac
done
cat '%s' > "$out"
STUB

# The stub digest tool. It digests the file that the shim names, so
# no fixed value passes for a digest. `sha256 -q` prints the digest
# alone, and `sha256sum` prints the file name after it.
my $SUM = <<'SUM';
#!/bin/sh
exec '%s' -MDigest::SHA -e '
	my $f = $ARGV[-1];
	print Digest::SHA->new(256)->addfile($f)->hexdigest, %s, "\n";
' -- "$@"
SUM

# _read($path):
#	The whole text of one file.
sub _read ($path)
{
	open my $fh, '<', $path or do {
		fail("$path is readable");
		return q{};
	};
	binmode $fh;
	local $/ = undef;
	my $text = <$fh>;
	close $fh;

	return $text;
}

# _write($path, $text):
#	Write one file of a temporary tree.
sub _write ( $path, $text )
{
	open my $fh, '>', $path or die "cannot write $path: $!\n";
	print {$fh} $text;
	close $fh or die "cannot close $path: $!\n";

	return $path;
}

# _sha256($path):
#	The sha256 digest of one file, in lower-case hex.
sub _sha256 ($path)
{
	open my $fh, '<', $path or die "cannot read $path: $!\n";
	binmode $fh;
	my $digest = Digest::SHA->new(256)->addfile($fh)->hexdigest;
	close $fh;

	return $digest;
}

# _entries($dir):
#	The names in one directory, sorted, without the two dots. An
#	absent directory gives the empty list.
sub _entries ($dir)
{
	opendir my $dh, $dir or return ();
	my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;

	return @names;
}

# _mode($path):
#	The permission bits of one file.
sub _mode ($path)
{
	return ( stat $path )[2] & 07777;
}

# _env(%extra):
#	The environment of a child. The child holds the named
#	variables and nothing else, so no variable of the operator
#	reaches it.
sub _env (%extra)
{
	return { PATH => $ENV{PATH} // '/usr/bin:/bin', %extra };
}

# _which($name):
#	The path of one tool of the PATH of the operator, or undef.
sub _which ($name)
{
	for my $dir ( split /:/, ( $ENV{PATH} // '/usr/bin:/bin' ), -1 ) {
		next unless length $dir;
		my $path = File::Spec->catfile( $dir, $name );
		return $path if -f $path && -x $path;
	}

	return;
}

# _on_shim_path($name):
#	True when the PATH that _shell writes holds one tool. The
#	redirect case runs the downloader of the host, and not a
#	stub, so it needs one of the three.
sub _on_shim_path ($name)
{
	# The path goes through a variable, because a file test reads
	# a bare class name as a filehandle on perl 5.34.
	for my $dir ( $PERLDIR, '/usr/bin', '/bin', '/sbin' ) {
		my $path = File::Spec->catfile( $dir, $name );
		return 1 if -x $path;
	}

	return 0;
}

# _server($body):
#	One HTTP server on the loopback address. It answers every
#	path but /asset with a 302 to /asset, and /asset with $body.
#	It returns the port and the pid, and the caller kills that
#	pid.
#
#	A release asset of GitHub answers 302, so the download of the
#	shim must follow a redirect (DIST-SHIM-3). The server holds
#	that case inside the host, so no case reaches the network.
sub _server ($body)
{
	my $listen = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Listen    => 5,
		Proto     => 'tcp',
		ReuseAddr => 1,
	) or die "cannot listen on the loopback address: $!\n";
	my $port = $listen->sockport;

	my $pid = fork;
	die "cannot fork: $!\n" unless defined $pid;
	if ( !$pid ) {

		# The parent kills this child with a signal, so no END
		# block of Test::More runs here.
		while ( my $c = $listen->accept ) {
			binmode $c;
			my $request = q{};
			while ( my $line = <$c> ) {
				$request .= $line;
				last if $line =~ /\A\r?\n\z/;
			}
			my $path = ( $request =~ m{\A[A-Z]+[ ](\S+)} )[0] // q{};
			if ( $path eq '/asset' ) {
				print {$c} "HTTP/1.1 200 OK\r\n",
				    'Content-Length: ', length $body, "\r\n",
				    "Connection: close\r\n\r\n", $body;
			}
			else {
				print {$c} "HTTP/1.1 302 Found\r\n",
				    "Location: /asset\r\n",
				    "Content-Length: 0\r\n",
				    "Connection: close\r\n\r\n";
			}
			close $c;
		}
		exit 0;
	}
	close $listen;

	return ( $port, $pid );
}

# _tools($dir):
#	Link the tools that the shim runs into one directory, and the
#	perl of the suite beside them. A case then holds PATH to that
#	directory alone, so the shim finds the stub of the case and no
#	downloader and no digest tool of the host.
sub _tools ($dir)
{
	for my $name (qw(cat chmod mkdir mv rm)) {
		my $path = _which($name) or do {
			fail("the host holds $name");
			next;
		};
		symlink $path, "$dir/$name" or die "symlink $name: $!\n";
	}
	symlink $PERL, "$dir/perl" or die "symlink perl: $!\n";

	return $dir;
}

# _pack():
#	Build one pack in a temporary tree, and return the path of the
#	packed file and the path of the install script beside it.
sub _pack ()
{
	my $dir = tempdir( CLEANUP => 1 );
	my $r   = Fugu::Process->run(
		cmd => [
			$^X, 'scripts/pack', '--version', $VERSION,
			'--out', $dir
		],
		cwd => $root,
		env => _env( HOME => $dir, %LIB ),
	);
	die "cannot run scripts/pack: $r->{error}\n" if defined $r->{error};
	die "scripts/pack exited $r->{exit_code}: $r->{stderr}\n"
	    unless $r->{success};

	return map { File::Spec->catfile( $dir, $_ ) }
	    qw(fugubench install.sh);
}

# _run($home, $path, @argv):
#	Run one packed file as a child, with HOME and the current
#	directory in one temporary tree. The child carries no
#	PERL5LIB, so it reads no installed Fugu.
sub _run ( $home, $path, @argv )
{
	my $r = Fugu::Process->run(
		cmd => [ $path, @argv ],
		cwd => $home,
		env => _env( HOME => $home ),
	);
	die "cannot run $path: $r->{error}\n" if defined $r->{error};

	return $r;
}

# _unstamped(@argv):
#	Run the program of the checkout as a child. No release
#	stamped that file, so App::FuguBench->VERSION is undef in the
#	child. The child loads the checkout, so it carries PERL5LIB.
sub _unstamped (@argv)
{
	my $home = tempdir( CLEANUP => 1 );
	my $r    = Fugu::Process->run(
		cmd => [ $^X, "-I$root/lib", $program, @argv ],
		cwd => $home,
		env => _env( HOME => $home, %LIB ),
	);
	die "cannot run $program: $r->{error}\n" if defined $r->{error};

	return $r;
}

# _stamped( $version, @argv ):
#	Run the program as a child with one stamped version. The dist
#	build stamps `our $VERSION` into every package, and a
#	checkout carries no stamp, so the child writes the variable
#	that the stamp writes. The child loads the checkout, so it
#	carries PERL5LIB.
sub _stamped ( $version, @argv )
{
	my $home = tempdir( CLEANUP => 1 );
	my $r    = Fugu::Process->run(
		cmd => [
			$^X, "-I$root/lib", '-e',
			'use App::FuguBench;'
			    . ' $App::FuguBench::VERSION = shift;'
			    . ' exit App::FuguBench->new->run(@ARGV)',
			$version, @argv
		],
		cwd => $home,
		env => _env( HOME => $home, %LIB ),
	);
	die "cannot run the stamped program: $r->{error}\n"
	    if defined $r->{error};

	return $r;
}

# _shell($home, $bin, $shim, %extra):
#	Run one shim with a PATH of its own. $bin is the directory of
#	the stub downloader, and %extra adds a variable to the
#	environment of the child.
sub _shell ( $home, $bin, $shim, %extra )
{
	my $r = Fugu::Process->run(
		cmd => [ '/bin/sh', $shim, @{ delete $extra{argv} // [] } ],
		cwd => $home,
		env => {
			PATH => "$bin:$PERLDIR:/usr/bin:/bin:/sbin",
			HOME => $home,
			%extra
		},
	);
	die "cannot run /bin/sh: $r->{error}\n" if defined $r->{error};

	return $r;
}

# _entered(@argv):
#	Run the program in process, with the two sandbox calls
#	replaced. The helper reports the exit code, the promise sets
#	of the run, the unveil entries, and the result of the verb.
#
#	It reports each path that exists at the call as well. A
#	required entry of an absent path stops the unveil, so a row
#	that makes a directory must make it before the call.
#
#	The result of the verb goes to a string, and the logger is
#	quiet, so neither stream joins the test output.
sub _entered (@argv)
{
	my ( @promises, @paths, %present );
	my $out = q{};
	my $code;

	my $log = Fugu::Log->default;
	Fugu::Log->set_default( Fugu::Log->new( mode => 'quiet' ) );
	{
		no warnings 'redefine';
		local *Fugu::Sandbox::pledge = sub ( $, %args ) {
			push @promises, $args{promises};
			return 1;
		};
		local *Fugu::Sandbox::unveil = sub ( $, %args ) {
			for my $entry ( @{ $args{paths} } ) {
				push @paths, $entry;
				$present{ $entry->[0] } = -e $entry->[0] ? 1 : 0;
			}
			return 1;
		};

		open my $fh, '>', \$out or die "capture: $!";
		my $old = select $fh;
		$code = App::FuguBench->new->run(@argv);
		select $old;
		close $fh;
	}
	Fugu::Log->set_default($log);

	return {
		code     => $code,
		promises => \@promises,
		paths    => \@paths,
		present  => \%present,
		out      => $out,
	};
}

my ( $packed, $script ) = _pack();
my $digest = _sha256($packed);
my $line   = sprintf "fugubench %s (Fugu %s)\n", $VERSION, Fugu->VERSION;

# The shim text of the pack. Every shim case reads it.
my $text;
subtest 'the shim of a release' => sub {
	my $home = tempdir( CLEANUP => 1 );
	my $r    = _run( $home, $packed, 'shim' );
	is( $r->{exit_code}, 0,   'shim exits 0' );
	is( $r->{stderr},    q{}, 'shim writes nothing to standard error' );
	$text = $r->{stdout};

	my @lines = split /^/, $text;
	ok( @lines <= 60, 'the shim fits in 60 lines' )
	    or diag scalar @lines;

	# The URL of the version that printed it, and the digest of
	# the file that printed it (DIST-SHIM-1)
	like(
		$text,
		qr{^url=https://github[.]com/FuguBSD/FuguBench/releases/download/v\Q$VERSION\E/fugubench$}m,
		'the shim holds the URL of the release'
	);
	like( $text, qr/^want=\Q$digest\E$/m,
		'the shim holds the digest of the packed file' );

	my $shim = _write( "$home/fugubench.sh", $text );
	my $n = Fugu::Process->run(
		cmd => [ '/bin/sh', '-n', $shim ],
		env => _env( HOME => $home ),
	);
	is( $n->{exit_code}, 0, 'sh -n accepts the shim' )
	    or diag $n->{stderr};
};

subtest 'a file that no release stamped pins nothing' => sub {

	# A checkout carries no stamp at all, and a build of a tree
	# with no tag carries 0.0.0. No release holds either one.
	is( App::FuguBench->VERSION, undef, 'the checkout carries no stamp' );

	my $r = _unstamped('shim');
	is( $r->{exit_code}, 1,   'the checkout shim exits 1' );
	is( $r->{stdout},    q{}, 'and it prints no shim' );
	like(
		$r->{stderr}, qr/no release stamped this file/,
		'and the message names the reason'
	);

	my $s = _stamped( '0.0.0', 'shim' );
	is( $s->{exit_code}, 1,   'a build of 0.0.0 exits 1 too' );
	is( $s->{stdout},    q{}, 'and it prints no shim' );
	like(
		$s->{stderr}, qr/no release stamped this file/,
		'and it names the same reason'
	);
};

subtest 'a version of another shape writes no shell' => sub {

	# The verb writes the version into shell text, so a value with
	# a space or a semicolon must stop it (DIST-SHIM-1).
	for my $bad ( '1.0.0; echo pwned', '1.0 0', 'HEAD' ) {
		my $r = _stamped( $bad, 'shim' );
		is( $r->{exit_code}, 1, "the shim of '$bad' exits 1" );
		is( $r->{stdout}, q{}, 'and it prints no shim' );
		like(
			$r->{stderr}, qr/no dotted-decimal number/,
			'and the message names the shape'
		);
	}
};

subtest 'the shim fetches, verifies, caches, and runs' => sub {
	my $home = tempdir( CLEANUP => 1 );
	my $bin  = tempdir( CLEANUP => 1 );
	my $log  = "$bin/calls";
	_write( "$bin/curl", sprintf $STUB, $log, $packed );
	chmod 0755, "$bin/curl" or die "chmod: $!";

	my $shim  = _write( "$home/fugubench.sh", $text );
	my $cache = "$home/.cache/fugubench/$VERSION";

	my $r = _shell( $home, $bin, $shim, argv => ['version'] );
	is( $r->{exit_code}, 0,     'the first run exits 0' );
	is( $r->{stdout},    $line, 'and the argument reaches the program' );
	ok( -f $log, 'and the shim ran the downloader' );

	my $file = "$cache/fugubench";
	ok( -f $file, 'the shim caches the packed file' );
	is( _mode($file), 0755, 'and the cached file holds mode 755' );
	is( _sha256($file), $digest, 'and it holds the bytes of the pack' );

	# The second run reads the cache, so the downloader records
	# no second call (DIST-SHIM-3).
	my $again = _shell( $home, $bin, $shim, argv => ['version'] );
	is( $again->{exit_code}, 0,     'the second run exits 0' );
	is( $again->{stdout},    $line, 'and it prints the same line' );
	my @calls = split /^/, _read($log);
	is( scalar @calls, 1, 'and it reaches no downloader' );

	# The shim exits with the code of the program, and an unknown
	# verb is a usage error (DIST-SHIM-5, CLI-PROGRAM-3).
	my $bad = _shell( $home, $bin, $shim, argv => ['nosuchverb'] );
	is( $bad->{exit_code}, 2, 'the shim exits with the code of the program' );
	like(
		$bad->{stderr}, qr/^usage: fugubench /m,
		'and the usage of the program reaches standard error'
	);
};

subtest 'the shim follows a redirect' => sub {

	# A release asset of GitHub answers 302, so a downloader that
	# follows no redirect writes the redirect answer and not the
	# pack (DIST-SHIM-3). This case runs the downloader of the
	# host against a loopback server, so it reads the real flags.
	# Every other case runs a stub that reads the output flag
	# alone, and discards each other one.
	my @get = grep { _on_shim_path($_) } qw(curl wget ftp);
	my @sum = grep { _on_shim_path($_) } qw(sha256 shasum sha256sum);
	plan skip_all => 'the PATH of the shim holds no downloader,'
	    . ' or no digest tool'
	    unless @get && @sum;

	my $home = tempdir( CLEANUP => 1 );
	my $bin  = tempdir( CLEANUP => 1 );
	my ( $port, $pid ) = _server( _read($packed) );

	# The URL of the shim names the release, so the case points
	# that one line at the loopback server. Every other line of
	# the shim stands as the verb wrote it.
	my $local = $text;
	my $count = ( $local =~ s{^url=\S+$}{url=http://127.0.0.1:$port/get}m );
	is( $count, 1, 'the shim holds one url line' );

	my $shim = _write( "$home/fugubench.sh", $local );
	my $r    = _shell( $home, $bin, $shim, argv => ['version'] );
	kill 'TERM', $pid;
	waitpid $pid, 0;

	is( $r->{exit_code}, 0, "the $get[0] run exits 0" )
	    or diag $r->{stderr};
	is( $r->{stdout}, $line, "and $get[0] served the packed file" );

	my $file = "$home/.cache/fugubench/$VERSION/fugubench";
	ok( -f $file, 'the shim caches the file' ) or return;
	is( _sha256($file), $digest,
		'and the cache holds the body of the second address' );
};

subtest 'a download that fails the digest stops the shim' => sub {
	my $home  = tempdir( CLEANUP => 1 );
	my $bin   = tempdir( CLEANUP => 1 );
	my $log   = "$bin/calls";
	my $other = _write( "$home/other", "not the packed file\n" );
	my $wrong = _sha256($other);
	_write( "$bin/curl", sprintf $STUB, $log, $other );
	chmod 0755, "$bin/curl" or die "chmod: $!";

	my $shim = _write( "$home/fugubench.sh", $text );
	my $r = _shell( $home, $bin, $shim, argv => ['version'] );
	isnt( $r->{exit_code}, 0,   'the shim exits non-zero' );
	is( $r->{stdout},      q{}, 'and no program runs' );
	like( $r->{stderr}, qr/\Qwant $digest\E/,
		'and the message holds the expected digest' );
	like( $r->{stderr}, qr/\Qgot $wrong\E/,
		'and it holds the computed digest' );

	is_deeply( [ _entries("$home/.cache/fugubench/$VERSION") ],
		[], 'the shim deletes the download' );
};

subtest 'FUGUBENCH replaces the download' => sub {
	my $home = tempdir( CLEANUP => 1 );
	my $bin  = tempdir( CLEANUP => 1 );
	my $log  = "$bin/calls";
	_write( "$bin/curl", sprintf $STUB, $log, $packed );
	chmod 0755, "$bin/curl" or die "chmod: $!";

	my $shim = _write( "$home/fugubench.sh", $text );
	my $r = _shell( $home, $bin, $shim,
		argv => ['version'], FUGUBENCH => $packed );
	is( $r->{exit_code}, 0,     'the shim exits 0' );
	is( $r->{stdout},    $line, 'and it runs the named file' );
	ok( !-e $log, 'and it reaches no downloader' );
	ok( !-e "$home/.cache", 'and it writes no cache' );

	# DIST-SHIM-2 conditions on an executable, and the developer
	# named the file, so a value that names none stops the shim.
	# A silent download of the release would run a program that
	# the developer did not name.
	my $plain = _write( "$home/plain", "not a program\n" );
	my $p     = _shell( $home, $bin, $shim,
		argv => ['version'], FUGUBENCH => $plain );
	isnt( $p->{exit_code}, 0, 'a value that names no executable exits'
		    . ' non-zero' );
	is( $p->{stdout}, q{}, 'and no program runs' );
	like( $p->{stderr}, qr/\Q$plain\E is no executable/,
		'and the message names the value' );
	ok( !-e $log,     'and it reaches no downloader' );
	ok( !-e "$home/.cache", 'and it writes no cache' );

	# An empty value is a set value, and it names no executable
	# (DIST-SHIM-2). `FUGUBENCH=$(command -v fugubench)` writes
	# one on a failed lookup. A gate that tests the value for
	# emptiness alone downloads the release, and runs a program
	# that the developer did not name.
	my $e = _shell( $home, $bin, $shim,
		argv => ['version'], FUGUBENCH => q{} );
	isnt( $e->{exit_code}, 0, 'an empty value exits non-zero' );
	is( $e->{stdout}, q{}, 'and no program runs' );
	like( $e->{stderr}, qr/FUGUBENCH= is no executable/,
		'and the message names the variable' );
	ok( !-e $log,     'and it reaches no downloader' );
	ok( !-e "$home/.cache", 'and it writes no cache' );
};

subtest 'the shim names the downloaders that it wants' => sub {
	my $home = tempdir( CLEANUP => 1 );
	my $bin  = tempdir( CLEANUP => 1 );

	# The PATH holds one empty directory, so the shim finds no
	# downloader at all (DIST-SHIM-7).
	my $shim = _write( "$home/fugubench.sh", $text );
	my $r    = Fugu::Process->run(
		cmd => [ '/bin/sh', $shim, 'version' ],
		cwd => $home,
		env => { PATH => $bin, HOME => $home },
	);
	die "cannot run /bin/sh: $r->{error}\n" if defined $r->{error};

	isnt( $r->{exit_code}, 0, 'the shim exits non-zero' );
	like( $r->{stderr}, qr/curl/,  'the message names curl' );
	like( $r->{stderr}, qr/wget/,  'and wget' );
	like( $r->{stderr}, qr/\bftp/, 'and ftp' );
	ok( !-e "$home/.cache", 'and the shim makes no cache directory' );

	# A value of the environment must pass for no tool. The shim
	# resets each variable of its selection, so this run reports
	# the absent downloader as the run above does (DIST-SHIM-3).
	my $j = Fugu::Process->run(
		cmd => [ '/bin/sh', $shim, 'version' ],
		cwd => $home,
		env => {
			PATH => $bin,
			HOME => $home,
			get  => 'curl',
			sum  => 'shasum',
			got  => 'nothing',
		},
	);
	die "cannot run /bin/sh: $j->{error}\n" if defined $j->{error};

	isnt( $j->{exit_code}, 0, 'an inherited get exits non-zero as well' );
	like(
		$j->{stderr}, qr/install curl, wget or ftp/,
		'and the message names the three downloaders'
	);
	ok( !-e "$home/.cache", 'and the shim makes no cache directory' );
};

subtest 'the shim takes each downloader and each digest tool' => sub {

	# The redirect case takes the first downloader and the first
	# digest tool of the host, and that digest tool is `sha256`
	# on macOS. So these three runs cover each downloader and
	# each digest tool of DIST-SHIM-3 by themselves. PATH holds
	# the stub directory alone, so no tool of the host takes a
	# branch, and the last pair is the pair that OpenBSD selects.
	my %tail =
	    ( sha256 => 'q{}', shasum => '"  $f"', sha256sum => '"  $f"' );

	for my $pair (
		[ 'curl', 'shasum' ],
		[ 'wget', 'sha256sum' ],
		[ 'ftp',  'sha256' ]
	    )
	{
		my ( $get, $sum ) = @$pair;

		my $home = tempdir( CLEANUP => 1 );
		my $bin  = tempdir( CLEANUP => 1 );
		_tools($bin);

		my $log = "$bin/calls";
		_write( "$bin/$get", sprintf $STUB, $log, $packed );
		_write( "$bin/$sum", sprintf $SUM, $PERL, $tail{$sum} );
		chmod 0755, "$bin/$get", "$bin/$sum" or die "chmod: $!";

		my $shim = _write( "$home/fugubench.sh", $text );
		my $r    = Fugu::Process->run(
			cmd => [ '/bin/sh', $shim, 'version' ],
			cwd => $home,
			env => { PATH => $bin, HOME => $home },
		);
		die "cannot run /bin/sh: $r->{error}\n" if defined $r->{error};

		is( $r->{exit_code}, 0, "the $get and $sum run exits 0" )
		    or diag $r->{stderr};
		is( $r->{stdout}, $line, "and $get served the packed file" );

		my $file = "$home/.cache/fugubench/$VERSION/fugubench";
		ok( -f $file, "and the shim cached the file of $get" ) or next;
		is( _sha256($file), $digest, "and $sum held it to the digest" );
	}
};

subtest 'an inherited variable passes for no digest tool' => sub {

	# Without the reset of DIST-SHIM-3 an inherited `got` that
	# holds the expected digest installs and runs an unverified
	# download. The stub directory holds no digest tool, so the
	# shim must name the three commands and stop.
	my $home = tempdir( CLEANUP => 1 );
	my $bin  = tempdir( CLEANUP => 1 );
	_tools($bin);

	# The stub serves other bytes, and that file prints a word
	# that no run of the packed file prints.
	my $other = _write( "$home/other", "#!/bin/sh\necho unverified\n" );
	my $log   = "$bin/calls";
	_write( "$bin/curl", sprintf $STUB, $log, $other );
	chmod 0755, "$bin/curl" or die "chmod: $!";

	my $shim = _write( "$home/fugubench.sh", $text );
	my $r    = Fugu::Process->run(
		cmd => [ '/bin/sh', $shim, 'version' ],
		cwd => $home,
		env => {
			PATH => $bin,
			HOME => $home,
			sum  => 'nosuchsum',
			got  => $digest,
		},
	);
	die "cannot run /bin/sh: $r->{error}\n" if defined $r->{error};

	isnt( $r->{exit_code}, 0, 'the shim exits non-zero' );
	like(
		$r->{stderr}, qr/install sha256, shasum or sha256sum/,
		'and the message names the three digest tools'
	);
	is( $r->{stdout}, q{}, 'and no download runs' );
	ok( !-e $log, 'and the shim reaches no downloader' );
	is_deeply( [ _entries("$home/.cache/fugubench/$VERSION") ],
		[], 'and it caches nothing' );
};

subtest 'install copies the running file' => sub {
	my $home = tempdir( CLEANUP => 1 );
	ok(
		!defined App::FuguBench::Checkout->new( start => $home ),
		'the temporary tree sits under no checkout'
	);

	my $dir    = "$home/.local/bin";
	my $target = "$dir/fugubench";

	# The umask of the operator reaches the open of the write, and
	# DIST-INSTALL-2 wants the mode of the file.
	my $old = umask 0077;
	my $r   = _run( $home, $packed, 'install' );
	umask $old;

	is( $r->{exit_code},  0,           'install exits 0' );
	is( $r->{stdout},     "$target\n", 'and it prints the path' );
	is( _sha256($target), $digest,     'and the copy holds the bytes' );
	is( _mode($target),   0755,        'and it holds mode 755' );

	# The verb reads no checkout, so no walk reports one
	# (CLI-CHECKOUT-5).
	unlike( $r->{stderr}, qr/toolingrc/,
		'and it reports no configuration error' );
	like(
		$r->{stderr}, qr/no PATH entry names \Q$dir\E/,
		'and it hints when no PATH entry names the directory'
	);

	# The second run replaces the file, and the hint stays away
	# when the directory sits on PATH (DIST-INSTALL-2).
	my $p = Fugu::Process->run(
		cmd => [ $packed, 'install' ],
		cwd => $home,
		env => { PATH => "$dir:/usr/bin:/bin", HOME => $home },
	);
	die "cannot run $packed: $p->{error}\n" if defined $p->{error};
	is( $p->{exit_code}, 0,           'the second install exits 0' );
	is( $p->{stdout},    "$target\n", 'and it prints the path again' );
	is( $p->{stderr},    q{},         'and it prints no hint' );
	is( _mode($target),  0755,        'and the mode holds' );
};

subtest 'the install script fetches the pack and installs it' => sub {
	my $home = tempdir( CLEANUP => 1 );
	my $bin  = tempdir( CLEANUP => 1 );
	my $log  = "$bin/calls";
	_write( "$bin/curl", sprintf $STUB, $log, $packed );
	chmod 0755, "$bin/curl" or die "chmod: $!";

	my $n = Fugu::Process->run(
		cmd => [ '/bin/sh', '-n', $script ],
		env => _env( HOME => $home ),
	);
	is( $n->{exit_code}, 0, 'sh -n accepts the install script' )
	    or diag $n->{stderr};

	# The script is the shim with one argument list, so it fetches
	# and verifies as the shim does, and then it runs the install
	# verb of the packed file (DIST-INSTALL-1).
	my $r      = _shell( $home, $bin, $script );
	my $target = "$home/.local/bin/fugubench";
	is( $r->{exit_code}, 0, 'the install script exits 0' )
	    or diag $r->{stderr};
	is( $r->{stdout},     "$target\n", 'and it prints the installed path' );
	is( _sha256($target), $digest, 'and the copy holds the bytes of the pack' );
	is( _mode($target),   0755,    'and the copy holds mode 755' );

	ok( -f $log, 'the script reaches the downloader' );
	ok(
		-f "$home/.cache/fugubench/$VERSION/fugubench",
		'and the fetch passes through the shim cache'
	);
};

subtest 'a build that no release holds writes no install script' => sub {

	# A build of a tree with no tag carries 0.0.0, and no release
	# holds it. The shim of such a pack pins nothing, so the packer
	# writes the packed file alone (DIST-INSTALL-1).
	my $dir = tempdir( CLEANUP => 1 );
	my $r   = Fugu::Process->run(
		cmd => [
			$^X, 'scripts/pack', '--version', '0.0.0',
			'--out', $dir
		],
		cwd => $root,
		env => _env( HOME => $dir, %LIB ),
	);
	die "cannot run scripts/pack: $r->{error}\n" if defined $r->{error};

	is( $r->{exit_code}, 0, 'the build exits 0' ) or diag $r->{stderr};
	ok( -f "$dir/fugubench",   'and it writes the packed file' );
	ok( !-e "$dir/install.sh", 'and it writes no install script' );
	like(
		$r->{stderr}, qr/writes no install\.sh/,
		'and it reports the reason'
	);
};

subtest 'the two sandbox rows' => sub {
	my @lib = map { [ $_, 'r', { optional => 1 } ] }
	    Fugu::Sandbox->perl_lib_dirs;

	# The row runs in front of the verb, and the checkout that
	# runs this test carries no stamp, so the verb returns 1.
	my $s = _entered('shim');
	is( $s->{code}, 1, 'shim exits 1 in a checkout' );
	is_deeply( $s->{promises}, ['stdio rpath'],
		'the shim row pledges stdio rpath, and no write promise' );
	is_deeply(
		$s->{paths},
		[ @lib, [ $RealBin, 'r' ] ],
		'and it unveils the library directories and the running file'
	);

	# The install row adds the install directory, and it makes
	# that directory, because unveil(2) hides what the list
	# leaves out (CLI-SANDBOX-2).
	my $home = tempdir( CLEANUP => 1 );
	local $ENV{HOME} = $home;
	my $dir = "$home/.local/bin";

	my $i = _entered('install');
	is( $i->{code}, 0, 'install exits 0' );
	is_deeply(
		$i->{promises},
		['stdio rpath wpath cpath fattr'],
		'the install row pledges the write promises'
	);
	is_deeply(
		$i->{paths},
		[ @lib, [ $RealBin, 'r' ], [ $dir, 'rwc' ] ],
		'and it unveils the install directory beside them'
	);
	is( $i->{present}{$dir}, 1, 'the row makes it before the call' );

	# The verb copies the running file, and this run is the test
	# itself.
	is( $i->{out}, "$dir/fugubench\n", 'the verb prints the path' );
	is(
		_sha256("$dir/fugubench"),
		_sha256( Cwd::abs_path($0) ),
		'and it copies the running file'
	);
};

subtest 'the install row names one directory once' => sub {

	# The install directory holds the running file after an
	# install. unveil(2) returns EPERM on a second entry that
	# widens a path, so the row must name that directory once
	# (CLI-SANDBOX-2).
	my @lib = map { [ $_, 'r', { optional => 1 } ] }
	    Fugu::Sandbox->perl_lib_dirs;

	my $home = tempdir( CLEANUP => 1 );
	my $dir  = "$home/.local/bin";
	make_path($dir) or die "cannot make $dir: $!\n";

	my $running = "$dir/fugubench";
	copy( $0, $running ) or die "cannot copy $0: $!\n";

	local $ENV{HOME} = $home;
	local $0         = $running;

	my $i = _entered('install');
	is( $i->{code}, 0, 'install exits 0' ) or diag $i->{out};
	is_deeply(
		$i->{paths},
		[ @lib, [ $dir, 'rwc' ] ],
		'the row holds one entry for the install directory'
	);
	is( $i->{out}, "$running\n", 'and the verb prints the path' );
};

done_testing();
