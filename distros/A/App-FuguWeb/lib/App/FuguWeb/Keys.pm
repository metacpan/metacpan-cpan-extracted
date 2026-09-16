# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::FuguWeb::Keys;
our $VERSION = '0.6.2';

use App::FuguWeb;
use App::FuguWeb::Page;
use Digest::SHA ();
use Fugu::File;
use Fugu::KeyDir;
use Fugu::OpenPGP;
use Fugu::Signify;
use Fugu::X509;
use MIME::Base64 ();
use POSIX        ();

# App::FuguWeb::Keys - the key directory of a site.
#
# An organization publishes its public keys under one prefix, so a
# consumer install can fetch a key and verify a release with it. This
# module is the wiring of that directory. It reads the description
# blocks and calls the Fugu modules. It answers with paths, with
# bytes, and with the problems of a check.
#
# Every generic part lives in Fugu. Fugu::KeyDir holds the name
# pattern, the publication order, and the text of the KEYS file and of
# security.txt. Fugu::OpenPGP decodes an armored key and computes a
# fingerprint and a Web Key Directory hash. Fugu::X509 decodes a PEM
# certificate and reads its fingerprint, its subject and its validity.
# Fugu::Signify parses the manifest. Nothing generic lives here.
#
# A site build neither signs nor verifies, so the manifest pair is a
# source file and not a generated one. The check verifies each
# binding, per WEB-TRUST-9: a signify binding needs no command, and a
# binding of another type runs the command of its type.

# The two files of the manifest pair. The rotation workflow writes
# them, and the build copies them as they stand.
use constant {
	MANIFEST  => 'SHA256',
	SIGNATURE => 'SHA256.sig',
};

# The generated names inside the key directory. KEYS is the Apache
# form, which gpg --import reads, and index.html is the human page.
use constant {
	KEYS_FILE  => 'KEYS',
	INDEX_PAGE => 'index.html',
};

# The well-known paths, at the site root. RFC 8615 reserves the
# prefix, and both names are registered: openpgpkey is the Web Key
# Directory, and security.txt is RFC 9116. Neither one sits under the
# key directory, because a reader asks for the registered path.
use constant {
	WELL_KNOWN   => '.well-known',
	WKD_DIR      => '.well-known/openpgpkey',
	WKD_POLICY   => '.well-known/openpgpkey/policy',
	SECURITY_TXT => '.well-known/security.txt',
};

# The two names in the source directory that name no key. The check
# holds every other name to the key pattern.
my %NOT_A_KEY = map { $_ => 1 } ( MANIFEST, SIGNATURE );

# Every generated name of the key directory. A build writes each one,
# whatever the description names today.
my %GENERATED_NAME =
    map { $_ => 1 } ( MANIFEST, SIGNATURE, KEYS_FILE, INDEX_PAGE );

# A Web Key Directory name is the z-base-32 form of the SHA-1 of an
# address local part. SHA-1 holds 20 bytes, and z-base-32 writes 32
# characters of its own alphabet for them.
use constant WKD_NAME => qr{\A[ybndrfg8ejkmcpqxot1uwisza345h769]{32}\z};

# The purpose word of the root of trust, per D-02 and WEB-TRUST-1.
# Fugu::KeyDir holds no purpose, so the word lives here and the verbs
# read it from this module.
use constant ROOT_PURPOSE => 'root';

# How long before its expiry a current key with no successor is a
# problem, per WEB-OPENPGP-4 and WEB-X509-6. A rotation runs in two
# steps, and the consumers need the gap between them, so 30 days is
# the warning.
use constant EXPIRY_WARNING => 30 * 24 * 60 * 60;

# The rank of each status in the publication order, which
# Fugu::KeyDir states. A reader wants the key in force first, so
# current leads and retired trails.
my %STATUS_RANK = do {
	my $rank = 0;
	map { $_ => $rank++ } Fugu::KeyDir::STATUSES;
};

# The verifier of each binding type. Every class follows Fugu::Signer,
# so one call shape reads all three. Fugu::Signify verifies in Perl,
# and the other two need their command.
my %VERIFIER = (
	signify => 'Fugu::Signify',
	openpgp => 'Fugu::OpenPGP',
	x509    => 'Fugu::X509',
);

# App::FuguWeb::Keys->new(%args):
#	config => $config	the site description (required)
#	dir    => $name		the key directory (required)
#
#	One object reads one key directory. A description can name
#	several, and each one holds its own root of trust, per D-02.
#
#	The method dies when the description holds no such block. A
#	caller reads keys_dirs first, so an absent block is a
#	programming error and not a failure of the site.
sub new ( $class, %args )
{
	my $config = $args{config};
	die 'config parameter required'
	    unless defined $config;

	my $dir = $args{dir};
	die 'dir parameter required'
	    unless defined $dir;
	die "the description holds no keys block $dir\n"
	    unless grep { $_ eq $dir } $config->keys_dirs;

	# The reader of each key type needs no command of its own. The
	# expiry of an OpenPGP key is the one read that runs gpg(1).
	return bless {
		config  => $config,
		dir     => $dir,
		keydir  => Fugu::KeyDir->new( org => $config->keys_org($dir) ),
		openpgp => Fugu::OpenPGP->new,
		x509    => Fugu::X509->new,
		error   => undef,
	}, $class;
}

# $self->error:
#	The reason of the most recent failure, or undef after a
#	success.
sub error ($self)
{
	return $self->{error};
}

