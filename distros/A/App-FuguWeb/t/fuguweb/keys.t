#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Keys: the description blocks, the published tree, and
# every rule of the check.
#
# The test builds each key directory in a File::Temp directory, and it
# never reads the repository. The key material is a fixture, so the
# test needs neither signify(1) nor gpg(1).
#
# A few subtests drive the real command through App::FuguWeb::CLI,
# which renders. Those need the renderers, so each one skips without
# them. The skip sits inside the subtest, and never after an
# assertion.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Digest::SHA ();
use File::Path qw(make_path remove_tree);
use Cwd ();
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Check');
use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Keys');
use_ok('App::FuguWeb::Render');
use_ok('Fugu::OpenPGP');
use_ok('App::FuguWeb::CLI');
use_ok('App::FuguWeb::Site');
use_ok('Fugu::Log');

# A real signify public key, and a real OpenPGP public key. Both are
# fixtures of this file: signify(1) verified the manifest below
# against the first, and gpg(1) imported the second.
my $SIGNIFY = <<'KEY';
untrusted comment: fugubsd-1-release public key
RWRPa1Nd3YmPwqMMjxtMv+TPkCbHp43jYR8s7TGqxx1EI70I2bKmsAlE
KEY

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

# A second OpenPGP public key, so a test can give one address two
# keys. gpg(1) exported it, and its own address is another one. The
# Web Key Directory hash comes from the description block, and never
# from the user ID of the key.
my $OPENPGP_TWO = <<'KEY';
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEap8SyBYJKwYBBAHaRw8BAQdAGB4kM583QvVjstiJzxMyAue0PzoV0JBkAr97
o/R0iua0EW90aGVyQGV4YW1wbGUubmV0iJMEExYKADsWIQTK2oMEZ8k4Mqd9r9sc
td/IKBFyxgUCap8SyAIbAwULCQgHAgIiAgYVCgkICwIEFgIDAQIeBwIXgAAKCRAc
td/IKBFyxrYlAP9T9c5ckirPex8DHwD1x/t/Twkkpz4aRlGffqwVg87eXgD+MUAt
sJE5p9nZI/NPUXLbEpLZ9EQotNcVXyqku3JhTQE=
=joU/
-----END PGP PUBLIC KEY BLOCK-----
KEY

# The v4 fingerprint of the key above, and the Web Key Directory hash
# of the local part 'security'. Both were computed outside this file:
# gpg(1) printed the fingerprint, and an independent z-base-32 encoder
# gave the hash.
use constant {
	FINGERPRINT => '98385F7E3C8DB42F0CC6DBE8EB2D04A3AF4ECE55',
	WKD_HASH    => 't5s8ztdbon8yzntexy6oz5y48etqsnbb',
};

# A real signify signature. The site build verifies nothing: a site
# that verified its own manifest would prove nothing. It reads the
# shape, because a file of another shape fails at every consumer
# install and never here. signify-openbsd(1) wrote these bytes.
my $SIGNATURE = <<'SIG';
untrusted comment: verify with k.pub
RWS/n+2mbBbQjaszJlHbcECAmX6zY46E8MrxS6vpDXtY33UrTfBBVbrutfEVICOlrSP+m3H++WREZe3nc18vW/2QkeczyJcMFAo=
SIG

my $KEYS_BLOCK = <<'RC';
keys "keys" {
	org     = fugubsd
	contact = mailto:security@fugubsd.org
	expires = 2027-09-07T00:00:00Z
	url     = https://www.fugubsd.org/keys
}

key "fugubsd-1-release" {
	status = current
	since  = 2026-09-07
}

key "fugubsd-1-contact" {
	status      = current
	since       = 2026-09-07
	email       = security@fugubsd.org
	fingerprint = 98385F7E3C8DB42F0CC6DBE8EB2D04A3AF4ECE55
}
RC

# digest($bytes):
#	The lowercase hex SHA256 of the bytes, as the manifest writes
#	it.
sub digest ($bytes)
{
	return lc Digest::SHA::sha256_hex($bytes);
}

# manifest(%file):
#	The text of a SHA256 manifest over the named bytes, in the
#	sorted order that Fugu::Signify writes.
sub manifest (%file)
{
	my $text = '';
	$text .= "SHA256 ($_) = " . digest( $file{$_} ) . "\n"
	    for sort keys %file;

	return $text;
}

# slurp($path):
#	The whole file, as bytes.
sub slurp ($path)
{
	open my $fh, '<', $path or die "Cannot read $path: $!";
	binmode $fh;
	my $bytes = do { local $/; <$fh> };
	close $fh;

	return $bytes;
}

# spew($path, $bytes):
#	Write one file, and every directory above it.
sub spew ( $path, $bytes )
{
	my $dir = $path =~ s{/[^/]+\z}{}r;
	make_path($dir) unless -d $dir;

	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print {$fh} $bytes;
	close $fh;

	return $path;
}

# project(%args):
#	A whole small project with a key directory, and its root.
#
#	%args:
#		rc    => $text    the description, default the block above
#		keys  => \%file   the key directory, default both keys
#		files => \%file   more files, as path => bytes
sub project (%args)
{
	my $root = tempdir( CLEANUP => 1 );

	my %keys = %{
		$args{keys} // {
			'fugubsd-1-release.pub' => $SIGNIFY,
			'fugubsd-1-contact.asc' => $OPENPGP,
		}
	};

	# The manifest names every key file, so a fixture that adds a
	# key never has to restate the digests.
	spew( "$root/web/keys/$_", $keys{$_} ) for keys %keys;
	unless ( exists $args{files} && exists $args{files}{'web/keys/SHA256'} )
	{
		spew( "$root/web/keys/SHA256", manifest(%keys) );
	}
	spew( "$root/web/keys/SHA256.sig", $SIGNATURE );

	spew( "$root/web/index.body.html", "<h1>Home</h1>\n" );

	my $rc = $args{rc} // $KEYS_BLOCK;
	spew( "$root/.fuguwebrc", <<"RC" );
site       = Example
source_dir = web
out_dir    = out

nav "index.html" {
	label = Home
}

page "index.html" {
	title = Home
	body  = index.body.html
}

$rc
RC

	spew( "$root/$_", $args{files}{$_} ) for keys %{ $args{files} // {} };

	return $root;
}

