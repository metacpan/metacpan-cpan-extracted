#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Rotate: every rule of WEB-ROTATE, against the real
# signify(1).
#
# The rotation writes key material, so a fixture proves nothing here:
# the test generates each key with signify(1) and verifies each
# manifest with it. The whole file therefore skips without the
# command, and the skip stands before the first assertion.
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
use Fugu::Signify;
use POSIX ();

# The command signs and verifies, so no part of this file runs
# without it. The probe holds one key path, which the constructor
# needs and the lookup ignores.
#
# The skip stands before every assertion. A plan that arrived after
# one turns a skip into "you planned 0 tests but ran 3", and the
# suite then fails on a host that has no signify(1).
my $SIGNIFY = Fugu::Signify->new( keys => [__FILE__] );
plan skip_all => 'signify(1) is not installed'
    unless $SIGNIFY->is_available;

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

my $ORG = 'fugubsd';
my $URL = 'https://www.fugubsd.org/keys';

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
sub _rotate ($root)
{
	my $reason;
	my $config = App::FuguWeb::Config->load( root => $root,
		error => \$reason )
	    or die "load $root: $reason\n";

	return App::FuguWeb::Rotate->new(
		config => $config,
		org    => $ORG,
		url    => $URL,
	);
}

# _mint($root, %args), _promote($root, %args):
#	One step over a fresh rotation, so each step reads the
#	description that the step before it wrote.
sub _mint ( $root, %args )
{
	my $rotate = _rotate($root);
	my $facts  = $rotate->mint( purpose => 'release', %args );

	return ( $facts, $rotate->error );
}

sub _promote ( $root, %args )
{
	my $rotate = _rotate($root);
	my $facts  = $rotate->promote( purpose => 'release', %args );

	return ( $facts, $rotate->error );
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
	my $dir     = "$root/web/keys";
	my $signify = Fugu::Signify->new( keys => ["$dir/$stem.pub"] );

	return $signify->verify( "$dir/SHA256", "$dir/SHA256.sig" ) ? 1 : 0;
}

# _problems($root):
#	What App::FuguWeb::Keys reports about the directory.
sub _problems ($root)
{
	my $reason;
	my $config = App::FuguWeb::Config->load( root => $root,
		error => \$reason )
	    or return ("load: $reason");

	return App::FuguWeb::Keys->new( config => $config )->problems;
}

