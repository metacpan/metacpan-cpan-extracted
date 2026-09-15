#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Rotate: every rule of WEB-ROTATE and of WEB-TRUST,
# against the real signify(1).
#
# The verbs write key material, so a fixture proves nothing here.
# The test generates each signify key with signify(1). It verifies
# each manifest and each signify binding with that command. The whole
# file therefore skips without signify(1), and the skip stands before
# the first assertion.
#
# The OpenPGP subtests of WEB-OPENPGP need gpg(1), and the import of
# an OpenPGP key needs it too. Each one reads its key, its expiry or
# its binding with that command. Three more subtests cover a key of
# the X.509 type, and openssl(1) makes the certificate of each one.
# Each of those subtests skips without its command, and that skip
# stands before the first assertion of the subtest.
#
# Each subtest builds its own site in a File::Temp directory, and it
# reads the repository at no point.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Digest::SHA ();
use File::Path  qw(make_path);
use File::Temp  qw(tempdir);
use Fugu::File;
use Fugu::KeyDir;
use Fugu::OpenPGP;
use Fugu::Process;
use Fugu::Signify;
use Fugu::X509;
use POSIX       ();
use Time::Local ();

# The command generates and signs, so no part of this file runs
# without it. Fugu::Signify verifies in Perl, so is_available answers
# 1 with no command and the probe reads the resolved path instead.
#
# The skip stands before every assertion. A plan that arrived after
# one turns a skip into "you planned 0 tests but ran 3", and the
# suite then fails on a host that has no signify(1).
plan skip_all => 'signify(1) is not installed'
    unless defined Fugu::Signify->new->command;

use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Keys');
use_ok('App::FuguWeb::Rotate');
use_ok('App::FuguWeb::CLI');

# A real OpenPGP public key, so a subtest can plant one whose
# declared fingerprint is wrong. gpg(1) exported it.
my $OPENPGP = <<'KEY';
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEap8KyxYJKwYBBAHaRw8BAQdA/6e7KzznAvEb2GEzYP1hlO69/FHDWy/cXJot
91Zpg+q0FHNlY3VyaXR5QGZ1Z3Vic2Qub3JniJMEExYKADsWIQSYOF9+PI20LwzG
2+jrLQSjr07OVQUCap8KywIbAwULCQgHAgIiAgYVCgkICwIEFgIDAQIeBwIXgAAK
CRDrLQSjr07OVYrkAP4nNPl6GHRSz1HlUlOc2ojAwvr8XDIifmAU1cc5W8xyogD+
LtLBaFuVI8Oc1PPnYVpof5lHHSJd9KR/4F/S7omdUAU=
=+npU
-----END PGP PUBLIC KEY BLOCK-----
KEY

# A real OpenPGP public key whose expiry has passed, so a subtest can
# read the check of WEB-OPENPGP-4 without a wait. gpg(1) made it with
# an expiry one second after the creation time, and it exported the
# public half. The expiry is a fixed moment in the key, so this date
# stays the answer.
my $EXPIRED = <<'KEY';
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEaqZ4fhYJKwYBBAHaRw8BAQdAa1GC/KfbfSf4DWb0ws3bcx65N9vF4synOLX0
ElfwNw60FTxleHBpcmVkQGZ1Z3Vic2Qub3JnPoi1BBMWCgBdFiEE7Xxss1703FM1
O8L8O6/C8EisWKsFAmqmeH4bFIAAAAAABAAObWFudTIsMi41KzEuMTIsMCwzAhsD
BQkAAAABBQsJCAcCAiICBhUKCQgLAgQWAgMBAh4HAheAAAoJEDuvwvBIrFirlfMA
/20kqMoeZmMMPd+ZORtU2rBw9cR0rEZtRKf5ZqvqXMiWAQCeblqcRCCGJmO84Em4
5ed80wKo1vwmhlCGFEXCP0FeCrg4BGqmeH8SCisGAQQBl1UBBQEBB0Dido8Q/Get
x7nSwhA2EoC8pLuc9RrO1g7hMRuJAVayEwMBCAeIlAQYFgoAPBYhBO18bLNe9NxT
NTvC/DuvwvBIrFirBQJqpnh/GxSAAAAAAAQADm1hbnUyLDIuNSsxLjEyLDAsMwIb
DAAKCRA7r8LwSKxYq6JHAP9nCrRTP2DAI96z0wAoEbf9V4BavEo3L0Zb875qf9/V
bQD+ME+65MWd8YSlDXnvrVXdd3UJrqxeiMVynmJWdbdSuQY=
=TuQT
-----END PGP PUBLIC KEY BLOCK-----
KEY

# The date on which the key above stopped being valid, in UTC.
my $EXPIRED_DATE = '2026-09-13';

my $ORG = 'fugubsd';
my $URL = 'https://www.fugubsd.org/keys';

# The address of every OpenPGP key that a mint of this file makes.
my $EMAIL = 'security@fugubsd.org';

# _site():
#	A project directory with the smallest description that loads,
#	and no keys block.
sub _site ()
{
	my $root = tempdir( CLEANUP => 1 );
	make_path("$root/web");
	Fugu::File->write( "$root/web/index.body.html", "<p>Hi</p>\n" );
	Fugu::File->write( "$root/.fuguwebrc", <<'RC' );
site = Example

nav "index.html" {
	label = Home
}

page "index.html" {
	title = Home
	body  = index.body.html
}
RC

	return $root;
}

# _rotate($root):
#	A rotation over the description of the project, with the
#	bootstrap words that a first mint needs.
#
#	WEB-ROTATE-22. The word states the intent of a step that makes
#	the key directory. A step of a directory that the description
#	names reads it as nothing, so every step of this file takes
#	it.
sub _rotate ($root)
{
	my $reason;
	my $config = App::FuguWeb::Config->load( root => $root,
		error => \$reason )
	    or die "load $root: $reason\n";

	return App::FuguWeb::Rotate->new(
		config    => $config,
		org       => $ORG,
		url       => $URL,
		bootstrap => 1,
	);
}

# _mint($root, %args), _import($root, %args), _promote($root, %args):
#	One step over a fresh rotation, so each step reads the
#	description that the step before it wrote. The purpose is
#	release, which is a subordinate purpose.
sub _mint ( $root, %args )
{
	my $rotate = _rotate($root);
	my $facts  = $rotate->mint( purpose => 'release', %args );

	return ( $facts, $rotate->error );
}

sub _import ( $root, %args )
{
	my $rotate = _rotate($root);
	my $facts  = $rotate->import_key( purpose => 'release', %args );

	return ( $facts, $rotate->error );
}

sub _promote ( $root, %args )
{
	my $rotate = _rotate($root);
	my $facts  = $rotate->promote( purpose => 'release', %args );

	return ( $facts, $rotate->error );
}

# _root($root, %args):
#	One step of the root purpose, which is the root of trust of
#	the directory.
sub _root ( $root, %args )
{
	my $rotate = _rotate($root);
	my $facts  = $rotate->mint( purpose => 'root', %args );

	return ( $facts, $rotate->error );
}

sub _promote_root ( $root, %args )
{
	my $rotate = _rotate($root);
	my $facts  = $rotate->promote( purpose => 'root', %args );

	return ( $facts, $rotate->error );
}

# _keyed():
#	A project whose key directory holds the current root key and
#	one current release key. The private half of each one sits
#	beside the project, as root1.sec and rel1.sec.
sub _keyed ()
{
	my $root = _site();

	my ( $first, $why ) = _root( $root, secret => "$root/root1.sec" );
	die "the first root mint failed: $why\n" unless $first;

	my ( $release, $reason ) = _mint(
		$root,
		secret => "$root/rel1.sec",
		signer => "$root/root1.sec"
	);
	die "the release mint failed: $reason\n" unless $release;

	return $root;
}

# _run(@argv):
#	Drive the real command in process, and answer the exit code
#	with what it wrote.
sub _run (@argv)
{
	my ( $out, $err ) = ( '', '' );

	open my $saved_out, '>&', \*STDOUT or die "Cannot save stdout: $!";
	open my $saved_err, '>&', \*STDERR or die "Cannot save stderr: $!";
	close STDOUT;
	close STDERR;
	open STDOUT, '>', \$out or die 'Cannot capture stdout';
	open STDERR, '>', \$err or die 'Cannot capture stderr';

	my $exit = eval { App::FuguWeb::CLI->run(@argv) };
	my $died = $@;

	close STDOUT;
	close STDERR;
	open STDOUT, '>&', $saved_out or die "Cannot restore stdout: $!";
	open STDERR, '>&', $saved_err or die "Cannot restore stderr: $!";

	die $died if $died;

	return ( $exit, $out, $err );
}

# _verifies($root, $stem):
#	True when the published key of the stem verifies the manifest
#	pair of the key directory.
sub _verifies ( $root, $stem )
{
	my $dir = "$root/web/keys";

	return Fugu::Signify->new->verify(
		keys      => ["$dir/$stem.pub"],
		file      => "$dir/SHA256",
		signature => "$dir/SHA256.sig",
	) ? 1 : 0;
}

# _binds($root, $target, $signer):
#	True when the binding of the target by the signer stands in
#	the key directory, and the published public key of the signer
#	verifies it.
sub _binds ( $root, $target, $signer )
{
	my $dir  = "$root/web/keys";
	my $name = "$target.pub.$signer.sig";

	return 0 unless -f "$dir/$name";

	return Fugu::Signify->new->verify(
		keys      => ["$dir/$signer.pub"],
		file      => "$dir/$target.pub",
		signature => "$dir/$name",
	) ? 1 : 0;
}

# _names($root):
#	Every name of the key directory, sorted.
sub _names ($root)
{
	return sort map { s{.*/}{}r } glob "$root/web/keys/*";
}

# _files($root):
#	Every key file and every binding file of the key directory,
#	sorted. The manifest pair names no key, so it stays out.
sub _files ($root)
{
	return grep { $_ ne 'SHA256' && $_ ne 'SHA256.sig' } _names($root);
}

# _manifest($root):
#	The names that the manifest holds, sorted.
sub _manifest ($root)
{
	my $bytes = Fugu::File->read("$root/web/keys/SHA256") // '';
	my $digest = Fugu::Signify->new->parse_manifest($bytes) // {};

	return sort keys %$digest;
}

# _problems($root):
#	What App::FuguWeb::Keys reports about each key directory of
#	the project, as fuguweb check reads them.
sub _problems ($root)
{
	my $reason;
	my $config = App::FuguWeb::Config->load( root => $root,
		error => \$reason )
	    or return ("load: $reason");

	return map {
		App::FuguWeb::Keys->new( config => $config, dir => $_ )
		    ->problems
	} $config->keys_dirs;
}

# _keys($root, $dir):
#	An App::FuguWeb::Keys over one key directory of the project,
#	so a subtest can drive one rule of the check alone.
sub _keys ( $root, $dir = 'keys' )
{
	my $reason;
	my $config = App::FuguWeb::Config->load( root => $root,
		error => \$reason )
	    or die "load $root: $reason\n";

	return App::FuguWeb::Keys->new( config => $config, dir => $dir );
}

# _block($root, $stem):
#	The settings of one key block of the description, by name. A
#	subtest reads what a step wrote, and the padding of the block
#	takes no part in the answer.
sub _block ( $root, $stem )
{
	my $bytes = Fugu::File->read("$root/.fuguwebrc") // '';
	my ($body) = $bytes =~ /\nkey "\Q$stem\E" \{\n(.*?)\n\}\n/s;

	my %setting;
	return %setting unless defined $body;

	for my $line ( split /\n/, $body ) {
		next unless $line =~ /\A\s*(\S+)\s*=\s*(.*?)\s*\z/;
		$setting{$1} = $2;
	}

	return %setting;
}

