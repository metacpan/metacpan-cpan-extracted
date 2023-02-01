package Data::Validate::OpenAPI;

use strict;
use warnings;

# ABSTRACT: Validate and untaint input parameters via OpenAPI schema
our $VERSION = '0.3.0'; # VERSION

use OpenAPI::Render;
use parent OpenAPI::Render::;

use Data::Validate qw( is_integer );
use Data::Validate::Email qw( is_email );
use Data::Validate::IP qw( is_ipv4 is_ipv6 );
use Data::Validate::URI qw( is_uri );
use DateTime::Format::RFC3339;
use Scalar::Util qw( blessed );

=head1 SYNOPSIS

    use CGI;
    use Data::Validate::OpenAPI;

    my $validator = Data::Validate::OpenAPI->new( $parsed_openapi_json );
    my $params = $validator->validate( '/', 'post', CGI->new );

=head1 DESCRIPTION

C<Data::Validate::OpenAPI> validates and untaints CGI parameters using a supplied OpenAPI schema.
It applies format-specific validation and untainting using appropriate L<Data::Validate> subclasses, including email, IP, URI and other.
Also it checks values against enumerators and patterns, if provided.
At this point values without supported formats, enumerators or patterns are returned as they are, tainted.
This behavior may change in the future.

C<Data::Validate::OpenAPI> does not validate OpenAPI schemas.
To do so, refer to L<JSON::Validator>.

=head1 METHODS

=head2 C<new( $api )>

Takes a parsed OpenAPI schema as returned by L<JSON> module's C<decode_json()>.
Returns validator ready to validate CGI parameters.

=head2 C<validate( $path, $method, $cgi )>

Takes a call path, HTTP method and a CGI object.
Returns a hash of validated pairs of CGI parameter keys and their values.
At this point values failing to validate are not reported.
Keys for parameters having no valid values are omitted from the returned hash.

The interface for this method is bound to change, but backwards compatibility will be preserved on best effort basis.

=cut

sub validate
{
    my( $self, $path, $method, $input ) = @_;

    # FIXME: More specific parameters override less specific ones.
    # FIXME: Request body parameters should be taken from CGI object
    #        using their own specific methods.
    # TODO: In future, parameters other than 'query' can be returned too.
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
                my $value = _validate_value( $_, $schema );
                push @good_values, $value if defined $value;
                push @bad_values, $value unless defined $value;
            }
            $par->{$name} = \@good_values if @good_values;
            $self->_report( $name, @bad_values ) if @bad_values;
        } else {
            my $value = _validate_value( $par_hash->{$name}, $schema );
            $par->{$name} = $value if defined $value;
            $self->_report( $name, $value ) unless defined $value;
        }
    }

    return $par;
}

=head1 VALIDATION ERROR REPORTING

By default validation errors are silent, but there are two ways to handle validation errors: by setting validator-specific subroutine or by setting module variable:

    my $reporter_sub = sub { warn "value for '$_[0]' is incorrect" };

    # Set a reporter for this particular validator instance:
    $validator->reporter( $reporter_sub );

    # Set a reporter for all instances of this class:
    $Data::Validate::OpenAPI::reporter = $reporter_sub;

If any of them is set, reporter subroutine is called with the following parameters:

    $reporter_sub->( $parameter_name, @bad_values );

Validator-specific reporter takes precedence.
At this point the module does not indicate which particular check failed during the validation.

=cut

# Global variable for reporter subroutine
our $reporter;

=head2 C<reporter( $reporter_sub )> method

Set reporter subroutine to be called for each parameter failing the validation:

    $reporter_sub->( $parameter_name, @bad_values );

=cut

sub reporter
{
    my( $self, $reporter_sub ) = @_;
    $self->{reporter} = $reporter_sub;
}

sub _report
{
    my( $self, $name, @values ) = @_;

    if( $self->{reporter} ) {
        $self->{reporter}->( $name, @values );
    } elsif( $reporter ) {
        $reporter->( $name, @values );
    }
}

my %format_methods = (
    'date-time' => sub { my $parser = DateTime::Format::RFC3339->new;
                         return $parser->format_datetime( $parser->parse_datetime( $_[0] ) ) },
    email       => \&is_email,
    integer     => \&is_integer,
    ipv4        => \&is_ipv4,
    ipv6        => \&is_ipv6,
    uri         => \&is_uri,

    # Regex is taken from Data::Validate::UUID.
    # The module itself is not used as it does not untaint the value.
    uuid        => sub { return $1 if $_[0] =~ /^([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})$/i },
);

sub _validate_value
{
    my( $value, $schema ) = @_;

    my $format = $schema->{format} if $schema;

    # If empty values are explicitly (dis)allowed, they are checked here.
    if( $value eq '' && $schema && $schema->{allowEmptyValue} ) {
        return $value if $schema->{allowEmptyValue} eq 'true';
        return;
    }

    # 'enum' is the strictest possible validation method.
    if( $schema && $schema->{enum} ) {
        return grep { $value eq $_ } @{$schema->{enum}};
    }

    # 'pattern' is also quite strict.
    if( $schema && $schema->{pattern} ) {
        return $value =~ /^($schema->{pattern})$/ ? $1 : undef;
    }

    # FIXME: Maybe employ a proper JSON Schema validator?
    #        Not sure if it untaints, though.
    if( $format && exists $format_methods{$format} ) {
        return $format_methods{$format}->( $value );
    }

    # Tainted values may still get till here and are returned as such.
    return $value;
}

=head1 SEE ALSO

L<https://spec.openapis.org/oas/v3.0.2.html>

=cut

1;
