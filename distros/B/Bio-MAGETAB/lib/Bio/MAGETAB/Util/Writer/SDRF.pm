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
# $Id: SDRF.pm 378 2012-12-22 20:00:25Z tfrayner $

package Bio::MAGETAB::Util::Writer::SDRF;

use Moose;
use MooseX::FollowPBP;

use Carp;
use List::Util qw( sum max first );
use Scalar::Util qw( refaddr );

use MooseX::Types::Moose qw( ArrayRef );

BEGIN { extends 'Bio::MAGETAB::Util::Writer::Tabfile' };

has 'magetab_object'     => ( is         => 'ro',
                              isa        => 'Bio::MAGETAB::SDRF',
                              required   => 1 );

has '_table'             => ( is         => 'rw',
                              isa        => ArrayRef['ArrayRef'],
                              required   => 1,
                              default    => sub { [[]] }, );

has '_header'            => ( is         => 'rw',
                              isa        => ArrayRef,
                              required   => 1,
                              default    => sub { [] }, );

sub write {

    my ( $self ) = @_;

    # Create a defined matrix ($layers) indexed by columns and then
    # rows.
    my $sdrf       = $self->get_magetab_object();
    my @rows       = $sdrf->get_sdrfRows();
    my $node_lists = $self->_nodes_and_edges_from_rows( \@rows );

    # Generate the layer fragments to print out.
    my ( $table, $header ) = $self->_construct_lines( $node_lists );

    # Finally, dump everything to the file.
    my $max_column = max( map { scalar @{ $_ } } $header, @{ $table } );
    $self->set_num_columns( $max_column );
    foreach my $line ( $header, @{ $table } ) {
        $self->_write_line( @$line );
    }

    return;
}

sub _construct_lines {

    my ( $self, $node_lists ) = @_;

    # Quick Schwarzian transform to list the rows in order, longest
    # first.
    my @sorted_lists = map { $_->[1] }
                       reverse sort { $a->[0] <=> $b->[0] }
                       map { [ scalar @{ $_ }, $_ ] } @{ $node_lists };

    # Initialise our internal structures.
    $self->_set_header( [] );
    $self->_set_table( [ map { [] } 1 .. scalar @sorted_lists ] );

    # I think we're just processing Node, Edge and FactorValue objects here now.
    my %dispatch = (

        # Materials
        'Source'              => sub { $self->_process_sources( @_ )          },
        'Sample'              => sub { $self->_process_samples( @_ )          },
        'Extract'             => sub { $self->_process_extracts( @_ )         },
        'LabeledExtract'      => sub { $self->_process_labeledextracts( @_ )  },

        # Events
        'Assay'               => sub { $self->_process_assays( @_ )           },
        'DataAcquisition'     => sub { $self->_process_scans( @_ )            },
        'Normalization'       => sub { $self->_process_normalizations( @_ )   },

        # Data
        'DataFile'            => sub { $self->_process_datafiles( @_ )        },
        'DataMatrix'          => sub { $self->_process_datamatrices( @_ )     },

        # Edge
        'Edge'                => sub { $self->_process_edges( @_ )            },

        # FactorValue
        'FactorValue'         => sub { $self->_process_factorvalues( @_ )     },
    );

    while ( $self->_remaining_elements( \@sorted_lists ) ) {

        my ( $slice, $wanted ) = $self->_next_slice(
            \@sorted_lists,
            sub {
                my $id = ref $_[0];

                # FactorValues are a special case.
                if ( $id =~ /::FactorValue \z/xms ) {
                    $id .= '::' . $_[0]->get_factor()->get_name();
                }

                return $id;
            },
        );

        $wanted =~ s/\A Bio::MAGETAB:: //xms;
        if ( $wanted =~ /\b FactorValue \b/xms ) { $wanted = 'FactorValue' }

        if ( my $sub = $dispatch{ $wanted } ) {
            $sub->( $slice );
        }
        else {
            confess(qq{Error: Cannot find dispatch method for "$wanted".});
        }
    }

    return ( $self->_get_table(), $self->_get_header() );
}

