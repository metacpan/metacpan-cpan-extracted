#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The update verb (DIST-UPDATE, DIST-KEY, CLI-SANDBOX).
#
# The verb fetches a release, verifies it against the embedded keys,
# and replaces the running file. Each case therefore needs a signed
# release and a program of its own to replace.
#
# No case asks the network. One forked server over the core
# IO::Socket::INET answers on the loopback address, and each case
# takes a directory of its own under one document root. The server
# records every request path, so a case reads what the verb asked
# for, and in which order.
#
# Each case copies bin/fugubench into its own tree and runs that copy
# as a child. A temporary library directory comes first in @INC. It
# holds a copy of App::FuguBench with the stamp of a release, as the
# dist build writes it, and a copy of App::FuguBench::Keys with the
# fixture key in place of the organization keys. So no case needs a
# release, and no case reaches an organization key.
#
# The copy carries mode 600, and the run holds the umask to 077. A
# case that asserts mode 755 therefore reads the chmod of the verb,
# and a case of a failed update reads the mode that no write touched.
#
# Each child carries PERL5LIB, because CI reaches the installed Fugu
# through that variable alone. PATH names the downloader of this host
# and nothing else, so the verb needs no other command.
#
# The fixtures under t/fugubench/fixtures/update/ hold the public half
# of one signify key pair and two signed release trees. The tree holds
# no secret key, because each manifest carries its signature already
# and no case signs. These commands made the set one time, with
# signify(1), and a new set needs a new pair. They run at the
# repository root, and the secret half lands under gitignored
# scratch/, never under the fixture tree:
#
#	fix=t/fugubench/fixtures/update
#	signify -G -n -c 'fugubench update fixture' \
#		-p $fix/keys/fugubench-fixture.pub \
#		-s scratch/fugubench-fixture.sec
#	for v in v1.3.0 v1.1.0; do
#		signify -S -s scratch/fugubench-fixture.sec \
#			-m $fix/$v/SHA256 -x $fix/$v/SHA256.sig
#	done
#
# The key signs the two fixture releases and nothing else. It is no
# key of the organization, and one case holds it apart from the
# embedded list.
#
# One case embeds a key that signed nothing, and it derives that key
# from the fixture body. DIST-KEY-3 names that condition: a program
# whose embedded list lacks the key of the release.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use Digest::SHA      ();
use File::Basename   qw(basename dirname);
use File::Copy       qw(copy);
use File::Path       qw(make_path);
use File::Temp       qw(tempdir);
use FindBin          qw($RealBin);
use IO::Socket::INET ();
use MIME::Base64     ();
use POSIX            ();
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Log;
use Fugu::Process;
use Fugu::Sandbox;

use App::FuguBench;
use App::FuguBench::Keys;

my $repo    = "$RealBin/../..";
my $program = "$repo/bin/fugubench";
my $fixture = "$RealBin/fixtures/update";

# The stamp of the running program in every case. It sits between the
# two fixture releases, so one is an update and the other is a
# downgrade.
my $STAMP = '1.2.0';

# Fugu::Process gives a child the named environment alone, and CI
# reaches the installed Fugu through PERL5LIB.
my %LIB = defined $ENV{PERL5LIB} ? ( PERL5LIB => $ENV{PERL5LIB} ) : ();

# The verb verifies in-process, so the release of Fugu must hold the
# downloader, the verifier, and its perl engine.
plan skip_all => 'the installed Fugu holds no Fugu::Curl'
    unless eval { require Fugu::Curl; 1 };
plan skip_all => 'the installed Fugu holds no Fugu::Ed25519'
    unless eval { require Fugu::Ed25519; 1 };
plan skip_all => 'the installed Fugu holds no Fugu::Signify'
    unless eval { require Fugu::Signify; 1 };

my $signify = eval { Fugu::Signify->new( engine => 'perl' ) };
plan skip_all => 'Fugu::Signify holds no perl engine'
    unless $signify && $signify->is_available;

my $downloader = Fugu::Curl->new;
plan skip_all => 'no downloader is on PATH' unless $downloader->is_available;

