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

package App::FuguVM::Remote;
our $VERSION = '0.2.0';

use File::Basename;
use File::Find ();
use Fugu::File;
use Fugu::Log;
use Fugu::SSH;

# App::FuguVM::Remote - the remote side of one running guest.
#
# The module owns the Fugu::SSH object, the argument quoting, the
# local walk, and the publish order. Thus App::FuguVM::CLI keeps thin
# command bodies, and one module holds the session timeout.

use constant {

	# Seconds. Fugu::SSH bounds the connect and the channel read
	# with this one value. The value holds a guest build and a
	# large transfer, and it still ends a hang.
	SSH_TIMEOUT => 3600,

	# Bytes, for one file. write_file and read_file each hold a
	# file in memory, so the cap fails closed.
	MAX_TRANSFER_SIZE => 64 * 1024 * 1024,

	# Paths for each batched remote command, so no command line
	# grows too long.
	BATCH_PATHS => 100,
};

# The caller must give a host and a port. A missing value is a
# programming error, because App::FuguVM::CLI resolves both before it
# builds the object.
sub new ( $class, %args )
{
	die "App::FuguVM::Remote->new needs a host\n"
	    if !defined $args{host};
	die "App::FuguVM::Remote->new needs a port\n"
	    if !defined $args{port};

	my $self = bless {
		host => $args{host},
		port => $args{port},
		ssh  => Fugu::SSH->new(
			host    => $args{host},
			port    => $args{port},
			user    => 'root',
			timeout => SSH_TIMEOUT,
		),
	}, $class;

	return $self;
}

# $class_or_self->quote_argv(@argv):
#	Return one remote command string. Each word gets single
#	quotes, and a single quote inside a word becomes the '\''
#	form. An empty word becomes ''. The words join with one
#	space. So the remote shell splits the string at the word
#	boundaries only: it expands nothing, and it globs nothing.
sub quote_argv ( $, @argv )
{
	my @words;
	for my $word (@argv) {
		my $quoted = $word;
		$quoted =~ s/'/'\\''/g;
		push @words, "'$quoted'";
	}

	return join ' ', @words;
}

# $self->run(@argv):
#	Run one argument vector on the guest. The method returns the
#	hash of Fugu::SSH->run_command. An empty vector is a
#	programming error.
sub run ( $self, @argv )
{
	die "App::FuguVM::Remote->run needs an argument vector\n"
	    if !@argv;

	return $self->{ssh}->run_command( $self->quote_argv(@argv) );
}

# $self->interactive:
#	Open an interactive session. The method returns the exit code
#	of ssh(1).
sub interactive ($self)
{
	return $self->{ssh}->interactive;
}

# $self->put($local, $remote, %args):
#	Copy a local file or a local directory to $remote in the
#	guest. $remote is never a container: the content of a
#	directory arrives under $remote, with no component for the
#	source directory name. %args takes 'mode', the mode of each
#	file that the method writes. Without it each file keeps its
#	local permission bits, masked with 0777.
#
#	The method creates every remote directory first, writes each
#	file to a temporary name beside its destination, and then
#	publishes every temporary file with mv -f. A failure removes
#	every temporary file, so a failed run leaves no partial
#	destination file. The method returns 1, or undef.
sub put ( $self, $local, $remote, %args )
{
	my $entries = $self->_entries( $local, $remote, $args{mode} );
	return if !defined $entries;

	my @dirs  = grep { $_->{type} eq 'dir' } @$entries;
	my @files = grep { $_->{type} eq 'file' } @$entries;

	return if @dirs && !$self->_mkdir( map { $_->{dest} } @dirs );

	my @temps;
	for my $entry (@files) {
		my $temp = "$entry->{dest}.fuguvm.$$";

		my $content = Fugu::File->read( $entry->{source} );
		if ( !defined $content ) {
			$self->_discard(@temps);
			return;
		}

		my $wrote =
		    $self->{ssh}->write_file( $temp, $content, $entry->{mode} );
		if ( $wrote != 0 ) {
			Fugu::Log->default->error( 'Cannot write %s to %s:%d',
				$temp, $self->{host}, $self->{port} );
			$self->_discard(@temps);
			return;
		}

		push @temps, $temp;
	}

	if ( @files && !$self->_publish(@files) ) {
		$self->_discard(@temps);
		return;
	}

	return 1;
}

# $self->get($remote, $local):
#	Copy one regular guest file to $local on the host. The method
#	reads the whole file first, and it writes the local file
#	atomically, mode 0644. So a failure leaves no partial local
#	file. The method returns 1, or undef.
sub get ( $self, $remote, $local )
{
	if ( -d $local ) {
		Fugu::Log->default->error(
			'The local destination is a directory: %s', $local );
		return;
	}

	my $content = $self->{ssh}->read_file( $remote, MAX_TRANSFER_SIZE );
	if ( !defined $content ) {
		Fugu::Log->default->error( 'Cannot read %s from %s:%d',
			$remote, $self->{host}, $self->{port} );
		return;
	}

	Fugu::File->ensure_dir( dirname($local) ) or return;

	return Fugu::File->write_atomic( $local, $content, mode => 0644 )
	    ? 1
	    : ();
}