subtest 'the first mint bootstraps and signs its own manifest' => sub {
	my $root = _site();
	my ( $facts, $error ) =
	    _mint( $root, secret => "$root/k1.sec" );

	ok( $facts, 'the mint succeeds' ) or diag($error);
	return unless $facts;

	is( $facts->{name},   'fugubsd-1-release.pub', 'the name of the key' );
	is( $facts->{serial}, 1,                       'the serial starts at 1' );

	# WEB-ROTATE-3. The purpose held no current key.
	is( $facts->{status}, 'current', 'the first key is current at once' );

	# WEB-ROTATE-15. The keys block and the first key block
	# arrive together, and the block carries the published prefix.
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	like( $rc, qr/^keys "keys" \{$/m, 'the description takes a keys block' );
	like( $rc, qr/^\torg = \Q$ORG\E$/m, 'with the organization word' );
	like( $rc, qr/^\turl = \Q$URL\E$/m, 'and the published prefix' );
	like(
		$rc,
		qr/^key "fugubsd-1-release" \{\n\tstatus = current$/m,
		'and the block of the first key'
	);

	# WEB-ROTATE-6. The one exception: this key signs for itself.
	ok( _verifies( $root, 'fugubsd-1-release' ),
		'the published key verifies the manifest' );

	# WEB-ROTATE-2. The private half takes no group mode and no
	# other mode.
	my $mode = ( stat "$root/k1.sec" )[2] & 07777;
	is( sprintf( '%04o', $mode ), '0600', 'the private half takes mode 600' );

	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'the manifest records the digest of the key file' => sub {
	my $root = _site();
	my ($facts) = _mint( $root, secret => "$root/k1.sec" );
	ok( $facts, 'the mint succeeds' ) or return;

	# The digest is the trust anchor of the declaration in
	# FuguBSD/Tooling, so the test reads it against the bytes and
	# never against a shape.
	my $name  = $facts->{name};
	my $bytes = Fugu::File->read("$root/web/keys/$name");
	my $found = Digest::SHA::sha256_hex($bytes);

	my $manifest = Fugu::File->read("$root/web/keys/SHA256");
	is( $manifest, "SHA256 ($name) = $found\n",
		'the manifest names the file with the digest of its bytes' );

	# A manifest that named a digest of nothing would pass a
	# shape test, and the reader must refuse it.
	Fugu::File->write( "$root/web/keys/SHA256",
		"SHA256 ($name) = " . ( '0' x 64 ) . "\n" );
	my @problems = _problems($root);
	ok( scalar @problems, 'a false digest is a problem of the directory' );
	like( join( ' ', @problems ), qr/\Q$found\E/,
		'and the report names the digest of the file' );
};

subtest 'a later mint needs the current key as the signer' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

	# WEB-ROTATE-6. A mint that signed with the key it generated
	# would publish a manifest that no consumer can verify.
	my ( $facts, $error ) = _mint( $root, secret => "$root/k2.sec" );
	ok( !$facts, 'a mint with no signer fails' );
	like( $error, qr/needs the private half of that key/,
		'and the reason names the signer' );

	is_deeply( [ sort map { s{.*/}{}r } glob "$root/web/keys/*" ],
		[ 'SHA256', 'SHA256.sig', 'fugubsd-1-release.pub' ],
		'and the directory keeps the one key' );

	ok( !-e "$root/k2.sec", 'and no private half reaches the caller' );
};

subtest 'the first mint refuses a signer' => sub {
	my $root = _site();

	# A caller that passed a signer to a first mint would mean a
	# key that the purpose does not hold.
	my ( $facts, $error ) =
	    _mint( $root, secret => "$root/k1.sec", signer => __FILE__ );
	ok( !$facts, 'the mint fails' );
	like( $error, qr/takes no signer/, 'and the reason says why' );
};

subtest 'the current key signs the manifest that names the next one' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/k2.sec",
		signer => "$root/k1.sec",
	);
	ok( $facts, 'the second mint succeeds' ) or diag($error);
	return unless $facts;

	is( $facts->{serial}, 2,      'the serial reads as a number' );
	is( $facts->{status}, 'next', 'and the new key waits' );

	# WEB-ROTATE-6. The trust order carries the gap: a consumer
	# that holds the old key can still verify.
	ok( _verifies( $root, 'fugubsd-1-release' ),
		'the current key verifies the manifest' );
	ok( !_verifies( $root, 'fugubsd-2-release' ),
		'and the next key does not' );

	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a second mint waits for the promote' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;
	my ($second) = _mint(
		$root,
		secret => "$root/k2.sec",
		signer => "$root/k1.sec",
	);
	ok( $second, 'the second mint succeeds' ) or return;

	# WEB-ROTATE-5. A caller holds one place for the private half
	# of a mint, so a third key would lose the second one.
	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/k3.sec",
		signer => "$root/k1.sec",
	);
	ok( !$facts, 'a third mint fails' );
	like( $error, qr/holds the next key .* already/,
		'and the reason names the key that waits' );
	ok( !-e "$root/k3.sec", 'and it generates no pair' );
};

