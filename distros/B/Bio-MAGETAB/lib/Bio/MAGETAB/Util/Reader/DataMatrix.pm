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
# $Id: DataMatrix.pm 368 2012-05-28 15:49:02Z tfrayner $

package Bio::MAGETAB::Util::Reader::DataMatrix;

use Moose;
use MooseX::FollowPBP;

use Carp;

BEGIN { extends 'Bio::MAGETAB::Util::Reader::Tabfile' };

has 'magetab_object'     => ( is         => 'rw',
                              isa        => 'Bio::MAGETAB::DataMatrix',
                              required   => 0 );

# This is used purely as a cache.
has '_array_design'      => ( is         => 'rw',
                              isa        => 'Bio::MAGETAB::ArrayDesign',
                              required   => 0 );

sub parse {

    my ( $self ) = @_;

    # Find or create the target DataMatrix object.
    my $data_matrix;
    unless ( $data_matrix = $self->get_magetab_object() ) {

        # This is typically a stand-alone DM. FIXME consider type as
        # another attribute or argument to this reader object?
        my $type = $self->get_builder()->find_or_create_controlled_term({
            category => 'DataType',    # FIXME hard-coded.
            value    => 'unknown',
        });
        $data_matrix = $self->get_builder()->find_or_create_data_matrix({
            uri               => $self->get_uri(),
            dataType          => $type,
        });
        $self->set_magetab_object( $data_matrix );
    }

    my $ad = $self->_determine_array_design( $data_matrix );
    $self->_set_array_design( $ad ) if $ad;

    # This has to be set for Text::CSV_XS.
    local $/ = $self->get_eol_char();

    my $qts;
    my $nodes;
    my $row_identifier_type;
    my $de_authority = q{};
    my $de_namespace = q{};
    my @matrix_rows;

    my $row_number = 1;

    FILE_LINE:
    while ( my $larry = $self->getline() ) {
    
        # Skip empty lines, comments.
        next FILE_LINE if $self->can_ignore( $larry );

	# Strip surrounding whitespace from each element.
        $larry = $self->strip_whitespace( $larry );

        if ( $row_number == 1 ) {
            $nodes = $self->_parse_node_heading( $larry );
        }
        elsif ( $row_number == 2 ) {
            ( $qts, $row_identifier_type, $de_namespace )
                = $self->_parse_qt_heading( $larry );

            # If namespace isn't explicitly given in the matrix
            # header, set it to the name of the enclosing array
            # design.
            if ( my $ad = $self->_get_array_design() ) {
                $de_authority = $ad->get_authority();
                unless ( defined $de_namespace ) {
                    $de_namespace = $ad->get_name();
                }
            }
        }
        else {
            my $element = $self->_parse_row_index(
                $larry->[0],
                $row_identifier_type,
                $de_namespace,
                $de_authority,
            );
            push @matrix_rows, $self->get_builder()->find_or_create_matrix_row({
                rowNumber     => $row_number,
                designElement => $element,
                data_matrix   => $data_matrix,
            });
        }

        $row_number++;
    }

    # Confirm we've read to the end of the file.
    $self->confirm_full_parse();

    # Sanity check.
    unless ( scalar @{ $qts } == scalar @{ $nodes } ) {
        croak(qq{Error: Mismatch in number of nodes and qt column headings.\n});
    }

    # Create the MatrixColumn objects.
    my @matrix_columns;
    for ( my $col_number = 0; $col_number < scalar @{ $qts }; $col_number++ ) {
        push @matrix_columns, $self->get_builder()->find_or_create_matrix_column({
            columnNumber     => $col_number,
            quantitationType => $qts->[ $col_number ],
            referencedNodes  => $nodes->[ $col_number ],
            data_matrix      => $data_matrix,
        });
    }

    $data_matrix->set_rowIdentifierType( $row_identifier_type );
    $data_matrix->set_matrixColumns( \@matrix_columns );
    $data_matrix->set_matrixRows( \@matrix_rows );
    $self->get_builder()->update( $data_matrix );

    return $data_matrix;
}

sub _determine_array_design {

    my ( $self, $object ) = @_;

    # Back out of the recursion quickly if we've already found an
    # array. FIXME consider throwing an exception if we just continue
    # looking and find more than one.
    foreach my $inputEdge ( $object->get_inputEdges() ) {
        my $previous = $inputEdge->get_inputNode();
        if ( UNIVERSAL::isa( $previous, 'Bio::MAGETAB::Assay' ) ) {
            return $previous->get_arrayDesign();
        }
        return $self->_determine_array_design( $previous );
    }
}