# App::FuguWeb::Keys->shaped($config, $path):
#	Report whether a path of the output is one that a build of the
#	key directory writes.
#
#	A stale key file needs this. The build removes what the site
#	dropped, and a key that the description no longer names is
#	exactly that. The inventory cannot answer for it, because the
#	inventory names what the site holds today.
#
#	The set is bounded, and every member takes a fixed shape: a
#	generated name of a key directory, a key file that
#	Fugu::KeyDir parses, or one of the well-known paths. A path of
#	another shape belongs to whoever made it, so a target that
#	holds keys/notes.txt is no site.
#
#	The method reads each declared directory. A directory that the
#	description dropped keeps its files: the build reports them,
#	per WEB-OUTPUT-4, and the operator removes them by hand.
#
#	The prune and the clean read this one answer, so a build can
#	never remove a file that the clean refuses.
sub shaped ( $class, $config, $path )
{
	# A description with no keys block publishes no key directory,
	# so it owns no path of one. The well-known names are the
	# trap: a site of another maker holds security.txt too, and a
	# clean that took it would delete that site.
	#
	# A description that did not load names each block all the
	# same: App::FuguWeb::Config reads those names out of the file
	# that failed. A description that truly names none owns no
	# path here, whether it loaded or not.
	my @dirs = $config->keys_dirs;
	return 0 unless @dirs;

	# The well-known tree is one tree of the site, and every
	# directory writes into it.
	return 1 if $path eq SECURITY_TXT;
	return 1 if $path eq WKD_POLICY;

	my $hu = WKD_DIR . '/hu';
	if ( my ($hash) = $path =~ m{\A\Q$hu\E/(.+)\z} ) {
		return $hash =~ WKD_NAME ? 1 : 0;
	}

	for my $dir (@dirs) {
		my ($name) = $path =~ m{\A\Q$dir\E/(.+)\z};
		next unless defined $name;
		return 1 if $GENERATED_NAME{$name};

		# A description that did not load names no org, and
		# the key files of the output carry it. The name gives
		# its own, and Fugu::KeyDir then holds the whole
		# shape.
		my $org = $config->keys_org($dir)
		    // ( $name =~ /\A([a-z][a-z0-9]*)-/ )[0];
		next unless defined $org;

		my $keydir = Fugu::KeyDir->new( org => $org );

		return 1 if $keydir->parse_name($name);

		# A binding is the signature of one key file by
		# another key, and the directory publishes it beside
		# the two keys.
		return 1 if $keydir->parse_binding($name);
	}

	return 0;
}

# $self->paths:
#	Every path that the key directory adds to the output, relative
#	to the output directory. The list holds the copied files and
#	the generated ones. It reads no file: the description and the
#	file names decide it. The inventory of a site therefore costs
#	one directory listing and no more.
sub paths ($self)
{
	my @keys = $self->{config}->site_keys( $self->{dir} );

	my @paths = map { $self->_in_dir( $_->{name} ) } @keys;
	push @paths,
	    map { $self->_in_dir( $_->{name} ) }
	    $self->{config}->site_bindings( $self->{dir} );
	push @paths, $self->_in_dir(MANIFEST), $self->_in_dir(SIGNATURE);
	push @paths, $self->_in_dir(KEYS_FILE) if $self->_armored(@keys);
	push @paths, $self->_in_dir(INDEX_PAGE);

	my @wkd = _addresses( _published(@keys) );
	if (@wkd) {
		push @paths, WKD_DIR . "/hu/$_" for @wkd;
		push @paths, WKD_POLICY;
	}
	push @paths, SECURITY_TXT
	    if defined $self->{config}->keys_contact( $self->{dir} );

	return @paths;
}

# App::FuguWeb::Keys->site_generated($config):
#	Every file that a build generates for the key directories of
#	the site, as a hash reference of output path to bytes. The
#	method answers the reference, or undef with the reason behind
#	it.
#
#	The site holds one well-known tree, and each directory writes
#	into it. The Web Key Directory file of one address therefore
#	gathers the keys of that address across every directory, in
#	publication order, per WEB-KEYS-14. The order of one address
#	comes from the keys themselves and never from the directory
#	that holds them, so a retired key of one directory trails a
#	current key of the other.
#
#	One block alone names the contact, per WEB-KEYS-3, so one
#	directory writes security.txt. One policy file names the site,
#	and this method writes it beside the addresses.
#
#	This method holds the address rule alone. _generated answers
#	the files of one directory, and the keys of its addresses
#	beside them, so each directory is read and ordered once.
sub site_generated ( $class, $config )
{
	my ( %out, %wkd );
	for my $dir ( $config->keys_dirs ) {
		my $keys = $class->new( config => $config, dir => $dir );

		my ( $made, $addressed ) = $keys->_generated;
		return ( undef, "$dir: " . $keys->error ) unless $made;

		$out{$_} = $made->{$_} for keys %$made;
		push @{ $wkd{ $_->{wkd} } }, $_ for @{$addressed};
	}

	# WEB-KEYS-28. An address whose keys are all retired serves no
	# file, and the rule reads that address across the site.
	my $served = 0;
	for my $hash ( sort keys %wkd ) {
		my @live = _published( @{ $wkd{$hash} } ) or next;

		$out{ WKD_DIR . "/hu/$hash" } = join '',
		    map { $_->{bytes} } sort { _publication( $a, $b ) } @live;
		$served = 1;
	}

	$out{ WKD_POLICY() } = _policy($config) if $served;

	return \%out;
}

# $self->copies:
#	Every file that the build copies as it stands, as a list of
#	hash references with from and to. The from is a path in the
#	checkout, and the to is relative to the output directory.
sub copies ($self)
{
	my $config = $self->{config};

	my @names = (
		( map { $_->{name} } $config->site_keys( $self->{dir} ) ),
		( map { $_->{name} } $config->site_bindings( $self->{dir} ) ),
		MANIFEST,
		SIGNATURE
	);

	return map {
		{
			from => $config->keys_path( $self->{dir}, $_ ),
			to   => $self->_in_dir($_) }
	} @names;
}