# keyless():
#	The same small project with no keys block and no key
#	directory. A description that publishes no key owns no path of
#	one, and the well-known names are the trap: a site of another
#	maker holds security.txt too.
sub keyless ()
{
	my $root = tempdir( CLEANUP => 1 );

	spew( "$root/web/index.body.html", "<h1>Home</h1>\n" );
	spew( "$root/.fuguwebrc", <<'RC' );
site       = Example
source_dir = web
out_dir    = out

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

# load($root):
#	Load the description of the project, and return it with the
#	reason of a failure.
sub load ($root)
{
	my $reason;
	my $config =
	    App::FuguWeb::Config->load( root => $root, error => \$reason );

	return ( $config, $reason );
}

# problems($root):
#	The key problems of the project, as one string.
sub problems ($root)
{
	my ( $config, $reason ) = load($root);
	return "the description does not load: $reason" unless $config;

	return join "\n",
	    App::FuguWeb::Keys->new( config => $config )->problems;
}

subtest 'the published paths' => sub {
	my ( $config, $reason ) = load( project() );
	ok( $config, 'a description with a key directory loads' )
	    or diag $reason;

	is( $config->keys_dir,     'keys',    'keys_dir' );
	is( $config->keys_org,     'fugubsd', 'keys_org' );
	is( $config->keys_contact, 'mailto:security@fugubsd.org',
		'keys_contact' );
	is( $config->keys_expires, '2027-09-07T00:00:00Z', 'keys_expires' );
	is( $config->keys_url, 'https://www.fugubsd.org/keys', 'keys_url' );

	my %path = map { $_ => 1 } $config->key_paths;
	for my $name (
		'keys/fugubsd-1-release.pub', 'keys/fugubsd-1-contact.asc',
		'keys/SHA256',                'keys/SHA256.sig',
		'keys/KEYS',                  'keys/index.html',
		'.well-known/openpgpkey/hu/' . WKD_HASH,
		'.well-known/openpgpkey/policy',
		'.well-known/security.txt'
	    )
	{
		ok( $path{$name}, "the inventory names $name" );
	}

	is( scalar keys %path, 9, 'and it names nothing else' );

	my %inventory = map { $_ => 1 } $config->inventory;
	ok( $inventory{'keys/KEYS'}, 'the inventory of the site holds them' );
	ok( $inventory{'index.html'}, 'beside the pages of the description' );
};

subtest 'the key blocks' => sub {
	my ( $config, $reason ) = load( project() );
	ok( $config, 'the description loads' ) or diag $reason;

	my ($signify) =
	    grep { $_->{type} eq 'signify' } $config->site_keys;
	is( $signify->{name}, 'fugubsd-1-release.pub', 'the file name' );
	is( $signify->{stem}, 'fugubsd-1-release',     'the stem' );
	is( $signify->{serial},  1,         'the serial' );
	is( $signify->{purpose}, 'release', 'the purpose' );
	is( $signify->{status},  'current', 'the status' );
	is( $signify->{email},   undef,     'a signify key has no email' );

	my ($openpgp) =
	    grep { $_->{type} eq 'openpgp' } $config->site_keys;
	is( $openpgp->{name}, 'fugubsd-1-contact.asc',
		'the type comes from the extension' );
	is( $openpgp->{email}, 'security@fugubsd.org', 'the email' );
	is( $openpgp->{wkd}, WKD_HASH, 'the Web Key Directory hash' );
	is( $openpgp->{fingerprint}, FINGERPRINT, 'the fingerprint' );
};

subtest 'the generated files' => sub {
	my ( $config, $reason ) = load( project() );
	ok( $config, 'the description loads' ) or diag $reason;

	my $keys      = App::FuguWeb::Keys->new( config => $config );
	my $generated = $keys->generated;
	ok( $generated, 'the key directory generates' ) or diag $keys->error;

	my $apache = $generated->{'keys/KEYS'};
	like( $apache, qr/^fugubsd-1-contact$/m, 'KEYS names the stem' );
	like( $apache, qr/^fingerprint: \Q@{[FINGERPRINT]}\E$/m,
		'KEYS names the fingerprint' );
	like( $apache, qr/-----BEGIN PGP PUBLIC KEY BLOCK-----/,
		'KEYS holds the armored body' );
	unlike( $apache, qr/fugubsd-1-release/,
		'and it holds no signify key, which gpg cannot read' );

	# WEB-KEYS-13 names every column of the page, so the test does
	# too. A row that lost six of eight columns passed before.
	my $page = $generated->{'keys/index.html'};
	for my $head (
		'Key',    'Purpose',     'Serial', 'Type',
		'Status', 'Fingerprint', 'Since',  'Until'
	    )
	{
		like( $page, qr{<th>\Q$head\E</th>},
			"the page names the $head column" );
	}

	like(
		$page,
		qr{<td>release</td><td>1</td><td>signify</td><td>current</td><td></td><td>2026-09-07</td><td></td>},
		'and a signify row holds each value in order'
	);
	like(
		$page,
		qr{<td>contact</td><td>1</td><td>openpgp</td><td>current</td><td>\Q@{[FINGERPRINT]}\E</td>},
		'and an OpenPGP row holds its fingerprint'
	);

	like( $page, qr{<title>Keys },     'the index page has a title' );
	like( $page, qr{href="\.\./style\.css"},
		'and it steps back to the stylesheet of the root' );
	like( $page, qr{href="\.\./index\.html"},
		'and back to the entry page' );
	like( $page, qr{href="fugubsd-1-release\.pub"},
		'and it links each key beside it' );
	like( $page, qr{<td>release</td>}, 'and it names each purpose' );

	my $binary = $generated->{ '.well-known/openpgpkey/hu/' . WKD_HASH };
	ok( defined $binary, 'the Web Key Directory file exists' );
	unlike( $binary, qr/-----BEGIN/,
		'and it holds the binary form, which the direct method serves'
	);
	is( ord( substr $binary, 0, 1 ), 0x98,
		'whose first byte opens a public key packet' );

	like( $generated->{'.well-known/openpgpkey/policy'}, qr/^#/,
		'the policy file carries a comment and no flag' );

	my $security = $generated->{'.well-known/security.txt'};
	like( $security, qr{^Contact: mailto:security\@fugubsd\.org$}m,
		'security.txt holds the contact' );
	like( $security, qr{^Expires: 2027-09-07T00:00:00Z$}m,
		'and the expiry' );
	like(
		$security,
		qr{^Encryption: \Qhttps://www.fugubsd.org/keys/fugubsd-1-contact.asc\E$}m,
		'and an Encryption field that points at the current key'
	);
};

subtest 'a signify key alone generates no OpenPGP file' => sub {
	my $root = project(
		keys => { 'fugubsd-1-release.pub' => $SIGNIFY },
		rc   => <<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}
RC
	);

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my %path = map { $_ => 1 } $config->key_paths;
	ok( !$path{'keys/KEYS'}, 'no KEYS file, which would be empty' );
	ok( !$path{'.well-known/openpgpkey/policy'}, 'no policy file' );
	ok( !$path{'.well-known/security.txt'},
		'and no security.txt without a contact' );
	ok( $path{'keys/index.html'}, 'the human page stays' );

	my $keys      = App::FuguWeb::Keys->new( config => $config );
	my $generated = $keys->generated;
	ok( $generated, 'the key directory generates' ) or diag $keys->error;
	is_deeply( [ sort keys %$generated ],
		['keys/index.html'], 'and it writes the page only' );
};

subtest 'a description with no keys block' => sub {
	my $root = tempdir( CLEANUP => 1 );
	spew( "$root/web/index.body.html", "<h1>Home</h1>\n" );
	spew( "$root/.fuguwebrc", <<'RC' );
site = Example

page "index.html" {
	title = Home
	body  = index.body.html
}
RC

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	is( $config->keys_dir, undef, 'it names no key directory' );
	is( scalar $config->site_keys, 0, 'and it holds no key' );
	is( scalar $config->key_paths, 0, 'so the inventory gains nothing' );

	my %inventory = map { $_ => 1 } $config->inventory;
	ok( $inventory{'index.html'}, 'and the site is unchanged' );

	is( scalar App::FuguWeb::Check->new( config => $config, out => 'out' )
		->_check_keys,
		0, 'the checks find nothing to say' );
};

subtest 'a good directory has no problem' => sub {
	is( problems( project() ), '', 'nothing to report' );
};

subtest 'a key file that no block names' => sub {
	my $root = project(
		keys => {
			'fugubsd-1-release.pub' => $SIGNIFY,
			'fugubsd-1-contact.asc' => $OPENPGP,
			'fugubsd-2-release.pub' => $SIGNIFY,
		}
	);

	like( problems($root), qr{^keys/fugubsd-2-release\.pub: no key block},
		'the check names the file' );
};

subtest 'a name that the pattern does not match' => sub {
	my $root = project(
		keys => {
			'fugubsd-1-release.pub' => $SIGNIFY,
			'fugubsd-1-contact.asc' => $OPENPGP,
			'notes.txt'             => "a note\n",
		}
	);

	like( problems($root), qr{^keys/notes\.txt: unknown key extension},
		'the check names the extension' );
};

subtest 'two current keys of one purpose' => sub {
	my $root = project(
		keys => {
			'fugubsd-1-release.pub' => $SIGNIFY,
			'fugubsd-2-release.pub' => $SIGNIFY,
		},
		rc => <<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-2-release" {
	status = current
}
RC
	);

	like(
		problems($root),
		qr{the purpose release holds 2 current keys},
		'the check names the purpose and the count'
	);
};

subtest 'a digest that disagrees with its file' => sub {
	my $root = project(
		files => {
			'web/keys/SHA256' => manifest(
				'fugubsd-1-release.pub' => "other bytes\n",
				'fugubsd-1-contact.asc' => $OPENPGP,
			)
		}
	);

	like(
		problems($root),
		qr{^keys/fugubsd-1-release\.pub: the manifest records \w+, and the file digests to},
		'the check names both digests'
	);
};

subtest 'a manifest that does not name a key' => sub {
	my $root = project(
		files => {
			'web/keys/SHA256' =>
			    manifest( 'fugubsd-1-contact.asc' => $OPENPGP )
		}
	);

	like( problems($root),
		qr{^keys/SHA256: it does not name fugubsd-1-release\.pub}m,
		'the check names the key' );
};

subtest 'a manifest that names a key of no block' => sub {
	my $root = project(
		files => {
			'web/keys/SHA256' => manifest(
				'fugubsd-1-release.pub' => $SIGNIFY,
				'fugubsd-1-contact.asc' => $OPENPGP,
				'fugubsd-9-release.pub' => $SIGNIFY,
			)
		}
	);

	like(
		problems($root),
		qr{^keys/SHA256: it names fugubsd-9-release\.pub, which is not a key}m,
		'the check names the line'
	);
};

subtest 'a fingerprint that the key does not give' => sub {
	my $root = project( rc => <<'RC' );
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status      = current
	fingerprint = 0000000000000000000000000000000000000000
}
RC

	like(
		problems($root),
		qr{^keys/fugubsd-1-contact\.asc: the description declares 0{40}, and the key gives \Q@{[FINGERPRINT]}\E$}m,
		'the check names both fingerprints'
	);
};

subtest 'a description that the loader refuses' => sub {
	my %case = (
		'an unknown setting of a key block' => [
			qr{key "fugubsd-1-release" names the unknown setting sinse},
			<<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
	sinse  = 2026-09-07
}
RC
		],
		'a status outside the vocabulary' => [
			qr{holds the status active, and the vocabulary is current, next, retired},
			<<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = active
}
RC
		],
		'a block that names no file' => [
			qr{key "fugubsd-9-release" names no file in web/keys},
			<<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-9-release" {
	status = current
}
RC
		],
		'an email on a signify key' => [
			qr{key "fugubsd-1-release" names email, and fugubsd-1-release\.pub is a signify key},
			<<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
	email  = x@example.org
}
RC
		],
		'an org word that no key name can hold' => [
			qr{keys "keys": org must hold lower-case letters},
			<<'RC'
keys "keys" {
	org = Fugu BSD
}

key "fugubsd-1-release" {
	status = current
}
RC
		],
		'a contact with no expiry' => [
			qr{names a contact and no expires},
			<<'RC'
keys "keys" {
	org     = fugubsd
	contact = mailto:security@fugubsd.org
}

key "fugubsd-1-release" {
	status = current
}
RC
		],
		'an expiry with no contact' => [
			qr{names expires and no contact},
			<<'RC'
keys "keys" {
	org     = fugubsd
	expires = 2027-09-07T00:00:00Z
}

key "fugubsd-1-release" {
	status = current
}
RC
		],
		'a url that is not absolute' => [
			qr{url is www\.fugubsd\.org/keys, which is not an absolute URL},
			<<'RC'
keys "keys" {
	org = fugubsd
	url = www.fugubsd.org/keys
}

key "fugubsd-1-release" {
	status = current
}
RC
		],
		'a keys block with no key block' => [
			qr{keys "keys" holds no key block},
			<<'RC'
keys "keys" {
	org = fugubsd
}
RC
		],
		'a second keys block' => [
			qr{the description holds 2 keys blocks},
			<<'RC'
keys "keys" {
	org = fugubsd
}

keys "other" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}
RC
		],
		'an unknown setting of the keys block' => [
			qr{keys "keys" names the unknown setting orgg},
			<<'RC'
keys "keys" {
	org  = fugubsd
	orgg = fugubsd
}

key "fugubsd-1-release" {
	status = current
}
RC
		],
		'an expiry that RFC 3339 does not hold' => [
			qr{expires is 2027-09-07, which is not an RFC 3339},
			<<'RC'
keys "keys" {
	org     = fugubsd
	contact = mailto:security@fugubsd.org
	expires = 2027-09-07
}

key "fugubsd-1-release" {
	status = current
}
RC
		],
		'a key block with no keys block' => [
			qr{key "fugubsd-1-release" stands with no keys block},
			<<'RC'
key "fugubsd-1-release" {
	status = current
}
RC
		],
		'a duplicate key block' => [
			qr{key "fugubsd-1-release" is declared twice},
			<<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-release" {
	status = retired
}
RC
		],
	);

	for my $name ( sort keys %case ) {
		my ( $pattern, $rc ) = @{ $case{$name} };
		my $root = project(
			keys => { 'fugubsd-1-release.pub' => $SIGNIFY },
			rc   => $rc
		);

		my ( $config, $reason ) = load($root);
		ok( !$config, "$name is refused" );
		like( $reason, $pattern, "and the reason names it" );
	}
};

