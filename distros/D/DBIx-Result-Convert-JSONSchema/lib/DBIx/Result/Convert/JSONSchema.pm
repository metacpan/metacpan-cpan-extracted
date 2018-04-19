package DBIx::Result::Convert::JSONSchema;

=head1 NAME
    DBIx::Result::Convert::JSONSchema - Convert DBIx result schema to JSON schema

=for html

    <a href='https://travis-ci.org/Humanstate/p5-dbix-result-convert-jsonschema?branch=master'><img src='https://travis-ci.org/Humanstate/p5-dbix-result-convert-jsonschema.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/github/Humanstate/p5-dbix-result-convert-jsonschema?branch=master'><img src='https://coveralls.io/repos/github/Humanstate/p5-dbix-result-convert-jsonschema/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

    0.02

=head1 SYNOPSIS

    use DBIx::Result::Convert::JSONSchema;

    my $SchemaConvert = DBIx::Result::Convert::JSONSchema->new(
        schema => _DBIx::Class::Schema_
    );
    my $json_schema = $SchemaConvert->get_json_schema( _DBIx::Class::ResultSource_ );

=head1 DESCRIPTION

This module attempts basic conversion of L<DBIx::Class::ResultSource> to equivalent
of L<http://json-schema.org/>.
By default the conversion assumes that the L<DBIx::Class::ResultSource> originated
from MySQL database. Thus all the types and defaults are set based on MySQL
field definitions.
It is, however, possible to overwrite field type map and length map to support
L<DBIx::Class::ResultSource> from other database solutions.

Note, relations between tables are not taken in account!

=cut

use Moo;
use Types::Standard qw/ :all /;

use Carp;
use Module::Load qw/ load /;
use Storable qw/ dclone /;

our $VERSION = '0.02';


has schema => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::Class::Schema'],
    required => 1,
);

has schema_source => (
    is      => 'lazy',
    isa     => Enum[ qw/ MySQL / ],
    default => 'MySQL',
);

has length_type_map => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        return {
            string  => [ qw/ minLength maxLength / ],
            number  => [ qw/ minimum maximum / ],
            integer => [ qw/ minimum maximum / ],
        };
    },
);

has type_map => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        my ( $self ) = @_;

        my $type_class = __PACKAGE__ . '::Type::' . $self->schema_source;
        load $type_class;

        return $type_class->get_type_map;
    },
);

has length_map => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        my ( $self ) = @_;

        my $defaults_class = __PACKAGE__ . '::Default::' . $self->schema_source;
        load $defaults_class;

        return $defaults_class->get_length_map;
    },
);

has pattern_map => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default  => sub {
        my ( $self ) = @_;
        return {
            date      => '^\d{4}-\d{2}-\d{2}$',
            time      => '^\d{2}:\d{2}:\d{2}$',
            year      => '^\d{4}$',
            datetime  => '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$',
            timestamp => '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$',
        };
    }
);


=head2 C<get_json_schema>

Returns somewhat equivalent JSON schema based on DBIx result source name.

    my $json_schema = $converted->get_json_schema( 'TableSource', {
        decimals_to_pattern             => 1,
        has_schema_property_description => 1,
        allow_additional_properties     => 0,
        overwrite_schema_property_keys  => {
            name    => 'cat',
            address => 'dog',
        },
        overwrite_schema_properties     => {
            name => {
                _action  => 'merge', # one of - merge/overwrite
                minimum  => 10,
                maximum  => 20,
                type     => 'number',
            },
        },
        exclude_required   => [ qw/ name address / ],
        exclude_properties => [ qw/ mouse house / ],
    });

    ARGS:
        Required ARGS[0]:
            - Source name e.g. 'Address'
        Optional ARGS[1]:
            decimals_to_pattern:
                True/false value to indicate if 'number' type field should be converted to 'string' type with
                RegExp pattern based on decimal place definition in database
            has_schema_property_description:
                True/false value to indicate if basic JSON schema properties should include 'description' key
                containing basic information about field
            allow_additional_properties:
                1/0 to indicate if JSON schema should accept properties which are not defined by default
            overwrite_schema_property_keys:
                HashRef containing { OLD_PROPERTY => NEW_PROPERTY } to overwrite default column names, default
                property attributes from old key will be assigned to new key
                (!) The key conversion is executed last, every other option e.g. exclude_properties will work
                only on original database column names
            overwrite_schema_properties:
                HashRef of { PROPERTY_NAME => { ... JSON SCHEMA ATTRIBUTES ... } } which will replace default generated
                schema properties.
            exclude_required:
                ArrayRef of database column names which should always be EXCLUDED from required schema properties
            include_required:
                ArrayRef of database column names which should always be INCLUDED in required schema properties
            exclude_properties:
                ArrayRef of database column names which should be excluded from JSON schema

