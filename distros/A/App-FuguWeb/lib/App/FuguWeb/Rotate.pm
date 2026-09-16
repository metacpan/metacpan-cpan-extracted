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

package App::FuguWeb::Rotate;
our $VERSION = '0.6.2';

use App::FuguWeb;
use App::FuguWeb::Config;
use App::FuguWeb::Keys;
use Digest::SHA ();
use File::Temp  ();
use Fugu::File;
use Fugu::KeyDir;
use Fugu::OpenPGP;
use Fugu::Signify;
use Fugu::X509;
use POSIX       ();
use Time::Local ();

# App::FuguWeb::Rotate - write the key directory of a site, per
# WEB-ROTATE and WEB-TRUST.
#
# App::FuguWeb::Keys reads the directory, and this module writes it.
# One signify key of the directory is the root of trust, and its
# purpose word is root. The current root signs the manifest, and each
# other key binds to it with a signature of its own.
#
# One rotation runs in two steps. A mint makes the next key of a
# purpose, and a promote makes that key current and retires the old
# one. An import takes a key that another tool made, and it follows
# the rules of a mint of its purpose.
#
# Every step reads the status of each key from the description, and no
# step assumes one. Every step ends with the reader: the module writes
# the directory, loads the description again, and asks
# App::FuguWeb::Keys->problems. A step that leaves one problem fails,
# so the writer can never publish a directory that the checks reject.
# That read leaves out the validity rules of WEB-OPENPGP-4 and
# WEB-X509-6 alone. The clock decides those, and _accept states why
# each one stays out.
#
# The module runs no command of its own. Fugu::Signify holds every
# call of signify(1), the class of each other key type holds every
# call of its own command, and Fugu::KeyDir holds every name.
#
# The module reaches no network and holds no token. The caller stores
# the private key and declares the public one.

# The two files of the manifest pair, which name no key.
use constant {
	MANIFEST  => 'SHA256',
	SIGNATURE => 'SHA256.sig',
};

# The purpose word of the root of trust, the default key type of
# every verb, and the default key directory of a site that names
# none. App::FuguWeb::Keys holds the root word, so the reader and the
# writer can never disagree about it.
use constant {
	ROOT => App::FuguWeb::Keys::ROOT_PURPOSE,
	TYPE => 'signify',
	DIR  => 'keys',
};

# The key type that a mint generates, per WEB-ROTATE-2 and
# WEB-OPENPGP-1. An issuer makes a certificate, so no verb mints one.
my %MINT_TYPE = (
	signify => 1,
	openpgp => 1,
);

# The key type that an import publishes, per WEB-X509-2. The step
# takes a key that another tool made, so it reads every type that a
# key directory holds.
my %IMPORT_TYPE = (
	signify => 1,
	openpgp => 1,
	x509    => 1,
);

# The signer of each key type, per WEB-TRUST-8. A binding of a key
# takes the private half of that key, so the type of the signer key
# selects the class. Each class follows Fugu::Signer, and Fugu::X509
# needs the certificate of the key as well, so _bind names it in
# every call. The other two classes ignore that argument.
my %SIGNER = (
	signify => 'Fugu::Signify',
	openpgp => 'Fugu::OpenPGP',
	x509    => 'Fugu::X509',
);

sub new ( $class, %args )
{
	my $config = $args{config};
	die "config is a necessary argument\n" unless defined $config;

	# WEB-ROTATE-21. The caller names the directory that the step
	# writes. A description with one keys block needs no name, and
	# a description with none takes the default: a site publishes
	# its first key before a block can stand.
	my @dirs = $config->keys_dirs;
	my $dir = $args{dir} // ( @dirs == 1 ? $dirs[0] : @dirs ? undef : DIR );

	# A keys block cannot load until a key block stands beside it,
	# so a directory that publishes its first key holds neither
	# yet. The caller then names the organization word, the
	# directory and the prefix, and one commit carries all of it
	# with the first key, per WEB-ROTATE-15.
	my $fresh = defined $dir && !grep { $_ eq $dir } @dirs;

	return bless {
		config       => $config,
		tool_missing => 0,
		bootstrap    => $fresh,
		asked        => $args{bootstrap} ? 1 : 0,
		dir          => $dir,
		org          => $config->keys_org($dir) // $args{org},
		url          => $config->keys_url($dir) // $args{url},
		error        => undef,
	}, $class;
}

# $self->_selected:
#	Hold a step to one key directory that it can write. The method
#	answers 1, or undef with a reason in $self->error.
#
#	WEB-ROTATE-21. A description with several keys blocks names no
#	one directory, and a step writes one. The caller names it.
#	The word names one directory below the source directory, as
#	WEB-KEYS-29 holds it. A word that held a solidus or a dot
#	would write the key outside the site.
#
#	WEB-ROTATE-22. A word that no keys block names makes a key
#	directory, with a root of trust of its own, so the caller
#	states that intent. A mistyped word would otherwise publish a
#	second root in silence, and the description of the site would
#	then name a block that holds no key file.
#
#	The list of directories comes from the description of today,
#	because a step of this object reloads it.
sub _selected ($self)
{
	my $dir = $self->{dir};
	unless ( defined $dir ) {
		return $self->_fail( 'the description holds the key'
			    . ' directories '
			    . join( ' and ', $self->{config}->keys_dirs )
			    . ', so the step needs --dir' );
	}

	return $self->_fail("the key directory $dir is not one name")
	    if $dir eq '.' || $dir eq '..' || $dir =~ m{[/\\]};

	return $self->_fail( "the description names no key directory $dir,"
		    . ' and a mint or an import makes one with --bootstrap' )
	    if $self->{bootstrap} && !$self->{asked};

	return 1;
}

# $self->config:
#	The description. A step loads it again after it writes, so a
#	caller that holds this object reads the current state.
sub config ($self) { return $self->{config}; }

# $self->error:
#	The reason of the most recent failure, or undef.
sub error ($self) { return $self->{error}; }

# $self->tool_missing:
#	True when the failure was an absent command of a key type. A
#	caller answers a missing tool with its own exit code, so a
#	script can tell it from a rotation that failed.
sub tool_missing ($self) { return $self->{tool_missing}; }

# $self->mint(%args):
#	Generate the next key of the purpose and publish its public
#	half. The method answers a hash reference of the facts, or
#	undef with a reason in $self->error.
#
#	%args:
#		purpose => $word	what the key signs
#		type    => $word	the key type, signify by default
#		secret  => $path	where the private half goes
#		signer  => $path	the private half of the root
#		bind    => \%path	one path for each bound stem
#		email   => $address	the user id of an OpenPGP key
#		expires => $date	the expiry of an OpenPGP key
#
#	An OpenPGP mint needs the email, and it takes the expiry as a
#	date of the form YYYY-MM-DD, per WEB-OPENPGP-1 and
#	WEB-OPENPGP-3. A signify mint takes neither.
sub mint ( $self, %args )
{
	$self->{error} = undef;

	return $self->_add( 'mint', %args );
}