# $self->generated:
#	Every file that the build writes itself for this directory, as
#	a hash reference of output path to bytes. The method returns
#	undef on a failure, and error holds the reason.
#
#	The Web Key Directory files of the site are not among them:
#	one address can hold a key of every directory, so
#	site_generated writes that tree.
sub generated ($self)
{
	my ($out) = $self->_generated;

	return $out;
}

# $self->_generated:
#	The files of this directory, as a hash reference of output
#	path to bytes, and the keys that its addresses serve, as an
#	array reference. The method returns the two, or the empty list
#	on a failure, and error holds the reason.
#
#	The key set reaches Fugu::KeyDir with the armored body of each
#	OpenPGP key, because the KEYS file holds that body.
sub _generated ($self)
{
	$self->{error} = undef;

	my $set = $self->key_set or return;
	my %out;

	my $ordered = $self->{keydir}->order($set)
	    or return $self->_fail( $self->{keydir}->error );

	# The armor guards of Fugu::KeyDir run here, and they refuse a
	# block that is not a public key. A build that copied first
	# would leave a private key in the output of a failed build.
	if ( $self->_armored(@$set) ) {
		my $text = $self->{keydir}->keys_file($set);
		return $self->_fail( $self->{keydir}->error )
		    unless defined $text;
		$out{ $self->_in_dir(KEYS_FILE) } = $text;
	}

	# The guards of keys_file read the armored text. They hold the
	# block type and the delimiters, and they decode nothing, so a
	# body with a broken base64 or a broken checksum passes them.
	# The decoder is what proves that the bytes are a key.
	for my $key ( grep { $_->{type} eq 'openpgp' } @$ordered ) {
		my $binary = $self->{openpgp}->decode_armor( $key->{armor} );
		return $self->_fail(
			"$key->{name}: " . $self->{openpgp}->error )
		    unless defined $binary;
	}

	my $rows = $self->{keydir}->index_data($set)
	    or return $self->_fail( $self->{keydir}->error );
	$self->_describe( $rows, $set ) or return;
	$out{ $self->_in_dir(INDEX_PAGE) } =
	    $self->_index_page( $rows, $self->_by_target );

	# One address holds every key of that address, in publication
	# order. A rotation gives one address a current key and a next
	# key, and a reader takes the whole file.
	#
	# One address can hold a key of every directory, so the caller
	# gathers these keys with the keys of each other directory.
	my $addressed = $self->_wkd_keys($ordered) or return;

	if ( defined $self->{config}->keys_contact( $self->{dir} ) ) {
		my $text = $self->_security_txt($ordered) or return;
		$out{ SECURITY_TXT() } = $text;
	}

	return ( \%out, $addressed );
}

# $self->key_set:
#	The key set for Fugu::KeyDir: every key block of the
#	description, with the bytes of each key that a later read
#	needs. An OpenPGP key carries its armored body, and a
#	certificate the DER that its PEM block holds. The method
#	returns undef on a failure, and error holds the reason.
#
#	WEB-KEYS-26. The reader of each type runs here, before one
#	byte reaches the output.
sub key_set ($self)
{
	$self->{error} = undef;

	my @set;
	for my $key ( $self->{config}->site_keys( $self->{dir} ) ) {
		my %entry = %$key;

		my $path =
		    $self->{config}->keys_path( $self->{dir}, $key->{name} );
		my $bytes = Fugu::File->read($path);
		return $self->_fail("cannot read $path") unless defined $bytes;

		if ( $key->{type} eq 'openpgp' ) {
			$entry{armor} = $bytes;
		}
		elsif ( $key->{type} eq 'x509' ) {

			# WEB-X509-1. The decoder takes one CERTIFICATE
			# block, so a file that holds a private key or
			# a second block fails here. It needs no
			# openssl(1). A build that copied first would
			# publish the private half of a signing
			# identity.
			my $der = $self->{x509}->decode_pem($bytes)
			    or return $self->_fail(
				"$key->{name}: " . $self->{x509}->error );

			$entry{der} = $der;
		}
		else {
			my $why = _signify_problem($bytes);
			return $self->_fail("$key->{name}: $why")
			    if defined $why;
		}

		push @set, \%entry;
	}

	return $self->_fail('the description holds no key block')
	    unless @set;

	return \@set;
}

# $self->problems(%args):
#	What the key directory of the checkout is not true of, each
#	one a sentence that names the file. An empty list means the
#	directory is good.
#
#	%args:
#		expiry => 0	leave out the validity rules of
#				WEB-OPENPGP-4 and WEB-X509-6
#
#	The checks read the source directory and not the output. A
#	stray file and a stale digest are faults of the checkout, and
#	the answer must not depend on a build having run.
#
#	The method verifies each binding, per WEB-TRUST-9. It verifies
#	no SHA256.sig, per WEB-KEYS-33. That one is the work of a
#	consumer install: the site build cannot sign, so a site that
#	verified its own manifest would prove nothing.
#
#	The clock decides the validity rules of WEB-OPENPGP-4 and
#	WEB-X509-6, and no step of the rotation can make a key expire
#	later. A caller that reads back the work of one step therefore
#	leaves them out, and it reads the bytes that the step wrote
#	alone. An expired current key is still current at that read,
#	so a step of its purpose could never be made. The 30-day
#	report reads the whole directory, so it would fail a step of
#	another purpose, which writes no next key of the purpose that
#	it names. App::FuguWeb::Rotate::_accept holds both reasons.
sub problems ( $self, %args )
{
	my $config = $self->{config};
	my $dir    = $self->{dir};

	my @keys     = $config->site_keys( $self->{dir} );
	my @problems = $self->_stray_files( \@keys );

	# Every rule below reads the whole set, so one unreadable key
	# would report the same fault once for each rule.
	my $set = $self->key_set;
	return ( @problems, "$dir: " . $self->error ) unless $set;

	unless ( $self->{keydir}->check_statuses($set) ) {
		push @problems, "$dir: " . $self->{keydir}->error;
	}

	push @problems, $self->_root_problems($set);
	push @problems, $self->_binding_problems($set);
	push @problems, $self->_manifest_problems( \@keys );
	push @problems, $self->_signature_problems;
	push @problems, $self->_fingerprint_problems($set);
	push @problems, $self->_encryption_problems($set);
	push @problems, $self->_expiry_problems($set)
	    if $args{expiry} // 1;

	return @problems;
}