sub _next_slice {

    # Given a list of (sorted) lists, and a code reference which when
    # passed an object in those lists will return an identifying
    # string, this method determines which object type is best to
    # process next, and, where the first element of a given list is of
    # that type shifts the object into a slice list of objects to be
    # processed.

    my ( $self, $nodelists, $coderef ) = @_;

    my @firstnodes = map { $_->[0] } @{ $nodelists };

    my $wanted = $self->_best_object_type( \@firstnodes, $coderef );

    my @slice = map { ( defined $_->[0] && $coderef->( $_->[0] ) eq $wanted )
                          ? shift @{$_} : undef }
                   @{ $nodelists };

    return wantarray ? ( \@slice, $wanted ) : \@slice;
}

sub _remaining_elements {

    my ( $self, $AoA ) = @_;

    return sum map { scalar grep { defined $_ } @{ $_ || [] } } @{ $AoA };
}

sub _best_object_type {

    # Given a list of objects and a coderef which can be used to
    # identify nodes in the list, return the best object type to use
    # for subsequent processing.

    # FIXME this needs to be *much* more sophisticated; voting and
    # potentially some deep list introspection needed. Currently we
    # just return the first identifier term we find.

    my ( $self, $nodes, $coderef ) = @_;

    # Handle either objects or strings.
    my @terms = map { $coderef->( $_ ) }
               grep { defined $_ }
                   @{ $nodes };

    return $terms[0];
}

sub _first_node_in_row {

    my ( $self, $row, $thisnode, $stackcount ) = @_;

    $stackcount++;
    if ( $stackcount > 256 ) {
        confess("Probable deep recursion while finding first node in"
                . " row. Are you sure you don't have any cycles?");
    }

    my @nodes = $row->get_nodes();

    $thisnode ||= $nodes[0];

    # Quick sanity check.
    unless ( first { refaddr $thisnode eq refaddr $_ } @nodes ) {
        confess("Error: Node is not in row list.");
    }

    if ( $thisnode->has_inputEdges() ) {
        foreach my $edge ( $thisnode->get_inputEdges() ) {
            my $prevnode = $edge->get_inputNode();

            if ( first { refaddr $prevnode eq refaddr $_ } @nodes ) {

                # Prior node found in this row.
                return $self->_first_node_in_row( $row,
                                                  $prevnode,
                                                  $stackcount );
            }
        }

        # Any prior nodes are not in this row.
        return $thisnode;
    }
    else {

        # If no input edges, we know it must be the first.
        return $thisnode;
    }
}

sub _nodes_and_edges_from_rows {

    my ( $self, $rows ) = @_;

    # Return the node lists in the same order as the rows were passed.
    my @lists;
    foreach my $row ( @{ $rows }  ) {
        my @nodes = $row->get_nodes();

        # Quick sanity check.
        my @input_nodes = grep { ! $_->has_inputEdges() } @nodes;
        my $num_inputs  = scalar @input_nodes;
        unless ( $num_inputs <= 1 ) {
            croak("Error: SDRFRow has multiple nodes without"
                      . " inputEdges ($num_inputs)");
        }

        # Recurse through the graph to find the first row node.
        my $current = $self->_first_node_in_row( $row );
        unless ( $current ) {
            croak("Error: Cannot identify a suitable starting node in SDRFRow.");
        }

        # Add all the nodes in the SDRFRow, in order, by following the
        # node-edge graph.
        my @ordered_nodes;
        my %in_this_row = map { refaddr $_ => 1 } @nodes;

        NODE:
        while ( $current->has_outputEdges() ) {
            foreach my $edge ( $current->get_outputEdges() ) {
                my $next = $edge->get_outputNode()
                    or croak("Error: Edge without an output node "
                              . "(this really shouldn't happen).");
                if ( $in_this_row{ refaddr $next } ) {
                    push @ordered_nodes, $current, $edge;
                    $current = $next;

                    # This assumes that no branching occurs within the
                    # SDRFRow; but then it shouldn't anyway.
                    next NODE;
                }
            }

            # $next not found in the row, so we bail.
            last NODE;
        }

        # This is now the last node.
        push @ordered_nodes, $current;

        # Add the FactorValues (sorted)
        my @fvs = sort { $a->get_factor()->get_name() cmp $b->get_factor()->get_name() }
                        $row->get_factorValues();
        push @ordered_nodes, @fvs;

        # Store the row nodes in the return array.
        push @lists, \@ordered_nodes;
    }

    return \@lists;
}

