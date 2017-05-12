package Business::CPI::Role::Exception;
# ABSTRACT: Exceptions from the gateway
use Moo::Role;
use Types::Standard qw/Int Str HashRef/;
use Business::CPI::Util::Types qw/ExceptionType/;
with 'Throwable';

our $VERSION = '0.924'; # VERSION

has type => (
    coerce   => ExceptionType->coercion,
    isa      => ExceptionType,
    is       => 'ro',
    required => 1,
);

has message => (
    isa      => Str,
    is       => 'ro',
    required => 1,
);

has gateway_data => (
    isa      => HashRef,
    is       => 'ro',
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Role::Exception - Exceptions from the gateway

=head1 VERSION

version 0.924

=head1 DESCRIPTION

This role is meant to be used by the drivers to encapsulate gateway exceptions,
put them in the required format, and rethrowing them as real Perl exceptions
(using L<Throwable>).

=head1 ATTRIBUTES

=head2 type

The type is a string, that will contain one of the predefined values mentioned
below. The examples will refer to HTTP Status, but the exceptions are not
limited to HTTP errors. The gateway API doesn't need to be RESTful.

=over 4

=item invalid_data

Part or all of the data provided to the gateway was not valid. Example: the
buyer name contained numbers.

=item incomplete_data

The data sent to the gateway was not complete. Example: the buyer name was
missing.

=item invalid_request

The request could not be made because it's formatted in a way the gateway did
not expect. Most likely this is due to an error in the Business::CPI driver.

Example: the gateway responded with HTTP status 405, 406, 417, etc, supposing a
RESTful API.

=item resource_not_found

Some item in the request references an item which was not found in the gateway,
or the request returns HTTP status 404.

=item unauthorized

The API user is not authorized to make this request (HTTP Status 403).

=item unauthenticated

The API user is not properly authenticated (HTTP Status 401).

=item duplicate_transaction

The transaction has already been executed. Example: a shopping cart which has
already been payed, or a refund that has already been requested.

The gateway API could respond HTTP 200 OK, but it's not always the case. When
it responds with error, and this is the reason, the type will be
duplicate_transaction.

=item rejected

Some business logic in the gateway determined that this request could not be
completed. Example: requesting a refund of a payment which is still processing.
That is, the payment exists (not L</resource_not_found>), the request is valid,
the data is complete and valid, but it cannot be fulfilled.

=item gateway_unavailable

The gateway API responded with one of the following HTTP Status, for example:
408, 502, 503 or 504. That is, either a timeout occurred, or the server
reported to be unavailable.

=item gateway_error

There was an internal server error in the gateway.

=item unknown

The gateway threw some kind of exception that Business::CPI was unable to
parse.

=back

=head2 message

A human readable message of the error, preferably in English, either generated
by L<Business::CPI>, the driver, or the gateway. This serves only for debuging
purposes, and not for your code to parse this and handle the exception.

=head2 gateway_data

Plain HashRef (i.e., not blessed) containing any extra data regarding the
exception that might be useful. For example:

    {
        raw_lwp_request    => $req, # $res->isa('HTTP::Request')
        raw_lwp_response   => $res, # $res->isa('HTTP::Response')
        http_status_code   => 400,
        error_code         => 'XM-231',
        message            => 'That currency is currently not supported',
        context            => 'currency',
        exception_id       => 'e171eadad51791966aad6ac10bb6d16354d1952',
    }

That HashRef is supposed to be non-standard, as a way of keeping information
that is only relevant to certain gateways. Although some things might be
standardized, such as the LWP request and response, for instance. Again, this
is still being designed.

=head1 DISCLAIMER

This is very B<EXPERIMENTAL>. We're still designing the interface, and the
error codes are not defined yet. This role will not be usable before the
documentation of all error codes.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
