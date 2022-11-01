package Data::Validate::OpenAPI;

use strict;
use warnings;

# ABSTRACT: Validate and untaint input parameters via OpenAPI schema
our $VERSION = '0.1.0'; # VERSION

use OpenAPI::Render;
use parent OpenAPI::Render::;

use Data::Validate qw( is_integer );
use Data::Validate::Email qw( is_email );
use Data::Validate::IP qw( is_ipv4 is_ipv6 );
use Data::Validate::URI qw( is_uri );
use DateTime::Format::RFC3339;
use Scalar::Util qw( blessed );

sub validate
{
    my( $self, $path, $method, $input ) = @_;

    # FIXME: More specific parameters override less specific ones.
    # FIXME: Request body parameters should be taken from CGI object
    #        using their own specific methods.
    my $api = $self->{api};
    my @parameters =
        grep { $_->{in} eq 'query' }
        exists $api->{paths}{$path}{parameters}
           ? @{$api->{paths}{$path}{parameters}} : (),
        exists $api->{paths}{$path}{$method}{parameters}
           ? @{$api->{paths}{$path}{$method}{parameters}} : (),
        exists $api->{paths}{$path}{$method}{requestBody}
           ? OpenAPI::Render::RequestBody2Parameters( $api->{paths}{$path}{$method}{requestBody} ) : ();

    my $par = {};
    my $par_hash = $input;

    if( blessed $par_hash ) {
        $par_hash = { $par_hash->Vars }; # object is assumed to be CGI
    }

    for my $description (@parameters) {
        my $name = $description->{name};
        my $schema = $description->{schema} if $description->{schema};
        if( !exists $par_hash->{$name} ) {
            if( $schema && exists $schema->{default} ) {
                $par->{$name} = $schema->{default};
            }
            next;
        }

        if( $schema && $schema->{type} eq 'array' ) {
            my @values = grep { defined $_ }
                         map { validate_value( $_, $schema ) }
                         ref $par_hash->{$name} eq 'ARRAY'
                            ? @{$par_hash->{$name}}
                            : split "\0", $par_hash->{$name};
            $par->{$name} = \@values if @values;
        } else {
            my $value = validate_value( $par_hash->{$name}, $schema );
            $par->{$name} = $value if defined $value;
        }
    }

    return $par;
}

sub validate_value
{
    my( $value, $schema ) = @_;

    my $format = $schema->{format} if $schema;

    # FIXME: Maybe employ a proper JSON Schema validator? Not sure
    # if it untaints, though.
    if( !defined $format ) {
        # nothing to do here
    } elsif( $format eq 'date-time' ) {
        my $parser = DateTime::Format::RFC3339->new;
        $value = $parser->format_datetime( $parser->parse_datetime( $value ) );
    } elsif( $format eq 'email' ) {
        $value = is_email $value;
    } elsif( $format eq 'integer' ) {
        $value = is_integer $value;
    } elsif( $format eq 'ipv4' ) {
        $value = is_ipv4 $value;
    } elsif( $format eq 'ipv6' ) {
        $value = is_ipv6 $value;
    } elsif( $format eq 'uri' ) {
        $value = is_uri $value;
    } elsif( $format eq 'uuid' ) {
        # Regex taken from Data::Validate::UUID. Module is not used as
        # it does not untaint the value.
        if( $value =~ /^([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})$/i ) {
            $value = $1;
        } else {
            return;
        }
    }

    return unless defined $value;

    if( $schema && $schema->{enum} ) {
        ( $value ) = grep { $value eq $_ } @{$schema->{enum}};
        return unless defined $value;
    }

    if( $schema && $schema->{pattern} ) {
        return unless $value =~ /^($schema->{pattern})$/;
        $value = $1;
    }

    ## Not sure this is appropriate here
    # if( defined $value && $value eq '' &&
    #     ( !exists $description->{allowEmptyValue} ||
    #       $description->{allowEmptyValue} eq 'false' ) ) {
    #     return; # nothing to do
    # }

    return $value;
}

1;