subtest 'a keys name that names no directory of its own' => sub {
	my %case = (
		'a solidus' => [ 'a/b', qr{holds a solidus} ],
		'one dot'   => [ '.',   qr{names a directory of the path} ],
		'two dots'  => [ '..',  qr{leaves the output directory} ],
		'the staging directory' =>
		    [ '.man', qr{is the staging directory of the build} ],
	);

	for my $name ( sort keys %case ) {
		my ( $word, $pattern ) = @{ $case{$name} };
		my $root = project(
			keys => { 'fugubsd-1-release.pub' => $SIGNIFY },
			rc   => <<"RC"
keys "$word" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}
RC
		);

		my ( $config, $reason ) = load($root);
		ok( !$config, "$name is refused" );
		like( $reason, $pattern, 'and the reason names it' );
	}
};

subtest 'a key directory that collides with a page' => sub {
	my $root = project( rc => <<'RC' );
page "keys" {
	title = Keys
	body  = index.body.html
}

keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status = current
}
RC

	my ( $config, $reason ) = load($root);
	ok( !$config, 'the description is refused' );
	like( $reason, qr{both become the same name in the output},
		'because a page and a directory cannot share one name' );
};

subtest 'a key directory that collides with the stylesheet' => sub {
	# The guard reads the whole inventory and not the pages, so
	# every name that the output takes gets it. The stylesheet is
	# the one such name that no block declares.
	my $root = project( rc => <<'RC' );
keys "style.css" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status = current
}
RC

	rename "$root/web/keys", "$root/web/style.css"
	    or die "Cannot rename: $!";

	my ( $config, $reason ) = load($root);
	ok( !$config, 'the description is refused' );
	like( $reason, qr{both become the same name in the output},
		'because the stylesheet takes that name' );
};

subtest 'an email that is not a local part and a domain' => sub {
	my $root = project( rc => <<'RC' );
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status = current
	email  = security-at-fugubsd.org
}
RC

	my ( $config, $reason ) = load($root);
	ok( !$config, 'the description is refused' );
	like( $reason, qr{which is not a local part and a domain},
		'and the reason names the shape' );
};

subtest 'an armored body that does not decode' => sub {
	# The guards of Fugu::KeyDir read the text of a block. They
	# hold the delimiters and the block type, and they decode
	# nothing, so a body with a broken checksum passes them.
	my $broken = $OPENPGP;
	$broken =~ s/^=\S+$/=AAAA/m;

	my $root = project(
		keys => {
			'fugubsd-1-release.pub' => $SIGNIFY,
			'fugubsd-1-contact.asc' => $broken,
		},
		rc => <<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status = current
}
RC
	);

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $keys = App::FuguWeb::Keys->new( config => $config );
	ok( !$keys->generated, 'the key directory refuses to generate' );
	like( $keys->error, qr{checksum}, 'and the reason names the checksum' );
};

subtest 'an address whose keys are all retired' => sub {
	my $root = project( rc => <<'RC' );
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status = retired
	email  = security@fugubsd.org
}
RC

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	# gpg --locate-keys reads the file to encrypt a message, and a
	# retired key is the one key that must not answer that.
	my @wkd = grep { m{openpgpkey/hu/} } $config->key_paths;
	is( scalar @wkd, 0, 'the address serves no key' );

	my $keys      = App::FuguWeb::Keys->new( config => $config );
	my $generated = $keys->generated;
	ok( $generated, 'the key directory generates' ) or diag $keys->error;
	ok( !grep { m{openpgpkey/hu/} } keys %$generated,
		'and it writes no Web Key Directory file' );
	ok( !$generated->{'.well-known/openpgpkey/policy'},
		'and no policy file beside it' );
};

subtest 'a reference that climbs above the site root' => sub {
	my $root = project();
	spew( "$root/web/footer.body.html",
		qq{<p><a href="../../secret.txt">Up</a></p>\n} );

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	# A step above the root names no file of the output. A walk
	# that stopped at the root would read the reference as a link
	# that resolves.
	my @problems =
	    App::FuguWeb::Check->new( config => $config, out => $out )->run;
	ok( ( grep { m{names no page of the site} } @problems ),
		'the check reports it' )
	    or diag join "\n", @problems;
};

subtest 'a reference that names its own directory' => sub {
	my $root = project();

	# './' names the directory of the page, and a directory is no
	# page. An empty answer reads as false in the walk of the
	# reachability check, which stops the walk at that page.
	#
	# A page that the walk marks on the way in still counts as
	# seen. The fixture therefore needs a second step: the home
	# page links one page, and that page links another.
	spew( "$root/web/one.body.html",
		qq{<h1>One</h1>\n<p><a href="two.html">Two</a></p>\n} );
	spew( "$root/web/two.body.html", "<h1>Two</h1>\n" );
	spew( "$root/web/index.body.html", <<'BODY' );
<h1>Home</h1>
<p><a href="./">Here</a></p>
<p><a href="one.html">One</a></p>
BODY

	my $rc = slurp("$root/.fuguwebrc");
	$rc =~ s{^keys "keys"}{page "one.html" {\n\ttitle = One\n\tbody  = one.body.html\n}\n\npage "two.html" {\n\ttitle = Two\n\tbody  = two.body.html\n}\n\nkeys "keys"}m
	    or die 'the fixture adds no page';
	spew( "$root/.fuguwebrc", $rc );

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	my @problems =
	    App::FuguWeb::Check->new( config => $config, out => $out )->run;
	ok( !( grep { m{two\.html: no page links to it} } @problems ),
		'the walk reaches a page that a second page links' )
	    or diag join "\n", @problems;
};

subtest 'a fingerprint of the wrong shape' => sub {
	my $root = project( rc => <<'RC' );
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status      = current
	fingerprint = abc
}
RC

	my ( $config, $reason ) = load($root);
	ok( !$config, 'the description is refused' );
	like( $reason, qr{fingerprint is abc, which is not 40 hexadecimal},
		'and the reason names the shape' );
};

subtest 'a symlink in the key directory' => sub {
	my $root = project();
	symlink '/etc/passwd', "$root/web/keys/fugubsd-9-release.pub"
	    or plan skip_all => 'cannot make a symlink here';

	my ( $config, $reason ) = load($root);
	ok( !$config, 'the description is refused' );
	like(
		$reason,
		qr{web/keys/fugubsd-9-release\.pub is a symlink},
		'because the build would publish what the link points at'
	);
};

subtest 'an armored block that is not a public key' => sub {
	my $private = $OPENPGP;
	$private =~ s/PGP PUBLIC KEY BLOCK/PGP PRIVATE KEY BLOCK/g;

	my $root = project(
		keys => {
			'fugubsd-1-release.pub' => $SIGNIFY,
			'fugubsd-1-contact.asc' => $private,
		},
		rc => <<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status = current
}
RC
	);

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $keys = App::FuguWeb::Keys->new( config => $config );
	ok( !$keys->generated, 'the key directory refuses to generate' );
	like( $keys->error, qr{PRIVATE KEY BLOCK},
		'and the reason names the block' );

	# The guard must run before the first copy, or a failed build
	# leaves the private key in the output.
	my $out = tempdir( CLEANUP => 1 ) . '/out';
	ok( !site( $config, $out )->build, 'the build fails' );
	ok( !-e "$out/keys/fugubsd-1-contact.asc",
		'and it copies no key into the output' );
};

subtest 'two key files under one stem' => sub {
	my $root = project(
		keys => {
			'fugubsd-1-release.pub' => $SIGNIFY,
			'fugubsd-1-release.asc' => $OPENPGP,
		},
		rc => <<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}
RC
	);

	my ( $config, $reason ) = load($root);
	ok( !$config, 'the description is refused' );
	like(
		$reason,
		qr{names fugubsd-1-release\.asc and fugubsd-1-release\.pub, and one key block names one file},
		'because one purpose holds one current key of one type'
	);
};

subtest 'a directory with no manifest' => sub {
	for my $missing (qw(SHA256 SHA256.sig)) {
		my $root = project();
		unlink "$root/web/keys/$missing";

		my ( $config, $reason ) = load($root);
		ok( !$config, "a directory with no $missing is refused" );
		like( $reason, qr{keys "keys" holds no \Q$missing\E in web/keys},
			'and the reason names the file' );
	}
};

# site($config, $out):
#	A site over the description, with a quiet log and a renderer
#	that runs nothing.
#
#	The fixtures hold no manual and no Markdown, so no renderer is
#	ever called. The probe still tests all three, so it gets three
#	programs that exist. The key directory needs no renderer, and
#	a test of it must not skip where mandoc is absent.
sub site ( $config, $out )
{
	return App::FuguWeb::Site->new(
		config => $config,
		out    => $out,
		log    => Fugu::Log->new( mode => Fugu::Log::MODE_QUIET() ),
		render => App::FuguWeb::Render->new(
			config  => $config,
			mandoc  => '/bin/true',
			lowdown => '/bin/true',
		),
	);
}

# tree($dir):
#	Every file below the directory, as sorted relative paths.
sub tree ($dir)
{
	return sort @{ App::FuguWeb::list_tree($dir) // [] };
}

subtest 'the build writes the whole tree' => sub {
	my ( $config, $reason ) = load( project() );
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $config, $out )->build, 'the build succeeds' );

	my @expected = sort ( $config->inventory );
	is_deeply( [ tree($out) ],
		\@expected, 'the output holds the inventory and nothing else' );

	ok( -s "$out/keys/KEYS", 'the KEYS file is not empty' );
	ok( -s "$out/.well-known/openpgpkey/hu/" . WKD_HASH,
		'the Web Key Directory file is not empty' );

	# A copied file goes in byte for byte. The manifest is signed,
	# so one changed byte breaks the signature of the whole
	# directory.
	open my $fh, '<', "$out/keys/fugubsd-1-release.pub"
	    or die "Cannot read the published key: $!";
	my $published = do { local $/; <$fh> };
	close $fh;
	is( $published, $SIGNIFY, 'a key file is copied byte for byte' );

	is( scalar App::FuguWeb::Check->new( config => $config, out => $out )
		->run,
		0, 'and the built site passes its checks' );

	# A build must give the same bytes for the same checkout, or a
	# published diff shows a change that nobody made. The compare
	# reads the bytes: two files of one length can differ.
	my %first = map { $_ => slurp("$out/$_") } tree($out);
	ok( site( $config, $out )->build, 'a second build succeeds' );
	my %second = map { $_ => slurp("$out/$_") } tree($out);
	is_deeply( \%second, \%first, 'and writes the same bytes' );
};

