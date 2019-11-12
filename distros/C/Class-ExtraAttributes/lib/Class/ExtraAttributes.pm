package Class::ExtraAttributes;

# version
$VERSION= '0.03';

# be as strict and verbose as possible
use strict;
use warnings;

# modules that we need
use OOB qw( OOB_get OOB_set );

# additionals attributes per class
my %attributes;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Class Methods
#
#-------------------------------------------------------------------------------
# attributes
#
# Return the extra attributes for the given class
#
#  IN: 1 Class::ExtraAttributes (ignored)
#      2 class to return extra attributes of (optional)
# OUT: 1 list (or list ref) with extra attributes

sub attributes {

    # fetch attributes
    my @attributes= keys %{ $attributes{ $_[1] || caller() } || {} };

    return wantarray ? @attributes : \@attributes;
}    #attributes

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
# import
#
# Export any constants requested
#
#  IN: 1 class (ignored)
#      2..N attributes to be defined

sub import {
    my $class= shift;

    # nothing to export
    return if !@_;

    # determine namespace to export to
    my $namespace=  caller();
    my $attributes= $attributes{$namespace} ||= {};

    # create accessor / mutator for given attributes
    no strict 'refs';
    foreach my $method ( grep { !exists $attributes->{$_} } @_ ) {

        # make sure we don't cloak anything
        die "Can already do '$method' on class $namespace"
          if $namespace->can($method);

        # install accessor / mutator
        $attributes->{$method}= undef;
        *{ $namespace . '::' . $method }= sub {
            return @_ == 2
             ? OOB_set( $_[0], $method => $_[1], $namespace )
             : OOB_get( $_[0], $method, $namespace );
        };
    }

    return;
}    #import

#-------------------------------------------------------------------------------

__END__

=head1 NAME

Class::ExtraAttributes - extra attributes for a class

=head1 VERSION

This documentation describes version 0.03.

=head1 SYNOPSIS

 package MyObject;
 use base qw( AnyClass );

 use Class::ExtraAttributes qw( foo );

 my $object = MyObject->new;
 $object->foo($value);
 my $value = $object->foo;

 sub update {  # in case you want persistence for extra attributes
     my $object= shift;
     $object->SUPER::update(@_);

     my @extra= Class::ExtraAttributes->attributes;
     # perform update for extra attributes
 }

 sub retrieve {  # in case you have persistence of extra attributes
     my $class= shift;
     $class->SUPER::retrieve(@_);

     my @extra= Class::ExtraAttributes->attributes;
     # perform retrieve of extra attributes
 }

=head1 DESCRIPTION

Ever ran into the problem that you want to subclass an existing class B<and>
add extra attributes to that class?  And run into the problem of having to
know the internal representation of that class in order to be able to do so?
Look no further, this module is (at least a large part) of the solution.

This module makes it possible to transparently add attributes to an existing
class (usually a subclass of a standard class) without interfering with the
functionality of that class.  This functionality is based on the L<OOB> class
which allows attributes to be added to any Perl data-structure.

Of course, this only applies to extra attributes on instantiated objects.
If there is a persistent backend for the class ( as there e.g. is with
L<Class::DBI> or L<DBIx::Class> ), then you will have to provide your own
persistence "update" and "retrieve" to the class.

=head1 THEORY OF OPERATION

Calling the C<import> routine in a given namespace (as is done with C<use>)
will export accessors / mutators with the given names into that namespace,
provided they don't exist yet.  These accessors / mutators in turn call the
C<OOB_set> and C<OOB_get> functions of the L<OOB> module.

=head2 CLASS METHODS

=head1 attributes

 my @attributes = Class::ExtraAttributes->attributes; # caller's namespace

 my $attributes = Class::ExtraAttributes->attributes($namespace);

The C<attributes> class method returns the names of the extra attributes that
have been declared for the (implictely) given namespace.  If no namespace is
specified, then the caller's namespace will be assumed.  The attributes are
returned as either a list (in list context) or as a list reference (in scalar
context).

=head1 REQUIRED MODULES

 OOB (0.08)

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

maintained by LNATION, <thisusedtobeanemail@gmail.com>

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2008, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