# $self->import_key(%args):
#	Publish a key that another tool made, under the next name of
#	the purpose. The method answers a hash reference of the facts,
#	or undef with a reason in $self->error.
#
#	The step takes the options of a mint of its purpose, and
#	--file beside them, per WEB-X509-2. The caller holds the
#	private half already, so the step writes none. An issuer makes
#	a certificate, so this verb is the one that publishes one.
#
#	%args:
#		purpose => $word	what the key signs
#		type    => $word	the key type, signify by default
#		file    => $path	the public key file to publish
#		secret  => $path	the private half of that key
#		signer  => $path	the private half of the root
#		bind    => \%path	one path for each bound stem
sub import_key ( $self, %args )
{
	$self->{error} = undef;

	return $self->_add( 'import', %args );
}

# $self->promote(%args):
#	Make the next key of the purpose current, and retire the key
#	that was current. The method answers a hash reference of the
#	facts, or undef with a reason in $self->error.
#
#	%args:
#		purpose  => $word	what the key signs
#		secret   => $path	the private half of the new root
#		signer   => $path	the private half of the root
#		retiring => $path	the private half of the old key
#		bind     => \%path	one path for each bound stem
sub promote ( $self, %args )
{
	$self->{error} = undef;

	$self->_selected or return;

	my $purpose = $args{purpose};
	my $set     = $self->_set or return;

	my $next = _by_status( $set, $purpose, 'next' )
	    or return $self->_fail("the purpose $purpose holds no next key");
	my $old = _by_status( $set, $purpose, 'current' )
	    or return $self->_fail("the purpose $purpose holds no current key");

	my $root    = _by_status( $set, ROOT, 'current' );
	my $is_root = $purpose eq ROOT;

	# WEB-TRUST-4. The retiring key signs the public key file of
	# the key that takes its place, so a consumer that trusts the
	# old key reaches the new one.
	my $retiring = $args{retiring};
	return $self->_fail( "the promote writes the chain binding of $old,"
		    . ' so it needs the private half of that key as the'
		    . ' retiring key' )
	    unless defined $retiring && length $retiring;
	return $self->_fail("the retiring half $retiring is no file")
	    unless -f $retiring;

	my $bound = $self->_promote_options( $set, $is_root, $root, %args )
	    or return;

	my $keys     = $self->_key_bytes($set) or return;
	my $bindings = $self->_binding_bytes   or return;
	my $retire   = Fugu::File->read($retiring);
	return $self->_fail("cannot read $retiring") unless defined $retire;

	my %fresh;
	my ( $chain, $bytes ) =
	    $self->_bind( $next, $keys->{$next}, $old, $keys->{$old}, $retire );
	return unless defined $chain;
	$fresh{$chain} = $bytes;

	my @drop;
	if ($is_root) {

		# WEB-TRUST-7. Each key in force attests the new root,
		# and every other binding of the retired root goes.
		for my $signer ( sort keys %$bound ) {
			my ( $name, $written ) =
			    $self->_bind( $next, $keys->{$next}, $signer,
				$keys->{$signer}, $bound->{$signer} );
			return unless defined $name;
			$fresh{$name} = $written;
		}

		@drop = $self->_of_target( $set, $old );
	}
	else {
		# WEB-TRUST-5. The retired key attests the root no
		# more, and its chain binding takes the place of that
		# binding.
		my $keydir = $self->_keydir or return;
		my $gone =
		    $keydir->binding_for( target => $root, signer => $old )
		    or return $self->_fail( $keydir->error );

		push @drop, $gone if exists $bindings->{$gone};
	}
	delete $bindings->{$_} for @drop;

	# WEB-ROTATE-6. A root promote signs with the new root, and
	# every other step signs with the current root.
	my $with    = $is_root ? $args{secret} : $args{signer};
	my $private = Fugu::File->read($with);
	return $self->_fail("cannot read $with") unless defined $private;

	my ( $manifest, $signature ) = $self->_signed(
		$private,
		$is_root ? $next : $root,
		{ %$keys, %$bindings, %fresh } );
	return unless defined $manifest;

	my $today  = POSIX::strftime( '%Y-%m-%d', gmtime );
	my %change = (
		_stem_of($next) => { status => 'current' },
		_stem_of($old)  => { status => 'retired', until => $today },
	);

	my $description = $self->_with_statuses( \%change ) or return;

	my %write = (
		$self->{config}->path   => $description,
		$self->_path(MANIFEST)  => $manifest,
		$self->_path(SIGNATURE) => $signature,
	);
	$write{ $self->_path($_) } = $fresh{$_} for keys %fresh;

	return $self->_publish(
		\%write,
		[ map { $self->_path($_) } @drop ],
		{ map { $_ => $change{$_}{status} } keys %change },
		{
			name    => $next,
			stem    => _stem_of($next),
			serial  => $set->{$next}{serial},
			status  => 'current',
			retired => $old,
		} );
}

