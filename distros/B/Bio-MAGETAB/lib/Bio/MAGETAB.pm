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
# $Id: MAGETAB.pm 386 2014-04-11 14:54:54Z tfrayner $

# Convenience class for module loading and object tracking.
package Bio::MAGETAB;

use 5.008001;

use Moose;
use MooseX::FollowPBP;

use Bio::MAGETAB::BaseClass;

use List::Util qw(first);

use MooseX::Types::Moose qw( HashRef );

our $VERSION = 1.31;

# This cache is used to store all the Bio::MAGETAB objects registered
# with this instance (which, by default, is all of them).
has 'object_cache'          => ( is         => 'rw',
                                 isa        => HashRef,
                                 default    => sub{ {} },
                                 required   => 0 );

# Non-recursive, so we can set up e.g. a Util subdirectory without
# breaking anything.
my $magetab_modules = [
    qw(
       Bio::MAGETAB::ArrayDesign
       Bio::MAGETAB::Assay
       Bio::MAGETAB::BaseClass
       Bio::MAGETAB::Comment
       Bio::MAGETAB::CompositeElement
       Bio::MAGETAB::Contact
       Bio::MAGETAB::ControlledTerm
       Bio::MAGETAB::Data
       Bio::MAGETAB::DataAcquisition
       Bio::MAGETAB::DataFile
       Bio::MAGETAB::DataMatrix
       Bio::MAGETAB::DatabaseEntry
       Bio::MAGETAB::DesignElement
       Bio::MAGETAB::Edge
       Bio::MAGETAB::Event
       Bio::MAGETAB::Extract
       Bio::MAGETAB::Factor
       Bio::MAGETAB::FactorValue
       Bio::MAGETAB::Feature
       Bio::MAGETAB::Investigation
       Bio::MAGETAB::LabeledExtract
       Bio::MAGETAB::Material
       Bio::MAGETAB::MatrixColumn
       Bio::MAGETAB::MatrixRow
       Bio::MAGETAB::Measurement
       Bio::MAGETAB::Node
       Bio::MAGETAB::Normalization
       Bio::MAGETAB::ParameterValue
       Bio::MAGETAB::Protocol
       Bio::MAGETAB::ProtocolApplication
       Bio::MAGETAB::ProtocolParameter
       Bio::MAGETAB::Publication
       Bio::MAGETAB::Reporter
       Bio::MAGETAB::SDRF
       Bio::MAGETAB::SDRFRow
       Bio::MAGETAB::Sample
       Bio::MAGETAB::Source
       Bio::MAGETAB::TermSource
   ) ];

my %irregular_plural = (
    'BaseClass'     => 'BaseClasses',
    'Data'          => 'Data',
    'DataMatrix'    => 'DataMatrices',
    'DatabaseEntry' => 'DatabaseEntries',
);

# Load each module and install an accessor to return all the objects
# of each given class (and their subclasses).
foreach my $module ( @{ $magetab_modules } ) {

    ## no critic ProhibitStringyEval
    eval "require $module";
    ## use critic ProhibitStringyEval

    if ( $@ ) {
        die("Error loading module $module: $@");
    }

    my $slot = $module;
    my $namespace = __PACKAGE__;
    $slot =~ s/^${namespace}:://;
    $slot = $irregular_plural{$slot} || "${slot}s";
    $slot = lcfirst($slot);
    $slot =~ s/^SDRF/sdrf/i;

    {
        no strict qw(refs);

        *{"get_${slot}"} = sub {
            my ( $self ) = @_;
            return $self->get_objects( $module );
	};

        *{"has_${slot}"} = sub {
            my ( $self ) = @_;
            return scalar $self->get_objects( $module ) ? 1 : q{};
	};
    }
}

sub BUILD {

    my ( $self, $params ) = @_;

    foreach my $param ( keys %{ $params } ) {
        my $getter = "get_$param";
        unless ( UNIVERSAL::can( $self, $getter ) ) {
            confess("ERROR: Unrecognised parameter: $param");
        }
    }

    # Set the BaseClass container to the latest instance of this
    # class. FIXME this may get confusing; might be better just to get
    # the user to set this themselves?
    Bio::MAGETAB::BaseClass->set_ClassContainer( $self );

    return;
}

sub add_objects {

    my ( $self, @objects ) = @_;

    my $obj_hash = $self->get_object_cache();

    foreach my $object ( @objects ) {

        my $class = blessed $object;
        unless ( first { $_ eq $class } @{ $magetab_modules } ) {
            confess( qq{Error: Not a Bio::MAGETAB class: "$class"} );
        }

        $obj_hash->{ $class }{ $object } = $object;
    }

    $self->set_object_cache( $obj_hash );

    return;
}

sub delete_objects {

    my ( $self, @objects ) = @_;

    my $obj_hash = $self->get_object_cache();

    foreach my $object ( @objects ) {

        my $class = blessed $object;
        unless ( first { $_ eq $class } @{ $magetab_modules } ) {
            confess( qq{Error: Not a Bio::MAGETAB class: "$class"} );
        }

        delete $obj_hash->{ $class }{ $object }
    }

    $self->set_object_cache( $obj_hash );

    return;
}

