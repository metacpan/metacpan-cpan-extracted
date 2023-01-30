package Data::Validate::OpenAPI;

use strict;
use warnings;

# ABSTRACT: Validate and untaint input parameters via OpenAPI schema
our $VERSION = '0.2.0'; # VERSION

use OpenAPI::Render;
use parent OpenAPI::Render::;

use Data::Validate qw( is_integer );
use Data::Validate::Email qw( is_email );
use Data::Validate::IP qw( is_ipv4 is_ipv6 );
use Data::Validate::URI qw( is_uri );
use DateTime::Format::RFC3339;
use Scalar::Util qw( blessed );

# Global variable for reporter subroutine
our $reporter;

=head1 SYNOPSIS

    use CGI;
    use Data::Validate::OpenAPI;

    my $validator = Data::Validate::OpenAPI->new( $parsed_openapi_json );
    my $params = $validator->validate( '/', 'post', CGI->new );

=head1 DESCRIPTION

C<Data::Validate::OpenAPI> validates and untaints CGI parameters using a supplied OpenAPI schema.
It applies format-specific validation and untainting using appropriate L<Data::Validate> subclasses, including email, IP, URI and other.
Also it checks values against enumerators and patterns, if provided.

=head1 SUBROUTINES

=method C<new>

Takes a parsed OpenAPI schema as returned by L<JSON> module's C<decode_json()>.
Returns validator ready to validate CGI parameters.

=method C<validate>

Takes a call path, HTTP method and a CGI object.
Returns a hash of validated pairs of CGI parameter keys and their values.
At this point values failing to validate are not reported.
Keys for parameters having no valid values are omitted from the returned hash.

=cut

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
            my( @good_values, @bad_values );
            for (ref $par_hash->{$name} eq 'ARRAY' ? @{$par_hash->{$name}} : split "\0", $par_hash->{$name}) {
                my $value = validate_value( $_, $schema );
                push @good_values, $value if defined $value;
                push @bad_values, $value unless defined $value;
            }
            $par->{$name} = \@good_values if @good_values;
            $reporter->( $name, @bad_values ) if $reporter && @bad_values;
        } else {
            my $value = validate_value( $par_hash->{$name}, $schema );
            $par->{$name} = $value if defined $value;
            if( $reporter ) {
                $reporter->( $name, $par_hash->{$name} );
            }
        }
    }

    return $par;
}

=head1 VALIDATION ERROR REPORTING

By default validation errors are silent by default.
However, this can be overridden by setting module variable C<$Data::Validate::OpenAPI::reporter> to a subroutine reference to be called upon validation failure with the following signature:

    $reporter->( $parameter_name, @bad_values );

At this point the module does not indicate which particular check failed during the validation.

=cut

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
