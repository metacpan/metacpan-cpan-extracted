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
our $VERSION = '0.5.0';

use App::FuguWeb;
use App::FuguWeb::Config;
use App::FuguWeb::Keys;
use Digest::SHA ();
use File::Temp  ();
use Fugu::File;
use Fugu::KeyDir;
use Fugu::Signify;
use POSIX ();

# App::FuguWeb::Rotate - write the key directory of a site, per
# WEB-ROTATE.
#
# App::FuguWeb::Keys reads the directory, and this module writes it.
# One rotation runs in two steps. A mint makes the next key of a
# purpose, and the current key signs the manifest that names it. A
# promote makes that key current and retires the old one.
#
# The first mint of a purpose finds no current key. That key is
# current at once, and it signs its own manifest.
#
# Every step reads the status of each key from the description, and no
# step assumes one. Every step ends with the reader: the module writes
# the directory, loads the description again, and asks
# App::FuguWeb::Keys->problems. A step that leaves one problem fails,
# so the writer can never publish a directory that the checks reject.
#
# The module reaches no network and holds no token. The caller stores
# the private key and declares the public one.

# The two files of the manifest pair, which name no key.
use constant {
	MANIFEST  => 'SHA256',
	SIGNATURE => 'SHA256.sig',
};

sub new ( $class, %args )
{
	my $config = $args{config};
	die "config is a necessary argument\n" unless defined $config;

	# A keys block cannot load until a key block stands beside it,
	# so a site that publishes its first key holds neither yet.
	# The caller then names the organization word, the directory
	# and the prefix, and one commit carries all of it with the
	# first key, per WEB-ROTATE-15.
	my $fresh = !defined $config->keys_dir;

	return bless {
		config       => $config,
		tool_missing => 0,
		bootstrap    => $fresh,
		dir          => $config->keys_dir // $args{dir} // 'keys',
		org          => $config->keys_org // $args{org},
		url          => $config->keys_url // $args{url},
		error        => undef,
	}, $class;
}

# $self->config:
#	The description. A step loads it again after it writes, so a
#	caller that holds this object reads the current state.
sub config ($self) { return $self->{config}; }

# $self->error:
#	The reason of the most recent failure, or undef.
sub error ($self) { return $self->{error}; }

# $self->tool_missing:
#	True when the failure was an absent signify(1). A caller
#	answers a missing tool with its own exit code, so a script can
#	tell it from a rotation that failed.
sub tool_missing ($self) { return $self->{tool_missing}; }

