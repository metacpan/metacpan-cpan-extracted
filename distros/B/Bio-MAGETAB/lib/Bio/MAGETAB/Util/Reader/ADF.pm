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
# $Id: ADF.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Util::Reader::ADF;

use Moose;
use MooseX::FollowPBP;

use Carp;
use List::Util qw(first);

BEGIN { extends 'Bio::MAGETAB::Util::Reader::TagValueFile' };

has 'magetab_object'     => ( is         => 'rw',
                              isa        => 'Bio::MAGETAB::ArrayDesign',
                              required   => 0 );

# Define some standard regexps:
my $BLANK = qr/\A [ ]* \z/xms;

sub BUILD {

    my ( $self, $params ) = @_;

    my $dispatch = {
        qr/Array *Design *Name/i
            => sub{ $self->_add_singleton_datum('array_design', 'name', @_) },
        qr/Version/i
            => sub{ $self->_add_singleton_datum('array_design', 'version', @_) },
        qr/Provider/i
            => sub{ $self->_add_singleton_datum('array_design', 'provider', @_) },
        qr/Printing *Protocol/i
            => sub{ $self->_add_singleton_datum('array_design', 'printingProtocol', @_) },

        qr/Technology *Type/i
            => sub{ $self->_add_grouped_data('technology', 'value',       @_) },
        qr/Technology *(?:Type)? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('technology', 'termSource', @_) },
        qr/Technology *(?:Type)? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('technology', 'accession',  @_) },

        qr/Surface *Type/i
            => sub{ $self->_add_grouped_data('surface', 'value',       @_) },
        qr/Surface *(?:Type)? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('surface', 'termSource', @_) },
        qr/Surface *(?:Type)? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('surface', 'accession',  @_) },

        qr/Substrate *Type/i
            => sub{ $self->_add_grouped_data('substrate', 'value',       @_) },
        qr/Substrate *(?:Type)? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('substrate', 'termSource', @_) },
        qr/Substrate *(?:Type)? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('substrate', 'accession',  @_) },

        qr/Sequence *Polymer *Type/i
            => sub{ $self->_add_grouped_data('polymer', 'value',       @_) },
        qr/Sequence *Polymer *(?:Type)? *Term *Source *REF/i
            => sub{ $self->_add_grouped_data('polymer', 'termSource', @_) },
        qr/Sequence *Polymer *(?:Type)? *Term *Accession *Numbers?/i
            => sub{ $self->_add_grouped_data('polymer', 'accession',  @_) },

        qr/Term *Source *Names?/i
            => sub{ $self->_add_grouped_data('termsource', 'name',     @_) },
        qr/Term *Source *Files?/i
            => sub{ $self->_add_grouped_data('termsource', 'uri',      @_) },
        qr/Term *Source *Versions?/i
            => sub{ $self->_add_grouped_data('termsource', 'version',  @_) },        
    };

    $self->set_dispatch_table( $dispatch );

    return;
}

sub parse {

    my ( $self ) = @_;

    $self->_parse_header();
    $self->_parse_body();

    return $self->get_magetab_object();
}

sub _position_fh_at_section {

    my ( $self, $section ) = @_;

    # This has to be set for Text::CSV_XS.
    local $/ = $self->get_eol_char();

    my $adf_fh     = $self->get_filehandle();

    seek( $adf_fh, 0, 0 ) or croak("Error seeking within ADF filehandle: $!\n");

    my $larry;
    my $is_body;

    HEADER_LINE:
    while ( $larry = $self->getline($adf_fh) ) {
    
        # Skip empty lines, comments.
        next HEADER_LINE if $self->can_ignore( $larry );

	# Strip surrounding whitespace from each element.
        $larry = $self->strip_whitespace( $larry );

        # First useful line after the start of the ADF body.
        if ( $is_body ) {
            last HEADER_LINE;
        }

        # If we've seen the start of the main ADF body, note it.
        if ( $larry->[0] =~ /\A \[ [ ]* (?:$section) [ ]* \] \z/ixms ) {
            $is_body++;
            next HEADER_LINE;
        }
    }

    $self->confirm_full_parse( $larry );

    return ( $adf_fh, $larry );
}

