#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
#     use_ok( 'Apache2::API::Status', 'all' );
    use ok( 'Apache2::API::Status', qw( :all ) );
};

my $s = Apache2::API::Status->new;
isa_ok( $s => 'Apache2::API::Status' );

# for m in `egrep -E '^sub ([a-z]\w+)' ./lib/Apache2/API/Status.pm| awk '{ print $2 }'`; do echo "can_ok( \$s => '$m' );"; done
# or
# egrep -E '^sub ' ./lib/Apache2/API/Status.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$s, ''$m'' );"'
# perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$s, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/Apache2/API/Status.pm
can_ok( $s, 'convert_short_lang_to_long' );
can_ok( $s, 'is_info' );
can_ok( $s, 'is_success' );
can_ok( $s, 'is_redirect' );
can_ok( $s, 'is_error' );
can_ok( $s, 'is_client_error' );
can_ok( $s, 'is_server_error' );
can_ok( $s, 'status_message' );
can_ok( $s, 'supported_languages' );

subtest 'constants' => sub
{
    my $constants = [
        'HTTP_CONTINUE'                           => 100,
        'HTTP_SWITCHING_PROTOCOLS'                => 101,
        'HTTP_PROCESSING'                         => 102,
        'HTTP_EARLY_HINTS'                        => 103,
        'HTTP_OK'                                 => 200,
        'HTTP_CREATED'                            => 201,
        'HTTP_ACCEPTED'                           => 202,
        'HTTP_NON_AUTHORITATIVE'                  => 203,
        'HTTP_NO_CONTENT'                         => 204,
        'HTTP_RESET_CONTENT'                      => 205,
        'HTTP_PARTIAL_CONTENT'                    => 206,
        'HTTP_MULTI_STATUS'                       => 207,
        'HTTP_ALREADY_REPORTED'                   => 208,
        'HTTP_IM_USED'                            => 226,
        'HTTP_MULTIPLE_CHOICES'                   => 300,
        'HTTP_MOVED_PERMANENTLY'                  => 301,
        'HTTP_MOVED_TEMPORARILY'                  => 302,
        'HTTP_SEE_OTHER'                          => 303,
        'HTTP_NOT_MODIFIED'                       => 304,
        'HTTP_USE_PROXY'                          => 305,
        'HTTP_TEMPORARY_REDIRECT'                 => 307,
        'HTTP_PERMANENT_REDIRECT'                 => 308,
        'HTTP_BAD_REQUEST'                        => 400,
        'HTTP_UNAUTHORIZED'                       => 401,
        'HTTP_PAYMENT_REQUIRED'                   => 402,
        'HTTP_FORBIDDEN'                          => 403,
        'HTTP_NOT_FOUND'                          => 404,
        'HTTP_METHOD_NOT_ALLOWED'                 => 405,
        'HTTP_NOT_ACCEPTABLE'                     => 406,
        'HTTP_PROXY_AUTHENTICATION_REQUIRED'      => 407,
        'HTTP_REQUEST_TIME_OUT'                   => 408,
        'HTTP_CONFLICT'                           => 409,
        'HTTP_GONE'                               => 410,
        'HTTP_LENGTH_REQUIRED'                    => 411,
        'HTTP_PRECONDITION_FAILED'                => 412,
        'HTTP_REQUEST_ENTITY_TOO_LARGE'           => 413,
        'HTTP_REQUEST_URI_TOO_LARGE'              => 414,
        'HTTP_UNSUPPORTED_MEDIA_TYPE'             => 415,
        'HTTP_RANGE_NOT_SATISFIABLE'              => 416,
        'HTTP_EXPECTATION_FAILED'                 => 417,
        'HTTP_I_AM_A_TEA_POT'                     => 418,
        'HTTP_MISDIRECTED_REQUEST'                => 421,
        'HTTP_UNPROCESSABLE_ENTITY'               => 422,
        'HTTP_LOCKED'                             => 423,
        'HTTP_FAILED_DEPENDENCY'                  => 424,
        'HTTP_TOO_EARLY'                          => 425,
        'HTTP_UPGRADE_REQUIRED'                   => 426,
        'HTTP_PRECONDITION_REQUIRED'              => 428,
        'HTTP_TOO_MANY_REQUESTS'                  => 429,
        'HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE'    => 431,
        'HTTP_CONNECTION_CLOSED_WITHOUT_RESPONSE' => 444,
        'HTTP_UNAVAILABLE_FOR_LEGAL_REASONS'      => 451,
        'HTTP_CLIENT_CLOSED_REQUEST'              => 499,
        'HTTP_INTERNAL_SERVER_ERROR'              => 500,
        'HTTP_NOT_IMPLEMENTED'                    => 501,
        'HTTP_BAD_GATEWAY'                        => 502,
        'HTTP_SERVICE_UNAVAILABLE'                => 503,
        'HTTP_GATEWAY_TIME_OUT'                   => 504,
        'HTTP_VERSION_NOT_SUPPORTED'              => 505,
        'HTTP_VARIANT_ALSO_VARIES'                => 506,
        'HTTP_INSUFFICIENT_STORAGE'               => 507,
        'HTTP_LOOP_DETECTED'                      => 508,
        'HTTP_BANDWIDTH_LIMIT_EXCEEDED'           => 509,
        'HTTP_NOT_EXTENDED'                       => 510,
        'HTTP_NETWORK_AUTHENTICATION_REQUIRED'    => 511,
        'HTTP_NETWORK_CONNECT_TIMEOUT_ERROR'      => 599,
    ];

    for( my $i = 0; $i < scalar( @$constants ); $i += 2 )
    {
        my $const = $constants->[$i];
        my $value = $constants->[$i + 1];
        no strict 'refs';
        ok( defined( &$const ), "constant $const defined" );
        if( defined( &$const ) )
        {
            is( &$const, $value, "constant $const value" );
        }
        else
        {
            fail( "constant $const value" );
        }
    }
};