# $self->mint(%args):
#	Generate the next key of the purpose and publish its public
#	half. The method answers a hash reference of the facts, or
#	undef with a reason in $self->error.
#
#	%args:
#		purpose => $word	what the key signs
#		secret  => $path	where the private half goes
#		signer  => $path	the private half of the current key
sub mint ( $self, %args )
{
	$self->{error} = undef;

	my $purpose = $args{purpose};
	my $secret  = $args{secret};
	my $signer  = $args{signer};

	# WEB-ROTATE-21. The word names one directory below the source
	# directory, as WEB-KEYS-29 holds it. A word that held a
	# solidus or a dot would write the key outside the site.
	my $dir = $self->{dir};
	return $self->_fail("the key directory $dir is not one name")
	    if $dir eq '.' || $dir eq '..' || $dir =~ m{[/\\]};

	return $self->_fail( 'cannot make ' . $self->_dir )
	    unless Fugu::File->ensure_dir( $self->_dir );

	my $set = $self->_set or return;

	# WEB-ROTATE-18. The private half of the current key is the
	# one thing a rotation cannot make again. A caller holds each
	# private half in one place, so a path that stands already,
	# or that names the signer, would take the private half of a
	# published key.
	return $self->_fail('the mint needs the path of the private half')
	    unless defined $secret && length $secret;
	return $self->_fail( "$secret stands already, and a mint writes the"
		    . ' private half of a new key' )
	    if -e $secret;
	return $self->_fail('the secret and the signer name one path')
	    if defined $signer && length $signer && $secret eq $signer;

	# WEB-ROTATE-5. The guard runs before the pair exists, because
	# a caller holds one place for the private half of a mint: a
	# second next key loses the private half of the first.
	if ( my $pending = _by_status( $set, $purpose, 'next' ) ) {
		return $self->_fail( "the purpose $purpose holds the next key "
			    . "$pending already, so promote it first" );
	}

	# WEB-ROTATE-19. One manifest covers the whole directory, and
	# one key signs it, so every key of the directory holds one
	# purpose. A second purpose would leave the current key of the
	# first unable to verify the pair, and no check would say so.
	my %held = map { $set->{$_}{purpose} => 1 } keys %$set;
	delete $held{$purpose};
	if ( my @other = sort keys %held ) {
		return $self->_fail( 'the key directory holds the purpose '
			    . join( ' and ', @other )
			    . ", so it takes no key of $purpose" );
	}

	my $current = _by_status( $set, $purpose, 'current' );

	# WEB-ROTATE-6. The current key signs, and the key that this
	# run makes must never sign for it. A first mint is the one
	# exception, and it takes no signer at all.
	my ( $status, $verify ) = ( 'next', $current );
	if ($current) {
		unless ( defined $signer && length $signer ) {
			return $self->_fail(
				      "the purpose $purpose holds the current"
				    . " key $current, so the mint needs the"
				    . ' private half of that key as the signer'
			);
		}
		return $self->_fail("the signer $signer is no file")
		    unless -f $signer;
	}
	else {
		if ( defined $signer && length $signer ) {
			return $self->_fail(
				      "the purpose $purpose holds no current"
				    . ' key, so the new key signs its own'
				    . ' manifest and the mint takes no signer'
			);
		}
		$status = 'current';
	}

	my $keydir = $self->_keydir or return;
	my $serial = $keydir->next_serial( [ keys %$set ], $purpose )
	    or return $self->_fail( $keydir->error );
	my $name = $keydir->name_for(
		serial  => $serial,
		purpose => $purpose,
		type    => 'signify',
	) or return $self->_fail( $keydir->error );

	my $stem = $name =~ s/\.pub\z//r;

	# _set refuses a key file that no block names, and next_serial
	# reads every name, so no run reaches a name that stands.
	# The guard holds that true, whatever a later change makes of
	# the scan: a mint must never write over a key.
	return $self->_fail("$name exists already") if -e $self->_path($name);

	# The verification key of a first mint is the key of this run.
	$verify //= $name;

	# signify(1) holds a pair to one stem: <stem>.pub beside
	# <stem>.sec. The pair is therefore made in a temporary
	# directory, and each half then goes where it belongs. The
	# directory dies with the process, so no secret stays behind.
	#
	# signify(1) writes ' public key' after the comment word, so
	# the published comment is '<stem> public key'. WEB-KEYS-31
	# states that form.
	my $work = File::Temp->newdir;
	$self->_signify( '-G', '-n', '-c', $stem,
		'-p', "$work/$stem.pub", '-s', "$work/$stem.sec" )
	    or return;

	my $public = Fugu::File->read("$work/$stem.pub");
	return $self->_fail('cannot read the generated public key')
	    unless defined $public;
	my $private = Fugu::File->read("$work/$stem.sec");
	return $self->_fail('cannot read the generated private key')
	    unless defined $private;

	my $bytes = $self->_key_bytes($set) or return;
	$bytes->{$name} = $public;

	# The signer reaches the signature as bytes, so the private
	# half of the new key never lands before the step succeeds.
	my $with = $private;
	if ($current) {
		$with = Fugu::File->read($signer);
		return $self->_fail("cannot read $signer")
		    unless defined $with;
	}

	my ( $manifest, $signature ) = $self->_signed( $with, $verify, $bytes );
	return unless defined $manifest;

	my $description = $self->_with_block( $stem, $status ) or return;

	return $self->_publish( {
			$self->{config}->path   => $description,
			$self->_path($name)     => $public,
			$self->_path(MANIFEST)  => $manifest,
			$self->_path(SIGNATURE) => $signature,
		},
		{ $stem => $status },
		{
			name   => $name,
			stem   => $stem,
			serial => $serial,
			status => $status,
		},

		# WEB-ROTATE-2. The private half takes no group mode
		# and no other mode, and it lands last: a step that
		# fails leaves no key that the site does not publish.
		{ path => $secret, bytes => $private, mode => 0600 } );
}

