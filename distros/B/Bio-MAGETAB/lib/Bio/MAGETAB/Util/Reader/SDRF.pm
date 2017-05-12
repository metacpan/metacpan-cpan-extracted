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
# $Id: SDRF.pm 385 2014-04-08 09:28:43Z tfrayner $

package Bio::MAGETAB::Util::Reader::SDRF;

use Moose;
use MooseX::FollowPBP;

use Carp;
use List::Util qw(first);
use English qw( -no_match_vars );
use Parse::RecDescent;
use File::Temp qw(tempfile);

BEGIN { extends 'Bio::MAGETAB::Util::Reader::Tabfile' };

has 'magetab_object'     => ( is         => 'rw',
                              isa        => 'Bio::MAGETAB::SDRF',
                              required   => 0 );

# Define some standard regexps:
my $BLANK = qr/\A [ ]* \z/xms;

# The Parse::RecDescent grammar is stored in the __DATA__ section, below.
my $GRAMMAR = join("\n", <DATA> );

sub parse {

    my ( $self ) = @_;

    # This has to be set for Text::CSV_XS.
    local $/ = $self->get_eol_char();

    my $row_parser = $self->_parse_header();

    my $larry;
    my @sdrf_rows;

    # Find or create our SDRF object.
    my $sdrf;
    unless ( $sdrf = $self->get_magetab_object() ) {
        $sdrf = $self->get_builder()->find_or_create_sdrf({
            uri => $self->get_uri(),
        });
        $self->set_magetab_object( $sdrf );
    }

    # Run through the rest of the file with the row-level parser.
    my $row_number = 1;

    FILE_LINE:
    while ( $larry = $self->getline() ) {
    
        # Skip empty lines, comments.
        next FILE_LINE if $self->can_ignore( $larry );

	# Strip surrounding whitespace from each element.
        $larry = $self->strip_whitespace( $larry );

        # Parse the line into Bio::MAGETAB objects using the row-level parser.
	my $objects = $row_parser->(@$larry);

        # Post-process Nodes and FactorValues.
        my @nodes            = grep { $_ && UNIVERSAL::isa($_, 'Bio::MAGETAB::Node') }           @{ $objects };
        my @factorvals       = grep { $_ && UNIVERSAL::isa($_, 'Bio::MAGETAB::FactorValue') }    @{ $objects };
        my @labeled_extracts = grep { $_ && UNIVERSAL::isa($_, 'Bio::MAGETAB::LabeledExtract') } @nodes;

        my $channel;
        if ( scalar @labeled_extracts == 1 ) {
            my $val = 'unknown';
            if ( my $label = $labeled_extracts[0]->get_label() ) {
                $val = $label->get_value();
            }
            $channel = $self->get_builder()->find_or_create_controlled_term({
                category => 'Channel',    # FIXME hard-coded.
                value    => $val,
            });
        }
        elsif ( scalar @labeled_extracts > 1 ) {
            carp("WARNING: multiple labeled extracts in SDRF Row.\n");
        }

        # We know we only see each row just once, and Builder uniques
        # these by SDRF.
        push @sdrf_rows, $self->get_builder()->find_or_create_sdrf_row({
            factorValues => \@factorvals,
            nodes        => \@nodes,
            channel      => $channel,
            rowNumber    => $row_number,
            sdrf         => $sdrf,
        });

        # Maintain the reciprocal relationship in storage.
        $self->get_builder()->update( @nodes );

        $row_number++;
    }

    # Check we've parsed to the end of the file.
    $self->confirm_full_parse();

    # Add the rows to the SDRF object.
    if ( scalar @sdrf_rows ) {
        $sdrf->set_sdrfRows( \@sdrf_rows );
        $self->get_builder()->update( $sdrf );
    }

    return $sdrf;
}

sub _parse_header {

    # Generates a row-level parser function based on the first line in the SDRF.

    # $::sdrf is a qualified $self, used below in the Parse::RecDescent grammar.
    ( $::sdrf ) = @_;

    # Globals to record the previous material and event (bioassay) in
    # the chain.
    our ($previous_material,
	 $previous_event,
	 $previous_data,
	 $channel);

    # FIXME add support for REF:namespaces (currently accepted, but
    # discarded for termsource).

    # Check linebreaks; get first line as $header_string and generate
    # row-level parser.

    # Get the header line - the first non-empty, non-comment line in the file.
    my ( $header_string, $harry );
    HEADERLINE:
    while ( $harry = $::sdrf->getline() ) {

	# Skip empty and commented lines.
        next HEADERLINE if $::sdrf->can_ignore( $harry );

	$header_string = join( qq{\x{0}}, @$harry );

        if ( $header_string ) {

	    # We've found the header line. Add a starting skip
	    # character for the benefit of the parser.
	    $header_string = qq{\x{0}} . $header_string;
	    last HEADERLINE;
	}
    }

    # Check we have no CSV parse errors.
    $::sdrf->confirm_full_parse( $harry );

    # N.B. MAGE-TAB 1.1 SDRFs can actually be empty, so an empty
    # $header_string is valid at this point.

    # This will be used to store header line parsing errors.
    $::ERROR_FH = tempfile();

    # Set the token separator character.
    $Parse::RecDescent::skip = ' *\x{0} *';

    # FIXME most of these are removable once development is advanced.
    $::RD_ERRORS++;       # unless undefined, report fatal errors
    $::RD_WARN++;         # unless undefined, also report non-fatal problems
    $::RD_HINT++;         # if defined, also suggest remedies

    # Generate the grammar parser first.
    my $parser = Parse::RecDescent->new($GRAMMAR) or die("Bad grammar!: $@");

    # The parser should return a function which can process each SDRF
    # row as an array (row-level parser).
    my $row_parser;
    {
        # throw away the default error reports; we do our own.
        local *STDERR = tempfile() or die $!;
        $row_parser = $parser->header($header_string);
    }

    # Typically the grammar will generate some error messages before
    # we get here. N.B. $! doesn't really give a useful error here so
    # we don't use it.
    unless (defined $row_parser) {
        seek($::ERROR_FH, 0, 0) or croak("Unable to rewind Parse::RecDescent error filehandle: $!");
 	die(
	    qq{\nERROR parsing header line:\n} . join(q{}, <$::ERROR_FH>)
	);
    }

    return $row_parser;
}

sub _create_source {

    my ( $self, $name ) = @_;

    return if ( ! defined $name || $name =~ $BLANK );

    my $source = $self->get_builder()->find_or_create_source({
        name  => $name,
    });

    return $source;
}

sub _create_providers {

    my ( $self, $providers, $source ) = @_;

    return if ( ! $source || ! defined $providers || $providers =~ $BLANK );

    my @names = split /\s*;\s*/, $providers;

    my @preexisting = $source->get_providers();

    foreach my $name ( @names ) {
        my $found = first { $_->get_lastName() eq $name } @preexisting;

        unless ( $found ) {

            # Inelegant, but probably the best we can reliably attempt. FIXME?
            push @preexisting, $self->get_builder()->find_or_create_contact({
                lastName => $name,
            });
        }
    }
    
    $source->set_providers( \@preexisting );
    $self->get_builder()->update( $source );

    return \@preexisting;
}

sub _create_description {

    my ( $self, $description, $describable ) = @_;

    return if ( ! $describable || ! defined $description || $description =~ $BLANK );

    if ( $describable ) {
        $describable->set_description( $description );
        $self->get_builder()->update( $describable );
    }

    return $description;
}

sub _link_to_previous {

    my ( $self, $obj, $previous, $protocolapps ) = @_;

    if ( $previous ) {
        my $edge = $self->get_builder()->find_or_create_edge({
            inputNode  => $previous,
            outputNode => $obj,
        });

        # Maintain the reciprocal relationship in storage.
        $self->get_builder()->update( $previous, $obj );

        # FIXME this doesn't adequately address the possible options,
        # in which PAs may be different between SDRF rows on what is
        # (ostensibly) the same edge. This will probably work in 95%
        # of cases, though.
        if ( $protocolapps && scalar @{ $protocolapps } ) {

            # Our protocol apps and parameter values have previously
            # been stored as hashrefs, deferring object creation until
            # an Edge was created. We now instantiate the correct
            # objects:
            my @app_objs;
            foreach my $proto_app ( @{ $protocolapps } ) {

                # Prepare the proto_app hashref for object creation.
                my $param_vals = $proto_app->{parameterValues};
                delete $proto_app->{parameterValues};
                $proto_app->{edge} = $edge;

                # Generate a ProtocolApp keyed to this Edge.
                my $app = $self->get_builder()->find_or_create_protocol_application( $proto_app );

                # Generate ParameterVals keyed to this ProtocolApp.
                if ( $param_vals && scalar @{ $param_vals } ) {
                    my @val_objs;
                    foreach my $pv ( @{ $param_vals } ) {

                        # Extract the measurement hashref or term
                        # object, create the parameter value and then
                        # the measurement if necessary, and combine.
                        my ( $meas_data, $term_obj );
                        if ( $meas_data = $pv->{measurement_data} ) {
                            delete $pv->{measurement_data};
                        }
                        elsif ( $term_obj = $pv->{term_object} ) {
                            delete $pv->{term_object};
                        }
                        else {
                            confess("Error: Neither measurement_data nor term_object"
                                        . " found for parameter value.");
                        }
                        
                        $pv->{protocol_application} = $app;
                        my $pv_obj = $self->get_builder()->find_or_create_parameter_value( $pv );

                        if ( $meas_data ) {
                            $meas_data->{object} = $pv_obj;
                            my $meas = $self->get_builder()->find_or_create_measurement( $meas_data );
                            $pv_obj->set_measurement( $meas );
                        }
                        elsif ( $term_obj ) {
                            $pv_obj->set_term( $term_obj );
                        }

                        # Mainly for the benefit of the DBLoader back-end.
                        $self->get_builder()->update( $pv_obj );

                        push @val_objs, $pv_obj;
                    }
                    $app->set_parameterValues( \@val_objs );
                    $self->get_builder()->update( $app );
                }

                push @app_objs, $app;
            }
                    
            $edge->set_protocolApplications( \@app_objs );
            $self->get_builder()->update( $edge );
        }
    }

    return;
}

sub _create_sample {

    my ( $self, $name, $previous, $protocolapps ) = @_;

    return if ( ! defined $name || $name =~ $BLANK );

    my $sample = $self->get_builder()->find_or_create_sample({
        name => $name,
    });

    $self->_link_to_previous( $sample, $previous, $protocolapps );

    return $sample;
}

sub _create_extract {

    my ( $self, $name, $previous, $protocolapps ) = @_;

    return if ( ! defined $name || $name =~ $BLANK );

    my $extract = $self->get_builder()->find_or_create_extract({
        name => $name,
    });

    $self->_link_to_previous( $extract, $previous, $protocolapps );

    return $extract;
}

sub _create_labeled_extract {

    my ( $self, $name, $previous, $protocolapps ) = @_;

    return if ( ! defined $name || $name =~ $BLANK );

    my $labeled_extract = $self->get_builder()->find_or_create_labeled_extract({
        name  => $name,
    });

    $self->_link_to_previous( $labeled_extract, $previous, $protocolapps );

    return $labeled_extract;
}

sub _create_label {

    my ( $self, $dyename, $le, $termsource, $accession ) = @_;

    return if ( ! $le || ! defined $dyename || $dyename =~ $BLANK );

    my $ts_obj;
    if ( $termsource ) {
        $ts_obj = $self->get_builder()->get_term_source({
            'name' => $termsource,
        });
    }

    my $label = $self->get_builder()->find_or_create_controlled_term({
        'category'   => 'LabelCompound',
        'value'      => $dyename,
        'accession'  => $accession,
        'termSource' => $ts_obj,
    });

    if ( $le ) {
        $le->set_label( $label );
        $self->get_builder()->update( $le );
    }

    return $label;
}

sub _create_characteristic_value {

    my ( $self, $category, $value, $material, $termsource, $accession ) = @_;

    return if ( ! $material || ! defined $value || $value =~ $BLANK );

    my $ts_obj;
    if ( $termsource ) {
        $ts_obj = $self->get_builder()->get_term_source({
            'name' => $termsource,
        });
    }

    my $term = $self->get_builder()->find_or_create_controlled_term({
        category   => $category,
        value      => $value,
        accession  => $accession,
        termSource => $ts_obj,
    });

    $self->_add_characteristic_to_material( $term, $material ) if $material;

    return $term;
}

sub _create_characteristic_measurementhash {

    my ( $self, $type, $value, $material ) = @_;

    return if ( ! $material || ! defined $value || $value =~ $BLANK );

    return {
        measurementType  => $type,
        value            => $value,
        object           => $material,
    };
}

sub _create_material_type {

    my ( $self, $value, $material, $termsource, $accession ) = @_;

    return if ( ! $material || ! defined $value || $value =~ $BLANK );

    my $ts_obj;
    if ( $termsource ) {
        $ts_obj = $self->get_builder()->get_term_source({
            'name' => $termsource,
        });
    }

    my $term = $self->get_builder()->find_or_create_controlled_term({
        category   => 'MaterialType',    # FIXME hard-coded
        value      => $value,
        accession  => $accession,
        termSource => $ts_obj,
    });

    if ( $material ) {
        $material->set_materialType( $term );
        $self->get_builder()->update( $material );
    }

    return $term;
}

# The create_protocolapplication and create_parametervalue methods
# defer object creation until the Edge is defined (this allows for
# better internal identification of these protocol apps and param
# vals).
sub _create_protocolapplication {

    my ( $self, $name, $namespace, $termsource, $accession ) = @_;

    return if ( ! defined $name || $name =~ $BLANK );

    my ( $protocol, $ts_obj );

    # If we have a valid namespace or termsource, let it through.
    if ( $termsource ) {

        $ts_obj   = $self->get_builder()->get_term_source({
            'name' => $termsource,
        });
        $protocol = $self->get_builder()->find_or_create_protocol({
            name       => $name,
            accession  => $accession,
            termSource => $ts_obj,
            namespace  => $namespace,
        });
    }
    elsif ( $namespace ) {

        # FIXME what about authority here?
        $protocol = $self->get_builder()->find_or_create_protocol({
            name      => $name,
            namespace => $namespace,
        });
    }
    else {

        # Simple case; this call will die if $name is not valid.
        $protocol = $self->get_builder()->get_protocol({
            'name' => $name,
        });
    }

    # Just a hashref for now. See _link_to_previous for object
    # creation.
    my $protocol_app = { protocol => $protocol };

    return $protocol_app;
}

sub _create_performers {

    my ( $self, $performers, $proto_app ) = @_;

    return if ( ! $proto_app || ! defined $performers || $performers =~ $BLANK );

    my @names = split /\s*;\s*/, $performers;

    # Protocol app is still a hashref at this stage.
    my @preexisting = $proto_app->{performers} || ();

    foreach my $name ( @names ) {
        my $found = first { $_->get_lastName() eq $name } @preexisting;

        unless ( $found ) {

            # Inelegant, but probably the best we can reliably attempt. FIXME?
            push @preexisting, $self->get_builder()->find_or_create_contact({
                lastName => $name,
            });
        }
    }
    
    $proto_app->{performers} = \@preexisting if scalar @preexisting;

    return \@preexisting;
}

sub _create_date {

    my ( $self, $date, $proto_app ) = @_;

    return if ( ! $proto_app || ! defined $date || $date =~ $BLANK );

    # Protocol app is still a hashref at this stage.
    $proto_app->{date} = $date if $proto_app;

    return $date;
}

sub _create_parametervalue_measurement {

    my ( $self, $paramname, $value, $protocolapp ) = @_;

    return if ( ! $protocolapp || ! defined $value || $value =~ $BLANK );

    # Protocol app is still a hashref at this stage.
    my $protocol = $protocolapp->{protocol};

    my $parameter = $self->get_builder()->get_protocol_parameter({
        name     => $paramname,
        protocol => $protocol,
    });

    # This needs to be a hashref also, until such time as the
    # parameter value is created. This is because the Measurement
    # object's identity is tied up with the object to which it is
    # attached.
    my $measurement_data = {
        measurementType  => $paramname,
        value            => $value,
    };

    # Just a hashref for now. See _link_to_previous for object
    # creation.
    my $parameterval = {
        parameter        => $parameter,
        measurement_data => $measurement_data,
    };

    $self->_add_parameterval_to_protocolapp(
	$parameterval,
	$protocolapp,
    ) if $protocolapp;

    return $parameterval;
}

sub _create_parametervalue_value {

    my ( $self, $paramname, $value, $protocolapp, $termsource, $accession ) = @_;

    return if ( ! $protocolapp || ! defined $value || $value =~ $BLANK );

    # Protocol app is still a hashref at this stage.
    my $protocol = $protocolapp->{protocol};

    my $parameter = $self->get_builder()->get_protocol_parameter({
        name     => $paramname,
        protocol => $protocol,
    });

    my $ts_obj;
    if ( $termsource ) {
        $ts_obj = $self->get_builder()->get_term_source({
            'name' => $termsource,
        });
    }

    # In contrast to measurements, controlled terms have their own
    # intrinsic identity, so we can instantiate this without worry.
    my $term = $self->get_builder()->find_or_create_controlled_term({
        category   => 'ParameterValue',
        value      => $value,
        accession  => $accession,
        termSource => $ts_obj,
    });

    # Just a hashref for now. See _link_to_previous for object
    # creation.
    my $parameterval = {
        parameter        => $parameter,
        term_object      => $term,
    };

    $self->_add_parameterval_to_protocolapp(
	$parameterval,
	$protocolapp,
    ) if $protocolapp;

    return $parameterval;
}

sub _add_parameterval_to_protocolapp {

    my ( $self, $parameterval, $protocolapp ) = @_;

    my $found;

    # Protocol app and Param value are still hashrefs at this stage.
    if ( my $preexisting = ( $protocolapp->{parameterValues} || [] ) ) {
        my $parameter = $parameterval->{'parameter'};
	$found = first {
	    $_->{'parameter'} eq $parameter
	}   @$preexisting;
    }
    unless ( $found ) {
        my $values = $protocolapp->{parameterValues} || [];
        push @{ $values }, $parameterval;
        $protocolapp->{parameterValues} = $values;
    }

    return;
}

# FIXME OE as adjunct to parameter not supported by MAGE-TAB model.
# At the moment (v1.1 DRAFT) it seems that OE is not required, but
# we'll keep this here in case that ever changes.
sub _add_value_to_parameter {

    my ( $self, $parameter, $termsource, $accession ) = @_;

    return if ( ! defined $termsource || $termsource =~ $BLANK || ! $parameter );

    my $ts_obj = $self->get_builder()->get_term_source({
        'name' => $termsource,
    });

    # FIXME hard-coded category because MAGE-TAB has nowhere to
    # specify this at the moment.
    my $term = $self->get_builder()->find_or_create_controlled_term({
        category   => 'ParameterValue',
        value      => $parameter->get_value(),
        accession  => $accession,
        termSource => $ts_obj,
    });

    # Delete the measurement (FIXME the grammar action needs changing
    # here if OE is ever supported).
    $parameter->clear_value();

    # FIXME this call not yet implemented and will fail.
    $parameter->set_term( $term );
    $self->get_builder()->update( $parameter );

    return;
}

sub _create_unit {

    my ( $self, $type, $name, $thing, $termsource, $accession ) = @_;

    return if ( ! $thing || ! defined $name || $name =~ $BLANK );

    my $ts_obj;
    if ( $termsource ) {
        $ts_obj = $self->get_builder()->get_term_source({
            'name' => $termsource,
        });
    }

    my $unit = $self->get_builder()->find_or_create_controlled_term({
        category   => $type,
        value      => $name,
        accession  => $accession,
        termSource => $ts_obj,
    });

    # Add unit to $thing, where given.
    if ( $thing ) {
        $self->_add_unit_to_thing( $unit, $thing );
    }

    return $unit;
}

sub _add_unit_to_thing {

    my ( $self, $unit, $thing ) = @_;

    return unless ( $unit && $thing );

    # Either $thing has a unit, or a measurement.
    if ( UNIVERSAL::can( $thing, 'set_unit') ) {
        $thing->set_unit( $unit );
        $self->get_builder()->update( $thing );
    }
    elsif ( UNIVERSAL::can( $thing, 'has_measurement' ) && $thing->has_measurement() ) {
        my $meas = $thing->get_measurement();
        $meas->set_unit( $unit );
        $self->get_builder()->update( $meas );
    }
    elsif ( UNIVERSAL::isa( $thing, 'HASH' ) ) {
        if ( exists $thing->{measurement_data} ) {

            # Typically $thing is a hashref of ParameterValue
            # attributes with an accessory measurement_data key.
            $thing->{measurement_data}{unit} = $unit;
        }
        else {

            # Not sure if this is ever used.
            $thing->{unit} = $unit;
        }
    }
    else{
        confess("Error: Cannot process argument: $thing (" . blessed($thing) .")");
    }

    return;
}

sub _create_technology_type {

    my ( $self, $value, $assay, $termsource, $accession ) = @_;

    return if ( ! $assay || ! defined $value || $value =~ $BLANK );

    my $ts_obj;
    if ( $termsource ) {
        $ts_obj = $self->get_builder()->get_term_source({
            'name' => $termsource,
        });
    }

    my $type = $self->get_builder()->find_or_create_controlled_term({
        category   => 'TechnologyType',    #FIXME hard-coded.
        value      => $value,
        accession  => $accession,
        termSource => $ts_obj,
    });

    if ( $assay ) {
        $assay->set_technologyType( $type );
        $self->get_builder()->update( $assay );
    }

    return $type;
}

sub _create_hybridization {

    my ( $self, $name, $previous, $protocolapps, $channel ) = @_;

    return if ( ! defined $name || $name =~ $BLANK );

    my $default_type = $self->get_builder()->find_or_create_controlled_term({
        category   => 'TechnologyType',    #FIXME hard-coded.
        value      => 'hybridization',     #FIXME hard-coded.
    });

    my $hybridization = $self->get_builder()->find_or_create_assay({
        name           => $name,
        technologyType => $default_type,
    });

    $self->_link_to_previous( $hybridization, $previous, $protocolapps );

    return $hybridization;
}

sub _create_assay {

    my ( $self, $name, $previous, $protocolapps, $channel ) = @_;

    return if ( ! defined $name || $name =~ $BLANK );

    my $dummy_type = $self->get_builder()->find_or_create_controlled_term({
        category   => 'TechnologyType',    #FIXME hard-coded.
        value      => 'unknown',           #FIXME hard-coded.
    });

    # Pre-delete the dummy term.
    $self->get_builder()->get_magetab()->delete_objects( $dummy_type );

    my $assay = $self->get_builder()->find_or_create_assay({
        name           => $name,
        technologyType => $dummy_type,
    });

    $self->_link_to_previous( $assay, $previous, $protocolapps );

    return $assay;
}

sub _create_array {

    my ( $self, $name, $namespace, $termsource, $accession, $assay ) = @_;

    # $name is the term in the Array Design REF column;
    # $accession is the optional contents of the Term Accession
    # Number column.

    return if ( ! $assay || ! defined $name || $name =~ $BLANK );

    my $array_design;

    # If we have a valid namespace or termsource, let it through.
    if ( $termsource ) {

        my $ts_obj   = $self->get_builder()->get_term_source({
            'name' => $termsource,
        });
        $array_design = $self->get_builder()->find_or_create_array_design({
            name       => $name,
            accession  => $accession,
            termSource => $ts_obj,
            namespace  => $namespace,
        });
    }
    elsif ( $namespace ) {

        # FIXME what about authority here?
        $array_design = $self->get_builder()->find_or_create_array_design({
            name       => $name,
            namespace  => $namespace,
        });
    }
    else {

        # Simple case; this call will die if $name is not valid.
        $array_design = $self->get_builder()->get_array_design({
            name       => $name,
        });
    }

    if ( $assay ) {
        $assay->set_arrayDesign( $array_design );
        $self->get_builder()->update( $assay );
    }

    return $array_design;
}

sub _create_array_from_file {

    my ( $self, $uri, $assay ) = @_;

    return if ( ! $assay || ! defined $uri || $uri =~ $BLANK );

    # We just create a stub object here for now; the main Reader
    # object will come back and fill in the details using the ADF
    # parser. Use of the URI as name attribute here is problematic -
    # the name attr acts as an internal identifier, but the ADF parser
    # will replace this attribute with a correct name later and so the
    # Builder identifier mechanism (get_array_design,
    # find_or_create_array_design) is ultimately broken for
    # ArrayDesign. FIXME consider just parsing the ADF right here
    # rather than in the Reader.
    my $array_design = $self->get_builder()->find_or_create_array_design({
        name => $uri,
        uri  => $uri,
    });

    if ( $assay ) {
        $assay->set_arrayDesign( $array_design );
        $self->get_builder()->update( $assay );
    }

    return $array_design;
}

sub _create_scan {

    my ( $self, $name, $previous, $protocolapps ) = @_;

    return if ( ! defined $name || $name =~ $BLANK );

    my $scan = $self->get_builder()->find_or_create_data_acquisition({
        name => $name,
    });

    $self->_link_to_previous( $scan, $previous, $protocolapps );

    return $scan;
}

sub _create_normalization {

    my ( $self, $name, $previous, $protocolapps ) = @_;

    return if ( ! defined $name || $name =~ $BLANK );

    my $normalization = $self->get_builder()->find_or_create_normalization({
        name => $name,
    });

    $self->_link_to_previous( $normalization, $previous, $protocolapps );

    return $normalization;
}

sub _find_data_format {

    my ( $self, $uri ) = @_;

    # We need a data format, but MAGE-TAB has nowhere to specify
    # it. This is a very basic start on a way to automatically derive
    # formats from what we know. This is in a separate method so that
    # it can be easily overridden in subclasses. Possible additions
    # include parsing the CEL, CHP headers to get the exact format
    # version.
    my %known = (
        'cel'    => 'CEL',
        'chp'    => 'CHP',
        'gpr'    => 'GPR',
	'tif'    => 'TIFF',
	'tiff'   => 'TIFF',
	'jpg'    => 'JPEG',
	'jpeg'   => 'JPEG',
	'png'    => 'PNG',
	'gif'    => 'GIF',
    );

    my $format_str = 'unknown';
    if ( my ( $ext ) = ( $uri =~ m/\. (\w{3,4}) \z/xms ) ) {
	if ( my $term = $known{lc($ext)} ) {
	    $format_str = $term;
	}
    }

    my $format = $self->get_builder()->find_or_create_controlled_term({
        category => 'DataFormat',    # FIXME hard-coded.
        value    => $format_str,
    });

    return $format;
}

sub _create_data_file {

    my ( $self, $uri, $type_str, $previous, $protocolapps ) = @_;

    return if ( ! defined $uri || $uri =~ $BLANK );

    my $format = $self->_find_data_format( $uri );

    my $type = $self->get_builder()->find_or_create_controlled_term({
        category => 'DataType',    # FIXME hard-coded.
        value    => $type_str,
    });

    my $data_file = $self->get_builder()->find_or_create_data_file({
        uri        => $uri,
        format     => $format,
        dataType   => $type,
    });

    $self->_link_to_previous( $data_file, $previous, $protocolapps );

    return $data_file;
}

sub _create_data_matrix {

    my ( $self, $uri, $type_str, $previous, $protocolapps ) = @_;

    return if ( ! defined $uri || $uri =~ $BLANK );

    # There's a lot more metadata to acquire here, by actually parsing
    # the data matrix file. We do that later after everything else has
    # been parsed, so that we can reliably map matrix columns to
    # nodes.

    my $type = $self->get_builder()->find_or_create_controlled_term({
        category => 'DataType',    # FIXME hard-coded.
        value    => $type_str,
    });

    my $data_matrix = $self->get_builder()->find_or_create_data_matrix({
        uri      => $uri,
        dataType => $type,
    });

    $self->_link_to_previous( $data_matrix, $previous, $protocolapps );

    return $data_matrix;
}

sub _get_fv_category_from_factor {

    my ( $self, $factor ) = @_;

    my $category;
    if ( my $ef_oe = $factor->get_factorType() ) {
                 
	# Otherwise, derive the category from the EF term:
	my @ef_catparts = split /_/, $ef_oe->get_value();
	$category = join(q{}, map{ ucfirst($_) } @ef_catparts);
    }
    else {

        # Fall back to a default category.
        $category = 'FactorValue';
    }

    return $category;
}

