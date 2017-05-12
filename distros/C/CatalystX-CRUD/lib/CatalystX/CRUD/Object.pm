package CatalystX::CRUD::Object;
use Moose;
with 'MooseX::Emulate::Class::Accessor::Fast';
with 'Catalyst::ClassData';
use base 'CatalystX::CRUD';

use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';

__PACKAGE__->mk_ro_accessors(qw( delegate ));
__PACKAGE__->mk_classdata('delegate_class');

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD::Object - an instance returned from a CatalystX::CRUD::Model

=head1 SYNOPSIS

 package My::Object;
 use base qw( CatalystX::CRUD::Object );
 
 sub create { shift->delegate->save }
 sub read   { shift->delegate->load }
 sub update { shift->delegate->save }
 sub delete { shift->delegate->remove }
 
 1;

=head1 DESCRIPTION

A CatalystX::CRUD::Model returns instances of CatalystX::CRUD::Object.

The assumption is that the Object knows how to manipulate the data it represents,
typically by holding an instance of an ORM or other data model in the
C<delegate> accessor, and calling methods on that instance.

So, for example, a CatalystX::CRUD::Object::RDBO has a Rose::DB::Object instance,
and calls its RDBO object's methods.

The idea is to provide a common CRUD API for various backend storage systems.

=head1 METHODS

The following methods are provided.

=cut

=head2 new

Generic constructor. I<args> may be a hash or hashref.

=cut

sub new {
    my $class = shift;
    my $arg = ref( $_[0] ) eq 'HASH' ? $_[0] : {@_};
    return $class->next::method($arg);
}

=head2 delegate

The delegate() accessor is a holder for the object instance that the CXCO instance
has. A CXCO object "hasa" instance of another class in its delegate() slot. The
delegate is the thing that does the actual work; the CXCO object just provides a container
for the delegate to inhabit.

Think of delegate as a noun, not a verb, as in "The United Nations delegate often
slept here."


=head1 REQUIRED METHODS

A CXCO subclass needs to implement at least the following methods:

=over

=item create

Write a new object to store.

=item read

Load a new object from store.

=item update

Write an existing object to store.

=item delete

Remove an existing object from store.

=back

=cut

sub create { shift->throw_error("must implement create") }
sub read   { shift->throw_error("must implement read") }
sub update { shift->throw_error("must implement update") }
sub delete { shift->throw_error("must implement delete") }

=head2 is_new

Return results should be boolean indicating whether the object
already exists or not. Expectation is code like:

 if ($object->is_new) {
     $object->create;
 }
 else {
     $object->update;
 }

=cut

sub is_new { shift->throw_error("must implement is_new") }

=head2 serialize

Stringify the object. This class overloads the string operators
to call this method.

Your delegate class should implement a serialize() method
or stringify to something useful.

=cut

sub serialize {
    my $self = shift;
    return "" unless defined $self->delegate;
    return $self->delegate->can('serialize')
        ? $self->delegate->serialize
        : $self->delegate . "";
}

=head2 AUTOLOAD

Some black magic hackery to make Object classes act like
they are overloaded delegate()s.

=cut

sub AUTOLOAD {
    my $obj            = shift;
    my $obj_class      = ref($obj) || $obj;
    my $delegate_class = ref( $obj->delegate ) || $obj->delegate;
    my $method         = our $AUTOLOAD;
    $method =~ s/.*://;
    return if $method eq 'DESTROY';
    if ( $obj->delegate->can($method) ) {
        return $obj->delegate->$method(@_);
    }

    $obj->throw_error( "method '$method' not implemented in class "
            . "'$obj_class' or '$delegate_class'" );

}

# this overrides the basic can()
# to always call secondary can() on its delegate.
# we have to UNIVERSAL::can because we are overriding can()
# and would otherwise have a recursive nightmare.

=head2 can( I<method> )

Overrides basic can() method to call can() first on the delegate
and secondly (fallback) on the Object class itself.

=cut

sub can {
    my ( $obj, $method, @arg ) = @_;
    if ( ref($obj) ) {

        # object method tries object_class first,
        # then the delegate().
        my $subref = UNIVERSAL::can( ref($obj), $method );
        return $subref if $subref;
        if ( defined $obj->delegate ) {
            return $obj->delegate->can( $method, @arg );
        }
        return undef;
    }
    else {

        # class method
        return UNIVERSAL::can( $obj, $method );
    }
}

1;
__END__

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
