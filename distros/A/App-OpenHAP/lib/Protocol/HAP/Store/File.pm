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

package Protocol::HAP::Store::File;
our $VERSION = '0.1.0';

use Carp       qw(croak);
use Fcntl      qw(O_CREAT O_EXCL O_TRUNC O_WRONLY);
use File::Path qw(make_path);
use JSON::PP;
use Protocol::HAP;

# Protocol::HAP::Store::File - the store contract over files.
#
# This is the durable implementation of the twelve store methods that
# Protocol/HAP/Store.pod documents. Everything here is HAP: the
# long-term key files, the pairings format, the counters, and the rule
# that every pairing change bumps the configuration number.
#
# The tier holds a sans-IO engine, and this module writes files. That
# is the point: sans-IO describes Protocol::HAP::Server, and the store
# is the injected seam that keeps the engine pure.
#
# The layout on disk is:
#
#	<path>/accessory_ltsk		mode 0600
#	<path>/accessory_ltpk		mode 0644
#	<path>/pairings.db		mode 0600
#	<path>/state.json		mode 0600, the counters
#
# Every write sets the mode at the open, before the first byte. A
# chmod after the write leaves a window in which the identity of the
# accessory is world-readable.

# Protocol::HAP::Store::File->new(%args):
#	path   => $dir	the state directory (required)
#	logger => $obj	a logger (default the null logger)
#
#	The caller owns the path. This module holds no host policy, so
#	it carries no default location.
sub new ( $class, %args )
{
	my $path = $args{path};
	croak 'path parameter required'
	    unless defined $path && length $path;

	my $self = bless {
		path          => $path,
		logger        => $args{logger} // Protocol::HAP->null_logger,
		pairings_file => "$path/pairings.db",
		accessory_ltsk_file => "$path/accessory_ltsk",
		accessory_ltpk_file => "$path/accessory_ltpk",
		state_file          => "$path/state.json",
		state               => {},
	}, $class;

	$self->_ensure_dir( $path, 0700 )
	    or croak "Cannot create the state directory $path";
	$self->_load_state;

	return $self;
}

# --- the accessory identity -----------------------------------------------

sub load_accessory_keys ($self)
{
	if (       -f $self->{accessory_ltsk_file}
		&& -f $self->{accessory_ltpk_file} )
	{
		$self->{logger}->debug('Loading accessory keys from storage');
		my $ltsk = $self->_read( $self->{accessory_ltsk_file} );
		my $ltpk = $self->_read( $self->{accessory_ltpk_file} );
		return ( $ltsk, $ltpk );
	}

	$self->{logger}->debug('No existing accessory keys found');
	return ();
}

sub save_accessory_keys ( $self, $ltsk, $ltpk )
{
	$self->{logger}->debug('Generating and saving new accessory keys');

	$self->_write( $self->{accessory_ltsk_file}, $ltsk, 0600 )
	    or croak 'Cannot store the accessory secret key';
	$self->_write( $self->{accessory_ltpk_file}, $ltpk, 0644 )
	    or croak 'Cannot store the accessory public key';

	return;
}

# --- the pairings ---------------------------------------------------------

sub load_pairings ($self)
{
	return {} unless -f $self->{pairings_file};

	$self->{logger}->debug('Loading pairings from storage');
	my %pairings;
	open my $fh, '<', $self->{pairings_file}
	    or die 'Cannot open pairings file: ' . _reason($!);

	while ( my $line = <$fh> ) {
		chomp $line;
		next if $line =~ /^#/ || $line =~ /^\s*$/;

		# Format: controller_id:ltpk_hex:permissions
		if ( $line =~ /^([^:]+):([^:]+):([01])$/ ) {
			my ( $id, $ltpk_hex, $perms ) = ( $1, $2, $3 );
			$pairings{$id} = {
				ltpk        => pack( 'H*', $ltpk_hex ),
				permissions => $perms,
			};
		}
	}

	close $fh;

	return \%pairings;
}