# $self->_add($verb, %args):
#	Publish one new key of the purpose: a mint generates the pair,
#	and an import reads the public half from a file. The two share
#	every rule of the trust order, so they share this method.
sub _add ( $self, $verb, %args )
{
	$self->_selected or return;

	my $purpose = $args{purpose};
	my $type    = $args{type} // TYPE;

	# WEB-ROTATE-1, WEB-ROTATE-2 and WEB-X509-2. A mint generates a
	# signify pair or an OpenPGP key, and an import publishes a key
	# of every type. An issuer makes a certificate, so a mint of
	# one fails here and never in openssl(1).
	my $known = $verb eq 'mint' ? $MINT_TYPE{$type} : $IMPORT_TYPE{$type};
	return $self->_fail("$verb-key reads no key of the type $type")
	    unless $known;

	# WEB-TRUST-1. The root of trust is a signify key, and no
	# later read of a step holds a root to that type. A first
	# root mint signs its own manifest, so it fails in
	# Fugu::Signify, which reads no OpenPGP secret half. A root
	# mint beside a current root takes the status next, and
	# _root_problems of App::FuguWeb::Keys reads the current root
	# alone, so that step publishes the key. This guard refuses
	# both, and it refuses before the step generates one byte.
	return $self->_fail( 'the root of trust is a signify key, so a '
		    . "$verb of the "
		    . ROOT
		    . " purpose takes no $type key" )
	    if $purpose eq ROOT && $type ne TYPE;

	# The organization word reaches Fugu::KeyDir before the step
	# makes one directory. A word that no key name can carry fails
	# here, and a bootstrap that names none fails with it, so a
	# failed step leaves no empty directory in the source tree.
	my $keydir = $self->_keydir or return;

	return $self->_fail( 'cannot make ' . $self->_dir )
	    unless Fugu::File->ensure_dir( $self->_dir );

	my $set = $self->_set or return;

	my ( $root, $first ) = $self->_anchor( $set, $purpose ) or return;
	my $bound = $self->_add_options( $verb, $set, $first, $root, %args )
	    or return;

	# WEB-ROTATE-5. The guard runs before the pair exists, because
	# a caller holds one place for the private half of a mint: a
	# second next key loses the private half of the first.
	if ( my $pending = _by_status( $set, $purpose, 'next' ) ) {
		return $self->_fail( "the purpose $purpose holds the next key "
			    . "$pending already, so promote it first" );
	}

	# WEB-ROTATE-3. The status comes from the purpose alone, so a
	# first key of any purpose is current at once.
	my $status =
	    _by_status( $set, $purpose, 'current' ) ? 'next' : 'current';

	my $serial = $keydir->next_serial( [ keys %$set ], $purpose )
	    or return $self->_fail( $keydir->error );
	my $name = $keydir->name_for(
		serial  => $serial,
		purpose => $purpose,
		type    => $type,
	) or return $self->_fail( $keydir->error );

	my $stem = _stem_of($name);

	# _set refuses a key file that no key block names, and
	# next_serial reads every name, so no run reaches a name that
	# stands. The guard holds that true, whatever a later change
	# makes of the scan: a step must never write over a key.
	return $self->_fail("$name exists already") if -e $self->_path($name);

	my ( $public, $private ) =
	      $verb eq 'mint'
	    ? $self->_generate( $stem, $name, $type, %args )
	    : $self->_read_pair( $args{file}, $args{secret} );
	return unless defined $public;

	# WEB-OPENPGP-2 and WEB-X509-4. The key block names the
	# fingerprint of the key that the step publishes, and the block
	# of an OpenPGP mint names its address beside it. A signify key
	# takes neither setting, per WEB-KEYS-7.
	my $settings =
	      $type eq 'openpgp'
	    ? $self->_openpgp_settings( $public, $args{email} )
	    : $type eq 'x509' ? $self->_x509_settings($public)
	    :                   [];
	return unless $settings;

	my $keys = $self->_key_bytes($set) or return;
	$keys->{$name} = $public;

	my $bindings = $self->_binding_bytes or return;

	my %fresh;
	if ($first) {

		# WEB-TRUST-7. A first root mint writes the binding of
		# each key in force, so every one of them attests the
		# new anchor.
		for my $signer ( sort keys %$bound ) {
			my ( $file, $bytes ) =
			    $self->_bind( $name, $public, $signer,
				$keys->{$signer}, $bound->{$signer} );
			return unless defined $file;
			$fresh{$file} = $bytes;
		}
	}
	elsif ( $purpose ne ROOT ) {

		# WEB-TRUST-3. The new key attests the current root,
		# and that signature proves that one holder holds both
		# private halves.
		my ( $file, $bytes ) =
		    $self->_bind( $root, $keys->{$root}, $name, $public,
			$private );
		return unless defined $file;
		$fresh{$file} = $bytes;
	}

	# WEB-ROTATE-6. A first root mint signs its own manifest, and
	# every other step signs with the current root. The signer
	# reaches the signature as bytes, so the private half of the
	# new key never lands before the step succeeds.
	my $with = $private;
	unless ($first) {
		$with = Fugu::File->read( $args{signer} );
		return $self->_fail("cannot read $args{signer}")
		    unless defined $with;
	}

	my ( $manifest, $signature ) = $self->_signed(
		$with,
		$first ? $name : $root,
		{ %$keys, %$bindings, %fresh } );
	return unless defined $manifest;

	my $description = $self->_with_block( $stem, $status, $settings )
	    or return;

	my %write = (
		$self->{config}->path   => $description,
		$self->_path($name)     => $public,
		$self->_path(MANIFEST)  => $manifest,
		$self->_path(SIGNATURE) => $signature,
	);
	$write{ $self->_path($_) } = $fresh{$_} for keys %fresh;

	# WEB-ROTATE-13. A caller declares the new key with the digest
	# and the URL, so it reads neither from the tree.
	my %facts = (
		name   => $name,
		stem   => $stem,
		serial => $serial,
		status => $status,
		digest => lc Digest::SHA::sha256_hex($public),
	);
	$facts{url} = "$self->{url}/$name"
	    if defined $self->{url} && length $self->{url};

	# WEB-ROTATE-2. The private half takes no group mode and no
	# other mode, and it lands last: a step that fails leaves no
	# key that the site does not publish. An import writes none,
	# because the caller holds that half already.
	my $last =
	    $verb eq 'mint'
	    ? { path => $args{secret}, bytes => $private, mode => 0600 }
	    : undef;

	return $self->_publish( \%write, [], { $stem => $status }, \%facts,
		$last );
}

# $self->_anchor($set, $purpose):
#	The current root key of the directory, and whether this step
#	is the first mint of the root purpose. The method answers the
#	two, or an empty list with a reason in $self->error.
#
#	WEB-ROTATE-19 and WEB-TRUST-1. One manifest covers the whole
#	directory, and the current root signs it, so a step of another
#	purpose needs that key. A directory whose keys hold no root is
#	the state of a site before its first root mint, and that one
#	step must take it.
sub _anchor ( $self, $set, $purpose )
{
	my $root  = _by_status( $set, ROOT, 'current' );
	my $first = $purpose eq ROOT && !$root;

	return ( $root, $first ) if $root || $first;

	return $self->_fail( 'the key directory holds no current key of the'
		    . ' purpose '
		    . ROOT
		    . ', which signs the manifest, so mint that key first' );
}

