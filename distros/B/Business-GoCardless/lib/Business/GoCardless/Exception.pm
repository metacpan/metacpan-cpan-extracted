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

=cut

# plain string or JSON
has message => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        my ( $message ) = @_;

        cluck $message if $ENV{GOCARDLESS_DEV_TESTING};

        if ( $message =~ /^[{\[]/ ) {
            # defensive decoding
            eval { $message = JSON->new->decode( $message ) };
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

=head1 METHODS

=head2 description

An alias to the message attribute.

=cut

# compatibility with ruby lib
sub description { shift->message }

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
