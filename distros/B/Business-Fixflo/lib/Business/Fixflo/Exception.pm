package Business::Fixflo::Exception;

=head1 NAME

Business::Fixflo::Exception

=head1 DESCRIPTION

Exception handling for the Business::Fixflo modules, uses the Throwable
module.

=cut

use strict;
use warnings;

use Moo;
use JSON ();
use Carp qw/ cluck /;

with 'Throwable';

=head1 ATTRIBUTES

=head2 message (required)

The error message, if JSON is passed this will be coerced to a string.

=head2 code (optional)

The error code, generally the HTTP status code.

=head2 response (optional)

The error response, generally the HTTP response.

=head2 request (optional)

The original HTTP request data including path, params, content, and headers.
You should be careful if you write this data to a file as it may contain
sensitive information such as API key(s).

=cut

# plain string or JSON
has message => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        my ( $message ) = @_;

        cluck $message if $ENV{FIXFLO_DEBUG};

        if ( $message =~ /^[{\[]/ ) {
            # defensive decoding
            eval { $message = JSON->new->decode( $message ) };
            $@ && do { return "Failed to parse JSON response ($message): $@"; };

            if ( ref( $message ) eq 'HASH' ) {
                my $error = delete( $message->{Message} ) // "Unknown error";
                return ref( $error ) ? join( ', ',@{ $error } ) : $error;
            } else {
                return join( ', ',@{ $message } );
            }
        } else {
            return $message;
        }
    },
);

# HTTP status code, response, request
has [ qw/ code response / ] => (
    is       => 'ro',
    required => 0,
);

has [ qw/ request / ] => (
    is       => 'ro',
    required => 0,
    default  => sub { $Business::Fixflo::Client::request_data || undef },
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

    https://github.com/Humanstate/business-fixflo

=cut

1;

# vim: ts=4:sw=4:et