# $self->_add_options($verb, $set, $first, $root, %args):
#	Hold a mint and an import to the options that their purpose
#	and their key type take, and answer the private half of each
#	bound key.
#
#	WEB-ROTATE-6, WEB-ROTATE-18 and WEB-TRUST-2. Every step but a
#	first root mint signs with the current root. A mint writes the
#	private half of the key that it makes, and that file is the
#	one thing a rotation cannot make again.
sub _add_options ( $self, $verb, $set, $first, $root, %args )
{
	$self->_type_options( $verb, %args ) or return;

	my $secret = $args{secret};
	return $self->_fail("$verb-key needs the path of the private half")
	    unless defined $secret && length $secret;

	my $signer = $args{signer};
	return $self->_fail('the secret and the signer name one path')
	    if defined $signer && length $signer && $secret eq $signer;

	if ( $verb eq 'mint' ) {
		return $self->_fail( "$secret stands already, and a mint"
			    . ' writes the private half of a new key' )
		    if -e $secret;
	}
	else {
		return $self->_fail("the private half $secret is no file")
		    unless -f $secret;
	}

	if ($first) {
		return $self->_fail( 'the directory holds no root key, so the'
			    . ' new key signs its own manifest and the step'
			    . ' takes no signer' )
		    if defined $signer && length $signer;

		return $self->_bound( $set, $args{bind} );
	}

	return $self->_fail( "the current root key $root signs the manifest,"
		    . ' so the step needs the private half of that key as'
		    . ' the signer' )
	    unless defined $signer && length $signer;
	return $self->_fail("the signer $signer is no file")
	    unless -f $signer;

	return $self->_free( $args{bind} );
}

# $self->_type_options($verb, %args):
#	Hold a step to the options that its key type takes. The
#	method answers 1, or undef with a reason in $self->error.
#
#	WEB-OPENPGP-1 and WEB-OPENPGP-3. An OpenPGP mint needs the
#	email address of the user id, and it takes an optional expiry
#	date. A key of another type carries neither, and
#	App::FuguWeb::Config refuses a key block that names an email,
#	so a step of another type must refuse both here.
sub _type_options ( $self, $verb, %args )
{
	my $type = $args{type} // TYPE;

	unless ( $verb eq 'mint' && $type eq 'openpgp' ) {
		for my $only (qw(email expires)) {
			next unless defined $args{$only} && length $args{$only};
			return $self->_fail(
				"a $verb of a $type key takes no $only");
		}

		return 1;
	}

	return $self->_fail( 'an OpenPGP mint writes the address into the user'
		    . ' id of the key, so it needs the email' )
	    unless defined $args{email} && length $args{email};

	return 1 unless defined $args{expires} && length $args{expires};

	my $epoch = _epoch_of( $args{expires} );
	return $self->_fail( "the expiry $args{expires} is no date of the form"
		    . ' YYYY-MM-DD' )
	    unless defined $epoch;

	# WEB-OPENPGP-3. A key that expired already signs nothing.
	# The epoch is the start of the date in UTC, so it is above
	# the current time for a later date and below it for the day
	# of the run. Fugu::OpenPGP refuses such a date too, and its
	# reason names the epoch: the caller typed a date, and the
	# reason must name that date.
	return $self->_fail( "the expiry $args{expires} is not after the day"
		    . ' of the run' )
	    if $epoch <= time;

	return 1;
}

# $self->_promote_options($set, $is_root, $root, %args):
#	Hold a promote to the options that its purpose takes, and
#	answer the private half of each bound key.
#
#	WEB-ROTATE-6. A root promote signs the manifest with the key
#	that it makes current, so it takes no signer. Every other
#	promote signs with the current root, and it writes no key
#	file, so it takes no secret.
sub _promote_options ( $self, $set, $is_root, $root, %args )
{
	my $secret = $args{secret};
	my $signer = $args{signer};

	unless ($is_root) {
		return $self->_fail( 'the key directory holds no current key'
			    . ' of the purpose '
			    . ROOT )
		    unless $root;
		return $self->_fail( "the current root key $root signs the"
			    . ' manifest, so the promote needs the private'
			    . ' half of that key as the signer' )
		    unless defined $signer && length $signer;
		return $self->_fail("the signer $signer is no file")
		    unless -f $signer;
		return $self->_fail( 'a promote of a subordinate purpose'
			    . ' writes no key file, so it takes no secret' )
		    if defined $secret && length $secret;

		return $self->_free( $args{bind} );
	}

	return $self->_fail( 'a root promote signs with the key that it makes'
		    . ' current, so it takes no signer' )
	    if defined $signer && length $signer;
	return $self->_fail( 'the new root signs the manifest, so the promote'
		    . ' needs the private half of that key as the secret' )
	    unless defined $secret && length $secret;
	return $self->_fail("the private half $secret is no file")
	    unless -f $secret;

	return $self->_bound( $set, $args{bind} );
}

# $self->_bound($set, $bind):
#	The private half of each current and next subordinate key, by
#	key file name. The method answers a hash reference, or undef
#	with a reason in $self->error.
#
#	WEB-TRUST-7. A first root mint and a root promote write the
#	binding of each key in force again, so the step refuses before
#	it writes when one private half is absent.
sub _bound ( $self, $set, $bind )
{
	$bind //= {};

	my %want;
	for my $name ( sort keys %$set ) {
		next if $set->{$name}{purpose} eq ROOT;
		next if $set->{$name}{status} eq 'retired';
		$want{ _stem_of($name) } = $name;
	}

	for my $stem ( sort keys %want ) {
		next if defined $bind->{$stem} && length $bind->{$stem};
		return $self->_fail( 'the step writes the binding of '
			    . "$stem again, so it needs the private half of"
			    . " that key as the bound key $stem" );
	}

	for my $stem ( sort keys %$bind ) {
		next if $want{$stem};
		return $self->_fail( "the bound key $stem names no current"
			    . ' key and no next key of a subordinate'
			    . ' purpose' );
	}

	my %private;
	for my $stem ( sort keys %want ) {
		my $path = $bind->{$stem};
		return $self->_fail(
			"the private half $path of $stem is no file")
		    unless -f $path;

		my $bytes = Fugu::File->read($path);
		return $self->_fail("cannot read $path") unless defined $bytes;

		$private{ $want{$stem} } = $bytes;
	}

	return \%private;
}

# $self->_free($bind):
#	The empty bound set of a step that writes no binding of
#	WEB-TRUST-7. A bound key on such a step names a private half
#	that the step does not need, which is a caller mistake.
sub _free ( $self, $bind )
{
	return {} unless $bind && %$bind;

	return $self->_fail( 'a first root mint and a root promote take a'
		    . ' bound key, and no other step does' );
}

# $self->_of_target($set, $target):
#	Every binding of the directory that names the target, less a
#	chain binding.
#
#	WEB-TRUST-7. A root promote drops each binding of the retired
#	root, because a consumer pins the root that stands. The chain
#	binding of WEB-TRUST-4 stays published with the retired key
#	that wrote it, and a retired signer writes no other binding.
sub _of_target ( $self, $set, $target )
{
	my @drop;
	for my $binding ( $self->{config}->site_bindings( $self->{dir} ) ) {
		next unless $binding->{target} eq $target;
		next if $set->{ $binding->{signer} }{status} eq 'retired';

		push @drop, $binding->{name};
	}

	return @drop;
}

