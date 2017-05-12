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
# $Id: Builder.pm 351 2010-09-03 10:58:15Z tfrayner $

package Bio::MAGETAB::Util::Builder;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str HashRef Bool );

use Bio::MAGETAB;
use Carp;
use List::Util qw( first );
use English qw( -no_match_vars );

has 'authority'           => ( is         => 'rw',
                               isa        => Str,
                               default    => q{},
                               required   => 1 );

has 'namespace'           => ( is         => 'rw',
                               isa        => Str,
                               default    => q{},
                               required   => 1 );

has 'database'            => ( is         => 'rw',
                               isa        => HashRef,
                               default    => sub { {} },
                               required   => 1 );

has 'magetab'             => ( is         => 'ro',
                               isa        => 'Bio::MAGETAB',
                               default    => sub { Bio::MAGETAB->new() },
                               required   => 1 );

has 'relaxed_parser'      => ( is         => 'rw',
                               isa        => Bool,
                               default    => 0,
                               required   => 1 );

sub update {

    # Empty stub method; updates are not required when the objects are
    # all held in scope by the database hashref. This method is
    # overridden in persistence subclasses dealing with
    # e.g. relational databases.

    1;
}

sub _create_id {

    my ( $self, $class, $data, $id_fields ) = @_;

    unless ( first { defined $data->{ $_ } } @{ $id_fields } ) {
        my $allowed = join(', ', @{ $id_fields });
        confess(qq{Error: No identifying attributes for $class.}
              . qq{ Must use at least one of the following: $allowed.\n});
    }

    my $id = join(q{; }.chr(0), map { $data->{$_} || q{} } sort @{ $id_fields });

    # This really should never happen.
    unless ( $id ) {
        confess("Error: Null object ID in class $class.\n");
    }

    return $id;
}

sub _update_object_attributes {

    my ( $self, $obj, $data ) = @_;

    my $class = $obj->meta()->name();

    ATTR:
    while ( my ( $attr, $value ) = each %{ $data } ) {

        next ATTR unless ( defined $value );

        my $getter = "get_$attr";
        my $setter = "set_$attr";
        my $has_a  = "has_$attr";

        # Object either must have attr or has a predicate method.
        if( ! UNIVERSAL::can( $obj, $has_a ) || $obj->$has_a ) {

            my $attr_obj = $obj->meta->find_attribute_by_name( $attr );
            my $type = $attr_obj->type_constraint()->name();

            if ( $type =~ /\A ArrayRef/xms ) {
                if ( ref $value eq 'ARRAY' ) {
                    my @old = $obj->$getter;
                    foreach my $item ( @$value ) {
                         
                        # If this is a list attribute, add the new value.
                        unless ( first { $_ eq $item } @old ) {
                            push @old, $item;
                        }
                    }
                    $obj->$setter( \@old );
                }
                else {
                    croak("Error: ArrayRef value expected for $class $attr");
                }
            }
            else {
                
                # Otherwise, we leave it alone (older values take
                # precedence).
            }
        }
        else {

            # If unset to start with, we set the new value.
            $obj->$setter( $value );
        }
    }
}

sub _get_object {

    my ( $self, $class, $data, $id_fields ) = @_;

    my $id = $self->_create_id( $class, $data, $id_fields );

    # Strip out aggregator identifier components.
    $data = $self->_strip_aggregator_info( $class, $data );

    if ( my $retval = $self->get_database()->{ $class }{ $id } ) {
        return $retval;
    }
    elsif ( $self->get_relaxed_parser() ) {

        # If we're relaxing constraints, try and create an
        # empty object (in most cases this will probably fail
        # anyway).
        my $retval;
        eval {
            $retval = $self->_find_or_create_object( $class, $data, $id_fields );
        };
        if ( $EVAL_ERROR ) {
            croak(qq{Error: Unable to autogenerate $class with ID "$id": $EVAL_ERROR\n});
        }
        return $retval;
    }
    else {
        croak(qq{Error: $class with ID "$id" is unknown.\n});
    }
}