# $self->_entries($local, $remote, $mode):
#	Walk $local and return one sorted entry list:
#	{ type, source, dest, mode }. A directory entry carries no
#	source and no mode. A symbolic link, a device node, a socket,
#	a fifo, and a file above MAX_TRANSFER_SIZE each fail the whole
#	walk, before the caller writes one byte. The method returns
#	undef on every failure, with the reason logged.
sub _entries ( $self, $local, $remote, $mode = undef )
{
	if ( -l $local || ( !-f $local && !-d $local ) ) {
		Fugu::Log->default->error(
			'Not a regular file or a directory: %s', $local );
		return;
	}

	my @entries;
	my $failed;

	my $add_file = sub ( $source, $dest ) {
		my $size = -s $source;
		if ( $size > MAX_TRANSFER_SIZE ) {
			Fugu::Log->default->error(
				'%s holds %d bytes, the cap is %d',
				$source, $size, MAX_TRANSFER_SIZE );
			$failed = 1;
			return;
		}

		# The mask drops a setuid bit and a setgid bit. The
		# --mode value of the caller can name all four digits,
		# because the caller then asks for them.
		my $bits = $mode // ( ( stat _ )[2] & 0777 );

		push @entries,
		    {
			type   => 'file',
			source => $source,
			dest   => $dest,
			mode   => $bits,
		    };
	};

	if ( -f $local ) {
		$add_file->( $local, $remote );
		return $failed ? undef : \@entries;
	}

	if ( !-r $local || !-x $local ) {
		Fugu::Log->default->error( 'Cannot enter directory: %s',
			$local );
		return;
	}

	push @entries, { type => 'dir', dest => $remote };

	File::Find::find( {
			no_chdir => 1,
			wanted   => sub {
				return if $failed;
				my $source = $File::Find::name;
				return if $source eq $local;

				my $rel  = substr $source, length($local) + 1;
				my $dest = "$remote/$rel";

				if ( -l $source ) {
					Fugu::Log->default->error(
						'Cannot copy a symbolic'
						    . ' link: %s',
						$source
					);
					$failed = 1;
					return;
				}
				if ( -d $source ) {

					# Fail closed: a directory that
					# the walk cannot enter would
					# read as a complete copy.
					if ( !-r $source || !-x $source ) {
						Fugu::Log->default->error(
							'Cannot enter'
							    . ' directory: %s',
							$source );
						$failed            = 1;
						$File::Find::prune = 1;
						return;
					}
					push @entries,
					    { type => 'dir', dest => $dest };
					return;
				}
				if ( !-f $source ) {
					Fugu::Log->default->error(
						'Not a regular file: %s',
						$source );
					$failed = 1;
					return;
				}

				$add_file->( $source, $dest );
			},
		},
		$local
	);

	return if $failed;

	my @sorted =
	    sort { $a->{dest} cmp $b->{dest} } @entries;

	return \@sorted;
}

# $self->_mkdir(@dirs):
#	Create every remote directory, batched under BATCH_PATHS
#	paths for each call. The method returns 1, or undef.
sub _mkdir ( $self, @dirs )
{
	while (@dirs) {
		my @batch = splice @dirs, 0, BATCH_PATHS;
		my $result =
		    $self->{ssh}
		    ->run_command( $self->quote_argv( 'mkdir', '-p', @batch ) );

		if ( $result->{exit_code} != 0 ) {
			Fugu::Log->default->error(
				'Cannot create directories on %s:%d: %s',
				$self->{host}, $self->{port},
				$result->{stderr} );
			return;
		}
	}

	return 1;
}

# $self->_publish(@files):
#	Move every temporary file onto its destination, with batched
#	mv -f commands. Each mv holds two paths, so one batch holds
#	BATCH_PATHS / 2 moves. The method returns 1, or undef.
sub _publish ( $self, @files )
{
	my @pairs = map { [ "$_->{dest}.fuguvm.$$", $_->{dest} ] } @files;

	while (@pairs) {
		my @batch   = splice @pairs, 0, int( BATCH_PATHS / 2 );
		my $command = join ' && ',
		    map { $self->quote_argv( 'mv', '-f', $_->[0], $_->[1] ) }
		    @batch;

		my $result = $self->{ssh}->run_command($command);
		if ( $result->{exit_code} != 0 ) {
			Fugu::Log->default->error(
				'Cannot publish files on %s:%d: %s',
				$self->{host}, $self->{port},
				$result->{stderr} );
			return;
		}
	}

	return 1;
}

# $self->_discard(@temps):
#	Remove the temporary files that a failed put wrote, with
#	batched rm -f commands. The removal is best effort: the
#	caller already reports the failure that got it here.
sub _discard ( $self, @temps )
{
	while (@temps) {
		my @batch = splice @temps, 0, BATCH_PATHS;
		$self->{ssh}
		    ->run_command( $self->quote_argv( 'rm', '-f', @batch ) );
	}

	return;
}

1;