# $self->_encryption_problems($set):
#	The rule of WEB-KEYS-15 that reads the whole site. The block
#	that names the contact writes security.txt, and the
#	Encryption field names the current OpenPGP key of that block.
#
#	A block that names a url and holds no such key writes no
#	field, and a key of another directory cannot fill it: each
#	directory holds its own root of trust, per D-02, and a binding
#	never crosses a directory. A site that publishes no OpenPGP
#	key at all writes no field either, and that one is no
#	problem, so the report needs a key of another directory.
sub _encryption_problems ( $self, $set )
{
	my $config = $self->{config};
	my $dir    = $self->{dir};

	return () unless defined $config->keys_contact($dir);
	return () unless defined $config->keys_url($dir);
	return () if _current_openpgp($set);

	my @elsewhere;
	for my $other ( $config->keys_dirs ) {
		next if $other eq $dir;

		my $key = _current_openpgp( [ $config->site_keys($other) ] )
		    or next;
		push @elsewhere, "$other/$key->{name}";
	}

	return () unless @elsewhere;

	return
	      "$dir: it names a url and no current OpenPGP key, so"
	    . ' security.txt carries no Encryption field, and '
	    . join( ' and ', @elsewhere )
	    . ' holds one';
}

# _current_openpgp($keys):
#	The first current OpenPGP key of a key list, or undef when the
#	list holds none.
sub _current_openpgp ($keys)
{
	my ($key) =
	    grep { $_->{type} eq 'openpgp' && $_->{status} eq 'current' }
	    @$keys;

	return $key;
}

# $self->_root_problems($set):
#	The root rule of WEB-TRUST-1. One signify key of the directory
#	is the root of trust, its purpose word is root, and its
#	current key signs the manifest. A directory with no such key
#	has no anchor, and every binding of it names a target that no
#	consumer can pin.
#
#	The method reports an absent root alone. Two current keys of
#	one purpose is the fault that check_statuses names, and one
#	fault reads better than two.
sub _root_problems ( $self, $set )
{
	my $dir = $self->{dir};

	my ($root) = _current_root($set);
	unless ($root) {
		return
		      "$dir: it holds no current key of the purpose "
		    . ROOT_PURPOSE
		    . ', and that key is the root of trust of the directory';
	}

	return () if $root->{type} eq 'signify';

	return "$dir/$root->{name}: the root key is a $root->{type} key,"
	    . ' and the root of trust is a signify key';
}

# $self->_binding_problems($set):
#	The rules of a binding, per WEB-TRUST-3, WEB-TRUST-9 and
#	WEB-TRUST-10. Each key in force of a subordinate purpose must
#	hold a binding over the current root. Each binding must verify
#	against the public key of its signer, and each one must hold
#	the retention rule of Fugu::KeyDir.
#
#	The last two rules read the root. A directory with no root has
#	one fault, which _root_problems names, so both stay unread
#	there.
sub _binding_problems ( $self, $set )
{
	my @bindings = $self->{config}->site_bindings( $self->{dir} );

	my $dir      = $self->{dir};
	my @problems = map { $self->_binding_verified($_) } @bindings;

	my ($root) = _current_root($set);
	return @problems unless $root;

	push @problems, $self->_unbound_problems( $set, \@bindings, $root );

	my @names = map { $_->{name} } @bindings;
	return @problems
	    if $self->{keydir}->check_bindings( $set, \@names, $root->{name} );

	return ( @problems, "$dir: " . $self->{keydir}->error );
}

# $self->_unbound_problems($set, $bindings, $root):
#	Each current key and each next key of a subordinate purpose
#	that holds no binding over the current root, per WEB-TRUST-3.
#
#	That signature proves that the holder of the root also holds
#	the subordinate key. A directory that publishes a key without
#	one gives a consumer no way to reach that key from the root.
sub _unbound_problems ( $self, $set, $bindings, $root )
{
	my $dir = $self->{dir};

	my %attests;
	for my $binding (@$bindings) {
		next unless $binding->{target} eq $root->{name};
		$attests{ $binding->{signer} } = 1;
	}

	my @problems;
	for my $key (@$set) {
		next if $key->{purpose} eq ROOT_PURPOSE;
		next if $key->{status} eq 'retired';
		next if $attests{ $key->{name} };

		push @problems,
		    "$dir/$key->{name}: the $key->{status} key holds no"
		    . " binding over the current root key $root->{name}";
	}

	return @problems;
}

# $self->_binding_verified($binding):
#	The reason that a binding does not verify against the public
#	key of its signer, or the empty list when it does.
#
#	The verifier of the type comes from the Fugu library, and each
#	class follows Fugu::Signer, so one call shape reads all three.
#	A signify binding needs no command.
sub _binding_verified ( $self, $binding )
{
	my $config = $self->{config};
	my $dir    = $self->{dir};
	my $name   = $binding->{name};

	my $class = $VERIFIER{ $binding->{type} }
	    or return "$dir/$name: no verifier reads a $binding->{type}"
	    . ' signature';

	# An absent command is a problem of the host, and the walk of
	# the verifier reports it in the reason of the call. The check
	# therefore needs no second test for one: a binding that
	# nothing read must never pass.
	my $signer = $class->new;

	return ()
	    if $signer->verify(
		keys =>
		    [ $config->keys_path( $self->{dir}, $binding->{signer} ) ],
		file => $config->keys_path( $self->{dir}, $binding->{target} ),
		signature => $config->keys_path( $self->{dir}, $name ),
	    );

	return "$dir/$name: " . $signer->error;
}