sub _create_object {

    my ( $self, $class, $data, $id_fields ) = @_;

    my $id = $self->_create_id( $class, $data, $id_fields );

    # Strip out aggregator identifier components
    $data = $self->_strip_aggregator_info( $class, $data );

    # Strip out any undefined values, which will only create problems
    # during object instantiation.
    my %cleaned_data;
    while ( my ( $key, $value ) = each %{ $data } ) {
        $cleaned_data{ $key } = $value if defined $value;
    }

    # Initial object creation. Namespace, authority can both be
    # overridden by $data, hence the order here. Note that we make no
    # special allowance for "global" objects such as DatabaseEntry
    # here; see Builder subclasses for smarter handling.
    my $obj = $class->new(
        'namespace' => $self->get_namespace(),
        'authority' => $self->get_authority(),
        %cleaned_data,
    );

    # Store object in cache for later retrieval.
    $self->get_database()->{ $class }{ $id } = $obj;

    return $obj;
}

sub _find_or_create_object {

    my ( $self, $class, $data, $id_fields ) = @_;

    my $id = $self->_create_id( $class, $data, $id_fields );

    # Strip out aggregator identifier components
    $data = $self->_strip_aggregator_info( $class, $data );

    my $obj;
    if ( $obj = $self->get_database()->{ $class }{ $id } ) {

        # Update the old object as appropriate.
        $self->_update_object_attributes( $obj, $data );
    }
    else {

        $obj = $self->_create_object( $class, $data, $id_fields );
    }

    return $obj;
}

# Hash of method types (find_or_create_*, get_*), pointing to an
# arrayref indicating the class to instantiate and the attributes to
# use in defining a unique internal identifier.
my %method_map = (
    'investigation'   => [ 'Bio::MAGETAB::Investigation',
                           qw( title ) ],

    'controlled_term' => [ 'Bio::MAGETAB::ControlledTerm',
                           qw( category value accession termSource ) ],

    'database_entry'  => [ 'Bio::MAGETAB::DatabaseEntry',
                           qw( accession termSource ) ],

    'term_source'     => [ 'Bio::MAGETAB::TermSource',
                           qw( name ) ],

    'factor'          => [ 'Bio::MAGETAB::Factor',
                           qw( name ) ],

    'factor_value'    => [ 'Bio::MAGETAB::FactorValue',
                           qw( factor term measurement ) ],

    'measurement'     => [ 'Bio::MAGETAB::Measurement',
                           qw( measurementType value minValue maxValue unit object ) ],

    'sdrf'            => [ 'Bio::MAGETAB::SDRF',
                           qw( uri ) ],

    'sdrf_row'        => [ 'Bio::MAGETAB::SDRFRow',
                           qw( rowNumber sdrf ) ],

    'protocol'        => [ 'Bio::MAGETAB::Protocol',
                           qw( name accession termSource ) ],

    # FIXME: Date not included for protocol_application to simplify the
    # implementation of the DBLoader class. We could include date, but
    # then we'd have to be careful how it serialises to the database
    # (c.f. uri). This is only useful in a rare use case (one edge,
    # with the same protocol applied multiple times on different
    # dates) and so we leave it out for now. Workaround: use more
    # edges.
    'protocol_application' => [ 'Bio::MAGETAB::ProtocolApplication',
                           qw( protocol edge ) ],

    'parameter_value' => [ 'Bio::MAGETAB::ParameterValue',
                           qw( parameter protocol_application ) ],

    'protocol_parameter' => [ 'Bio::MAGETAB::ProtocolParameter',
                           qw( name protocol ) ],

    'contact'         => [ 'Bio::MAGETAB::Contact',
                           qw( firstName midInitials lastName ) ],

    'publication'     => [ 'Bio::MAGETAB::Publication',
                           qw( title ) ],

    'source'          => [ 'Bio::MAGETAB::Source',
                           qw( name ) ],

    'sample'          => [ 'Bio::MAGETAB::Sample',
                           qw( name ) ],

    'extract'         => [ 'Bio::MAGETAB::Extract',
                           qw( name ) ],

    'labeled_extract' => [ 'Bio::MAGETAB::LabeledExtract',
                           qw( name ) ],

    'edge'            => [ 'Bio::MAGETAB::Edge',
                           qw( inputNode outputNode ) ],

    'array_design'    => [ 'Bio::MAGETAB::ArrayDesign',
                           qw( name accession termSource ) ],

    'assay'           => [ 'Bio::MAGETAB::Assay',
                           qw( name ) ],

    'data_acquisition' => [ 'Bio::MAGETAB::DataAcquisition',
                           qw( name ) ],

    'normalization'    => [ 'Bio::MAGETAB::Normalization',
                           qw( name ) ],

    'data_file'        => [ 'Bio::MAGETAB::DataFile',
                           qw( uri ) ],

    'data_matrix'      => [ 'Bio::MAGETAB::DataMatrix',
                           qw( uri ) ],

    'matrix_column'    => [ 'Bio::MAGETAB::MatrixColumn',
                           qw( columnNumber data_matrix ) ],

    'matrix_row'       => [ 'Bio::MAGETAB::MatrixRow',
                           qw( rowNumber data_matrix ) ],

    'feature'          => [ 'Bio::MAGETAB::Feature',
                           qw( blockCol blockRow col row array_design ) ],

    'reporter'          => [ 'Bio::MAGETAB::Reporter',
                           qw( name ) ],

    'composite_element' => [ 'Bio::MAGETAB::CompositeElement',
                           qw( name ) ],

    'comment'           => [ 'Bio::MAGETAB::Comment',
                           qw( name value object ) ],

);