sub get_objects {

    my ( $self, $class ) = @_;

    if ( $class ) {

        # We validate $class here.
        unless ( first { $_ eq $class } @{ $magetab_modules } ) {
            confess( qq{Error: Not a Bio::MAGETAB class: "$class"} );
        }

        # Recurse through all possible subclasses
        # (e.g. so that get_nodes() will return Material objects).
        my @members;
        foreach my $subclass ( $class, $class->meta->subclasses() ) {
            if ( my $objhash = $self->get_object_cache()->{ $subclass } ) {
                push @members, values %{ $objhash };
            }
        }

        return @members;
    }

    else {

        my @objects;
        while ( my ( $class, $objhash ) = each %{ $self->get_object_cache() } ) {
            push @objects, values %{ $objhash };
        }

        return @objects;
    }
}

__PACKAGE__->meta->make_immutable();

no Moose;

=pod

=head1 NAME

Bio::MAGETAB - A data model and utility API for the MAGE-TAB format.

=head1 SYNOPSIS

 # Use case 1: using Bio::MAGETAB simply to import all of the MAGE-TAB
 # classes:
 
 use Bio::MAGETAB;
 my $sample = Bio::MAGETAB::Sample->new({ name => "Sample 1" });

 # Use case 2: a Bio::MAGETAB object as a container for MAGE-TAB objects:
 
 use Bio::MAGETAB;
 
 # Instantiation automatically installs the new object as the default
 # container for objects subsequently instantiated from all classes
 # derived from Bio::MAGETAB::BaseClass.
 my $container = Bio::MAGETAB->new();
 
 # Create some samples.
 for ( 1 .. 4 ) {
    Bio::MAGETAB::Sample->new({ name => "Sample $_" });
 }
 
 # Retrieve all the Samples created so far.
 $container->get_samples();

=head1 DESCRIPTION

The Bio::MAGETAB module provides the core set of classes used to
support the perl MAGE-TAB API. This module provides a set of data
structures and type constraints which help to reliably handle data in
MAGE-TAB format. See the L<Reader|Bio::MAGETAB::Util::Reader>,
L<Writer|Bio::MAGETAB::Util::Writer> and
L<GraphViz|Bio::MAGETAB::Util::Writer::GraphViz> modules for classes
which can be used to read, write and visualize MAGE-TAB data
respectively.

This top-level Bio::MAGETAB class provides convenience methods for
managing MAGE-TAB objects. It can be used to import the class
namespaces needed for all the MAGE-TAB classes, but more usefully it
can also be used to create container objects which automatically track
object creation.

=head1 METHODS

=head2 Generic methods

=over 2

=item new

Instantiate a new container object. This method writes its result to a
Bio::MAGETAB::BaseClass class variable such that the new container
will automatically receive all subsequently instantiated MAGE-TAB
objects.

=item add_objects( @objects )

Add the passed objects to the Bio::MAGETAB container object. The
objects are sorted by class behind the scenes. Note that this method
is typically invoked for you upon instantiation of MAGE-TAB objects;
it is only needed in cases where you are using multiple Bio::MAGETAB
container classes.

=item delete_objects( @objects )

Delete the passed MAGE-TAB object from the container.

=item get_objects( $class )

Return all the remaining MAGE-TAB objects of the specified
class. Usually you will want one of the class-specific accessors
listed below which wrap this method, but C<get_objects> can be used as
a simple way of dynamically accessing the objects of multiple classes.

=back

=head2 Class-specific methods

Each MAGE-TAB class has its own predicate (has_*) and accessor (get_*)
method. Note that the C<has_baseClasses> and C<get_baseClasses>
methods can be used to query all MAGE-TAB objects held by the
container.

=over 2

=item has_arrayDesigns

Returns true if the container holds any ArrayDesign objects, and false
otherwise.

=item get_arrayDesigns

Returns all the ArrayDesign objects held by the container.

=item has_assays

Returns true if the container holds any Assay objects, and false
otherwise.

=item get_assays

Returns all the Assay objects held by the container.

=item has_baseClasses

Returns true if the container holds any BaseClass objects, and false
otherwise.

=item get_baseClasses

Returns all the BaseClass objects held by the container.

=item has_comments

Returns true if the container holds any Comment objects, and false
otherwise.

=item get_comments

Returns all the Comment objects held by the container.

=item has_compositeElements

Returns true if the container holds any CompositeElement objects, and false
otherwise.

=item get_compositeElements

Returns all the CompositeElement objects held by the container.

=item has_contacts

Returns true if the container holds any Contact objects, and false
otherwise.

=item get_contacts

Returns all the Contact objects held by the container.

=item has_controlledTerms

Returns true if the container holds any ControlledTerm objects, and false
otherwise.

=item get_controlledTerms

