# $Id: AutoReconnect.pm,v 1.4 2005/12/01 18:09:52 dk Exp $

package DBIx::Roles::AutoReconnect;

use strict;
use DBIx::Roles;
use vars qw(%defaults $VERSION);

$VERSION = '1.00';

%defaults = (
	ReconnectTimeout  => 60,
	ReconnectMaxTries => 5,
	ReconnectFailure  => undef,
);

sub initialize
{
	my $self = $_[0];
	return [], \%defaults;
}

sub connect
{
	my ( $self, $conninfo, $dsn, $user, $pass, $attr) = @_;

	@$conninfo = ( $dsn, $user, $pass, $attr );
	
	my ( $super, $private) = $self-> get_super;
	return unless $super;

	my $dbh = db_connect( $self, $conninfo, $super, $private);

	return $dbh;
}

sub db_connect
{
	my ( $self, $conninfo, $ref, @param) = @_;

	my $attr = $self-> {attr};
	my $tries = 0;
	my $downtime = 0;
	my $ret;
	RETRY: while ( 1) {
		{
			my $context = $self-> context;
			eval {
				local $conninfo->[3]->{RaiseError} = 1;
				$ret = $ref->( $self, @param, @$conninfo);
			};
			if ( $@) {
				# restore context if calls are restarted	
				$self-> context( $context);
			} elsif ( $ret) {
				warn "DBIx::Roles::AutoReconnect: successfully reconnected after $tries tries and $downtime sec downtime\n"
					if $tries > 0 and (
						$conninfo->[3]-> {PrintError} or
						not (exists $conninfo->[3]->{PrintError}) # DBI defaults
					);
				last RETRY;
			} else {
				$@ = "DBIx::Roles::AutoReconnect: Cannot connect(): no suitable roles found";
			}
		}
		$attr-> {ReconnectFailure}->() 
			if $attr-> {ReconnectFailure};
		$tries++;
		if ( 
			defined ($attr-> {ReconnectMaxTries}) and 
			$attr-> {ReconnectMaxTries} <= $tries
		) {
			$@ = "DBIx::Roles::AutoReconnect: Tried to connect $attr->{ReconnectMaxTries} time(s), giving up\n"
				unless $@;
			if ( $conninfo-> [3]-> {RaiseError}) {
				die $@;
			} else {
				warn $@ if 
					not (exists $conninfo->[3]->{PrintError}) # DBI defaults
					or $conninfo->[3]->{PrintError};
				return undef;
			}
		}
		if ( $attr-> {ReconnectTimeout} > 0) {
			warn "DBIx::AutoReconnect: sleeping for $attr->{ReconnectTimeout} seconds\n"
				if $conninfo-> [3]->{PrintError};
			sleep $attr-> {ReconnectTimeout};
			$downtime += $attr-> {ReconnectTimeout};
		}
	}

	return $ret;
}

sub dbi_method
{
	my ( $self, $conninfo, $method, @parameters) = @_;

	return $self-> super( $method, @parameters) 
		if $method eq 'connect' or not $self->dbh->{AutoCommit};

	my ( $wantarray, @ret) = ( wantarray);
	my ( $super, $private) = $self-> get_super;
	return unless $super;

	my $tries = 0;
	while ( 1) {
		if ( 
			defined ($self->{attr}-> {ReconnectMaxTries}) and 
			$self->{attr}-> {ReconnectMaxTries} <= $tries
		) {
			if ( $conninfo-> [3]-> {RaiseError}) {
				die "DBIx::Roles::AutoReconnect: Tried to call '$method' $self->{attr}->{ReconnectMaxTries} time(s), giving up\n";
			} else {
				warn "DBIx::Roles::AutoReconnect: Tried to call '$method' $self->{attr}->{ReconnectMaxTries} time(s), giving up\n" if
					not exists ($conninfo->[3]->{PrintError}) # DBI defaults
					or $conninfo->[3]->{PrintError};
				return;
			}
		}
		$tries++;

		unless ( $self-> dbh) {
			$conninfo-> [3]-> {RaiseError} ?
				croak( "DBIx::Roles::AutoReconnect: not connected" ) :
				return;
		}
		# repeatedly call the roles below until they succeed
		{
			local $self-> object-> {RaiseError} = 1;
			my $context = $self-> context;
			eval {
				if ( $wantarray) {
					@ret = $super-> ($self, $private, $method, @parameters);
				} else {
					$ret[0] = $super-> ($self, $private, $method, @parameters);
				}
			};
			return wantarray ? @ret : $ret[0]
				unless $@;
			# restore context if calls are restarted	
			$self-> context( $context);	
		}
		if ( $self-> dbh-> ping) {
			# DB is alive, most probably that was not a DBI-related error 
			if ( $conninfo-> [3]-> {RaiseError}) {
				die $@;
			} else {
				warn $@ if 
					not (exists $conninfo->[3]->{PrintError}) # DBI defaults
					or $conninfo->[3]->{PrintError};
				return;
			}
		} else {
			# without disconnect 
			$self-> dbh( $self-> connect( @$conninfo));
		}
	}
}

sub STORE
{
	my ( $self, $conninfo, $key, $val) = @_;
	if ( $key eq 'ReconnectTimeout' or $key eq 'ReconnectMaxTries') {
		die "Fatal: '$key' must be a positive integer"
			unless $val =~ /^\d+$/;
	} elsif ( $key eq 'ReconnectFailure') {
		die "Fatal: '$key' must be either 'undef' or a CODE reference"
			if not defined($val) or not ref($val) or ref($val) ne 'CODE';
	} elsif ( not exists $self->{defaults}->{$key}) {
		# update $attr for eventual reconnects
		$conninfo->[3]->{$key} = $val;
	}

	
	return $self-> super( $key, $val);
}

1;

__DATA__

=pod

=head1 NAME

DBIx::Roles::AutoReconnect - restart DBI calls after reconnecting on failure

=head1 DESCRIPTION

The role wraps all calls to DBI methods call so that any operation with DB
connection handle that fails due to connection break ( server shutdown, tcp
reset etc etc), is automatically reconnected.

The role is useful when a little more robustness is desired for a cheap price;
the proper DB failure resistance should of course be inherent to the program logic.

=head1 SYNOPSIS

     use DBIx::Roles qw(AutoReconnect);

     my $dbh = DBI-> connect(
           "dbi:Pg:dbname=template1",
	   "postgres",
	   "password",
	   {
	   	PrintError => 0,
		ReconnectTimeout => 5,
		ReconnectFailure => sub { warn "oops!" },
	   },
     );

=head1 Attributes

=over

=item ReconnectFailure &SUB

Called when a DBI method fails.

=item ReconnectTimeout $SECONDS

Seconds to sleep after reconnection attempt fails.

Default: 60

=item ReconnectMaxTries $INTEGER

Max number of tries before giving up. The connections are tried
indefinitely if C<undef>.

Default: 5

=back

=head1 NOTES

Transactions are not restarted if connection breaks or C<AutoCommit> is not set.

C<RaiseError> is not called when a connection is restarted, but rather when
C<ReconnectMaxTries> tries are exhausted, and depending on C<RaiseError>, the
code dies or returns C<undef> from the C<connect> call. All other error-related
attributes (C<PrintError>, C<HandleError>) are not affected.

=head1 SEE ALSO

L<DBI>, L<DBIx::Roles>, L<DBIx::AutoReconnect>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut
