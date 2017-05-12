package App::Shotgun::Target::SFTP;
BEGIN {
  $App::Shotgun::Target::SFTP::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $App::Shotgun::Target::SFTP::VERSION = '0.001';
}
use strict;
use warnings;

# ABSTRACT: App::Shotgun target for SFTP servers

use MooseX::POE::SweetArgs;
use POE::Component::Generic;

# argh, we need to fool Test::Apocalypse::Dependencies!
# Also, this will let dzil autoprereqs pick it up without actually loading it...
if ( 0 ) {
	require Net::SFTP::Foreign;
	require Expect; # to make sure SFTP can handle passwords
}

with qw(
	App::Shotgun::Target
	MooseX::LogDispatch
);


has port => (
	isa => 'Int',
	is => 'ro',
	default => 22,
);


has username => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);


has password => (
	isa => 'Str',
	is => 'ro',
	predicate => '_has_password',
);

# the poco-generic sftp subprocess
has sftp => (
	isa => 'Maybe[POE::Component::Generic]',
	is => 'rw',
	init_arg => undef,
);

# the master told us to shutdown
event shutdown => sub {
	my $self = shift;

	# remove the timeout timer
	$poe_kernel->delay( 'timeout_event' );

	# tell poco-generic to shutdown
	if ( defined $self->sftp ) {
		# TODO ARGH poco-generic NEEDS TO SHUTDOWN NOW
		# the problem is that it does a "graceful" shutdown
		# but the ssh process is stuck on password prompt
		# and everything freezes....
		$self->sftp->{'wheel'}->kill( 'KILL' );
		$poe_kernel->call( $self->sftp->session_id, 'shutdown' );
		$self->sftp( undef );
	}
};

sub START {
	my $self = shift;

	# spawn poco-generic
	$self->sftp( POE::Component::Generic->spawn(
		'alt_fork'		=> 1,	# conserve memory by using exec
		'package'		=> 'Net::SFTP::Foreign',
		'methods'		=> [ qw( error setcwd mkdir put ) ],

		'object_options'	=> [
			host => $self->hostname,
			port => $self->port,

			user => $self->username,
			( $self->_has_password ? ( password => $self->password ) : () ),

			timeout => 120,
		],

#		( 'debug' => 1, 'error' => 'sftp_generic_error' ),
	) );

	# set a timer in case the password negotiation/whatever doesnt work
	$poe_kernel->delay( 'timeout_event' => 120 );

	# check for connection error
	$self->sftp->error( { 'event' => 'sftp_connect' } );

	return;
}

event timeout_event => sub {
	my $self = shift;

	$self->error( "[" . $self->name . "] CONNECT error: timed out" );

	return;
};

event sftp_generic_error => sub {
	my( $self, $err ) = @_;

	# TODO poco-generic sucks for not properly shutting down
	return if ! defined $self->sftp;

	if( $err->{stderr} ) {
		# $err->{stderr} is a line that was printed to the
		# sub-processes' STDERR.  99% of the time that means from
		# your code.
		warn "Got stderr: $err->{stderr}";
	} else {
		# Wheel error.  See L<POE::Wheel::Run/ErrorEvent>
		# $err->{operation}
		# $err->{errnum}
		# $err->{errstr}
		warn "Got wheel error: $err->{operation} ($err->{errnum}): $err->{errstr}";
	}

	return;
};

event _parent => sub { return };
event _child => sub { return };

# actually transfer $file from the local dir to the remote
event transfer => sub {
	my $self = shift;

	# TODO poco-generic sucks for not properly shutting down
	return if ! defined $self->sftp;

	$self->state( 'xfer' );

	$self->logger->debug( "Target [" . $self->name . "] starting transfer of '" . $self->file . "'" );

	# Do we need to mkdir the file's path?
	my $dir = $self->file->dir->absolute( $self->path )->stringify;
	if ( ! $self->known_dir( $dir ) ) {
		# okay, go check it!
		$self->state( 'testdir' );
		$self->sftp->setcwd( { 'event' => 'sftp_setcwd', 'data' => $dir }, $dir );

		return;
	}

	# Okay, we are now ready to transfer the file
	$self->process_put;

	return;
};

sub process_put {
	my $self = shift;

	$self->state( 'xfer' );

	my $localpath = $self->file->absolute( $self->shotgun->source )->stringify;
	my $remotepath = $self->file->absolute( $self->path )->stringify;
	$self->sftp->put( { 'event' => 'sftp_put', 'data' => $remotepath }, $localpath, $remotepath );

	# TODO some optimizations to make compatibility better?
#		copy_time => 0,
#		copy_perm => 0,
#		perm => 0755,
}

event sftp_connect => sub {
	my( $self, $response ) = @_;

	# remove the timeout timer
	$poe_kernel->delay( 'timeout_event' );

	# TODO poco-generic sucks for not properly shutting down
	return if ! defined $self->sftp;

	# Did we get an error?
	if ( ! $response->{'result'}[0] ) {
		# set our cwd so we can initiate the transfer
		$self->sftp->setcwd( { 'event' => 'sftp_setcwd', 'data' => $self->path->stringify }, $self->path->stringify );
	} else {
		$self->error( "[" . $self->name . "] CONNECT error: " . $response->{'result'}[0] );
	}

	return;
};