sub _add_single_column {

    my ( $self, $objs, $colname, $coderef ) = @_;

    my $header = $self->_get_header();
    push @{ $header }, $colname;
    $self->_set_header( $header );    # unnecessary?

    my $table  = $self->_get_table();
    OBJ:
    for ( my $i = 0; $i < scalar @{ $objs }; $i++ ) {
        my $obj = $objs->[ $i ];
        unless ( $obj ) {
            push @{ $table->[ $i ] }, undef;
            next OBJ;
        }
        push @{ $table->[ $i ] }, $coderef->($obj);
    }
    $self->_set_table( $table );    #unnecessary?
}    

sub _process_sources {

    my ( $self, $objs ) = @_;

    # Add our main node name column.
    $self->_add_single_column( $objs,
                               'Source Name',
                               sub { $_[0]->get_name() }, );

    # Comments
    $self->_process_objects( $objs );

    # Providers
    $self->_process_obj_contacts( $objs, 'Provider', 'get_providers' );

    # Hand the objects on to the next class processor in the
    # heirarchy.
    $self->_process_materials( $objs );
}

sub _format_contact_name {

    my ( $self, $contact ) = @_;

    my $first = $contact->get_firstName();
    my $last  = $contact->get_lastName();
    my @name;
    push @name, $first if ( defined $first );
    push @name, $last  if ( defined $last  );

    return join(" ", @name);
}

sub _process_obj_contacts {

    my ( $self, $objs, $colname, $getter ) = @_;

    # FIXME check if multiple Providers/Performers columns are allowed in the
    # format, and if not concatenate with semicolons.
    my @contacts = map {
        defined $_
            ? [ sort { $a->get_lastName() cmp $b->get_lastName() }
                       $_->$getter ]
            : []
        } @{ $objs };

    while ( $self->_remaining_elements( \@contacts ) ) {
        my $slice = $self->_next_slice( \@contacts,
                                        sub { $self->_format_contact_name( $_[0] ) } );
        $self->_process_contacts( $slice, $colname );
    }
}

sub _process_contacts {

    my ( $self, $objs, $colname ) = @_;

    $self->_add_single_column( $objs,
                               $colname,
                               sub { $self->_format_contact_name( $_[0] ) } );

    # Comments
    $self->_process_objects( $objs );
}

sub _process_samples {

    my ( $self, $objs ) = @_;

    # Add our main node name column.
    $self->_add_single_column( $objs,
                               'Sample Name',
                               sub { $_[0]->get_name() }, );

    # Comments
    $self->_process_objects( $objs );

    # Hand the objects on to the next class processor in the
    # heirarchy.
    $self->_process_materials( $objs );
}

sub _process_extracts {

    my ( $self, $objs ) = @_;

    # Add our main node name column.
    $self->_add_single_column( $objs,
                               'Extract Name',
                               sub { $_[0]->get_name() }, );

    # Comments
    $self->_process_objects( $objs );

    # Hand the objects on to the next class processor in the
    # heirarchy.
    $self->_process_materials( $objs );
}

sub _process_controlled_terms {

    my ( $self, $objs, $colname ) = @_;

    $self->_add_single_column( $objs,
                               $colname,
                               sub { $_[0]->get_value() }, );

    if ( scalar grep { $_ && defined $_->get_termSource() } @{ $objs } ) {
        $self->_process_dbentries( $objs );
    }
}

sub _process_dbentries {

    my ( $self, $objs ) = @_;

    $self->_add_single_column(
        $objs,
        'Term Source REF',
        sub { $_[0]->get_termSource()
            ? $_[0]->get_termSource()->get_name()
            : undef
        },
    );

    # Skip accessions for MAGE-TAB v1.0 export.
    if ( $self->get_export_version ne '1.0' ) {
        if ( scalar grep { $_ && defined $_->get_accession() } @{ $objs } ) {
            $self->_add_single_column( $objs,
                                       'Term Accession Number',
                                       sub { $_[0]->get_accession() }, );
        }
    }
}

sub _process_measurements {

    my ( $self, $objs, $colname ) = @_;

    # Values
    $self->_add_single_column(
        $objs,
        $colname,
        sub {

            # We support both regular values and min-max ranges. Sort of.
            my $value = $_[0]->get_value();
            my $min   = $_[0]->get_minValue();
            my $max   = $_[0]->get_maxValue();
            if ( defined $value && ! ( defined $min || defined $max ) ) {
                return $value
            }
            elsif ( defined $min && defined $max && ! defined $value ) {
                return sprintf("%s - %s", $min, $max);
            }
            else {
                croak("Error: Ambiguous Measurement - must have either"
                          . " value alone, or both minValue and maxValue.");
            }
        },
    );

    # Units
    my @units = map { $_ ? $_->get_unit() : undef } @{ $objs };
    my @defined = grep { defined $_ } @units;
    if ( scalar @defined ) {
        my $class = $defined[0]->get_category();    # First defined unit speaks for all.
        $self->_process_controlled_terms( \@units, "Unit [$class]" );
    }
}

sub _process_labeledextracts {

    my ( $self, $objs ) = @_;

    # Add our main node name column.
    $self->_add_single_column( $objs,
                               'Labeled Extract Name',
                               sub { $_[0]->get_name() }, );

    # Comments
    $self->_process_objects( $objs );

    # Label
    my @labels = map { $_ ? $_->get_label() : undef } @{ $objs };
    if ( scalar grep { defined $_ } @labels ) {
        $self->_process_controlled_terms( \@labels, 'Label' );
    }

    # Hand the objects on to the next class processor in the
    # heirarchy.
    $self->_process_materials( $objs );
}

sub _process_materials {

    my ( $self, $objs ) = @_;

    # Description
    if ( scalar grep { $_ && defined $_->get_description() } @{ $objs } ) {
        $self->_add_single_column( $objs,
                                   'Description',
                                   sub { $_[0]->get_description() }, );
    }

    # Material Type
    my @types = map { $_ ? $_->get_materialType() : undef } @{ $objs };
    if ( scalar grep { defined $_ } @types ) {
        $self->_process_controlled_terms( \@types, 'Material Type' );
    }

    # Characteristics
    my @chars = map {
        defined $_
            ? [ sort { $a->get_category() cmp $b->get_category() }
                       $_->get_characteristics() ]
            : []
        } @{ $objs };

    while ( $self->_remaining_elements( \@chars ) ) {
        my ( $slice, $category ) =
            $self->_next_slice( \@chars, sub { $_[0]->get_category() } );
        $self->_process_controlled_terms( $slice, "Characteristics [$category]" );
    }

    # Measurements
    my @measurements = map {
        defined $_
            ? [ sort { $a->get_measurementType() cmp $b->get_measurementType() }
                       $_->get_measurements() ]
            : []
        } @{ $objs };

    while ( $self->_remaining_elements( \@measurements ) ) {
        my ( $slice, $type ) =
            $self->_next_slice( \@measurements, sub { $_[0]->get_measurementType() } );
        $self->_process_measurements( $slice, "Characteristics [$type]" );
    }
}

sub _process_objects {

    my ( $self, $objs ) = @_;

    my @comments = map {
        defined $_
            ? [ sort { $a->get_name() cmp $b->get_name() }
                       $_->get_comments() ]
            : []
        } @{ $objs };

    while ( $self->_remaining_elements( \@comments ) ) {
        my ( $slice, $name ) = $self->_next_slice( \@comments, sub { $_[0]->get_name() } );
        $self->_process_comments( $slice, $name );
    }
}

sub _process_comments {

    my ( $self, $objs, $name ) = @_;

    $self->_add_single_column( $objs,
                               sprintf('Comment [%s]', $name),
                               sub { $_[0]->get_value() }, );
}