=cut

sub get_json_schema {
    my ( $self, $source, $args ) = @_;
    $args = dclone( $args // {} );

    croak 'missing schema source' unless $source;

    # additional schema generation options
    my $decimals_to_pattern             = delete $args->{decimals_to_pattern};
    my $has_schema_property_description = delete $args->{has_schema_property_description};
    my $allow_additional_properties     = delete $args->{allow_additional_properties}    // 0;
    my $overwrite_schema_property_keys  = delete $args->{overwrite_schema_property_keys} // {};
    my $overwrite_schema_properties     = delete $args->{overwrite_schema_properties}    // {};
    my %exclude_required                = map { $_ => 1 } @{ delete $args->{exclude_required}   || [] };
    my %include_required                = map { $_ => 1 } @{ delete $args->{include_required}   || [] };
    my %exclude_properties              = map { $_ => 1 } @{ delete $args->{exclude_properties} || [] };

    my %json_schema = (
        type                  => 'object',
        additional_properties => $allow_additional_properties,
        required              => [],
        properties            => {},
    );

    my $source_info = $self->_get_column_info($source);

    SCHEMA_COLUMN:
    foreach my $column ( keys %{ $source_info } ) {
        next SCHEMA_COLUMN if $exclude_properties{ $column };

        my $column_info = $source_info->{ $column };

        # DBIx schema data type -> JSON schema data type
        my $json_type = $self->type_map->{ $column_info->{data_type} }
            or croak sprintf(
                'unknown data type - %s (source: %s, column: %s)',
                $column_info->{data_type}, $source, $column
            );

        $json_schema{properties}->{ $column }->{type} = $json_type;

        # DBIx schema size constraint -> JSON schema size constraint
        if ( $self->length_map->{ $column_info->{data_type} } ) {
            $self->_set_json_schema_property_range( \%json_schema, $column_info, $column );
        }

        # DBIx schema required -> JSON schema required
        if ( $include_required{ $column } ) {
            my $required_property = $overwrite_schema_property_keys->{ $column } // $column;
            push @{ $json_schema{required} }, $required_property;
        }
        elsif ( ! $source_info->{ $column }->{default_value} && ! $source_info->{ $column }->{is_nullable} && ! $exclude_required{ $column } ) {
            my $required_property = $overwrite_schema_property_keys->{ $column } // $column;
            push @{ $json_schema{required} }, $required_property;
        }

        # DBIx schema defaults -> JSON schema defaults (no refs e.g. current_timestamp)
        if ( $source_info->{ $column }->{default_value} && ! ref $source_info->{ $column }->{default_value} ) {
            $json_schema{properties}->{ $column }->{default} = $source_info->{ $column }->{default_value};
        }

        # DBIx schema list -> JSON enum list
        if ( $json_type eq 'enum' && $column_info->{extra} && $column_info->{extra}->{list} ) { # no autovivification
            $json_schema{properties}->{ $column }->{enum} = $column_info->{extra}->{list};
        }

        # Consider 'is nullable' to accept 'null' values in all cases
        if ( $source_info->{ $column }->{is_nullable} ) {
            if ( $json_type eq 'enum' ) {
                $json_schema{properties}->{ $column }->{enum} //= [];
                push @{ $json_schema{properties}->{ $column }->{enum} }, 'null';
            }
            else {
                $json_schema{properties}->{ $column }->{type} = [ $json_type, 'null' ];
            }
        }

        # DBIx decimal numbers -> JSON schema numeric string pattern
        if ( $json_type eq 'number' && $decimals_to_pattern ) {
            if ( $column_info->{size} && ref $column_info->{size} eq 'ARRAY' ) {
                $json_schema{properties}->{ $column }->{type}    = 'string';
                $json_schema{properties}->{ $column }->{pattern} = $self->_get_decimal_pattern( $column_info->{size} );
            }
        }

        # JSON schema field patterns
        if ( $self->pattern_map->{ $column_info->{data_type} } ) {
            $json_schema{properties}->{ $column }->{pattern} = $self->pattern_map->{ $column_info->{data_type} };
        }

        # JSON schema property description
        if ( ! $json_schema{properties}->{ $column }->{description} && $has_schema_property_description ) {
            my $property_description = $self->_get_json_schema_property_description(
                $overwrite_schema_property_keys->{ $column } // $column,
                $json_schema{properties}->{ $column }
            );
            $json_schema{properties}->{ $column }->{description} = $property_description;
        }

        # Overwrites: merge JSON schema property key values with custom ones
        if ( my $overwrite_property = delete $overwrite_schema_properties->{ $column } ) {
            my $action = delete $overwrite_property->{_action} // 'merge';

            $json_schema{properties}->{ $column } = {
                %{ $action eq 'merge' ? $json_schema{properties}->{ $column } : {} },
                %{ $overwrite_property }
            };
        }

        # Overwrite: replace JSON schema keys
        if ( my $new_key = $overwrite_schema_property_keys->{ $column } ) {
            $json_schema{properties}->{ $new_key } = delete $json_schema{properties}->{ $column };
        }
    }

    return \%json_schema;
}

# Return DBIx result source column info for the given result class name
sub _get_column_info {
    my ( $self, $source ) = @_;

    return $self->schema->source($source)->columns_info;
}

# Returns RegExp pattern for decimal numbers based on database field definition
sub _get_decimal_pattern {
    my ( $self, $size ) = @_;

    my ( $x, $y ) = @{ $size };
    return sprintf '^\d{1,%s}\.\d{0,%s}$', $x - $y, $y;
}

# Generates somewhat logical field description based on type and length constraints
sub _get_json_schema_property_description {
    my ( $self, $column, $property ) = @_;

    if ( ! $property->{type} ) {
        if ( $property->{enum} ) {
            return sprintf 'Enum list type, one of - %s', join( ', ', @{ $property->{enum} } );
        }

        return '';
    }

    return '' if $property->{type} eq 'object'; # no idea how to handle

    my %types;
    if ( ref $property->{type} eq 'ARRAY' ) {
        %types = map { $_ => 1 } @{ $property->{type} };
    }
    else {
        $types{ $property->{type} } = 1;
    }

    my $description = '';
    $description   .= 'Optional' if $types{null};

    my $type_part;
    if ( grep { /^integer|number$/ } keys %types ) {
        $type_part = 'numeric';
    }
    else {
        ( $type_part ) = grep { $_ ne 'null' } keys %types; # lucky roll, last type that isn't 'null' should be legit
    }

    $description .= $description ? " $type_part" : ucfirst $type_part;
    $description .= sprintf ' type value for field %s', $column;

    if ( ( grep { /^integer$/ } keys %types ) && $property->{maximum} ) {
        my $integer_example = $property->{default} // int rand $property->{maximum};
        $description       .= ' e.g. ' . $integer_example;
    }
    elsif ( ( grep { /^string$/ } keys %types ) && $property->{pattern} ) {
        $description .= sprintf ' with pattern %s ', $property->{pattern};
    }

    return $description;
}

# Convert from DBIx field length to JSON schema field length based on field type
sub _set_json_schema_property_range {
    my ( $self, $json_schema, $column_info, $column ) = @_;

    my $json_schema_min_type = $self->length_type_map->{ $self->type_map->{ $column_info->{data_type} } }->[0];
    my $json_schema_max_type = $self->length_type_map->{ $self->type_map->{ $column_info->{data_type} } }->[1];

    my $json_schema_min = $self->_get_json_schema_property_min_max_value( $column_info, 0 );
    my $json_schema_max = $self->_get_json_schema_property_min_max_value( $column_info, 1 );

    # bump min value to 0 (don't see how this starts from negative)
    $json_schema_min = 0 if $column_info->{is_auto_increment};

    $json_schema->{properties}->{ $column }->{ $json_schema_min_type } = $json_schema_min;
    $json_schema->{properties}->{ $column }->{ $json_schema_max_type } = $json_schema_max;

    if ( $column_info->{size} ) {
        $json_schema->{properties}->{ $column }->{ $json_schema_max_type } = $column_info->{size};
    }

    return;
}

# Returns min/max value from DBIx result field definition or lookup from defaults
sub _get_json_schema_property_min_max_value {
    my ( $self, $column_info, $range ) = @_;

    if ( $column_info->{extra} && $column_info->{extra}->{unsigned} ) { # no autovivification
        return $self->length_map->{ $column_info->{data_type} }->{unsigned}->[ $range ];
    }

    return ref $self->length_map->{ $column_info->{data_type} } eq 'ARRAY' ? $self->length_map->{ $column_info->{data_type} }->[ $range ]
        : $self->length_map->{ $column_info->{data_type} }->{signed}->[ $range ];
}

=head1 SEE ALSO

L<DBIx::Class::ResultSource> - Result source object

=head1 AUTHOR

malishew - C<malishew@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/p5-dbix-result-convert-jsonschema

=cut

__PACKAGE__->meta->make_immutable;