# $self->_generate($stem, $name, $type, %args):
#	A new key pair of the type, as the public bytes and the
#	private bytes. The method answers the two, or an empty list
#	with a reason in $self->error.
#
#	Each generator writes a pair of files, and the two names of a
#	pair are its own. The pair is therefore made in a temporary
#	directory, and each half then goes where it belongs. The
#	directory dies with the process, so no secret stays behind.
sub _generate ( $self, $stem, $name, $type, %args )
{
	my $work = File::Temp->newdir;

	my $made =
	      $type eq 'openpgp'
	    ? $self->_generate_openpgp( $work, $stem, $name, %args )
	    : $self->_generate_signify( $work, $stem, $name );
	return unless $made;

	my $public = Fugu::File->read("$work/$name");
	return $self->_fail('cannot read the generated public key')
	    unless defined $public;
	my $private = Fugu::File->read("$work/$stem.sec");
	return $self->_fail('cannot read the generated private key')
	    unless defined $private;

	return ( $public, $private );
}

# $self->_generate_signify($work, $stem, $name):
#	Write a signify pair into the work directory. The method
#	answers 1, or undef with a reason in $self->error.
#
#	signify(1) holds a pair to one stem: <stem>.pub beside
#	<stem>.sec.
#
#	Fugu::Signify writes ' public key' after the comment word, so
#	the published comment is '<stem> public key'. WEB-KEYS-31
#	states that form.
sub _generate_signify ( $self, $work, $stem, $name )
{
	my $sig = Fugu::Signify->new;

	$sig->generate(
		comment => $stem,
		public  => "$work/$name",
		secret  => "$work/$stem.sec",
	) or return $self->_tool_fail($sig);

	return 1;
}

# $self->_generate_openpgp($work, $stem, $name, %args):
#	Write an OpenPGP key into the work directory. The method
#	answers 1, or undef with a reason in $self->error.
#
#	WEB-OPENPGP-1 and WEB-OPENPGP-3. Fugu::OpenPGP makes one
#	Ed25519 primary key with one Curve25519 encryption subkey, and
#	the email is the user id. Each half is armored text. gpg(1)
#	takes the expiry as seconds since the epoch, and _epoch_of
#	reads the date of the caller in UTC. A mint with no expiry
#	date sets no expiry.
sub _generate_openpgp ( $self, $work, $stem, $name, %args )
{
	my $expires = $args{expires};
	my $pgp     = Fugu::OpenPGP->new;

	$pgp->generate(
		email   => $args{email},
		expires => defined $expires && length $expires
		? _epoch_of($expires)
		: undef,
		public => "$work/$name",
		secret => "$work/$stem.sec",
	) or return $self->_tool_fail($pgp);

	return 1;
}

# $self->_openpgp_settings($public, $email):
#	The settings that the key block of an OpenPGP key takes, as a
#	list of name and value pairs. The method answers an array
#	reference, or undef with a reason in $self->error.
#
#	WEB-OPENPGP-2. The fingerprint comes from the key that the
#	step publishes, and never from an argument. WEB-KEYS-22 holds
#	a declared fingerprint to the one that the body gives, so a
#	step which copied an argument could publish a directory that
#	its own reader rejects.
#
#	A mint names the address of the user id that it wrote, per
#	WEB-OPENPGP-1. An import takes no address: the key comes from
#	another tool, and _type_options refuses the option there.
#
#	The reader of Fugu::OpenPGP needs no gpg(1). The key stands
#	already, so this read adds no command of its own.
sub _openpgp_settings ( $self, $public, $email )
{
	my $pgp = Fugu::OpenPGP->new;

	my $binary = $pgp->decode_armor($public)
	    or return $self->_fail(
		'cannot decode the public key: ' . $pgp->error );

	my $fingerprint = $pgp->fingerprint($binary)
	    or return $self->_fail(
		'cannot read the fingerprint of the public key: '
		    . $pgp->error );

	my @setting;
	push @setting, [ email => $email ]
	    if defined $email && length $email;
	push @setting, [ fingerprint => $fingerprint ];

	return \@setting;
}

# $self->_x509_settings($public):
#	The one setting that the key block of a certificate takes, as
#	a list of name and value pairs. The method answers an array
#	reference, or undef with a reason in $self->error.
#
#	WEB-X509-4. The fingerprint is the SHA-256 of the DER form,
#	and the step reads it from the certificate that it publishes.
#
#	WEB-X509-1. The decoder takes one CERTIFICATE block, so a
#	--file that holds a private key or a second block fails the
#	step here, before one byte reaches the directory. The reader
#	needs no openssl(1).
sub _x509_settings ( $self, $public )
{
	my $x509 = Fugu::X509->new;

	my $der = $x509->decode_pem($public)
	    or return $self->_fail(
		'cannot decode the certificate: ' . $x509->error );

	my $fingerprint = $x509->fingerprint($der)
	    or return $self->_fail(
		'cannot read the fingerprint of the certificate: '
		    . $x509->error );

	return [ [ fingerprint => $fingerprint ] ];
}

# _epoch_of($date):
#	A date of the form YYYY-MM-DD as seconds since the epoch, at
#	the start of that date in UTC, or undef for a text of another
#	form and for a day that the month does not hold.
#
#	The key directory writes each date in UTC, per WEB-ROTATE-16,
#	and this date reads the same way.
#
#	Time::Local dies for a field out of range, and this module
#	answers a caller mistake with a reason. The method therefore
#	holds every field to its range itself, and it calls the
#	library with a date that stands.
sub _epoch_of ($date)
{
	my ( $year, $month, $day ) =
	    $date =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/
	    or return;

	return unless $month >= 1 && $month <= 12;
	return unless $day >= 1   && $day <= _days_in( $year, $month );

	return Time::Local::timegm_modern( 0, 0, 0, $day, $month - 1, $year );
}

# _days_in($year, $month):
#	The number of days of the month, with the leap year rule of
#	the Gregorian calendar.
sub _days_in ( $year, $month )
{
	my @length = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
	return $length[ $month - 1 ] unless $month == 2;

	my $leap = $year % 4 == 0 && ( $year % 100 != 0 || $year % 400 == 0 );

	return $leap ? 29 : 28;
}

# $self->_read_pair($file, $secret):
#	The public bytes and the private bytes of a key that another
#	tool made. The method answers the two, or an empty list with a
#	reason in $self->error.
sub _read_pair ( $self, $file, $secret )
{
	return $self->_fail('the import needs the public key file')
	    unless defined $file && length $file;
	return $self->_fail("the public key file $file is no file")
	    unless -f $file;

	my $public = Fugu::File->read($file);
	return $self->_fail("cannot read $file") unless defined $public;

	my $private = Fugu::File->read($secret);
	return $self->_fail("cannot read $secret") unless defined $private;

	return ( $public, $private );
}