subtest 'the build prunes a key that the description dropped' => sub {
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $config, $out )->build, 'the build succeeds' );
	ok( -e "$out/keys/fugubsd-1-contact.asc", 'the OpenPGP key is there' );
	ok( -d "$out/.well-known/openpgpkey/hu", 'and its directory' );

	# The description drops the OpenPGP key, and the key directory
	# then holds a signify key alone.
	spew( "$root/.fuguwebrc", <<'RC' );
site       = Example
source_dir = web
out_dir    = out

nav "index.html" {
	label = Home
}

page "index.html" {
	title = Home
	body  = index.body.html
}

keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}
RC
	unlink "$root/web/keys/fugubsd-1-contact.asc";
	spew( "$root/web/keys/SHA256",
		manifest( 'fugubsd-1-release.pub' => $SIGNIFY ) );

	my ( $dropped, $why ) = load($root);
	ok( $dropped, 'the smaller description loads' ) or diag $why;
	ok( site( $dropped, $out )->build, 'the build succeeds again' );

	ok( !-e "$out/keys/fugubsd-1-contact.asc",
		'the key that the site dropped is gone' );
	ok( !-e "$out/keys/KEYS", 'and the KEYS file with it' );
	ok( !-e "$out/.well-known",
		'and the well-known tree, which is now empty' );
	ok( -e "$out/keys/fugubsd-1-release.pub", 'the signify key stays' );
	ok( -d $out, 'and the output directory itself stays' );

	is( scalar App::FuguWeb::Check->new( config => $dropped, out => $out )
		->run,
		0, 'the site passes its checks' );
};

subtest 'the checks read the whole output tree' => sub {
	my ( $config, $reason ) = load( project() );
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $config, $out )->build, 'the build succeeds' );

	# A walk of one level would take every published key for a
	# stray file, and a stray file below the root for nothing.
	spew( "$out/keys/stray.txt", "left behind\n" );

	my @problems =
	    App::FuguWeb::Check->new( config => $config, out => $out )->run;
	is_deeply( [@problems],
		['keys/stray.txt: in the output but not in the site'],
		'the check names a stray file below the root by its path' );
};

subtest 'the whole check run holds the key rules' => sub {
	my $root = project(
		files => {
			'web/keys/SHA256' => manifest(
				'fugubsd-1-release.pub' => "other bytes\n",
				'fugubsd-1-contact.asc' => $OPENPGP,
			)
		}
	);

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $config, $out )->build, 'the build succeeds' );

	# fuguweb check is what a publish workflow runs, so the key
	# rules must reach it and not only the class that holds them.
	my @problems =
	    App::FuguWeb::Check->new( config => $config, out => $out )->run;
	ok(
		( grep { m{^keys/fugubsd-1-release\.pub: the manifest records} }
			@problems ),
		'the run reports a digest that disagrees with its file'
	) or diag join "\n", @problems;
};

subtest 'the chrome of a page below the root' => sub {
	my $root = project( rc => <<'RC' );
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status = current
}
RC

	# An absolute navigation entry names a place of its own, so
	# the step back must not stand in front of it.
	my $rc = slurp("$root/.fuguwebrc");
	$rc =~ s{nav "index\.html" \{\n\tlabel = Home\n\}}{$&\n\nnav "https://example.org/" {\n\tlabel = Elsewhere\n}};
	spew( "$root/.fuguwebrc", $rc );

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $config, $out )->build, 'the build succeeds' );

	my $page = slurp("$out/keys/index.html");
	like( $page, qr{href="https://example\.org/"},
		'an absolute navigation href keeps its own form' );
	unlike( $page, qr{href="\.\./https://},
		'and takes no step back in front of it' );
	like( $page, qr{href="\.\./index\.html"},
		'a relative one takes the step back' );

	# The generated page gets the checks of a page, so a broken
	# link of the chrome fails the check and never publishes.
	is( scalar App::FuguWeb::Check->new( config => $config, out => $out )
		->run,
		0, 'and the site passes its checks' );

	my @generated =
	    App::FuguWeb::Check->new( config => $config, out => $out )
	    ->generated_pages;
	is_deeply( \@generated, ['keys/index.html'],
		'the checks hold the generated page' );
};

subtest 'the generated page carries no footer' => sub {
	my $root = project();

	# The footer is the prose of the project, and the chrome
	# copies it in unchanged. A relative link of it would resolve
	# against the directory of the page that carries it. The same
	# href therefore names one file from the root, and another
	# from keys/.
	spew( "$root/web/about.body.html", "<h1>About</h1>\n" );
	spew( "$root/web/footer.body.html",
		qq{<p><a href="about.html">About</a></p>\n} );

	my $rc = slurp("$root/.fuguwebrc");
	$rc =~ s{^keys "keys"}{page "about.html" {\n\ttitle    = About\n\tbody     = about.body.html\n\tunlinked = yes\n}\n\nkeys "keys"}m
	    or die 'the fixture adds no page';
	spew( "$root/.fuguwebrc", $rc );

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	like( slurp("$out/index.html"), qr{<footer>},
		'a page of the root carries the footer' );
	unlike( slurp("$out/keys/index.html"), qr{<footer>},
		'and a page below it does not' );

	is( scalar App::FuguWeb::Check->new( config => $config, out => $out )
		->run,
		0, 'so the site passes its checks' );
};

subtest 'the checks read the links of the generated page' => sub {
	my $root = project();

	# A navigation entry that names no page is wrong on every page
	# that carries the chrome. The generated page carries it too,
	# so the check must report it there under its own path.
	my $rc = slurp("$root/.fuguwebrc");
	$rc =~ s{^nav "index\.html" \{\n\tlabel = Home\n\}}{$&\n\nnav "missing.html" {\n\tlabel = Missing\n}}m
	    or die 'the fixture adds no navigation entry';
	spew( "$root/.fuguwebrc", $rc );

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	my @problems =
	    App::FuguWeb::Check->new( config => $config, out => $out )->run;

	ok( ( grep { $_ eq 'index.html: missing.html leads nowhere' }
			@problems ),
		'the check reports the page of the root' )
	    or diag join "\n", @problems;

	# The step back is part of the href that the generated page
	# carries, so the report names it.
	ok(
		(
			grep {
				$_ eq
				    'keys/index.html: ../missing.html leads'
				    . ' nowhere'
			} @problems
		),
		'and the generated page under its own path'
	) or diag join "\n", @problems;
};

subtest 'two keys of one address share one path' => sub {
	my $root = project(
		keys => {
			'fugubsd-1-release.pub' => $SIGNIFY,
			'fugubsd-1-contact.asc' => $OPENPGP,
			'fugubsd-2-contact.asc' => $OPENPGP_TWO,
		},
		rc => <<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}

key "fugubsd-1-contact" {
	status = retired
	email  = security@fugubsd.org
}

key "fugubsd-2-contact" {
	status = current
	email  = security@fugubsd.org
}
RC
	);

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my @wkd = grep { m{openpgpkey/hu/} } $config->key_paths;
	is_deeply( \@wkd, [ '.well-known/openpgpkey/hu/' . WKD_HASH ],
		'the inventory names the address once' );

	my $keys      = App::FuguWeb::Keys->new( config => $config );
	my $generated = $keys->generated;
	ok( $generated, 'the key directory generates' ) or diag $keys->error;

	# One file holds both keys, so a rotation publishes the
	# current key and the retired one at one address. One file for
	# each key would publish the last one written only.
	# The file holds both keys, byte for byte, in publication
	# order. A length test would pass for one key of any size.
	my $binary = $generated->{ '.well-known/openpgpkey/hu/' . WKD_HASH };
	my ($current) = Fugu::OpenPGP->decode_armor($OPENPGP_TWO);
	my ($retired) = Fugu::OpenPGP->decode_armor($OPENPGP);

	is( $binary, $current . $retired,
		'the file holds the current key and then the retired one' );
};

subtest 'clean removes the whole tree' => sub {
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );
	ok( -d "$out/keys", 'the key directory is there' );

	ok( site( $config, $out )->clean, 'the clean succeeds' );
	ok( !-e $out, 'and the whole tree is gone' );
};

subtest 'the build keeps a directory that no build made' => sub {
	my ( $config, $reason ) = load( project() );
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $config, $out )->build, 'the build succeeds' );

	# The output holds one flat directory of files, and the key
	# directory below it. Anything else belongs to whoever put it
	# there, so a build must leave it, however deep it sits.
	make_path("$out/photos/deep");
	spew( "$out/photos/holiday.jpg",   "mine\n" );
	spew( "$out/photos/deep/more.jpg", "mine\n" );

	ok( site( $config, $out )->build, 'a second build succeeds' );
	ok( -e "$out/photos/holiday.jpg", 'and it keeps the file' );
	ok( -e "$out/photos/deep/more.jpg", 'and the file below it' );
	ok( -d "$out/photos/deep",          'and the directory' );

	# The prune must never remove what the clean refuses to.
	ok( !site( $config, $out )->clean, 'the clean refuses the tree' );

	my @problems =
	    App::FuguWeb::Check->new( config => $config, out => $out )->run;
	ok(
		( grep { m{^photos/holiday\.jpg: in the output} } @problems ),
		'and the check reports it'
	) or diag join "\n", @problems;
};

subtest 'the checks see an empty directory that no build made' => sub {
	my ( $config, $reason ) = load( project() );
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = tempdir( CLEANUP => 1 ) . '/out';
	ok( site( $config, $out )->build, 'the build succeeds' );

	mkdir "$out/archive" or die "Cannot make the directory: $!";

	# An empty directory is a leaf of the walk, so the checks and
	# the clean agree about the same tree.
	my @problems =
	    App::FuguWeb::Check->new( config => $config, out => $out )->run;
	ok( ( grep { m{^archive: in the output} } @problems ),
		'the check reports it' )
	    or diag join "\n", @problems;

	# The clean refuses this directory, so the build must keep it.
	# WEB-OUTPUT-6 holds for a directory as it holds for a file.
	ok( site( $config, $out )->build, 'a second build succeeds' );
	ok( -d "$out/archive", 'and the build keeps it' );
	ok( !site( $config, $out )->clean, 'the clean refuses it too' );

	spew( "$out/archive/notes.txt", "mine\n" );
	ok( site( $config, $out )->build, 'a third build succeeds' );
	ok( -e "$out/archive/notes.txt", 'and it keeps a directory of files' );
};