is( HTTP_OK, 200 );

ok( $s->is_info( HTTP_CONTINUE ), 'is_info' );
ok( $s->is_success( HTTP_ACCEPTED ), 'is_success' );
ok( $s->is_error( HTTP_BAD_REQUEST ), 'is_error' );
diag( "Checking is HTTP_I_AM_A_TEAPOT (", HTTP_I_AM_A_TEAPOT, ") is a client error" ) if( $DEBUG );
ok( $s->is_client_error( HTTP_I_AM_A_TEAPOT ), 'is_client_error' );
ok( $s->is_redirect( HTTP_MOVED_PERMANENTLY ), 'is_redirect' );
ok( $s->is_redirect( HTTP_PERMANENT_REDIRECT ), 'is_redirect' );

# renamed status constants
ok( $s->is_error( HTTP_REQUEST_ENTITY_TOO_LARGE ), 'is_error' );
ok( $s->is_error( HTTP_PAYLOAD_TOO_LARGE ), 'is_error' );
ok( $s->is_error( HTTP_REQUEST_URI_TOO_LARGE ), 'is_error' );
ok( $s->is_error( HTTP_URI_TOO_LONG ), 'is_error' );
ok( $s->is_error( HTTP_REQUEST_RANGE_NOT_SATISFIABLE ), 'is_error' );
ok( $s->is_error( HTTP_RANGE_NOT_SATISFIABLE ), 'is_error' );
ok( $s->is_error( HTTP_NO_CODE ), 'is_error' );
ok( $s->is_error( HTTP_UNORDERED_COLLECTION ), 'is_error' );
ok( Apache2::API::Status->is_error( HTTP_TOO_EARLY ), 'is_error' );

ok( !$s->is_success( HTTP_NOT_FOUND ), 'is_success' );

is( $s->status_message(0), undef, 'status_message' );
is( $s->status_message(200), 'OK', 'status_message' );
is( $s->status_message(404), 'Object not found!', 'status_message' );
is( $s->status_message(999), undef, 'status_message' );


ok( !$s->is_info( HTTP_NOT_FOUND ), 'is_info' );
ok( !$s->is_success( HTTP_NOT_FOUND ), 'is_success' );
ok( !$s->is_redirect( HTTP_NOT_FOUND ), 'is_redirect' );
ok( !$s->is_error( HTTP_CONTINUE ), 'is_error' );
ok( !$s->is_client_error( HTTP_CONTINUE ), 'is_client_error' );
ok( !$s->is_server_error( HTTP_NOT_FOUND ), 'is_server_error' );
ok( !$s->is_server_error(999), 'is_server_error' );
ok( !$s->is_info(99), 'is_info' );
ok( !$s->is_success(99), 'is_success' );
ok( !$s->is_redirect(99), 'is_redirect' );

ok( $s->is_cacheable_by_default( $_ ),
  "Cacheable by default [$_] " . $s->status_message( $_ )
) for( 200, 203, 204, 206, 300, 301, 308, 404, 405, 410, 414, 451, 501 );

ok( !$s->is_cacheable_by_default( $_ ),
  "... is not cacheable [$_] " . $s->status_message( $_ )
) for( 100, 201, 302, 400, 500 );

done_testing();

__END__