# $self->_bind($target, $bytes, $signer, $public, $private):
#	The name and the bytes of one binding: the signature of the
#	public key file of the target by the private half of the
#	signer. The method answers the two, or an empty list with a
#	reason in $self->error.
#
#	Every file of the signature is staged in a temporary
#	directory, so the work never depends on what the tree holds,
#	and nothing reaches the tree until it verifies.
#
#	WEB-TRUST-8. The type of the signer key selects the signer
#	class, as it selects the extension of the binding name. A
#	directory that holds an OpenPGP key or a certificate therefore
#	binds that key with the command of its own type.
sub _bind ( $self, $target, $bytes, $signer, $public, $private )
{
	my $keydir = $self->_keydir or return;
	my $name = $keydir->binding_for( target => $target, signer => $signer )
	    or return $self->_fail( $keydir->error );

	my $parts = $keydir->parse_name($signer)
	    or return $self->_fail( $keydir->error );
	my $class = $SIGNER{ $parts->{type} }
	    or return $self->_fail(
		"a key of the type $parts->{type} signs no binding");

	# signify(1) reads the stem of the secret file and writes
	# 'verify with <stem>.pub' into the signature. The staged name
	# therefore carries the stem of the signing key, so the
	# published comment names a file that the site publishes. A
	# key of another type reads the path alone, and one staged
	# name serves every type.
	my $stem = _stem_of($signer);
	my $work = File::Temp->newdir;

	return $self->_fail("cannot stage $target")
	    unless Fugu::File->write( "$work/$target", $bytes );
	return $self->_fail("cannot stage $signer")
	    unless Fugu::File->write( "$work/$signer", $public );
	return $self->_fail("cannot stage the private half of $signer")
	    unless Fugu::File->write( "$work/$stem.sec", $private,
		mode => 0600 );

	my $sig = $class->new;

	# A PEM private key names no certificate, so Fugu::X509 signs
	# with the certificate of the key beside it. The call therefore
	# names the staged public half. Fugu::Signify and Fugu::OpenPGP
	# read no public argument in sign, and they ignore this one.
	$sig->sign(
		public    => "$work/$signer",
		secret    => "$work/$stem.sec",
		file      => "$work/$target",
		signature => "$work/$name",
	) or return $self->_tool_fail($sig);

	# WEB-TRUST-8. The published public half of the signer proves
	# that the caller named the right private half, and no byte
	# reaches the directory before it does.
	unless (
		$sig->verify(
			keys      => ["$work/$signer"],
			file      => "$work/$target",
			signature => "$work/$name"
		) )
	{
		return $self->_fail( "$signer does not verify the binding"
			    . " $name that the step wrote: "
			    . $sig->error );
	}

	my $written = Fugu::File->read("$work/$name");
	return $self->_fail("cannot read the staged binding $name")
	    unless defined $written;

	return ( $name, $written );
}

# $self->_publish($write, $remove, $want, $facts, $last):
#	Write every file of one step, remove every file that it
#	retires, and then read the result back.
#
#	WEB-ROTATE-8 and WEB-ROTATE-10. Each byte of the step is ready
#	before the first write, and a failure puts every file back. A
#	step therefore leaves the description and the manifest pair as
#	it found them, or as it means them to be, and never between.
#
#	A binding goes after every write, so a run that stops between
#	the two leaves a file that the manifest does not name, and
#	never a manifest that names a file which is gone.
#
#	$last names one more file, which lands after the read back
#	passes. The private half of a new key goes there: a step that
#	fails leaves no key that the site does not publish.
#
#	A caller that runs a step and then commits sees one state or
#	the other. A process that dies inside this method leaves the
#	checkout dirty, and the caller commits nothing.
#
#	The method answers $facts, or undef with a reason in
#	$self->error.
sub _publish ( $self, $write, $remove, $want, $facts, $last = undef )
{
	my %was;
	my @touched = ( keys %$write, @$remove );
	for my $path ( sort @touched ) {
		$was{$path} = -e $path ? Fugu::File->read($path) : undef;
	}

	# The write goes through a temporary file in the same
	# directory, so a reader sees the old bytes or the new ones
	# and never a half-written file.
	my $config    = $self->{config};
	my $bootstrap = $self->{bootstrap};
	for my $path ( sort keys %$write ) {
		next
		    if Fugu::File->write_atomic( $path, $write->{$path} );

		my $stuck = $self->_undo( \%was, $config, $bootstrap );
		return $self->_fail( _why( "cannot write $path", $stuck ) );
	}

	for my $path ( sort @$remove ) {
		next unless -e $path;
		next if unlink $path;

		my $stuck = $self->_undo( \%was, $config, $bootstrap );
		return $self->_fail( _why( "cannot remove $path", $stuck ) );
	}

	# WEB-ROTATE-11 and WEB-ROTATE-12. The reader decides. A
	# directory that App::FuguWeb::Keys rejects is one that
	# fuguweb check rejects, so the step fails and the caller
	# commits nothing.
	unless ( $self->_reload && $self->_confirm($want) && $self->_accept ) {
		my $stuck = $self->_undo( \%was, $config, $bootstrap );
		return $self->_fail( _why( $self->{error}, $stuck ) );
	}

	if ($last) {
		my $ok = Fugu::File->write_atomic( $last->{path},
			$last->{bytes}, mode => $last->{mode} );
		unless ($ok) {
			my $stuck = $self->_undo( \%was, $config, $bootstrap );
			return $self->_fail(
				_why( "cannot write $last->{path}", $stuck ) );
		}
	}

	return $facts;
}

# $self->_undo($was, $config, $bootstrap):
#	Put every file back to the bytes that it held, and remove each
#	file that held none. The description of the object goes back
#	with them, so a caller that holds it reads the tree.
#
#	The method answers a reason when a file stayed, and undef when
#	every file went back.
sub _undo ( $self, $was, $config, $bootstrap )
{
	my @stuck;
	for my $path ( sort keys %$was ) {
		if ( defined $was->{$path} ) {
			next
			    if Fugu::File->write_atomic( $path, $was->{$path} );
			push @stuck, $path;
			next;
		}

		next if unlink $path;
		next unless -e $path;
		push @stuck, $path;
	}

	$self->{config}    = $config;
	$self->{bootstrap} = $bootstrap;

	return @stuck ? 'cannot put back ' . join( ', ', @stuck ) : undef;
}

# _why($reason, $stuck):
#	The reason of a step, with the reason of a failed restore
#	behind it. A tree that no restore reached is one that no
#	caller must commit, so the reader hears both.
sub _why ( $reason, $stuck )
{
	return defined $stuck ? "$reason, and $stuck" : $reason;
}