sub _coerce_adf_main_headings {

    my ( $self, $larry ) = @_;

    my %mapping = (
        qr/Block [ ]* Columns?/ixms
            => 'block_column',

        qr/Block [ ]* Rows?/ixms
            => 'block_row',

        qr/Columns?/ixms
            => 'column',

        qr/Rows?/ixms
            => 'row',

        qr/Reporter [ ]* Names?/ixms
            => 'reporter_name',

        qr/Reporter [ ]* Sequences?/ixms
            => 'reporter_sequence',

        qr/Reporter [ ]* Database [ ]* Entr(?:y|ies) [ ]* \[ [ ]* (.+?) [ ]* \]/ixms
            => 'reporter_database_entry',

        qr/Reporter [ ]* Groups? [ ]* \[ [ ]* (.+?) [ ]* \]/ixms
            => 'reporter_group',

        qr/Reporter [ ]* Groups? [ ]* Term [ ]* Source [ ]* REFs?/ixms
            => 'reporter_group_term_source',

        qr/Reporter [ ]* Groups? [ ]* Term [ ]* Accession [ ]* Numbers?/ixms
            => 'reporter_group_term_accession',

        qr/Control [ ]* Types?/ixms
            => 'control_type',

        qr/Control [ ]* Types? [ ]* Term [ ]* Source [ ]* REFs?/ixms
            => 'control_type_term_source',

        qr/Control [ ]* Types? [ ]* Term [ ]* Accession [ ]* Numbers?/ixms
            => 'control_type_term_accession',

        qr/Composite [ ]* Element [ ]* Names?/ixms
            => 'composite_element_name',

        qr/Composite [ ]* Element [ ]* Database [ ]* Entr(?:y|ies) [ ]* \[ [ ]* (.+?) [ ]* \]/ixms
            => 'composite_element_database_entry',

        qr/Composite [ ]* Element [ ]* Comments?/ixms
            => 'composite_element_comment',

        # FIXME this isn't strictly according to the v1.1 specification.
        qr/Composite [ ]* Element [ ]* Comments? [ ]* \[ [ ]* (.+?) [ ]* \]/ixms
            => 'composite_element_comment',
    );

    return $self->_coerce_adf_headings( $larry, \%mapping );
}

sub _coerce_adf_mapping_headings {

    my ( $self, $larry ) = @_;

    my %mapping = (
        qr/Composite [ ]* Element [ ]* Names?/ixms
            => 'composite_element_name',

        qr/Map [ ]* 2 [ ]* Reporters?/ixms
            => 'map2reporters',

        qr/Composite [ ]* Element [ ]* Database [ ]* Entr(?:y|ies) [ ]* \[ [ ]* (.+?) [ ]* \]/ixms
            => 'composite_element_database_entry',

        qr/Composite [ ]* Element [ ]* Comments?/ixms
            => 'composite_element_comment',

        # FIXME this isn't strictly according to the v1.1 specification.
        qr/Composite [ ]* Element [ ]* Comments? [ ]* \[ [ ]* (.+?) [ ]* \]/ixms
            => 'composite_element_comment',
    );

    return $self->_coerce_adf_headings( $larry, \%mapping );
}

sub _coerce_adf_headings {

    my ( $self, $larry, $mapping ) = @_;

    my @header;
    COLUMN:
    foreach my $element ( @$larry ) {

        # We allow empty columns here, or multi-section ADFs won't
        # work as expected.
        if ( $element =~ $BLANK ) {
            push @header, [ q{} ];
            next COLUMN;
        }

        my $found;

        while ( my ( $regexp, $tag ) = each %$mapping ) {
            if ( $element =~ /\A $regexp \z/xms ) {
                push @header, [ $tag, $1 ];
                $found++;

                # Sadly we have to finish the while loop here, rather
                # than calling last(), due to the way while and each
                # work together.
            }
        }
        unless ( $found ) {
            croak("Error: Unrecognized ADF heading: $element\n");
        }
    }

    return \@header;
}

