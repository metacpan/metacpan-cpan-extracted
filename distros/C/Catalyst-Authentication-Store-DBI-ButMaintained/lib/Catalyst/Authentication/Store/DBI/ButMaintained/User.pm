package Catalyst::Authentication::Store::DBI::ButMaintained::User;
use strict;
use warnings;
use namespace::autoclean;

use Moose;
extends 'Catalyst::Authentication::User';

has 'store' => (
	isa => 'Object'
	, is => 'ro'
	, required => 1
	, handles => [qw/get_config _safe_escape/]
);

has 'authinfo' => ( isa => 'HashRef', is => 'ro', required => 1 );

has 'user' => (
	isa => 'HashRef'
	, is => 'ro'
	, required => 1
	, traits => ['Hash']
	, handles => { 'get' => 'get' }
);

## Currently requires user-role to be joined on single key
## TODO If we have user_role_table, and role_table AND role_key behave old way
## Provide option to have no role_table, and to handle composite key roles
## Append the conditionals in find_user
## Current workaround is to just subclass this and override the default
## Now possible with store_user_class
has 'dbi_model' => ( isa => 'Object', is => 'ro' );
has 'roles' => (
	isa => 'ArrayRef'
	, is => 'ro'
	, auto_deref => 1
	, lazy => 1
	, default => sub {
		my $self = shift;
		my $dbh = $self->dbi_model->dbh;

		my @field = (
			'role_table', 'role_name',
			'role_table',
			'user_role_table',
			'user_role_table', 'user_role_role_key',
			'role_table', 'role_key',
			'user_role_table', 'user_role_user_key'
		);

		my $sql = sprintf(
			'SELECT %s.%s FROM %s '
			. 'INNER JOIN %s ON %s.%s = %s.%s '
			. 'WHERE %s.%s = ?'
			, map { $dbh->quote_identifier($self->get_config($_)) } @field
		);

		my $sth = $dbh->prepare_cached($sql) or die($dbh->errstr());

		my $role;
		$sth->execute( $self->get($self->get_config('user_key')) )  or die($dbh->errstr());
		$sth->bind_columns(\$role) or die($dbh->errstr());

		my @roles;
		while ($sth->fetch()) {
			push @roles, $role;
		}
		$sth->finish();

		return \@roles;
	}
);

sub id {
	my $self = shift;
	return $self->get( $self->get_config('user_key') );
}

# sub supports is implemented by the base class, so supported_features is enough
sub supported_features { +{ session => 1, roles => 1 } }

sub BUILDARGS {
	my $class = shift;
	my ( $store, $user ) = @_;

	scalar @_ == 1
		? $class->SUPER::BUILDARGS(@_)
		: { store => $store, user => $user }
	;

}


## These are used in the base class for defaults
## Deprecated
sub get_object { +shift->user }
## Deprecated
sub obj { +shift->user }

1;

__END__

=head1 NAME

Catalyst::Authentication::Store::DBI::ButMaintained::User - User object representing a database record

=head1 DESCRIPTION

This class represents users found in the database and implements methods to access the contained information.

=head1 METHODS

=head2 new({ store => $objRef, user => $sth->fetchrow_hashref, auth_info => $hashRef, $dbi_model => $objRef })

=head3 Attributes

=over 4

=item store

Internal reference to the store.

=item user

Hash ref of the row from the database, what calls to C<get> read.

=item auth_info

Original hash ref supplied to C<find_user>

=item dbi_model

Required so it can retreive roles, in the future.

=back

=head2 id

=head2 supported_features

=head2 get

=head2 user

This method returns the original hash ref returned by the DB.

=head2 get_object

I<DEPRECATED> use C<user> instead

=head2 obj

I<DEPRECATED> use C<user> instead

=head2 roles

=head1 SEE ALSO

=over 4

=item L<Catalyst::Authentication::Store::DBI::ButMaintained>

=back

=head1 AUTHOR

Evan Carroll E<lt>cpan@evancarroll.comE<gt>

(old) Simon Bertrang, E<lt>simon.bertrang@puzzworks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2010 Evan Carroll, L<http://www.evancarroll.com/>

Copyright (c) 2008 PuzzWorks OHG, L<http://puzzworks.com/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
