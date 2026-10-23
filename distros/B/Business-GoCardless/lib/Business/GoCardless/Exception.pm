package Business::GoCardless::Exception;

=head1 NAME

Business::GoCardless::Exception

=head1 DESCRIPTION

Exception handling for the Business::GoCardless modules, uses the Throwable
module.

=cut

use strict;
use warnings;

use Moo;
use JSON ();
use Carp qw/ cluck /;

with 'Throwable';

=head1 ATTRIBUTES

=head2 message

The error message, if JSON is passed this will be coerced to a string.

=head2 code

The error code, generally the HTTP status code.

=head2 response

The error response, generally the HTTP response.

The following attributes are populated from the error response of the Pro (v2)
API, see L<https://developer.gocardless.com/api-reference/#api-usage-errors>

=head2 type

The type of error, one of C<gocardless>, C<invalid_api_usage>, C<invalid_state>,
or C<validation_failed>.

=head2 request_id

The ID of the request, include this if you need to contact GoCardless support.

=head2 documentation_url

A link to the GoCardless documentation for the error.

=head2 errors

An arrayref of the individual errors, for C<validation_failed> errors these have
C<field> and C<message> keys, for other errors they have C<reason> and C<message>
keys (and possibly C<links>).

=cut

around BUILDARGS => sub {
    my ( $orig,$class,@args ) = @_;

    my $args = $class->$orig( @args );

    # v2 API errors are JSON, so pull out the details to allow inspection
    # of the error rather than just having it as a message string
    if (
        defined( $args->{message} )
        && ! ref( $args->{message} )
        && $args->{message} =~ /^\{/
    ) {
        my $data = eval { _decode_json( $args->{message} ) };

        if ( ref( $data ) eq 'HASH' && ref( $data->{error} ) eq 'HASH' ) {
            my $error = $data->{error};
            $args->{$_} //= $error->{$_} for qw/ type request_id documentation_url /;
            $args->{errors} //= $error->{errors};
        }
    }

    return $args;
};

# plain string or JSON
has message => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        my ( $message ) = @_;

        cluck $message if $ENV{GOCARDLESS_DEV_TESTING};

        if ( $message =~ /^[{\[]/ ) {
            # defensive decoding
            eval { $message = _decode_json( $message ) };
            $@ && do { return "Failed to parse JSON response ($message): $@"; };

            if ( ref( $message ) eq 'HASH' ) {
                my $error = delete( $message->{error} ) // "Unknown error";

                if ( ref( $error ) eq 'HASH' ) {

                    my $mess = $error->{message};

                    foreach my $sub_error ( @{ $error->{errors} // [] } ) {
                        $mess .= ' / ' . $sub_error->{message};
                    }

                    return $mess . " << $mess >> ";

                } elsif ( ref( $error ) eq 'ARRAY' ) {
                    return join( ', ',@{ $error } );
                } else {
                    return $error;
                }

            } else {
                return join( ', ',@{ $message } );
            }
        } else {
            return $message;
        }
    },
);

# generally the HTTP status code
has code => (
    is       => 'ro',
    required => 0,
);

# generally the HTTP status code + message
has response => (
    is       => 'ro',
    required => 0,
);

has [ qw/
    type
    request_id
    documentation_url
/ ] => (
    is       => 'ro',
    required => 0,
);

has errors => (
    is       => 'ro',
    required => 0,
    coerce   => sub { ref( $_[0] ) eq 'ARRAY' ? $_[0] : [] },
    default  => sub { [] },
);

# error responses are UTF-8 encoded bytes, but we may have been passed a
# message that has already been decoded. work out which it is before decoding
# so any failure to decode is reported as is, rather than retrying in the
# other mode and masking the real error. note a string of characters that is
# also valid UTF-8 (e.g. "Ã¸") is ambiguous, and treated as UTF-8 bytes
sub _decode_json {
    my ( $json ) = @_;

    my $is_utf8_bytes = $json !~ /[^\x00-\xFF]/
        && utf8::decode( my $copy = $json );

    return JSON->new->utf8( $is_utf8_bytes ? 1 : 0 )->decode( $json );
}

=head1 METHODS

=head2 description

An alias to the message attribute.

=head2 reasons

Returns a list of the C<reason> values from the L</errors>:

    my @reasons = $Exception->reasons;

=head2 has_reason

Returns true if any of the L</errors> have the given reason:

    if ( $Exception->has_reason( 'mandate_is_inactive' ) ) {
        ...
    }

=head2 conflicting_resource_id

Returns the ID of the resource already created with the idempotency key used
in the request, if the error is an C<idempotent_creation_conflict>.

=cut

# compatibility with ruby lib
sub description { shift->message }

sub reasons {
    my ( $self ) = @_;
    return map { $_->{reason} // () } @{ $self->errors };
}

sub has_reason {
    my ( $self,$reason ) = @_;
    return scalar( grep { $_ eq $reason } $self->reasons );
}

sub conflicting_resource_id {
    my ( $self ) = @_;

    foreach my $error ( @{ $self->errors } ) {
        next if ( $error->{reason} // '' ) ne 'idempotent_creation_conflict';
        return $error->{links}{conflicting_resource_id};
    }

    return;
}

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
