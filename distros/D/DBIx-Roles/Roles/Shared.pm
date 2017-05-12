# $Id: Shared.pm,v 1.4 2005/12/19 15:02:00 dk Exp $

package DBIx::Roles::Shared;

use strict;
use vars qw(%instances %dsns $VERSION);

$VERSION = '1.00';

sub connect
{
	my ( $self, undef, $dsn, $user, $pass, $attr) = @_;

	my $inst_key = "$self";
	my $dsn_key = join( ' | ', $dsn, $user, $pass);
	my $dbh;

	if ( exists $instances{$inst_key}) {
		# apparently, connect() without disconnect --
		# 1. find if the object was connected to another handle, and clean it up
		keys %dsns; # reset each()
		while ( my ( $k, $v) = each %dsns) {
			my @d = grep { $_ != $self } @$v;
			next if @d == @$v;
			# found a connection
			last if $k eq $dsn_key; # yes, it is trying to reconnect
			# cleanup
			@d ? ( @$v = @d ) : delete $dsns{$k};
			delete $instances{"$self"};
			goto DEFAULT_CONNECT;
		}
		# 2. reconnect and apply the new handle to all the shared objects
		eval { $dbh = $self-> super( $dsn, $user, $pass, $attr); };
		my $exception = $@;
		
		for my $obj (@{$dsns{$dsn_key}}) { 
			$obj-> dbh( $dbh);
		}
		$instances{$inst_key} = $dbh; 

		die $exception if $exception;
	} else {
	DEFAULT_CONNECT:
		if ( exists $dsns{$dsn_key}) {
			# reuse an existing connection
			$dbh = $dsns{$dsn_key}-> [0]-> dbh;
		} else {
			# new connection
			$dbh = $self-> super( $dsn, $user, $pass, $attr);
			return undef unless $dbh;
			$instances{$inst_key} = $dbh; 
		}
		push @{$dsns{$dsn_key}}, $self;
	}

	return $dbh;
}

sub disconnect
{
	my $self = $_[0];

	keys %dsns; # reset each()
	while ( my ( $k, $v) = each %dsns) {
		my @d = grep { $_ != $self } @$v;
		if ( @d == @$v) {
			# not found
			next;
		} elsif ( @d) {
			# remove the shared connection from the list but do not disconnect 
			@$v = @d;
			delete $instances{"$self"};
			$self-> dbh( undef); # disconnect can be called twice
			return;
		} else {
			# that was the last reference, disconnect
			delete $dsns{$k};
			last;
		}
	}

	# also disconnect if wasn't found somehow
	delete $instances{"$self"};
	$self-> super();
}

1;

__DATA__

=head1 NAME

DBIx::Roles::Shared - Share DB connection handles

=head1 DESCRIPTION

Caches DB handles for already established connections, and returns these when
another C<connect> call is issued. Serves as a replacement to 
C<< DBI-> connect_cached >>.

=head1 SIDE EFFECTS

The roles allows itself some freedom with calling C<< $self-> dbh >> at will,
in particular, it assumes that result of C<connect> is stored in C<dbh>, and
is cleared after C<dbh>. The role probably won't work if these conditions
don't hold.

Any change to an intrinsic DBI attribute on a DB handle silently propagates the
attribute value to the other C<DBIx::Roles> objects that use the same handle.
It is possible to extend the role to virtualize the attributes, but I think
that would be an overkill.

Whenever C<connect> is called without previously calling C<disconnect>, the
role assumes that the DB handle is being reconnected, and updates all objects
that share the handle, with the new connection. This feature allows the role to
coexist with L<DBIx::Roles::AutoReconnect>.

=head1 SEE ALSO

L<DBIx::Roles>.

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut

