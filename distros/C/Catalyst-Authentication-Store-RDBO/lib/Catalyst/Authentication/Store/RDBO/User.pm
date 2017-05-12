package Catalyst::Authentication::Store::RDBO::User;
use strict;
use warnings;

use base qw/Catalyst::Authentication::User/;
use base qw/Class::Accessor::Fast/;

BEGIN {
	__PACKAGE__->mk_accessors(qw/config user_class manager_class _user _roles/);
}

sub new
{
	my ($class, $config, $c) = @_;

	my $self = {
		user_class => $config->{'user_class'},
		manager_class => $config->{'manager_class'}
			? $config->{'manager_class'}
			: $config->{'user_class'} . '::Manager',
		config    => $config,
		_roles    => undef,
		_user     => undef
	};

	bless $self, $class;

	## Note to self- add handling of multiple-column primary keys.
	if(!exists($self->config->{'id_field'})) {
		my @pks = $self->user_class->meta->primary_key->column_names;
		if($#pks == 0) {
			$self->config->{'id_field'} = $pks[0];
		} else {
			Catalyst::Exception->throw("user table does not contain a single primary key column - please specify 'id_field' in config!");
		}
	}

	if(!$self->user_class->meta->column($self->config->{'id_field'})) {
		Catalyst::Exception->throw("id_field set to " . $self->config->{'id_field'} . " but user table has no column by that name!");
	}

	## if we have lazyloading turned on - we should not query the DB unless something gets read.
	## that's the idea anyway - still have to work out how to manage that - so for now we always force
	## lazyload to off.
	$self->config->{lazyload} = 0;

	return $self;
}

sub _fetch_first
{
	my ($self, $query ) = @_;
	my $results = $self->manager_class->get_objects(
		query => $query,
		object_class => $self->user_class,
		limit => 1,
	);
	if( ! $results || ! @$results) {
		return undef;
	}

	return $results->[0];
}

sub load
{
	my ($self, $authinfo, $c) = @_;

	my $rdbo_config = 0;

	if(exists($authinfo->{'rdbo'})) {
		$authinfo          = $authinfo->{'rdbo'};
		$rdbo_config = 1;
	}

	# User can provide an arrayref containing the arguments to search on
	# the user class by providing a 'rdbo' authinfo hash.
	if($rdbo_config && exists($authinfo->{'searchargs'})) {
		$self->_user( $self->_fetch_first( $authinfo->{'searchargs'}));
	} else {
		# merge the ignore fields array into a hash - so we can do an
		# easy check while building the query
		my %ignorefields = map { $_ => 1 } @{ $self->config->{'ignore_fields_in_find'} };
		my $searchargs = {};

		# now we walk all the fields passed in, and build up a search hash.
		foreach my $key (grep { !$ignorefields{$_} } keys %{$authinfo}) {
			if($self->user_class->meta->column($key)) {
				$searchargs->{$key} = $authinfo->{$key};
			}
		}
		if(keys %{$searchargs}) {
			$self->_user($self->_fetch_first( [ %$searchargs ]));
		} else {
			Catalyst::Exception->throw("User retrieval failed: no columns from " . $self->config->{'user_model'} . " were provided");
		}
	}

	if($self->get_object) {
		return $self;
	} else {
		return undef;
	}

}

sub supported_features
{
	my $self = shift;

	return {
		session => 1,
		roles   => 1,
	};
}

sub roles
{
	my ($self) = shift;

	## shortcut if we have already retrieved them
	if(ref $self->_roles eq 'ARRAY') {
		return (@{ $self->_roles });
	}

	my @roles = ();
	if(exists($self->config->{'role_column'})) {
		my $role_data = $self->get($self->config->{'role_column'});
		if($role_data) {
			@roles = split /[\s,\|]+/, $self->get($self->config->{'role_column'});
		}
		$self->_roles(\@roles);
	} elsif(exists($self->config->{'role_relation'})) {
		my $relation = $self->config->{'role_relation'};
		if(!$self->_user->meta->relationship($relation)) {
			Catalyst::Exception->throw('User object does not have a relation matching role_relation config');
		}
		my $role_field = $self->config->{'role_field'};
		if(!$self->_user->meta->relationship($relation)->foreign_class->meta->column($role_field)) {
			Catalyst::Exception->throw("role table does not have a column called " . $self->config->{'role_field'});
		}
		@roles = map { $_->$role_field } $self->_user->$relation;
		$self->_roles(\@roles);
	} else {
		Catalyst::Exception->throw("user->roles accessed, but no role configuration found");
	}

	return @{ $self->_roles };
}

sub for_session
{
	my $self = shift;

	return $self->get($self->config->{'id_field'});
}

sub from_session
{
	my ($self, $frozenuser, $c) = @_;

	my $id = $frozenuser;

	return $self->load({ $self->config->{'id_field'} => $id }, $c);
}

sub get
{
	my ($self, $field) = @_;

	if($self->_user->can($field)) {
		return $self->_user->$field;
	} else {
		return undef;
	}
}

sub get_object
{
	my ($self, $force) = @_;

	return $self->_user;
}

sub obj
{
	my ($self, $force) = @_;

	return $self->get_object($force);
}

sub AUTOLOAD
{
	my $self = shift;
	(my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
	return if $method eq "DESTROY";

	$self->_user->$method(@_);
}

1;

__END__

=head1 NAME

Catalyst::Authentication::Store::RDBO::User - The backing user
class for the Catalyst::Authentication::Store::RDBO storage
module.

=head1 VERSION

This documentation refers to version 0.1000.

=head1 SYNOPSIS

Internal - not used directly, please see
L<Catalyst::Authentication::Store::RDBO> for details on how to
use this module. If you need more information than is present there, read the
source.


=head1 DESCRIPTION

The Catalyst::Authentication::Store::RDBO::User class implements user storage
connected to an underlying Rose::DB::Object subclass.

=head1 SUBROUTINES / METHODS

=head2 new

Constructor.

=head2 load ( $authinfo, $c )

Retrieves a user from storage using the information provided in $authinfo.

=head2 supported_features

Indicates the features supported by this class.  These are currently Roles and Session.

=head2 roles

Returns an array of roles associated with this user, if roles are configured for this user class.

=head2 for_session

Returns a serialized user for storage in the session.

=head2 from_session

Revives a serialized user from storage in the session.

=head2 get ( $fieldname )

Returns the value of $fieldname for the user in question.  Roughly translates to a call to
the $fieldname method of the underlying Rose::DB::Object subclass.

=head2 get_object

Retrieves the underlying Rose::DB::Object-subclassed object that corresponds to this user

=head2 obj (method)

Synonym for get_object

=head2 auto_create

This is called when the auto_create_user option is turned on in
Catalyst::Plugin::Authentication and a user matching the authinfo provided is not found.
By default, this will call the C<auto_create()> method of the resultset associated
with this object. It is up to you to implement that method.

=head2 auto_update

This is called when the auto_update_user option is turned on in
Catalyst::Plugin::Authentication. Note that by default the RDBO store
uses every field in the authinfo hash to match the user. This means any
information you provide with the intent to update must be ignored during the
user search process. Otherwise the information will most likely cause the user
record to not be found. To ignore fields in the search process, you
have to add the fields you wish to update to the 'ignore_fields_in_find'
authinfo element.  Alternately, you can use one of the advanced row retrieval
methods (searchargs or resultset).

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Dave O'Neill (dmo@dmo.ca)

Based heavily on L<Catalyst::Authentication::Store::DBIx::Class> by Jason Kuri (jayk@cpan.org)

=head1 LICENSE

Copyright (c) 2008 the aforementioned authors. All rights
reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