sub _create_factorvalue_value {

    my ( $self, $factorname, $altcategory, $value, $termsource, $accession ) = @_;

    return if ( ! defined $value || $value =~ $BLANK );

    my $exp_factor = $self->get_builder()->get_factor({
        name => $factorname,
    });
    
    my $ts_obj;
    if ( $termsource ) {
        $ts_obj = $self->get_builder()->get_term_source({
            'name' => $termsource,
        });
    }

    my $category;
    if ( $altcategory ) {

	# If we're given a category in parentheses, use it.
	$category = $altcategory;
    }
    else {

        # Otherwise derive it from the factor type.
        $category = $self->_get_fv_category_from_factor( $exp_factor );
    }

    my $term = $self->get_builder()->find_or_create_controlled_term({
        category   => $category,
        value      => $value,
        accession  => $accession,
        termSource => $ts_obj,
    });

    my $factorvalue = $self->get_builder()->find_or_create_factor_value({
        factor => $exp_factor,
        term   => $term,
    });

    return $factorvalue;
}

sub _create_factorvalue_measurementhash {

    my ( $self, $factorname, $value, $altcategory ) = @_;

    return if ( ! defined $value || $value =~ $BLANK );

    my $exp_factor  = $self->get_builder()->get_factor({
        name => $factorname,
    });

    my $category;
    if ( $altcategory ) {

        # If we're given a category in parentheses, use it.
        $category = $altcategory;
    }
    else {

        # Otherwise derive it from the factor type.
        $category = $self->_get_fv_category_from_factor( $exp_factor );
    }

    return {
        measurementType  => $category,
        value            => $value,
    };
}

sub _create_factorvalue_measurement {

    my ( $self, $meashash, $factorname ) = @_;

    return if ( ! defined $meashash );

    my $exp_factor  = $self->get_builder()->get_factor({
        name => $factorname,
    });

    my $fvmeas = $self->get_builder->find_or_create_measurement($meashash);

    my $fv = $self->get_builder()->find_or_create_factor_value({
        factor      => $exp_factor,
        measurement => $fvmeas,
    });
    $self->get_builder()->update( $fv );

    return $fv;
}

sub _add_comment_to_thing {

    my ( $self, $comment, $thing ) = @_;

    # NOTE that $thing can be either an object with get_/set_comments
    # methods, or a hashref with a "comments" key (the latter is the
    # case for ProtocolApplication, ParameterValue).

    return unless ( $comment && $thing );

    my @preexisting = blessed($thing) ? $thing->get_comments() : ( $thing->{comments} || () );

    my $new_name  = $comment->get_name();
    my $new_value = $comment->get_value();
    my $found = first {
        $_->get_name()  eq $new_name
     && $_->get_value() eq $new_value;
    }   @preexisting;

    unless ( $found ) {
        
        push @preexisting, $comment;

        if ( blessed($thing) ) {
            $thing->set_comments( \@preexisting );
            $self->get_builder()->update( $thing );
        }
        else {
            $thing->{comments} = \@preexisting if scalar @preexisting;
        }
    }

    return;
}

sub _create_comment {

    my ( $self, $name, $value, $thing ) = @_;

    return if ( ! $thing || ! defined $value || $value =~ $BLANK );

    my $comment = $self->get_builder()->find_or_create_comment({
        name   => $name,
        value  => $value,
        object => $thing,
    });

    $self->_add_comment_to_thing( $comment, $thing )
        if $thing;

    return $comment;
}

sub _get_characteristic_type {

    my ( $self, $char ) = @_;

    # Handle both ControlledTerm and Measurement. Both have value
    # attributes, but Measurement has type while ControlledTerm has
    # category.
    my $getter;
    if ( blessed($char) eq 'Bio::MAGETAB::ControlledTerm' ) {
        $getter = "get_category";
    }
    elsif ( blessed($char) eq 'Bio::MAGETAB::Measurement' ) {
        $getter = "get_measurementType";
    }
    else {
        croak("Cannot process argument: $char (" . blessed($char) .")");
    }

    return $char->$getter;
}