sub _process_assays {

    my ( $self, $objs ) = @_;

    # The change from 1.0 to 1.1 had consequences for Assays.
    my $is_original_spec = $self->get_export_version() eq '1.0';

    # Again, the first defined assay makes our choice between Hyb and
    # Assay; this is not good FIXME.
    my @defined = grep { defined $_ } @{ $objs };
    my $type = $defined[0]->get_technologyType();
    if ( $type->get_value() =~ /\b (hybridi[sz]ation|array[ ]+assay) \b/xms ) {

        # Assay Name only available in 1.1 and above.
        my $name = $is_original_spec ? 'Hybridization Name'
                                     : 'Assay Name';
        $self->_add_single_column( $objs,
                                   $name,
                                   sub { $_[0]->get_name() }, );

        # Comments
        $self->_process_objects( $objs );

        # Array Design
        my @arrays = map { $_ ? $_->get_arrayDesign() : undef } @{ $objs };
        if ( scalar grep { defined $_ } @arrays ) {
            $self->_process_array_designs( \@arrays );
        }
    }
    elsif ( ! $is_original_spec ) {
        $self->_add_single_column( $objs,
                                   'Assay Name',
                                   sub { $_[0]->get_name() }, );

        # Comments
        $self->_process_objects( $objs );
    }
    else {
        croak("Error: Attempting to export non-hybridization Assay type in MAGE-TAB v1.0 format.");
    }

    # We add Technology Type to both Assay and Hybridization for
    # versions 1.1 and above; this is both legal and more consistent
    # than previous behaviours. Technology Type is not available in
    # version 1.0.
    if ( ! $is_original_spec ) {
        my @types = map { $_ ? $_->get_technologyType() : undef } @{ $objs };
        if ( scalar grep { defined $_ } @types ) {
            $self->_process_controlled_terms( \@types, 'Technology Type' );
        }
    }
}

sub _process_array_designs {

    my ( $self, $objs ) = @_;

    # FIXME first defined array design determines whether it's a File
    # or a REF. This isn't great.
    my @defined = grep { defined $_ } @{ $objs };
    if ( $defined[0]->has_uri() ) {
        $self->_add_single_column( $objs,
                                   'Array Design File',
                                   sub { $_[0]->get_uri() }, );
    }
    else {

        # FIXME REF columns may need a namespace:authority tag?
        $self->_add_single_column( $objs,
                                   'Array Design REF',
                                   sub { $_[0]->get_name() }, );

        # REFs can have Term Source, accession, and comments. Array
        # Design File comments would normally be handled in the ADF.
        $self->_process_dbentries( $objs );
        $self->_process_objects( $objs );
    }
}

sub _process_scans {

    my ( $self, $objs ) = @_;

    $self->_add_single_column( $objs,
                               'Scan Name',
                               sub { $_[0]->get_name() }, );

    # Comments
    $self->_process_objects( $objs );
}

sub _process_normalizations {

    my ( $self, $objs ) = @_;

    $self->_add_single_column( $objs,
                               'Normalization Name',
                               sub { $_[0]->get_name() }, );

    # Comments
    $self->_process_objects( $objs );
}

sub _process_datafiles {

    my ( $self, $objs ) = @_;

    # FIXME first defined data file determines whether the column
    # contains image, raw or derived data. This isn't great.
    my @defined = grep { defined $_ } @{ $objs };
    my $type = $defined[0]->get_dataType()->get_value();
    my $colname = $type eq 'image' ? 'Image File'
                : $type eq 'raw'   ? 'Array Data File'
                                   : 'Derived Array Data File';

    $self->_add_single_column( $objs,
                               $colname,
                               sub { $_[0]->get_uri() }, );

    # Comments
    $self->_process_objects( $objs );
}

sub _process_datamatrices {

    my ( $self, $objs ) = @_;

    # FIXME first defined data file determines whether the column
    # contains raw or derived data. This isn't great.
    my @defined = grep { defined $_ } @{ $objs };
    my $type = $defined[0]->get_dataType()->get_value();
    my $colname = $type eq 'raw'   ? 'Array Data Matrix File'
                         : 'Derived Array Data Matrix File';

    $self->_add_single_column( $objs,
                               $colname,
                               sub { $_[0]->get_uri() }, );

    # Comments
    $self->_process_objects( $objs );
}

sub _process_edges {

    my ( $self, $objs ) = @_;

    # Protocol Applications; we don't sort these because the order is
    # supposedly already set to indicate chronological order.
    my @papps = map { [ $_ ? $_->get_protocolApplications() : undef ] } @{ $objs };

    while ( $self->_remaining_elements( \@papps ) ) {
        my ( $slice, $pname ) =
            $self->_next_slice( \@papps, sub { $_[0]->get_protocol()->get_name() } );
        $self->_process_protocolapps( $slice );
    }
}