sub save_pairing ( $self, $controller_id, $ltpk, $permissions = 1 )
{
	$self->{logger}
	    ->debug( 'Saving pairing for controller: %s', $controller_id );
	my $pairings = $self->load_pairings;
	$pairings->{$controller_id} = {
		ltpk        => $ltpk,
		permissions => $permissions,
	};

	$self->_save_pairings($pairings);
	$self->increment_config_number();

	return;
}

sub remove_pairing ( $self, $controller_id )
{
	$self->{logger}
	    ->debug( 'Removing pairing for controller: %s', $controller_id );
	my $pairings = $self->load_pairings;
	delete $pairings->{$controller_id};

	$self->_save_pairings($pairings);
	$self->increment_config_number();

	return;
}

# remove_all_pairings() - Remove all pairings. This is a factory
# reset. The engine calls this method when it removes the last admin
# pairing (HAP-Pairing.md §7.2).
sub remove_all_pairings ($self)
{
	$self->{logger}->debug('Removing all pairings');
	$self->_save_pairings( {} );
	$self->increment_config_number();

	return;
}

sub _save_pairings ( $self, $pairings )
{
	my $text =
	      "# OpenHAP Pairings Database\n"
	    . "# Format: controller_id:ltpk_hex:permissions\n"
	    . "# Permissions: 1=admin, 0=regular\n\n";

	for my $id ( sort keys %$pairings ) {
		my $ltpk_hex = unpack( 'H*', $pairings->{$id}{ltpk} );
		my $perms    = $pairings->{$id}{permissions};
		$text .= "$id:$ltpk_hex:$perms\n";
	}

	# The file is 0600 from its first byte. A pairing record names
	# every controller that may reach the accessory.
	$self->_write( $self->{pairings_file}, $text, 0600 )
	    or croak 'Cannot write the pairings file';

	return;
}

# --- the counters ---------------------------------------------------------

# The configuration number tells a controller that the accessory
# database changed [HAP-Accessories]. It only ever goes up: a
# controller that sees it go backwards drops the accessory and pairs
# again. Thus the value starts at 1, not at 0.
sub get_config_number ($self)
{
	my $number = $self->{state}{config_number};
	return 1 unless defined $number && $number =~ /^\d+$/;

	return $number;
}

sub increment_config_number ($self)
{
	my $number = $self->get_config_number + 1;
	$self->_set( config_number => $number );

	return $number;
}

sub get_config_digest ($self)
{
	return $self->{state}{config_digest};
}

sub save_config_digest ( $self, $digest )
{
	$self->_set( config_digest => $digest );

	return;
}

sub get_auth_attempts ($self)
{
	my $count = $self->{state}{auth_attempts};
	return 0 unless defined $count && $count =~ /^\d+$/;

	return $count;
}

sub set_auth_attempts ( $self, $count )
{
	$self->_set( auth_attempts => $count );

	return;
}

# --- the state file -------------------------------------------------------
#
# The counters live in one JSON file. The load tolerates a missing file
# and a corrupt one: a state file that a crash truncated must not stop
# the daemon that would rewrite it. The save writes through a temporary
# file and renames over the target, so the file is never the corrupt
# one that the next load has to tolerate.

sub _load_state ($self)
{
	$self->{state} = {};

	return $self unless -f $self->{state_file};

	my $content = $self->_read( $self->{state_file} );
	return $self if !defined $content || $content eq '';

	my $data = eval { JSON::PP->new->utf8->decode($content) };
	unless ( defined $data && ref $data eq 'HASH' ) {
		$self->{logger}->warning( 'Cannot read state from %s: %s',
			$self->{state_file}, _reason($@) );
		return $self;
	}

	$self->{state} = $data;

	return $self;
}

sub _save_state ($self)
{
	# The encoding is canonical, so the same data always gives the
	# same bytes and a diff of two state files is readable.
	my $json =
	    eval { JSON::PP->new->utf8->canonical->encode( $self->{state} ) };
	unless ( defined $json ) {
		$self->{logger}->error( 'Cannot encode %s: %s',
			$self->{state_file}, _reason($@) );
		return;
	}

	return $self->_write_atomic( $self->{state_file}, $json, 0600 );
}