subtest 'the build reports a stray directory' => sub {
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	spew( "$out/archive/notes.txt", "mine\n" );

	# The build keeps a directory that no build made, and it says
	# so. An empty one gets the same report, because the build
	# keeps that one too.
	my $said = '';
	open my $saved, '>&', \*STDERR or die "Cannot save stderr: $!";
	close STDERR;
	open STDERR, '>', \$said or die 'Cannot capture stderr';

	my $again = App::FuguWeb::Site->new(
		config => $config,
		out    => $out,
		render => App::FuguWeb::Render->new(
			config  => $config,
			mandoc  => '/bin/true',
			lowdown => '/bin/true',
		),
	)->build;

	close STDERR;
	open STDERR, '>&', $saved or die "Cannot restore stderr: $!";

	ok( $again, 'a second build succeeds' );
	ok( -e "$out/archive/notes.txt", 'and it keeps the file' );
	like( $said, qr{archive/notes\.txt is in the output},
		'and it reports the file' );

	# An empty directory below the key directory is nobody's
	# build, so it stays. The report of it has its own subtest.
	mkdir "$out/keys/stale" or die "Cannot make the directory: $!";
	ok( site( $config, $out )->build, 'a third build succeeds' );
	ok( -d "$out/keys/stale", 'and it keeps an empty one' );
	ok( !site( $config, $out )->clean, 'the clean refuses it too' );
};

subtest 'list_tree walks the leaves and no symlink' => sub {
	my $dir = tempdir( CLEANUP => 1 );

	spew( "$dir/top.txt",           "a\n" );
	spew( "$dir/below/deep/one.txt", "b\n" );
	mkdir "$dir/empty" or die "Cannot make the directory: $!";

	my $linked = -e '/etc/hostname' ? '/etc/hostname' : '/etc/passwd';
	my $made = symlink $linked, "$dir/link";
	my $tree = symlink $dir . '/below', "$dir/tree";

	my $paths = App::FuguWeb::list_tree($dir);
	ok( $paths, 'the walk reads the directory' );

	my %found = map { $_ => 1 } @$paths;
	ok( $found{'top.txt'},            'a file of the top level' );
	ok( $found{'below/deep/one.txt'}, 'a file below it' );
	ok( $found{'empty'}, 'an empty directory is a leaf of its own' );

	SKIP: {
		skip 'cannot make a symlink here', 2 unless $made && $tree;

		ok( $found{'link'}, 'a symlink is one entry' );
		ok( $found{'tree'},
			'and a symlinked directory is one entry, not a walk' );
	}

	is( App::FuguWeb::list_tree("$dir/no-such-directory"),
		undef, 'a directory that it cannot read gives undef' );
};

# renderers():
#	Whether every renderer of a page is installed. A subtest that
#	drives the real command needs them, and the rest of this file
#	needs none.
sub renderers ()
{
	for my $tool (qw(mandoc lowdown pod2man)) {
		return 0 unless system("command -v $tool >/dev/null 2>&1") == 0;
	}

	return 1;
}

# cli($root, @argv):
#	Run one command of the tool from the project root, with the
#	output captured, and return the exit code.
sub cli ( $root, @argv )
{
	my ( $out, $err ) = ( '', '' );

	my $here = Cwd::getcwd();
	chdir $root or die "Cannot chdir to $root: $!";

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

	chdir $here or die "Cannot chdir back: $!";
	die $died if $died;

	return ( $exit, $err );
}

subtest 'the clean command removes a key directory' => sub {
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );
	ok( -d "$out/keys", 'the key directory is there' );

	# The command names --out, so it loads no description of its
	# own by the older rule. The description is what names the key
	# directory, and without it the clean refuses the whole site.
	my ( $exit, $err ) = cli( $root, 'clean', '--out', $out );
	is( $exit, 0, 'the clean succeeds' ) or diag $err;
	ok( !-e $out, 'and the whole tree is gone' );
};

subtest 'the clean command still refuses a tree that no build made' => sub {
	my $root = project();

	# A description that does not load must not stop the clean.
	# It is the command an operator reaches for when a description
	# is broken.
	spew( "$root/.fuguwebrc", "site = Example\nkeys \"keys\" {\n" );

	my $victim = "$root/victim";
	spew( "$victim/deep/keep.txt", "important\n" );

	my ( $exit, $err ) = cli( $root, 'clean', '--out', $victim );
	isnt( $exit, 0, 'the clean fails' );
	ok( -e "$victim/deep/keep.txt", 'and removes nothing' );
	like( $err, qr/refusing to remove it/, 'and says why' );
};

subtest 'clean refuses a file that the site does not name' => sub {
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	# The site names the key directory, so a walk that read a
	# prefix would take every name below it. The rule is the
	# shape, and no key file is named notes.txt.
	spew( "$out/keys/notes.txt", "mine\n" );

	ok( !site( $config, $out )->clean, 'the clean refuses' );
	ok( -e "$out/keys/notes.txt", 'and removes nothing' );
};

subtest 'the top level takes any plain file that a build could write' =>
    sub {
	# A renamed page leaves its old file behind, and the
	# description no longer names it. The clean must still take
	# it, or a rename would strand the output for good.
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	spew( "$out/old-name.html", "a page of an earlier run\n" );

	ok( site( $config, $out )->clean, 'the clean takes the output' );
	ok( !-e $out, 'and the whole tree is gone' );
};

subtest 'clean refuses an empty directory that no build made' => sub {
	# A directory holds a name of the site, or is a directory of
	# the key tree. Anything else is somebody else's, and an empty
	# one carries no file that the walk could refuse instead.
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	make_path("$out/photos");
	ok( !site( $config, $out )->clean, 'the clean refuses' );
	ok( -d "$out/photos", 'and removes nothing' );

	# The key tree is the one exception: its directories stay
	# after a description drops a key, and the clean takes them.
	remove_tree("$out/photos");
	ok( site( $config, $out )->clean, 'without it the clean succeeds' );
};

subtest 'a description with no keys block owns no well-known path' => sub {
	# A site of another maker holds security.txt too, so a
	# predicate that answered on the name alone would let the
	# clean delete that site.
	my $root = keyless();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;
	is( $config->keys_dir, undef, 'and it names no key directory' );

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	spew( "$out/.well-known/security.txt",       "Contact: mine\n" );
	spew( "$out/.well-known/openpgpkey/policy",  "" );
	spew( "$out/.well-known/openpgpkey/hu/ybndrfg8ejkmcpqxot1uwisza345h769",
		"mine\n" );

	my $hash = '.well-known/openpgpkey/hu/'
	    . 'ybndrfg8ejkmcpqxot1uwisza345h769';

	ok( site( $config, $out )->build, 'a second build succeeds' );
	ok( -e "$out/.well-known/security.txt",      'it keeps security.txt' );
	ok( -e "$out/.well-known/openpgpkey/policy", 'and the policy' );
	ok( -e "$out/$hash",                         'and the key of a hash' );

	ok( !site( $config, $out )->clean, 'the clean refuses the tree' );
	ok( -e "$out/.well-known/security.txt", 'and removes nothing' );
	ok( -e "$out/$hash",                    'the key of a hash as well' );
};

subtest 'a keyless description takes no foreign well-known tree' => sub {
	# The clean of a foreign target reads the description that it
	# can load. A .well-known directory alone must not make a tree
	# read like a built site.
	my ( $config, $reason ) = load( keyless() );
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = tempdir( CLEANUP => 1 ) . '/out';
	make_path("$out/.well-known");
	spew( "$out/index.html", "<h1>Someone else</h1>\n" );
	spew( "$out/style.css",  "body{}\n" );
	spew( "$out/.well-known/security.txt", "Contact: theirs\n" );

	ok( !site( $config, $out )->clean, 'the clean refuses' );
	ok( -e "$out/.well-known/security.txt", 'and removes nothing' );
};

subtest 'a keyless description owns no well-known directory' => sub {
	# The directory half of the rule. An empty tree carries no
	# file, so the file guard never reaches it.
	my ( $config, $reason ) = load( keyless() );
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = tempdir( CLEANUP => 1 ) . '/out';
	make_path("$out/.well-known/openpgpkey/hu");
	spew( "$out/index.html", "<h1>Someone else</h1>\n" );

	ok( !site( $config, $out )->clean, 'the clean refuses the tree' );
	ok( -d "$out/.well-known/openpgpkey/hu", 'and removes nothing' );
};

subtest 'the build names the stray directory that it keeps' => sub {
	# WEB-OUTPUT-4: the build keeps an entry that it may not
	# write, and it reports it. A silent build would leave the
	# operator to find the tree by hand.
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	make_path("$out/photos/2024/raw");

	my $said = '';
	open my $saved, '>&', \*STDERR or die "Cannot save stderr: $!";
	close STDERR;
	open STDERR, '>', \$said or die 'Cannot capture stderr';

	my $again = App::FuguWeb::Site->new(
		config => $config,
		out    => $out,
		render => App::FuguWeb::Render->new(
			config  => $config,
			mandoc  => '/bin/true',
			lowdown => '/bin/true',
		),
	)->build;

	close STDERR;
	open STDERR, '>&', $saved or die "Cannot restore stderr: $!";

	ok( $again, 'a second build succeeds' );
	ok( -d "$out/photos/2024/raw", 'and it keeps the tree' );
	like( $said, qr{photos/2024/raw is in the output},
		'and it names the tree' );
};

subtest 'the clean refuses a directory of the source' => sub {
	# The build renders, so the skip comes before the first
	# assertion. A plan that arrives after one is not a plan.
	plan skip_all => 'a renderer is not installed' unless renderers();

	# The key files are the trust anchor of every release, and
	# each one sits at the top level of the key directory, where
	# the clean takes a plain file.
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	for my $target (qw(web web/keys web/keys/deep)) {
		my ( $exit, $err ) = cli( $root, 'clean', '--out', $target );
		isnt( $exit, 0, "the clean refuses $target" );
		like( $err, qr{is the (?:source|key) directory},
			"and the target guard is the reason for $target" );
	}

	ok( -e "$root/web/keys/fugubsd-1-release.pub", 'the key survives' );
	ok( -e "$root/web/keys/SHA256",       'the manifest survives' );
	ok( -e "$root/web/keys/SHA256.sig",   'the signature survives' );
	ok( -e "$root/web/index.body.html",   'the source survives' );

	# The output directory that the description names is the one
	# exception below the source. This description names out, so
	# web/build is a directory of the source like any other.
	my ($exit) = cli( $root, 'build', '--out', 'web/build' );
	isnt( $exit, 0, 'the build refuses another directory of the source' );

	($exit) = cli( $root, 'build' );
	is( $exit, 0, 'and it takes the output that the site names' );

	# Every directory of the source, and not the key directory
	# alone. An operator directory there is content of the project.
	make_path("$root/web/img");
	spew( "$root/web/img/logo.svg", "logo\n" );

	for my $command (qw(build clean)) {
		my ($code) = cli( $root, $command, '--out', 'web/img' );
		isnt( $code, 0, "the $command refuses web/img" );
	}
	ok( -e "$root/web/img/logo.svg", 'the operator file survives' );
};