event sftp_setcwd => sub {
	my( $self, $response ) = @_;

	# TODO poco-generic sucks for not properly shutting down
	return if ! defined $self->sftp;

	if ( $self->state eq 'init' ) {
		# success?
		if ( defined $response->{'result'}[0] ) {
			# we're set!
			$self->add_known_dir( $self->path->stringify );
			$self->ready( $self );
		} else {
			# get the error!
			$self->sftp->error( { 'event' => 'sftp_setcwd_error', 'data' => $self->path->stringify } );
		}
	} elsif ( $self->state eq 'testdir' ) {
		# success?
		if ( defined $response->{'result'}[0] ) {
			# we tried to cd to the full path, and it worked!
			$self->_build_filedirs;
			foreach my $d ( @{ $self->_filedirs } ) {
				$self->add_known_dir( $d );
			}

			# Okay, actually start the transfer!
			$self->process_put;
		} else {
			$self->_build_filedirs;

			# if there is only 1 path, we've "tested" it and no need to re-cd into it!
			if ( scalar @{ $self->_filedirs } == 1 ) {
				# we need to mkdir this one!
				$self->state( 'dir' );
				$self->sftp->mkdir( { 'event' => 'sftp_mkdir', 'data' => $self->_filedirs->[0] }, $self->_filedirs->[0] );
			} else {
				# we now cd to the first element
				$self->state( 'dir' );
				$self->sftp->setcwd( { 'event' => 'sftp_setcwd', 'data' => $self->_filedirs->[0] }, $self->_filedirs->[0] );
			}
		}
	} elsif ( $self->state eq 'dir' ) {
		# success?
		if ( defined $response->{'result'}[0] ) {
			# Okay, this dir is ok, move on to the next one
			$self->add_known_dir( shift @{ $self->_filedirs } );
			if ( defined $self->_filedirs->[0] ) {
				$self->sftp->setcwd( { 'event' => 'sftp_setcwd', 'data' => $self->_filedirs->[0] }, $self->_filedirs->[0] );
			} else {
				# finally validated the entire dir path
				$self->process_put;
			}
		} else {
			# we need to mkdir this one!
			$self->sftp->mkdir( { 'event' => 'sftp_mkdir', 'data' => $self->_filedirs->[0] }, $self->_filedirs->[0] );
		}
	} else {
		die "(CD) unknown state: " . $self->state;
	}

	return;
};

event sftp_setcwd_error => sub {
	my( $self, $response ) = @_;

	$self->error( "[" . $self->name . "] Error changing to initial path '" . $response->{'data'} . "': " . $response->{'result'}[0] );

	return;
};

event sftp_mkdir => sub {
	my( $self, $response ) = @_;

	# TODO poco-generic sucks for not properly shutting down
	return if ! defined $self->sftp;

	if ( $self->state eq 'dir' ) {
		# success?
		if ( $response->{'result'}[0] ) {
			# mkdir the next directory in the filedirs?
			$self->add_known_dir( shift @{ $self->_filedirs } );
			if ( defined $self->_filedirs->[0] ) {
				$self->sftp->mkdir( { 'event' => 'sftp_mkdir', 'data' => $self->_filedirs->[0] }, $self->_filedirs->[0] );
			} else {
				# Okay, finally done creating the entire path to the file!
				$self->process_put;
			}
		} else {
			$self->sftp->error( { 'event' => 'sftp_mkdir_error', 'data' => $response->{'data'} } );
		}
	} else {
		die "(MKDIR) unknown state: " . $self->state;
	}

	return;
};

event sftp_mkdir_error => sub {
	my( $self, $response ) = @_;

	$self->error( "[" . $self->name . "] MKDIR(" . $response->{'data'} . ") error: " . $response->{'result'}[0] );

	return;
};

event sftp_put => sub {
	my( $self, $response ) = @_;

	# TODO poco-generic sucks for not properly shutting down
	return if ! defined $self->sftp;

	# success?
	if ( $response->{'result'}[0] ) {
		# we're finally done with this transfer!
		$self->xferdone( $self );
	} else {
		$self->sftp->error( { 'event' => 'sftp_put_error', 'data' => $response->{'data'} } );
	}

	return;
};

event sftp_put_error => sub {
	my( $self, $response ) = @_;

	$self->error( "[" . $self->name . "] XFER(" . $response->{'data'} . ") error: " . $response->{'result'}[0] );

	return;
};

no MooseX::POE::SweetArgs;
__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

App::Shotgun::Target::SFTP - App::Shotgun target for SFTP servers

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Implements the SFTP ( FTP via SSH ) target.

Note: It is recommended to have ssh certificates set up for passwordless authentication. If you supply a password, L<Net::SFTP::Foreign>
will attempt to use L<Expect> to do the interaction, but you must have L<Expect> installed. Otherwise the connection will hang at the
password prompt and nothing will work!

=head1 ATTRIBUTES

=head2 port

The port to connect on the server.

The default is: 22

=head2 username

The username to login to the server with.

Required.

=head2 password

The password to login to the server with. Please see the note in L</DESCRIPTION> for more information.

The default is: none ( use ssh certificates )

=for Pod::Coverage process_put START

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Apocalypse <APOCAL@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software L<http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