# _gpg_fields($path):
#	Every colon line of an OpenPGP public key file, as gpg(1)
#	shows it, by record name. The value is the field list of the
#	line, so a subtest reads the expiry, the capabilities and the
#	curve of the key and of its subkey.
#
#	The read is independent of the code under test: it runs the
#	command itself, and it imports nothing. The home dies with the
#	call, so the read touches no home of the user.
sub _gpg_fields ($path)
{
	my $home = tempdir( CLEANUP => 1 );
	chmod 0700, $home;

	my $result = Fugu::Process->run(
		cmd => [
			Fugu::OpenPGP->new->command,
			'--batch',
			'--quiet',
			'--homedir',
			$home,
			'--with-colons',
			'--import-options',
			'show-only',
			'--import',
			'--',
			$path
		],
		timeout => 60,
		env     => {
			PATH      => $ENV{PATH} // '',
			HOME      => $home,
			GNUPGHOME => $home,
			LC_ALL    => 'C',
		},
	);

	my %record;
	return %record unless $result->{success};

	for my $line ( split /\n/, $result->{stdout} // '' ) {
		my @field = split /:/, $line, -1;
		$record{ $field[0] } //= \@field;
	}

	return %record;
}

# _utc_day($days):
#	The date of a moment so many days from now, as YYYY-MM-DD in
#	UTC, and the epoch of the start of that date.
sub _utc_day ($days)
{
	my @when = gmtime( time + $days * 24 * 60 * 60 );
	my $date = POSIX::strftime( '%Y-%m-%d', @when );
	my $epoch =
	    Time::Local::timegm_modern( 0, 0, 0, $when[3], $when[4],
		$when[5] + 1900 );

	return ( $date, $epoch );
}