subtest 'a source that holds its own stylesheet' => sub {
	# The stylesheet guard alone would take this target, because
	# every build writes style.css and this source holds one. The
	# target guard is the rule that refuses it.
	my $root = project();
	spew( "$root/web/style.css", "body{}\n" );
	spew( "$root/.fuguwebrc", "site = Example\nnav \"index.html\" {\n" );

	my ( $config, $reason ) = load($root);
	ok( !$config, 'the description does not load' );

	my ($exit) = cli( $root, 'clean', '--out', 'web' );
	isnt( $exit, 0, 'the clean refuses the source directory' );
	ok( -e "$root/web/index.body.html", 'the source survives' );
	ok( -e "$root/web/keys/fugubsd-1-release.pub", 'the key survives' );

	# A source of plain files and no directory. Every other guard
	# takes this one, so the target guard is the only rule left.
	my $flat = project();
	spew( "$flat/.fuguwebrc", "site = Example\nnav \"index.html\" {\n" );
	spew( "$flat/web/style.css", "body{}\n" );
	remove_tree("$flat/web/keys");

	($exit) = cli( $flat, 'clean', '--out', 'web' );
	isnt( $exit, 0, 'and a flat source with a stylesheet as well' );
	ok( -e "$flat/web/index.body.html", 'that source survives too' );
};

subtest 'the clean refuses a foreign target with no stylesheet' => sub {
	# Outside the project the target guard says nothing, so the
	# stylesheet is the whole rule. Every build writes it.
	my $root = project();
	spew( "$root/.fuguwebrc", "site = Example\nnav \"index.html\" {\n" );

	my $victim = tempdir( CLEANUP => 1 ) . '/victim';
	spew( "$victim/notes.txt",  "mine\n" );
	spew( "$victim/README.txt", "mine\n" );

	my ($exit) = cli( $root, 'clean', '--out', $victim );
	isnt( $exit, 0, 'the clean refuses it' );
	ok( -e "$victim/notes.txt", 'and removes nothing' );

	# The same target with a stylesheet is the output of a build.
	spew( "$victim/style.css", "body{}\n" );
	($exit) = cli( $root, 'clean', '--out', $victim );
	is( $exit, 0, 'and it takes one that holds the stylesheet' );
	ok( !-e $victim, 'which is gone' );
};

# break($root):
#	Break the description of a project, as a description usually
#	breaks: a fault in the last block that somebody edited.
#	Fugu::Config keeps every setting and block that it read before
#	the fault, so the names above it survive.
sub break ($root)
{
	open my $fh, '>>', "$root/.fuguwebrc"
	    or die "Cannot append to the description: $!";
	print {$fh} "\nnav \"stray.html\" {\n";
	close $fh;

	my ( $config, $reason ) = load($root);
	ok( !$config, 'the description does not load' );

	return;
}

subtest 'a broken description guards its own directories' => sub {
	# The clean is the command an operator reaches for when a
	# description is broken, so this path is the real one. The
	# guard must still answer for the directories of that project.
	my $root = project();
	break($root);

	for my $target (qw(web/keys web)) {
		my ( $exit, $err ) = cli( $root, 'clean', '--out', $target );
		isnt( $exit, 0, "the clean refuses $target" );
		like( $err, qr{is the source directory},
			"and the target guard is the reason for $target" );
	}

	ok( -e "$root/web/keys/fugubsd-1-release.pub", 'the key survives' );
	ok( -e "$root/web/keys/SHA256",     'the manifest survives' );
	ok( -e "$root/web/keys/SHA256.sig", 'the signature survives' );
	ok( -e "$root/web/index.body.html", 'the source survives' );
};

subtest 'a broken description reads its own directory names' => sub {
	# A project of no default name at all. A guard that read a
	# default instead would refuse the wrong directory, and it
	# would miss the source key directory of this one.
	my $root = tempdir( CLEANUP => 1 );
	spew( "$root/site/index.body.html", "<h1>H</h1>\n" );
	spew( "$root/site/pubkeys/fugubsd-1-release.pub", $SIGNIFY );
	spew( "$root/site/pubkeys/SHA256",
		manifest( 'fugubsd-1-release.pub' => $SIGNIFY ) );
	spew( "$root/site/pubkeys/SHA256.sig", $SIGNATURE );
	spew( "$root/.fuguwebrc", <<'RC' );
site       = Example
source_dir = site
out_dir    = site/build

nav "index.html" {
	label = Home
}

page "index.html" {
	title = Home
	body  = index.body.html
}

keys "pubkeys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}
RC

	# The output that this description names sits inside the
	# source, as the default layout does. The build runs first,
	# because a broken description renders nothing.
	my $built = 0;
	SKIP: {
		skip 'a renderer is not installed', 2 unless renderers();

		my ($code) = cli( $root, 'build' );
		is( $code, 0, 'the build succeeds into site/build' );
		ok( -d "$root/site/build/pubkeys",
			'and it writes the key directory' );
		$built = 1;
	}

	break($root);

	# The source of this project, and the key directory in it.
	for my $target (qw(site site/pubkeys)) {
		my ( $exit, $err ) = cli( $root, 'clean', '--out', $target );
		isnt( $exit, 0, "the clean refuses $target" );
		like( $err, qr{is the source directory},
			"and the target guard is the reason for $target" );
	}
	ok( -e "$root/site/pubkeys/fugubsd-1-release.pub", 'the key survives' );
	ok( -e "$root/site/index.body.html",               'the source too' );

	# A guard that read a default output directory would refuse
	# this one, and a guard that read a default key directory
	# name would refuse the tree inside it.
	SKIP: {
		skip 'a renderer is not installed', 2 unless $built;

		my ($took) = cli( $root, 'clean', '--out', 'site/build' );
		is( $took, 0, 'the clean takes that output' );
		ok( !-e "$root/site/build", 'which is gone' );
	}

	# A directory of no build at all. The target guard says
	# nothing about it, so the stylesheet rule answers.
	spew( "$root/web/build/notes.txt", "mine\n" );

	my ( $exit, $err ) = cli( $root, 'clean', '--out', 'web/build' );
	isnt( $exit, 0, 'the clean refuses a directory of no build' );
	like( $err, qr{holds no style\.css},
		'and the stylesheet is the reason' );
	ok( -e "$root/web/build/notes.txt", 'and removes nothing' );
};

subtest 'a broken description cleans its own output' => sub {
	# The build renders, so the skip comes before the first
	# assertion. A plan that arrives after one is not a plan.
	plan skip_all => 'a renderer is not installed' unless renderers();

	# A clean of a directory that is not there returns success
	# without a walk, so the build has to run first.
	my $root = project();
	my ($code) = cli( $root, 'build' );
	is( $code, 0, 'a build of a whole description succeeds' );
	ok( -d "$root/out/keys", 'and it writes the key directory' );

	break($root);

	my ($exit) = cli( $root, 'clean', '--out', 'out' );
	is( $exit, 0, 'the clean takes the output of a build' );
	ok( !-e "$root/out", 'which is gone' );
};

subtest 'a broken description keeps the org of its keys block' => sub {
	# The org pins a key file to this organization. A description
	# that did not load names it all the same, so the published
	# key of another organization stays refused.
	my $root = project();
	break($root);

	my $victim = tempdir( CLEANUP => 1 ) . '/victim';
	spew( "$victim/style.css",  "body{}\n" );
	spew( "$victim/index.html", "<h1>Theirs</h1>\n" );
	spew( "$victim/keys/otherorg-1-release.pub", $SIGNIFY );

	my ($exit) = cli( $root, 'clean', '--out', $victim );
	isnt( $exit, 0, 'the clean refuses it' );
	ok( -e "$victim/keys/otherorg-1-release.pub",
		'and the key of another org survives' );
};

subtest 'a broken description of the default layout' => sub {
	# The build renders, so the skip comes before the first
	# assertion. A plan that arrives after one is not a plan.
	plan skip_all => 'a renderer is not installed' unless renderers();

	# A description that names neither directory takes the two
	# defaults, and the anonymous config must read them from the
	# file and not invent them.
	my $root = project( rc => $KEYS_BLOCK, files => {} );
	spew( "$root/.fuguwebrc", <<"RC" );
site = Example

nav "index.html" {
	label = Home
}

page "index.html" {
	title = Home
	body  = index.body.html
}

$KEYS_BLOCK
RC

	my ($code) = cli( $root, 'build' );
	is( $code, 0, 'the build succeeds into web/build' ) or diag "exit=$code";
	ok( -d "$root/web/build/keys", 'and it writes the key directory' );

	break($root);

	my ($exit) = cli( $root, 'clean', '--out', 'web/build' );
	is( $exit, 0, 'the clean takes the default output directory' );
	ok( !-e "$root/web/build",          'which is gone' );
	ok( -e "$root/web/index.body.html", 'and the source survives' );
};

subtest 'a key name of another organization' => sub {
	# The org comes from the description, and never from a name.
	# A guard that read a fixed org would take the key of this
	# site and refuse the key of any other one.
	my $root = project(
		rc => <<'RC'
keys "keys" {
	org = acme
}

key "acme-1-release" {
	status = current
}
RC
		,
		keys => { 'acme-1-release.pub' => $SIGNIFY },
	);

	my ( $config, $reason ) = load($root);
	ok( $config, 'a description of another org loads' ) or diag $reason;
	is( $config->keys_org, 'acme', 'and it names that org' );

	ok( App::FuguWeb::Keys->shaped( $config, 'keys/acme-1-release.pub' ),
		'the key of this site is shaped' );
	ok( !App::FuguWeb::Keys->shaped( $config, 'keys/fugubsd-1-release.pub' ),
		'and the key of another org is not' );

	# The same holds when the description does not load.
	break($root);
	my ($anon) = ( App::FuguWeb::Config->anonymous($root) );
	is( $anon->keys_org, 'acme', 'a broken description keeps the org' );
	ok( App::FuguWeb::Keys->shaped( $anon, 'keys/acme-1-release.pub' ),
		'and the key of this site stays shaped' );
	ok( !App::FuguWeb::Keys->shaped( $anon, 'keys/fugubsd-1-release.pub' ),
		'and the key of another org stays refused' );
};