sub _parse_mapping_section {

    my ( $self ) = @_;

    my ($adf_fh, $larry) = $self->_position_fh_at_section('mapping');
    my $header = $self->_coerce_adf_mapping_headings( $larry );

    unless ( $header && scalar @$header ) {
        croak("Error: Unable to find ADF mapping section header line.\n");
    }

    # This has to be set for Text::CSV_XS.
    local $/ = $self->get_eol_char();

    my @design_elements;

    MAPPING_LINE:
    while ( my $larry = $self->getline($adf_fh) ) {

        # Skip empty lines, comments.
        next MAPPING_LINE if $self->can_ignore( $larry );

	# Strip surrounding whitespace from each element.
        $larry = $self->strip_whitespace( $larry );

        my @row_elements = $self->_parse_adfrow( $larry, $header );

        push @design_elements, @row_elements;
    }

    # Check we've parsed to the end of the file.
    $self->confirm_full_parse();

    # N.B. this *may* contain duplicates, beware.
    return \@design_elements;
}

sub _parse_body {

    my ( $self ) = @_;

    my ($adf_fh, $larry) = $self->_position_fh_at_section('main');
    my $header = $self->_coerce_adf_main_headings( $larry );

    unless ( $header && scalar @$header ) {
        croak("Error: Unable to find ADF main body header line.\n");
    }

    # This has to be set for Text::CSV_XS.
    local $/ = $self->get_eol_char();

    my %design_elements;

    BODY_LINE:
    while ( my $larry = $self->getline($adf_fh) ) {

        # Skip empty lines, comments.
        next BODY_LINE if $self->can_ignore( $larry );

	# Strip surrounding whitespace from each element.
        $larry = $self->strip_whitespace( $larry );

        # If we find a mapping section, parse it also.
        if ( $larry->[0] =~ /\A \[ [ ]* (?:mapping) [ ]* \] \z/ixms ) {
            my $mapped_elements = $self->_parse_mapping_section( $adf_fh );
            foreach my $element ( @$mapped_elements ) {
                $design_elements{ $element } = $element;
            }
            last BODY_LINE;
        }

        my @row_elements = $self->_parse_adfrow( $larry, $header );

        foreach my $element ( @row_elements ) {
            $design_elements{ $element } = $element;
        }
    }

    # Check we've parsed to the end of the file.
    $self->confirm_full_parse();

    # Add our DesignElements to our ArrayDesign
    my $array_design;
    if ( $array_design = $self->get_magetab_object() ) {
        $array_design->set_designElements( [ values %design_elements ] );
        $self->get_builder()->update( $array_design );
    }
    else {

        # Typically either instantiation or header parsing will have
        # populated magetab_object, so this is here just for
        # completeness if _parse_body ever gets called independently.
        $array_design = $self->get_builder()->find_or_create_array_design({
            name           => $self->get_uri(),
            designElements => [ values %design_elements ],
        });
        $self->set_magetab_object( $array_design );
    }

    return;
}

sub _add_composite_to_reporter {

    my ( $self, $composite, $reporter ) = @_;

    my @previous = $reporter->get_compositeElements();
    my $found = first { $composite eq $_ } @previous;
    unless ( $found ) {
        push @previous, $composite;
        $reporter->set_compositeElements( \@previous );
        $self->get_builder()->update( $reporter );
    }

    return;
}

sub _parse_adfrow_for_feature {

    my ( $self, $larry, $header ) = @_;

    # Map our internal column tags to MAGETAB attributes.
    my %data;
    my %dispatch = (
        'block_column'
            => sub { my ( $hc, $lc ) = @_;
                     $data{'blockCol'} = $lc; },
        'block_row'
            => sub { my ( $hc, $lc ) = @_;
                     $data{'blockRow'} = $lc; },
        'column'
            => sub { my ( $hc, $lc ) = @_;
                     $data{'col'} = $lc; },
        'row'
            => sub { my ( $hc, $lc ) = @_;
                     $data{'row'} = $lc; },
        'reporter_name'
            => sub { my ( $hc, $lc ) = @_;
                     $data{'reporter'}
                         = $self->get_builder()->find_or_create_reporter({
                             name => $lc,
                         }); },
    );

    # Call the dispatch methods to populate %data.
    COLUMN:
    for ( my $i = 0; $i < scalar @$larry; $i++ ) {
        next COLUMN if ( $header->[$i][0] eq q{} || $larry->[$i] =~ $BLANK );
        if ( my $sub = $dispatch{ $header->[$i][0] } ) {
            $sub->( $header->[$i], $larry->[$i] );
        }
    }

    return \%data;
}