# $self->promote(%args):
#	Make the next key of the purpose current, and retire the key
#	that was current. The method answers a hash reference of the
#	facts, or undef with a reason in $self->error.
#
#	%args:
#		purpose => $word	what the key signs
#		secret  => $path	the private half of the next key
sub promote ( $self, %args )
{
	$self->{error} = undef;

	my $purpose = $args{purpose};
	my $secret  = $args{secret};

	my $set = $self->_set or return;

	my $next = _by_status( $set, $purpose, 'next' )
	    or return $self->_fail("the purpose $purpose holds no next key");
	my $old = _by_status( $set, $purpose, 'current' );

	unless ( defined $secret && -f $secret ) {
		return $self->_fail( 'the promote needs the private half of '
			    . "$next, which this run makes current" );
	}

	my $today  = POSIX::strftime( '%Y-%m-%d', gmtime );
	my %change = ( _stem_of($next) => { status => 'current' } );
	$change{ _stem_of($old) } = { status => 'retired', until => $today }
	    if $old;

	my $bytes = $self->_key_bytes($set) or return;

	my $private = Fugu::File->read($secret);
	return $self->_fail("cannot read $secret") unless defined $private;

	# WEB-ROTATE-6. The key that this run makes current signs.
	my ( $manifest, $signature ) =
	    $self->_signed( $private, $next, $bytes );
	return unless defined $manifest;

	my $description = $self->_with_statuses( \%change ) or return;

	return $self->_publish( {
			$self->{config}->path   => $description,
			$self->_path(MANIFEST)  => $manifest,
			$self->_path(SIGNATURE) => $signature,
		},
		{ map { $_ => $change{$_}{status} } keys %change },
		{
			name    => $next,
			stem    => _stem_of($next),
			serial  => $set->{$next}{serial},
			status  => 'current',
			retired => $old // '',
		} );
}