# Arguments which aren't actual object attributes, but yet still
# contribute to its identity. Typically this is all about aggregation.
my %aggregator_map = (
    'Bio::MAGETAB::SDRFRow'              => [ qw( sdrf ) ],
    'Bio::MAGETAB::Comment'              => [ qw( object ) ],
    'Bio::MAGETAB::ProtocolApplication'  => [ qw( edge ) ],
    'Bio::MAGETAB::ParameterValue'       => [ qw( protocol_application ) ],
    'Bio::MAGETAB::MatrixColumn'         => [ qw( data_matrix ) ],
    'Bio::MAGETAB::MatrixRow'            => [ qw( data_matrix ) ],
    'Bio::MAGETAB::Measurement'          => [ qw( object ) ],
    'Bio::MAGETAB::Feature'              => [ qw( array_design ) ],
);

sub _strip_aggregator_info {

    my ( $self, $class, $data ) = @_;

    my %aux = map { $_ => 1 } @{ $aggregator_map{ $class } || [] };

    my ( %new_data, @discarded );
    while ( my ( $key, $value ) = each %$data ) {
        if ( $aux{ $key } ) {
            push @discarded, $key;
        }
        else {
            $new_data{ $key } = $value;
        }
    }

    return wantarray ? ( \%new_data, \@discarded ) : \%new_data;
}

