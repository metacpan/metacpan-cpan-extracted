package Class::StorageFactory;

use strict;
use warnings;

use vars '$VERSION';
$VERSION = '1.0';

use Carp ();

sub new
{
	my ($class, %args) = @_;

	for my $attribute (qw( storage type ))
	{
		Carp::croak( "No $attribute specified" ) unless $args{$attribute};
	}

	bless \%args, $class;
}

sub storage
{
	my $self = shift;
	return $self->{storage};
}

sub type
{
	my $self = shift;
	return $self->{type};
}

sub fetch
{
	Carp::croak( 'Unimplemented method fetch called in parent class' );
}

sub store
{
	Carp::croak( 'Unimplemented method store called in parent class' );
}

1;
__END__

=head1 NAME

Class::StorageFactory - base class for factories to store and fetch objects

=head1 SYNOPSIS

    use base 'Class::StorageFactory';

	sub fetch
	{
		my ($self, $id) = @_;
		my $storage     = $self->storage();
		my $type        = $self->type();
		# do something sensible here to fetch data based on $id and $storage

		return $type->new( $fetched_data );
	}

	sub store
	{
		my ($self, $id, $object) = @_;
		my $storage              = $self->storage();
		# do something sensible here to store data from object
	}

=head1 DESCRIPTION

Class::StorageFactory is a base class for object factories that build and store
objects.

This class provides only the barest methods for its purposes; the main
interface is through C<new()>, C<fetch()>, and C<store()>.

=head1 METHODS

=over 4

=item C<new( storage =E<gt> $storage, type =E<gt> $type )>

Creates a new object of this class.  This takes two required parameters,
C<storage> and C<type>.  C<storage> is an identifier (a file path, perhaps, or
the name of a table in a database) that tells the factory where to store and
fetch the objects it manages. C<type> is the name of the class to use when
creating objects.  If you store data for the C<Astronaut> module in the
F<astronauts> directory, create a factory with:

	my $space_camp = Class::StorageFactory::YAML->new( 
		storage => 'astronauts',
		type    => 'Astronaut',
	);

This method will throw an exception unless you have provided both attributes.

=item C<storage()>

Accessor for the C<storage> attribute set in the constructor.  You cannot set
this from here; you can only read it.

=item C<type()>

Accessor for the C<type> attribute set in the constructor.  You cannot set this
from here; you can only read it.

=item C<fetch( $id )>

This is an abstract method here that always throws an exception.  It has no
behavior in this class.  Override it in a subclass to do something sensible.

Given an object's C<$id>, attempts to fetch the object from storage.  If the
object does not appear to exist based on C<$id>, this will throw an exception.
If it does exist, it will pass the data retrieved from storage to the
constructor for the class identified by the C<type> attribute (set in the
constructor).

=item C<store( $id, $object )>

This is an abstract method here that always throws an exception.  It has no
behavior in this class.  Override it in a subclass to do something sensible.

Calls the C<data()> method on the received C<$object> to retrieve the storable
data and stores it in the storage location, identified by the C<$id>.

=back

=head1 AUTHOR

chromatic, E<lt>chromatic at wgz dot orgE<gt>

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2005, chromatic.  Some rights reserved.

This module is free software; you can use, redistribute, and modify it under
the same terms as Perl 5.8.