# _current_root($set):
#	The current key of the root purpose, or the empty list.
sub _current_root ($set)
{
	return
	    grep { $_->{purpose} eq ROOT_PURPOSE && $_->{status} eq 'current' }
	    @$set;
}

# $self->_stray_files($keys):
#	Every name in the source directory that no key block names.
#	The manifest pair names no key, and every other name must be
#	a key file with a block. A key that the description forgot
#	reaches no output. A reader of the directory would still take
#	that key for published.
sub _stray_files ( $self, $keys )
{
	my $config = $self->{config};
	my $dir    = $self->{dir};

	my $names = App::FuguWeb::list_dir( $config->keys_path( $self->{dir} ) )
	    or return "$dir: cannot read the key directory: $!";

	my %key = map { $_->{name} => 1 } @$keys;

	my %declared = %key;
	$declared{ $_->{name} } = 1 for $config->site_bindings( $self->{dir} );

	my @problems;
	for my $name (@$names) {
		next if $NOT_A_KEY{$name};
		next if $declared{$name};

		# A binding needs no key block: its name holds the
		# target and the signer, and App::FuguWeb::Config keeps
		# a binding whose two keys the description names. One
		# that reaches here therefore names a key that no block
		# names, per WEB-KEYS-18.
		if ( my $parts = $self->{keydir}->parse_binding($name) ) {
			for my $part (qw(target signer)) {
				next if $key{ $parts->{$part} };
				push @problems,
				      "$dir/$name: it names the $part"
				    . " $parts->{$part}, and no key block"
				    . ' names it';
			}
			next;
		}

		# The name pattern comes first, because a name that no
		# block names and that no pattern matches is one fault
		# and not two.
		unless ( $self->{keydir}->parse_name($name) ) {
			push @problems, "$dir/$name: " . $self->{keydir}->error;
			next;
		}

		push @problems, "$dir/$name: no key block names it";
	}

	return @problems;
}

# $self->_manifest_problems($keys):
#	The manifest names every key file and every binding file, with
#	the digest that the file has, and it names nothing else. A
#	digest that disagrees with its file is the fault that the tier
#	of scripts/deps rests on.
#	The check therefore reads the bytes, and never the size or the
#	time.
sub _manifest_problems ( $self, $keys )
{
	my $config = $self->{config};
	my $dir    = $self->{dir};
	my $path   = $config->keys_path( $self->{dir}, MANIFEST );

	my $bytes = Fugu::File->read($path);
	return "$dir/" . MANIFEST . ': cannot read it'
	    unless defined $bytes;

	# The parser is the one of the consumer install, so the site
	# and the install can never disagree about a line. The object
	# runs no command for a parse.
	my $signify = Fugu::Signify->new;

	my $digest = $signify->parse_manifest($bytes);
	return "$dir/" . MANIFEST . ': ' . $signify->error
	    unless $digest;

	# WEB-TRUST-6. The manifest pins the bytes of every key file
	# and of every binding file, and it names nothing else.
	my @files = (
		( map { $_->{name} } @$keys ),
		( map { $_->{name} } $config->site_bindings( $self->{dir} ) ) );

	my @problems;
	my %named;
	for my $name (@files) {
		$named{$name} = 1;

		my $recorded = $digest->{$name};
		unless ( defined $recorded ) {
			push @problems,
			    "$dir/" . MANIFEST . ": it does not name $name";
			next;
		}

		my $found =
		    _digest_of( $config->keys_path( $self->{dir}, $name ) );
		unless ( defined $found ) {
			push @problems, "$dir/$name: cannot read it";
			next;
		}

		next if $found eq $recorded;
		push @problems,
		    "$dir/$name: the manifest records $recorded,"
		    . " and the file digests to $found";
	}

	push @problems,
	      "$dir/"
	    . MANIFEST
	    . ": it names $_, which is"
	    . ' no key and no binding of the directory'
	    for grep { !$named{$_} } sort keys %$digest;

	return @problems;
}

# $self->_signature_problems:
#	What the signature of the manifest is not true of. The
#	consumer install reads these bytes with signify(1), and a file
#	of another shape fails there and never here.
sub _signature_problems ($self)
{
	my $config = $self->{config};
	my $dir    = $self->{dir};

	my $bytes =
	    Fugu::File->read( $config->keys_path( $self->{dir}, SIGNATURE ) );
	return "$dir/" . SIGNATURE . ': cannot read it'
	    unless defined $bytes;

	my $why = _signature_problem($bytes);

	return defined $why ? "$dir/" . SIGNATURE . ": $why" : ();
}

# $self->_fingerprint_problems($set):
#	The declared fingerprint of a key equals the one that its own
#	bytes give, per WEB-KEYS-22 and WEB-X509-4. A key block that
#	declares none is not a fault. The fingerprint is a convenience
#	for a reader, and the digest of the manifest is what binds the
#	bytes.
#
#	App::FuguWeb::Config takes a fingerprint on an OpenPGP key and
#	on a certificate alone, so no signify key reaches this rule.
sub _fingerprint_problems ( $self, $set )
{
	my $dir = $self->{dir};

	my @problems;
	for my $key (@$set) {
		next unless defined $key->{fingerprint};

		my ( $found, $why ) = $self->_fingerprint_of($key);
		unless ( defined $found ) {
			push @problems, "$dir/$key->{name}: $why";
			next;
		}

		next if $found eq $key->{fingerprint};
		push @problems,
		    "$dir/$key->{name}: the description declares"
		    . " $key->{fingerprint}, and the key gives $found";
	}

	return @problems;
}