subtest 'the promote makes the next key current' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;
	my ($second) = _mint(
		$root,
		secret => "$root/k2.sec",
		signer => "$root/k1.sec",
	);
	ok( $second, 'the second mint succeeds' ) or return;

	my ( $facts, $error ) = _promote( $root, secret => "$root/k2.sec" );
	ok( $facts, 'the promote succeeds' ) or diag($error);
	return unless $facts;

	is( $facts->{name}, 'fugubsd-2-release.pub', 'the new current key' );
	is( $facts->{retired}, 'fugubsd-1-release.pub',
		'and the key that it retires' );

	# WEB-ROTATE-9. The retired key keeps its file and takes an
	# until date, so a release that it signed still verifies.
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	like(
		$rc,
		qr/^key "fugubsd-1-release" \{\n\tstatus = retired\n/m,
		'the old key reads retired'
	);
	like( $rc, qr/^\tuntil  = \d{4}-\d\d-\d\d$/m, 'with an until date' );
	like(
		$rc,
		qr/^key "fugubsd-2-release" \{\n\tstatus = current\n/m,
		'and the new key reads current'
	);
	ok( -f "$root/web/keys/fugubsd-1-release.pub",
		'and the retired key stays published' );

	# WEB-ROTATE-6. The key that the step makes current signs.
	ok( _verifies( $root, 'fugubsd-2-release' ),
		'the new current key verifies the manifest' );
	ok( !_verifies( $root, 'fugubsd-1-release' ),
		'and the retired key does not' );

	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a retired key is no current key' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;
	my ($second) = _mint(
		$root,
		secret => "$root/k2.sec",
		signer => "$root/k1.sec",
	);
	ok( $second, 'the second mint succeeds' ) or return;
	my ($promote) = _promote( $root, secret => "$root/k2.sec" );
	ok( $promote, 'the promote succeeds' ) or return;

	# WEB-ROTATE-4. A step that read no status would take the
	# first key of the purpose, which is the retired one. The
	# mint would then make a next key for a purpose that holds
	# one current key, and it would ask the retired key to sign.
	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/k3.sec",
		signer => "$root/k2.sec",
	);
	ok( $facts, 'a mint after a promote succeeds' ) or diag($error);
	return unless $facts;

	is( $facts->{serial}, 3, 'the serial follows the retired key' );
	ok( _verifies( $root, 'fugubsd-2-release' ),
		'and the key that is current signs' );

	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a wrong signer fails the step and changes nothing' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;
	my ($second) = _mint(
		$root,
		secret => "$root/k2.sec",
		signer => "$root/k1.sec",
	);
	ok( $second, 'the second mint succeeds' ) or return;

	my %before = map { $_ => Fugu::File->read($_) } (
		"$root/.fuguwebrc",
		"$root/web/keys/SHA256",
		"$root/web/keys/SHA256.sig",
	);

	# WEB-ROTATE-7. The promote must sign with the key that it
	# makes current, and this run names the wrong private half.
	my ( $facts, $error ) = _promote( $root, secret => "$root/k1.sec" );
	ok( !$facts, 'the promote fails' );
	like( $error, qr/does not verify the signature/,
		'and the reason names the verification' );

	# WEB-ROTATE-8 and WEB-ROTATE-10. Every file reads as it did.
	for my $path ( sort keys %before ) {
		my $name = $path =~ s{.*/}{}r;
		is( Fugu::File->read($path), $before{$path},
			"$name reads as it did before the step" );
	}

	ok( _verifies( $root, 'fugubsd-1-release' ),
		'and the current key still verifies the manifest' );
	is_deeply( [ _problems($root) ], [], 'the reader reports no problem' );
};

subtest 'a promote needs a next key' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

	my ( $facts, $error ) = _promote( $root, secret => "$root/k1.sec" );
	ok( !$facts, 'the promote fails' );
	like( $error, qr/holds no next key/, 'and the reason says why' );
};

subtest 'a key file with no block fails every step' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

	# WEB-ROTATE-4. A step that assumed a status would take this
	# file for a current key.
	Fugu::File->write( "$root/web/keys/fugubsd-9-release.pub",
		Fugu::File->read("$root/web/keys/fugubsd-1-release.pub") );

	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/k2.sec",
		signer => "$root/k1.sec",
	);
	ok( !$facts, 'the mint fails' );
	like( $error, qr/no key block names it/,
		'and the reason names the file' );

	# App::FuguWeb::Keys reports the same words, so the message
	# alone cannot say which side refused. A step that read the
	# set correctly refuses before it generates a pair.
	ok( !-e "$root/k2.sec", 'and it generates no pair' );
	is_deeply(
		[ sort map { s{.*/}{}r } glob "$root/web/keys/*" ],
		[
			'SHA256', 'SHA256.sig',
			'fugubsd-1-release.pub', 'fugubsd-9-release.pub'
		],
		'and it writes no key file'
	);
};

subtest 'a check that fails after the write puts every file back' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

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
		secret => "$root/k2.sec",
		signer => "$root/k1.sec",
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
	ok( !-e "$root/k2.sec",
		'and the private half of that key reaches no caller' );
};

subtest 'each step records the date of the run' => sub {
	my $root  = _site();
	my $today = POSIX::strftime( '%Y-%m-%d', gmtime );

	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

	# WEB-ROTATE-16. A reader of the human page needs the day that
	# the key entered service, and the day that it left.
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	like( $rc, qr/^\tsince  = \Q$today\E$/m, 'the mint records since' );

	my ($second) = _mint(
		$root,
		secret => "$root/k2.sec",
		signer => "$root/k1.sec",
	);
	ok( $second, 'the second mint succeeds' ) or return;
	my ($promote) = _promote( $root, secret => "$root/k2.sec" );
	ok( $promote, 'the promote succeeds' ) or return;

	$rc = Fugu::File->read("$root/.fuguwebrc");
	like( $rc, qr/^\tuntil  = \Q$today\E$/m,
		'and the promote records until' );
};