# $self->_signed($private, $pubname, $bytes):
#	The manifest text over the bytes of the directory, and a
#	signature that the private key made. The method answers the
#	two, or an empty list with a reason in $self->error.
#
#	WEB-TRUST-6. The manifest names every key file and every
#	binding file, and it names nothing else.
#
#	Every file that the signature needs is staged in a temporary
#	directory, so the work never depends on what the tree holds
#	and nothing reaches the tree until it verifies. A first root
#	mint verifies against a key that the tree does not hold yet.
sub _signed ( $self, $private, $pubname, $bytes )
{
	return $self->_fail('the key directory holds no key')
	    unless %$bytes;
	return $self->_fail("the manifest names no $pubname")
	    unless defined $bytes->{$pubname};

	my %digest = map { $_ => Digest::SHA::sha256_hex( $bytes->{$_} ) }
	    keys %$bytes;

	# signify(1) reads the stem of the secret file and writes
	# 'verify with <stem>.pub' into the signature. The staged name
	# therefore carries the stem of the signing key, so the
	# published comment names a file that the site publishes.
	my $stem = _stem_of($pubname);
	my $work = File::Temp->newdir;

	# The writer of the manifest is the parser of the consumer
	# install, so the two never disagree about a line.
	my $sig  = Fugu::Signify->new;
	my $text = $sig->write_manifest( \%digest )
	    or return $self->_fail( $sig->error );

	return $self->_fail('cannot stage the public key')
	    unless Fugu::File->write( "$work/$pubname", $bytes->{$pubname} );
	return $self->_fail('cannot stage the signer')
	    unless Fugu::File->write( "$work/$stem.sec", $private,
		mode => 0600 );
	return $self->_fail('cannot stage the manifest')
	    unless Fugu::File->write( "$work/" . MANIFEST, $text );

	$sig->sign(
		secret    => "$work/$stem.sec",
		file      => "$work/" . MANIFEST,
		signature => "$work/" . SIGNATURE,
	) or return $self->_tool_fail($sig);

	# WEB-ROTATE-7. A signature that the published key does not
	# verify means the caller named the wrong private half. One
	# key in the list, so the check proves that this key signed
	# and no other.
	unless (
		$sig->verify(
			keys      => ["$work/$pubname"],
			file      => "$work/" . MANIFEST,
			signature => "$work/" . SIGNATURE
		) )
	{
		return $self->_fail( "$pubname does not verify the signature"
			    . ' that the signer wrote: '
			    . $sig->error );
	}

	my $bytes_of = Fugu::File->read( "$work/" . SIGNATURE );
	return $self->_fail('cannot read the staged signature')
	    unless defined $bytes_of;

	return ( $text, $bytes_of );
}

# $self->_key_bytes($set):
#	The bytes of every key file of the set, by name.
sub _key_bytes ( $self, $set )
{
	return $self->_bytes_of( sort keys %$set );
}

# $self->_binding_bytes:
#	The bytes of every binding file of the directory, by name.
sub _binding_bytes ($self)
{
	return $self->_bytes_of( map { $_->{name} }
		    $self->{config}->site_bindings( $self->{dir} ) );
}

# $self->_bytes_of(@names):
#	The bytes of each named file of the key directory, by name.
sub _bytes_of ( $self, @names )
{
	my %bytes;
	for my $name (@names) {
		my $found = Fugu::File->read( $self->_path($name) );
		return $self->_fail( 'cannot read ' . $self->_path($name) )
		    unless defined $found;
		$bytes{$name} = $found;
	}

	return \%bytes;
}

# $self->_dir, $self->_path($name):
#	The source key directory, and one file in it. The names come
#	from the directory word, because a first mint runs before a
#	keys block can load.
sub _dir ($self)
{
	return $self->{config}->source_path( $self->{dir} );
}

sub _path ( $self, $name )
{
	return $self->_dir . "/$name";
}

# $self->_set:
#	Each key file of the directory, by name, with the block that
#	describes it.
#
#	WEB-ROTATE-4. The status comes from the description, so a key
#	file with no block, and a block with no file, each fail here.
#	No step of this module assumes a status.
sub _set ($self)
{
	my $dir = $self->_dir;
	return $self->_fail("$dir is no directory") unless -d $dir;

	my %block =
	    map { $_->{name} => $_ } $self->{config}->site_keys( $self->{dir} );

	# A binding carries no key block: its name holds the target
	# and the signer, and App::FuguWeb::Config parses it.
	my %binding =
	    map { $_->{name} => 1 }
	    $self->{config}->site_bindings( $self->{dir} );

	# The reader takes every name of the directory, a dotted one
	# included, so this scan must agree with it. A writer that
	# stepped over a file would publish a directory that
	# App::FuguWeb::Keys rejects.
	my $names = App::FuguWeb::list_dir($dir)
	    or return $self->_fail("cannot read $dir: $!");

	my %set;
	for my $name ( @{$names} ) {
		next if $name eq MANIFEST || $name eq SIGNATURE;
		next if $binding{$name};
		next unless -f "$dir/$name";

		my $block = $block{$name}
		    or return $self->_fail("$dir/$name: no key block names it");
		$set{$name} = $block;
	}

	for my $name ( sort keys %block ) {
		next if $set{$name};
		return $self->_fail(
			"the key block $block{$name}{stem} names no file");
	}

	# WEB-ROTATE-20. A set that breaks the status rules is one
	# that no step can mend, and a step over it would ask a
	# retired key to sign. A directory with no key is the state of
	# a site before its first mint, so it stands.
	if (%set) {
		my $keydir = $self->_keydir or return;
		my @keys =
		    map { { name => $_, status => $set{$_}{status} } }
		    sort keys %set;
		return $self->_fail( $keydir->error )
		    unless $keydir->check_statuses( \@keys );
	}

	return \%set;
}

# _by_status($set, $purpose, $status):
#	The file name of the one key of the purpose that holds the
#	status, or undef.
sub _by_status ( $set, $purpose, $status )
{
	my ($name) = grep {
		       $set->{$_}{purpose} eq $purpose
		    && $set->{$_}{status} eq $status
	} sort keys %$set;

	return $name;
}

# $self->_accept:
#	The problems that App::FuguWeb::Keys reports, as a failure.
#
#	The read leaves out the validity rules of WEB-OPENPGP-4 and
#	WEB-X509-6. The clock decides those, and no step can move a
#	date that a key carries.
#
#	An expired current key is still current when this method
#	reads it back, so a step of its purpose could never be made:
#	the mint that the promote needs would fail first.
#
#	The 30-day report reads the whole directory. The mint of the
#	successor clears its own report, because the purpose then
#	holds a next key. A step of another purpose writes no such
#	key, so it would fail for a report that it cannot answer.
#
#	`fuguweb check` reports each one.
sub _accept ($self)
{
	my @problems = App::FuguWeb::Keys->new(
		config => $self->{config},
		dir    => $self->{dir} )->problems( expiry => 0 );
	return 1 unless @problems;

	return $self->_fail( 'the key directory holds a problem: ' . join '; ',
		@problems );
}

