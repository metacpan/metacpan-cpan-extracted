package Catalyst::Authentication::User;
use Moose;
use namespace::autoclean;

with 'MooseX::Emulate::Class::Accessor::Fast';
use Scalar::Util qw/refaddr/;

## auth_realm is the realm this user came from.
__PACKAGE__->mk_accessors(qw/auth_realm store/);

## THIS IS NOT A COMPLETE CLASS! it is intended to provide base functionality only.
## translation - it won't work if you try to use it directly.

## chances are you want to override this.
sub id { shift->get('id'); }

## this relies on 'supported_features' being implemented by the subclass..
## but it is not an error if it is not.  it just means you support nothing.
## nihilist user objects are welcome here.
sub supports {
    my ( $self, @spec ) = @_;

    my $cursor = undef;
    if ($self->can('supported_features')) {
        $cursor = $self->supported_features;

        # traverse the feature list,
        for (@spec) {
            #die "bad feature spec: @spec" if ref($cursor) ne "HASH";
            return if ref($cursor) ne "HASH";

            $cursor = $cursor->{$_};
        }
    }

    return $cursor;
}

## REQUIRED.
## get should return the value of the field specified as it's single argument from the underlying
## user object.  This is here to provide a simple, standard way of accessing individual elements of a user
## object - ensuring no overlap between C::P::A::User methods and actual fieldnames.
## this is not the most effecient method, since it uses introspection.  If you have an underlying object
## you most likely want to write this yourself.
sub get {
    my ($self, $field) = @_;

    my $object;
    if ($object = $self->get_object and $object->can($field)) {
        return $object->$field();
    } else {
        return undef;
    }
}

## REQUIRED.
## get_object should return the underlying user object.  This is for when more advanced uses of the
## user is required.  Modifications to the existing user, etc.  Changes in the object returned
## by this routine may not be reflected in the C::P::A::User object - if this is required, re-authenticating
## the user is probably the best route to take.
## note that it is perfectly acceptable to return $self in cases where there is no underlying object.
sub get_object {
    return shift;
}

## obj is shorthand for get_object.  This is originally from the DBIx::Class store, but
## as it has become common usage, this makes things more compatible.  Plus, it's shorter.
sub obj {
    my $self = shift;
    return $self->get_object(@_);
}

sub AUTOLOAD {
    my $self = shift;
    (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $method eq "DESTROY";

    my $obj = $self->obj;
    # Don't bother unless we have a backing object
    return if refaddr($obj) eq refaddr($self);

    $obj->$method(@_);
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Authentication::User - Base class for user objects.

=head1 SYNOPSIS

    package MyStore::User;
    use base qw/Catalyst::Authentication::User/;

=head1 DESCRIPTION

This is the base class for authentication user objects.

THIS IS NOT A COMPLETE CLASS! it is intended to provide base functionality only.

It provides the base methods listed below, and any additional methods
are proxied onto the user object fetched from the underlieing store.

=head1 NOTES TO STORE IMPLEMENTORS

Please read the comments in the source code of this class to work out
which methods you should override.

=head1 METHODS

=head2 id( )

A unique ID by which a user can be retrieved from the store.

=head2 store( )

Should return a class name that can be used to refetch the user using it's
ID.

=head2 supports( )

An introspection method used to determine what features a user object has, to support credential and authorization plugins.

=head2 get( $field )

Returns the value for the $field provided.

=head2 get_object( )

Returns the underlying object storing the user data.  The return value of this
method will vary depending
on the storage module used.

=head2 obj( )

Shorthand for get_object( )

=head2 AUTOLOAD

Delegates any unknown methods onto the user object returned by ->obj

=cut