subtest 'a key block with no file fails the command' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

	# WEB-ROTATE-4, the other half. A block with no file names a
	# key that the site does not publish, so a consumer that read
	# the description would fetch nothing.
	Fugu::File->write( "$root/.fuguwebrc",
		Fugu::File->read("$root/.fuguwebrc")
		    . qq{\nkey "fugubsd-1-docs" {\n\tstatus = current\n}\n} );

	my ( $exit, $out, $err ) = _run(
		'--project', $root, 'rotate-key',
		'--step',    'mint',
		'--purpose', 'release',
		'--secret',  "$root/k2.sec",
		'--signer',  "$root/k1.sec",
	);
	is( $exit, 3, 'the command exits with the config error code' );
	like( $err, qr/names no file/, 'and the reason names the block' );
	ok( !-e "$root/k2.sec", 'and it generates no pair' );
};

subtest 'the read back compares the status that the step wrote' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

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
		config => $config,
		org    => $ORG,
		url    => 'https://example.invalid/other',
	);
	ok( $rotate->mint( purpose => 'release', secret => "$root/k1.sec" ),
		'the mint succeeds' )
	    or diag( $rotate->error );

	is( $rotate->config->keys_url, 'https://example.invalid/other',
		'the description carries the prefix that the caller named' );
};

subtest 'a rollback takes the description of the object back' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

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
			secret  => "$root/k3.sec",
			signer  => "$root/k1.sec"
		),
		'the mint fails'
	);

	my %stem = map { $_->{stem} => 1 } $rotate->config->site_keys;
	ok( !$stem{'fugubsd-3-release'},
		'the description of the object names no key that it wrote' );
	ok( $stem{'fugubsd-1-release'}, 'and it still names the current key' );
};

subtest 'the mint guards the path of the private half' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

	# WEB-ROTATE-18. A caller holds each private half in one
	# place, so one path for both options would take the private
	# half of the published key.
	my $before = Fugu::File->read("$root/k1.sec");
	my ( $facts, $error ) = _mint(
		$root,
		secret => "$root/k1.sec",
		signer => "$root/k1.sec",
	);
	ok( !$facts, 'a mint over the signer fails' );
	like( $error, qr/stands already/, 'and the reason says why' );
	is( Fugu::File->read("$root/k1.sec"), $before,
		'and the private half of the current key stands' );

	# A path of the key directory would write the private half
	# over a published public key.
	( $facts, $error ) = _mint(
		$root,
		secret => "$root/web/keys/fugubsd-1-release.pub",
		signer => "$root/k1.sec",
	);
	ok( !$facts, 'a mint over a published key fails' );
	like( $error, qr/stands already/, 'and the reason says why' );
	ok( _verifies( $root, 'fugubsd-1-release' ),
		'and the published key still verifies the manifest' );
};

subtest 'one directory holds one purpose' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

	# WEB-ROTATE-19. One manifest covers the directory and one
	# key signs it, so a key of another purpose would leave the
	# release key unable to verify the pair.
	my ( $facts, $error ) = _mint(
		$root,
		purpose => 'snapshot',
		secret  => "$root/k2.sec",
	);
	ok( !$facts, 'a mint of another purpose fails' );
	like( $error, qr/holds the purpose release/,
		'and the reason names the purpose that it holds' );
	ok( !-e "$root/k2.sec", 'and it generates no pair' );
	ok( _verifies( $root, 'fugubsd-1-release' ),
		'and the release key still verifies the manifest' );
};

subtest 'a broken key set fails before a step writes' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;

	# WEB-ROTATE-20. A purpose whose keys are all retired holds
	# no current key. A step that read no rules would take the
	# first-mint path and sign with a key that no consumer holds.
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	Fugu::File->write( "$root/.fuguwebrc",
		$rc =~ s/status = current/status = retired/r );

	my ( $facts, $error ) = _mint( $root, secret => "$root/k2.sec" );
	ok( !$facts, 'the mint fails' );
	like( $error, qr/0 current keys/, 'and the status rules say why' );
	ok( !-e "$root/k2.sec", 'and it generates no pair' );
};