subtest 'a keyless description keeps its guard when it breaks' => sub {
	# A description that names no keys block owns no key shape,
	# and a break must not give it one. Another maker's site holds
	# security.txt and a key directory too.
	my $root = keyless();
	break($root);

	my $victim = tempdir( CLEANUP => 1 ) . '/victim';
	spew( "$victim/style.css",  "body{}\n" );
	spew( "$victim/index.html", "<h1>Theirs</h1>\n" );
	spew( "$victim/.well-known/security.txt", "Contact: theirs\n" );
	spew( "$victim/keys/fugubsd-1-release.pub", $SIGNIFY );

	my ($exit) = cli( $root, 'clean', '--out', $victim );
	isnt( $exit, 0, 'the clean refuses it' );
	ok( -e "$victim/.well-known/security.txt", 'and security.txt survives' );
	ok( -e "$victim/keys/fugubsd-1-release.pub", 'and the key with it' );
};

subtest 'the build refuses a staging tree that no build made' => sub {
	# A build writes one flat directory of plain files into the
	# staging directory. The clean refuses anything else there,
	# so WEB-OUTPUT-6 says the build must keep it.
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	my $staging = "$out/" . App::FuguWeb::STAGING_DIR();
	make_path("$staging/sub");
	spew( "$staging/sub/mine.txt", "mine\n" );

	ok( !site( $config, $out )->clean, 'the clean refuses the tree' );
	ok( !site( $config, $out )->build, 'and a second build refuses it' );
	ok( -e "$staging/sub/mine.txt",    'and removes nothing' );
};

subtest 'the prune and the clean answer alike' => sub {
	# WEB-OUTPUT-6: a build must never remove a file that the
	# clean refuses. The two read one predicate, and this test
	# plants a name and compares the two answers for it.
	#
	# A name that the site holds gets skipped below: the build
	# rewrites it, so no prune ever sees it.
	my @name = (
		'keys/notes.txt',
		'keys/archive/f.txt',
		'keys/README',
		'keys/.hidden',
		'keys/fugubsd-9-release.pub',
		'keys/fugubsd-9-signing.asc',
		'keys/KEYS',
		'.well-known/security.txt',
		'.well-known/openpgpkey/policy',
		'.well-known/notes.txt',
		'.well-known/openpgpkey/hu/ybndrfg8ejkmcpqxot1uwisza345h769',
		'.well-known/openpgpkey/hu/short',
		'.well-known/openpgpkey/hu/deep/f',
		'sub/page.html',
		'stale.html',
		App::FuguWeb::STAGING_DIR() . '/mine/notes.txt',
	);

	# A directory answers the same rule, and an empty one is the
	# case that no planted file reaches: the walk gives it as a
	# leaf of its own.
	my @dir = (
		'photos',
		'photos/2024/raw',
		'keys/stale',
		'.well-known/acme-challenge',
		App::FuguWeb::STAGING_DIR() . '/mine',
	);

	# The clean reads the description that it can load, so a
	# project with no keys block must answer alike as well.
	my $tested = 0;
	for my $maker ( \&project, \&keyless ) {
		for my $name ( @name, @dir ) {
			my $is_dir = grep { $_ eq $name } @dir;

			my $root = $maker->();
			my ( $config, $reason ) = load($root);
			ok( $config, "$name: the description loads" ) or next;

			next if grep { $_ eq $name } $config->inventory;
			$tested++;

			my $out = "$root/out";
			ok( site( $config, $out )->build,
				"$name: the build succeeds" );

			$is_dir
			    ? make_path("$out/$name")
			    : spew( "$out/$name", "planted\n" );
			my $takes = site( $config, $out )->clean ? 1 : 0;

			# The clean of a taken target removed the
			# output, so the second run builds and plants
			# again.
			my $again = $maker->();
			my ($second) = load($again);
			my $out2 = "$again/out";
			site( $second, $out2 )->build;
			$is_dir
			    ? make_path("$out2/$name")
			    : spew( "$out2/$name", "planted\n" );
			site( $second, $out2 )->build;
			my $removes = -e "$out2/$name" ? 0 : 1;

			is( $removes, $takes,
				"$name: the prune and the clean answer alike"
			);
		}
	}

	# The test compares two answers, so it passes when both refuse.
	# It cannot catch a refusal that is too wide on its own: the
	# subtests above hold each side to the answer that it owes.
	#
	# A filter that dropped a name would prove less than it says,
	# so the count is the one that the loop reaches today.
	is( $tested, 39, 'the test reached every name of both makers' );
};

subtest 'the shape of a Web Key Directory name' => sub {
	# A stale hu name is the encoded SHA-1 of a local part, so it
	# holds 32 characters of the z-base-32 alphabet. The build
	# removes one of that shape and keeps every other name, and
	# the clean answers the same way.
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	my $hu    = '.well-known/openpgpkey/hu';
	my $stale = "$hu/ybndrfg8ejkmcpqxot1uwisza345h769";
	my $other = "$hu/holiday.jpg";

	spew( "$out/$stale", "stale\n" );
	spew( "$out/$other", "mine\n" );

	ok( site( $config, $out )->build, 'a second build succeeds' );
	ok( !-e "$out/$stale", 'the build removes the stale hash' );
	ok( -e "$out/$other",  'and keeps the name of another shape' );

	ok( !site( $config, $out )->clean, 'the clean refuses the tree' );
	ok( -e "$out/$other", 'and removes nothing' );
};

subtest 'a signify key file that holds no signify key' => sub {
	# The extension gives the type, so a name that ends in .pub is
	# a signify key by its name alone. The guards of Fugu::KeyDir
	# hold an OpenPGP key and skip every other type, so a file of
	# any content would publish under that name.
	# The delimiter is built and never written, because the secret
	# gate reads this file and a block of that name is what it
	# looks for. The bytes below hold no key of any kind.
	my $block   = join ' ', 'PGP', 'PRIVATE', 'KEY', 'BLOCK';
	my $private = "-----BEGIN $block-----\n\n"
	    . "bm90IGEga2V5IG9mIGFueSBraW5k\n"
	    . "=AAAA\n"
	    . "-----END $block-----\n";

	my $root = project(
		keys => { 'fugubsd-1-release.pub' => $private },
		rc   => <<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}
RC
	);

	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $keys = App::FuguWeb::Keys->new( config => $config );
	ok( !$keys->generated, 'the key directory refuses to generate' );
	like( $keys->error, qr{a signify public key holds 2},
		'and the reason names the shape' );

	my $out = "$root/out";
	ok( !site( $config, $out )->build, 'the build fails' );
	ok( !-e "$out/keys/fugubsd-1-release.pub",
		'and it publishes no private key' );

	my @problems =
	    App::FuguWeb::Check->new( config => $config, out => $out )->run;
	ok( ( grep { m{signify public key holds 2} } @problems ),
		'and the check reports it' )
	    or diag join "\n", @problems;
};

subtest 'a signify key body that is not a key' => sub {
	my %case = (
		'a body of the wrong length' =>
		    "untrusted comment: x\nRWRPa1Nd3YmPwqMM\n",
		'a body that names no algorithm' =>
		    "untrusted comment: x\n"
		    . ( 'A' x 56 ) . "\n",
		'no untrusted comment line' =>
		    "a comment\nRWRPa1Nd3YmPwqMMjxtMv+TPkCbHp43jYR8s7TGqxx1EI70I2bKmsAlE\n",
	);

	for my $name ( sort keys %case ) {
		my $root = project(
			keys => { 'fugubsd-1-release.pub' => $case{$name} },
			rc   => <<'RC'
keys "keys" {
	org = fugubsd
}

key "fugubsd-1-release" {
	status = current
}
RC
		);

		my ( $config, $reason ) = load($root);
		ok( $config, "$name loads" ) or diag $reason;

		my $keys = App::FuguWeb::Keys->new( config => $config );
		ok( !$keys->generated, "and $name is refused" );
	}
};

subtest 'a signature that is not a signify signature' => sub {
	# The build copies the signature and verifies nothing: a site
	# that verified its own manifest would prove nothing. It reads
	# the shape, because a file of another shape fails at every
	# consumer install and never here.
	my %case = (
		'the wrong line count' => [
			"untrusted comment: x\n",
			qr{a signify signature holds 2},
		],
		'no untrusted comment line' => [
			"a comment\n" . ( 'A' x 99 ) . "=\n",
			qr{no untrusted comment line},
		],
		'a body of the wrong length' => [
			"untrusted comment: x\nRWS/n+2mbBbQ\n",
			qr{not 100 base64 characters},
		],
		'a body that names no algorithm' => [
			"untrusted comment: x\n" . ( 'A' x 99 ) . "=\n",
			qr{names no signify algorithm},
		],
	);

	for my $name ( sort keys %case ) {
		my ( $bytes, $why ) = @{ $case{$name} };

		my $root =
		    project( files => { 'web/keys/SHA256.sig' => $bytes } );
		my ( $config, $reason ) = load($root);
		ok( $config, "$name loads" ) or diag $reason;

		my @problems =
		    App::FuguWeb::Keys->new( config => $config )->problems;
		ok( ( grep { $_ =~ $why } @problems ),
			"and the check reports $name" )
		    or diag join "\n", @problems;
	}
};

subtest 'a signature that the checkout does not hold' => sub {
	# The description refuses a directory with no manifest pair,
	# so an unreadable signature reaches the check through a
	# directory that lost it after the load.
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	unlink "$root/web/keys/SHA256.sig" or die "Cannot remove: $!";

	my @problems =
	    App::FuguWeb::Keys->new( config => $config )->problems;
	ok( ( grep { m{SHA256\.sig: cannot read it} } @problems ),
		'the check reports the missing signature' )
	    or diag join "\n", @problems;
};

subtest 'clean refuses a symlink that no build made' => sub {
	# The skip comes before the first assertion. A plan that
	# arrives after one turns a failed assertion into a pass.
	my $probe = tempdir( CLEANUP => 1 );
	plan skip_all => 'cannot make a symlink here'
	    unless symlink '/nonexistent', "$probe/link";

	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	# A symlink below the root. The clean deletes a tree without
	# asking, so it must refuse anything that a build cannot have
	# written.
	symlink '/etc/passwd', "$out/keys/link" or die "Cannot link: $!";

	ok( !site( $config, $out )->clean, 'the clean refuses' );
	ok( -e "$out/keys/fugubsd-1-release.pub", 'and removes nothing' );
};