sub _process_protocolapps {

    my ( $self, $objs ) = @_;

    # FIXME namespace/authority may also be needed here.
    $self->_add_single_column( $objs,
                              'Protocol REF',
                              sub { $_[0]->get_protocol()->get_name() } );

    # Term Source, accession.
    my @protocols = map { $_ ? $_->get_protocol() : undef } @{ $objs };
    $self->_process_dbentries( \@protocols );

    # Comments
    $self->_process_objects( $objs );

    # Date
    if ( scalar grep { $_ && defined $_->get_date() } @{ $objs } ) {
        $self->_add_single_column( $objs,
                                   'Date',
                                   sub { $_[0]->get_date() }, );
    }

    # Performers
    $self->_process_obj_contacts( $objs, 'Performer', 'get_performers' );

    # ParameterValues
    my @pvals = map {
        defined $_
            ? [ sort { $a->get_parameter() cmp $b->get_parameter() }
                       $_->get_parameterValues() ]
            : []
        } @{ $objs };

    while ( $self->_remaining_elements( \@pvals ) ) {
        my ( $slice, $param ) =
            $self->_next_slice( \@pvals, sub { $_[0]->get_parameter()->get_name() } );

        $self->_process_parametervalues( $slice, $param );
    }
}

sub _process_parametervalues {

    my ( $self, $objs, $param ) = @_;

    # Similar to FVs below, only PVs from only one parameter name are
    # passed in at any given time.
    my $colname = "Parameter Value [$param]";
    my @defined = grep { defined $_ } @{ $objs };

    # However, we've not established that all PVs are term- or
    # measurement-based, and yet we make that assumption here FIXME.
    if ( $defined[0]->has_term() ) {

        # As of MAGE-TAB v1.1 (June 2009) ParameterValue can have
        # controlled term.
        my @terms = map { $_ ? $_->get_term() : undef } @{ $objs };
        if ( scalar @terms > 0 && $self->get_export_version eq '1.0' ) {
            croak("Error: Cannot export ParameterValues with ControlledTerms"
                      . " under the MAGE-TAB v1.0 specification.");
        }

        $self->_process_controlled_terms( \@terms, $colname );
    }
    elsif ( $defined[0]->has_measurement() ) {
        my @meas = map { $_ ? $_->get_measurement() : undef } @{ $objs };
        $self->_process_measurements( \@meas, $colname );
    }
    else {
        croak("Error: FactorValue has no term or measurement.");
    }

    # ParameterValue Comments
    $self->_process_objects( $objs );
}

sub _process_factorvalues {

    my ( $self, $objs ) = @_;

    # We've previously established that FVs from only one factor are
    # passed to this method at any given time.
    my @defined = grep { defined $_ } @{ $objs };
    my $factor  = $defined[0]->get_factor()->get_name();
    my $colname = "FactorValue [$factor]";

    # However, we've not established that all FVs are term- or
    # measurement-based, and yet we make that assumption here FIXME.
    if ( $defined[0]->has_term() ) {
        my @terms = map { $_ ? $_->get_term() : undef } @{ $objs };
        $self->_process_controlled_terms( \@terms, $colname );
    }
    elsif ( $defined[0]->has_measurement() ) {
        my @meas = map { $_ ? $_->get_measurement() : undef } @{ $objs };
        $self->_process_measurements( \@meas, $colname );
    }
    else {
        croak("Error: FactorValue has no term or measurement.");
    }
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Writer::SDRF - Export of MAGE-TAB SDRF
objects.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::Writer::SDRF;
 my $writer = Bio::MAGETAB::Util::Writer::SDRF->new({
    magetab_object => $sdrf_object,
    filehandle     => $sdrf_fh,
 });
 
 $writer->write();

=head1 DESCRIPTION

Export of SDRF objects to SDRF files.

=head1 ATTRIBUTES

See the L<Tabfile|Bio::MAGETAB::Util::Writer::Tabfile> class for superclass attributes.

=over 2

=item magetab_object

The Bio::MAGETAB::SDRF object to export. This is a required
attribute.

=back

=head1 METHODS

=over 2

=item write

Exports the SDRF object to an SDRF file.

=back

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Writer>
L<Bio::MAGETAB::Util::Writer::Tabfile>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
