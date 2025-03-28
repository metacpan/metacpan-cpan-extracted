# ABSTRACT: helper for rendering HTTP status codes for Dancer2

package Dancer2::Core::HTTP;
$Dancer2::Core::HTTP::VERSION = '1.1.2';
use strict;
use warnings;

use List::Util qw/ pairmap pairgrep /;

my $HTTP_CODES = {

    # informational
    100 => 'Continue',               # only on HTTP 1.1
    101 => 'Switching Protocols',    # only on HTTP 1.1
    102 => 'Processing',             # WebDAV; RFC 2518

    # processed
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information', # only on HTTP 1.1
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',           # WebDAV; RFC 4918
    208 => 'Already Reported',       # WebDAV; RFC 5842
    # 226 => 'IM Used'               # RFC 3229

    # redirections
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',          # only on HTTP 1.1
    304 => 'Not Modified',
    305 => 'Use Proxy',          # only on HTTP 1.1
    306 => 'Switch Proxy',
    307 => 'Temporary Redirect',     # only on HTTP 1.1
    # 308 => 'Permanent Redirect'    # approved as experimental RFC

    # problems with request
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Requested Range Not Satisfiable',
    417 => 'Expectation Failed',
    418 => "I'm a teapot",             # RFC 2324
    # 419 => 'Authentication Timeout', # not in RFC 2616
    420 => 'Enhance Your Calm',
    422 => 'Unprocessable Entity',
    423 => 'Locked',
    424 => 'Failed Dependency',        # Also used for 'Method Failure'
    425 => 'Unordered Collection',
    426 => 'Upgrade Required',
    428 => 'Precondition Required',
    429 => 'Too Many Requests',
    431 => 'Request Header Fields Too Large',
    444 => 'No Response',
    449 => 'Retry With',
    450 => 'Blocked by Windows Parental Controls',
    451 => 'Unavailable For Legal Reasons',
    494 => 'Request Header Too Large',
    495 => 'Cert Error',
    496 => 'No Cert',
    497 => 'HTTP to HTTPS',
    499 => 'Client Closed Request',

    # problems with server
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',
    507 => 'Insufficient Storage',
    508 => 'Loop Detected',
    509 => 'Bandwidth Limit Exceeded',
    510 => 'Not Extended',
    511 => 'Network Authentication Required',
    598 => 'Network read timeout error',
    599 => 'Network connect timeout error',
};

$HTTP_CODES = {
    %$HTTP_CODES,
    ( reverse %$HTTP_CODES ),
    pairmap { join( '_', split /\W/, lc $a ) => $b } reverse %$HTTP_CODES
};

$HTTP_CODES->{error} = $HTTP_CODES->{internal_server_error};

sub status {
    my ( $class, $status ) = @_;
    return if ! defined $status;
    return $status if $status =~ /^\d+$/;
    if ( exists $HTTP_CODES->{$status} ) {
        return $HTTP_CODES->{$status};
    }
    return;
}

sub status_message {
    my ( $class, $status ) = @_;
    return if ! defined $status;
    my $code = $class->status($status);
    return if ! defined $code || ! exists $HTTP_CODES->{$code};
    return $HTTP_CODES->{ $code };
}

sub status_mapping {
    pairgrep { $b =~ /^\d+$/ and $a !~ /_/ } %$HTTP_CODES;
}

sub code_mapping {
    my @result = reverse status_mapping();
    return @result;
}

sub all_mappings { %$HTTP_CODES }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Core::HTTP - helper for rendering HTTP status codes for Dancer2

=head1 VERSION

version 1.1.2

=head1 FUNCTIONS

=head2 status(status_code)

    Dancer2::Core::HTTP->status(200); # returns 200

    Dancer2::Core::HTTP->status('Not Found'); # returns 404

    Dancer2::Core::HTTP->status('bad_request'); # 400

Returns a HTTP status code.  If given an integer, it will return the value it
received, else it will try to find the appropriate alias and return the correct
status.

=head2 status_message(status_code)

    Dancer2::Core::HTTP->status_message(200); # returns 'OK'

    Dancer2::Core::HTTP->status_message('error'); # returns 'Internal Server Error'

Returns the HTTP status message for the given status code.

=head2 status_mapping()

    my %table = Dancer2::Core::HTTP->status_mapping;
    # returns ( 'Ok' => 200, 'Created' => 201, ... )

Returns the full table of status -> code mappings.

=head2 code_mapping()

    my %table = Dancer2::Core::HTTP->code_mapping;
    # returns ( 200 => 'Ok', 201 => 'Created', ... )

Returns the full table of code -> status mappings.

=head2 all_mappings()

    my %table = Dancer2::Core::HTTP->all_mappings;
    # returns ( 418 => 'I'm a teapot', "I'm a teapot' => 418, 'i_m_a_teapot' => 418 )

Returns the code-to-status, status-to-code and underscore-groomed status-to-code mappings
all mashed up in a single table. Mostly for internal uses.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