# $self->_fingerprint_of($key):
#	The fingerprint that the bytes of a key give, or undef with
#	the reason behind it.
#
#	The fingerprint of an OpenPGP key covers its public key
#	packet, and the fingerprint of a certificate is the SHA-256 of
#	its DER form. The two therefore differ in width, and the
#	description reader holds each one to its own. Each read needs
#	no command.
sub _fingerprint_of ( $self, $key )
{
	if ( $key->{type} eq 'openpgp' ) {
		my $binary = $self->{openpgp}->decode_armor( $key->{armor} )
		    or return ( undef, $self->{openpgp}->error );

		my $found = $self->{openpgp}->fingerprint($binary)
		    or return ( undef, $self->{openpgp}->error );

		return $found;
	}

	my $found = $self->{x509}->fingerprint( $key->{der} )
	    or return ( undef, $self->{x509}->error );

	return $found;
}

# $self->_expiry_problems($set):
#	The validity rules of WEB-OPENPGP-4 and WEB-X509-6. A current
#	or next key whose expiry has passed is a problem, and so is a
#	certificate whose notBefore has not come. A current key that
#	expires within EXPIRY_WARNING is a problem when its purpose
#	holds no next key, because one rotation runs in two steps and
#	the consumers need the gap between them.
#
#	A signify key carries no date, and it reaches no rule. An
#	OpenPGP key with no expiry reaches none either: the key
#	directory retires a key with an until date, and the machine
#	rotates, per WEB-OPENPGP-3.
#
#	An absent command is a problem of the host, and the reason of
#	the call names it: a key that nothing read must never pass.
sub _expiry_problems ( $self, $set )
{
	my $dir = $self->{dir};
	my $now = time;

	my %successor;
	for my $key (@$set) {
		$successor{ $key->{purpose} } = 1 if $key->{status} eq 'next';
	}

	my @problems;
	for my $key (@$set) {
		next if $key->{type} eq 'signify';
		next
		    unless $key->{status} eq 'current'
		    || $key->{status} eq 'next';

		my ( $window, $why ) = $self->_validity($key);
		unless ($window) {
			push @problems, "$dir/$key->{name}: $why";
			next;
		}

		if ( $window->{start} > $now ) {
			push @problems,
			      "$dir/$key->{name}: the $key->{status} key is"
			    . ' not valid before '
			    . _utc_date( $window->{start} );
			next;
		}

		# 0 is the end of a key that never expires, and an
		# epoch is the end of a key that does.
		next unless $window->{end};

		if ( $window->{end} <= $now ) {
			push @problems,
			    "$dir/$key->{name}: the $key->{status} key expired"
			    . ' on '
			    . _utc_date( $window->{end} );
			next;
		}

		next unless $key->{status} eq 'current';
		next if $successor{ $key->{purpose} };
		next if $window->{end} > $now + EXPIRY_WARNING;

		push @problems,
		      "$dir/$key->{name}: the current key expires on "
		    . _utc_date( $window->{end} )
		    . ", and the purpose $key->{purpose} holds no next key";
	}

	return @problems;
}

# $self->_validity($key):
#	The window in which a key is valid, as a hash reference with
#	start and end, or undef with the reason behind it. Each value
#	is an epoch: a start of 0 has passed already, and an end of 0
#	never comes.
#
#	gpg(1) reports the expiry that an OpenPGP key carries, and an
#	OpenPGP key is valid from the moment that it exists, so that
#	read answers the end alone. The dates of a certificate come
#	from its own DER, and that read needs no openssl(1).
sub _validity ( $self, $key )
{
	if ( $key->{type} eq 'openpgp' ) {
		my $path =
		    $self->{config}->keys_path( $self->{dir}, $key->{name} );

		my $expiry = $self->{openpgp}->expiry( public => $path );
		return ( undef, $self->{openpgp}->error )
		    unless defined $expiry;

		return { start => 0, end => $expiry };
	}

	my $certificate = $self->{x509}->parse( $key->{der} )
	    or return ( undef, $self->{x509}->error );

	return {
		start => $certificate->{not_before},
		end   => $certificate->{not_after},
	};
}

# _utc_date($epoch):
#	One date of an expiry, in UTC. The key directory writes each
#	date of a key block the same way, per WEB-ROTATE-16, so a
#	reader compares the two without a conversion.
sub _utc_date ($epoch)
{
	return POSIX::strftime( '%Y-%m-%d', gmtime $epoch );
}

# $self->_describe($rows, $set):
#	Add the subject and the validity dates of each certificate to
#	its row of the human page, per WEB-X509-5. The method answers
#	1, or undef with the reason in error.
#
#	A reader of the page compares the subject with what a signed
#	binary reports. The fingerprint names one certificate, and it
#	changes at each renewal, so the subject is what holds across
#	one.
#
#	Fugu::KeyDir holds no certificate, so the two fields join the
#	rows here. The row of every other type carries neither, and
#	the page writes an empty cell for one.
sub _describe ( $self, $rows, $set )
{
	my %der =
	    map { $_->{name} => $_->{der} }
	    grep { $_->{type} eq 'x509' } @$set;

	for my $row (@$rows) {
		my $der = $der{ $row->{name} } or next;

		my $certificate = $self->{x509}->parse($der)
		    or return $self->_fail(
			"$row->{name}: " . $self->{x509}->error );

		$row->{subject} = _name_text( $certificate->{subject} );
		$row->{validity} =
		      _utc_date( $certificate->{not_before} ) . ' to '
		    . _utc_date( $certificate->{not_after} );
	}

	return 1;
}

