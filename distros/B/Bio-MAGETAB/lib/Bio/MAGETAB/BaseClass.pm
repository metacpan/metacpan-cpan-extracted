# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: BaseClass.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::BaseClass;

use Moose;
use MooseX::FollowPBP;

use Carp;
use Scalar::Util qw(weaken);

use MooseX::Types::Moose qw( Str );

has 'authority'           => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_authority',
                               predicate  => 'has_authority',
                               default    => q{},
                               required   => 1 );

has 'namespace'           => ( is         => 'rw',
                               isa        => Str,
                               clearer    => 'clear_namespace',
                               predicate  => 'has_namespace',
                               default    => q{},
                               required   => 1 );

# This is an abstract class; block direct instantiation.
sub BUILD {

    my ( $self, $params ) = @_;

    foreach my $param ( keys %{ $params } ) {
        my $getter = "get_$param";
        unless ( UNIVERSAL::can( $self, $getter ) ) {
            confess("ERROR: Unrecognised parameter: $param");
        }
    }

    if ( blessed $self eq __PACKAGE__ ) {
        confess("ERROR: Attempt to instantiate abstract class " . __PACKAGE__);
    }

    if ( my $container = __PACKAGE__->get_ClassContainer() ) {
        weaken $self;
        $container->add_objects( $self );
    }

    return;
}

{   # This is a class variable pointing to the container object with
    # which, when set, instantiated BaseClass objects will register.

    my $container;

    sub set_ClassContainer {

        my ( $self, $cont ) = @_;
        
        $container = $cont;
    }

    sub get_ClassContainer {

        my ( $self ) = @_;

        return $container;
    }

    sub has_ClassContainer {

        my ( $self ) = @_;

        return 1 if defined( $container );

        return;
    }
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB::BaseClass - Abstract base class for all MAGE-TAB classes.

=head1 SYNOPSIS

 use Bio::MAGETAB::BaseClass;

=head1 DESCRIPTION

This class is the abstract base class from which all of the MAGE-TAB
classes are derived. It cannot be instantiated directly, but provides
methods and attributes common to all MAGE-TAB objects.

=head1 ATTRIBUTES

=over 2

=item namespace (optional)

The namespace associated with any object identifiers (data type:
String).

=item authority (optional)

The authority responsible for assignment of object identifiers
(data type: String).

=back

=head1 METHODS

Each attribute has accessor (get_*) and mutator (set_*) methods, and
also predicate (has_*) and clearer (clear_*) methods where the
attribute is optional. Where an attribute represents a one-to-many
relationship the mutator accepts an arrayref and the accessor returns
an array.

Methods not related to instantiated object attributes are listed below:

=over 2

=item set_ClassContainer

Class method which stores a Bio::MAGETAB container object which will
then be used to store all subsequent instances of any
Bio::MAGETAB::BaseClass derived class (i.e., any MAGE-TAB object).

=item get_ClassContainer

Class method which retrieves the Bio::MAGETAB container object. This
can be used to navigate from a MAGE-TAB object instance to a listing
of all MAGE-TAB objects of a given type.

=item has_ClassContainer

Class method indicating whether or not a Bio::MAGETAB container object
has been associated with this class.

=back

=head1 SEE ALSO

L<Bio::MAGETAB>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
