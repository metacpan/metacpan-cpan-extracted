package Test::Apache2::API::Response;
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use parent qw( Test::Apache2::Common );
    use Apache2::Connection ();
    use Apache2::Const -compile => qw( :common :http OK DECLINED );
    use Apache2::RequestIO ();
    use Apache2::RequestRec ();
    # so we can get the request as a string
    use Apache2::RequestUtil ();
    use APR::URI ();
    use Apache2::API;
    use Scalar::Util;
    # 2021-11-1T17:12:10+0900
    use Test::Time time => 1635754330;
    use constant HAS_SSL => ( $ENV{HTTPS} || ( defined( $ENV{SCRIPT_URI} ) && substr( lc( $ENV{SCRIPT_URI} ), 0, 5 ) eq 'https' ) ) ? 1 : 0;
};

use strict;
use warnings;

# allow_credentials
# allow_headers
# allow_methods
# allow_origin
# alt_svc
# bytes_sent
# cache_control
# clear_site_data

sub connection { return( shift->_test({ method => 'connection', expect => 'Apache2::Connection', type => 'isa' }) ); }

# code
# content_disposition
# content_encoding
# content_language
# content_languages
# content_length
# content_location
# content_range
# content_security_policy
# content_security_policy_report_only
# cookie_new
# cookie_replace
# cookie_set
# cross_origin_embedder_policy
# cross_origin_opener_policy
# cross_origin_resource_policy
# cspro
# custom_response
# decode
# digest
# encode
# env
# err_headers
# err_headers_out
# escape
# etag
# expires
# expose_headers
# flush
# get_http_message
# get_status_line

sub headers { return( shift->_test({ method => 'headers', expect => 'APR::Table', type => 'isa' }) ); }

sub headers_out { return( shift->_test({ method => 'headers_out', expect => 'APR::Table', type => 'isa' }) ); }

# internal_redirect
# internal_redirect_handler
# is_info
# is_success
# is_redirect
# is_error
# is_client_error
# is_server_error
# keep_alive
# last_modified
# last_modified_date
# location
# lookup_uri

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag>
sub make_etag { return( shift->_test({ method => 'make_etag', expect => sub
{
    my $val = shift( @_ );
    # "5fd7520368c40"
    return(0) if( !defined( $val ) || !length( $val ) );
    return( $val =~ /^(?:W\/)?\"[a-zA-Z0-9]+\"$/ );
} }) ); }

# max_age
# meets_conditions
# nel
# no_cache

sub no_cache { return( shift->_test({ method => 'no_cache', expect => 0, type => 'boolean' }) ); }

sub no_local_copy { return( shift->_test({ method => 'no_local_copy', expect => 0, type => 'boolean' }) ); }

# print
# printf
# puts
# redirect
# referrer_policy
# request
# retry_after
# rflush
# send_cgi_header

sub sendfile { return( shift->_test({ method => 'sendfile', expect => APR::Const::SUCCESS, args => [__FILE__] }) ); }

# server
# server_timing
# set_content_length
# set_cookie
# set_etag
# set_keepalive

# 2021-11-1T167:12:10+0900
sub set_last_modified { return( shift->_test({ method => 'set_last_modified', expect => sub
{
    return(1);
}, args => [1635754330] }) ); }

sub socket { return( shift->_test({ method => 'socket', expect => 'APR::Socket', type => 'isa' }) ); }

# sourcemap
# status
# status_line
# strict_transport_security
# subprocess_env
# timing_allow_origin
# trailer
# transfer_encoding
# unescape
# upgrade
# update_mtime
# uri_escape
# uri_unescape
# url_decode
# url_encode
# vary
# via
# want_digest
# warning
# write
# www_authenticate
# x_content_type_options
# x_dns_prefetch_control
# x_frame_options
# x_xss_protection

sub _target { return( shift->api->response ); }

1;
# NOTE: POD
# Use this to generate the tests list:
# egrep -E '^sub ' ./t/lib/Test/Apache2/API/Response.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "=head2 $m\n"'
__END__

=encoding utf8

=head1 NAME

Test::Apache2::API::Response - Apache2::API::Response Testing Class

=head1 SYNOPSIS

    my $hostport = Apache::TestRequest::hostport( $config ) || '';
    my( $host, $port ) = split( ':', ( $hostport ) );
    my $mp_host = 'www.example.org';
    Apache::TestRequest::user_agent(reset => 1, keep_alive => 1 );
    my $ua = Apache::TestRequest->new;
    # To get the fingerprint for the certificate in ./t/server.crt, do:
    # echo "sha1\$$(openssl x509 -noout -in ./t/server.crt -fingerprint -sha1|perl -pE 's/^.*Fingerprint=|(\w{2})(?:\:?|$)/$1/g')"
    $ua->ssl_opts(
        # SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, 
        # SSL_verify_mode => 0x00
        # verify_hostname => 0,
        SSL_fingerprint => 'sha1$DEE8650E44870896E821AAE4A5A24382174D100E',
        # SSL_version     => 'SSLv3',
        # SSL_verfifycn_name => 'localhost',
    );
    my $req = HTTP::Request->new( 'GET' => "${proto}://${hostport}/tests/response/some_method" );
    my $resp = $ua->request( $req );
    is( $resp->code, Apache2::Const::HTTP_OK, 'some test name' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a package for testing the L<Apache2::API> module under Apache2/modperl2 and inherits from C<Test::Apache::Common>

=head1 TESTS

=head2 connection

=head2 headers

=head2 headers_out

=head2 make_etag

=head2 no_cache

=head2 no_local_copy

=head2 sendfile

=head2 set_last_modified

=head2 socket

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API>, L<Apache::Test>, L<Apache::TestUtil>, L<Apache::TestRequest>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