sub _set ( $self, $key, $value )
{
	$self->{state}{$key} = $value;

	return $self->_save_state;
}

# --- the file operations --------------------------------------------------

# $self->_read($path):
#	Read a whole file and return its bytes, or undef.
sub _read ( $self, $path )
{
	open my $fh, '<', $path or do {
		$self->{logger}->debug( 'Cannot read %s: %s', $path, $! );
		return;
	};
	binmode $fh;
	my $content = do { local $/; <$fh> };
	close $fh;

	return $content // '';
}

# $self->_write($path, $data, $mode):
#	Write the bytes with the mode applied at the open. An existing
#	file keeps its own mode through the open, so the method removes
#	it first and the mode argument means what it says.
sub _write ( $self, $path, $data, $mode )
{
	unlink $path if -e $path;

	sysopen my $fh, $path, O_CREAT | O_WRONLY | O_TRUNC, $mode or do {
		$self->{logger}->error( 'Cannot write %s: %s', $path, $! );
		return;
	};
	binmode $fh;

	my $ok = $self->_write_all( $fh, $data, $path );
	close $fh or $ok = undef;

	return $ok;
}

# $self->_write_atomic($path, $data, $mode):
#	Write through a temporary file in the same directory, then
#	rename over the target. A reader sees the old content or the new
#	content, never a half-written file. The rename must stay inside
#	one filesystem, so the temporary name is a sibling.
sub _write_atomic ( $self, $path, $data, $mode )
{
	# A hidden sibling, as the host helper used before the move. The
	# state directory thus looks the same to an operator.
	my $temp = $path =~ s{(^|/)([^/]+)$}{${1}.$2.$$.tmp}r;
	unlink $temp if -e $temp;

	sysopen my $fh, $temp, O_CREAT | O_EXCL | O_WRONLY, $mode or do {
		$self->{logger}->error( 'Cannot write %s: %s', $temp, $! );
		return;
	};
	binmode $fh;

	unless ( $self->_write_all( $fh, $data, $temp ) && close $fh ) {
		close $fh;
		unlink $temp;
		return;
	}

	unless ( rename $temp, $path ) {
		$self->{logger}
		    ->error( 'Cannot rename %s to %s: %s', $temp, $path, $! );
		unlink $temp;
		return;
	}

	return 1;
}

# $self->_write_all($fh, $data, $path):
#	Write every byte. A short syswrite is not an error by itself, so
#	the loop continues until the data is gone.
sub _write_all ( $self, $fh, $data, $path )
{
	my $offset = 0;
	while ( $offset < length $data ) {
		my $n = syswrite $fh, $data, length($data) - $offset, $offset;
		unless ( defined $n ) {
			next if $!{EINTR};
			$self->{logger}
			    ->error( 'Cannot write %s: %s', $path, $! );
			return;
		}
		$offset += $n;
	}

	return 1;
}

# $self->_ensure_dir($path, $mode):
#	Make sure the directory exists. The method refuses a symlink and
#	refuses a path that exists as something else. Both are conditions
#	that a daemon must not write through.
sub _ensure_dir ( $self, $path, $mode )
{
	if ( -l $path ) {
		$self->{logger}->error( 'Directory is a symlink: %s', $path );
		return;
	}
	if ( -e $path && !-d $path ) {
		$self->{logger}->error( 'Path is not a directory: %s', $path );
		return;
	}
	return 1 if -d $path;

	eval { make_path( $path, { mode => $mode } ); 1 };
	unless ( -d $path ) {

		# make_path dies with a message that names the module and
		# the line. A daemon log wants the reason only.
		$self->{logger}
		    ->error( 'Cannot create %s: %s', $path, _reason($@) );
		return;
	}

	return 1;
}

# _reason($error):
#	Reduce a die message to one line with no file and line number.
#	A daemon log is not the place for a Perl backtrace.
sub _reason ($error)
{
	my $why = $error // 'unknown error';
	$why =~ s/ at \S+ line \d+.*//s;
	$why =~ s/\s+$//;

	return length($why) ? $why : 'unknown error';
}

1;