subtest 'the first root mint bootstraps and signs its own manifest' => sub {
	my $root = _site();
	my ( $facts, $error ) = _root( $root, secret => "$root/root1.sec" );

	ok( $facts, 'the mint succeeds' ) or diag($error);
	return unless $facts;

	is( $facts->{name},   'fugubsd-1-root.pub', 'the name of the key' );
	is( $facts->{serial}, 1,                    'the serial starts at 1' );

	# WEB-ROTATE-3. The purpose held no current key.
	is( $facts->{status}, 'current', 'the first key is current at once' );

	# WEB-ROTATE-13. A caller declares the key with the digest and
	# the URL, so it reads neither from the tree.
	is(
		$facts->{digest},
		lc Digest::SHA::sha256_hex(
			Fugu::File->read("$root/web/keys/fugubsd-1-root.pub")
		),
		'the digest of the new key file'
	);
	is( $facts->{url}, "$URL/fugubsd-1-root.pub", 'and its published URL' );

	# WEB-ROTATE-15. The keys block and the first key block
	# arrive together, and the block carries the published prefix.
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	like( $rc, qr/^keys "keys" \{$/m, 'the description takes a keys block' );
	like( $rc, qr/^\torg = \Q$ORG\E$/m, 'with the organization word' );

	# A site can hold a second key directory, so the comment above
	# the block names the organization word of this one.
	like(
		$rc,
		qr/^\# The published keys of \Q$ORG\E\. The rotation$/m,
		'and a comment that names that word'
	);
	like( $rc, qr/^\turl = \Q$URL\E$/m, 'and the published prefix' );
	like(
		$rc,
		qr/^key "fugubsd-1-root" \{\n\tstatus = current$/m,
		'and the block of the first key'
	);

	# WEB-ROTATE-6. The one exception: this key signs for itself.
	ok( _verifies( $root, 'fugubsd-1-root' ),
		'the published root verifies the manifest' );

	# WEB-ROTATE-2. The private half takes no group mode and no
	# other mode.
	my $mode = ( stat "$root/root1.sec" )[2] & 07777;
	is( sprintf( '%04o', $mode ), '0600', 'the private half is owner only' );

	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'the manifest records the digest of the key file' => sub {
	my $root = _site();
	my ($facts) = _root( $root, secret => "$root/root1.sec" );
	ok( $facts, 'the mint succeeds' ) or return;

	# WEB-KEYS-21. The consumer install reads this digest, and a
	# manifest that named the wrong bytes would fail it.
	my $bytes = Fugu::File->read("$root/web/keys/fugubsd-1-root.pub");
	my $want  = Digest::SHA::sha256_hex($bytes);

	my $manifest = Fugu::File->read("$root/web/keys/SHA256");
	is( $manifest, "SHA256 (fugubsd-1-root.pub) = $want\n",
		'one line, with the digest of the file' );
};

subtest 'a step of a subordinate purpose needs the root' => sub {
	my $root = _site();

	# WEB-ROTATE-19 and WEB-TRUST-1. The current root signs the
	# manifest of the whole directory, so a directory with no root
	# takes no other key.
	my ( $facts, $error ) = _mint( $root, secret => "$root/rel1.sec" );
	ok( !$facts, 'a mint before the first root mint fails' );
	like( $error, qr/holds no current key of the purpose root/,
		'and the reason names the purpose' );
	ok( !-e "$root/rel1.sec", 'and it generates no pair' );
};

subtest 'a subordinate mint takes the root as the signer' => sub {
	my $root = _site();
	my ($first) = _root( $root, secret => "$root/root1.sec" );
	ok( $first, 'the first root mint succeeds' ) or return;

	# WEB-TRUST-2. The current root signs SHA256, and no other
	# key signs it.
	my ( $facts, $error ) = _mint( $root, secret => "$root/rel1.sec" );
	ok( !$facts, 'a mint with no signer fails' );
	like( $error, qr/needs the private half of that key as the signer/,
		'and the reason names the signer' );

	( $facts, $error ) = _mint(
		$root,
		secret => "$root/rel1.sec",
		signer => "$root/root1.sec"
	);
	ok( $facts, 'the mint succeeds with the root as the signer' )
	    or diag($error);
	return unless $facts;

	is( $facts->{status}, 'current',
		'the first key of the purpose is current at once' );
	ok( _verifies( $root, 'fugubsd-1-root' ),
		'and the root still verifies the manifest' );
	ok( !_verifies( $root, 'fugubsd-1-release' ),
		'and the new key verifies nothing' );

	# WEB-TRUST-3 and WEB-TRUST-8. The new key attests the current
	# root, and the step verified that binding before it landed.
	ok( _binds( $root, 'fugubsd-1-root', 'fugubsd-1-release' ),
		'the new key binds to the root' );

	# WEB-TRUST-6. The manifest names every key file and every
	# binding file, and nothing else.
	is_deeply(
		[ _manifest($root) ],
		[
			'fugubsd-1-release.pub',
			'fugubsd-1-root.pub',
			'fugubsd-1-root.pub.fugubsd-1-release.sig'
		],
		'and the manifest names the binding beside the two keys'
	);

	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'the first root mint refuses a signer' => sub {
	my $root = _site();

	# WEB-ROTATE-6. No root stands, so no key can sign for the
	# new one, and a signer here names a key of another directory.
	my ( $facts, $error ) = _root(
		$root,
		secret => "$root/root1.sec",
		signer => "$root/other.sec"
	);
	ok( !$facts, 'the mint fails' );
	like( $error, qr/takes no signer/, 'and the reason says why' );
	ok( !-e "$root/root1.sec", 'and it generates no pair' );
};

subtest 'the first root mint binds each key in force' => sub {
	my $root = _site();

	# A directory whose keys hold no root is the state of a site
	# that published a key before this release. WEB-TRUST-1 makes
	# the first root mint take such a directory, and WEB-TRUST-7
	# makes it bind each key of it.
	my ($first) = _root( $root, secret => "$root/root1.sec" );
	ok( $first, 'the first root mint succeeds' ) or return;
	my ($release) = _mint(
		$root,
		secret => "$root/rel1.sec",
		signer => "$root/root1.sec"
	);
	ok( $release, 'the release mint succeeds' ) or return;

	# The root goes, and the directory then holds one key that no
	# root attests.
	unlink "$root/web/keys/fugubsd-1-root.pub";
	unlink "$root/web/keys/fugubsd-1-root.pub.fugubsd-1-release.sig";
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	$rc =~ s/\nkey "fugubsd-1-root" \{[^}]*\}\n//
	    or die 'the fixture drops no root block';
	Fugu::File->write( "$root/.fuguwebrc", $rc );

	# WEB-TRUST-7. The step refuses before it writes when the
	# private half of one key in force is absent.
	my ( $facts, $error ) = _root( $root, secret => "$root/root2.sec" );
	ok( !$facts, 'a mint with no bound key fails' );
	like( $error, qr/needs the private half of that key as the bound key/,
		'and the reason names the key' );
	ok( !-e "$root/root2.sec", 'and it generates no pair' );

	( $facts, $error ) = _root(
		$root,
		secret => "$root/root2.sec",
		bind   => { 'fugubsd-1-release' => "$root/rel1.sec" }
	);
	ok( $facts, 'the mint succeeds with the bound key' ) or diag($error);
	return unless $facts;

	# The directory holds no root file, so the serial of the root
	# purpose starts at 1 again.
	is( $facts->{name}, 'fugubsd-1-root.pub', 'the name of the new root' );
	ok( _binds( $root, 'fugubsd-1-root', 'fugubsd-1-release' ),
		'the key in force binds to the new root' );
	ok( _verifies( $root, 'fugubsd-1-root' ),
		'and the new root signs its own manifest' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

# WEB-TRUST-8. The type of the signer key selects the signer, so an
# OpenPGP key of the directory signs its binding with gpg(1). A
# directory that published such a key stands before this release, and
# the first root mint must bind it.
subtest 'a root step binds an OpenPGP key with the signer of its type' => sub {
	my $pgp = Fugu::OpenPGP->new;
	plan skip_all => 'gpg(1) is not installed' unless $pgp->is_available;

	my $root = _site();
	my ($first) = _root( $root, secret => "$root/root1.sec" );
	ok( $first, 'the first root mint succeeds' ) or return;

	# The verbs mint no OpenPGP key in this plan, so the fixture
	# writes the key file and its block itself.
	my $dir = "$root/web/keys";
	$pgp->generate(
		email  => 'security@fugubsd.org',
		public => "$dir/fugubsd-1-contact.asc",
		secret => "$root/contact1.sec",
	) or die 'the OpenPGP key fixture failed: ' . $pgp->error . "\n";

	# The root goes, so the directory holds one key of another
	# type that no root attests, per WEB-TRUST-1.
	unlink "$dir/fugubsd-1-root.pub";
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	$rc =~ s/\nkey "fugubsd-1-root" \{[^}]*\}\n//
	    or die 'the fixture drops no root block';
	Fugu::File->write( "$root/.fuguwebrc",
		$rc . qq{\nkey "fugubsd-1-contact" {\n\tstatus = current\n}\n} );

	my ( $facts, $error ) = _root(
		$root,
		secret => "$root/root2.sec",
		bind   => { 'fugubsd-1-contact' => "$root/contact1.sec" }
	);
	ok( $facts, 'the mint succeeds with the OpenPGP bound key' )
	    or diag($error);
	return unless $facts;

	# The binding takes the extension of the signer type, and the
	# signature under it must be one that gpg(1) made.
	my $name = 'fugubsd-1-root.pub.fugubsd-1-contact.asc';
	ok( -f "$dir/$name", 'the step writes the binding of the OpenPGP key' );
	ok(
		$pgp->verify(
			keys      => ["$dir/fugubsd-1-contact.asc"],
			file      => "$dir/fugubsd-1-root.pub",
			signature => "$dir/$name"
		),
		'and the published OpenPGP key verifies it'
	);
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

# WEB-OPENPGP-1, WEB-OPENPGP-2, WEB-OPENPGP-3 and WEB-OPENPGP-5. The
# mint generates the key with gpg(1), publishes the armored public
# half, writes the address and the fingerprint into the key block, and
# binds the new key to the current root.
subtest 'the OpenPGP mint writes the key, its block and its binding' => sub {
	my $pgp = Fugu::OpenPGP->new;
	plan skip_all => 'gpg(1) is not installed' unless $pgp->is_available;

	my $root = _site();
	my ($first) = _root( $root, secret => "$root/root1.sec" );
	ok( $first, 'the first root mint succeeds' ) or return;

	my ( $date, $epoch ) = _utc_day(400);

	my $rotate = _rotate($root);
	my $facts  = $rotate->mint(
		purpose => 'contact',
		type    => 'openpgp',
		email   => $EMAIL,
		expires => $date,
		secret  => "$root/contact1.sec",
		signer  => "$root/root1.sec",
	);
	ok( $facts, 'the OpenPGP mint succeeds' ) or diag( $rotate->error );
	return unless $facts;

	my $dir  = "$root/web/keys";
	my $name = 'fugubsd-1-contact.asc';
	is( $facts->{name}, $name, 'the key file takes the OpenPGP extension' );
	is( $facts->{status}, 'current',
		'and the first key of a purpose is current' );

	# WEB-ROTATE-2. The public half goes into the key directory,
	# and the private half goes to the named path with no group
	# mode and no other mode.
	like( Fugu::File->read("$dir/$name"),
		qr/\A-----BEGIN PGP PUBLIC KEY BLOCK-----\n/,
		'the published half is armored text' );
	ok( -f "$root/contact1.sec",
		'the private half lands at the secret path' );
	is( ( stat "$root/contact1.sec" )[2] & 07777,
		0600, 'and it takes no group mode and no other mode' );

	# WEB-OPENPGP-1. One Ed25519 primary key, one Curve25519
	# encryption subkey, and the address as the one user id.
	my %field = _gpg_fields("$dir/$name");
	is( $field{pub}[16], 'ed25519', 'the primary key is Ed25519' );
	is( $field{sub}[16], 'cv25519', 'and the subkey is Curve25519' );
	like( $field{sub}[11], qr/e/, 'and the subkey encrypts' );
	is( $field{uid}[9], "<$EMAIL>",
		'and the user id holds the address alone' );

	# WEB-OPENPGP-3. The key expires at the start of the named
	# date, in UTC.
	is( $field{pub}[6], $epoch,
		'the key expires at the start of the named date' );

	# WEB-OPENPGP-2. The block names the address, and the
	# fingerprint that the generated key gives.
	my $binary = $pgp->decode_armor( Fugu::File->read("$dir/$name") );
	my %setting = _block( $root, 'fugubsd-1-contact' );
	is( $setting{email}, $EMAIL, 'the key block names the address' );
	is( $setting{fingerprint},
		$pgp->fingerprint($binary),
		'and the fingerprint that the key itself gives' );

	# WEB-ROTATE-16. A mint records the date of the run as since,
	# whatever the type of the key.
	is( $setting{since}, POSIX::strftime( '%Y-%m-%d', gmtime ),
		'and the date of the run' );

	# WEB-TRUST-3 and WEB-OPENPGP-5. The new key binds to the
	# current root, and that binding is an armored detached
	# signature which the published key verifies.
	my $binding = 'fugubsd-1-root.pub.fugubsd-1-contact.asc';
	ok( -f "$dir/$binding", 'the mint writes the binding over the root' );
	like( Fugu::File->read("$dir/$binding"),
		qr/\A-----BEGIN PGP SIGNATURE-----\n/,
		'and it is an armored detached signature' );
	ok(
		$pgp->verify(
			keys      => ["$dir/$name"],
			file      => "$dir/fugubsd-1-root.pub",
			signature => "$dir/$binding"
		),
		'and the published key verifies it'
	);

	ok( _verifies( $root, 'fugubsd-1-root' ),
		'the current root still signs the manifest' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

# WEB-OPENPGP-3. A mint with no date makes a key with no expiry. The
# key directory retires a key with an until date, and the machine
# rotates.
subtest 'an OpenPGP mint with no date makes a key with no expiry' => sub {
	my $pgp = Fugu::OpenPGP->new;
	plan skip_all => 'gpg(1) is not installed' unless $pgp->is_available;

	my $root = _site();
	my ($first) = _root( $root, secret => "$root/root1.sec" );
	ok( $first, 'the first root mint succeeds' ) or return;

	my $rotate = _rotate($root);
	my $facts  = $rotate->mint(
		purpose => 'contact',
		type    => 'openpgp',
		email   => $EMAIL,
		secret  => "$root/contact1.sec",
		signer  => "$root/root1.sec",
	);
	ok( $facts, 'the mint succeeds with no expiry date' )
	    or diag( $rotate->error );
	return unless $facts;

	my $key = "$root/web/keys/fugubsd-1-contact.asc";
	my %field = _gpg_fields($key);
	is( $field{pub}[6], '', 'the key holds no expiry' );
	is( $field{sub}[6], '', 'and the subkey holds none' );
	is( $pgp->expiry( public => $key ),
		0, 'and the library reads no expiry' );

	is_deeply( [ _problems($root) ], [],
		'and the check reports no expiry problem' );
};

# WEB-OPENPGP-1 and WEB-OPENPGP-3. The address becomes the one user id
# of the key, so an OpenPGP mint needs it. A key of another type
# carries no address and no expiry of its own, and App::FuguWeb::Config
# refuses a key block that names an email on such a key.
#
# Every step here fails before it generates, so the subtest needs no
# gpg(1).
subtest 'a mint guards the options of its key type' => sub {
	my $root   = _keyed();
	my @before = _names($root);

	my ( $facts, $error ) = _mint(
		$root,
		type   => 'openpgp',
		secret => "$root/contact1.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'an OpenPGP mint with no email fails' );
	like( $error, qr/so it needs the email$/,
		'and the reason names the option' );

	# WEB-OPENPGP-3. _epoch_of holds every field to its range
	# itself, and _days_in gives the length of the month with the
	# leap rule of the Gregorian calendar. 2027 is a common year,
	# 2100 is a century that the rule leaves common, and April
	# holds 30 days. A step that let one of these through would
	# reach Time::Local, which dies, so each one must give a
	# reason instead.
	my @bad = qw(
	    2028-1-1 2028-02-30 2028-13-01 2027-02-29 2100-02-29
	    2028-04-31 tomorrow
	);
	for my $bad (@bad) {
		( $facts, $error ) = ( undef, undef );
		my $lived = eval {
			( $facts, $error ) = _mint(
				$root,
				type    => 'openpgp',
				email   => $EMAIL,
				expires => $bad,
				secret  => "$root/contact1.sec",
				signer  => "$root/root1.sec"
			);
			1;
		};

		# $@ is global, and each statement after the eval can
		# clear it. The reason is read here, so the
		# diagnostic holds the croak of the date.
		my $died = $@;
		ok( $lived, "the expiry date $bad gives a reason and no die" )
		    or diag($died);
		ok( !$facts, "the expiry date $bad fails" );
		like(
			$error,
			qr/^the expiry \Q$bad\E is no date of the form YYYY-MM-DD$/,
			'and the reason names the form'
		);
	}

	# WEB-OPENPGP-3. February holds 29 days in a leap year, so
	# each of these dates passes the guard. The four year rule
	# makes 2060 a leap year, and the 400 year clause makes 2400
	# one. The step then fails on the secret path, which stands
	# already, and it generates nothing.
	for my $leap (qw(2060-02-29 2400-02-29)) {
		( $facts, $error ) = _mint(
			$root,
			type    => 'openpgp',
			email   => $EMAIL,
			expires => $leap,
			secret  => "$root/rel1.sec",
			signer  => "$root/root1.sec"
		);
		ok( !$facts, "the leap day $leap passes the date guard" );
		like(
			$error,
			qr/^\Q$root\E\/rel1[.]sec stands already, and a mint writes/,
			'and the step fails on the secret path instead'
		);
	}

	# WEB-OPENPGP-3. A key that expired already signs nothing, so
	# the step refuses the day of the run and each earlier date.
	# The reason names the date that the caller gave, and never
	# the epoch that Fugu::OpenPGP would name.
	for my $days ( 0, -1, -400 ) {
		my ($past) = _utc_day($days);
		( $facts, $error ) = _mint(
			$root,
			type    => 'openpgp',
			email   => $EMAIL,
			expires => $past,
			secret  => "$root/contact1.sec",
			signer  => "$root/root1.sec"
		);
		ok( !$facts, "the expiry date $past fails" );
		like(
			$error,
			qr/^the expiry \Q$past\E is not after the day of the run$/,
			'and the reason names the date of the caller'
		);
	}

	# WEB-OPENPGP-3. The day after the run is the nearest date
	# that the guard accepts. The test reads the clock, and the
	# guard reads it again, so the case runs once more when the
	# UTC day moves between the two reads.
	my ( $day, $tomorrow );
	do {
		($day)      = _utc_day(0);
		($tomorrow) = _utc_day(1);
		( $facts, $error ) = _mint(
			$root,
			type    => 'openpgp',
			email   => $EMAIL,
			expires => $tomorrow,
			secret  => "$root/rel1.sec",
			signer  => "$root/root1.sec"
		);
	} while ( ( _utc_day(0) )[0] ne $day );

	ok( !$facts, "the expiry date $tomorrow passes the date guard" );
	like(
		$error,
		qr/^\Q$root\E\/rel1[.]sec stands already, and a mint writes/,
		'and the step fails on the secret path instead'
	);

	# WEB-TRUST-1. The root of trust is a signify key, and no
	# later read of a step holds a root to that type. This key
	# would take the status next, and the check reads the current
	# root alone, so the step would publish an OpenPGP root.
	( $facts, $error ) = _root(
		$root,
		type   => 'openpgp',
		email  => $EMAIL,
		secret => "$root/root2.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'an OpenPGP mint of the root purpose fails' );
	like(
		$error,
		qr/^the root of trust is a signify key, so a mint of the root purpose takes no openpgp key$/,
		'and the reason names the purpose and the type'
	);

	# The first root mint finds no root, and it signs its own
	# manifest with the key that it makes. Fugu::Signify reads no
	# OpenPGP secret half, so that step fails in the signer. The
	# guard refuses it first, and with the reason of the rule.
	my $bare = _site();
	( $facts, $error ) = _root(
		$bare,
		type   => 'openpgp',
		email  => $EMAIL,
		secret => "$bare/root1.sec"
	);
	ok( !$facts, 'the first root mint of the OpenPGP type fails too' );
	like(
		$error,
		qr/^the root of trust is a signify key, so a mint of the root purpose takes no openpgp key$/,
		'and it gives the reason of the rule'
	);
	ok( !-e "$bare/web/keys", 'and it makes no key directory' );
	ok( !-e "$bare/root1.sec", 'and it writes no private half' );

	( $facts, $error ) = _mint(
		$root,
		email  => $EMAIL,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'a signify mint with an email fails' );
	like( $error, qr/^a mint of a signify key takes no email$/,
		'and the reason names the type and the option' );

	( $facts, $error ) = _mint(
		$root,
		expires => '2028-01-01',
		secret  => "$root/rel2.sec",
		signer  => "$root/root1.sec"
	);
	ok( !$facts, 'a signify mint with an expiry date fails' );
	like( $error, qr/^a mint of a signify key takes no expires$/,
		'and the reason names that option' );

	is_deeply( [ _names($root) ], [@before],
		'and no step writes one file' );
	ok( !-e "$root/contact1.sec", 'and none of them makes an OpenPGP key' );
	ok( !-e "$root/root2.sec",    'and none of them makes an OpenPGP root' );
	ok( !-e "$root/rel2.sec",     'and none of them makes a signify pair' );
};

# WEB-OPENPGP-4. The check reports a current OpenPGP key that expires
# within 30 days, when its purpose holds no next key. One rotation
# runs in two steps, and the consumers need the gap between them.
subtest 'the check reports a current OpenPGP key that expires soon' => sub {
	plan skip_all => 'gpg(1) is not installed'
	    unless Fugu::OpenPGP->new->is_available;

	my $root = _site();
	my ($first) = _root( $root, secret => "$root/root1.sec" );
	ok( $first, 'the first root mint succeeds' ) or return;

	# The bar is 30 days, and this date stands inside it at every
	# hour. The start of the day 30 days out is never later than
	# 30 days from now, and a UTC midnight between the mint and
	# the check brings it nearer.
	my ($soon)  = _utc_day(30);
	my $rotate  = _rotate($root);
	my $current = $rotate->mint(
		purpose => 'contact',
		type    => 'openpgp',
		email   => $EMAIL,
		expires => $soon,
		secret  => "$root/contact1.sec",
		signer  => "$root/root1.sec",
	);
	ok( $current, 'the mint of the current key succeeds' )
	    or diag( $rotate->error );
	return unless $current;

	my @problems = _problems($root);
	is( scalar @problems, 1, 'the check reports one problem' );
	like(
		$problems[0],
		qr{^keys/fugubsd-1-contact[.]asc: the current key expires on \Q$soon\E, and the purpose contact holds no next key$},
		'and it names the file, the date and the purpose'
	);

	# The other side of the bar. This key is current, its purpose
	# holds no next key, and it stands outside the bar, so it adds
	# no problem. The mint reads the clock, and the check reads it
	# again: a run that crosses UTC midnight between the two
	# brings the key one day nearer. The start of the day 32 days
	# out therefore stands more than 30 days from the check at
	# every hour, and the answer never depends on the hour.
	my ($edge) = _utc_day(32);
	$rotate = _rotate($root);
	my $outside = $rotate->mint(
		purpose => 'notify',
		type    => 'openpgp',
		email   => $EMAIL,
		expires => $edge,
		secret  => "$root/notify1.sec",
		signer  => "$root/root1.sec",
	);
	ok( $outside, 'the mint of a key outside the bar succeeds' )
	    or diag( $rotate->error );
	return unless $outside;

	@problems = _problems($root);
	is( scalar @problems, 1, 'the check reports the same one problem' );
	like(
		$problems[0],
		qr{^keys/fugubsd-1-contact[.]asc: },
		'and a key outside the bar adds none'
	);

	# A step reads its own work back, and it must not fail for
	# this report. The mint of the successor clears the report by
	# itself, because the purpose then holds a next key. This step
	# names another purpose, so it writes no such key, and it
	# would fail for a report that it cannot answer.
	$rotate = _rotate($root);
	my $release = $rotate->mint(
		purpose => 'release',
		secret  => "$root/rel1.sec",
		signer  => "$root/root1.sec",
	);
	ok( $release, 'a step of another purpose succeeds all the same' )
	    or diag( $rotate->error );
	is( scalar( () = _problems($root) ),
		1, 'and the check still reports the one problem' );

	# The next key of the purpose carries the gap of the rotation,
	# so the current key that expires soon is no problem.
	my ($far) = _utc_day(400);
	$rotate = _rotate($root);
	my $next = $rotate->mint(
		purpose => 'contact',
		type    => 'openpgp',
		email   => $EMAIL,
		expires => $far,
		secret  => "$root/contact2.sec",
		signer  => "$root/root1.sec",
	);
	ok( $next, 'the mint of the next key succeeds' )
	    or diag( $rotate->error );
	return unless $next;

	is_deeply( [ _problems($root) ], [],
		'and a next key of the purpose takes the problem away' );
};

# WEB-OPENPGP-4. A current OpenPGP key whose expiry has passed is a
# problem of App::FuguWeb::Keys->problems, which is the path of
# fuguweb check. A step of the rotation must not fail for it: the
# expired key is still current when the step reads its work back, so a
# step that failed for the report could never mint the successor that
# the promote needs.
#
# gpg(1) refuses to sign with an expired key, so no step can build
# such a directory. The subtest mints a key that expires far away, and
# it moves the reader of the clock instead. Fugu::OpenPGP::expiry
# answers the epoch that the key carries, and this one answers a past
# epoch for that one file. Every other read of the run is the real
# one, and the local restores the real reader at the end.
subtest 'a step succeeds over an expired current OpenPGP key' => sub {
	plan skip_all => 'gpg(1) is not installed'
	    unless Fugu::OpenPGP->new->is_available;

	my $root = _site();
	my ($first) = _root( $root, secret => "$root/root1.sec" );
	ok( $first, 'the first root mint succeeds' ) or return;

	my ($far)  = _utc_day(400);
	my $rotate = _rotate($root);
	my $facts  = $rotate->mint(
		purpose => 'contact',
		type    => 'openpgp',
		email   => $EMAIL,
		expires => $far,
		secret  => "$root/contact1.sec",
		signer  => "$root/root1.sec",
	);
	ok( $facts, 'the mint of the current key succeeds' )
	    or diag( $rotate->error );
	return unless $facts;

	is_deeply( [ _problems($root) ], [],
		'the check reports no problem while the key stands' );

	my $name = 'fugubsd-1-contact.asc';
	my $gone = time - 24 * 60 * 60;
	my $date = POSIX::strftime( '%Y-%m-%d', gmtime $gone );
	my $real = \&Fugu::OpenPGP::expiry;
	local *Fugu::OpenPGP::expiry = sub ( $self, %args ) {
		return $gone
		    if ( $args{public} // '' ) =~ m{/\Q$name\E\z};

		return $self->$real(%args);
	};

	my @problems = _problems($root);
	is( scalar @problems, 1, 'the whole check reports one problem' );
	like(
		$problems[0],
		qr{^keys/\Q$name\E: the current key expired on \Q$date\E$},
		'and it names the file, the status and the date'
	);

	# The deadlock that expiry => 0 answers. A promote needs a
	# next key, and this mint writes it. The expired key is still
	# current when the mint reads its work back, so a step that
	# failed for the report could never make that key.
	$rotate = _rotate($root);
	my $next = $rotate->mint(
		purpose => 'contact',
		type    => 'openpgp',
		email   => $EMAIL,
		expires => $far,
		secret  => "$root/contact2.sec",
		signer  => "$root/root1.sec",
	);
	ok( $next, 'the mint of the successor succeeds all the same' )
	    or diag( $rotate->error );
	return unless $next;

	is( $next->{status}, 'next', 'and the successor takes that status' );
	is( scalar( () = _problems($root) ),
		1, 'and the check still reports the expired key' );
};

# WEB-OPENPGP-4. The rule reads the status of the key: a current key
# and a next key are each a problem, and a retired key is none. gpg(1)
# refuses to sign with an expired key, so no step can mint one. The
# subtest plants the fixture key and drives that one rule over a set
# which names it. It reads no whole report, so the planted file stands
# beside the directory of _keyed and takes no part in the answer.
subtest 'the check reports an OpenPGP key whose expiry has passed' => sub {
	plan skip_all => 'gpg(1) is not installed'
	    unless Fugu::OpenPGP->new->is_available;

	my $root = _keyed();
	Fugu::File->write( "$root/web/keys/fugubsd-1-contact.asc", $EXPIRED );

	my $keys = _keys($root);

	for my $status (qw(current next)) {
		my @problems = $keys->_expiry_problems(
			[ {
				name    => 'fugubsd-1-contact.asc',
				type    => 'openpgp',
				purpose => 'contact',
				status  => $status,
			} ] );

		is( scalar @problems, 1, "the check reports the $status key" );
		like(
			$problems[0],
			qr{^keys/fugubsd-1-contact[.]asc: the $status key expired on \Q$EXPIRED_DATE\E$},
			'and it names the file, the status and the date'
		);
	}

	# A retired key stays published with an until date, and a
	# release that it signed still verifies, so its expiry is no
	# problem.
	is_deeply(
		[
			$keys->_expiry_problems(
				[ {
					name    => 'fugubsd-1-contact.asc',
					type    => 'openpgp',
					purpose => 'contact',
					status  => 'retired',
				} ] ) ],
		[],
		'and a retired key of the same file is no problem'
	);
};

# WEB-TRUST-8. A PEM private key names no certificate, so Fugu::X509
# signs with the certificate beside it, and _bind must name that file.
# _bound reads the status of a key and never its type, so a directory
# that published a certificate reaches this path.
#
# The subtest drives _bind alone. The checks of a certificate are
# absent, per the WEB-X509 row of spec/STATUS.md, so the reader of a
# whole step rejects a .pem key before it reads the binding.
subtest 'a certificate signs its binding with openssl(1)' => sub {
	my $x509 = Fugu::X509->new;
	plan skip_all => 'openssl(1) is not installed'
	    unless $x509->is_available;

	my $root = _keyed();
	$x509->generate(
		subject => '/CN=Example Signer',
		days    => 30,
		public  => "$root/contact1.pem",
		secret  => "$root/contact1.sec",
	) or die 'the certificate fixture failed: ' . $x509->error . "\n";

	my $target = "$root/web/keys/fugubsd-1-root.pub";
	my $bytes  = Fugu::File->read($target);

	# Fugu::X509::sign dies for a call that names no certificate.
	# The eval holds that die, so a _bind which drops the public
	# argument fails one assertion here, and the file runs on.
	my $rotate = _rotate($root);
	my ( $name, $signature ) = eval {
		$rotate->_bind(
			'fugubsd-1-root.pub',
			$bytes,
			'fugubsd-1-contact.pem',
			Fugu::File->read("$root/contact1.pem"),
			Fugu::File->read("$root/contact1.sec")
		);
	};
	my $why = $@ || $rotate->error;
	ok( defined $signature, 'the certificate signs the binding' )
	    or diag($why);
	return unless defined $signature;

	is( $name, 'fugubsd-1-root.pub.fugubsd-1-contact.p7s',
		'and the name takes the binding extension of the type' );

	# _bind verifies what it wrote, and this read proves that the
	# bytes it answers are the signature of that run.
	my $work = tempdir( CLEANUP => 1 );
	Fugu::File->write( "$work/$name", $signature );
	ok(
		$x509->verify(
			keys      => ["$root/contact1.pem"],
			file      => $target,
			signature => "$work/$name"
		),
		'and the published certificate verifies it'
	);
};

subtest 'a bound key that names no key in force fails the step' => sub {
	my $root = _keyed();

	# WEB-TRUST-7. A bound key names the private half of a key of
	# the directory. A word that names none is a caller mistake,
	# and a step that took it would write no binding at all.
	my ( $facts, $error ) = _root(
		$root,
		secret => "$root/root2.sec",
		signer => "$root/root1.sec",
		bind   => { 'fugubsd-1-release' => "$root/rel1.sec" }
	);
	ok( !$facts, 'a bound key on a next root mint fails' );
	like( $error, qr/a first root mint and a root promote take a bound key/,
		'and the reason names the two steps that take one' );
	ok( !-e "$root/root2.sec", 'and it generates no pair' );
};

# WEB-ROTATE-1, WEB-ROTATE-2 and WEB-X509-2. Each verb takes a --type,
# and the default is signify. A mint makes a signify pair or an
# OpenPGP key: an issuer makes a certificate, so no verb mints one. An
# import publishes a key of each type that a key directory holds, and
# it refuses every other word. Each verb refuses before it writes.
subtest 'each verb refuses the key type that it does not read' => sub {
	my $root   = _keyed();
	my @before = _names($root);

	my ( $facts, $error ) = _mint(
		$root,
		type   => 'x509',
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'a mint of a certificate fails' );
	like( $error, qr/^mint-key reads no key of the type x509$/,
		'and the reason names the verb and the type' );
	ok( !-e "$root/rel2.sec", 'and it generates no pair' );

	( $facts, $error ) = _import(
		$root,
		type   => 'ssh',
		file   => "$root/web/keys/fugubsd-1-release.pub",
		secret => "$root/rel1.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'an import of a type that no key directory holds fails' );
	like( $error, qr/^import-key reads no key of the type ssh$/,
		'and the reason names that verb and its type' );

	is_deeply( [ _names($root) ], [@before],
		'and no step writes one file' );
};

# WEB-X509-2. An issuer makes a certificate, so the import is the verb
# that publishes one. It copies the certificate under the next name of
# the purpose, and the private key of the publisher signs the binding.
#
# The subtest drives the real command. openssl(1) makes the
# certificate, the step signs the binding with it, and the check
# verifies that binding with it. The skip therefore stands before the
# first assertion.
subtest 'import-key publishes a certificate, and a promote renews it' => sub {
	my $x509 = Fugu::X509->new;
	plan skip_all => 'openssl(1) is not installed'
	    unless $x509->is_available;

	my $root = _keyed();
	my $work = tempdir( CLEANUP => 1 );

	# A code signing certificate of Apple Developer ID carries the
	# team identifier in its subject. An issuer makes that one, and
	# this fixture is its own issuer: the renderer knows no issuer
	# by name, and the root manifest vouches for the bytes.
	$x509->generate(
		subject => '/O=Example/OU=TEAMID/CN=Example Signer',
		days    => 365,
		public  => "$work/sign.pem",
		secret  => "$work/sign.key",
	) or die 'the certificate fixture failed: ' . $x509->error . "\n";

	my ( $exit, $out, $err ) = _run(
		'--project', $root, 'import-key',
		'--purpose', 'sign',
		'--type',    'x509',
		'--file',    "$work/sign.pem",
		'--secret',  "$work/sign.key",
		'--signer',  "$root/root1.sec",
	);
	is( $exit, 0, 'the import succeeds' ) or diag($err);
	return unless $exit == 0;

	my %facts = map { split /=/, $_, 2 } split /\n/, $out;
	is( $facts{name}, 'fugubsd-1-sign.pem',
		'the name takes the extension of the type' );
	is( $facts{status}, 'current',
		'and the first key of the purpose is current' );

	my $published = "$root/web/keys/fugubsd-1-sign.pem";
	is( Fugu::File->read($published), Fugu::File->read("$work/sign.pem"),
		'the certificate goes in byte for byte' );
	ok( !-e "$root/web/keys/fugubsd-1-sign.key",
		'and the step writes no private half' );

	# WEB-X509-4. The step reads the fingerprint from the
	# certificate that it published, and never from an argument.
	my $der = $x509->decode_pem( Fugu::File->read($published) );
	my %block = _block( $root, 'fugubsd-1-sign' );
	is( $block{fingerprint}, $x509->fingerprint($der),
		'the key block names the SHA-256 of the DER form' );
	is( $block{email}, undef, 'and an import writes no address' );

	# WEB-TRUST-3 and WEB-X509-7. The private key of the publisher
	# signs a detached CMS signature over the public key file of
	# the current root, and the binding takes the extension of the
	# signer type.
	my $binding = 'fugubsd-1-root.pub.fugubsd-1-sign.p7s';
	ok( -f "$root/web/keys/$binding", 'the certificate binds to the root' );
	ok(
		$x509->verify(
			keys      => [$published],
			file      => "$root/web/keys/fugubsd-1-root.pub",
			signature => "$root/web/keys/$binding"
		),
		'and the published certificate verifies that binding'
	);

	# The reader verifies the binding itself, with openssl(1), and
	# it holds the certificate to every rule of the directory.
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );

	# WEB-ROTATE-9 and WEB-TRUST-4. A renewal is a rotation. The
	# new certificate enters as the next key, and the promote makes
	# it current. The retiring certificate signs the chain binding,
	# so a consumer that pins the old one reaches the new one.
	$x509->generate(
		subject => '/O=Example/OU=TEAMID/CN=Example Signer',
		days    => 365,
		public  => "$work/renewal.pem",
		secret  => "$work/renewal.key",
	) or die 'the renewal fixture failed: ' . $x509->error . "\n";

	( $exit, $out, $err ) = _run(
		'--project', $root, 'import-key',
		'--purpose', 'sign',
		'--type',    'x509',
		'--file',    "$work/renewal.pem",
		'--secret',  "$work/renewal.key",
		'--signer',  "$root/root1.sec",
	);
	is( $exit, 0, 'the import of the renewal succeeds' ) or diag($err);
	return unless $exit == 0;

	%facts = map { split /=/, $_, 2 } split /\n/, $out;
	is( $facts{status}, 'next', 'and the renewal waits as the next key' );

	( $exit, $out, $err ) = _run(
		'--project',  $root, 'promote-key',
		'--purpose',  'sign',
		'--signer',   "$root/root1.sec",
		'--retiring', "$work/sign.key",
	);
	is( $exit, 0, 'the promote succeeds' ) or diag($err);
	return unless $exit == 0;

	my $chain = 'fugubsd-2-sign.pem.fugubsd-1-sign.p7s';
	ok(
		$x509->verify(
			keys      => [$published],
			file      => "$root/web/keys/fugubsd-2-sign.pem",
			signature => "$root/web/keys/$chain"
		),
		'the retiring certificate signs the chain binding'
	);
	ok( !-e "$root/web/keys/$binding",
		'and the binding of the retired certificate is gone' );
	is_deeply( [ _problems($root) ], [],
		'and the reader reports no problem' );
};

# WEB-X509-9. An absent openssl(1) fails the step with the exit code
# of a missing tool, as WEB-ROTATE-17 holds for signify(1). A caller
# then tells a tool that it must install from a step that failed.
subtest 'an absent openssl takes the code of a missing tool' => sub {
	my $x509 = Fugu::X509->new;
	plan skip_all => 'openssl(1) is not installed'
	    unless $x509->is_available;

	my $root = _keyed();
	my $work = tempdir( CLEANUP => 1 );

	$x509->generate(
		subject => '/CN=Example Signer',
		days    => 365,
		public  => "$work/sign.pem",
		secret  => "$work/sign.key",
	) or die 'the certificate fixture failed: ' . $x509->error . "\n";

	my ( $exit, $out, $err ) = do {
		local $ENV{PATH} = '/nonexistent';
		_run(
			'--project', $root, 'import-key',
			'--purpose', 'sign',
			'--type',    'x509',
			'--file',    "$work/sign.pem",
			'--secret',  "$work/sign.key",
			'--signer',  "$root/root1.sec",
		);
	};
	is( $exit, 6, 'the command takes the missing tool code' );
	like( $err, qr/openssl/, 'and the reason names the command' );
	ok( !-e "$root/web/keys/fugubsd-1-sign.pem",
		'and it publishes no certificate' );
};

subtest 'a second mint waits for the promote' => sub {
	my $root = _keyed();

	my ($second) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( $second, 'the second mint succeeds' ) or return;

	# WEB-ROTATE-5. A caller holds one place for the private half
	# of a mint, so a second next key loses the private half of
	# the first.
	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/rel3.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'a third mint fails' );
	like( $error, qr/holds the next key fugubsd-2-release\.pub already/,
		'and the reason names the key that waits' );
	ok( !-e "$root/rel3.sec", 'and it generates no pair' );
};

subtest 'the promote makes the next key current' => sub {
	my $root = _keyed();
	my ($second) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( $second, 'the second mint succeeds' ) or return;

	my ( $facts, $error ) = _promote(
		$root,
		signer   => "$root/root1.sec",
		retiring => "$root/rel1.sec"
	);
	ok( $facts, 'the promote succeeds' ) or diag($error);
	return unless $facts;

	# WEB-ROTATE-9.
	is( $facts->{name},    'fugubsd-2-release.pub', 'the name' );
	is( $facts->{status},  'current',               'the new status' );
	is( $facts->{retired}, 'fugubsd-1-release.pub', 'the retired name' );

	my $rc = Fugu::File->read("$root/.fuguwebrc");
	like(
		$rc,
		qr/^key "fugubsd-1-release" \{\n\tstatus = retired$/m,
		'the old key reads retired'
	);
	like(
		$rc,
		qr/^key "fugubsd-2-release" \{\n\tstatus = current$/m,
		'and the new key reads current'
	);

	# WEB-TRUST-4. The retiring key signs the key that takes its
	# place, so a consumer that trusts the old key reaches the new
	# one.
	ok( _binds( $root, 'fugubsd-2-release', 'fugubsd-1-release' ),
		'the retiring key signs the chain binding' );

	# WEB-TRUST-5. The retired key attests the root no more.
	ok( !-e "$root/web/keys/fugubsd-1-root.pub.fugubsd-1-release.sig",
		'and its binding of the root is gone' );
	ok( _binds( $root, 'fugubsd-1-root', 'fugubsd-2-release' ),
		'the key that is now current still binds to the root' );

	# WEB-TRUST-2. The root signs the manifest of every step but
	# a root step.
	ok( _verifies( $root, 'fugubsd-1-root' ),
		'the root still verifies the manifest' );
	is_deeply(
		[ _manifest($root) ],
		[ _files($root) ],
		'and the manifest names every file of the directory'
	);

	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a promote needs the private half of the retiring key' => sub {
	my $root = _keyed();
	my ($second) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( $second, 'the second mint succeeds' ) or return;

	# WEB-TRUST-4. The chain binding is the one part of a promote
	# that no other key can write.
	my ( $facts, $error ) =
	    _promote( $root, signer => "$root/root1.sec" );
	ok( !$facts, 'a promote with no retiring key fails' );
	like( $error, qr/as the retiring key/, 'and the reason names it' );

	# WEB-TRUST-8. A private half of another key writes a binding
	# that the published key of the signer does not verify.
	( $facts, $error ) = _promote(
		$root,
		signer   => "$root/root1.sec",
		retiring => "$root/rel2.sec"
	);
	ok( !$facts, 'a promote with the wrong retiring key fails' );
	like( $error, qr/does not verify the binding/,
		'and the reason names the binding' );

	ok( _binds( $root, 'fugubsd-1-root', 'fugubsd-1-release' ),
		'and the binding of the current key stands' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a subordinate promote takes no secret' => sub {
	my $root = _keyed();
	my ($second) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( $second, 'the second mint succeeds' ) or return;

	# The key that becomes current holds its binding of the root
	# already, so the step needs no private half of it. An option
	# that the step does not need names a secret for nothing.
	my ( $facts, $error ) = _promote(
		$root,
		signer   => "$root/root1.sec",
		retiring => "$root/rel1.sec",
		secret   => "$root/rel2.sec"
	);
	ok( !$facts, 'a promote with a secret fails' );
	like( $error, qr/writes no key file, so it takes no secret/,
		'and the reason says why' );
};

subtest 'the root promote rewrites the binding of each key in force' => sub {
	my $root = _keyed();
	my ($next) = _root(
		$root,
		secret => "$root/root2.sec",
		signer => "$root/root1.sec"
	);
	ok( $next, 'the next root mint succeeds' ) or diag($next);
	return unless $next;

	is( $next->{status}, 'next', 'the new root waits' );

	# WEB-ROTATE-6. A root promote signs with the key that it
	# makes current, so it takes no signer.
	my ( $facts, $error ) = _promote_root(
		$root,
		secret   => "$root/root2.sec",
		signer   => "$root/root1.sec",
		retiring => "$root/root1.sec",
		bind     => { 'fugubsd-1-release' => "$root/rel1.sec" }
	);
	ok( !$facts, 'a root promote with a signer fails' );
	like( $error, qr/takes no signer/, 'and the reason says why' );

	# WEB-TRUST-7. The step refuses before it writes when one
	# private half is absent.
	( $facts, $error ) = _promote_root(
		$root,
		secret   => "$root/root2.sec",
		retiring => "$root/root1.sec"
	);
	ok( !$facts, 'a root promote with no bound key fails' );
	like( $error, qr/needs the private half of that key as the bound key/,
		'and the reason names the key' );

	( $facts, $error ) = _promote_root(
		$root,
		secret   => "$root/root2.sec",
		retiring => "$root/root1.sec",
		bind     => { 'fugubsd-1-release' => "$root/rel1.sec" }
	);
	ok( $facts, 'the root promote succeeds' ) or diag($error);
	return unless $facts;

	# WEB-ROTATE-6. The new root signs the manifest.
	ok( _verifies( $root, 'fugubsd-2-root' ),
		'the new root verifies the manifest' );
	ok( !_verifies( $root, 'fugubsd-1-root' ),
		'and the retired root verifies it no more' );

	# WEB-TRUST-4. The retiring root signs the root that takes
	# its place.
	ok( _binds( $root, 'fugubsd-2-root', 'fugubsd-1-root' ),
		'the retiring root signs the chain binding' );

	# WEB-TRUST-7. Each key in force attests the new anchor, and
	# every other binding of the retired root goes.
	ok( _binds( $root, 'fugubsd-2-root', 'fugubsd-1-release' ),
		'the key in force binds to the new root' );
	ok( !-e "$root/web/keys/fugubsd-1-root.pub.fugubsd-1-release.sig",
		'and its binding of the retired root is gone' );

	is_deeply(
		[ _names($root) ],
		[
			'SHA256',
			'SHA256.sig',
			'fugubsd-1-release.pub',
			'fugubsd-1-root.pub',
			'fugubsd-2-root.pub',
			'fugubsd-2-root.pub.fugubsd-1-release.sig',
			'fugubsd-2-root.pub.fugubsd-1-root.sig',
		],
		'the directory holds the two keys and the two bindings'
	);
	is_deeply( [ _manifest($root) ], [ _files($root) ],
		'and the manifest names each file of it' );

	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a second root promote keeps the chain binding' => sub {
	my $root = _keyed();
	my ($next) = _root(
		$root,
		secret => "$root/root2.sec",
		signer => "$root/root1.sec"
	);
	ok( $next, 'the next root mint succeeds' ) or return;

	my ($first) = _promote_root(
		$root,
		secret   => "$root/root2.sec",
		retiring => "$root/root1.sec",
		bind     => { 'fugubsd-1-release' => "$root/rel1.sec" }
	);
	ok( $first, 'the first root promote succeeds' ) or return;

	my ($third) = _root(
		$root,
		secret => "$root/root3.sec",
		signer => "$root/root2.sec"
	);
	ok( $third, 'the third root mint succeeds' ) or return;

	my ( $facts, $error ) = _promote_root(
		$root,
		secret   => "$root/root3.sec",
		retiring => "$root/root2.sec",
		bind     => { 'fugubsd-1-release' => "$root/rel1.sec" }
	);
	ok( $facts, 'the second root promote succeeds' ) or diag($error);
	return unless $facts;

	# WEB-TRUST-5 and WEB-TRUST-7. A chain binding stays
	# published, as the retired key that wrote it does. A holder
	# of the first root therefore still reaches the third.
	ok( _binds( $root, 'fugubsd-2-root', 'fugubsd-1-root' ),
		'the chain binding of the first root stands' );
	ok( _binds( $root, 'fugubsd-3-root', 'fugubsd-2-root' ),
		'beside the chain binding of the second' );
	ok( !-e "$root/web/keys/fugubsd-2-root.pub.fugubsd-1-release.sig",
		'and the binding of the retired root is gone' );

	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'import-key publishes a key that another tool made' => sub {
	my $root = _keyed();

	# WEB-X509-2 and WEB-ROTATE-1. The caller holds the private
	# half already, so the step writes no key file of its own. It
	# takes the options of a mint of its purpose.
	my $work = tempdir( CLEANUP => 1 );
	my $sig  = Fugu::Signify->new;
	$sig->generate(
		comment => 'fugubsd-1-docs',
		public  => "$work/fugubsd-1-docs.pub",
		secret  => "$work/fugubsd-1-docs.sec",
	) or die 'cannot generate the imported key: ' . $sig->error;

	my $rotate = _rotate($root);
	my $facts  = $rotate->import_key(
		purpose => 'docs',
		file    => "$work/fugubsd-1-docs.pub",
		secret  => "$work/fugubsd-1-docs.sec",
		signer  => "$root/root1.sec",
	);
	ok( $facts, 'the import succeeds' ) or diag( $rotate->error );
	return unless $facts;

	is( $facts->{name},   'fugubsd-1-docs.pub', 'the name of the key' );
	is( $facts->{status}, 'current', 'the first key of the purpose' );

	is( Fugu::File->read("$root/web/keys/fugubsd-1-docs.pub"),
		Fugu::File->read("$work/fugubsd-1-docs.pub"),
		'the key file goes in byte for byte' );

	# WEB-TRUST-3. The imported key attests the current root.
	ok( _binds( $root, 'fugubsd-1-root', 'fugubsd-1-docs' ),
		'the imported key binds to the root' );

	# WEB-ROTATE-19. A directory holds one root purpose and any
	# number of other purposes.
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

# WEB-X509-2 and WEB-OPENPGP-2. An import of another type takes the
# same options, so a key that gpg(1) made enters the directory. The
# step copies the armored public half and writes the fingerprint of
# that key into its block.
#
# WEB-OPENPGP-1. A mint writes the address of the user id that it
# made, and an import takes no --email. The block of an imported key
# therefore names the fingerprint alone.
#
# The subtest drives the real command, as the certificate import
# above does. gpg(1) makes the key and verifies the binding, so the
# skip stands before the first assertion of the subtest.
subtest 'import-key publishes an OpenPGP key that gpg(1) made' => sub {
	my $pgp = Fugu::OpenPGP->new;
	plan skip_all => 'gpg(1) is not installed' unless $pgp->is_available;

	my $root = _keyed();
	my $work = tempdir( CLEANUP => 1 );
	$pgp->generate(
		email  => $EMAIL,
		public => "$work/contact.asc",
		secret => "$work/contact.sec",
	) or die 'the OpenPGP key fixture failed: ' . $pgp->error . "\n";

	my ( $exit, $out, $err ) = _run(
		'--project', $root, 'import-key',
		'--purpose', 'contact',
		'--type',    'openpgp',
		'--file',    "$work/contact.asc",
		'--secret',  "$work/contact.sec",
		'--signer',  "$root/root1.sec",
	);
	is( $exit, 0, 'the import of an OpenPGP key succeeds' ) or diag($err);
	return unless $exit == 0;

	my %facts = map { split /=/, $_, 2 } split /\n/, $out;
	my $dir   = "$root/web/keys";
	my $name  = 'fugubsd-1-contact.asc';
	is( $facts{name}, $name, 'the name takes the OpenPGP extension' );
	is( $facts{status}, 'current',
		'and the first key of the purpose is current' );
	is( Fugu::File->read("$dir/$name"),
		Fugu::File->read("$work/contact.asc"),
		'the key file goes in byte for byte' );

	# WEB-OPENPGP-2. The block names the fingerprint that the
	# imported key itself gives, and no address.
	my $binary = $pgp->decode_armor( Fugu::File->read("$dir/$name") );
	my %setting = _block( $root, 'fugubsd-1-contact' );
	is( $setting{fingerprint},
		$pgp->fingerprint($binary),
		'the block names the fingerprint of the imported key' );
	ok( !exists $setting{email}, 'and it names no address' );

	# WEB-TRUST-3 and WEB-OPENPGP-5. The imported key attests the
	# current root, and the published key verifies that binding.
	my $binding = 'fugubsd-1-root.pub.fugubsd-1-contact.asc';
	ok(
		$pgp->verify(
			keys      => ["$dir/$name"],
			file      => "$dir/fugubsd-1-root.pub",
			signature => "$dir/$binding"
		),
		'the published key verifies the binding over the root'
	);

	ok( _verifies( $root, 'fugubsd-1-root' ),
		'the current root still signs the manifest' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a retired key is no current key' => sub {
	my $root = _keyed();
	my ($second) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( $second, 'the second mint succeeds' ) or return;
	my ($promote) = _promote(
		$root,
		signer   => "$root/root1.sec",
		retiring => "$root/rel1.sec"
	);
	ok( $promote, 'the promote succeeds' ) or return;

	# A third mint reads the status of each key, so the retired
	# key must not be the one that it takes for current.
	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/rel3.sec",
		signer => "$root/root1.sec"
	);
	ok( $facts, 'the third mint succeeds' ) or diag($error);
	return unless $facts;

	is( $facts->{serial}, 3, 'the serial counts every key of the purpose' );
	is( $facts->{status}, 'next', 'and the new key waits' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a wrong signer fails the step and changes nothing' => sub {
	my $root = _keyed();
	my ($second) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( $second, 'the second mint succeeds' ) or return;

	my %before = map { $_ => Fugu::File->read($_) } (
		"$root/.fuguwebrc",
		"$root/web/keys/SHA256",
		"$root/web/keys/SHA256.sig",
	);

	# WEB-ROTATE-7. The current root must sign, and this run names
	# the private half of another key.
	my ( $facts, $error ) = _promote(
		$root,
		signer   => "$root/rel1.sec",
		retiring => "$root/rel1.sec"
	);
	ok( !$facts, 'the promote fails' );
	like( $error, qr/does not verify the signature/,
		'and the reason names the verification' );

	# WEB-ROTATE-8 and WEB-ROTATE-10. Every file reads as it did.
	for my $path ( sort keys %before ) {
		my $name = $path =~ s{.*/}{}r;
		is( Fugu::File->read($path), $before{$path},
			"$name reads as it did before the step" );
	}

	ok( _verifies( $root, 'fugubsd-1-root' ),
		'and the root still verifies the manifest' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a promote needs a next key' => sub {
	my $root = _keyed();

	my ( $facts, $error ) = _promote(
		$root,
		signer   => "$root/root1.sec",
		retiring => "$root/rel1.sec"
	);
	ok( !$facts, 'the promote fails' );
	like( $error, qr/holds no next key/, 'and the reason says why' );
};

subtest 'a key file with no block fails every step' => sub {
	my $root = _keyed();

	# WEB-ROTATE-4. A step that assumed a status would take this
	# file for a current key.
	Fugu::File->write( "$root/web/keys/fugubsd-9-release.pub",
		Fugu::File->read("$root/web/keys/fugubsd-1-release.pub") );

	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'the mint fails' );
	like( $error, qr/no key block names it/,
		'and the reason names the file' );

	# App::FuguWeb::Keys reports the same words, so the message
	# alone cannot say which side refused. A step that read the
	# set correctly refuses before it generates a pair.
	ok( !-e "$root/rel2.sec", 'and it generates no pair' );
	is_deeply(
		[ _names($root) ],
		[
			'SHA256',
			'SHA256.sig',
			'fugubsd-1-release.pub',
			'fugubsd-1-root.pub',
			'fugubsd-1-root.pub.fugubsd-1-release.sig',
			'fugubsd-9-release.pub',
		],
		'and it writes no key file'
	);
};

subtest 'a check that fails after the write puts every file back' => sub {
	my $root = _keyed();

	# A retired OpenPGP key of the same purpose, with a
	# fingerprint that the key does not carry.
	# App::FuguWeb::Config loads it and the status rules take it,
	# so the fault reaches the step only after the write.
	Fugu::File->write( "$root/web/keys/fugubsd-2-release.asc", $OPENPGP );
	my $block = <<'RC';

key "fugubsd-2-release" {
	status      = retired
	email       = security@fugubsd.org
	fingerprint = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
}
RC
	Fugu::File->write( "$root/.fuguwebrc",
		Fugu::File->read("$root/.fuguwebrc") . $block );

	my %before = map { $_ => Fugu::File->read($_) } (
		"$root/.fuguwebrc",
		"$root/web/keys/SHA256",
		"$root/web/keys/SHA256.sig",
	);

	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/rel3.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'the mint fails' );
	like( $error, qr/the key directory holds a problem/,
		'and the reader is what refused it' );

	# WEB-ROTATE-8 and WEB-ROTATE-10. The step wrote every file
	# before the reader spoke, and each one reads as it did.
	for my $path ( sort keys %before ) {
		my $name = $path =~ s{.*/}{}r;
		is( Fugu::File->read($path), $before{$path},
			"$name reads as it did before the step" );
	}
	ok( !-e "$root/web/keys/fugubsd-3-release.pub",
		'and the key file that the step added is gone' );
	ok( !-e "$root/web/keys/fugubsd-1-root.pub.fugubsd-3-release.sig",
		'and the binding that it wrote is gone' );
	ok( !-e "$root/rel3.sec",
		'and the private half of that key reaches no caller' );
};

subtest 'a promote that fails puts every binding back' => sub {
	my $root = _keyed();
	my ($second) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( $second, 'the second mint succeeds' ) or return;

	# The same fault as above, so the reader refuses after the
	# step removed the binding of the retiring key.
	Fugu::File->write( "$root/web/keys/fugubsd-1-docs.asc", $OPENPGP );
	Fugu::File->write( "$root/.fuguwebrc",
		Fugu::File->read("$root/.fuguwebrc") . <<'RC' );

key "fugubsd-1-docs" {
	status      = current
	email       = security@fugubsd.org
	fingerprint = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
}
RC

	my @before = _names($root);
	my ( $facts, $error ) = _promote(
		$root,
		signer   => "$root/root1.sec",
		retiring => "$root/rel1.sec"
	);
	ok( !$facts, 'the promote fails' );
	like( $error, qr/the key directory holds a problem/,
		'and the reader is what refused it' );

	# WEB-ROTATE-8. The removal of a binding goes back with every
	# write, so the directory reads as it did.
	is_deeply( [ _names($root) ], \@before,
		'every file of the directory reads as it did' );
	ok( _binds( $root, 'fugubsd-1-root', 'fugubsd-1-release' ),
		'and the binding that the step removed is back' );
};

subtest 'each step records the date of the run' => sub {
	my $today = POSIX::strftime( '%Y-%m-%d', gmtime );
	my $root  = _keyed();

	# WEB-ROTATE-16. A reader of the human page needs the day that
	# the key entered service, and the day that it left.
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	like( $rc, qr/^\tsince  = \Q$today\E$/m, 'the mint records since' );

	my ($second) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( $second, 'the second mint succeeds' ) or return;
	my ($promote) = _promote(
		$root,
		signer   => "$root/root1.sec",
		retiring => "$root/rel1.sec"
	);
	ok( $promote, 'the promote succeeds' ) or return;

	$rc = Fugu::File->read("$root/.fuguwebrc");
	like( $rc, qr/^\tuntil  = \Q$today\E$/m,
		'and the promote records until' );
};

subtest 'a key block with no file fails the command' => sub {
	my $root = _keyed();

	# WEB-ROTATE-4, the other half. A block with no file names a
	# key that the site does not publish, so a consumer that read
	# the description would fetch nothing.
	Fugu::File->write( "$root/.fuguwebrc",
		Fugu::File->read("$root/.fuguwebrc")
		    . qq{\nkey "fugubsd-1-docs" {\n\tstatus = current\n}\n} );

	my ( $exit, $out, $err ) = _run(
		'--project', $root, 'mint-key',
		'--purpose', 'release',
		'--secret',  "$root/rel2.sec",
		'--signer',  "$root/root1.sec",
	);
	is( $exit, 3, 'the command exits with the config error code' );
	like( $err, qr/names no file/, 'and the reason names the block' );
	ok( !-e "$root/rel2.sec", 'and it generates no pair' );
};

subtest 'the read back compares the status that the step wrote' => sub {
	my $root = _keyed();

	# WEB-ROTATE-11. The guard reads the description again, so a
	# write that did not take effect fails the step. The intent
	# below is one that the description does not carry.
	my $rotate = _rotate($root);
	ok( !$rotate->_confirm( { 'fugubsd-1-release' => 'retired' } ),
		'a status that differs fails the read back' );
	like( $rotate->error, qr/reads the status current/,
		'and the reason names both values' );

	ok( $rotate->_confirm( { 'fugubsd-1-release' => 'current' } ),
		'and the status that the step wrote passes it' );
};

subtest 'the published prefix reaches the description' => sub {
	my $root = _site();

	# The prefix is the URL that FuguBSD/Tooling declares beside
	# the digest of the key, so a wrong one breaks make deps in
	# every consumer that syncs it.
	my $reason;
	my $config = App::FuguWeb::Config->load( root => $root,
		error => \$reason )
	    or die "load: $reason\n";
	my $rotate = App::FuguWeb::Rotate->new(
		config    => $config,
		org       => $ORG,
		url       => 'https://example.invalid/other',
		bootstrap => 1,
	);
	ok( $rotate->mint( purpose => 'root', secret => "$root/root1.sec" ),
		'the mint succeeds' )
	    or diag( $rotate->error );

	is( $rotate->config->keys_url('keys'), 'https://example.invalid/other',
		'the description carries the prefix that the caller named' );
};

subtest 'a rollback takes the description of the object back' => sub {
	my $root = _keyed();

	# A step that fails loads the description again before the
	# reader speaks, so the object must go back with the tree. A
	# caller that held the object would otherwise read a key that
	# the tree does not hold.
	Fugu::File->write( "$root/web/keys/fugubsd-2-release.asc", $OPENPGP );
	Fugu::File->write( "$root/.fuguwebrc",
		Fugu::File->read("$root/.fuguwebrc") . <<'RC' );

key "fugubsd-2-release" {
	status      = retired
	email       = security@fugubsd.org
	fingerprint = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
}
RC

	my $reason;
	my $config = App::FuguWeb::Config->load( root => $root,
		error => \$reason )
	    or die "load: $reason\n";
	my $rotate = App::FuguWeb::Rotate->new(
		config => $config,
		org    => $ORG,
	);
	ok(
		!$rotate->mint(
			purpose => 'release',
			secret  => "$root/rel3.sec",
			signer  => "$root/root1.sec"
		),
		'the mint fails'
	);

	my %stem = map { $_->{stem} => 1 } $rotate->config->site_keys('keys');
	ok( !$stem{'fugubsd-3-release'},
		'the description of the object names no key that it wrote' );
	ok( $stem{'fugubsd-1-release'}, 'and it still names the current key' );
};

subtest 'the mint guards the path of the private half' => sub {
	my $root = _keyed();

	# WEB-ROTATE-18. A caller holds each private half in one
	# place, so one path for both options would take the private
	# half of the published key.
	my $before = Fugu::File->read("$root/root1.sec");
	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/root1.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'a mint over the signer fails' );
	like( $error, qr/name one path/, 'and the reason says why' );
	is( Fugu::File->read("$root/root1.sec"), $before,
		'and the private half of the root stands' );

	# A path of the key directory would write the private half
	# over a published public key.
	( $facts, $error ) = _mint(
		$root,
		secret => "$root/web/keys/fugubsd-1-release.pub",
		signer => "$root/root1.sec",
	);
	ok( !$facts, 'a mint over a published key fails' );
	like( $error, qr/stands already/, 'and the reason says why' );
	ok( _verifies( $root, 'fugubsd-1-root' ),
		'and the root still verifies the manifest' );
};

subtest 'one directory holds one root and any other purpose' => sub {
	my $root = _keyed();

	# WEB-ROTATE-19. One manifest covers the directory and the
	# current root signs it, so a second subordinate purpose is no
	# fault: each key of it binds to that one root.
	my ( $facts, $error ) = _mint(
		$root,
		purpose => 'snapshot',
		secret  => "$root/snap1.sec",
		signer  => "$root/root1.sec"
	);
	ok( $facts, 'a mint of a second purpose succeeds' ) or diag($error);
	return unless $facts;

	is( $facts->{name}, 'fugubsd-1-snapshot.pub',
		'the serial of a new purpose starts at 1' );
	ok( _binds( $root, 'fugubsd-1-root', 'fugubsd-1-snapshot' ),
		'and the new key binds to the root' );
	ok( _verifies( $root, 'fugubsd-1-root' ),
		'and the root signs the manifest of both purposes' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a broken key set fails before a step writes' => sub {
	my $root = _keyed();

	# WEB-ROTATE-20. A purpose whose keys are all retired holds
	# no current key. A step that read no rules would take the
	# first-mint path and sign with a key that no consumer holds.
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	Fugu::File->write( "$root/.fuguwebrc",
		$rc =~ s/status = current/status = retired/gr );

	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( !$facts, 'the mint fails' );
	like( $error, qr/0 current keys/, 'and the status rules say why' );
	ok( !-e "$root/rel2.sec", 'and it generates no pair' );
};

subtest 'a trailing comment keeps its line' => sub {
	my $root = _keyed();
	my ($second) = _mint(
		$root,
		secret => "$root/rel2.sec",
		signer => "$root/root1.sec"
	);
	ok( $second, 'the second mint succeeds' ) or return;

	# Fugu::Config takes a comment behind a value, so the rewrite
	# must take one too. A writer that refused it would refuse a
	# description that the reader accepts.
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	$rc =~ s/(key "fugubsd-1-release" \{\n\tstatus = current)/$1\t# the live key/
	    or die 'the fixture adds no comment';
	Fugu::File->write( "$root/.fuguwebrc", $rc );

	my ( $facts, $error ) = _promote(
		$root,
		signer   => "$root/root1.sec",
		retiring => "$root/rel1.sec"
	);
	ok( $facts, 'the promote succeeds' ) or diag($error);
	return unless $facts;

	$rc = Fugu::File->read("$root/.fuguwebrc");
	like( $rc, qr/status = retired\t\# the live key/,
		'the comment stands behind the new value' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'an organization word that no key name carries fails' => sub {
	my $root = _site();

	# Fugu::KeyDir dies on such a word, and a caller of the
	# command reads a reason and an exit code.
	my $reason;
	my $config = App::FuguWeb::Config->load( root => $root,
		error => \$reason )
	    or die "load: $reason\n";
	my $rotate = App::FuguWeb::Rotate->new(
		config    => $config,
		org       => 'Fugu BSD',
		bootstrap => 1,
	);
	ok( !$rotate->mint( purpose => 'root', secret => "$root/k.sec" ),
		'the mint fails' );
	like( $rotate->error, qr/the organization word/,
		'and the reason names the word' );
};

subtest 'the key directory word names one directory' => sub {
	my $root = _site();

	# WEB-ROTATE-21. A word that held a solidus would write the
	# key outside the source directory.
	for my $dir ( '../escaped', 'a/b', '..', '.' ) {
		my $reason;
		my $config = App::FuguWeb::Config->load( root => $root,
			error => \$reason )
		    or die "load: $reason\n";
		my $rotate = App::FuguWeb::Rotate->new(
			config    => $config,
			org       => $ORG,
			dir       => $dir,
			bootstrap => 1,
		);
		ok(
			!$rotate->mint(
				purpose => 'root',
				secret  => "$root/k.sec"
			),
			"the word $dir fails the mint"
		);
		like( $rotate->error, qr/is not one name/,
			'and the reason says why' );
	}

	ok( !-e "$root/escaped", 'and no directory stands outside the source' );
};

# WEB-ROTATE-21. The directory word selects the key directory that a
# step writes. A description with one keys block needs none, and every
# subtest above reads that.
subtest 'a step names the key directory that it writes' => sub {
	my $root = _keyed();

	# The description holds no block of the second directory yet,
	# so the mint takes the intent, the name, the organization word
	# and the prefix, per WEB-ROTATE-15 and WEB-ROTATE-22.
	my $reason;
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \$reason )
	    or die "load: $reason\n";
	my $second = App::FuguWeb::Rotate->new(
		config    => $config,
		dir       => 'other',
		org       => 'other',
		url       => 'https://www.example.net/other',
		bootstrap => 1,
	);
	ok(
		$second->mint(
			purpose => 'root',
			secret  => "$root/other1.sec"
		),
		'the first root mint of a second directory succeeds'
	) or diag( $second->error );

	ok( -f "$root/web/other/other-1-root.pub",
		'the key lands in the directory that the caller named' );
	ok( -f "$root/web/other/SHA256", 'with a manifest of its own' );
	ok( !-e "$root/web/keys/other-1-root.pub",
		'and never in the first directory' );

	my $both =
	    App::FuguWeb::Config->load( root => $root, error => \$reason )
	    or die "load: $reason\n";
	is_deeply( [ $both->keys_dirs ],
		[ 'keys', 'other' ], 'the description names both directories' );

	# A description with several blocks names no one directory, so
	# a step that names none refuses before it writes.
	my $blind = App::FuguWeb::Rotate->new( config => $both );
	ok(
		!$blind->mint(
			purpose => 'release',
			secret  => "$root/blind.sec",
			signer  => "$root/root1.sec"
		),
		'a step that names no directory fails'
	);
	like(
		$blind->error,
		qr{the description holds the key directories keys and other, so the step needs --dir},
		'and the reason names each directory'
	);
	ok( !-e "$root/blind.sec", 'and the step writes no private half' );

	# The named directory is the one that the step writes, and the
	# root of that directory signs its manifest, per D-02.
	my $named = App::FuguWeb::Rotate->new( config => $both, dir => 'other' );
	ok(
		$named->mint(
			purpose => 'release',
			secret  => "$root/other-rel1.sec",
			signer  => "$root/other1.sec"
		),
		'a step that names the second directory succeeds'
	) or diag( $named->error );

	ok( -f "$root/web/other/other-1-release.pub",
		'the new key lands in the named directory' );
	ok( !-e "$root/web/keys/other-1-release.pub",
		'and the first directory keeps its own keys' );
	is( join( '; ', _problems($root) ),
		'', 'and every directory passes the checks' );

	# Every verb takes the word, so a promote of a second
	# directory reaches its own keys.
	my ( $exit, $out, $err ) = _run(
		'--project',  $root, 'promote-key',
		'--purpose',  'release',
		'--dir',      'other',
		'--signer',   "$root/other1.sec",
		'--retiring', "$root/other-rel1.sec",
	);
	is( $exit, 1, 'a promote with no next key fails the step' );
	like( $err, qr/the purpose release holds no next key/,
		'and the reason reads the keys of the named directory' );
};

# WEB-ROTATE-22. A step that makes a key directory states that
# intent, because each directory holds a root of trust of its own.
subtest 'a step that makes a key directory states that intent' => sub {
	my $root = _keyed();

	my $reason;
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \$reason )
	    or die "load: $reason\n";

	# A mistyped word names no block of the description, and it
	# reads as a directory that no key file stands in.
	my $typo = App::FuguWeb::Rotate->new(
		config => $config,
		dir    => 'keyz',
		org    => $ORG,
	);
	ok(
		!$typo->mint( purpose => 'root', secret => "$root/typo.sec" ),
		'a mint of a directory that no keys block names fails'
	);
	like(
		$typo->error,
		qr{the description names no key directory keyz, and a mint or an import makes one with --bootstrap},
		'and the reason names the word that makes one'
	);

	# The refusal comes before the first write, so a mistyped word
	# leaves no directory and no key behind.
	ok( !-e "$root/web/keyz", 'and the source tree holds no such'
		    . ' directory' );
	ok( !-e "$root/typo.sec", 'and the step writes no private half' );
	unlike( Fugu::File->read("$root/.fuguwebrc"),
		qr/keyz/, 'and the description names no second block' );

	# The organization word reaches Fugu::KeyDir before the step
	# makes the directory, so a bootstrap that names none leaves no
	# empty directory either.
	my $nameless = App::FuguWeb::Rotate->new(
		config    => $config,
		dir       => 'other',
		bootstrap => 1,
	);
	ok(
		!$nameless->mint(
			purpose => 'root',
			secret  => "$root/other.sec"
		),
		'a bootstrap with no organization word fails'
	);
	like( $nameless->error, qr/needs the organization word/,
		'and the reason names the word' );
	ok( !-e "$root/web/other",
		'and the source tree holds no empty directory' );

	# The same step with the intent and the word makes the
	# directory.
	my $asked = App::FuguWeb::Rotate->new(
		config    => $config,
		dir       => 'other',
		org       => 'other',
		bootstrap => 1,
	);
	ok(
		$asked->mint(
			purpose => 'root',
			secret  => "$root/other.sec"
		),
		'a mint that states the intent succeeds'
	) or diag( $asked->error );
	ok( -f "$root/web/other/other-1-root.pub",
		'and the key lands in the new directory' );
};

# WEB-ROTATE-21 and WEB-KEYS-29. Every verb holds the word to one
# directory below the source directory.
subtest 'a promote names one key directory' => sub {
	my $root = _keyed();

	for my $dir ( '../escaped', 'a/b', '..', '.' ) {
		my $reason;
		my $config = App::FuguWeb::Config->load( root => $root,
			error => \$reason )
		    or die "load: $reason\n";
		my $rotate = App::FuguWeb::Rotate->new(
			config => $config,
			dir    => $dir,
		);
		ok(
			!$rotate->promote(
				purpose  => 'release',
				retiring => "$root/rel1.sec"
			),
			"the word $dir fails the promote"
		);
		like( $rotate->error, qr/is not one name/,
			'and the reason says why' );
	}

	ok( !-e "$root/escaped", 'and no directory stands outside the source' );
};

subtest 'an absent signify takes the code of a missing tool' => sub {
	my $root = _site();

	# WEB-ROTATE-17. A caller tells a tool that it must install
	# from a step that failed, as it does for a renderer.
	my ( $exit, $out, $err ) = do {
		local $ENV{PATH} = '/nonexistent';
		_run(
			'--project', $root, 'mint-key',
			'--purpose', 'root',
			'--secret',  "$root/root1.sec",
			'--org',     $ORG,
			'--bootstrap',
		);
	};
	is( $exit, 6, 'the command takes the missing tool code' );
	like( $err, qr/signify/, 'and the reason names the command' );
	ok( !-e "$root/root1.sec", 'and it writes no private half' );
};

subtest 'the verbs guard their options and print their facts' => sub {
	my $root = _site();

	# WEB-ROTATE-1. Each verb names the options that it needs.
	my %need = (
		'mint-key'    => [qw(purpose secret)],
		'import-key'  => [qw(purpose secret file)],
		'promote-key' => [qw(purpose retiring)],
	);

	for my $verb ( sort keys %need ) {
		for my $missing ( @{ $need{$verb} } ) {
			my %opt = map { $_ => "$root/value" }
			    @{ $need{$verb} };
			$opt{purpose} = 'release';
			delete $opt{$missing};

			my ( $exit, $out, $err ) =
			    _run( '--project', $root, $verb,
				map { ( "--$_", $opt{$_} ) } sort keys %opt );
			is( $exit, 2,
				"$verb: an absent --$missing takes the"
				    . ' argument code' );
			like( $err, qr/--\Q$missing\E is a necessary option/,
				'and the reason names it' );
		}
	}

	# WEB-ROTATE-13. One name=value line for each fact, so a
	# caller appends the output to a file that its steps read.
	my ( $exit, $out, $err ) = _run(
		'--project', $root, 'mint-key',
		'--purpose', 'root',
		'--secret',  "$root/root1.sec",
		'--org',     $ORG,
		'--url',     $URL,
		'--bootstrap',
	);
	is( $exit, 0, 'the mint succeeds' ) or diag($err);

	my $digest = lc Digest::SHA::sha256_hex(
		Fugu::File->read("$root/web/keys/fugubsd-1-root.pub") );
	is_deeply(
		[ sort split /\n/, $out ],
		[
			"digest=$digest",
			'name=fugubsd-1-root.pub',
			'serial=1',
			'status=current',
			'stem=fugubsd-1-root',
			"url=$URL/fugubsd-1-root.pub",
		],
		'and it prints one name=value line for each fact'
	);

	# A step that fails takes the error code, and it prints no
	# fact at all.
	( $exit, $out, $err ) = _run(
		'--project',  $root, 'promote-key',
		'--purpose',  'release',
		'--signer',   "$root/root1.sec",
		'--retiring', "$root/root1.sec",
	);
	is( $exit, 1, 'a step that fails takes the error code' );
	is( $out,  '', 'and it prints no fact' );
	like( $err, qr/holds no next key/, 'and the reason says why' );
};

subtest 'the command line binds each key of a root step' => sub {
	my $root = _keyed();

	# WEB-TRUST-7. The option carries one stem and one path, so a
	# workflow writes each private half to a file and names it.
	my ( $exit, $out, $err ) = _run(
		'--project', $root, 'mint-key',
		'--purpose', 'root',
		'--secret',  "$root/root2.sec",
		'--signer',  "$root/root1.sec",
	);
	is( $exit, 0, 'the next root mint succeeds' ) or diag($err);

	( $exit, $out, $err ) = _run(
		'--project',  $root, 'promote-key',
		'--purpose',  'root',
		'--secret',   "$root/root2.sec",
		'--retiring', "$root/root1.sec",
		'--bind',     "fugubsd-1-release=$root/rel1.sec",
	);
	is( $exit, 0, 'the root promote succeeds' ) or diag($err);

	ok( _binds( $root, 'fugubsd-2-root', 'fugubsd-1-release' ),
		'and the key in force binds to the new root' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

done_testing();