subtest 'clean refuses a foreign staging tree' => sub {
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	# The build writes one flat directory of sources into the
	# staging directory. A tree below it belongs to whoever made
	# it, and the name must not carry the whole target with it.
	my $victim = tempdir( CLEANUP => 1 ) . '/victim';
	spew( "$victim/.man/deep/keep.txt", "important\n" );

	ok( !site( $config, $victim )->clean, 'the clean refuses' );
	ok( -e "$victim/.man/deep/keep.txt", 'and removes nothing' );
};

subtest 'clean refuses a foreign target that holds a tree' => sub {
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	# A --out that names another directory gets the strict rule.
	# The clean deletes without asking. A typed path must never
	# take the tree of somebody else with it, whatever the
	# description of this site happens to name.
	my $victim = tempdir( CLEANUP => 1 ) . '/victim';
	spew( "$victim/keys/deep/keep.txt", "important\n" );

	ok( !site( $config, $victim )->clean, 'the clean refuses' );
	ok( -e "$victim/keys/deep/keep.txt", 'and removes nothing' );

	# The site names each published key, so the clean removes the
	# key directory of a site that it read.
	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );
	ok( site( $config, $out )->clean, 'and the clean removes it' );
	ok( !-e $out, 'the whole tree is gone' );

	# A directory with no description at all names nothing, so
	# only one flat directory of files is a site. Without that
	# rule, a clean of a path that an operator typed would take
	# whatever the path holds.
	my $bare = tempdir( CLEANUP => 1 ) . '/build';
	spew( "$bare/somebody/precious.txt", "precious\n" );

	my $anonymous = App::FuguWeb::Config->anonymous( $root );
	ok( !site( $anonymous, $bare )->clean,
		'a clean with no description refuses a tree' );
	ok( -e "$bare/somebody/precious.txt", 'and removes nothing' );
};

subtest 'a description that drops its keys block' => sub {
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );
	ok( -d "$out/keys", 'the key directory is there' );

	# A site that drops the whole block strands the published
	# tree. The site names nothing under keys/ any more, so the
	# clean refuses it. A clean deletes without asking, and it
	# reads the site and never a guess.
	spew( "$root/.fuguwebrc", <<'RC' );
site       = Example
source_dir = web
out_dir    = out

nav "index.html" {
	label = Home
}

page "index.html" {
	title = Home
	body  = index.body.html
}
RC

	my ( $bare, $why ) = load($root);
	ok( $bare, 'the smaller description loads' ) or diag $why;
	is( $bare->keys_dir, undef, 'and it names no key directory' );

	my @problems =
	    App::FuguWeb::Check->new( config => $bare, out => $out )->run;
	ok( ( grep { m{^keys/} } @problems ),
		'the check reports the stranded tree' );

	ok( !site( $bare, $out )->clean, 'the clean refuses the output' );
	ok( -e "$out/keys/fugubsd-1-release.pub", 'and removes nothing' );

	# The operator removes the directory, or names the block
	# again. Either one makes the site whole, and the clean then
	# reads a site that it can account for.
	remove_tree("$out/keys");
	remove_tree("$out/.well-known");
	ok( site( $bare, $out )->clean, 'the clean succeeds once it is gone' );
	ok( !-e $out, 'and the whole tree with it' );
};

subtest 'the build refuses a symlink in the output' => sub {
	# The skip comes before the first assertion. A plan that
	# arrives after one turns a failed assertion into a pass.
	my $probe = tempdir( CLEANUP => 1 );
	plan skip_all => 'cannot make a symlink here'
	    unless symlink '/nonexistent', "$probe/link";

	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	# A dangling symlink is the dangerous one. Fugu::File->write
	# unlinks a path only when it exists, so an open would follow
	# the link and write the page outside the output directory.
	my $outside = tempdir( CLEANUP => 1 ) . '/pwned.html';
	unlink "$out/index.html";
	symlink $outside, "$out/index.html" or die "Cannot link: $!";

	ok( !site( $config, $out )->build, 'a second build refuses' );
	ok( !-e $outside, 'and it writes nothing through the link' );

	# The same rule guards the key directory, where a link would
	# take the published key material with it.
	unlink "$out/index.html";
	# The link points at a directory that is there, so the write
	# would succeed and _check_links is the only thing that stops
	# it. A dangling link would fail at the write instead, and
	# prove nothing about the guard.
	remove_tree("$out/.well-known");
	my $elsewhere = tempdir( CLEANUP => 1 );
	symlink $elsewhere, "$out/.well-known" or die "Cannot link: $!";

	ok( !site( $config, $out )->build, 'a build with a linked tree fails' );
	is_deeply( App::FuguWeb::list_tree($elsewhere), [],
		'and it writes no key through the link' );
	ok( -l "$out/.well-known", 'and it keeps the link' );
};

subtest 'the build refuses a symlink at the staging directory' => sub {
	# The skip comes before the first assertion. A plan that
	# arrives after one turns a failed assertion into a pass.
	my $probe = tempdir( CLEANUP => 1 );
	plan skip_all => 'cannot make a symlink here'
	    unless symlink '/nonexistent', "$probe/link";

	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	# _prepare_output removes the staging path, so a link there
	# would go without a word and the operator would lose it.
	my $target = tempdir( CLEANUP => 1 );
	symlink $target, "$out/" . App::FuguWeb::STAGING_DIR()
	    or die "Cannot link: $!";

	ok( !site( $config, $out )->build, 'a second build refuses' );
	ok( -l "$out/" . App::FuguWeb::STAGING_DIR(), 'and it keeps the link' );
	ok( -d $target, 'and the target as well' );
};

subtest 'the build refuses a symlink below the staging directory' => sub {
	# The skip comes before the first assertion. A plan that
	# arrives after one turns a failed assertion into a pass.
	my $probe = tempdir( CLEANUP => 1 );
	plan skip_all => 'cannot make a symlink here'
	    unless symlink '/nonexistent', "$probe/link";

	# _check_links reads the staging path itself, and never a name
	# below it. _drop_staging is the guard of those, and a build
	# writes one flat directory of plain files there.
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	my $staging = "$out/" . App::FuguWeb::STAGING_DIR();
	make_path($staging);
	my $target = tempdir( CLEANUP => 1 ) . '/theirs.1';
	spew( $target, "theirs\n" );
	symlink $target, "$staging/tool.1" or die "Cannot link: $!";

	ok( !site( $config, $out )->build, 'a second build refuses' );
	ok( -l "$staging/tool.1", 'and it keeps the link' );
	ok( -e $target,           'and the target as well' );

	ok( !site( $config, $out )->clean, 'the clean refuses it too' );
};

subtest 'the build refuses a symlink above a key path' => sub {
	# The skip comes before the first assertion. A plan that
	# arrives after one turns a failed assertion into a pass.
	my $probe = tempdir( CLEANUP => 1 );
	plan skip_all => 'cannot make a symlink here'
	    unless symlink '/nonexistent', "$probe/link";

	# A link at any directory of a written path sends the bytes
	# through it, not only a link at the first segment. The key
	# tree is three deep, so each level needs the rule.
	my $hu = '.well-known/openpgpkey';

	for my $where ( '.well-known', $hu, "$hu/hu" ) {
		my $root = project();
		my ($config) = load($root);
		my $out = "$root/out";
		ok( site( $config, $out )->build, "$where: the build succeeds" );

		remove_tree("$out/.well-known");
		make_path( "$out/" . ( $where =~ s{/[^/]+\z}{}r ) )
		    if $where =~ m{/};

		my $elsewhere = tempdir( CLEANUP => 1 );
		symlink $elsewhere, "$out/$where" or die "Cannot link: $!";

		ok( !site( $config, $out )->build, "$where: a build refuses" );
		is_deeply( App::FuguWeb::list_tree($elsewhere), [],
			"$where: and writes nothing through the link" );
	}
};

subtest 'the build keeps a symlink of the top level' => sub {
	# The skip comes before the first assertion. A plan that
	# arrives after one turns a failed assertion into a pass.
	my $probe = tempdir( CLEANUP => 1 );
	plan skip_all => 'cannot make a symlink here'
	    unless symlink '/nonexistent', "$probe/link";

	# The prune reads _build_made as well as _owns, and a name of
	# the top level passes _owns whatever it is. A link there is
	# never a thing that a build wrote, so the prune must keep it
	# and the clean must refuse it.
	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	my $target = tempdir( CLEANUP => 1 ) . '/elsewhere.html';
	spew( $target, "theirs\n" );
	symlink $target, "$out/stale.html" or die "Cannot link: $!";

	ok( site( $config, $out )->build, 'a second build succeeds' );
	ok( -l "$out/stale.html", 'and it keeps the link' );
	ok( -e $target,           'and the target as well' );

	ok( !site( $config, $out )->clean, 'the clean refuses the link' );
	ok( -l "$out/stale.html", 'and removes nothing' );
};

subtest 'the build keeps a symlink it never writes through' => sub {
	# The skip comes before the first assertion. A plan that
	# arrives after one turns a failed assertion into a pass.
	my $probe = tempdir( CLEANUP => 1 );
	plan skip_all => 'cannot make a symlink here'
	    unless symlink '/nonexistent', "$probe/link";

	my $root = project();
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	# The build writes the inventory and no more. A link on any
	# other path is somebody else's, and the build leaves it.
	my $target = tempdir( CLEANUP => 1 );
	symlink $target, "$out/photos" or die "Cannot link: $!";

	ok( site( $config, $out )->build, 'a second build succeeds' );
	ok( -l "$out/photos", 'and it keeps the link' );

	# The clean is the stricter of the two here, by design: it
	# deletes a tree without asking, and a link is never a thing
	# that a build wrote.
	ok( !site( $config, $out )->clean, 'the clean refuses the link' );
	ok( -l "$out/photos", 'and removes nothing' );
};

subtest 'an output path that ends in a slash' => sub {
	my $root = project();

	# File::Find writes the root of a walk without a trailing
	# slash, so a path that carries one would cut every relative
	# path one character short. The clean would then read its own
	# answer as 'nothing to refuse'.
	my ( $config, $reason ) = load($root);
	ok( $config, 'the description loads' ) or diag $reason;

	my $out = "$root/out";
	ok( site( $config, $out )->build, 'the build succeeds' );

	my $victim = tempdir( CLEANUP => 1 ) . '/victim';
	spew( "$victim/precious/data.txt", "data\n" );

	ok( !site( $config, "$victim/" )->clean, 'the clean refuses' );
	ok( -e "$victim/precious/data.txt", 'and removes nothing' );
};

done_testing();