{
    no strict qw(refs);
    while ( my( $item, $info ) = each %method_map ) {

        my ( $class, @id_fields ) = @{ $info };

        # Getter only; if the object is unfound, fail unless we're
        # being cool about it.
        *{"get_${item}"} = sub {
            my ( $self, $data ) = @_;

            return $self->_get_object(
                $class,
                $data,
                [ @id_fields ],
            );
	};

        # Flexible method to update a previous object or create a new one.
        *{"find_or_create_${item}"} = sub {
            my ( $self, $data ) = @_;

            return $self->_find_or_create_object(
                $class,
                $data,
                [ @id_fields ],
            );
        };

        # Sometimes we just want to instantiate whatever (ProtocolApps, ParamValues).
        *{"create_${item}"} = sub {
            my ( $self, $data ) = @_;

            return $self->_create_object(
                $class,
                $data,
                [ @id_fields ],
            );
        }
    }
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Builder - A storage class used to track
Bio::MAGETAB object creation.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::Builder;
 my $builder = Bio::MAGETAB::Util::Builder->new({
    relaxed_parser => $is_relaxed,
 });

=head1 DESCRIPTION

Creation of complex Bio::MAGETAB object heirarchies and DAGs requires
a mechanism to track the instantiated objects, and manage any
updates. This class (and its subclasses) provides that
mechanism. Builder objects are created and included in Reader object
instantiation, such that the back-end storage engine populated by a
given Reader object may be redefined as desired. This base Builder
class simply tracks objects in a hash of hashes; this is sufficient
for simple parsing of MAGE-TAB documents. See the
L<DBLoader|Bio::MAGETAB::Util::DBLoader> class for an example of a Builder subclass
that can be used to populate a Tangram-based relational database
schema.

=head1 ATTRIBUTES

=over 2

=item relaxed_parser

A boolean value (default FALSE) indicating whether or not the parse
should take place in "relaxed mode" or not. The regular parsing mode
will throw an exception in cases where an object is referenced before
it has been declared (e.g., Protocol REF pointing to a non-existent
Protocol Name). Relaxed parsing mode will silently autogenerate the
non-existent objects instead.

=item magetab

An optional Bio::MAGETAB container object. If none is passed upon
Builder object instantiation, a new Bio::MAGETAB object is created for
you. See the L<Bio::MAGETAB|Bio::MAGETAB> class for details.

=item authority

An optional authority string to be used in object creation.

=item namespace

An optional namespace string to be used in object creation.

=item database

The internal store to use for object lookups. In the base Builder
class this is a simple hash reference, and it is unlikely that you
will ever want to change the default. This attribute is used in
persistence subclasses (such as DBLoader) to point at the underlying
storage engine.

=back

=head1 METHODS

Each of the Bio::MAGETAB classes can be handled by get_*, create_* and
find_or_create_* methods.

=over 2

=item get_*

Retrieve the desired object from the database. Takes a hash reference
of attribute values and returns the desired object. This method raises
an exception if the passed-in attributes do not match any object in
the database. See L<OBJECT IDENTITY>, below, for information on how
objects are matched in the database.

=item create_*

Creates a new object using the passed attribute hash reference and
stores it in the database.

=item find_or_create_*

Attempts to find the desired object in the same way as the get_*
methods, and upon failure creates a new object and stores it.

=back

The following mapping should be used to determine the name of the
desired method:

 Bio::MAGETAB class                  Method base name
 ------------------                  ----------------

 Bio::MAGETAB::ArrayDesign           array_design
 Bio::MAGETAB::Assay                 assay
 Bio::MAGETAB::Comment               comment
 Bio::MAGETAB::CompositeElement      composite_element
 Bio::MAGETAB::Contact               contact
 Bio::MAGETAB::ControlledTerm        controlled_term
 Bio::MAGETAB::DataAcquisition       data_acquisition
 Bio::MAGETAB::DatabaseEntry         database_entry
 Bio::MAGETAB::DataFile              data_file
 Bio::MAGETAB::DataMatrix            data_matrix
 Bio::MAGETAB::Edge                  edge
 Bio::MAGETAB::Extract               extract
 Bio::MAGETAB::Factor                factor
 Bio::MAGETAB::FactorValue           factor_value
 Bio::MAGETAB::Feature               feature
 Bio::MAGETAB::Investigation         investigation
 Bio::MAGETAB::LabeledExtract        labeled_extract
 Bio::MAGETAB::MatrixColumn          matrix_column
 Bio::MAGETAB::MatrixRow             matrix_row
 Bio::MAGETAB::Measurement           measurement
 Bio::MAGETAB::Normalization         normalization
 Bio::MAGETAB::ParameterValue        parameter_value
 Bio::MAGETAB::Protocol              protocol
 Bio::MAGETAB::ProtocolApplication   protocol_application
 Bio::MAGETAB::ProtocolParameter     protocol_parameter
 Bio::MAGETAB::Publication           publication
 Bio::MAGETAB::Reporter              reporter
 Bio::MAGETAB::SDRF                  sdrf
 Bio::MAGETAB::SDRFRow               sdrf_row
 Bio::MAGETAB::Sample                sample
 Bio::MAGETAB::Source                source
 Bio::MAGETAB::TermSource            term_source

Example: a Bio::MAGETAB::DataFile object can be created using the
C<create_data_file> method.

In addition to the above, the following method is included to help
manage objects stored relational database backends (see the DBLoader
subclass):

=over 2

=item update

Passed a list of Bio::MAGETAB objects, this method will attempt to
update those objects in any persistent storage engine. This method
doesn't have any effect in the base Builder class, but it is very
important to the DBLoader subclass. See L<CAVEATS|Bio::MAGETAB::Util::DBLoader/CAVEATS> in the DBLoader class.

=back

=head1 OBJECT IDENTITY

For most Bio::MAGETAB classes, identity between objects is fairly
easily defined. For example, all Material objects have a name
attribute which identifies it within a given namespace:authority
grouping. However, many classes do not have this simple mechanism. For
example, Edge objects have no attributes other than their input and
output nodes, and a list of protocol applications. To address this,
the Builder module includes a set of identity heuristics defined for
each class; in this example, Edge will be identified by examining its
input and output nodes. Namespace and authority terms are used to
localize objects.

In theory this should all just work. However, the system is complex
and so undoubtedly there will be times when this module behaves other
than you might expect. Therefore, the current set of heuristics is
listed below for your debugging delight:

 Bio::MAGETAB class                Identity depends on:
 ------------------                -------------------
 Bio::MAGETAB::ArrayDesign         name accession termSource
 Bio::MAGETAB::Assay               name
 Bio::MAGETAB::Comment             name value object*
 Bio::MAGETAB::CompositeElement    name
 Bio::MAGETAB::Contact             firstName midInitials lastName
 Bio::MAGETAB::ControlledTerm      category value termSource accession
 Bio::MAGETAB::DataAcquisition     name
 Bio::MAGETAB::DatabaseEntry       accession termSource
 Bio::MAGETAB::DataFile            uri
 Bio::MAGETAB::DataMatrix          uri
 Bio::MAGETAB::Edge                inputNode outputNode
 Bio::MAGETAB::Extract             name
 Bio::MAGETAB::Factor              name
 Bio::MAGETAB::FactorValue         factor term measurement
 Bio::MAGETAB::Feature             blockCol blockRow col row array_design*
 Bio::MAGETAB::Investigation       title
 Bio::MAGETAB::LabeledExtract      name
 Bio::MAGETAB::MatrixColumn        columnNumber data_matrix*
 Bio::MAGETAB::MatrixRow           rowNumber data_matrix*
 Bio::MAGETAB::Measurement         measurementType value minValue maxValue unit object*
 Bio::MAGETAB::Normalization       name
 Bio::MAGETAB::ParameterValue      parameter protocol_application*
 Bio::MAGETAB::Protocol            name accession termSource
 Bio::MAGETAB::ProtocolApplication protocol edge*
 Bio::MAGETAB::ProtocolParameter   name protocol
 Bio::MAGETAB::Publication         title
 Bio::MAGETAB::Reporter            name
 Bio::MAGETAB::SDRF                uri
 Bio::MAGETAB::SDRFRow             rowNumber sdrf*
 Bio::MAGETAB::Sample              name
 Bio::MAGETAB::Source              name
 Bio::MAGETAB::TermSource          name

Not all the slots are needed for an object to be identified; for
example, a Contact object might only have a lastName. Asterisked (*)
terms are those which do not correspond to any attribute of the
Bio::MAGETAB class. These are typically "container" objects,
i.e. those involved in aggregating the target objects. For example,
the identity of a given Comment object is tied up with the "object" to
which it has been applied. These objects are passed in as part of the
object instantiation hash reference, and are discarded prior to object
creation. NOTE: These aggregating objects are not processed in any way
by Builder; you will need to ensure the objects are correctly linked
together yourself.

=head1 KNOWN BUGS

The identity of Bio::MAGE::ProtocolApplication objects is based solely
around the Protocol being applied, and the Edge to which it is
attached. Ideally, the protocol application date would also be
included, but this can create problems for persistence-based Builder
subclasses where the exact serialization behavior of DateTime objects
needs to be defined (see the L<DBLoader|Bio::MAGETAB::Util::DBLoader> class). This is a
tractable problem, but a fix has been omitted from this release since
the use case (the same Protocol applied to a single Edge multiple
times on different dates) seems a minor one. The workaround is to
split the protocol applications into as many Edges as are needed.

=head1 SEE ALSO

L<Bio::MAGETAB>
L<Bio::MAGETAB::Util::Reader>
L<Bio::MAGETAB::Util::DBLoader>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
