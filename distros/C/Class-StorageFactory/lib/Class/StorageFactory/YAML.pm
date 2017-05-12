package Class::StorageFactory::YAML;

use strict;
use warnings;

use base 'Class::StorageFactory';

use Carp ();
use YAML qw( LoadFile DumpFile );
use File::Spec::Functions 'catfile';

sub fetch
{
	my ($self, $id) = @_;
	my $storage     = $self->storage();
	my $type        = $self->type();

	Carp::croak( 'No id specified for fetch()' ) unless $id;

	my $file        = catfile( $storage, $id . '.yml' );

	Carp::croak( "No file found for id '$id'" ) unless -e $file;

	my $data        = LoadFile( $file );
	$type->new( $data );
}

sub store
{
	my ($self, $id, $object) = @_;
	my $storage              = $self->storage();

	Carp::croak( 'No id specified for store()' ) unless $id;

	my $path                 = catfile( $storage, $id . '.yml' );
	DumpFile( $path, $object->data() );
}

1;
__END__

=head1 NAME

Class::StorageFactory::YAML - object factory to fetch and store objects via YAML

=head1 SYNOPSIS

    use Class::StorageFactory::YAML;

	my $astronauts = Class::StorageFactory::YAML->new(
		storage => 'astronaut_data',
		type    => 'Astronaut',
	);

	my $flyboy  = eval { $astronauts->fetch( 'Yeager' ) };
	warn "No Chuck found\n" if $@;

=head1 DESCRIPTION

Class::StorageFactory::YAML is an object factory to fetch and store object data
to and from YAML files.

=head1 METHODS

=over 4

=item C<new( storage =E<gt> $storage, type =E<gt> $type )>

Creates a new object of this class.  This takes two required parameters,
C<storage> and C<type>.  C<storage> is the name of the directory holding the
F<.yml> files associated with this factory.  C<type> is the name of the class
to use when creating objects.  If you store data for the C<Astronaut> module in
the F<astronaut_data> directory, create a factory with:

	my $space_camp = Class::StorageFactory::YAML->new( 
		storage => 'astronaut_data',
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

Given an astronaut's C<$id>, attempts to fetch the object from storage.  If the
object does not appear to exist based on C<$id>, this will throw an exception.
If it does exist, it will pass the data retrieved from storage to the
constructor for the class identified by the C<type> attribute (set in the
constructor).

In the example above, C<fetch()> looks for data for C<Yeager> in
F<astronaut_data/Yeager.yml>.

=item C<store( $id, $object )>

Calls the C<data()> method on the received C<$object> to retrieve the storable
data and stores it in the storage location, identified by the C<$id>.

If you want to clone an astronaut in C<$flyboy>, you can do so with:

	$space_camp->store( 'ChuckClone', $flyboy );

=back

=head1 AUTHOR

chromatic, E<lt>chromatic at wgz dot orgE<gt>

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2005, chromatic.  Some rights reserved.

This module is free software; you can use, redistribute, and modify it under
the same terms as Perl 5.8.