# _name_text($name):
#	One line for the distinguished name of a certificate: each
#	attribute type with its value. Fugu::X509 answers a hash, so
#	the type sorts the line and two builds write one byte
#	sequence.
sub _name_text ($name)
{
	return join ', ', map { "$_=$name->{$_}" } sort keys %$name;
}

# $self->_index_page($rows, $by_target):
#	The human page of the directory, as a whole HTML document. The
#	page carries the chrome of the site. It sits one directory
#	below the root, so every link of the chrome takes the step
#	back.
sub _index_page ( $self, $rows, $by_target )
{
	my $page = App::FuguWeb::Page->new(
		config => $self->{config},
		base   => '../'
	);

	return $page->document( 'Keys', _index_body( $rows, $by_target ) );
}

# $self->_by_target:
#	The bindings of the directory, by the key file that each one
#	targets. The human page lists each binding under its target,
#	so a reader of one key sees every key that attests it, per
#	WEB-TRUST-11.
sub _by_target ($self)
{
	my %by;
	push @{ $by{ $_->{target} } }, $_
	    for $self->{config}->site_bindings( $self->{dir} );

	return \%by;
}

# _policy($config):
#	The policy file of the Web Key Directory. The file carries no
#	flag, and the draft of the service reads a line that starts
#	with a number sign as a comment. An empty file would pass no
#	check of the site that tells a written file from a missing
#	one.
#
#	One site serves one policy file, and every key directory of
#	the site writes into that one tree. The line therefore names
#	the site, and it names no org word.
sub _policy ($config)
{
	return
	      '# The Web Key Directory of '
	    . $config->site
	    . ". It sets no policy flag.\n";
}

# $self->_security_txt($set):
#	The text of security.txt. The Encryption field points at the
#	current OpenPGP key. A site that publishes no such key, or
#	that names no url, writes no such field.
sub _security_txt ( $self, $ordered )
{
	my $config = $self->{config};

	# The first current OpenPGP key of the publication order. A
	# site with two OpenPGP purposes names the newest current key
	# of them, because the order sorts the serial down inside one
	# status.
	my $encryption;
	my $url = $config->keys_url( $self->{dir} );
	if ( defined $url ) {
		my ($current) =
		    grep {
			       $_->{type} eq 'openpgp'
			    && $_->{status} eq 'current'
		    } @$ordered;
		$encryption = "$url/$current->{name}" if $current;
	}

	my $text = $self->{keydir}->security_txt(
		contact    => $config->keys_contact( $self->{dir} ),
		expires    => $config->keys_expires( $self->{dir} ),
		encryption => $encryption
	);

	return defined $text ? $text : $self->_fail( $self->{keydir}->error );
}

# $self->_in_dir($name):
#	The path of one name of the key directory, relative to the
#	output directory.
sub _in_dir ( $self, $name )
{
	return $self->{dir} . "/$name";
}

# $self->_armored(@keys):
#	Report whether the set holds an OpenPGP key. The KEYS file
#	holds those keys only, so a set with none writes no such file
#	and the inventory names none.
sub _armored ( $self, @keys )
{
	return scalar grep { $_->{type} eq 'openpgp' } @keys;
}

# _published(@keys):
#	Every OpenPGP key that the Web Key Directory serves. A key
#	with no email address has no address to answer for, so the
#	directory holds no file for it.
#
#	An address whose keys are all retired serves nothing. gpg
#	--locate-keys reads the file to encrypt a message, and a
#	retired key is the one key that must not answer that. A
#	retired key beside a current one still serves, because the
#	current key leads the file.
sub _published (@keys)
{
	my @named =
	    grep { $_->{type} eq 'openpgp' && defined $_->{email} } @keys;

	my %live;
	for my $key (@named) {
		$live{ $key->{wkd} } = 1 if $key->{status} ne 'retired';
	}

	return grep { $live{ $_->{wkd} } } @named;
}

# $self->_wkd_keys($ordered):
#	Each key of the ordered set that the Web Key Directory can
#	serve, with the binary body of that key in bytes. The method
#	returns undef on a failure, and error holds the reason.
#
#	A key with no email address has no address to answer for, so
#	the directory holds no file for it.
sub _wkd_keys ( $self, $ordered )
{
	my @out;
	for my $key (@$ordered) {
		next
		    unless $key->{type} eq 'openpgp'
		    && defined $key->{email};

		my $binary = $self->{openpgp}->decode_armor( $key->{armor} );
		return $self->_fail(
			"$key->{name}: " . $self->{openpgp}->error )
		    unless defined $binary;

		push @out, { %$key, bytes => $binary };
	}

	return \@out;
}

# _publication($one, $two):
#	Order two keys as Fugu::KeyDir orders the keys of one
#	directory: the status first, then the serial from the highest
#	down, then the purpose and the name.
#
#	One address can hold a key of each key directory, and two
#	directories carry two organization words, so Fugu::KeyDir
#	cannot order that set: it parses each name against one word.
#	The vocabulary stays there all the same, and this module reads
#	the rank from it.
sub _publication ( $one, $two )
{
	return
	       $STATUS_RANK{ $one->{status} } <=> $STATUS_RANK{ $two->{status} }
	    || $two->{serial}                 <=> $one->{serial}
	    || $one->{purpose}                cmp $two->{purpose}
	    || $one->{name}                   cmp $two->{name};
}