sub _parse_adfrow_for_reporter {

    my ( $self, $larry, $header ) = @_;

    my (%data, $group_ts, $ctype_ts, $group_accno, $ctype_accno);

    # Map our internal column tags to MAGETAB attributes.
    my %dispatch = (
        'reporter_name'
            => sub { my ( $hc, $lc ) = @_;
                     $data{'name'} = $lc; },
        'reporter_sequence'
            => sub { my ( $hc, $lc ) = @_;
                     $data{'sequence'} = $lc; },
        'reporter_group'
            => sub { my ( $hc, $lc ) = @_;
                     push @{ $data{'groups'} },
                         $self->get_builder()->find_or_create_controlled_term({
                             category => $hc->[1],
                             value    => $lc,
                         }); },
        'control_type'
            => sub { my ( $hc, $lc ) = @_;
                     $data{'controlType'}
                         = $self->get_builder()->find_or_create_controlled_term({
                             category => 'ControlType',    # FIXME hard-coded.
                             value    => $lc,
                         }); },
        'reporter_database_entry'
            => sub { my ( $hc, $lc ) = @_;
                     my $ts_obj = $self->get_builder()->get_term_source({
                         'name' => $hc->[1],
                     });
                     push @{ $data{'databaseEntries'} },
                         $self->get_builder()->find_or_create_database_entry({
                             accession  => $lc,
                             termSource => $ts_obj,
                         }); },
        'reporter_group_term_source',
            => sub { my ( $hc, $lc ) = @_;
                     $group_ts = $self->get_builder()->get_term_source({
                         'name' => $lc,
                     }); },
        'control_type_term_source',
            => sub { my ( $hc, $lc ) = @_;
                     $ctype_ts = $self->get_builder()->get_term_source({
                         name => $lc,
                     }); },
        'reporter_group_term_accession',
            => sub { my ( $hc, $lc ) = @_;
                     $group_accno = $lc;
                 },
        'control_type_term_accession',
            => sub { my ( $hc, $lc ) = @_;
                     $ctype_accno = $lc;
                 },
    );

    # Call the dispatch methods to populate %data.
    COLUMN:
    for ( my $i = 0; $i < scalar @$larry; $i++ ) {
        next COLUMN if ( $header->[$i][0] eq q{} || $larry->[$i] =~ $BLANK );
        if ( my $sub = $dispatch{ $header->[$i][0] } ) {
            $sub->( $header->[$i], $larry->[$i] );
        }
    }

    # Add term sources and accessions to groups, control types.
    foreach my $group ( @{ $data{'groups'} } ) {
        if ( $group_ts ) {
            $group->set_termSource( $group_ts );
        }
        if ( $group_accno ) {
            $group->set_accession( $group_accno );
        }
        $self->get_builder()->update( $group );
    }
    if ( my $ctype = $data{'controlType'} ) {
        if ( $ctype_ts ) {
            $ctype->set_termSource( $ctype_ts );
        }
        if ( $ctype_accno ) {
            $ctype->set_accession( $ctype_accno );
        }
        $self->get_builder()->update( $ctype );
    }

    return \%data;
}

sub _parse_adfrow_for_composite {

    my ( $self, $larry, $header ) = @_;

    my %data;

    my %dispatch = (
        'composite_element_name'
            => sub { my ( $hc, $lc ) = @_;
                     $data{'name'} = $lc; },
        'composite_element_database_entry'
            => sub { my ( $hc, $lc ) = @_;
                     my $ts_obj = $self->get_builder()->get_term_source({
                         'name' => $hc->[1],
                     });
                     push @{ $data{'databaseEntries'} },
                         $self->get_builder()->find_or_create_database_entry({
                             accession  => $lc,
                             termSource => $ts_obj,
                         }); },
        'composite_element_comment'
            => sub { my ( $hc, $lc ) = @_;

                     # We allow comment[] tags here, even though it
                     # isn't actually in the v1.1 specification.
                     my $name = defined $hc->[1] ? $hc->[1] : 'CompositeElementComment';

                     # FIXME this should ideally include the
                     # composite element as 'object' for ID purposes.
                     push @{ $data{'comments'} },
                         $self->get_builder()->create_comment({
                             name  => $name,
                             value => $lc,
                         }); },
    );

    # Call the dispatch methods to populate %data.
    COLUMN:
    for ( my $i = 0; $i < scalar @$larry; $i++ ) {
        next COLUMN if ( $header->[$i][0] eq q{} || $larry->[$i] =~ $BLANK );
        if ( my $sub = $dispatch{ $header->[$i][0] } ) {
            $sub->( $header->[$i], $larry->[$i] );
        }
    }

    return \%data;
}

