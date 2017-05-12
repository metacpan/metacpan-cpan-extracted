package Catalyst::Authentication::Store::DBI::User;
use strict;
use warnings;
use base 'Catalyst::Authentication::User';

=head1 NAME

Catalyst::Authentication::Store::DBI::User - User object representing a
database record

=head1 DESCRIPTION

This class represents users found in the database and implements methods to
access the contained information.

=head1 METHODS

=head2 new

=cut

sub new
{
	my ($class, $store, $user) = @_;

	unless ($user) {
		return undef;
	}

	my $self = {
		'store'	=> $store,
		'user'	=> $user,
	};

	bless($self, $class);

	return $self;
}

=head2 id

=cut

sub id
{
	my $self = shift;

	my $user_key = $self->{'store'}{'user_key'};

	return $self->{'user'}{$user_key};
}

# sub supports is implemented by the base class, so supported_features is enough

=head2 supported_features

=cut

sub supported_features
{
	my $self = shift;

	return {
		'session'	=> 1,
		'roles'		=> 1,
	};
}

=head2 get

=cut

sub get
{
	my ($self, $fieldname) = @_;

	unless (exists($self->{'user'}{$fieldname})) {
		return undef;
	}

	return $self->{'user'}{$fieldname};
}

=head2 get_object

This method returns the actual contents of the user, i.e. the hashref.

=head2 obj

Method alias to get_object for your convenience.

=cut

sub get_object
{
	my $self = shift;

	return $self->{'user'};
}

*obj = \&get_object;

=head2 roles

=cut

sub roles
{
	my $self = shift;

	if (exists($self->{'roles'}) && ref($self->{'roles'}) eq 'ARRAY') {
		return @{$self->{'roles'}};
	}

	my $store = $self->{'store'};
	my $dbh = $store->{'dbh'};
	my $sth;
	my $role;
	my @field = (
		'role_table', 'role_name',
		'role_table',
		'user_role_table',
		'user_role_table', 'user_role_role_key',
		'role_table', 'role_key',
		'user_role_table', 'user_role_user_key',
	);

	my $sql = sprintf('SELECT %s.%s FROM %s' .
	    ' INNER JOIN %s ON %s.%s = %s.%s WHERE %s.%s = ?',
	    map { $dbh->quote_identifier($store->{$_}) } @field);

	$sth = $dbh->prepare($sql) or die($dbh->errstr());
	$sth->execute($self->{'user'}{$store->{'user_key'}}) or
	    die($dbh->errstr());
	$sth->bind_columns(\$role) or die($dbh->errstr());
	while ($sth->fetch()) {
		push(@{$self->{'roles'}}, $role);
	}
	$sth->finish();

	return @{$self->{'roles'}};
}

=head1 SEE ALSO

=over 4

=item L<Catalyst::Authentication::Store::DBI>

=back

=head1 AUTHOR

Simon Bertrang, E<lt>simon.bertrang@puzzworks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 PuzzWorks OHG, L<http://puzzworks.com/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
