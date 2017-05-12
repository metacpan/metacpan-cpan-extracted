# $Id: AutoReconnect.pm,v 1.3 2005/07/08 08:30:09 dk Exp $

package DBIx::AutoReconnect;

use DBI;
use strict;
use vars qw(%instances %defaults $VERSION);

$VERSION = '0.01';

%defaults = (
	ReconnectTimeout  => 60,
	ReconnectMaxTries => 5,
	ReconnectFailure  => undef,
);

sub connect
{
	my ( $class, $dsn, $user, $pass, $opt, @extras) = @_;

	$opt = {} unless $opt;
	my $profile = {
		conninfo   => [ $dsn, $user, $pass, $opt, @extras ],
		dbh	   => undef,
		do_connect => 1,
	};

	# XXX DBI doesn't say its defaults out, so hack
	$opt->{PrintError} = 1 unless defined $opt->{PrintError};

	for ( keys %defaults) {
		if ( exists $opt->{$_}) {
			$profile->{$_} = $opt->{$_};
			delete $opt->{$_};
		} else {
			$profile->{$_} = $defaults{$_};
		};
	}

	my $self = {};
	tie %{$self}, 'DBIx::AutoReconnect::TieHash', $profile;

	bless $self, $class;
	$instances{"$self"} = $profile;
	
	return $self-> __dbh_connect ? $self : undef;
}

sub __dbh_connect
{
	my $self = $instances{"$_[0]"};

	return $self-> {dbh} unless $self->{do_connect};

	my $tries = 0;
	my $downtime = 0;
	RETRY: while ( 1) {
		{
			local $self->{conninfo}->[3]-> {RaiseError} = 0; 
			if ( $self-> {dbh} = DBI-> connect( @{$self->{conninfo}})) {
				warn "DBIx::AutoReconnect: successfully reconnected after $tries tries and $downtime sec downtime\n"
					if $tries > 0 and $self->{conninfo}->[3]-> {PrintError};
				last RETRY;
			}
		}
		$self-> {ReconnectFailure}->() if $self-> {ReconnectFailure};
		$tries++;
		if ( defined ($self-> {ReconnectMaxTries}) and $self-> {ReconnectMaxTries} <= $tries) {
			if ( $self->{conninfo}->[3]-> {RaiseError}) {
				die $DBI::errstr;
			} else {
				return undef;
			}
		}
		if ( $self-> {ReconnectTimeout} > 0) {
			warn "DBIx::AutoReconnect: sleeping for $self->{ReconnectTimeout} seconds\n"
				if $self-> {conninfo}->[3]->{PrintError};
			sleep $self-> {ReconnectTimeout};
			$downtime += $self-> {ReconnectTimeout};
		}
	}

	return $self-> {dbh};
}

sub begin_work { 
	die "DBI::begin_work() is not to be used together with DBIx::AutoReconnect" 
}
sub rollback { 
	die "DBI::rollback() is not to be used together with DBIx::AutoReconnect" 
}
sub commit { 
	die "DBI::commit() is not to be used together with DBIx::AutoReconnect" 
}

sub get_handle { $instances{"$_[0]"}->{dbh} }

sub disconnect
{	
	my $self = $instances{"$_[0]"};

	$self-> {dbh}-> disconnect;
	$self-> {do_connect} = 0;
	$self-> {dbh} = undef;
}

sub AUTOLOAD
{
	use vars qw($AUTOLOAD);

	my $method = $AUTOLOAD;
	$method =~ s/^.*:([^:]+)$/$1/;

	my $obj = shift;
	my $self = $instances{"$obj"};

	my ( $ret, @ret);

	my $wa = wantarray;

	while ( 1) {
		unless ( $self->{dbh}) {
			$self-> {conninfo}->[3]-> {RaiseError} ?
				croak( "DBIx::AutoReconnect: not connected" ) :
				return;
		}

		eval {
			local $self->{dbh}->{RaiseError} = 1;
			if ( $wa) {
				@ret = $self-> {dbh}-> $method(@_);
			} else {
				$ret = $self-> {dbh}-> $method(@_);
			}
		};
		last unless $@;

		if ( $self->{dbh}->ping) {
			die $@;
		} else {
			$obj-> __dbh_connect;
		}
	}

	return $wa ? @ret : $ret;
}

sub DESTROY
{
	my $self = $instances{"$_[0]"};
	$self-> {do_connect} = 0;

	delete $instances{"$_[0]"};
}


package DBIx::AutoReconnect::TieHash;

sub TIEHASH
{
	my ( $class, $profile) = @_;
	bless $profile, $class;
}

sub FETCH
{
	my ( $self, $key) = @_;
	if ( exists $DBIx::AutoReconnect::defaults{$key}) {
		return $self-> {$key};
	} else {
		return $self-> {dbh}->{$key};
	}
}

sub STORE
{
	my ( $self, $key, $val) = @_;
	if ( exists $DBIx::AutoReconnect::defaults{$key}) {
		$self-> {$key} = $val;
	} else {
		$self-> {conninfo}->[3]->{$key} = $val;
		$self-> {dbh}->{$key} = $val;
	}
}

1;

__DATA__

=pod

=head1 NAME

DBIx::AutoReconnect - restart DBI calls after reconnecting on failure

=head1 DESCRIPTION

The module wraps C<< DBI->connect >> call with C<< DBIx::AutoReconnect->connect >>
call so that any operation with DB connection handle that fails due to
connection break ( server shutdown, tcp reset etc etc), is automatically
reconnected.

The module is useful when a little more robustness is desired for a cheap price;
the proper DB failure resistance should of course be inherent to the program logic.

=head1 SYNOPSIS

     use DBIx::AutoReconnect;

     my $dbh = DBIx::AutoReconnect-> connect(
           "dbi:Pg:dbname=template1",
	   "postgres",
	   "password",
	   {
	   	PrintError => 0,
		ReconnectTimeout => 5,
		ReconnectFailure => sub { warn "oops!" },
	   },
     );

=head1 USAGE

C<DBIx::AutoReconnect> contains a single method C<get_handle>
that returns underlying DBI handle, returned from C<< DBI->connect() >>.

The module-specific knobs that can be directly assigned to the object
handle, are described below

=over

=item ReconnectFailure &SUB

Called when C<< DBI->connect >> call fails.

=item ReconnectTimeout $SECONDS

Seconds to sleep after reconnection attempt fails.

Default: 60

=item ReconnectMaxTries $INTEGER

Max number of tries before giving up. The connections are tried
indefinitely if C<undef>.

Default: 5

=back

=head1 NOTES

Transactions are not restarted if connection breaks, moreover, C<begin_work>,
C<rollback>, and C<commit> die when called, to protect from unintentional use.
To use transactions, operate with the original DBI handle returned by
C<get_handle>. C<AutoCommit> is allowed though. 

C<RaiseError> is mostly useless with this module, because the DBI errors that
may raise the exception, are all wrapped in eval by the connection detector
code. The only place where it is useful, is when C<ReconnectMaxTries> tries are
exhausted, and depending on C<RaiseError>, the code dies or returns C<undef>
from the <connect> call.

=head1 SEE ALSO

L<DBI>, L<DBIx::Abstract>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>


=cut
