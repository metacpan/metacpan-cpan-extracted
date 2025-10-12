# -*- perl -*-
##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API/Response.pm
## Version v0.1.3
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/05/30
## Modified 2025/10/03
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::API::Response;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    use Apache2::Request;
    use Apache2::Const -compile => qw( :common :http );
    use Apache2::Log ();
    use Apache2::Response ();
    use Apache2::RequestIO ();
    use Apache2::RequestRec ();
    use Apache2::SubRequest ();
    use APR::Request ();
    # use APR::Request::Cookie;
    use Apache2::API::Status;
    use Cookie::Jar;
    use Scalar::Util;
    use URI::Escape ();
    our $VERSION = 'v0.1.3';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $r;
    $r = shift( @_ ) if( @_ % 2 );
    # Which is an Apache2::Request, but inherits everything from Apache2::RequestRec and APR::Request::Apache2
    $self->{request} = '';
    $self->{checkonly} = 0;
    $self->SUPER::init( @_ );
    $r ||= $self->{request};
    unless( $self->{checkonly} )
    {
        return( $self->error( "No Apache2::API::Request was provided." ) ) if( !$r );
        return( $self->error( "Apache2::API::Request provided ($r) is not an object!" ) ) if( !Scalar::Util::blessed( $r ) );
        return( $self->error( "I was expecting an Apache2::API::Request, but instead I got \"$r\"." ) ) if( !$r->isa( 'Apache2::API::Request' ) );
    }
    return( $self );
}

# Response header: <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials>
sub allow_credentials { return( shift->_set_get_one( 'Access-Control-Allow-Credentials', @_ ) ); }