# $self->_reload:
#	Load the description again, so every later read sees what this
#	step wrote.
sub _reload ($self)
{
	# A my declaration inside the argument list takes effect at the
	# next statement, so the reason gets a name of its own first.
	my $reason;
	my $config = App::FuguWeb::Config->load(
		root  => $self->{config}->root,
		error => \$reason,
	) or return $self->_fail($reason);

	$self->{config}    = $config;
	$self->{bootstrap} = 0;

	return 1;
}

# $self->_confirm($want):
#	Read the status of each key that the step changed, and fail
#	when one differs from the intent.
sub _confirm ( $self, $want )
{
	my %status =
	    map { $_->{stem} => $_->{status} }
	    $self->{config}->site_keys( $self->{dir} );

	for my $stem ( sort keys %$want ) {
		my $found = $status{$stem};
		next if defined $found && $found eq $want->{$stem};

		return $self->_fail( "the key block $stem reads the status "
			    . ( $found // '(none)' )
			    . ", and this step wrote $want->{$stem}" );
	}

	return 1;
}

# $self->_with_block($stem, $status, $settings):
#	The description with one key block added, as bytes. A new
#	block goes at the end, so the file keeps every block that it
#	held and the diff shows the addition alone.
#
#	$settings holds one name and value pair for each setting that
#	joins the status and the date. An OpenPGP key takes the email
#	and the fingerprint there, per WEB-OPENPGP-2, and a signify
#	key takes an empty list.
#
#	The name of every setting of one block takes one width, so the
#	values of the block line up.
#
#	A site that publishes its first key takes the keys block in
#	the same bytes, per WEB-ROTATE-15.
sub _with_block ( $self, $stem, $status, $settings = [] )
{
	my $path  = $self->{config}->path;
	my $bytes = Fugu::File->read($path);
	return $self->_fail("cannot read $path") unless defined $bytes;

	my $today = POSIX::strftime( '%Y-%m-%d', gmtime );
	$bytes =~ s/\n*\z/\n/;

	if ( $self->{bootstrap} ) {

		# _add reads the organization word through _keydir, and
		# it does that before the step makes one directory, so
		# the word stands here.
		#
		# A site can hold a second key directory, so the comment
		# names the organization word of this one and never the
		# organization of the site.
		$bytes .=
		      "\n# The published keys of $self->{org}. The"
		    . " rotation\n# writes this directory.\n"
		    . "keys \"$self->{dir}\" {\n\torg = $self->{org}\n";
		$bytes .= "\turl = $self->{url}\n"
		    if defined $self->{url} && length $self->{url};
		$bytes .= "}\n";
	}

	my @block = ( [ status => $status ], [ since => $today ], @$settings );

	my $width = 0;
	for my $setting (@block) {
		my $length = length $setting->[0];
		$width = $length if $length > $width;
	}

	$bytes .= "\nkey \"$stem\" {\n";
	$bytes .= sprintf "\t%-*s = %s\n", $width, @$_ for @block;
	$bytes .= "}\n";

	return $bytes;
}

# $self->_with_statuses($change):
#	The description with the status of each named key block
#	rewritten, as bytes. An until date joins a block where the
#	change names one.
#
#	Fugu::Config takes a block name bare or in quotes, and a
#	setting with or without the equals sign, so both forms match.
sub _with_statuses ( $self, $change )
{
	my $path  = $self->{config}->path;
	my $bytes = Fugu::File->read($path);
	return $self->_fail("cannot read $path") unless defined $bytes;

	my @lines = split /\n/, $bytes, -1;
	my ( $stem, %status, %until, @out );

	for my $line (@lines) {
		if ( $line =~ /\A\s*key\s+(?:"([^"]*)"|(\S+))\s*\{\s*\z/ ) {
			$stem = $1 // $2;
			push @out, $line;
			next;
		}

		my $want = defined $stem ? $change->{$stem} : undef;

		if ( defined $stem && $line =~ /\A\s*\}\s*\z/ ) {
			push @out, "\tuntil  = $want->{until}"
			    if $want
			    && defined $want->{until}
			    && !$until{$stem};
			$stem = undef;
			push @out, $line;
			next;
		}

		# Fugu::Config takes a comment behind a value, so the
		# rewrite keeps it. A pattern that needed the value at
		# the end of the line would refuse a description that
		# the reader takes.
		if (       $want
			&& $line =~ /\A(\s*status\s*=?\s*)\S+(\s*(?:\#.*)?)\z/ )
		{
			push @out, "$1$want->{status}$2";
			$status{$stem} = 1;
			next;
		}

		if (       $want
			&& defined $want->{until}
			&& $line =~ /\A(\s*until\s*=?\s*)\S+(\s*(?:\#.*)?)\z/ )
		{
			push @out, "$1$want->{until}$2";
			$until{$stem} = 1;
			next;
		}

		push @out, $line;
	}

	for my $name ( sort keys %$change ) {
		return $self->_fail("no key block names $name")
		    unless $status{$name};
	}

	return join "\n", @out;
}

# $self->_keydir:
#	A Fugu::KeyDir for the organization of the description.
sub _keydir ($self)
{
	my $org = $self->{org};
	return $self->_fail('the rotation needs the organization word')
	    unless defined $org && length $org;

	# Fugu::KeyDir dies on a word that no key name can carry, and
	# a caller of this module reads a reason and an exit code.
	my $keydir = eval { Fugu::KeyDir->new( org => $org ) };
	return $self->_fail( 'the organization word ' . ( $@ =~ s/\n\z//r ) )
	    unless $keydir;

	return $keydir;
}

# $self->_tool_fail($signer):
#	The failure of a call that needed the command of a key type.
#	An absent command is an install problem, and a failed
#	signature is an integrity problem, so the caller answers each
#	one with its own exit code, per WEB-ROTATE-17, WEB-OPENPGP-6
#	and WEB-X509-9.
sub _tool_fail ( $self, $signer )
{
	$self->{tool_missing} = 1 if $signer->command_absent;

	return $self->_fail( $signer->error );
}

# _stem_of($name):
#	The stem of a key file name.
sub _stem_of ($name)
{
	return $name =~ s/\.[^.]+\z//r;
}

sub _fail ( $self, $reason )
{
	$self->{error} = $reason;

	return;
}

1;