sub _add_characteristic_to_material {

    my ( $self, $char, $material ) = @_;

    return unless ( $material && $char );

    my @preexisting;
    if ( blessed($char) eq 'Bio::MAGETAB::ControlledTerm' ) {
        @preexisting = $material->get_characteristics();
    }
    elsif ( blessed($char) eq 'Bio::MAGETAB::Measurement' ) {
        @preexisting = $material->get_measurements();
    }
    else {
        croak("Cannot process argument: $char (" . blessed($char) .")");
    }

    my $new_category = $self->_get_characteristic_type( $char );
    my $new_value    = $char->get_value();
    my $new_class    = blessed $char;
    my $found = first {
        $self->_get_characteristic_type( $_ ) eq $new_category
     && $_->get_value()                       eq $new_value
     && blessed $_                            eq $new_class
    }   @preexisting;

    unless ( $found ) {
        push @preexisting, $char;

        if ( blessed($char) eq 'Bio::MAGETAB::ControlledTerm' ) {
            $material->set_characteristics( \@preexisting );
        }
        else { # Must therefore be Bio::MAGETAB::Measurement
            $material->set_measurements( \@preexisting );
        }
        $self->get_builder()->update( $material );
    }

    return;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Reader::SDRF - SDRF parser class.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::Reader::SDRF;
 my $parser = Bio::MAGETAB::Util::Reader::SDRF->new({
     uri => $sdrf_filename,
 });
 my $sdrf = $parser->parse();

=head1 DESCRIPTION

This class is used to parse SDRF files. It can be used on its own, but
more often you will want to use the main Bio::MAGETAB::Util::Reader
class which handles extended parsing options more transparently.

=head1 ATTRIBUTES

See the L<TabFile|Bio::MAGETAB::Util::Reader::TabFile> class for superclass attributes.

=over 2

=item magetab_object

A Bio::MAGETAB::SDRF object. This can either be set upon
instantiation, or a new object will be created for you. It can be
retrieved at any time using C<get_magetab_object>.

=back

=head1 METHODS

=over 2

=item parse

Parse the SDRF pointed to by C<$self-E<gt>get_uri()>. Returns the
Bio::MAGETAB::SDRF object updated with the SDRF contents.

=back

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Reader::Tabfile>
L<Bio::MAGETAB::Util::Reader>
L<Bio::MAGETAB::SDRF>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;

# Below is the Parse::RecDescent grammar used to parse the SDRF header
# line and generate the row-level parser.

__DATA__

    header:                    section_list
                             | { # Display errors using our own report format.
                                 # Adapted from P::RD demo/demo_errors.pl
                                 for ( @{ $thisparser->{errors} } ) {
                                     my $t = $_->[0];
                                     $t =~ s/\x0/ | /g;
                                     print $::ERROR_FH "$t\n";
                                 }
                                 return;
                               }

    section_list:              material_section(?)
                               edge(s?)
                               assay_or_hyb(?)
                               edge(s?)
                               data_section(?)
                               factor_value(s?)
                               end_of_line

                                   { $return = sub{

                                          my @objects;

                                          # Reset some global variables.
                                          $::channel           = 'Unknown';
                                          $::previous_node     = undef;
                                          @::protocolapp_list  = ();

                                          # Generate the objects.
                                          foreach my $sub (@{$item[1][0]},
                                                           @{$item[2]},
                                                           @{$item[3]},
                                                           @{$item[4]},
                                                           @{$item[5][0]},
                                                           @{$item[6]}){
                                              if ( UNIVERSAL::isa( $sub, 'CODE' ) ) {
                                                  my @obj = &{ $sub };
                                                  push @objects, @obj;
                                              }
                                              else {
                                                  die("Error: Grammar rule return value not a CODE ref: $sub");
                                              }
                                          }

                                          if ( scalar @_ ) {
                                              die("Error: SDRF row not completely parsed: " . join("\n", @_));
                                          }

                                          return \@objects;
                                     };
                                   }

                             | <error:  Invalid header; unparseable sequence starts here:\n    $text>

    end_of_line:               <skip:'[ \x{0}\r]*'> /\Z/

    material_section:          material edge_and_material(s?)

                               { $return = [$item[1], map { @{ $_ } } @{$item[2]}] }

    data_section:              assay_or_data edge_and_assay_or_data(s?)

                               { $return = [$item[1], map { @{ $_ } } @{$item[2]}] }

    edge_and_material:         edge(s?) material { $return = [ @{ $item[1] }, $item[2] ] }

    edge_and_assay_or_data:    edge(s?) assay_or_data    { $return = [ @{ $item[1] }, $item[2] ] }

    assay_or_data:             event
                             | data

    edge:                      factor_value
                             | protocol

    material:                  source
                             | sample
                             | extract
                             | labeled_extract

    event:                     scan
                             | normalization

    data:                      raw_data
                             | derived_data

    source_name:               /Source *Names?/i

    source:                    source_name source_attribute(s?)

                                   { $return = sub{
                                          my $name = shift;
                                          my $obj  = $::sdrf->_create_source($name);
                                          foreach my $sub (@{$item[2]}){
                                              unshift( @_, $obj ) and
                                                  &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                          }
                                          $::previous_node = $obj if $obj;
                                          return $obj; 
                                     };
                                   }

    sample_name:               /Sample *Names?/i

    sample:                    sample_name material_attribute(s?)

                                   { $return = sub{
                                          my $name = shift;
                                          my $obj  = $::sdrf->_create_sample(
                                              $name,
                                              $::previous_node,
                                              \@::protocolapp_list,
                                          );
                                          @::protocolapp_list = () if $obj;
                                          foreach my $sub (@{$item[2]}){
                                              unshift( @_, $obj ) and
                                                  &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                          }
                                          $::previous_node = $obj if $obj;
                                          return $obj; 
                                     };
                                   }

    extract_name:              /Extract *Names?/i

    extract:                   extract_name material_attribute(s?)

                                   { $return = sub{
                                          my $name = shift;
                                          my $obj  = $::sdrf->_create_extract(
                                              $name,
                                              $::previous_node,
                                              \@::protocolapp_list,
                                          );
                                          @::protocolapp_list = () if $obj;
                                          foreach my $sub (@{$item[2]}){
                                              unshift( @_, $obj ) and
                                                  &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                          }
                                          $::previous_node = $obj if $obj;
                                          return $obj; 
                                     };
                                   }

    labeled_extract_name:      /Labell?ed *Extract *Names?/i

    labeled_extract:           labeled_extract_name labeled_extract_attribute(s?)

                                   { $return = sub{
                                          my $name = shift;
                                          my $obj  = $::sdrf->_create_labeled_extract(
                                              $name,
                                              $::previous_node,
                                              \@::protocolapp_list,
                                          );
                                          @::protocolapp_list = () if $obj;
                                          foreach my $sub (@{$item[2]}){
                                              unshift( @_, $obj ) and
                                                  &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                          }
                                          $::previous_node = $obj if $obj;
                                          return $obj; 
                                     };
                                   }

    source_attribute:          material_attribute
                             | provider

    labeled_extract_attribute: material_attribute
                             | label

    material_attribute:        characteristic
                             | materialtype
                             | description
                             | comment

    characteristic_heading:    /Characteristics?/i

    characteristic:            characteristic_meas
                             | characteristic_value

    characteristic_meas:       characteristic_heading
                               <skip:' *'> bracket_term
                               <skip:' *\x{0} *'> unit

                                   { $return = sub {
                                         my $material = shift;

                                         # Add a measurement with unit to the material.
                                         my $charhash = $::sdrf->_create_characteristic_measurementhash(
                                             $item[3], shift, $material,
                                         );

                                         unshift(@_, $charhash);
                                         my $unit = &{ $item[5] };

                                         if ( defined $charhash ) {
                                             my $char = $::sdrf->get_builder->find_or_create_measurement($charhash);
                                             $::sdrf->_add_characteristic_to_material($char, $material);
                                             return $char;
                                         }
                                         else {
                                             return;
                                         }
                                     };
                                   }

    characteristic_value:      characteristic_heading
                               <skip:' *'> bracket_term
                               <skip:' *\x{0} *'> termsource(?)

                                   { $return = sub {
                                         my $material = shift;

                                         # Value
                                         my $value = shift;

                                         my @args;
                                         if ( UNIVERSAL::isa( $item[5][0], 'ARRAY' ) ) {

                                             # Term Source
                                             push @args, shift;

                                             # Accession
                                             push @args, ($item[5][0][1] && $item[5][0][1] eq 'term_accession')
                                                         ? shift
                                                         : undef;
                                         }
                                         else {

                                             # No term source given
                                             push @args, undef, undef;
                                         }

                                         my $char = $::sdrf->_create_characteristic_value(
                                             $item[3], $value, $material, @args,
                                         );

                                         return $char;
                                     };
                                   }

    factor_value_heading:      /Factor *Values?/i

    factor_value:              factor_value_meas
                             | factor_value_value

    factor_value_meas:         factor_value_heading
                               <skip:' *'> bracket_term parens_term(?)
                               <skip:' *\x{0} *'> unit

                                   { $return = sub {

                                         # Value
                                         my $value = shift;

                                         my $meashash = $::sdrf->_create_factorvalue_measurementhash( $item[3], $value, $item[4][0]  );

                                         # Attach the unit to the measurement.
                                         unshift(@_, $meashash);
                                         my $unit = &{ $item[6] };
                                         if ( defined $meashash ) {
                                             return $::sdrf->_create_factorvalue_measurement($meashash, $item[3]);
                                         }
                                         else {
                                             return;
                                         }
                                     };
                                   }

    factor_value_value:       factor_value_heading
                               <skip:' *'> bracket_term parens_term(?)
                               <skip:' *\x{0} *'> termsource(?)

                                   { $return = sub {

                                         # Value
                                         my $value = shift;

                                         my @args;
                                         if (  UNIVERSAL::isa( $item[6][0], 'ARRAY' ) ) {

                                             # Term Source
                                             push @args, shift;

                                             # Accession
                                             push @args, ($item[6][0][1] && $item[6][0][1] eq 'term_accession')
                                                         ? shift
                                                         : undef;
                                         }
                                         else {

                                             # No term source given
                                             push @args, undef, undef;
                                         }

                                         my $fv = $::sdrf->_create_factorvalue_value(
                                             $item[3],
                                             $item[4][0],
                                             $value,
                                             @args,
                                         );

                                         return $fv;
                                     };
                                   }

    bracket_term:              /\A \[ [ ]* ([^\x{0}\]]+?) [ ]* \]/xms

                                   { $return = $1 }

    parens_term:               /\A \( [ ]* ([^\x{0}\)]+?) [ ]* \)/xms

                                   { $return = $1 }

    namespace_term:            /\A : ([^\x{0}]+)/xms

                                   { $return = $1 }

    term_source_ref:           /Term *Source *REFs?/i

    termsource:                term_source_ref
                               <skip:' *'> namespace_term(?)
                               <skip:' *\x{0} *'> term_accession(?)

                                   { $return = [ $item[3][0], $item[5][0] ] } # FIXME add namespace_term support

    term_accession:            /Term *Accession *Numbers?/i

                                   { $return = 'term_accession'; }

    provider_heading:          /Providers?/i

    provider:                  provider_heading comment(s?)

                                   { $return = sub {
                                         my $source = shift;

                                         my $providers = $::sdrf->_create_providers( shift, $source );

                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, @{$providers} ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );
                                         }

                                         return @$providers if defined $providers;
                                     };
                                   }

    materialtype_heading:      /Material *Types?/i

    materialtype:              materialtype_heading termsource(?)

                                   { $return = sub {
                                         my $material = shift;

                                         # Value
                                         my $value = shift;

                                         my @args;
                                         if ( UNIVERSAL::isa( $item[2][0], 'ARRAY' ) ) {

                                             # Term Source
                                             push @args, shift;

                                             # Accession
                                             push @args, ($item[2][0][1] && $item[2][0][1] eq 'term_accession')
                                                         ? shift
                                                         : undef;
                                         }
                                         else {

                                             # No term source given
                                             push @args, undef, undef;
                                         }

                                         my $type = $::sdrf->_create_material_type(
                                             $value, $material, @args,
                                         );

                                         return $type;
                                     };
                                   }

    label_heading:             /Labels?/i

    label:                     label_heading termsource(?)

                                   { $return = sub {
                                         my $labeled_extract = shift;
                                         $::channel = shift;

                                         my @args;

                                         if ( UNIVERSAL::isa( $item[2][0], 'ARRAY' ) ) {

                                             # Term Source
                                             push @args, shift;

                                             # Accession
                                             push @args, ($item[2][0][1] && $item[2][0][1] eq 'term_accession')
                                                         ? shift
                                                         : undef;
                                         }
                                         else {

                                             # No term source given
                                             push @args, undef, undef;
                                         }
                                         my $label = $::sdrf->_create_label($::channel, $labeled_extract, @args);
                                         return $label;
                                     };
                                   }

    description:               /Descriptions?/i

                                   { $return = sub {
                                         my $describable = shift;
                                         my $description = shift;

                                         return $::sdrf->_create_description( $description, $describable );
                                     };
                                   }

    comment_heading:           /Comments?/i

    comment:                   comment_heading <skip:' *'> bracket_term

                                   { $return = sub {
                                         my $thing = shift;
                                         return $::sdrf->_create_comment($item[3], shift, $thing);
                                     };
                                   }

    protocol_ref:              /Protocol *REFs?/i

    protocol:                  protocol_ref
                               <skip:' *'> namespace_term(?)
                               <skip:' *\x{0} *'> termsource(?)
                               protocol_attributes(s?)

                                   { $return = sub{

                                          # Name, namespace_term
                                          my @args = (shift, $item[3][0]);

                                          if ( UNIVERSAL::isa( $item[5][0], 'ARRAY' ) ) {

                                              # Term Source
                                              push @args, shift;

                                              # Accession
                                              push @args, ($item[5][0][1] && $item[5][0][1] eq 'term_accession')
                                                          ? shift
                                                          : undef;
                                          }
                                          else {

                                              # No term source given
                                              push @args, undef, undef;
                                          }

                                          my $obj  = $::sdrf->_create_protocolapplication(@args);

                                          # Add to the global ProtApp list immediately.
                                          push(@::protocolapp_list, $obj) if $obj;

                                          foreach my $sub (@{$item[6]}){
                                              unshift( @_, $obj ) and
                                                  &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                          }
                                          return $obj; 
                                     };
                                   }

    protocol_attributes:       parameter
                             | performer
                             | date
                             | comment

    parameter_heading:         /Parameter *Values?/i

    parameter:                 parameter_value_meas
                             | parameter_value_value

    parameter_value_meas:      parameter_heading
                               <skip:' *'> bracket_term
                               <skip:' *\x{0} *'> unit comment(s?)

                                   { $return = sub {
                                         my $protocolapp = shift;
                                         my $value       = shift;

                                         my $obj = $::sdrf->_create_parametervalue_measurement($item[3], $value, $protocolapp);
                                         foreach my $sub ($item[5], @{$item[6]}){

                                              # Comment
                                              unshift( @_, $obj );
                                              my $attr = &{ $sub };
                                         }
                                         return $obj;
                                     };
                                   }

    parameter_value_value:     parameter_heading
                               <skip:' *'> bracket_term
                               <skip:' *\x{0} *'> termsource(?) comment(s?)

                                   { $return = sub {
                                         my $protocolapp = shift;
                                         my $value       = shift;

                                         my @args;
                                         if ( UNIVERSAL::isa( $item[5][0], 'ARRAY' ) ) {
                                             
                                             # Term Source
                                             push @args, shift;

                                             # Accession
                                             push @args, ($item[5][0][1] && $item[5][0][1] eq 'term_accession')
                                                         ? shift
                                                         : undef;
                                         }
                                         else {

                                             # No term source given
                                             push @args, undef, undef;
                                         }
                                         my $obj = $::sdrf->_create_parametervalue_value(
                                             $item[3],
                                             $value,
                                             $protocolapp,
                                             @args,
                                         );

                                         foreach my $sub (@{$item[6]}){

                                              # Comment
                                              unshift( @_, $obj );
                                              my $attr = &{ $sub };
                                         }
                                         return $obj;
                                     };
                                   }

    unit_heading:              /Unit/i

    unit:                      unit_heading
                               <skip:' *'> bracket_term
                               <skip:' *\x{0} *'> termsource(?)

                                   { $return = sub {

                                         # Thing having unit.
                                         my $thing = shift;

                                         # Unit name
                                         my $name = shift;

                                         my @args;
                                         if ( UNIVERSAL::isa( $item[5][0], 'ARRAY' ) ) {

                                             # Term Source
                                             push @args, shift;

                                             # Accession
                                             push @args, ($item[5][0][1] && $item[5][0][1] eq 'term_accession')
                                                         ? shift
                                                         : undef;
                                         }
                                         else {

                                             # No term source given
                                             push @args, undef, undef;
                                         }

                                         my $unit = $::sdrf->_create_unit(
                                             $item[3],
                                             $name,
                                             $thing,
                                             @args,
                                         );

                                         return $unit;
                                     };
                                   }

    performer_heading:         /Performers?/i

    performer:                 performer_heading comment(s?)

                                   { $return = sub {
                                         my $protocolapp = shift;

                                         my $performers = $::sdrf->_create_performers( shift, $protocolapp );

                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, @{$performers} ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );
                                         }

                                         return @$performers if defined $performers;
                                     };
                                   }

    date:                      /Dates?/i

                                   { $return = sub {
                                         my $protocolapp = shift;
                                         my $date        = shift;

                                         return $::sdrf->_create_date( $date, $protocolapp );
                                     };
                                   }

    array_design:              array_design_file
                             | array_design_ref

    array_design_file_heading: /Array *Design *Files?/i

    array_design_file:         array_design_file_heading comment(s?)

                                   { $return = sub {
                                         my $hybridization = shift;
                                         my $uri           = shift;
                                  
                                         my $obj = $::sdrf->_create_array_from_file($uri, $hybridization);
                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         return $obj;
                                     };
                                   }

    array_design_ref_heading:  /Array *Design *REFs?/i

    array_design_ref:          array_design_ref_heading
                               <skip:' *'> namespace_term(?)
                               <skip:' *\x{0} *'> termsource(?)
                               comment(s?)

                                   { $return = sub {
                                         my $hybridization  = shift;

                                         # array_accession, namespace_term
                                         my @args = ( shift, $item[3][0] );

                                         if ( UNIVERSAL::isa( $item[5][0], 'ARRAY' ) ) {

                                             # Term Source
                                             push @args, shift;

                                             # Accession
                                             push @args, ($item[5][0][1] && $item[5][0][1] eq 'term_accession')
                                                         ? shift
                                                         : undef;
                                         }
                                         else {

                                             # No term source given
                                             push @args, undef, undef;
                                         }

                                         my $obj = $::sdrf->_create_array(@args, $hybridization);
                                         foreach my $sub (@{$item[6]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         return $obj;
                                     };
                                   }

    assay_or_hyb:              assay
                             | hybridization

    hybridization_name:        /Hybridi[sz]ation *Names?/i

    hybridization:             hybridization_name assay_attribute(s?)

                                   { $return = sub {
                                         my $name = shift;
                                         my $obj  = $::sdrf->_create_hybridization(
                                             $name,
                                             $::previous_node,
                                             \@::protocolapp_list,
                                             $::channel,
                                         );
                                         @::protocolapp_list = () if $obj;
                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         $::previous_node = $obj if $obj;
                                         return $obj;
                                      };
                                    }

    assay_attribute:          array_design
                             | technology_type
                             | comment

    assay_name:                /Assay *Names?/i

    assay:                     assay_name assay_attribute(s?)

                                   { $return = sub {
                                         my $name = shift;
                                         my $obj  = $::sdrf->_create_assay(
                                             $name,
                                             $::previous_node,
                                             \@::protocolapp_list,
                                             $::channel,
                                         );
                                         @::protocolapp_list = () if $obj;
                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         $::previous_node = $obj if $obj;
                                         return $obj;
                                      };
                                    }

    technol_type_heading:      /Technology *Types?/i

    technology_type:           technol_type_heading termsource(?)

                                   { $return = sub {
                                         my $assay = shift;

                                         # Value
                                         my $value = shift;

                                         my @args;
                                         if ( UNIVERSAL::isa( $item[2][0], 'ARRAY' ) ) {

                                             # Term Source
                                             push @args, shift;

                                             # Accession
                                             push @args, ($item[2][0][1] && $item[2][0][1] eq 'term_accession')
                                                         ? shift
                                                         : undef;
                                         }
                                         else {

                                             # No term source given
                                             push @args, undef, undef;
                                         }
                                         my $type = $::sdrf->_create_technology_type(
                                             $value, $assay, @args,
                                         );
                                         return $type;
                                     };
                                   }

    scan_name:                 /Scan *Names?/i

    scan:                      scan_name scan_attribute(s?)

                                   { $return = sub {
                                         my $name = shift;
                                         my $obj = $::sdrf->_create_scan(
                                             $name,
                                             $::previous_node,
                                             \@::protocolapp_list,
                                         );
                                         @::protocolapp_list = () if $obj;

                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }

                                         $::previous_node = $obj if $obj;
                                         return $obj;
                                      };
                                    }

    scan_attribute:            comment

    normalization_name:        /Normali[sz]ation *Names?/i

    normalization:             normalization_name norm_attribute(s?)

                                   { $return = sub {
                                         my $obj = $::sdrf->_create_normalization(
                                             shift,
                                             $::previous_node,
                                             \@::protocolapp_list,
                                         );
                                         @::protocolapp_list = () if $obj;
                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         $::previous_node = $obj if $obj;
                                         return $obj;
                                     };
                                   }

    norm_attribute:            comment

    raw_data:                  image
                             | array_data
                             | array_data_matrix

    derived_data:              derived_array_data
                             | derived_array_data_matrix

    array_data_file:           /Array *Data *Files?/i

    array_data:                array_data_file comment(s?)

                                   { $return = sub {
                                         my $obj = $::sdrf->_create_data_file(
                                             shift,
                                             'raw',
                                             $::previous_node,
                                             \@::protocolapp_list,
                                         );
                                         @::protocolapp_list = () if $obj;
                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         $::previous_node = $obj if $obj;
                                         return $obj;
                                     };
                                   }

    derived_array_data_file:   /Derived *Array *Data *Files?/i

    derived_array_data:        derived_array_data_file comment(s?)

                                   { $return = sub {
                                         my $obj = $::sdrf->_create_data_file(
                                             shift,
                                             'derived',
                                             $::previous_node,
                                             \@::protocolapp_list,
                                         );
                                         @::protocolapp_list = () if $obj;
                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         $::previous_node = $obj if $obj;
                                         return $obj;
                                     };
                                   }

    array_data_matrix_file:    /Array *Data *Matrix *Files?/i

    array_data_matrix:         array_data_matrix_file comment(s?)

                                   { $return = sub {
                                         my $obj = $::sdrf->_create_data_matrix(
                                             shift,
                                             'raw',
                                             $::previous_node,
                                             \@::protocolapp_list,
                                         );
                                         @::protocolapp_list = () if $obj;
                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         $::previous_node = $obj if $obj;
                                         return $obj;
                                     };
                                   }

    derived_array_data_matrix_file: /Derived *Array *Data *Matrix *Files?/i

    derived_array_data_matrix: derived_array_data_matrix_file comment(s?)

                                   { $return = sub {
                                         my $obj = $::sdrf->_create_data_matrix(
                                             shift,
                                             'derived',
                                             $::previous_node,
                                             \@::protocolapp_list,
                                         );
                                         @::protocolapp_list = () if $obj;
                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         $::previous_node = $obj if $obj;
                                         return $obj;
                                     };
                                   }

    image_file:                /Image *Files?/i

    image:                     image_file comment(s?)

                                   { $return = sub {
                                         my $obj = $::sdrf->_create_data_file(
                                             shift,
                                             'image',
                                             $::previous_node,
                                             \@::protocolapp_list,
                                         );
                                         foreach my $sub (@{$item[2]}){
                                             unshift( @_, $obj ) and
                                                 &{ $sub } if UNIVERSAL::isa( $sub, 'CODE' );  
                                         }
                                         $::previous_node = $obj if $obj;
                                         return $obj;
                                     };
                                   }