# Response header <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers>
sub allow_headers { return( shift->_set_get_one( 'Access-Control-Allow-Headers', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods>
sub allow_methods { return( shift->_set_get_one( 'Access-Control-Allow-Methods', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin>
sub allow_origin { return( shift->_set_get_one( 'Access-Control-Allow-Origin', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Alt-Svc>
sub alt_svc { return( shift->_set_get_multi( 'Alt-Svc', @_ ) ); }

sub bytes_sent { return( shift->_try( '_request', 'bytes_sent' ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control>
sub cache_control { return( shift->_set_get_one( 'Cache-Control', @_ ) ); }

sub call { return( shift->_try( 'request', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data>
sub clear_site_data { return( shift->_set_get_multi( 'Clear-Site-Data', @_ ) ); }

# Apache2::Connection
sub connection { return( shift->_try( '_request', 'connection' ) ); }

# Set the http code to be returned, e.g,:
# return( $resp->code( Apache2::Const:HTTP_OK ) );
sub code { return( shift->_try( '_request', 'status', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>
# TODO: More work to be done here like create a disposition method to parse its content
sub content_disposition { return( shift->_set_get_one( 'Content-Disposition', @_ ) ); }

# sub content_encoding { return( shift->_request->content_encoding( @_ ) ); }
sub content_encoding
{
    my $self = shift( @_ );
    my( $pack, $file, $line ) = caller;
    my $sub = ( caller( 1 ) )[3];
    # try-catch
    local $@;
    my $rv = eval
    {
        return( $self->_request->content_encoding( @_ ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to access Apache Request method \"content_encoding\": $@" ) );
    }
    return( $rv );
}

# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Language
sub content_language { return( shift->headers( 'Content-Language', @_ ) ); }

sub content_languages { return( shift->_try( '_request', 'content_languages', @_ ) ); }

# sub content_length { return( shift->headers( 'Content-Length', @_ ) ); }
# https://perl.apache.org/docs/2.0/api/Apache2/Response.html#toc_C_set_content_length_
sub content_length { return( shift->_try( '_request', 'set_content_length', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Location>
sub content_location { return( shift->_set_get_one( 'Content-Location', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Range>
sub content_range { return( shift->_set_get_one( 'Content-Range', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy>
sub content_security_policy { return( shift->_set_get_one( 'Content-Security-Policy', @_ ) ); }

sub content_security_policy_report_only { return( shift->_set_get_one( 'Content-Security-Policy-Report-Only', @_ ) ); }

# Apache content_type method is special. It does not just set the content type
sub content_type { return( shift->_try( '_request', 'content_type', @_ ) ); }
# sub content_type { return( shift->headers( 'Content-Type', @_ ) ); }

sub cookie_new
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Cookie name was not provided." ) ) if( !$opts->{name} );
    # No value is ok to remove a cookie, but it needs to be an empty string, not undef
    # return( $self->error( "No value was provided for cookie \"$opts->{name}\"." ) ) if( !length( $opts->{value} ) && !defined( $opts->{value} ) );
    my $c = $self->request->cookies->make( $opts ) || return( $self->pass_error( $self->request->cookies->error ) );
    return( $c );
}

# Add or replace a cookie, but because the headers function of Apache2 is based on APR::Table
# there is no replace method, AND because the value of the headers is a string and not an object
# we have to crawl each already set cookie, parse them, compare them en replace them or add them
sub cookie_replace
{
    my $self = shift( @_ );
    my $cookie = shift( @_ ) || return( $self->error( "No cookie to add to outgoing headers was provided." ) );
    # Expecting an APR::Request::Cookie object
    return( $self->error( "Cookie provided (", ref( $cookie ), ") is not an object." ) ) if( !Scalar::Util::blessed( $cookie ) );
    return( $self->error( "Cookie object provided (", ref( $cookie ), ") does not seem to have an \"as_string\" method." ) ) if( !$cookie->can( 'as_string' ) );
    # We use err_headers_out() which makes it also possible to set cookies upon error (regular headers_out method cannot)
    my( @cookie_headers ) = $self->err_headers->get( 'Set-Cookie' );
    if( !scalar( @cookie_headers ) )
    {
        $self->err_headers->set( 'Set-Cookie' => $cookie->as_string );
    }
    else
    {
        my $jar = Cookie::Jar->new;
        # Check each cookie header set to see if ours is one of them
        my $found = 0;
        for( my $i = 0; $i < scalar( @cookie_headers ); $i++ )
        {
            my $c = $jar->extract_one( $cookie_headers[ $i ] ) || do
            {
                warn( "Error parsing cookie string '", $cookie_headers[ $i ], "': ", $jar->error, "\n" ) if( $self->_is_warnings_enabled( 'Apache2::API' ) );
                next;
            };
            
            if( $c->name eq $cookie->name )
            {
                $cookie_headers[ $i ] = $cookie->as_string;
                $found = 1;
            }
        }
        if( !$found )
        {
            $self->err_headers->add( 'Set-Cookie' => $cookie->as_string );
        }
        else
        {
            # Remove all Set-Cookie headers
            $self->err_headers->unset( 'Set-Cookie' );
            # Now, re-add our updated set
            foreach my $cookie_str ( @cookie_headers )
            {
                $self->err_headers->add( 'Set-Cookie' => $cookie_str );
            }
        }
    }
    return( $cookie );
}

sub cookie_set
{
    my $self = shift( @_ );
    my $cookie = shift( @_ ) || return( $self->error( "No cookie to add to outgoing headers was provided." ) );
    # Expecting an APR::Request::Cookie object
    return( $self->error( "Cookie provided (", ref( $cookie ), ") is not an object." ) ) if( !Scalar::Util::blessed( $cookie ) );
    return( $self->error( "Cookie object provided (", ref( $cookie ), ") does not seem to have an \"as_string\" method." ) ) if( !$cookie->can( 'as_string' ) );
    $self->err_headers->set( 'Set-Cookie' => $cookie->as_string );
    return( $cookie );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Embedder-Policy>
sub cross_origin_embedder_policy { return( shift->_set_get_one( 'Cross-Origin-Embedder-Policy', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Opener-Policy>
sub cross_origin_opener_policy { return( shift->_set_get_one( 'Cross-Origin-Opener-Policy', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Resource-Policy>
sub cross_origin_resource_policy { return( shift->_set_get_one( 'Cross-Origin-Resource-Policy', @_ ) ); }

sub cspro { return( shift->content_security_policy_report_only( @_ ) ); }

# e.g. custom_response( $status, $string );
# e.g. custom_response( Apache2::Const::AUTH_REQUIRED, "Authenticate please" );
#  package MyApache2::MyShop;
#  use Apache2::Response ();
#  use Apache2::Const -compile => qw(FORBIDDEN OK);
#  sub access {
#    my $r = shift;
# 
#    if (MyApache2::MyShop::tired_squirrels()) {
#        $r->custom_response(Apache2::Const::FORBIDDEN,
#            "It is siesta time, please try later");
#        return Apache2::Const::FORBIDDEN;
#    }
# 
#    return Apache2::Const::OK;
#  }
sub custom_response { return( shift->_try( '_request', 'custom_response', @_ ) ); }

sub decode
{
    my $self = shift( @_ );
    return( APR::Request::decode( shift( @_ ) ) );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Digest>
sub digest { return( shift->_set_get_one( 'Digest', @_ ) ); }

sub encode
{
    my $self = shift( @_ );
    return( APR::Request::encode( shift( @_ ) ) );
}

sub env
{
    my $self = shift( @_ );
    my $r = $self->request;
    if( @_ )
    {
        if( scalar( @_ ) == 1 )
        {
            my $v = shift( @_ );
            if( ref( $v ) eq 'HASH' )
            {
                foreach my $k ( sort( keys( %$v ) ) )
                {
                    $r->subprocess_env( $k => $v->{ $k } );
                }
            }
            else
            {
                return( $r->subprocess_env( $v ) );
            }
        }
        else
        {
            my $hash = { @_ };
            foreach my $k ( sort( keys( %$hash ) ) )
            {
                $r->subprocess_env( $k => $hash->{ $k } );
            }
        }
    }
    else
    {
        $r->subprocess_env;
    }
}

sub err_headers { return( shift->_headers( 'err_headers_out', @_ ) ); }

sub err_headers_out { return( shift->_headers( 'err_headers_out', @_ ) ); }

sub escape { return( URI::Escape::uri_escape( @_ ) ); }

sub etag { return( shift->headers( 'ETag', @_ ) ); }
# <https://perl.apache.org/docs/2.0/api/Apache2/Response.html#toc_C_set_etag_>
# sub etag { return( shift->_try( '_request', 'set_etag', @_ ) ); }

sub expires { return( shift->headers( 'Expires', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers>
# e.g.: Access-Control-Expose-Headers: Content-Encoding, X-Kuma-Revision
sub expose_headers { return( shift->_set_get_multi( 'Access-Control-Expose-Headers', @_ ) ); }

sub flush { return( shift->_try( '_request', 'rflush' ) ); }

# sub get_http_message
# {
#   my $self = shift( @_ );
#   my $code = shift( @_ ) || return;
#   my $formal_msg = $self->get_status_line( $code );
#   $formal_msg =~ s/^(\d{3})[[:blank:]]+//;
#   return( $formal_msg );
# }
sub get_http_message { return( Apache2::API::Status->status_message( $_[1], $_[2] ) ); }

sub get_status_line { return( shift->_try( '_request', 'status_line', @_ ) ); }

sub header
{
    my $self = shift( @_ );
    return( $self->error( "No header field name was provided to retrieve its value." ) ) if( !scalar( @_ ) );
    my $field = shift( @_ );
    my $hdrs = $self->headers || return( $self->pass_error );
    if( scalar( @_ ) > 1 )
    {
        return( $hdrs->set( "$field" => @_ ) );
    }
    else
    {
        return( $hdrs->get( "$field" ) );
    }
}

sub headers { return( shift->_headers( 'err_headers_out', @_ ) ); }

sub headers_out { return( shift->_headers( 'headers_out', @_ ) ); }

# <https://perl.apache.org/docs/2.0/api/Apache2/SubRequest.html#toc_C_internal_redirect_>
sub internal_redirect
{
    my $self = shift( @_ );
    my $uri = shift( @_ );
    $uri = $uri->path if( Scalar::Util::blessed( $uri ) && $uri->isa( 'URI' ) );
    # try-catch
    local $@;
    eval
    {
        $self->_request->internal_redirect( $uri );
    };
    if( $@ )
    {
        $self->error( "An error occurred while trying to call Apache Request method \"internal_redirect\": $@" );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    return( Apache2::Const::HTTP_OK );
}

# <https://perl.apache.org/docs/2.0/api/Apache2/SubRequest.html#toc_C_internal_redirect_handler_>
sub internal_redirect_handler
{
    my $self = shift( @_ );
    my $uri = shift( @_ );
    $uri = $uri->path if( Scalar::Util::blessed( $uri ) && $uri->isa( 'URI' ) );
    # try-catch
    local $@;
    eval
    {
        $self->_request->internal_redirect_handler( $uri );
    };
    if( $@ )
    {
        $self->error( "An error occurred while trying to call Apache Request method \"internal_redirect_handler\": $@" );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    return( Apache2::Const::HTTP_OK );
}

sub is_info         { return( Apache2::API::Status->is_info( $_[1] ) ); }

sub is_success      { return( Apache2::API::Status->is_success( $_[1] ) ); }

sub is_redirect     { return( Apache2::API::Status->is_redirect( $_[1] ) ); }

sub is_error        { return( Apache2::API::Status->is_error( $_[1] ) ); }

sub is_client_error { return( Apache2::API::Status->is_client_error( $_[1] ) ); }

sub is_server_error { return( Apache2::API::Status->is_server_error( $_[1] ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Keep-Alive>
sub keep_alive { return( shift->_set_get_one( 'Keep-Alive', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified>
sub last_modified { return( shift->_set_get_one( 'Last-Modified', @_ ) ); }

sub last_modified_date { return( shift->headers( 'Last-Modified-Date', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location>
sub location { return( shift->_set_get_one( 'Location', @_ ) ); }

# <https://perl.apache.org/docs/2.0/api/Apache2/SubRequest.html#toc_C_run_>
sub lookup_uri
{
    my $self = shift( @_ );
    my $uri = shift( @_ );
    $uri = $uri->path if( Scalar::Util::blessed( $uri ) && $uri->isa( 'URI' ) );
    # try-catch
    local $@;
    my $rv = eval
    {
        my $subr = $self->_request->lookup_uri( $uri, @_ );
        # Returns Apache2::Const::OK, Apache2::Const::DECLINED, etc.
        return( $subr->run );
    };
    if( $@ )
    {
        $self->error( "An error occurred while trying to call Apache Request method \"internal_redirect_handler\": $@" );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    return( $rv );
}

# make_etag( $force_weak )
# <https://perl.apache.org/docs/2.0/api/Apache2/Response.html#C_make_etag_>
sub make_etag { return( shift->_try( '_request', 'make_etag', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age>
sub max_age { return( shift->_set_get_number( 'Access-Control-Max-Age', @_ ) ); }

sub meets_conditions { return( shift->_try( '_request', 'meets_conditions' ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/NEL>
sub nel { return( shift->_set_get_one( 'NEL', @_ ) ); }

# This adds the following to the outgoing headers:
# Pragma: no-cache
# Cache-control: no-cache
sub no_cache { return( shift->_try( '_request', 'no_cache', @_ ) ); }

sub no_local_copy { return( shift->_try( '_request', 'no_local_copy', @_ ) ); }

sub print { return( shift->_try( '_request', 'print', @_ ) ); }

sub printf { return( shift->_try( '_request', 'printf', @_ ) ); }

sub puts { return( shift->_try( '_request', 'puts', @_ ) ); }

sub redirect
{
    my $self = shift( @_ );
    # I have to die if nothing was provided, because our return value is the http code. We can't just return undef()
    my $uri = shift( @_ ) || die( "No uri provided to redirect\n" );
    # Stringify
    $self->headers->set( 'Location' => "$uri" );
    $self->code( Apache2::Const::HTTP_MOVED_TEMPORARILY );
    return( Apache2::Const::HTTP_MOVED_TEMPORARILY );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy>
sub referrer_policy { return( shift->_set_get_one( 'Referrer-Policy', @_ ) ); }

sub request { return( shift->_set_get_object( 'request', 'Apache2::API::Request', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After>
sub retry_after { return( shift->_set_get_one( 'Retry-After', @_ ) ); }

sub rflush { return( shift->_try( '_request', 'rflush' ) ); }

# e.g. send_cgi_header( $buffer )
sub send_cgi_header { return( shift->_try( '_request', 'send_cgi_header', @_ ) ); }

# e.g. sendfile( $filename );
# sendfile( $filename, $offset );
# sendfile( $filename, $offset, $len );
sub sendfile { return( shift->_try( '_request', 'sendfile', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server>
sub server { return( shift->_set_get_one( 'Server', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server-Timing>
sub server_timing { return( shift->_set_get_one( 'Server-Timing', @_ ) ); }

# e.g set_content_length( 1024 )
sub set_content_length { return( shift->_try( '_request', 'set_content_length', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>
sub set_cookie { return( shift->_set_get_one( 'Set-Cookie', @_ ) ); }

sub set_etag { return( shift->_try( '_request', 'set_etag', @_ ) ); }

sub set_keepalive { return( shift->_try( '_request', 'set_keepalive', @_ ) ); }

# <https://perl.apache.org/docs/2.0/api/Apache2/Response.html#toc_C_set_last_modified_>
sub set_last_modified { return( shift->_try( '_request', 'set_last_modified', @_ ) ); }

# Returns a APR::Socket
# See Apache2::Connection manual page
sub socket { return( shift->_try( 'connection', 'client_socket', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/SourceMap>
sub sourcemap { return( shift->_set_get_one( 'SourceMap', @_ ) ); }

sub status { return( shift->_try( '_request', 'status', @_ ) ); }

sub status_line { return( shift->_try( '_request', 'status_line', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security>
sub strict_transport_security { return( shift->_set_get_one( 'Strict-Transport-Security', @_ ) ); }

sub subprocess_env { return( shift->_try( '_request', 'subprocess_env' ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Timing-Allow-Origin>
sub timing_allow_origin { return( shift->_set_get_multi( 'Timing-Allow-Origin', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Trailer>
sub trailer { return( shift->_set_get_one( 'Trailer', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding>
sub transfer_encoding { return( shift->_set_get_one( 'Transfer-Encoding', @_ ) ); }

sub unescape { return( URI::Escape::uri_unescape( @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade>
sub upgrade { return( shift->_set_get_multi( 'Upgrade', @_ ) ); }

sub update_mtime { return( shift->_try( '_request', 'update_mtime', @_ ) ); }

sub uri_escape { return( shift->escape( @_ ) ); }

sub uri_unescape { return( shift->unescape( @_ ) ); }

sub url_decode { return( shift->decode( @_ ) ); }

sub url_encode { return( shift->encode( @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Vary>
sub vary { return( shift->_set_get_multi( 'Vary', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Via>
sub via { return( shift->_set_get_multi( 'Via', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Want-Digest>
sub want_digest { return( shift->_set_get_multi( 'Want-Digest', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Warning>
sub warning { return( shift->_set_get_one( 'Warning', @_ ) ); }

# e.g. $cnt = $r->write($buffer);
# $cnt = $r->write( $buffer, $len );
# $cnt = $r->write( $buffer, $len, $offset );
sub write { return( shift->_try( '_request', 'write', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate>
sub www_authenticate { return( shift->_set_get_one( 'WWW-Authenticate', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options>
sub x_content_type_options { return( shift->_set_get_one( 'X-Content-Type-Options', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-DNS-Prefetch-Control>
sub x_dns_prefetch_control { return( shift->_set_get_one( 'X-DNS-Prefetch-Control', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options>
sub x_frame_options { return( shift->_set_get_one( 'X-Frame-Options', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection>
sub x_xss_protection { return( shift->_set_get_one( 'X-XSS-Protection', @_ ) ); }

sub _headers
{
    my $self = shift( @_ );
    my $type = shift( @_ ) ||
        return( $self->error({
            message => "No header type was specified.",
            want => [qw( hash )],
        }) );
    my $req = $self->_request ||
        return( $self->error({
            message => "No Apache2::RequestRec found!",
            want => [qw( hash )],
        }) );
    my $code = $req->can( $type ) ||
        return( $self->error({
            message => "Header type '$type' is unsupported by Apache2::RequestRec",
            want => [qw( hash )],
        }) );
    my $apr = $code->( $req ) ||
        return( $self->error({
            message => "Could not get an APR::Table object from Apache2::RequestRec->${type}",
            want => [qw( hash )],
        }) );
    if( !$self->_is_a( $apr => 'APR::Table' ) )
    {
        return( $self->error({
            message => "Object retrieved from Apache2::RequestRec->${type} is not an APR::Table object.",
            want => [qw( hash )],
        }) );
    }
    if( scalar( @_ ) && !( @_ % 2 ) )
    {
        for( my $i = 0; $i < scalar( @_ ); $i += 2 )
        {
            if( !defined( $_[ $i + 1 ] ) )
            {
                $apr->unset( $_[ $i ] );
            }
            else
            {
                $apr->set( $_[ $i ] => $_[ $i + 1 ] );
            }
        }
    }
    elsif( scalar( @_ ) )
    {
        return( $apr->get( shift( @_ ) ) );
    }
    else
    {
        return( $apr );
    }
}

sub _request { return( shift->request->request ); }

sub _set_get_multi
{
    my $self = shift( @_ );
    my $f    = shift( @_ );
    return( $self->SUPER::error( "No field was provided to set its value." ) ) if( !defined( $f ) || !length( "$f" ) );
    my $headers = $self->headers;
    if( @_ )
    {
        my $v = shift( @_ );
        return( $headers->unset( $f ) ) if( !defined( $v ) );
        if( $self->_is_array( $v ) )
        {
            # Take a copy to be safe since this is a reference
            $headers->set( $f => [@$v] );
        }
        else
        {
            $headers->set( $f => [split( /\,[[:blank:]\h]*/, $v)] );
        }
        return( $self );
    }
    else
    {
        my $v = $headers->get( $f );
        unless( $self->_is_array( $v ) )
        {
            $v = [split( /\,[[:blank:]\h]*/, $v )];
        }
        return( $self->new_array( $v ) );
    }
}

sub _set_get_one
{
    my $self = shift( @_ );
    my $f    = shift( @_ );
    return( $self->SUPER::error( "No field was provided to set its value." ) ) if( !defined( $f ) || !length( "$f" ) );
    my $headers = $self->headers;
    if( @_ )
    {
        my $v = shift( @_ );
        return( $headers->unset( $f ) ) if( !defined( $v ) );
        $headers->set( $f => $v );
        return( $self );
    }
    else
    {
        my $v = $headers->get( $f );
        return( $self->new_scalar( $v ) ) if( !ref( $v ) );
        return( $self->new_array( $v ) ) if( $self->_is_array( $v ) );
        # By default
        return( $v );
    }
}

sub _try
{
    my $self = shift( @_ );
    my $pack = shift( @_ ) || return( $self->error( "No Apache package name was provided to call method" ) );
    my $meth = shift( @_ ) || return( $self->error( "No method name was provided to try!" ) );
    my $r = Apache2::RequestUtil->request;
    # $r->log_error( "Apache2::API::Response::_try to call method \"$meth\" in package \"$pack\"." );
    # try-catch
    local $@;
    my( @rv, $rv );
    if( wantarray() )
    {
        @rv = eval
        {
            return( $self->$pack->$meth() ) if( !scalar( @_ ) );
            return( $self->$pack->$meth( @_ ) );
        };
    }
    else
    {
        $rv = eval
        {
            return( $self->$pack->$meth() ) if( !scalar( @_ ) );
            return( $self->$pack->$meth( @_ ) );
        };
    }
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to call Apache ", ucfirst( $pack ), " method \"$meth\": $@" ) );
    }
    return( wantarray() ? @rv : $rv );
}

# NOTE: sub FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Apache2::API::Response - Apache2 Outgoing Response Access and Manipulation

=head1 SYNOPSIS

    use Apache2::API::Response;
    # $r is the Apache2::RequestRec object
    my $resp = Apache2::API::Response->new( request => $r, debug => 1 );
    # or, to test it outside of a modperl environment:
    my $resp = Apache2::API::Response->new( request => $r, debug => 1, checkonly => 1 );

    # Access-Control-Allow-Credentials
    my $cred = $resp->allow_credentials;
    # Access-Control-Allow-Headers
    $resp->allow_headers( $custom_header );
    # Access-Control-Allow-Methods
    $resp->allow_methods( $method );
    $reso->allow_origin( $origin );
    # Alt-Svc
    my $alt = $resp->alt_svc;
    my $nbytes = $resp->bytes_sent;
    # Cache-Control
    my $cache = $resp->cache_control;
    # Clear-Site-Data
    my $clear = $resp->clear_site_data;
    
    # Apache2::Connection object
    my $conn = $resp->connection;
    my $code = $resp->code;
    # Content-Disposition
    my $disp = $resp->content_disposition;
    my $encoding = $resp->content_encoding;
    # Content-Language
    my $lang = $resp->content_language;
    my $langs_array_ref = $resp->content_languages;
    # Content-Length
    my $len = $resp->content_length;
    # Content-Location
    my $location = $resp->content_location;
    # Content-Range
    my $range = $resp->content_range;
    # Content-Security-Policy
    my $policy = $resp->content_security_policy;
    my $policy = $resp->content_security_policy_report_only;
    my $ct = $resp->content_type;
    my $cookie = $resp->cookie_new(
        name => $name,
        value => $some_value,
        value => 'sid1234567',
        path => '/',
        expires => '+10D',
        # or alternatively
        maxage => 864000
        # to make it exclusively accessible by regular http request and not javascript
        http_only => 1,
        same_site => 'Lax',
        # should it be used under ssl only?
        secure => 1
    );
    $resp->cookie_replace( $cookie );
    $resp->cookie_set( $cookie );
    # Cross-Origin-Embedder-Policy
    my $policy = $resp->cross_origin_embedder_policy;
    # Cross-Origin-Opener-Policy
    my $policy = $resp->cross_origin_opener_policy;
    # Cross-Origin-Resource-Policy
    my $policy = $resp->cross_origin_resource_policy;
    my $cspro = $resp->cspro;
    $resp->custom_response( Apache2::Const::AUTH_REQUIRED, "Authenticate please" );
    my $decoded = $resp->decode( $string );
    # Digest
    my $digest = $resp->digest;
    my $encoded = $resp->encode( $string );
    # APR::Table object
    my $env = $resp->env;
    my $headers = $resp->err_headers;
    my $headers = $resp->err_headers_out;
    my $escaped = $resp->escape( $string );
    my $etag = $resp->etag;
    # Expires
    my $expires = $resp->expires;
    # Access-Control-Expose-Headers
    my $expose_headers = $resp->expose_headers;
    $resp->flush;
    my $msg = $resp->get_http_message( 429 => 'ja_JP' );
    my $string = $resp->get_status_line;
    my $content_type = $resp->headers( 'Content-Type' );
    # or (since it is case insensitive)
    my $content_type = $resp->headers( 'content-type' );
    # or
    my $content_type = $resp->headers->{'Content-Type'};
    $resp->header( 'Content-Type' => 'text/plain' );
    # or
    $resp->headers->{'Content-Type'} = 'text/plain';
    # APR::Table object
    my $headers = $resp->headers;
    my $headers = $resp->headers_out;
    $resp->internal_redirect( $uri );
    $resp->internal_redirect_handler( $uri );
    my $rv = $resp->is_info(100);
    my $rv = $resp->is_success(200);
    my $rv = $resp->is_redirect(302);
    my $rv = $resp->is_error(400);
    my $rv = $resp->is_client_error(401);
    my $rv = $resp->is_server_error(500);
    # Keep-Alive
    my $keep_alive = $resp->keep_alive;
    # Last-Modified
    my $http_date = $resp->last_modified;
    # Last-Modified-Date
    my $http_date = $resp->last_modified_date;
    # Location
    my $loc = $resp->location;
    my $rv = $resp->lookup_uri( $uri );
    my $etag = $resp->make_etag( $force_weak );
    # Access-Control-Max-Age
    my $max_age = $resp->max_age;
    my $rv = $resp->meets_conditions;
    # NEL
    my $nel = $resp->nel;
    $resp->no_cache(1);
    $resp->no_local_copy(1);
    $resp->print( @some_data );
    $resp->printf( $template, $param1, $param2 );
    my $puts = $resp->puts;
    my $rv = $resp->redirect( $uri );
    # Referrer-Policy
    my $policy = $resp->referrer_policy;
    my $r = $resp->request;
    # Retry-After
    my $retry_after = $resp->retry_after;
    $resp->rflush;
    $resp->send_cgi_header;
    $resp->sendfile( $filename, $offset, $len );
    $resp->sendfile( $filename );
    # Server
    my $server = $resp->server;
    my $server_timing = $resp->server_timing;
    $resp->set_content_length(1024);
    # Set-Cookie
    $resp->set_cookie( $cookie );
    $resp->set_last_modified;
    $resp->set_keepalive(1);
    my $socket = $resp->socket;
    my $sourcemap = $resp->sourcemap;
    my $status = $resp->status;
    my $status_line = $resp->status_line;
    # Strict-Transport-Security
    my $policy = $resp->strict_transport_security;
    # APR::Table object
    my $env = $resp->subprocess_env;
    # Timing-Allow-Origin
    my $origin = $resp->timing_allow_origin;
    # Trailer
    my $trailerv = $resp->trailer;
    my $enc = $resp->transfer_encoding;
    my $unescape = $resp->unescape( $string );
    # Upgrade
    my $upgrade = $resp->upgrade;
    $resp->update_mtime( $seconds );
    my $uri = $resp->uri_escape( $uri );
    my $uri = $resp->uri_unescape( $uri );
    my $decoded = $resp->url_decode( $uri );
    my $encoded = $resp->url_encode( $uri );
    # Vary
    my $vary = $resp->vary;
    # Via
    my $via = $resp->via;
    # Want-Digest
    my $want = $resp->want_digest;
    # Warning
    my $warn = $resp->warning;
    $resp->write( $buffer, $len, $offset );
    # WWW-Authenticate
    my $auth = $resp->www_authenticate;
    # X-Content-Type-Options
    my $opt = $resp->x_content_type_options;
    # X-DNS-Prefetch-Control
    my $proto = $resp->x_dns_prefetch_control;
    # X-Frame-Options
    my $opt = $resp->x_frame_options;
    # X-XSS-Protection
    my $xss = $resp->x_xss_protection; 

=head1 VERSION

    v0.1.3

=head1 DESCRIPTION

The purpose of this module is to provide an easy access to various method to process and manipulate incoming request.

This is designed to work under modperl.

Normally, one would need to know which method to access across various Apache2 mod perl modules, which makes development more time consuming and even difficult, because of the scattered documentation and even sometime outdated.

This module alleviate this problem by providing all the necessary methods in one place. Also, at the contrary of C<Apache2> modules suit, all the methods here are die safe. When an error occurs, it will always return undef() and the error will be able to be accessed using B<error> object, which is a L<Module::Generic::Exception> object.

Fo its alter ego to manipulate outgoing HTTP response, use the L<Apache2::API::Response> module.

=head1 CONSTRUCTORS

=head2 new

This initiates the package and take the following parameters:

=over 4

=item * C<checkonly>

If true, it will not perform the initialisation it would usually do under modperl.

=item * C<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=item * C<request>

This is a required parameter to be sent with a value set to a L<Apache2::RequestRec> object

=back

=head1 METHODS

=head2 allow_credentials

Sets or gets the HTTP header field C<Access-Control-Allow-Credentials>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials>

=head2 allow_headers

Sets or gets the HTTP header field C<Access-Control-Allow-Credentials>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers>

=head2 allow_methods

Sets or gets the HTTP header field C<Access-Control-Allow-Methods>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods>

=head2 allow_origin

Sets or gets the HTTP header field C<Access-Control-Allow-Origin>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin>

=head2 alt_svc

Sets or gets the HTTP header field C<Alt-Svc>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Alt-Svc>

=head2 bytes_sent

The number of bytes sent to the client, handy for logging, etc.

This calls L<Apache2::RequestRec/bytes_sent>

=head2 cache_control

Sets or gets the HTTP header field C<Cache-Control>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control>

=head2 call

Provided with an Apache2 API method name, and optionally with some additional arguments, and this will call that Apache2 method and return its result.

This is designed to allow you to call arbitrary Apache2 method that, possibly, are not covered here.

For example:

    $resp->call( 'send_error_response' );

It returns whatever value this call returns.

=head2 clear_site_data

Sets or gets the HTTP header field C<Clear-Site-Data>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data>

=head2 code

Sets or gets the response status code, by calling L<Apache2::RequestRec/status>

From the L<Apache2::RequestRec> documentation:

Usually you will set this value indirectly by returning the status code as the handler's function result. However, there are rare instances when you want to trick Apache into thinking that the module returned an C<Apache2::Const::OK> status code, but actually send the browser a non-OK status. This may come handy when implementing an HTTP proxy handler. The proxy handler needs to send to the client, whatever status code the proxied server has returned, while returning C<Apache2::Const::OK> to Apache. e.g.:

    $resp->status( $some_code );
    return( Apache2::Const::OK );

=head2 connection

Returns a L<Apache2::Connection> object.

=head2 content_disposition

Sets or gets the HTTP header field C<Content-Disposition>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>

=head2 content_encoding

Get or set content encoding (the C<Content-Encoding> HTTP header). Content encodings are string like C<gzip> or C<compress>.

For example, here is how to send a gzip'ed response:

     require Compress::Zlib;
     $resp->content_type( "text/plain" );
     $resp->content_encoding( "gzip" );
     $resp->print( Compress::Zlib::memGzip( "some text to be gzipped" ) );

=head2 content_language

Sets or gets the HTTP header field C<Content-Language>

=head2 content_languages

    my $languages = $resp->content_languages();
    my $prev_lang = $resp->content_languages( $nev_lang );

Sets or gets the value of the C<Content-Language> HTTP header, by calling L<Apache2::RequestRec/content_languages>

Content languages are string like C<en> or C<fr>.

It returns the language codes as an array reference.

=head2 content_length

Set the content length for this request, by calling L<Apache2::Response/set_content_length>

See L<Apache2::Response> for more information.

=head2 content_location

Sets or gets the HTTP header field C<Content-Location>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Location>

=head2 content_range

Sets or gets the HTTP header field C<Content-Range>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Range>

=head2 content_security_policy

Sets or gets the HTTP header field C<Content-Security-Policy>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy>

=head2 content_security_policy_report_only

Sets or gets the HTTP header field C<Content-Security-Policy-Report-Only>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only>

=head2 content_type

Get or set the HTTP response C<Content-type> header value.

For example, set the C<Content-type> header to C<text/plain>.

     $resp->content_type('text/plain');

If you set this header via the C<headers_out> table directly, it will be ignored by Apache. So do not do that.

See L<Apache2::RequestRec> for more information.

=head2 cookie_new

Given a hash reference with the following properties, this will create a L<Cookie> object that can be stringified and aded into a C<Set-Cookie> HTTP header.

=over 4

=item C<name>

=item C<value>

=item C<domain>

=item C<expires>

=item C<http_only>

=item C<max_age>

=item C<path>

=item C<secure>

=item C<same_site>

=back

See L<Cookie::Jar/make> and L<Cookie> for more information on those parameters.

=head2 cookie_replace

Given a cookie object, this either sets the given cookie in a C<Set-Cookie> header or replace the existing one with the same cookie name, if any.

It returns the cookie object provided.

=head2 cookie_set

Given a cookie object, this set the C<Set-Cookie> HTTP header for this cookie.

However, it does not check if another C<Set-Cookie> header exists for this cookie.

=head2 cross_origin_embedder_policy

Sets or gets the HTTP header field C<Cross-Origin-Embedder-Policy>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Embedder-Policy>

=head2 cross_origin_opener_policy

Sets or gets the HTTP header field C<Cross-Origin-Opener-Policy>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Opener-Policy>

=head2 cross_origin_resource_policy

Sets or gets the HTTP header field C<Cross-Origin-Resource-Policy>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Resource-Policy>

=head2 cspro

Alias for L</content_security_policy_report_only>

=head2 custom_response

Install a custom response handler for a given status.

    $resp->custom_response( $status, $string );

The first argument is the status for which the custom response should be used (e.g. C<Apache2::Const::AUTH_REQUIRED>)

The second argument is the custom response to use. This can be a static string, or a URL, full or just the uri path (C</foo/bar.txt>).

B<custom_response>() does not alter the response code, but is used to replace the standard response body. For example, here is how to change the response body for the access handler failure:

     package MyApache2::MyShop;
     use Apache2::Response ();
     use Apache2::Const -compile => qw(FORBIDDEN OK);
     sub access {
         my $r = shift;

         if (MyApache2::MyShop::tired_squirrels()) {
             $resp->custom_response(Apache2::Const::FORBIDDEN,
                 "It is siesta time, please try later");
             return Apache2::Const::FORBIDDEN;
         }

         return Apache2::Const::OK;
     }
     ...

     # httpd.conf
     PerlModule MyApache2::MyShop
     <Location /TestAPI__custom_response>
         AuthName dummy
         AuthType none
         PerlAccessHandler   MyApache2::MyShop::access
         PerlResponseHandler MyApache2::MyShop::response
     </Location>

When squirrels cannot run any more, the handler will return C<403>, with the custom message:

     It is siesta time, please try later

=head2 decode

Given a url-encoded string, this returns the decoded string

This uses L<APR::Request> XS method.

=head2 digest

Sets or gets the HTTP header field C<Digest>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Digest>

=head2 encode

Given a string, this returns its url-encoded version

This uses L<APR::Request> XS method.

=head2 env

    my $val = $resp->env( $name );
    $resp->env( $name, $value );

Using the Apache C<subprocess_env> table, this sets or gets environment variables. This is the equivalent of this:

                 $resp->subprocess_env;
    $env_table = $resp->subprocess_env;

           $resp->subprocess_env( $key => $val );
    $val = $resp->subprocess_env( $key );

where C<$resp> is this module object.

If one argument is provided, it will return the corresponding environment value.

If one or more sets of key-value pair are provided, they are set accordingly.

If nothing is provided, it returns a L<APR::Table> object.

=head2 err_headers

Given one or more name => value pair, this will set them in the HTTP header using the L</err_headers_out> method.

=head2 err_headers_out

Get or sets HTTP response headers, which are printed out even on errors and persist across internal redirects.

According to the L<Apache2::RequestRec> documentation:

The difference between L</headers_out> (L<Apache2::RequestRec/headers_out>) and L</err_headers_out> (L<Apache2::RequestRec/err_headers_out>), is that the latter are printed even on error, and persist across internal redirects (so the headers printed for C<ErrorDocument> handlers will have them).

For example, if a handler wants to return a C<404> response, but nevertheless to set a cookie, it has to be:

    $resp->err_headers_out->add( 'Set-Cookie' => $cookie );
    return( Apache2::Const::NOT_FOUND );

If the handler does:

    $resp->headers_out->add( 'Set-Cookie' => $cookie );
    return( Apache2::Const::NOT_FOUND );

the C<Set-Cookie> header will not be sent.

See L<Apache2::RequestRec> for more information.

=head2 escape

Provided with a value and this will return it uri escaped by calling L<URI::Escape/uri_escape>.

=head2 etag

Sets or gets the HTTP header field C<Etag>

=head2 expires

Sets or gets the HTTP header field C<Expires>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expires>

=head2 expose_headers

Sets or gets the HTTP header field C<Access-Control-Expose-Headers>

e.g.: Access-Control-Expose-Headers: Content-Encoding, X-Kuma-Revision

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers>

=head2 flush

Flush any buffered data to the client, by calling L<Apache2::RequestIO/rflush>

    $resp->flush();

Unless STDOUT stream's C<$|> is false, data sent via C<< $resp->print() >> is buffered. This method flushes that data to the client.

For example if your script needs to perform a relatively long-running operation (e.g. a slow db lookup) and the client may timeout if it receives nothing right away, you may want to start the handler by setting the C<Content-Type> header, following by an immediate flush[1]:

    $resp->content_type('text/html');
    $resp->flush; # send the headers out

    $resp->print( long_operation() );
    return( Apache2::Const::OK );

[1] mod_perl2 documentation L<https://perl.apache.org/docs/2.0/user/coding/coding.html#toc_Forcing_HTTP_Response_Headers_Out>

=head2 get_http_message

Given an HTTP code integer, and optionally a language code, this returns the HTTP status message in the language given.

If no language is provided, this returns the message by default in C<en_GB>, i.e. British English.

See also L<Apache2::API::Status>

=head2 get_status_line

Return the C<Status-Line> for a given status code (excluding the HTTP-Version field), by calling L<Apache2::RequestRec/status_line>

For example:

    print( $resp->get_status_line( 400 ) );

will print:

    400 Bad Request

See also L</status_line>

=head2 header

    $resp->header( 'Content-Type' => 'application/json' );
    my $ct = $resp->header( 'Content-Type' );

Sets or gets an HTTP header.

=head2 headers

Gets or sets the HTTP response headers using L<APR::Table> by calling L</Apache2::RequestRec/err_headers_out>

This takes zero, one or sets or C<< key => value >> pairs.

When no argument is provided, this returns the L<APR::Object>.

When one argument is provided, it returns the corresponding HTTP header value, if any.

You can set multiple key-value pairs, like so:

    $resp->headers( $var1 => $val1, $var2 => $val2 );

If a value provided is C<undef>, it will remove the corresponding HTTP headers.

With the L<APR::Table> object, you can access and set header fields directly, such as:

    my $accept = $resp->headers->{Accept};
    $resp->headers->{Accept} = 'application/json';
    $resp->headers->{Accept} = undef; # unset it

or

    my $accept = $resp->headers->get( 'Accept' );
    $resp->headers->set( Accept => 'application/json' );
    $resp->headers->unset( 'Accept' );
    $resp->headers->add( Vary => 'Accept-Encoding' );
    # Very useful for this header
    $resp->headers->merge( Vary => 'Accept-Encoding' );
    # Empty the headers
    $resp->headers->clear;
    use Apache2::API;
    # to merge: multiple values for the same key are flattened into a comma-separated list.
    $resp->headers->compress( APR::Const::OVERLAP_TABLES_MERGE );
    # to overwrite: each key will be set to the last value seen for that key.
    $resp->headers->compress( APR::Const::OVERLAP_TABLES_SET );
    my $table = $resp->headers->copy( $resp2->pool );
    my $headers = $resp->headers;
    $resp->headers->do(sub
    {
        my( $key, $val ) = @_;
        # Do something
        # return(0) to abort
    }, keys( %$headers ) );
    # or without any filter keys
    $resp->headers->do(sub
    {
        my( $key, $val ) = @_;
        # Do something
        # return(0) to abort
    });
    # To prepare a table of 20 elements, but the table can still grow
    my $table = APR::Table::make( $resp->pool, 20 );
    my $table2 = $resp2->headers;
    # overwrite any existing keys in our table $table
    $table->overlap( $table2, APR::Const::OVERLAP_TABLES_SET );
    # key, value pairs are added, regardless of whether there is another element with the same key in $table
    $table->overlap( $table2, APR::Const::OVERLAP_TABLES_MERGE );
    my $table3 = $table->overlay( $table2, $pool3 );

See L<APR::Table> for more information.

=head2 headers_out

Returns or sets the C<< key => value >> pairs of outgoing HTTP headers, only on 2xx responses.

See also L</err_headers_out>, which allows to set headers for non-2xx responses and persist across internal redirects.

More information at L<Apache2::RequestRec>

=head2 internal_redirect

Given a C<URI> object or a uri path string, this redirect the current request to some other uri internally.

If a C<URI> object is given, its C<path> method will be used to get the path string.

    $resp->internal_redirect( $new_uri );

In case that you want some other request to be served as the top-level request instead of what the client requested directly, call this method from a handler, and then immediately return L<Apache2::Const::OK>. The client will be unaware the a different request was served to her behind the scenes.

See L<Apache2::SubRequest> for more information.

=head2 internal_redirect_handler

Identical to L</internal_redirect>, plus automatically sets C<< $resp->content_type >> is of the sub-request to be the same as of the main request, if C<< $resp->handler >> is true.

=head2 is_info

Given a HTTP code integer, this will return true if the code is comprised between C<100> and less than C<200>, false otherwise.

=head2 is_success

Given a HTTP code integer, this will return true if the code is comprised between C<200> and less than C<300>, false otherwise.

=head2 is_redirect

Given a HTTP code integer, this will return true if the code is comprised between C<300> and less than C<400>, false otherwise.

=head2 is_error

Given a HTTP code integer, this will return true if the code is comprised between C<400> and less than C<600>, false otherwise.

=head2 is_client_error

Given a HTTP code integer, this will return true if the code is comprised between C<400> and less than C<500>, false otherwise.

=head2 is_server_error

Given a HTTP code integer, this will return true if the code is comprised between C<500> and less than C<600>, false otherwise.

=head2 keep_alive

Sets or gets the HTTP header field C<Keep-Alive>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Keep-Alive>

=head2 last_modified

Sets or gets the HTTP header field C<Last-Modified>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified>

=head2 last_modified_date

Sets or gets the HTTP header field C<Last-Modified-Date>

=head2 location

Sets or gets the HTTP header field C<Location>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location>

=head2 lookup_uri

Create a sub request from the given URI, by calling L<Apache2::SubRequest/lookup_uri>

This sub request can be inspected to find information about the requested URI.

     $ret = $resp->lookup_uri( $new_uri );
     $ret = $resp->lookup_uri( $new_uri, $next_filter );
     $ret = $resp->lookup_uri( $new_uri, $next_filter, $handler );

See L<Apache2::SubRequest> for more information.

=head2 make_etag

Provided with a boolean value, this constructs an entity tag from the resource information, by calling L<Apache2::Response/make_etag>

If it is a real file, build in some of the file characteristics.

    $etag = $resp->make_etag( $force_weak );

It returns the etag as a string.

=head2 max_age

Sets or gets the HTTP header field C<Access-Control-Max-Age>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age>

=head2 meets_conditions

Implements condition C<GET> rules for HTTP/1.1 specification. This function inspects the client headers and determines if the response fulfills the specified requirements.

    $status = $resp->meets_conditions();

It returns L<Apache2::Const::OK> if the response fulfils the condition GET rules. Otherwise some other status code (which should be returned to Apache).

=head2 nel

Sets or gets the HTTP header field C<NEL>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/NEL>

=head2 no_cache

Add or remove cache control headers:

     $prev_no_cache = $resp->no_cache( $boolean );

A true value sets the C<no_cache> request record member to a true value and inserts:

     Pragma: no-cache
     Cache-control: no-cache

into the response headers, indicating that the data being returned is volatile and the client should not cache it.

A false value unsets the C<no_cache> request record member and the mentioned headers if they were previously set.

This method should be invoked before any response data has been sent out.

=head2 no_local_copy

    my $status = $resp->no_local_copy();

Used internally in certain sub-requests to prevent sending C<Apache2::Const::HTTP_NOT_MODIFIED> for a fragment or error documents.

Also affect L</meets_conditions>. If set to a true value, the conditions are always met.

It returns a status integer.

=head2 print

Provided with a list of data, and this sends it to the client, by calling L<Apache2::RequestIO/print>

    $cnt = $resp->print( @msg );

It returns how many bytes were sent (or buffered). If zero bytes were sent, C<print> will return C<0E0>, or C<zero but true>, which will still evaluate to 0 in a numerical context.

The data is flushed only if STDOUT stream's C<$|> is true. Otherwise it is buffered up to the size of the buffer, flushing only excessive data.

=head2 printf

Format and send data to the client (same as perl's C<printf>), by calling L<Apache2::RequestIO/printf>

    $cnt = $resp->printf( $format, @args );

It returns how many bytes were sent (or buffered).

The data is flushed only if STDOUT stream's C<$|> is true. Otherwise it is buffered up to the size of the buffer, flushing only excessive data.

=head2 puts

    $cnt = $req->puts( @msg );

Provided with values, this sends it to the client, by calling L<Apache2::RequestIO/puts>

It returns how many bytes were sent (or buffered).

=head2 redirect

Given an URI, this will prepare the HTTP headers and return the proper code for a C<301> temporary HTTP redirect.

It should be used like this in your code:

    return( $resp->redirect( "https://example.com/somewhere/" ) );

=head2 referrer_policy

Sets or gets the HTTP header field C<Referrer-Policy>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy>

=head2 request

Returns the L<Apache2::API::Request> object.

=head2 retry_after

Sets or gets the HTTP header field C<Retry-After>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After>

=head2 rflush

Flush any buffered data to the client, by calling L<Apache2::RequestIO/rflush>

Unless STDOUT stream's C<$|> is false, data sent via C<< $resp->print() >> is buffered. This method flushes that data to the client.

It does not return any value.

=head2 send_cgi_header

Parse the header, by calling L<Apache2::Response/send_cgi_header>

    $resp->send_cgi_header( $buffer );

This method is really for back-compatibility with mod_perl 1.0. It is very inefficient to send headers this way, because of the parsing overhead.

If there is a response body following the headers it will be handled too (as if it was sent via L</print>).

Notice that if only HTTP headers are included they will not be sent until some body is sent (again the C<send> part is retained from the mod_perl 1.0 method).

See L<Apache2::Response> for more information.

=head2 sendfile

Provided with a file path, an optional offset and an optional length, and this will send a file or a part of it, by calling L<Apache2::RequestIO/sendfile>

     $rc = $resp->sendfile( $filename );
     $rc = $resp->sendfile( $filename, $offset );
     $rc = $resp->sendfile( $filename, $offset, $len );

It returns a L<APR::Const> constant.

On success, L<APR::Const::SUCCESS> is returned.

In case of a failure, a failure code is returned, in which case normally it should be returned to the caller

=head2 server

Sets or gets the HTTP header field C<Server>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server>

=head2 server_timing

Sets or gets the HTTP header field C<Server-Timing>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server-Timing>

=head2 set_content_length

Set the content length for this request, by calling L<Apache2::Response/set_content_length>

    $resp->set_content_length( $length );

It does not return any value.

=head2 set_cookie

Sets or gets the HTTP header field C<Set-Cookie>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>

=head2 set_etag

    $resp->set_etag;

Set automatically the C<E-tag> outgoing header.

It does not return any value.

=head2 set_keepalive

    $ret = $resp->set_keepalive;

Returns the keepalive status for this request, by calling L<Apache2::Response/set_keepalive>

It returns true if keepalive can be set, false otherwise.

=head2 set_last_modified

Sets the C<Last-Modified> response header field to the value of the mtime field in the request structure, rationalized to keep it from being in the future, by calling L<Apache2::Response/set_last_modified>

    $resp->set_last_modified( $mtime );

If the C<$mtime> argument is passed, C<< $resp->update_mtime >> will be first run with that argument.

=head2 socket

    my $socket      = $resp->socket;
    my $prev_socket = $resp->socket( $new_socket );

Get or set the client socket and returns a L<APR::Socket> object, by calling L<Apache2::Connection/client_socket>

=head2 sourcemap

Sets or gets the HTTP header field C<SourceMap>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/SourceMap>

=head2 status

Get or set the reply status for the client request, by calling L<Apache2::RequestRec/status>

Normally you would use some L<Apache2::Const> constant, e.g. L<Apache2::Const::REDIRECT>.

From the L<Apache2::RequestRec> documentation:

Usually you will set this value indirectly by returning the status code as the handler's function result. However, there are rare instances when you want to trick Apache into thinking that the module returned an C<Apache2::Const:OK> status code, but actually send the browser a non-OK status. This may come handy when implementing an HTTP proxy handler. The proxy handler needs to send to the client, whatever status code the proxied server has returned, while returning L<Apache2::Const::OK> to Apache. e.g.:

    $resp->status( $some_code );
    return( Apache2::Const::OK );

See also C<< $resp->status_line >>, which. if set, overrides C<< $resp->status >>.

=head2 status_line

    my $status_line      = $resp->status_line();
    my $prev_status_line = $resp->status_line( $new_status_line );

Get or sets the response status line. The status line is a string like C<200 Document follows> and it will take precedence over the value specified using the C<< $resp->status() >> described above.

According to the L<Apache2::RequestRec> documentation:

When discussing C<< $resp->status >> we have mentioned that sometimes a handler runs to a successful completion, but may need to return a different code, which is the case with the proxy server. Assuming that the proxy handler forwards to the client whatever response the proxied server has sent, it will usually use C<status_line()>, like so:

     $resp->status_line( $response->code() . ' ' . $response->message() );
     return( Apache2::Const::OK );

In this example C<$response> could be for example an L<HTTP::Response> object, if L<LWP::UserAgent> was used to implement the proxy.

This method is also handy when you extend the HTTP protocol and add new response codes. For example you could invent a new error code and tell Apache to use that in the response like so:

     $resp->status_line( "499 We have been FooBared" );
     return( Apache2::Const::OK );

Here 499 is the new response code, and We have been FooBared is the custom response message.

=head2 strict_transport_security

Sets or gets the HTTP header field C<Strict-Transport-Security>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security>

=head2 subprocess_env

Get or sets the L<Apache2::RequestRec> C<subprocess_env> table, or optionally set the value of a named entry.

From the L<Apache2::RequestRec> documentation:

When called in void context with no arguments, it populate C<%ENV> with special variables (e.g. C<$ENV{QUERY_STRING}>) like mod_cgi does.

When called in a non-void context with no arguments, it returns an C<APR::Table object>.

When the $key argument (string) is passed, it returns the corresponding value (if such exists, or C<undef>. The following two lines are equivalent:

     $val = $resp->subprocess_env( $key );
     $val = $resp->subprocess_env->get( $key );

When the $key and the $val arguments (strings) are passed, the value is set. The following two lines are equivalent:

     $resp->subprocess_env( $key => $val );
     $resp->subprocess_env->set( $key => $val );

The C<subprocess_env> C<table> is used by L<Apache2::SubProcess>, to pass environment variables to externally spawned processes. It is also used by various Apache modules, and you should use this table to pass the environment variables. For example if in C<PerlHeaderParserHandler> you do:

      $resp->subprocess_env( MyLanguage => "de" );

you can then deploy C<mod_include> and write in C<.shtml> document:

      <!--#if expr="$MyLanguage = en" -->
      English
      <!--#elif expr="$MyLanguage = de" -->
      Deutsch
      <!--#else -->
      Sorry
      <!--#endif -->

=head2 timing_allow_origin

Sets or gets the HTTP header field C<Timing-Allow-Origin>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Timing-Allow-Origin>

=head2 trailer

Sets or gets the HTTP header field C<Trailer>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Trailer>

=head2 transfer_encoding

Sets or gets the HTTP header field C<Transfer-Encoding>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding>

=head2 unescape

Unescape the given data chunk by calling L<URI::Escape/uri_unescape>

=head2 update_mtime

Set the C<< $resp->mtime >> field to the specified value if it is later than what is already there, by calling L<Apache2::Response/update_mtime>

    $resp->update_mtime( $mtime );

=head2 upgrade

Sets or gets the HTTP header field C<Upgrade>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade>

=head2 uri_escape

Provided with a string and this uses L<URI::Escape> to return an uri-escaped string.

=head2 uri_unescape

Provided with an uri-escaped string and this will decode it and return its original string, by calling L<URI::Escape/uri_unescape>

=head2 url_decode

Provided with an url-encoded string and this will return its decoded version, by calling L<APR::Request/decode>

=head2 url_encode

Provided with a string and this will return an url-encoded version, by calling L<APR::Request/encode>

=head2 vary

Sets or gets the HTTP header field C<Vary>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Vary>

=head2 via

Sets or gets the HTTP header field C<Via>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Via>

=head2 want_digest

Sets or gets the HTTP header field C<Want-Digest>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Want-Digest>

=head2 warning

Sets or gets the HTTP header field C<Warning>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Warning>

=head2 write

Send partial string to the client, by calling L<Apache2::RequestIO/write>

     $cnt = $resp->write( $buffer );
     $cnt = $resp->write( $buffer, $len );
     $cnt = $resp->write( $buffer, $len, $offset );

It returns How many bytes were sent (or buffered).

See L<Apache2::RequestIO> for more information.

=head2 www_authenticate

Sets or gets the HTTP header field C<WWW-Authenticate>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate>

=head2 x_content_type_options

Sets or gets the HTTP header field C<X-Content-Type-Options>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options>

=head2 x_dns_prefetch_control

Sets or gets the HTTP header field C<X-DNS-Prefetch-Control>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-DNS-Prefetch-Control>

=head2 x_frame_options

Sets or gets the HTTP header field C<X-Frame-Options>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options>

=head2 x_xss_protection

Sets or gets the HTTP header field C<X-XSS-Protection>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection>

=head2 _request

Returns the embedded L<Apache2::RequestRec>

=head2 _set_get_multi

    $self->_set_get_multi( 'SomeHeader' => $some_value );

Sets or gets a header with multiple values. The value provided for the header can be either an array reference and it will be used as is (after being copied), or a regular string, which will be converted into an array reference by splitting it by comma.

If the value is undefined, it will remove the corresponding header.

    $self->_set_get_multi( 'SomeHeader' => undef() );

If no value is provided, it returns the current value for this header as a L<Module::Generic::Array> object.

=head2 _set_get_one

Sets or gets a header with the provided value. If the value is undefined, the header will be removed.

If no value is provided, it returns the current value as an array object (L<Module::Generic::Array>) or as a scalar object (L<Module::Generic::Scalar>) if it is not a reference.

=head2 _try( object accessor, method, [ arguments ] )

Given an object type, a method name and optional parameters, this attempts to call it.

Apache2 methods are designed to die upon error, whereas our model is based on returning C<undef> and setting an exception with L<Module::Generic::Exception>, because we believe that only the main program should be in control of the flow and decide whether to interrupt abruptly the execution, not some sub routines.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::Request>, L<Apache2::RequestRec>, L<Apache2::RequestUtil>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