sub _parse_adfrow_for_map2rep {

    my ( $self, $larry, $header ) = @_;

    my $map2reporter;
    COLUMN:
    for ( my $i = 0; $i < scalar @$larry; $i++ ) {
        next COLUMN if ( $header->[$i][0] eq q{} || $larry->[$i] =~ $BLANK );
        if ( $header->[$i][0] eq 'map2reporters' ) {
            $map2reporter = $larry->[$i];
        }
    }

    return $map2reporter;
}

# Copied directly from List::MoreUtils 0.21, rather than adding a
# rather trivial dependency.
sub _any (&@) {
    my $f = shift;
    return if ! @_;
    for (@_) {
        return 1 if $f->();
    }
    return 0;
}
    
sub _all (&@) {
    my $f = shift;
    return if ! @_;
    for (@_) {
        return 0 if ! $f->();
    }
    return 1;
}

sub _parse_adfrow {

    my ( $self, $larry, $header ) = @_;

    my $feature_data = $self->_parse_adfrow_for_feature( $larry, $header );
    my $feature;
    my @required_feat_info = qw( blockCol blockRow col row );
    if ( _all { defined($feature_data->{$_}) } @required_feat_info ) {
        my $ad = $self->get_magetab_object()
            or confess("Error: ArrayDesign MAGETAB object not registered with parser object");
        $feature_data->{'array_design'} = $ad;
        $feature = $self->get_builder()->find_or_create_feature( $feature_data );
    }
    elsif ( _any { defined($feature_data->{$_}) } @required_feat_info ) {
        croak("Error: Incomplete feature-level information provided in ADF.");
    }

    my $reporter_data = $self->_parse_adfrow_for_reporter( $larry, $header );
    my $reporter;
    if ( defined($reporter_data->{'name'}) ) {
        $reporter = $self->get_builder()->find_or_create_reporter( $reporter_data );
    }

    my $map2rep_data = $self->_parse_adfrow_for_map2rep( $larry, $header );
    my @map2reporters;
    if ( $map2rep_data ) {
        foreach my $name ( split /\s*;\s*/, $map2rep_data ) {
            push @map2reporters, $self->get_builder()->find_or_create_reporter({
                name => $name,
            });
        }
    }

    my $composite_data = $self->_parse_adfrow_for_composite( $larry, $header );
    my $composite;
    if ( defined($composite_data->{'name'}) ) {
        $composite = $self->get_builder()->find_or_create_composite_element( $composite_data );

        # Link reporter to composite element.
        if ( $reporter ) {
            $self->_add_composite_to_reporter( $composite, $reporter );
        }

        # Link reporters from the mapping section to composite element.
        foreach my $reporter ( @map2reporters ) {
            $self->_add_composite_to_reporter( $composite, $reporter );
        }            
    }

    return( grep { defined $_ } $feature, $reporter, $composite, @map2reporters );
}

sub _parse_header {

    my ( $self ) = @_;

    # Parse the initial tag-value ADF header into memory here.
    my $array_of_rows = $self->_read_header_as_arrayref();

    # Check tags for duplicates, make sure that tags are recognized.
    my $adf_data = $self->_validate_arrayref_tags( $array_of_rows );

    # Populate the ADF object's internal data text_store attribute.
    foreach my $datum ( @$adf_data ) {
        my ( $tag, $values ) = @$datum;
	$self->_dispatch( $tag, @$values );
    }

    # Actually generate the Bio::MAGETAB objects.
    my ( $array_design, $magetab ) = $self->_generate_magetab();

    return ( $array_design, $magetab );
}

sub _generate_magetab {

    my ( $self ) = @_;

    my $magetab      = $self->get_builder()->get_magetab();
    my $term_sources = $self->_create_termsources();
    my $array_design = $self->_generate_array_design();

    return ( $array_design, $magetab );
}