subtest 'a trailing comment keeps its line' => sub {
	my $root = _site();
	my ($first) = _mint( $root, secret => "$root/k1.sec" );
	ok( $first, 'the first mint succeeds' ) or return;
	my ($second) = _mint(
		$root,
		secret => "$root/k2.sec",
		signer => "$root/k1.sec",
	);
	ok( $second, 'the second mint succeeds' ) or return;

	# Fugu::Config takes a comment behind a value, so the rewrite
	# must take one too. A writer that refused it would refuse a
	# description that the reader accepts.
	my $rc = Fugu::File->read("$root/.fuguwebrc");
	Fugu::File->write( "$root/.fuguwebrc",
		$rc =~ s/(status = current)/$1\t# the live key/r );

	my ( $facts, $error ) = _promote( $root, secret => "$root/k2.sec" );
	ok( $facts, 'the promote succeeds' ) or diag($error);
	return unless $facts;

	$rc = Fugu::File->read("$root/.fuguwebrc");
	like( $rc, qr/status = retired\t\# the live key/,
		'the comment stands behind the new value' );
	is_deeply( [ _problems($root) ], [], 'and the reader reports no problem' );
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
		config => $config,
		org    => 'Fugu BSD',
	);
	ok( !$rotate->mint( purpose => 'release', secret => "$root/k.sec" ),
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
			config => $config,
			org    => $ORG,
			dir    => $dir,
		);
		ok(
			!$rotate->mint(
				purpose => 'release',
				secret  => "$root/k.sec"
			),
			"the word $dir fails the mint"
		);
		like( $rotate->error, qr/is not one name/,
			'and the reason says why' );
	}

	ok( !-e "$root/escaped", 'and no directory stands outside the source' );
};

subtest 'an absent signify takes the code of a missing tool' => sub {
	my $root = _site();

	# WEB-ROTATE-17. A caller tells a tool that it must install
	# from a rotation that failed, as it does for a renderer.
	my ( $exit, $out, $err ) = do {
		local $ENV{PATH} = '/nonexistent';
		_run(
			'--project', $root, 'rotate-key',
			'--step',    'mint',
			'--purpose', 'release',
			'--secret',  "$root/k1.sec",
			'--org',     $ORG,
		);
	};
	is( $exit, 6, 'the command takes the missing tool code' );
	like( $err, qr/signify/, 'and the reason names the command' );
	ok( !-e "$root/k1.sec", 'and it writes no private half' );
};

subtest 'the command guards its options and prints its facts' => sub {
	my $root = _site();

	# WEB-ROTATE-1. Each option is necessary, and the step takes
	# two words.
	for my $missing (qw(step purpose secret)) {
		my %opt = (
			step    => 'mint',
			purpose => 'release',
			secret  => "$root/k.sec",
		);
		delete $opt{$missing};

		my ( $exit, $out, $err ) =
		    _run( '--project', $root, 'rotate-key',
			map { ( "--$_", $opt{$_} ) } sort keys %opt );
		is( $exit, 2, "an absent --$missing takes the argument code" );
		like( $err, qr/--\Q$missing\E is a necessary option/,
			'and the reason names it' );
	}

	my ( $exit, $out, $err ) = _run(
		'--project', $root, 'rotate-key',
		'--step',    'rotate',
		'--purpose', 'release',
		'--secret',  "$root/k.sec",
	);
	is( $exit, 2, 'a step of another word takes the argument code' );
	like( $err, qr/mint or promote/, 'and the reason names both words' );

	# WEB-ROTATE-13. One name=value line for each fact, so a
	# caller appends the output to a file that its steps read.
	( $exit, $out, $err ) = _run(
		'--project', $root, 'rotate-key',
		'--step',    'mint',
		'--purpose', 'release',
		'--secret',  "$root/k1.sec",
		'--org',     $ORG,
		'--url',     $URL,
	);
	is( $exit, 0, 'the mint succeeds' ) or diag($err);
	is_deeply(
		[ sort split /\n/, $out ],
		[
			'name=fugubsd-1-release.pub',
			'serial=1',
			'status=current',
			'stem=fugubsd-1-release',
		],
		'and it prints one name=value line for each fact'
	);

	# A rotation that fails takes the error code, and it prints
	# no fact at all.
	( $exit, $out, $err ) = _run(
		'--project', $root, 'rotate-key',
		'--step',    'promote',
		'--purpose', 'release',
		'--secret',  "$root/k1.sec",
	);
	is( $exit, 1, 'a step that fails takes the error code' );
	is( $out,  '', 'and it prints no fact' );
	like( $err, qr/holds no next key/, 'and the reason says why' );
};

done_testing();