# The published install command (DIST-INSTALL-3). Every case reads
# the constant, so no case repeats the literal.
my $INSTALL = App::FuguBench::Update::INSTALL();

my $tree = tempdir( CLEANUP => 1 );
my $srv  = "$tree/srv";
my $tmp  = "$tree/tmp";
my $bin  = "$tree/bin";
make_path( $srv, $tmp, $bin );

# The library directory of a child. _lib makes one for each stamp,
# and it asserts, so the first call comes after the last skip_all
# of this file.
my $lib;

my $requests = "$tree/requests";

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

# _sha256($text):
#	The sha256 digest of one string, in lower-case hexadecimal.
sub _sha256 ($text)
{
	return Digest::SHA->new(256)->add($text)->hexdigest;
}

# _mode($path):
#	The permission bits of one file.
sub _mode ($path)
{
	return ( stat $path )[2] & 07777;
}

# _entries($dir):
#	The names in one directory, sorted, without the two dots and
#	without a hidden name.
sub _entries ($dir)
{
	opendir my $dh, $dir or die "opendir $dir: $!";
	my @names = sort grep { !/\A[.]/ } readdir $dh;
	closedir $dh;

	return @names;
}

# The PATH of each child: the downloader of this host, and nothing
# else. The verb writes every file itself, so it needs no other
# command.
symlink $downloader->command, "$bin/" . basename( $downloader->command )
    or die "symlink the downloader: $!";

# _answer($conn, $path):
#	Write one response of the server. A path that names no file
#	under the document root takes 404, which the verb reads as an
#	absent tag or an absent asset.
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