# $self->_publish($write, $want, $facts, $last):
#	Write every file of one step, then read the result back.
#
#	WEB-ROTATE-8 and WEB-ROTATE-10. Each byte of the step is ready
#	before the first write, and a failure puts every file back. A
#	step therefore leaves the description and the manifest pair as
#	it found them, or as it means them to be, and never between.
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
sub _publish ( $self, $write, $want, $facts, $last = undef )
{
	my %was;
	for my $path ( sort keys %$write ) {
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

# $self->_signed($secret, $pubname, $bytes):
#	The manifest text over the key bytes, and a signature that the
#	private key made. The method answers the two, or an empty list
#	with a reason in $self->error.
#
#	Every file that the signature needs is staged in a temporary
#	directory, so the work never depends on what the tree holds
#	and nothing reaches the tree until it verifies. A first mint
#	verifies against a key that the tree does not hold yet.
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
	my $stem = $pubname =~ s/\.pub\z//r;
	my $work = File::Temp->newdir;

	# One key in the list, so a verification proves that this key
	# signed and no other. The writer of the manifest is the
	# parser of the consumer install, so the two never disagree.
	my $signify = Fugu::Signify->new( keys => ["$work/$pubname"] );
	my $text    = $signify->write_manifest( \%digest )
	    or return $self->_fail( $signify->error );

	return $self->_fail('cannot stage the public key')
	    unless Fugu::File->write( "$work/$pubname", $bytes->{$pubname} );
	return $self->_fail('cannot stage the signer')
	    unless Fugu::File->write( "$work/$stem.sec", $private,
		mode => 0600 );
	return $self->_fail('cannot stage the manifest')
	    unless Fugu::File->write( "$work/" . MANIFEST, $text );

	$self->_signify(
		'-S', '-s', "$work/$stem.sec", '-m',
		"$work/" . MANIFEST, '-x', "$work/" . SIGNATURE
	) or return;

	# WEB-ROTATE-7. A signature that the published key does not
	# verify means the caller named the wrong private half.
	unless ( $signify->verify( "$work/" . MANIFEST, "$work/" . SIGNATURE ) )
	{
		return $self->_fail( "$pubname does not verify the signature"
			    . ' that the signer wrote: '
			    . $signify->error );
	}

	my $sig = Fugu::File->read( "$work/" . SIGNATURE );
	return $self->_fail('cannot read the staged signature')
	    unless defined $sig;

	return ( $text, $sig );
}

# $self->_key_bytes($set):
#	The bytes of every key file of the set, by name.
sub _key_bytes ( $self, $set )
{
	my %bytes;
	for my $name ( sort keys %$set ) {
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

	my %block = map { $_->{name} => $_ } $self->{config}->site_keys;

	# The reader takes every name of the directory, a dotted one
	# included, so this scan must agree with it. A writer that
	# stepped over a file would publish a directory that
	# App::FuguWeb::Keys rejects.
	my $names = App::FuguWeb::list_dir($dir)
	    or return $self->_fail("cannot read $dir: $!");

	my %set;
	for my $name ( @{$names} ) {
		next if $name eq MANIFEST || $name eq SIGNATURE;
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
sub _accept ($self)
{
	my @problems =
	    App::FuguWeb::Keys->new( config => $self->{config} )->problems;
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
	    map { $_->{stem} => $_->{status} } $self->{config}->site_keys;

	for my $stem ( sort keys %$want ) {
		my $found = $status{$stem};
		next if defined $found && $found eq $want->{$stem};

		return $self->_fail( "the key block $stem reads the status "
			    . ( $found // '(none)' )
			    . ", and this step wrote $want->{$stem}" );
	}

	return 1;
}

# $self->_with_block($stem, $status):
#	The description with one key block added, as bytes. A new
#	block goes at the end, so the file keeps every block that it
#	held and the diff shows the addition alone.
#
#	A site that publishes its first key takes the keys block in
#	the same bytes, per WEB-ROTATE-15.
sub _with_block ( $self, $stem, $status )
{
	my $path  = $self->{config}->path;
	my $bytes = Fugu::File->read($path);
	return $self->_fail("cannot read $path") unless defined $bytes;

	my $today = POSIX::strftime( '%Y-%m-%d', gmtime );
	$bytes =~ s/\n*\z/\n/;

	if ( $self->{bootstrap} ) {
		return $self->_fail('the first key needs the organization word')
		    unless defined $self->{org} && length $self->{org};

		$bytes .=
		      "\n# The published keys of the organization. The"
		    . " rotation\n# writes this directory.\n"
		    . "keys \"$self->{dir}\" {\n\torg = $self->{org}\n";
		$bytes .= "\turl = $self->{url}\n"
		    if defined $self->{url} && length $self->{url};
		$bytes .= "}\n";
	}

	$bytes .= "\nkey \"$stem\" {\n\tstatus = $status\n"
	    . "\tsince  = $today\n}\n";

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

# $self->_signify(@args):
#	Run signify(1) with the arguments, and fail when it does. The
#	first word is a program path and no argument reaches a shell,
#	so no value can become part of a command.
sub _signify ( $self, @args )
{
	my $signify = Fugu::Signify->new( keys => [ $self->{config}->path ] );
	unless ( $signify->is_available ) {
		$self->{tool_missing} = 1;
		return $self->_fail( $signify->error );
	}

	my $command = $signify->command;
	system {$command} $command, @args;

	return 1 if $? == 0;

	return $self->_fail( "$command failed with status " . ( $? >> 8 ) );
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