# _signify_problem($bytes):
#	The reason that a file is not a signify public key, or undef
#	when it is one.
#
#	The extension of a key file gives its type, so a name that
#	ends in .pub is a signify key by its name alone. Nothing else
#	reads those bytes: the guards of Fugu::KeyDir hold an OpenPGP
#	key and skip every other type. A file of any content would
#	therefore publish under that name, a private key of any kind
#	included.
#
#	A signify public key holds two lines. The first line starts
#	with 'untrusted comment: ', which signify(1) needs. The second
#	line is the key body: 42 bytes in base64, and the first two
#	bytes spell Ed.
sub _signify_problem ($bytes)
{
	my @line = split /\n/, $bytes, -1;
	pop @line if @line && $line[-1] eq '';

	unless ( @line == 2 ) {
		return
		      'it holds '
		    . scalar(@line)
		    . ' lines, and a signify public key holds 2';
	}

	unless ( $line[0] =~ /\Auntrusted comment: / ) {
		return 'the first line is no untrusted comment line';
	}

	unless ( $line[1] =~ m{\A[A-Za-z0-9+/]{56}\z} ) {
		return 'the key body is not 56 base64 characters';
	}

	my $raw = MIME::Base64::decode_base64( $line[1] );
	unless ( length($raw) == 42 ) {
		return
		      'the key body decodes to '
		    . length($raw)
		    . ' bytes, and a signify key holds 42';
	}

	unless ( substr( $raw, 0, 2 ) eq 'Ed' ) {
		return 'the key body names no signify algorithm';
	}

	return;
}

# _signature_problem($bytes):
#	The reason that a file is not a signify signature, or undef
#	when it is one.
#
#	The build copies the signature as it stands, and it verifies
#	nothing: a site that verified its own manifest would prove
#	nothing. A file of any content would therefore publish under
#	the name that every consumer install reads.
#
#	A signify signature holds two lines. The first line starts
#	with 'untrusted comment: ', which signify(1) needs. The second
#	line is the signature body: 100 base64 characters, which
#	decode to 74 bytes whose first two bytes spell Ed.
sub _signature_problem ($bytes)
{
	my @line = split /\n/, $bytes, -1;
	pop @line if @line && $line[-1] eq '';

	unless ( @line == 2 ) {
		return
		      'it holds '
		    . scalar(@line)
		    . ' lines, and a signify signature holds 2';
	}

	unless ( $line[0] =~ /\Auntrusted comment: / ) {
		return 'the first line is no untrusted comment line';
	}

	# 99 characters and one pad always decode to 74 bytes, so the
	# length needs no second test. A key body needs one, because
	# 56 characters carry no pad and decode to 42.
	unless ( $line[1] =~ m{\A[A-Za-z0-9+/]{99}=\z} ) {
		return 'the signature body is not 100 base64 characters';
	}

	my $raw = MIME::Base64::decode_base64( $line[1] );
	unless ( substr( $raw, 0, 2 ) eq 'Ed' ) {
		return 'the signature body names no signify algorithm';
	}

	return;
}

# _addresses(@keys):
#	The Web Key Directory hash of each key, once for each hash, in
#	the order that the keys arrive. Two keys of one address share
#	one published path.
sub _addresses (@keys)
{
	my %seen;

	return grep { !$seen{$_}++ } map { $_->{wkd} } @keys;
}

# $self->_fail($reason):
#	Record the reason and return undef, so each public method
#	fails the same way.
sub _fail ( $self, $reason )
{
	$self->{error} = $reason;

	return;
}

# _index_body($rows, $by_target):
#	The body fragment of the human page: one row for each key, in
#	publication order. Every value is escaped, and a value that
#	the description left out becomes an empty cell.
#
#	The subject and the validity cells hold the two facts of a
#	certificate, per WEB-X509-5, and a key of another type leaves
#	them empty.
#
#	The last cell of a row holds the bindings of that key, per
#	WEB-TRUST-11. Each one names its signer and links its file, so
#	a reader fetches the signature beside the key that it covers.
sub _index_body ( $rows, $by_target )
{
	my @head = (
		'Key',    'Purpose',     'Serial',  'Type',
		'Status', 'Fingerprint', 'Subject', 'Validity',
		'Since',  'Until',       'Bindings'
	);

	my $html = "<h1>Keys</h1>\n<table>\n<thead>\n<tr>";
	$html .= "<th>$_</th>" for @head;
	$html .= "</tr>\n</thead>\n<tbody>\n";

	for my $row (@$rows) {
		my $href = App::FuguWeb::escape_attr( $row->{name} );
		my $stem = App::FuguWeb::escape_html( $row->{stem} );

		$html .= qq{<tr><td><a href="$href">$stem</a></td>};
		$html .= '<td>' . _cell( $row->{$_} ) . '</td>'
		    for qw(purpose serial type status fingerprint
		    subject validity since until);
		$html .= '<td>'
		    . _bindings( $by_target->{ $row->{name} } ) . "</td>";
		$html .= "</tr>\n";
	}

	return $html . "</tbody>\n</table>\n";
}

# _bindings($bindings):
#	The binding cell of one key: one link for each binding, named
#	by the signer of it. A key that no binding covers gives an
#	empty cell, so the row keeps its column count.
sub _bindings ($bindings)
{
	return '' unless $bindings;

	my @link;
	for my $binding ( sort { $a->{name} cmp $b->{name} } @$bindings ) {
		my $href = App::FuguWeb::escape_attr( $binding->{name} );
		my $stem = App::FuguWeb::escape_html(
			$binding->{signer} =~ s/\.[^.]+\z//r );

		push @link, qq{<a href="$href">$stem</a>};
	}

	return join ', ', @link;
}

# _cell($value):
#	One table cell. A value that the description left out becomes
#	an empty cell, so a template tests one thing and the row keeps
#	its column count.
sub _cell ($value)
{
	return defined $value ? App::FuguWeb::escape_html($value) : '';
}

# _digest_of($path):
#	The lowercase hex SHA256 digest of the file, or undef when the
#	file does not open. addfile reads in blocks, so the check
#	never holds a whole key set in memory.
sub _digest_of ($path)
{
	open my $fh, '<', $path or return;
	binmode $fh;

	my $sha = Digest::SHA->new(256);
	$sha->addfile($fh);
	close $fh;

	return lc $sha->hexdigest;
}

1;