Returns all the ControlledTerm objects held by the container.

=item has_data

Returns true if the container holds any Data objects, and false
otherwise.

=item get_data

Returns all the Data objects held by the container.

=item has_dataAcquisitions

Returns true if the container holds any DataAcquisition objects, and false
otherwise.

=item get_dataAcquisitions

Returns all the DataAcquisition objects held by the container.

=item has_dataFiles

Returns true if the container holds any DataFile objects, and false
otherwise.

=item get_dataFiles

Returns all the DataFile objects held by the container.

=item has_dataMatrices

Returns true if the container holds any DataMatrix objects, and false
otherwise.

=item get_dataMatrices

Returns all the DataMatrix objects held by the container.

=item has_databaseEntries

Returns true if the container holds any DatabaseEntry objects, and false
otherwise.

=item get_databaseEntries

Returns all the DatabaseEntry objects held by the container.

=item has_designElements

Returns true if the container holds any DesignElement objects, and false
otherwise.

=item get_designElements

Returns all the DesignElement objects held by the container.

=item has_edges

Returns true if the container holds any Edge objects, and false
otherwise.

=item get_edges

Returns all the Edge objects held by the container.

=item has_events

Returns true if the container holds any Event objects, and false
otherwise.

=item get_events

Returns all the Event objects held by the container.

=item has_extracts

Returns true if the container holds any Extract objects, and false
otherwise.

=item get_extracts

Returns all the Extract objects held by the container.

=item has_factors

Returns true if the container holds any Factor objects, and false
otherwise.

=item get_factors

Returns all the Factor objects held by the container.

=item has_factorValues

Returns true if the container holds any FactorValue objects, and false
otherwise.

=item get_factorValues

Returns all the FactorValue objects held by the container.

=item has_features

Returns true if the container holds any Feature objects, and false
otherwise.

=item get_features

Returns all the Feature objects held by the container.

=item has_investigations

Returns true if the container holds any Investigation objects, and false
otherwise.

=item get_investigations

Returns all the Investigation objects held by the container.

=item has_labeledExtracts

Returns true if the container holds any LabeledExtract objects, and false
otherwise.

=item get_labeledExtracts

Returns all the LabeledExtract objects held by the container.

=item has_materials

Returns true if the container holds any Material objects, and false
otherwise.

=item get_materials

Returns all the Material objects held by the container.

=item has_matrixColumns

Returns true if the container holds any MatrixColumn objects, and false
otherwise.

=item get_matrixColumns

Returns all the MatrixColumn objects held by the container.

=item has_matrixRows

Returns true if the container holds any MatrixRow objects, and false
otherwise.

=item get_matrixRows

Returns all the MatrixRow objects held by the container.

=item has_measurements

Returns true if the container holds any Measurement objects, and false
otherwise.

=item get_measurements

Returns all the Measurement objects held by the container.

=item has_nodes

Returns true if the container holds any Node objects, and false
otherwise.

=item get_nodes

Returns all the Node objects held by the container.

=item has_normalizations

Returns true if the container holds any Normalization objects, and false
otherwise.

=item get_normalizations

Returns all the Normalization objects held by the container.

=item has_parameterValues

Returns true if the container holds any ParameterValue objects, and false
otherwise.

=item get_parameterValues

Returns all the ParameterValue objects held by the container.

=item has_protocols

Returns true if the container holds any Protocol objects, and false
otherwise.

=item get_protocols

Returns all the Protocol objects held by the container.

=item has_protocolApplications

Returns true if the container holds any ProtocolApplication objects, and false
otherwise.

=item get_protocolApplications

Returns all the ProtocolApplication objects held by the container.

=item has_protocolParameters

Returns true if the container holds any ProtocolParameter objects, and false
otherwise.

=item get_protocolParameters

Returns all the ProtocolParameter objects held by the container.

=item has_publications

Returns true if the container holds any Publication objects, and false
otherwise.

=item get_publications

Returns all the Publication objects held by the container.

=item has_reporters

Returns true if the container holds any Reporter objects, and false
otherwise.

=item get_reporters

Returns all the Reporter objects held by the container.

=item has_sdrfs

Returns true if the container holds any SDRF objects, and false
otherwise.

=item get_sdrfs

Returns all the SDRF objects held by the container.

=item has_sdrfRows

Returns true if the container holds any SDRFRow objects, and false
otherwise.

=item get_sdrfRows

Returns all the SDRFRow objects held by the container.

=item has_samples

Returns true if the container holds any Sample objects, and false
otherwise.

=item get_samples

Returns all the Sample objects held by the container.

=item has_sources

Returns true if the container holds any Source objects, and false
otherwise.

=item get_sources

Returns all the Source objects held by the container.

=item has_termSources

Returns true if the container holds any TermSource objects, and false
otherwise.

=item get_termSources

Returns all the TermSource objects held by the container.

=back

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Reader>
L<Bio::MAGETAB::Util::Writer>
L<Bio::MAGETAB::BaseClass>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