sub _parse_node_heading {

    my ( $self, $larry ) = @_;

    my @nodes;

    my %type_map = (
        qr/Normalization/ixms  => 'get_normalization',
        qr/Scan         /ixms  => 'get_data_acquisition',
        qr/Hybridization/ixms  => 'get_assay',
        qr/Assay        /ixms  => 'get_assay',
        
        qr/LabeledExtract/ixms => 'get_labeled_extract',
        qr/Extract       /ixms => 'get_extract',
        qr/Sample        /ixms => 'get_sample',
        qr/Source        /ixms => 'get_source',

        qr/(?:Derived)? [ ]? Array [ ]? Data [ ]? File/ixms => 'get_data_file',
    );

    my $getter;
    TYPE:
    while ( my ( $regex, $method ) = each %type_map ) {
        if ( $larry->[0] =~ /\A $regex [ ]? (?:REF)? \z/ixms ) {
            $getter = $method;
            last TYPE;
        }
    }

    unless ( $getter ) {
        croak(qq{Error: Unable to parse Node type from header "$larry->[0]".\n});
    }

    # Data files are internally identified by "uri"; all other nodes by "name".
    my $id_field = $getter eq 'get_data_file' ? 'uri' : 'name';
    foreach my $node_list ( @{ $larry }[1..$#$larry] ) {
        push @nodes, [
            map {
                $self->get_builder()->$getter({ $id_field => $_ })
            } split /\s*;\s*/, $node_list,
        ];
    }

    return \@nodes;
}

sub _parse_qt_heading {

    my ( $self, $larry ) = @_;

    my %type_map = (
        qr/Reporter/ixms               => 'Reporter',
        qr/Composite [ ]? Element/ixms => 'Composite Element',
        qr/Term [ ]? Source/ixms       => 'Term Source',
        qr/Coordinates/ixms            => 'Coordinates',
    );

    my $row_identifier_type;
    while ( my ( $regex, $id_type ) = each %type_map ) {
        if ( $larry->[0] =~ /\A $regex [ ]? (?:REF)? \z/ixms ) {
            $row_identifier_type = $id_type;
        }
    }

    unless ( $row_identifier_type ) {
        croak(qq{Error: Unable to parse rowIdentifierType from header "$larry->[0]".\n});
    }

    my ( $namespace ) = ( $larry->[0] =~/ REF:(.*) \z/ixms );

    my @qts;
    foreach my $qt ( @{ $larry }[1..$#$larry] ) {
        push @qts, $self->get_builder()->find_or_create_controlled_term({
            category => 'QuantitationType',    # FIXME hard-coded
            value    => $qt,
        });
    }

    return ( \@qts, $row_identifier_type, $namespace );
}

sub _parse_row_index {

    my ( $self, $index, $row_identifier_type, $de_namespace, $de_authority ) = @_;

    my %type_map = (
        'Reporter'          => 'reporter',
        'Composite Element' => 'composite_element',
        'Term Source'       => 'reporter',
        'Coordinates'       => 'reporter',
    );

    # We constrain how objects are created depending on
    # $row_identifier_type; for Term Source or Coordinates we don't
    # require that the parser already know about the objects. Note
    # that the Builder object may still override strict parsing for
    # Reporter/CompositeElement.
    my $method_prefix =
          $row_identifier_type eq 'Coordinates' ? 'find_or_create_'
        : $row_identifier_type eq 'Term Source' ? 'find_or_create_'
        : 'get_';

    my $method = $method_prefix . $type_map{ $row_identifier_type };

    # Start off with just Reporter/CompositeElement; we add different
    # arguments for Coordinates/Term Source style design elements.
    my $args = {
        name      => $index,
        namespace => $de_namespace,
        authority => $de_authority,
    };

    if ( $row_identifier_type eq 'Coordinates' ) {
        my ( $chr, $start, $end ) = ( $index =~ /([^:-]+) : (\d+) - (\d+)/ixms );
        unless ( defined $chr && defined $start && defined $end ) {
            croak(qq{Error: unable to parse Coordinates "$index"; must be in chrX:123-456 format.\n});
        }
        $args->{'chromosome'}    = $chr;
        $args->{'startPosition'} = $start;
        $args->{'endPosition'}   = $end;
    }
    elsif ( $row_identifier_type eq 'Term Source' ) {

        # Term Source Name must be in the $de_namespace (this is in
        # the MAGE-TAB spec).
        unless ( $de_namespace ) {
            croak(qq{Error: Data Matrix Term Source must include Name, e.g. "Term Source REF:embl".\n});
        }
        my $ts_obj = $self->get_builder()->get_term_source({
            'name' => $de_namespace,
        });

        # FIXME consider supporting semicolon-delimited accessions
        # here (not currently part of MAGE-TAB spec).
        my $term = $self->get_builder()->find_or_create_database_entry({
            accession  => $index,
            termSource => $ts_obj,
        });
        $args->{'databaseEntries'} = [ $term ];

        # In such cases this isn't really a namespace, so we get rid of it.
        delete $args->{'namespace'};
    }
    else {

        # Reporter, CompositeElement.
        $args->{'name'} = $index;
    }

    my $element = $self->get_builder()->$method($args);

    return $element;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Reader::DataMatrix - Data matrix parser class.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::Reader::DataMatrix;
 my $parser = Bio::MAGETAB::Util::Reader::DataMatrix->new({
     uri => $dm_filename,
 });
 my $data_matrix = $parser->parse();

=head1 DESCRIPTION

This class is used to parse data matrix files. It can be used on its own, but
more often you will want to use the main Bio::MAGETAB::Util::Reader
class which handles extended parsing options more transparently.

=head1 ATTRIBUTES

See the L<TabFile|Bio::MAGETAB::Util::Reader::TabFile> class for superclass attributes.

=over 2

=item magetab_object

A Bio::MAGETAB::DataMatrix object. This can either be set upon
instantiation, or a new object will be created for you. It can be
retrieved at any time using C<get_magetab_object>.

=back

=head1 METHODS

=over 2

=item parse

Parse the data matrix pointed to by C<$self-E<gt>get_uri()>. Returns
the Bio::MAGETAB::DataMatrix object updated with the data matrix
contents.

=back

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Reader::Tabfile>
L<Bio::MAGETAB::Util::Reader>
L<Bio::MAGETAB::DataMatrix>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