sub _generate_array_design {

    my ( $self ) = @_;

    my $technology_types = $self->_create_controlled_terms(
        'technology',      'TechnologyType',   # FIXME hard-coded
    );
    my $surface_types    = $self->_create_controlled_terms(
        'surface',         'SurfaceType',      # FIXME hard-coded
    );
    my $substrate_types  = $self->_create_controlled_terms(
        'substrate',       'SubstrateType',    # FIXME hard-coded
    );
    my $polymer_types    = $self->_create_controlled_terms(
        'polymer',         'PolymerType',      # FIXME hard-coded
    );

    my $data = $self->get_text_store()->{'array_design'};
    
    # Find or create the target ArrayDesign object.  N.B. we can only
    # use the first of each set of controlled terms here, since these
    # are 0..1 both in the specification and the model.
    my $array_design;
    if ( $array_design = $self->get_magetab_object() ) {
        while ( my ( $key, $value ) = each %{ $data } ) {
            my $setter = "set_$key";
            $array_design->$setter( $value ) if defined $value;
        }
    }
    else {
        $array_design = $self->get_builder()->find_or_create_array_design({
            %{ $data },
        });
        $self->set_magetab_object( $array_design );
    }

    $array_design->set_technologyType     ( $technology_types->[0]      ) if @$technology_types;
    $array_design->set_surfaceType        ( $surface_types->[0]         ) if @$surface_types;
    $array_design->set_substrateType      ( $substrate_types->[0]       ) if @$substrate_types;
    $array_design->set_sequencePolymerType( $polymer_types->[0]         ) if @$polymer_types;

    my $comments = $self->_create_comments();
    $array_design->set_comments( $comments );
    $self->get_builder()->update( $array_design );

    return $array_design;    
}

sub _read_header_as_arrayref {

    my ( $self ) = @_;
    
    # This has to be set for Text::CSV_XS.
    local $/ = $self->get_eol_char();

    my $adf_fh     = $self->get_filehandle();

    seek( $adf_fh, 0, 0 ) or croak("Error seeking within ADF filehandle: $!\n");

    my ( $larry, @rows );

    FILE_LINE:
    while ( $larry = $self->getline($adf_fh) ) {
    
        # Skip empty lines, comments.
        next FILE_LINE if $self->can_ignore( $larry );

	# Strip surrounding whitespace from each element.
        $larry = $self->strip_whitespace( $larry );

        my ( $tag, @values ) = @$larry;

        next FILE_LINE if ( $tag =~ /\A \[ [ ]* header [ ]* \] \z/ixms );
        last FILE_LINE if ( $tag =~ /\A \[ [ ]* (?:main|mapping) [ ]* \] \z/ixms );

        # Strip off empty trailing values.
	my $end_value;
	until ( defined($end_value) && $end_value !~ /\A \s* \z/xms ) {
	    $end_value = pop(@$larry);
	}
	push @$larry, $end_value;

	# Reset empty strings to undefs.
	foreach my $value ( @$larry ) {
	    undef($value) if ( defined($value) && $value eq q{} );
	}

	push @rows, $larry;
    }

    $self->confirm_full_parse( $larry );

    return \@rows;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Reader::ADF - ADF parser class.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::Reader::ADF;
 my $parser = Bio::MAGETAB::Util::Reader::ADF->new({
     uri => $adf_filename,
 });
 my $array_design = $parser->parse();

=head1 DESCRIPTION

This class is used to parse ADF files. It can be used on its own, but
more often you will want to use the main Bio::MAGETAB::Util::Reader
class which handles extended parsing options more transparently.

=head1 ATTRIBUTES

See the L<TagValueFile|Bio::MAGETAB::Util::Reader::TagValueFile> class for superclass attributes.

=over 2

=item magetab_object

A Bio::MAGETAB::ArrayDesign object. This can either be set upon
instantiation, or a new object will be created for you. It can be
retrieved at any time using C<get_magetab_object>.

=back

=head1 METHODS

=over 2

=item parse

Parse the ADF pointed to by C<$self-E<gt>get_uri()>. Returns the
Bio::MAGETAB::ArrayDesign object updated with the ADF contents.

=back

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Reader::TagValueFile>
L<Bio::MAGETAB::Util::Reader::Tabfile>
L<Bio::MAGETAB::Util::Reader>
L<Bio::MAGETAB::ArrayDesign>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