# _record($path):
#	Append one request path to the log of the server. The line
#	goes down before the answer, and the file closes with it, so
#	the parent reads a whole line after the child of a case exits.
sub _record ($path)
{
	open my $fh, '>>', $requests or return;
	print {$fh} ( $path // q{} ), "\n";
	close $fh;

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
		_record($path);
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

# The fixture key, as the embedded list of a child. DIST-KEY-2 gives
# the embedded keys to this verb alone, so a child must hold no key of
# a consumer and no key of the organization.
my $KEY = ( split /\n/, _slurp("$fixture/keys/fugubench-fixture.pub") )[1];

# A key body that signed nothing: the fixture body with one step of
# its key number. A body holds the algorithm in the first two bytes,
# the key number in the next eight, and the key in the rest. The
# verifier compares the key number before it checks the signature, so
# this key verifies no fixture release. One case embeds it alone, and
# the program then lacks the key of the release (DIST-KEY-3).
my $OTHER = do {
	my $bytes = MIME::Base64::decode_base64($KEY);
	my $first = ord substr $bytes, 2, 1;
	substr $bytes, 2, 1, chr( ( $first + 1 ) % 256 );
	MIME::Base64::encode_base64( $bytes, q{} );
};

# _lib($stamp, $key, $label):
#	One library directory of a child, first in @INC. It holds a
#	copy of App::FuguBench with the stamp of a release, as the
#	dist build writes it, and a copy of App::FuguBench::Keys with
#	$key in place of the organization keys. So no case needs a
#	release, and no case reaches an organization key.
#
#	$key defaults to the fixture key, and $label names the
#	directory. The case of DIST-KEY-3 passes $OTHER, which signed
#	nothing, so its directory takes a label of its own.
#
#	The helper asserts, so the first call comes after the last
#	skip_all of this file. A plan behind an assertion writes
#	'1..0 # SKIP' after an 'ok' line, and the harness fails then.
sub _lib ( $stamp, $key = $KEY, $label = $stamp )
{
	my $dir = "$tree/lib-$label";
	make_path("$dir/App/FuguBench");

	my $source = _slurp("$repo/lib/App/FuguBench.pm");
	my $count  = ( $source =~
		    s{^package App::FuguBench;$}
		     {package App::FuguBench;\nour \$VERSION = '$stamp';}m );
	is( $count, 1,
		"the stamp $stamp reaches the package line of"
		    . ' App::FuguBench' );
	Fugu::File->write( "$dir/App/FuguBench.pm", $source )
	    or die 'write the stamped App::FuguBench';

	# The heredoc carries its own indentation, because the scan of
	# t/fugubench/conventions.t reads a package line of this file at
	# the first column as the package of this file.
	Fugu::File->write( "$dir/App/FuguBench/Keys.pm", <<~"KEYS" )
		package App::FuguBench::Keys;

		use v5.34;
		use warnings;
		use experimental 'signatures';
		no feature qw(indirect multidimensional bareword_filehandles);

		sub keys (\$)
		{
			return ( [ 'fugubench-fixture', '$key' ] );
		}

		1;
		KEYS
	    or die 'write the fixture App::FuguBench::Keys';

	return $dir;
}

$lib = _lib($STAMP);

# _base($case):
#	The release address of one case. FUGUBENCH_RELEASE_URL takes
#	this value, in the place of the host and the repository
#	(DIST-UPDATE-1).
sub _base ($case)
{
	return "http://127.0.0.1:$port/$case";
}

# _release($case, $where, $version, %change):
#	One release directory of the server: a copy of one fixture
#	tree, under the release path $where of the case. A value of
#	%change replaces the file of that name, and an undefined value
#	removes it.
sub _release ( $case, $where, $version, %change )
{
	my $dir = "$srv/$case/$where";
	make_path($dir);

	for my $name ( _entries("$fixture/$version") ) {
		copy( "$fixture/$version/$name", "$dir/$name" )
		    or die "copy $name: $!";
	}

	for my $name ( sort keys %change ) {
		if ( defined $change{$name} ) {
			Fugu::File->write( "$dir/$name", $change{$name} )
			    or die "write $name";
		}
		else {
			unlink "$dir/$name" or die "unlink $name: $!";
		}
	}

	return $dir;
}

# _requests($case):
#	Every request path that the server answered for one case, in
#	order. A case reads it to tell what the verb downloaded, and
#	what it did not.
sub _requests ($case)
{
	return () unless -e $requests;

	return grep { m{\A/\Q$case\E/} } split /\n/, _slurp($requests);
}

# _update($case, %args):
#	Run one update as a child of this case, and return the result
#	of Fugu::Process->run with the path of the program under file.
#
#	%args:
#		argv => \@list  # the options of the verb
#		home => $path   # the HOME of the child
#		file => $path   # the program that the verb replaces
#		url  => $string # FUGUBENCH_RELEASE_URL
#		lib  => $path   # the library of the child, in place of
#		                # the one of the running stamp
#		env  => \%pairs # a change of the environment; an
#		                # undefined value removes the variable
#
#	The umask of the run is 077, so a copy that holds mode 755
#	after the run took the chmod of the verb.
sub _update ( $case, %args )
{
	my $home = $args{home} // "$tree/home-$case";
	my $file = $args{file} // "$home/bin/fugubench";
	make_path( $home, dirname($file) );

	copy( $program, $file ) or die "copy $program: $!";
	chmod 0600, $file or die "chmod $file: $!";

	my %env = (
		PATH                  => $bin,
		HOME                  => $home,
		TMPDIR                => $tmp,
		FUGUBENCH_RELEASE_URL => $args{url} // _base($case),
		%LIB,
	);
	for my $name ( sort keys %{ $args{env} // {} } ) {
		my $value = $args{env}{$name};
		if ( defined $value ) { $env{$name} = $value }
		else                  { delete $env{$name} }
	}

	my $old = umask 0077;
	my $r   = Fugu::Process->run(
		cmd => [
			$^X, '-I' . ( $args{lib} // $lib ), "-I$repo/lib",
			$file, 'update', @{ $args{argv} // [] }
		],
		cwd => $tree,
		env => \%env,
	);
	umask $old;
	die "cannot run $file: $r->{error}\n" if defined $r->{error};

	$r->{file} = $file;

	return $r;
}

# _unchanged($r, $name):
#	Assert that one failed update left the program as it was: the
#	bytes of bin/fugubench, and the mode that the copy carried.
sub _unchanged ( $r, $name )
{
	is( _slurp( $r->{file} ), _slurp($program),
		"$name leaves the running file unchanged" );
	is( _mode( $r->{file} ), 0600, "$name writes no new mode" );

	return;
}

# _entered(@argv):
#	Run the program in process, with the two sandbox calls and the
#	two streams replaced. The helper reports the exit code, the
#	promise sets of the run, the unveil entries, and the two
#	streams.
sub _entered (@argv)
{
	my ( @promises, @paths );
	my $out = q{};
	my $err = q{};
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
			push @paths, @{ $args{paths} };
			return 1;
		};

		open my $fh, '>', \$out or die "capture: $!";
		my $old = select $fh;
		{
			local *STDERR;
			open *STDERR, '>', \$err or die "capture: $!";
			$code = App::FuguBench->new->run(@argv);
			close *STDERR;
		}
		select $old;
		close $fh;
	}
	Fugu::Log->set_default($log);

	return {
		code     => $code,
		promises => \@promises,
		paths    => \@paths,
		out      => $out,
		err      => $err,
	};
}

subtest 'the fixture releases carry one signature of the fixture key' => sub {

	# Every line of each fixture manifest names a file of the tree,
	# so this case holds the whole fixture to the signature. A
	# fixture that an edit broke then reports here, and not inside
	# a case of the verb.
	for my $version (qw(v1.3.0 v1.1.0)) {
		my %files = map { $_ => "$fixture/$version/$_" }
		    grep { $_ ne 'SHA256' && $_ ne 'SHA256.sig' }
		    _entries("$fixture/$version");

		ok(
			defined $signify->verify_manifest(
				keys => ["$fixture/keys/fugubench-fixture.pub"],
				manifest  => "$fixture/$version/SHA256",
				signature => "$fixture/$version/SHA256.sig",
				files     => \%files
			),
			"the manifest of $version verifies, and each digest of"
			    . ' it matches'
		) or diag $signify->error;
	}

	# The fixture key signs the fixture releases alone. A release of
	# the organization must never verify with it (DIST-KEY-2).
	my %embedded = map { $_->[1] => 1 } App::FuguBench::Keys->keys;
	ok( !$embedded{$KEY}, 'the fixture key is no embedded release key' );
};

subtest 'the latest release replaces the running file' => sub {
	_release( 'good', 'releases/latest/download', 'v1.3.0' );

	my $r = _update('good');
	is( $r->{exit_code}, 0, 'update exits 0' ) or diag $r->{stderr};
	is( $r->{stdout}, "fugubench 1.3.0\n", 'and it prints the new version' );
	is(
		_slurp( $r->{file} ), _slurp("$fixture/v1.3.0/fugubench"),
		'and the running file holds the bytes of the release'
	);
	is( _mode( $r->{file} ), 0755, 'and it holds mode 755' );

	# The verb reads no checkout, so no walk reports one
	# (CLI-CHECKOUT-5).
	unlike( $r->{stderr}, qr/toolingrc/,
		'and it reports no configuration error' );

	# The signature check comes in front of the packed file, as
	# DIST-UPDATE-1 orders.
	is_deeply(
		[ _requests('good') ],
		[
			'/good/releases/latest/download/SHA256',
			'/good/releases/latest/download/SHA256.sig',
			'/good/releases/latest/download/fugubench',
		],
		'the verb asks for the manifest, the signature, and then the'
		    . ' packed file'
	);
};

subtest 'a final solidus of the address reaches no path' => sub {

	# An operator writes FUGUBENCH_RELEASE_URL by hand, and a final
	# solidus of that value must not double the separator of the
	# address.
	_release( 'slash', 'releases/latest/download', 'v1.3.0' );

	my $r = _update( 'slash', url => _base('slash') . q{/} );
	is( $r->{exit_code}, 0, 'the run exits 0' ) or diag $r->{stderr};
	is_deeply(
		[ _requests('slash') ],
		[
			'/slash/releases/latest/download/SHA256',
			'/slash/releases/latest/download/SHA256.sig',
			'/slash/releases/latest/download/fugubench',
		],
		'and every path holds one separator'
	);
};

subtest 'a signature of another release stops the update' => sub {

	# The manifest of v1.3.0 beside the signature of v1.1.0. The
	# embedded key signed both files, so only the pairing is wrong.
	_release(
		'mixed', 'releases/latest/download', 'v1.3.0',
		'SHA256.sig' => _slurp("$fixture/v1.1.0/SHA256.sig")
	);

	my $r = _update('mixed');
	is( $r->{exit_code}, 1,   'a bad signature exits 1' );
	is( $r->{stdout},    q{}, 'and it prints no version' );
	like(
		$r->{stderr}, qr/no embedded key verifies the signature/,
		'and the message names the failed signature'
	);

	# The install script reads no embedded key, so the failure
	# names it as the path out (DIST-KEY-3, DIST-INSTALL-3).
	like( $r->{stderr}, qr/\Qinstall the program again: $INSTALL\E/,
		'and it names the install command as the path out' );

	_unchanged( $r, 'a bad signature' );

	is_deeply(
		[ _requests('mixed') ],
		[
			'/mixed/releases/latest/download/SHA256',
			'/mixed/releases/latest/download/SHA256.sig',
		],
		'and the verb downloads no packed file'
	);
};

subtest 'a release of no embedded key stops the update' => sub {

	# The condition of DIST-KEY-3: a rotation left this program
	# without the key of the release. The embedded list holds one
	# key of another key number, and the fixture key signed the
	# release. So the pairing is right and the list is wrong.
	_release( 'rotated', 'releases/latest/download', 'v1.3.0' );

	my $r =
	    _update( 'rotated', lib => _lib( $STAMP, $OTHER, 'rotated' ) );
	is( $r->{exit_code}, 1,   'an absent key exits 1' );
	is( $r->{stdout},    q{}, 'and it prints no version' );
	like(
		$r->{stderr}, qr/no embedded key verifies the signature/,
		'and the message names the failed signature'
	);
	like( $r->{stderr}, qr/checked against wrong key/,
		'and it gives the reason of the embedded key' );
	like( $r->{stderr}, qr/\Qinstall the program again: $INSTALL\E/,
		'and it names the install command as the path out' );

	_unchanged( $r, 'an absent key' );

	is_deeply(
		[ _requests('rotated') ],
		[
			'/rotated/releases/latest/download/SHA256',
			'/rotated/releases/latest/download/SHA256.sig',
		],
		'and the verb downloads no packed file'
	);
};

subtest 'a packed file of other bytes stops the update' => sub {
	my $served = "the served bytes\n";
	_release(
		'bytes', 'releases/latest/download', 'v1.3.0',
		'fugubench' => $served
	);

	my ($want) =
	    _slurp("$fixture/v1.3.0/SHA256") =~ /[(]fugubench[)] = (\w+)/;
	my $got = _sha256($served);

	my $r = _update('bytes');
	is( $r->{exit_code}, 1,   'a digest mismatch exits 1' );
	is( $r->{stdout},    q{}, 'and it prints no version' );
	like( $r->{stderr}, qr/\Q$want\E/,
		'and the message holds the digest of the manifest' );
	like( $r->{stderr}, qr/\Q$got\E/,
		'and it holds the digest of the served bytes' );
	_unchanged( $r, 'a digest mismatch' );
};

subtest 'a release below the running version needs the flag' => sub {
	_release( 'down', 'releases/download/v1.1.0', 'v1.1.0' );

	my $r = _update( 'down', argv => [ '--version', 'v1.1.0' ] );
	is( $r->{exit_code}, 1,   'a downgrade exits 1' );
	is( $r->{stdout},    q{}, 'and it prints no version' );
	like( $r->{stderr}, qr/\b1[.]1[.]0\b/,
		'the message names the version of the release' );
	like( $r->{stderr}, qr/\b\Q$STAMP\E\b/,
		'and the running version' );
	like( $r->{stderr}, qr/--allow-downgrade/,
		'and the flag that takes it' );
	_unchanged( $r, 'a refused downgrade' );

	is_deeply(
		[ _requests('down') ],
		[
			'/down/releases/download/v1.1.0/SHA256',
			'/down/releases/download/v1.1.0/SHA256.sig',
		],
		'and the verb downloads no packed file'
	);
};

subtest 'the flag takes the release below the running version' => sub {
	_release( 'allow', 'releases/download/v1.1.0', 'v1.1.0' );

	my $r = _update( 'allow',
		argv => [ '--version', 'v1.1.0', '--allow-downgrade' ] );
	is( $r->{exit_code}, 0, 'the flag exits 0' ) or diag $r->{stderr};
	is( $r->{stdout}, "fugubench 1.1.0\n", 'and it prints the older version' );
	is(
		_slurp( $r->{file} ), _slurp("$fixture/v1.1.0/fugubench"),
		'and the running file holds the bytes of that release'
	);
	is( _mode( $r->{file} ), 0755, 'and it holds mode 755' );
};

subtest 'the comparison of the versions reads each field as a number' => sub {

	# The release 1.3.0 sits below the running 1.10.0, because the
	# second field is 3 and 10 (DIST-UPDATE-2). A comparison of the
	# two strings answers the other way. Every other case runs on
	# single-digit fields, so this case holds that rule alone.
	_release( 'ten', 'releases/latest/download', 'v1.3.0' );

	my $r = _update( 'ten', lib => _lib('1.10.0') );
	is( $r->{exit_code}, 1,   'a lower second field exits 1' );
	is( $r->{stdout},    q{}, 'and it prints no version' );
	like( $r->{stderr}, qr/\b1[.]3[.]0\b/,
		'the message names the version of the release' );
	like( $r->{stderr}, qr/\b1[.]10[.]0\b/, 'and the running version' );
	_unchanged( $r, 'a release of a lower second field' );
};

subtest 'a file of the shim cache is a refusal' => sub {
	my $home = "$tree/home-cache";
	my $file = "$home/.cache/fugubench/$STAMP/fugubench";
	_release( 'cache', 'releases/latest/download', 'v1.3.0' );

	my $r = _update( 'cache', home => $home, file => $file );
	is( $r->{exit_code}, 1,   'a file of the cache exits 1' );
	is( $r->{stdout},    q{}, 'and it prints no version' );
	like(
		$r->{stderr}, qr{[.]cache/fugubench/\Q$STAMP\E/fugubench},
		'the message names the file'
	);
	like( $r->{stderr}, qr{FuguBSD/Tooling},
		'and it names the org pack as the path to a new version' );
	_unchanged( $r, 'a file of the cache' );

	# The refusal comes before the first download (DIST-UPDATE-3).
	is_deeply( [ _requests('cache') ], [], 'and the verb asks no server' );
};

subtest 'an update without HOME is a refusal' => sub {

	# The shim cache sits under HOME, so the verb cannot find that
	# cache without the variable. It refuses then, and it replaces
	# no file of the cache by chance (DIST-UPDATE-3).
	_release( 'home', 'releases/latest/download', 'v1.3.0' );

	my %case = (
		'an unset HOME' => undef,
		'an empty HOME' => q{},
	);
	for my $name ( sort keys %case ) {
		my $r = _update( 'home', env => { HOME => $case{$name} } );
		is( $r->{exit_code}, 1,   "$name exits 1" );
		is( $r->{stdout},    q{}, "$name prints no version" );
		like( $r->{stderr}, qr/HOME is unset or empty/,
			"$name names the variable and both cases" );
		_unchanged( $r, $name );
	}

	# The refusal comes before the first download (DIST-UPDATE-3).
	is_deeply( [ _requests('home') ], [], 'and the verb asks no server' );
};

subtest 'a tag that names no release reports the tag' => sub {
	_release( 'tag', 'releases/latest/download', 'v1.3.0' );

	my $r = _update( 'tag', argv => [ '--version', 'v9.9.9' ] );
	is( $r->{exit_code}, 1,   'an absent tag exits 1' );
	is( $r->{stdout},    q{}, 'and it prints no version' );
	like(
		$r->{stderr}, qr/the release v9[.]9[.]9 answers no SHA256/,
		'the message names the tag and the file'
	);
	_unchanged( $r, 'an absent tag' );
};

subtest 'a tag of another shape is a usage error' => sub {

	# The tag reaches a download address, so it must name one path
	# segment of the shape of DIST-ASSETS-1.
	for my $bad ( '1.3.0', 'v1.3', 'latest/../../etc' ) {
		my $r = _update( 'shape', argv => [ '--version', $bad ] );
		is( $r->{exit_code}, 2, "the tag '$bad' exits 2" );
		is( $r->{stdout}, q{}, 'and it prints no version' );
		like( $r->{stderr}, qr/is no v<MAJOR>[.]<MINOR>[.]<PATCH>/,
			'and the message names the shape' );
		like( $r->{stderr}, qr/^usage: fugubench update /m,
			'and it prints the usage' );
		_unchanged( $r, "the tag '$bad'" );
	}

	is_deeply( [ _requests('shape') ], [], 'and no tag reaches the server' );
};

subtest 'an argument is a usage error' => sub {
	my $r = _update( 'argv', argv => ['extra'] );
	is( $r->{exit_code}, 2, 'an argument exits 2' );
	like( $r->{stderr}, qr/^usage: fugubench update /m,
		'and the message is the usage of the verb' );
	is_deeply( [ _requests('argv') ], [], 'and it asks no server' );
};

subtest 'every address takes the shape check of the downloader' => sub {

	# Fugu::Curl places the URL last and writes no '--' separator,
	# so an address that starts with a dash would reach the
	# downloader as an option (DEPS-FETCH-4). The address comes from
	# the environment, so the check reads the value that it built.
	my %case = (
		'an address that starts with a dash' => '-K/tmp/evilrc',
		'an address with no scheme'          => '127.0.0.1/release',
	);
	for my $name ( sort keys %case ) {
		my $r = _update( 'shape-url', url => $case{$name} );
		is( $r->{exit_code}, 1, "$name exits 1" );
		is( $r->{stdout}, q{}, "$name prints no version" );
		like(
			$r->{stderr},
			qr/the release address: the URL must start with a scheme/,
			"$name names its source and the rule"
		);
		like( $r->{stderr}, qr/\Q$case{$name}\E/, "$name names the URL" );
		_unchanged( $r, $name );
	}
};

subtest 'the sandbox row of update' => sub {

	# The row runs in front of the verb, and this call stops at the
	# shape of the tag, so the case reads the row and asks no
	# server.
	my $u = _entered( 'update', '--version', '1.3.0' );
	is( $u->{code}, 2, 'a tag of another shape exits 2' );
	is_deeply(
		$u->{promises},
		['stdio rpath wpath cpath fattr proc exec inet dns'],
		'the update row pledges the file, the child and the network'
		    . ' promises'
	);

	# A verb that runs a child unveils nothing, because unveil(2)
	# holds across an exec (CLI-SANDBOX-2).
	is_deeply( $u->{paths}, [], 'and the row unveils nothing' );

	is( $u->{out}, q{}, 'the verb writes no result line' );
	like( $u->{err}, qr/^usage: fugubench update /m,
		'and the usage reaches standard error' );
};

subtest 'the embedded install command is the published one' => sub {

	# The verb names the install command in a failed signature
	# check, and INSTALL.md publishes the same command
	# (DIST-INSTALL-3). This case holds the two equal, and it reads
	# the published text from the file. So no case of this file
	# carries a copy of the command.
	my $doc = "$repo/INSTALL.md";
	plan skip_all => 'the release tarball holds no INSTALL.md'
	    unless -f $doc;

	# The first fenced sh block of the document is the install
	# command, and it holds that one line.
	my ($published) = _slurp($doc) =~ m{^```sh\n(.*?)\n```$}ms;
	ok( defined $published, 'INSTALL.md holds a fenced sh block' )
	    or return;

	is( $published, $INSTALL,
		'the published command is the embedded command' );
};

done_testing();
