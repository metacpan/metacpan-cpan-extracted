# -*- perl -*-
##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API/Request.pm
## Version v0.4.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/05/30
## Modified 2025/11/02
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::API::Request;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Apache2::API' );
    use parent qw( Module::Generic );
    use vars qw( $ERROR $VERSION $SERVER_VERSION );
    use utf8 ();
    use version;
    use Apache2::Access;
    use Apache2::Const -compile => qw( :common :methods :http );
    use Apache2::Connection ();
    use Apache2::Log ();
    use Apache2::Request;
    use Apache2::RequestRec ();
    use Apache2::RequestUtil ();
    use Apache2::ServerUtil ();
    use Apache2::RequestIO ();
    use Apache2::Log;
    use APR::Pool ();
    use APR::Request ();
    use APR::Socket ();
    use APR::SockAddr ();
    use APR::Request::Cookie;
    use APR::Request::Apache2;
    # For subnet_of() method
    use APR::IpSubnet ();
    use Apache2::API::Request::Params;
    use Apache2::API::Request::Upload;
    use Apache2::API::DateTime;
    use Apache2::API::Query;
    use Apache2::API::Status;
    use Cookie::Jar;
    use DateTime;
    use Encode ();
    use File::Which ();
    use HTTP::AcceptLanguage;
    use JSON ();
    use Module::Generic::HeaderValue;
    use Scalar::Util;
    use URI;
    use URI::Escape;
    our $VERSION = 'v0.4.0';
    our( $SERVER_VERSION, $ERROR );
};

use strict;
use warnings;

my $methods_bit_to_name =
{
    Apache2::Const::M_GET()        => 'GET',
    Apache2::Const::M_POST()       => 'POST',
    Apache2::Const::M_PUT()        => 'PUT',
    Apache2::Const::M_DELETE()     => 'DELETE',
    Apache2::Const::M_OPTIONS()    => 'OPTIONS',
    Apache2::Const::M_TRACE()      => 'TRACE',
    Apache2::Const::M_CONNECT()    => 'CONNECT',
    (Apache2::Const->can('M_PATCH')       ? (Apache2::Const::M_PATCH()       => 'PATCH')       : ()),
    (Apache2::Const->can('M_PROPFIND')    ? (Apache2::Const::M_PROPFIND()    => 'PROPFIND')    : ()),
    (Apache2::Const->can('M_PROPPATCH')   ? (Apache2::Const::M_PROPPATCH()   => 'PROPPATCH')   : ()),
    (Apache2::Const->can('M_MKCOL')       ? (Apache2::Const::M_MKCOL()       => 'MKCOL')       : ()),
    (Apache2::Const->can('M_COPY')        ? (Apache2::Const::M_COPY()        => 'COPY')        : ()),
    (Apache2::Const->can('M_MOVE')        ? (Apache2::Const::M_MOVE()        => 'MOVE')        : ()),
    (Apache2::Const->can('M_LOCK')        ? (Apache2::Const::M_LOCK()        => 'LOCK')        : ()),
    (Apache2::Const->can('M_UNLOCK')      ? (Apache2::Const::M_UNLOCK()      => 'UNLOCK')      : ()),
};

sub init
{
    my $self = shift( @_ );
    my $r;
    $r = shift( @_ ) if( @_ % 2 );
    $self->{request} = $r;
    $self->{checkonly} = 0;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $r ||= $self->{request};
    $self->{accept_charset}     = undef;
    $self->{auth}               = undef;
    $self->{charset}            = undef;
    $self->{client_api_version} = undef;
    $self->{_server_version}    = undef;
    # Which is an Apache2::Request, but inherits everything from Apache2::RequestRec and APR::Request::Apache2
    unless( $self->{checkonly} )
    {
        return( $self->error( "No Apache2::RequestRec was provided." ) ) if( !$r );
        return( $self->error( "Apache2::RequestRec provided ($r) is not an object!" ) ) if( !Scalar::Util::blessed( $r ) );
        return( $self->error( "I was expecting an Apache2::RequestRec, but instead I got \"$r\"." ) ) if( !$r->isa( 'Apache2::RequestRec' ) );
        $self->{request} = $r;
        # Important as few other methods rely on this
        $self->{apr} = APR::Request::Apache2->handle( $r );
        my $headers = $self->headers;
        # rfc 6750 <https://tools.ietf.org/html/rfc6750>
        my $auth = $headers->{Authorization};
        $self->auth( $auth ) if( length( $auth ) );
        # Content-Type: application/json; charset=utf-8
        my $ctype_raw = $self->content_type;
        # Accept: application/json; version=1.0; charset=utf-8
        my $accept_raw = $self->accept;
        # Returns an array of Module::Generic::HeaderValue objects
        my $accept_all = $self->acceptables;
        my( $ctype_def, $ctype );

        if( defined( $ctype_raw ) && CORE::length( $ctype_raw // '' ) )
        {
            $ctype_def = Module::Generic::HeaderValue->new_from_header( $ctype_raw );
            $ctype = lc( $ctype_def->value->first // '' );
            $self->type( $ctype );
            my $enc = $ctype_def->param( 'charset' );
            $self->charset( $enc ) if( defined( $enc ) && length( $enc ) );
        }

        if( defined( $accept_all ) && !$accept_all->is_empty )
        {
            my $accept_def = $accept_all->first;
            $self->accept_type( $accept_def->value->first );
            $self->client_api_version( $accept_def->param( 'version' ) );
            $self->accept_charset( $accept_def->param( 'charset' ) );
        }

        my $json = $self->json;
        my $payload = $self->data;
        # An error occurred while reading the payload, because even empty, data would return an empty string.
        return( $self->pass_error ) if( !defined( $payload ) );
        if( defined( $ctype ) && 
            $ctype eq 'application/json' && 
            CORE::length( $payload ) )
        {
            my $json_data = '';
            # try-catch
            local $@;
            eval
            {
                $json_data = $json->decode( $payload );
            };
            if( $@ )
            {
                return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "Json data provided is malformed." }) );
            }
            $self->payload( $json_data );
        }
    }
    return( $self );
}

# Tells whether the connection has been aborted or not
sub aborted { return( shift->_try( 'connection', 'aborted' ) ); }

# e.g. text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
sub accept { return( shift->headers->{ 'Accept' } ); }

sub accept_charset { return( shift->_set_get_scalar( 'accept_charset', @_ ) ); }

# e.g. gzip, deflate, br
sub accept_encoding { return( shift->headers->{ 'Accept-Encoding' } ); }

# e.g.: en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2
sub accept_language { return( shift->headers->{ 'Accept-Language' } ); }

sub accept_type { return( shift->_set_get_scalar( 'accept_type', @_ ) ); }

sub accept_version { return( shift->client_api_version( @_ ) ); }

sub acceptable
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $ref = scalar( @_ ) == 1
            ? Scalar::Util::reftype( $_[0] ) eq 'ARRAY'
                ? shift( @_ )
                : [ @_ ]
            : [ @_ ];
        $self->{acceptable} = $self->new_array( $ref );
    }
    if( !$self->{acceptable} )
    {
        my $all = $self->acceptables;
        my $list = [];
        for( @$all )
        {
            push( @$list, $_->value->first );
        }
        $self->{acceptable} = $self->new_array( $list );
    }
    return( $self->{acceptable} );
}

sub acceptables
{
    my $self = shift( @_ );
    return( $self->{acceptables} ) if( $self->{acceptables} );
    my $accept_raw = $self->accept;
    if( $accept_raw )
    {
        $self->_load_class( 'Module::Generic::HeaderValue' ) || return( $self->pass_error );
        # Typical value from Ajax call: application/json, text/javascript, */*
        my $all = Module::Generic::HeaderValue->new_from_multi( $accept_raw ) ||
            return( $self->pass_error( Module::Generic::HeaderValue->error ) );
        $self->{acceptables} = $all;
    }
    return( $self->{acceptables} );
}

# The allowed methods, GET, POST, PUT, OPTIONS, HEAD, etc
sub allowed { return( shift->_try( 'request', 'allowed', @_ ) ); }

sub allow_methods { return( shift->_try( 'request', 'allow_methods', @_ ) ); }

sub allow_methods_list
{
    my $self = shift( @_ );
    my $r = $self->request;
    my $mask = $r->allowed;
    my $names =
    [
        map  { $methods_bit_to_name->{ $_ } }
        grep { $mask & (1 << $_) }
        keys( %$methods_bit_to_name )
    ];
    # Mirror Apache behavior: if GET is allowed, HEAD is implied.
    push( @$names, 'HEAD' ) if( $mask & ( 1 << Apache2::Const::M_GET ) );
    return( $names );
}

sub allow_options { return( shift->_try( 'request', 'allow_options', @_ ) ); }

sub allow_overrides { return( shift->_try( 'request', 'allow_overrides', @_ ) ); }

# APR::Request::Apache2->handle( $r );
sub apr { return( shift->_set_get_object( { field => 'apr', no_init => 1 }, 'APR::Request', @_ ) ); }

# sub args { return( shift->_try( 'request', 'args', @_ ) ); }
# Better yet, use APR::Body->args
sub args { return( shift->_try( 'apr', 'args', @_ ) ); }

sub args_status { return( shift->_try( 'args_status', 'args', @_ ) ); }

sub as_string { return( shift->_try( 'request', 'as_string' ) ); }

sub auth { return( shift->_set_get_scalar( 'auth', @_ ) ); }

sub auth_headers { return( shift->_try( 'request', 'note_auth_failure', @_ ) ); }

sub auth_headers_basic { return( shift->_try( 'request', 'note_basic_auth_failure', @_ ) ); }

sub auth_headers_digest { return( shift->_try( 'request', 'note_digest_auth_failure', @_ ) ); }

sub auth_name { return( shift->_try( 'request', 'auth_name', @_ ) ); }

# with mod_perl2, we need to call ap_auth_type() rather than auth_type()
sub auth_type { return( shift->_try( 'request', 'ap_auth_type', @_ ) ); }

sub authorization { return( shift->headers( 'Authorization', @_ ) ); }

# Must manually update the counter
# $r->connection->keepalives($r->connection->keepalives + 1);
# See Apache2::RequestRec
sub auto_header 
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        return( $self->request->assbackwards( $v ? 0 : 1 ) );
    }
    return( $self->request->assbackwards );
}

# my( $rc, $passwd ) = $req->basic_auth_passwd;
sub basic_auth_passwd { return( shift->_try( 'request', 'get_basic_auth_pw' ) ); }

{
    no warnings 'once';
    *basic_auth_pwd = \&basic_auth_passwd;
    *basic_auth_pw = \&basic_auth_passwd;
}

# See APR::Request
# sub body { return( shift->_try( 'request', 'body', @_ ) ); }
sub body { return( shift->_try( 'apr', 'body', @_ ) ); }

sub body_status { return( shift->_try( 'apr', 'body_status', @_ ) ); }

sub brigade_limit { return( shift->_try( 'apr', 'brigade_limit', @_ ) ); }

sub call { return( shift->_try( 'request', @_ ) ); }

sub charset { return( shift->_set_get_scalar( 'charset', @_ ) ); }

sub checkonly { return( shift->_set_get_scalar( 'checkonly', @_ ) ); }

sub child_terminate { return( shift->_try( 'request', 'child_terminate' ) ); }

sub client_api_version
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        unless( ref( $v ) eq 'version' )
        {
            $v = version->parse( $v );
        }
        $self->{client_api_version} = $v;
    }
    return( $self->{client_api_version} );
}

# Close the client connection
# APR::Socket->close is not implemented; left undone
# So this is a successful work around
sub close
{
    my $self = shift( @_ );
    # Using APR::Socket to get the fileno
    my $fd = $self->socket->fileno;
    require IO::File;
    my $sock = IO::File->new;
    if( $sock->fdopen( $fd, 'w' ) )
    {
        return( $sock->close );
    }
    else
    {
        return(0);
    }
}

sub code { return( shift->_try( 'request', 'status', @_ ) ); }

# Apache2::Connection
sub connection { return( shift->_try( 'request', 'connection' ) ); }

sub connection_id { return( shift->_try( 'connection', 'id' ) ); }

sub content { return( ${ shift->request->slurp_filename } ); }

sub content_encoding { return( shift->_try( 'request', 'content_encoding', @_ ) ); }

sub content_languages { return( shift->_try( 'request', 'content_languages', @_ ) ); }

sub content_length { return( shift->headers( 'Content-Length' ) ); }

sub content_type
{
    my $self = shift( @_ );
    my $ct = $self->headers( 'Content-Type' );
    return( $ct ) if( !scalar( @_ ) );
    $self->error( "Warning only: caller is trying to use ", ref( $self ), " to set the content-type. Use Apache2::API::Response for that instead." ) if( @_ );
    return( $self->request->content_type( @_ ) );
}

# To get individual cookie sent. See APR::Request::Cookie
# APR::Request::Cookie
# sub cookie { return( shift->cookies->get( @_ ) ); }
sub cookie
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    # An erro has occurred if this is undef
    my $jar = $self->cookies || return( $self->pass_error );
    # Cookie::Jar might return undef if there was no match
    my $v = $jar->get( $name );
    return( $v ) unless( $v );
    return( $v->value );
}

# To get all cookies; then we can fetch then with $jar->get( 'this_cookie' ) for example
# sub cookies { return( shift->request->jar ); }
# https://grokbase.com/t/modperl/modperl/06c91r49n4/apache2-cookie-apr-request-cookie
# sub cookies { return( APR::Request::Apache2->handle( shift->request->pool )->jar ); }

# my $req = APR::Request::Apache2->handle( $self->r );
# my %cookies;
# if ( $req->jar_status =~ /^(?:Missing input data|Success)$/ ) {
# my $jar = $req->jar;
# foreach my $key ( keys %$jar ) {
# $cookies{$key} = $jar->get($key);
# }
# }
# 
# # Send warning with headers to explain bad cookie
# else {
# warn( "COOKIE ERROR: "
# . $req->jar_status . "\n"
# . Data::Dumper::Dumper( $self->r->headers_in() ) );
# }

sub cookies
{
    my $self = shift( @_ );
    return( $self->{_jar} ) if( $self->{_jar} );
    my $jar = Cookie::Jar->new( request => $self->request, debug => $self->debug ) ||
        return( $self->error( "An error occurred while trying to instantiate a new Cookie::Jar object: ", Cookie::Jar->error ) );
    $jar->fetch;
    $self->{_jar} = $jar;
    return( $jar );
}

sub data
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $r    = $self->request;
    # Mutator mode
    if( $opts->{data} )
    {
        if( !defined( $opts->{data} ) ||
            !CORE::length( $opts->{data} // '' ) )
        {
            warn( "Warning only: you are setting a zero-length payload data." ) if( $self->_is_warnings_enabled( 'Apache2::API' ) );
        }
        $self->pnotes( REQUEST_BODY => $opts->{data} );
        # Optional: allow caller to mark as processed explicitly
        if( $opts->{processed} )
        {
            $self->pnotes( REQUEST_BODY_PROCESSED => 1 );
        }
        return( $opts->{data} );
    }

    # Accessor mode
    my $payload = $self->pnotes( 'REQUEST_BODY' );
    return( $payload ) if( $self->pnotes( 'REQUEST_BODY_PROCESSED' ) );
    my $ctype    = $self->type;
    my $max_size = 0;
    # The request payload has been set or processed, so we re-use it.
    if( defined( $payload ) )
    {
        # We do not set the 'REQUEST_BODY_PROCESSED' flag, because 1) we do not need to, and 2) it is an indicator if the request payload was processed at all. For example, one could force a different request payload by calling data() in mutator mode. It may be useful to know by checking this flag.
        return( $payload );
    }

    if( $opts->{max_size} )
    {
        $max_size = $opts->{max_size};
    }
    elsif( my $val = $self->max_size )
    {
        $max_size = $val;
    }
    elsif( $r->dir_config( 'PAYLOAD_MAX_SIZE' ) )
    {
        $max_size = $r->dir_config( 'PAYLOAD_MAX_SIZE' );
    }

    $payload   = '';
    # Header Content-Length value
    my $nbytes = $self->length;
    # With Content-Length: read exactly $nbytes bytes
    if( int( $nbytes // 0 ) > 0 )
    {
        if( $max_size && $nbytes > $max_size )
        {
            return( $self->error({ code => Apache2::Const::HTTP_REQUEST_ENTITY_TOO_LARGE, message => "Total data submitted (" . $self->length . " bytes) is bigger than the limit you set in Apache configuration ($max_size)." }) );
        }

        # $r->read( $payload, $nbytes );
        my $to_read = int( $nbytes );
        my $read    = 0;
        # try-catch
        local $@;

        while( $read < $to_read )
        {
            my $chunk = '';
            my $want  = $to_read - $read;
            # Cap chunk size
            $want     = 65536 if( $want > 65536 );
            my $n = eval{ $r->read( $chunk, $want ); };
            # APR::Error
            if( $@ )
            {
                return( $self->error( "Error trying to read $want bytes from the APR::Bucket: $@" ) );
            }
            # EOF/abort
            last unless( $n );
            $payload .= $chunk;
            $read    += $n;
        }
    }
    # No Content-Length: stream until read() returns 0
    elsif( defined( $ctype ) && 
           lc( $ctype ) eq 'application/json' )
    {
        my $total = 0;
        while(1)
        {
            # try-catch
            local $@;
            my $chunk = '';
            my $n = eval{ $r->read( $chunk, 8192 ); };
            # APR::Error
            if( $@ )
            {
                return( $self->error( "Error trying to read 8192 bytes from the APR::Bucket: $@" ) );
            }
            last unless( $n );
            $payload .= $chunk;
            $total   += $n;

            if( $max_size && $total > $max_size )
            {
                return( $self->error({
                    code    => Apache2::Const::HTTP_REQUEST_ENTITY_TOO_LARGE,
                    message => "Total payload submitted ($total bytes) exceeds configured limit ($max_size)."
                }) );
            }
        }
    }

    # try-catch
    local $@;
    eval
    {
        # This is set during the init() phase
        my $charset = $self->charset;
        if( defined( $charset ) && $charset )
        {
            $payload = Encode::decode( $charset, $payload, Encode::FB_CROAK );
        }
        # We only UTF-8 decode it if it is a pure text file.
        # If no $ctype is defined, the default should be application/octet-stream
        elsif( defined( $ctype ) && $ctype =~ m,^text/,i )
        {
            $payload = Encode::decode_utf8( $payload, Encode::FB_CROAK );
        }
    };
    if( $@ )
    {
        return( $self->error({
            code    => Apache2::Const::HTTP_BAD_REQUEST,
            message => "Error while decoding payload received from http client: $@"
        }) );
    }
    # Cache the request body so other handlers can access it too.
    $self->pnotes( REQUEST_BODY => $payload );
    $self->pnotes( REQUEST_BODY_PROCESSED => 1 );
    return( $payload );
}

sub datetime { return( Apache2::API::DateTime->new( debug => shift->debug ) ); }

sub decode
{
    my $self = shift( @_ );
    return( APR::Request::decode( shift( @_ ) ) );
}

# Do not track: 1 or 0
sub dnt { return( shift->env( 'HTTP_DNT', @_ ) ); }

sub encode
{
    my $self = shift( @_ );
    return( APR::Request::encode( shift( @_ ) ) );
}

sub discard_request_body { return( shift->_try( 'request', 'discard_request_body' ) ); }

sub document_root { return( shift->_try( 'request', 'document_root', @_ ) ); }

sub document_uri { return( shift->env( 'document_uri', @_ ) ); }

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

sub err_headers_out { return( shift->_headers( 'err_headers_out', @_ ) ); }

sub filename { return( shift->_try( 'request', 'filename' ) ); }

# APR::Finfo
sub finfo { return( shift->_try( 'request', 'finfo' ) ) }

# example: CGI/1.1
sub gateway_interface { return( shift->env( 'GATEWAY_INTERFACE', @_ ) ); }

# $handlers_list = $r->get_handlers($hook_name);
# https://perl.apache.org/docs/2.0/api/Apache2/RequestUtil.html#C_get_handlers_
sub get_handlers { return( shift->_try( 'request', 'get_handlers', @_ ) ); }

# e.g. get_status_line( 404 ) would return 404 Not Found
sub get_status_line { return( shift->_try( 'request', 'get_status_line', @_ ) ); }

sub global_request { return( Apache2::RequestUtil->request ); }

sub has_auth { return( shift->_try( 'request', 'some_auth_required' ) ); }

sub header_only { return( shift->request->header_only ); }

# sub headers { return( shift->request->headers_in ); }
sub headers { return( shift->_headers( 'headers_in', @_ ) ); }

sub headers_as_hashref
{
    my $self = shift( @_ );
    my $ref = {};
    my $h = $self->headers;
    while( my( $k, $v ) = each( %$h ) )
    {
        if( CORE::exists( $ref->{ $k } ) )
        {
            # if( ref( $ref->{ $k } ) eq 'ARRAY' )
            if( $self->_is_array( $ref->{ $k } ) )
            {
                CORE::push( @{$ref->{ $k }}, $v );
            }
            else
            {
                my $old = $ref->{ $k };
                $ref->{ $k } = [];
                CORE::push( @{$ref->{ $k }}, $old, $v );
            }
        }
        else
        {
            $ref->{ $k } = $v;
        }
    }
    return( $ref );
}

sub headers_as_json
{
    my $self = shift( @_ );
    my $ref = $self->headers_as_hashref;
    my $json;
    # try-catch
    local $@;
    eval
    {
        # Non-utf8 encoded, because this resulting data may be sent over http or stored in a database which would typically encode data on the fly, and double encoding will damage data
        $json = $self->json->encode( $ref );
    };
    if( $@ )
    {
        return( $self->error( "An error occured while encoding the headers hash reference into json: $@" ) );
    }
    return( $json );
}

sub headers_in { return( shift->request->headers_in ); }

sub headers_out { return( shift->request->headers_out ); }

sub hostname { return( shift->_try( 'request', 'hostname' ) ); }

sub http_host { return( shift->uri->host ); }

sub id { return( shift->_try( 'connection', 'id' ) ); }

sub if_modified_since
{
    my $self = shift( @_ );
    my $v = $self->headers( 'If-Modified-Since' ) || return;
    return( $self->datetime->str2datetime( $v ) );
}

sub if_none_match { return( shift->headers( 'If-None-Match', @_ ) ); }

sub input_filters { return( shift->_try( 'request', 'input_filters' ) ); }

# <https://perl.apache.org/docs/1.0/guide/debug.html#toc_Detecting_Aborted_Connections>
sub is_aborted
{
    my $self = shift( @_ );
    my $r = $self->request ||
        return( $self->error( "No Apache2::RequestRec object set anymore!" ) );
    # try-catch
    local $@;
    eval
    {        
        $r->print( "\0" );
        $r->rflush;
    };
    return(1) if( $@ && $@ =~ /Broken pipe/i );
    return( $r->connection->aborted );
}

sub is_auth_required { return( shift->_try( 'request', 'some_auth_required' ) ); }

# A HEAD request maybe ?
sub is_header_only { return( shift->request->header_only ); }

# To find out if a PerlOptions is activated like +GlobalRequest or -GlobalRequest
sub is_perl_option_enabled { return( shift->_try( 'request', 'is_perl_option_enabled', @_ ) ); }

sub is_initial_req { return( shift->_try( 'request', 'is_initial_req', @_ ) ); }

sub is_secure { return( shift->env( 'HTTPS' ) eq 'on' ? 1 : 0 ); }

sub json
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $j = JSON->new->relaxed;
    my $equi =
    {
        ordered => 'canonical',
        sorted => 'canonical',
        sort => 'canonical',
    };

    foreach my $opt ( keys( %$opts ) )
    {
        my $ref;
        $ref = $j->can( exists( $equi->{ $opt } ) ? $equi->{ $opt } : $opt ) || do
        {
            warn( "Unknown JSON option '${opt}'\n" ) if( $self->_warnings_is_enabled );
            next;
        };
        $ref->( $j, $opts->{ $opt } );
    }
    return( $j );
}

sub keepalive { return( shift->_try( 'connection', 'keepalive', @_ ) ); }

sub keepalives { return( shift->_try( 'connection', 'keepalives', @_ ) ); }

sub languages
{
    my $self = shift( @_ );
    my $lang = $self->accept_language || return( [] );
    my $al = HTTP::AcceptLanguage->new( $lang );
    my( @langs ) = $al->languages;
    return( $self->new_array( \@langs ) );
}

sub length { return( shift->headers->{'Content-Length'} ); }

sub local_addr { return( shift->_try( 'connection', 'local_addr' ) ); }

sub local_host { return( shift->_try( 'connection', 'local_host' ) ); }

sub local_ip { return( shift->_try( 'connection', 'local_ip' ) ); }

sub location { return( shift->_try( 'request', 'location' ) ); }

# Would return a Apache2::Log::Request
sub log { return( shift->_try( 'request', 'log', @_ ) ); }

sub log_error { return( shift->_try( 'request', 'log_error', @_ ) ); }

sub max_size { return( shift->_set_get_number( 'max_size', @_ ) ); }

sub method { return( shift->_try( 'request', 'method', @_ ) ); }

# This takes a method name, notwithstanding its case, and returns the corresponding Apache2::Const value.
sub method_bit
{
    my $self = shift( @_ );
    my $meth = shift( @_ ) ||
        return( $self->error( "No HTTP method name was provided." ) );
    $meth = uc( $meth );
    my @keys = keys( %$methods_bit_to_name );
    my $name2bit = {};
    @$name2bit{ @$methods_bit_to_name{ @keys } } = @keys;
    unless( exists( $name2bit->{ $meth } ) )
    {
        return( $self->error( "The HTTP method provided (${meth}) is not supported." ) );
    }
    return( $name2bit->{ $meth } );
}

# Provided with an Apache constant representing a method bitwise value, and this returns its name
sub method_name
{
    my $self = shift( @_ );
    my $bit  = shift( @_ );
    unless( $self->_is_integer( $bit ) )
    {
        return( $self->error( "Value provided (", ( $bit // 'undef' ), ") is not a bitwise value." ) );
    }
    $bit = 0 + $bit;
    if( exists( $methods_bit_to_name->{ $bit } ) )
    {
        return( $methods_bit_to_name->{ $bit } );
    }
    return( $self->error( "No method name is associated with bit value ${bit}" ) );
}

sub method_number { return( shift->_try( 'request', 'method_number', @_ ) ); }

sub mod_perl { return( shift->env( 'MOD_PERL', @_ ) ); }

# example: mod_perl/2.0.11
# sub mod_perl_version { return( version->parse( ( shift->mod_perl =~ /^mod_perl\/(\d+\.[\d\.]+)/ )[0] ) ); }
sub mod_perl_version { require mod_perl2; return( version->parse( $mod_perl2::VERSION ) ); }

sub mtime { return( shift->_try( 'request', 'mtime' ) ); }

sub next { return( shift->_try( 'request', 'next' ) ); }

# Tells the client not to cache the response
sub no_cache { return( shift->_try( 'request', 'no_cache', @_ ) ); }

# Takes an APR::Table object
# There is also one available via the connection object
# It returns an APR::Table object which can be used like a hash ie foreach my $k ( sort( keys( %{$table} ) ) )
sub notes
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $hash = shift( @_ );
        return( $self->error( "Value provided is not a hash reference." ) ) if( ref( $hash ) ne 'HASH' );
        #my $pool = $self->pool->new;
        #my $table = APR::Table::make( $pool, 1 );
        #foreach my $k ( sort( keys( %$hash ) ) )
        #{
        #   $table->set( $k => $hash->{ $k } );
        #}
        my $r = $self->request;
        #$r->notes( $table );
        $r->pnotes( $hash );
    }
    return( $self->request->notes );
}

sub output_filters { return( shift->_try( 'request', 'output_filters', @_ ) ); }

sub param
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return;
    my $r = Apache2::API::Request::Params->new( $self->request );
    if( @_ )
    {
        return( $r->param( $name, @_ ) );
    }
    else
    {
        my $val = $r->param( $name );
        my $up = $r->upload( $name );
        # Return the Net:::API::REST::Request::Upload object if it is one
        return( $up ) if( Scalar::Util::blessed( $up ) );
        return( $val );
    }
}

sub params
{
    my $self = shift( @_ );
    return( $self->query ) if( $self->method eq 'GET' );
    # my $r = Apache2::Request->new( $self->request );
    my $r = Apache2::API::Request::Params->new( request => $self->request );
    # https://perl.apache.org/docs/1.0/guide/snippets.html#Reusing_Data_from_POST_request
    # my %params = $r->method eq 'POST' ? $r->content : $r->args;
    # Data are in pure utf8; not perl's internal, so it is up to us to decode them
    my( @params ) = $r->param;
    my( @uploads ) = $r->upload;
    my $upload_fields = {};
    # To make it easy to check if it exists
    if( scalar( @uploads ) )
    {
        @$upload_fields{ @uploads } = ( 1 ) x scalar( @uploads );
    }
    my $form = {};
    #my $io = IO::File->new( ">/tmp/form_data.txt" );
    #my $io2 = IO::File->new( ">/tmp/form_data_after_our_decoding.txt" );
    #my $raw = IO::File->new( ">/tmp/raw_form_data.txt" );
    #$io->binmode( ':utf8' );
    #$io2->binmode( ':utf8' );
    foreach my $k ( @params )
    {
        my( @values ) = $r->param( $k );
        #$raw->print( "$k => " );
        #$io->print( "$k => " );
        my $name = utf8::is_utf8( $k ) ? $k : Encode::decode_utf8( $k );
        #$io2->print( "$name => " );
        $form->{ $name } = scalar( @values ) > 1 ? \@values : $values[0];
        if( CORE::exists( $upload_fields->{ $name } ) )
        {
            my $up = $r->upload( $name );
            if( !$up )
            {
                CORE::warn( "Error: could not get the Apache2::API::Params::Upload object for this upload field \"$name\".\n" );
                next;
            }
            else
            {
                $form->{ $name } = $up;
            }
        }
        elsif( ref( $form->{ $name } ) )
        {
            #$raw->print( "[\n" );
            #$io->print( "[\n" );
            #$io2->print( "[\n" );
            for( my $i = 0; $i < scalar( @{$form->{ $name }} ); $i++ )
            {
                #$raw->print( "\t[$i]: ", $form->{ $name }->[ $i ], "\n" );
                #$io->print( "\t[$i]: ", $form->{ $name }->[ $i ], "\n" );
                $form->{ $name }->[ $i ] = utf8::is_utf8( $form->{ $name }->[ $i ] ) ? $form->{ $name }->[ $i ] : Encode::decode_utf8( $form->{ $name }->[ $i ] );
                #$io2->print( "\t[$i]: ", $form->{ $name }->[ $i ], "\n" );
            }
            #$raw->print( "];\n" );
            #$io->print( "];\n" );
            #$io2->print( "];\n" );
        }
        else
        {
            #$raw->print( $form->{ $name }, "\n" );
            #$io->print( $form->{ $name }, "\n" );
            $form->{ $name } = utf8::is_utf8( $form->{ $name } ) ? $form->{ $name } : Encode::decode_utf8( $form->{ $name } );
            #$io2->print( $form->{ $name }, "\n" );
        }
    }
    #$raw->close;
    #$io->close;
    #$io2->close;
    return( $form );
}

# NOTE: parse_date for compatibility
sub parse_date { return( shift->datetime->parse_date( @_ ) ); }

# example: /bin:/usr/bin:/usr/local/bin
sub path { return( shift->env( 'PATH', @_ ) ); }

sub path_info { return( shift->_try( 'request', 'path_info', @_ ) ); }

sub payload { return( shift->_set_get_hash( 'payload', @_ ) ); }

sub per_dir_config { return( shift->_try( 'rquest', 'per_dir_config' ) ); }

sub pnotes { return( shift->_try( 'request', 'pnotes', @_ ) ); }

sub pool { return( shift->_try( 'connection', 'pool' ) ); }

sub preferred_language
{
    my $self = shift( @_ );
    my $ok_langs = [];
    if( @_ )
    {
        return( $self->error( "I was expecting a list of supported languages as array reference, but instead I received this '", join( "', '", @_ ), "'." ) ) if( !$self->_is_array( $_[0] ) );
        # Make a copy
        $ok_langs = [ @{$_[0]} ];
        # Make sure the languages provided are in web format (e.g. en-GB), not unix format (e.g. en_GB)
        for( my $i = 0; $i < scalar( @$ok_langs ); $i++ )
        {
            $ok_langs->[ $i ] =~ tr/_/-/;
        }
    }
    else
    {
        return( $self->error( "No supported languages list was provided as array reference." ) );
    }
    # No supported languages was provided
    return( '' ) if( !scalar( @$ok_langs ) );
    # The user has not set his/her preferred languages
    my $accept_langs = $self->accept_language || return( '' );
    my $al = HTTP::AcceptLanguage->new( $accept_langs );
    # Get the most suitable one
    my $ok = $al->match( @$ok_langs );
    return( $ok ) if( CORE::length( $ok // '' ) );
    # No match, we return empty. undef is for error only
    return( '' );
}

sub prev { return( shift->_try( 'request', 'prev' ) ); }

sub protocol { return( shift->_try( 'request', 'protocol' ) ); }

sub proxyreq { return( shift->_try( 'request', 'proxyreq', @_ ) ); }

sub psignature { return( shift->_try( 'request', 'psignature', @_ ) ); }

# push_handlers( PerlCleanupHandler => \&handler );
# $ok = $r->push_handlers($hook_name => \&handler);
# $ok = $r->push_handlers($hook_name => ['Foo::Bar::handler', \&handler2]);
# https://perl.apache.org/docs/2.0/api/Apache2/RequestUtil.html#C_push_handlers_
sub push_handlers { return( shift->_try( 'request', 'push_handlers', @_ ) ); }

# Maybe better to APR::Body->args
sub query
{
    my $self = shift( @_ );
    my $qs = $self->query_string;
    my $qq = Apache2::API::Query->new( $qs );
    my %hash = $qq->hash;
    return( \%hash );
}

# Set/get a query string
sub query_string { return( shift->_try( 'request', 'args', @_ ) ); }

# Apache2::RequestIO
sub read { return( shift->_try( 'request', 'read', @_ ) ); }

sub redirect_error_notes { return( shift->env( 'REDIRECT_ERROR_NOTES', @_ ) ); }

sub redirect_query_string { return( shift->env( 'REDIRECT_QUERY_STRING', @_ ) ); }

sub redirect_status { return( shift->env( 'REDIRECT_STATUS', @_ ) ); }

# https://httpd.apache.org/docs/2.4/custom-error.html
sub redirect_url { return( shift->env( 'REDIRECT_URL', @_ ) ); }

sub referer { return( shift->headers->{Referer} ); }

# sub remote_addr { return( shift->connection->remote_ip ); }
sub remote_addr
{
    my $self = shift( @_ );
    # my $vers = $self->server_version;
    my $serv = $self->request;
    # http://httpd.apache.org/docs/2.4/developer/new_api_2_4.html
    # We have to prepend the version with 'v', because it will faill when there is a dotted decimal with 3 numbers, 
    # e.g. 2.4.16 > 2.2 will return false !!
    # but v2.4.16 > v2.2 returns true :(
    # Already contacted the author about this edge case (2019-09-22)
#     if( version->parse( "v$vers" ) > version->parse( 'v2.2' ) )
#     {
#         my $addr;
#         # try-catch
#         local $@;
#         eval
#         {
#             $addr = $serv->useragent_addr;
#         };
#         if( $@ )
#         {
#             warn( "Unable to get the remote addr with the method useragent_addr: $@\n" );
#             return( $self->pass_error );
#         }
#     }
#     else
#     {
#         return( $self->connection->remote_addr );
#     }
    my $c = $self->connection;
    my $coderef = $c->can( 'client_addr' ) // $c->can( 'remote_addr' );
    # try-catch
    local $@;
    my $rv = eval
    {
        $coderef->( $c, shift( @_ ) ) if( @_ );
        return( $coderef->( $c ) );
    };
    if( $@ )
    {
        warn( "Unable to get the remote addr with the method ", ( $c->can( 'client_addr' ) ? 'client_addr' : 'remote_addr' ), ": $@\n" );
        return;
    }
    return( $rv );
}

sub remote_host { return( shift->_try( 'connection', 'get_remote_host', @_ ) ); }

# sub remote_ip { return( shift->connection->remote_ip ); }
sub remote_ip
{
    my $self = shift( @_ );
    # my $vers = $self->server_version;
    my $serv = $self->request;
    # http://httpd.apache.org/docs/2.4/developer/new_api_2_4.html
    # We have to prepend the version with 'v', because it will faill when there is a dotted decimal with 3 numbers, 
    # e.g. 2.4.16 > 2.2 will return false !!
    # but v2.4.16 > v2.2 returns true :(
    # Already contacted the author about this edge case (2019-09-22)
#     if( version->parse( "v$vers" ) > version->parse( 'v2.2' ) )
#     {
#         my $ip;
#         # try-catch
#         local $@;
#         eval
#         {
#             $ip = $serv->useragent_ip;
#         };
#         if( $@ )
#         {
#             warn( "Unable to get the remote ip with the method useragent_ip: $@\n" );
#         }
#         $ip = $self->env( 'REMOTE_ADDR' ) if( !CORE::length( $ip ) );
#         return( $ip ) if( CORE::length( $ip ) );
#         return;
#     }
#     else
#     {
#         return( $self->connection->remote_addr->ip_get );
#     }
    my $c = $self->connection;
    my $coderef = $c->can( 'client_ip' ) // $c->can( 'remote_ip' );
    # try-catch
    local $@;
    my $rv = eval
    {
        $coderef->( $c, shift( @_ ) ) if( @_ );
        my $ip = $coderef->( $c );
        $ip = $self->env( 'REMOTE_ADDR' ) if( !CORE::length( $ip ) );
        return( $ip ) if( CORE::length( $ip ) );
        return( '' );
    };
    if( $@ )
    {
        warn( "Unable to get the remote addr with the method ", ( $c->can( 'client_ip' ) ? 'client_ip' : 'remote_ip' ), ": $@\n" );
        return;
    }
    return( $rv );
}

sub remote_port { return( shift->env( 'REMOTE_PORT', @_ ) ); }

sub request { return( shift->_set_get_object_without_init( 'request', 'Apache2::Request', @_ ) ); }

sub request_scheme { return( shift->env( 'REQUEST_SCHEME', @_ ) ); }

# sub request_time { return( shift->request->request_time ); }
sub request_time
{
    my $self = shift( @_ );
    my $t = $self->request->request_time;
    my $dt = DateTime->from_epoch( epoch => $t );
    # An Apache2::API::DateTime object
    my $fmt = $self->datetime;
    $dt->set_formatter( $fmt );
    return( $dt );
}

sub request_uri { return( shift->env( 'REQUEST_URI', @_ ) ); }

sub requires { return( shift->_try( 'request', 'requires' ) ); }

sub satisfies { return( shift->_try( 'request', 'satisfies' ) ); }

sub script_filename { return( shift->env( 'SCRIPT_FILENAME', @_ ) ); }

sub script_name { return( shift->env( 'SCRIPT_NAME', @_ ) ); }

# Example: https://example.com/cgi-bin/prog.cgi/path/info
sub script_uri { return( URI->new( shift->env( 'SCRIPT_URI', @_ ) ) ); }

# Example: /cgi-bin/prog.cgi/path/info
sub script_url { return( shift->env( 'SCRIPT_URL', @_ ) ); }

# Return Apache2::ServerUtil object
sub server { return( shift->request->server ); }

sub server_addr { return( shift->env( 'SERVER_ADDR', @_ ) ); }

sub server_admin { return( shift->_try( 'server', 'server_admin', @_ ) ); }

sub server_hostname { return( shift->_try( 'server', 'server_hostname', @_ ) ); }

sub server_name { return( shift->_try( 'request', 'get_server_name' ) ); }

sub server_port { return( shift->_try( 'request', 'get_server_port' ) ); }

# Example: HTTP/1.1
sub server_protocol { return( shift->env( 'SERVER_PROTOCOL', @_ ) ); }

sub server_signature { return( shift->env( 'SERVER_SIGNATURE', @_ ) ); }

sub server_software { return( shift->env( 'SERVER_SOFTWARE', @_ ) ); }

# Or maybe the environment variable SERVER_SOFTWARE, e.g. Apache/2.4.18
# sub server_version { return( version->parse( Apache2::ServerUtil::get_server_version ) ); }
sub server_version
{
    my $self = shift( @_ );
    $self->{_server_version} = $SERVER_VERSION if( !CORE::length( $self->{_server_version} ) && CORE::length( $SERVER_VERSION ) );
    $self->{_server_version} = shift( @_ ) if( @_ );
    return( $self->{_server_version} ) if( $self->{_server_version} );
    my $vers = '';
    if( $self->mod_perl )
    {
        # try-catch
        local $@;
        eval
        {
            my $desc = Apache2::ServerUtil::get_server_description();
            if( $desc =~ /\bApache\/([\d\.]+)/ )
            {
                $vers = $1;
            }
        };
        if( $@ )
        {
        }
    }

    # NOTE: to test our alternative approach
    if( !$vers && ( my $apxs = File::Which::which( 'apxs' ) ) )
    {
        $vers = qx( $apxs -q -v HTTPD_VERSION );
        chomp( $vers );
        $vers = '' unless( $vers =~ /^[\d\.]+$/ );
    }
    # Try apache2
    if( !$vers )
    {
        foreach my $bin ( qw( apache2 httpd ) )
        {
            if( ( my $apache2 = File::Which::which( $bin ) ) )
            {
                my $v_str = qx( $apache2 -v );
                if( ( split( /\r?\n/, $v_str ) )[0] =~ /\bApache\/([\d\.]+)/ )
                {
                    $vers = $1;
                    chomp( $vers );
                    last;
                }
            }
        }
    }
    if( $vers )
    {
        $self->{_server_version} = $SERVER_VERSION = version->parse( $vers );
        return( $self->{_server_version} );
    }
    return( '' );
}

# e.g. set_basic_credentials( $user, $password );
sub set_basic_credentials { return( shift->_try( 'request', 'set_basic_credentials', @_ ) ); }

# set_handlers( PerlCleanupHandler => [] );
# $ok = $r->set_handlers($hook_name => \&handler);
# $ok = $r->set_handlers($hook_name => ['Foo::Bar::handler', \&handler2]);
# $ok = $r->set_handlers($hook_name => []);
# $ok = $r->set_handlers($hook_name => undef);
# https://perl.apache.org/docs/2.0/api/Apache2/RequestUtil.html#C_set_handlers_
sub set_handlers { return( shift->_try( 'request', 'set_handlers', @_ ) ); }

sub slurp_filename { return( shift->_try( 'request', 'slurp_filename' ) ); }

# Returns a APR::Socket
# See Apache2::Connection manual page
sub socket { return( shift->_try( 'connection', 'client_socket', @_ ) ); }

sub status { return( shift->_try( 'request', 'status', @_ ) ); }

sub status_line { return( shift->_try( 'request', 'status_line', @_ ) ); }

# NOTE: str2datetime for compatibility
sub str2datetime { return( shift->datetime->str2datetime( @_ ) ); }

# NOTE: str2time for compatibility
sub str2time { return( shift->datetime->str2time( @_ ) ); }

sub subnet_of
{
    my $self = shift( @_ );
    my( $ip, $mask ) = @_;
    my $ipsub;
    # try-catch
    local $@;
    my $error;
    eval
    {
        if( $ip && $mask )
        {
            $ipsub = APR::IpSubnet->new( $self->pool, $ip, $mask );
        }
        elsif( $ip )
        {
            $ipsub = APR::IpSubnet->new( $self->pool, $ip );
        }
        else
        {
            $error = "No ip address or block was provided to evaluate current ip against";
        }
    };
    return( $self->error( $error ) ) if( defined( $error ) );
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to create a APR::IpSubnet object with ip \"$ip\" and mask \"$mask\": $@" ) );
    }
    return( $ipsub->test( $self->remote_addr ) );
}

sub subprocess_env { return( shift->_try( 'request', 'subprocess_env' ) ); }

sub temp_dir { return( shift->_try( 'apr', 'temp_dir', @_ ) ); }

sub the_request { return( shift->_try( 'request', 'the_request' ) ); }

# NOTE: time2datetime for compatibility
sub time2datetime { return( shift->datetime->time2datetime( @_ ) ); }

# NOTE: time2str for compatibility
sub time2str { return( shift->datetime->time2str( @_ ) ); }

sub type
{
    my $self = shift( @_ );
    if( @_ )
    {
        # Something like text/html, text/plain or application/json, etc...
        $self->{type} = shift( @_ );
    }
    elsif( !CORE::length( $self->{type} ) )
    {
        # Content-Type: application/json; charset=utf-8
        my $ctype_raw = $self->content_type;
        if( defined( $ctype_raw ) )
        {
            my $ctype_def = Module::Generic::HeaderValue->new_from_header( $ctype_raw ) ||
                return( $self->pass_error( Module::Generic::HeaderValue->error ) );
            # Accept: application/json; version=1.0; charset=utf-8
            my $ctype = lc( $ctype_def->value->first // '' );
            $self->{type} = $ctype if( $ctype );
            my $enc = $ctype_def->param( 'charset' );
            $enc = lc( $enc ) if( defined( $enc ) );
            $self->charset( $enc );
        }
    }
    return( $self->{type} );
}

sub unparsed_uri
{
    my $self = shift( @_ );
    my $uri = $self->uri;
    my $unparseed_path = $self->request->unparsed_uri;
    my $unparsed_uri = URI->new( $uri->scheme . '://' . $uri->host_port . $unparseed_path );
    return( $unparsed_uri );
}

sub uploads
{
    my $self = shift( @_ );
    my $r = Apache2::API::Request::Params->new( $self->request );
    my( @uploads ) = $r->upload;
    my $objs = $self->new_array;
    foreach my $name ( @uploads )
    {
        my $up = $r->upload( $name );
        if( !$up )
        {
            CORE::warn( "Error: could not get the Apache2::API::Params::Upload object for this upload field \"$name\".\n" );
        }
        else
        {
            CORE::push( @$objs, $up );
        }
    }
    return( $objs );
}

#sub uri { return( URI->new( shift->request->uri( @_ ) ) ); }
# FYI, there is also the APR::URI module, but I could not see the value of it
# https://perl.apache.org/docs/2.0/api/APR/URI.html
sub uri
{
    my $self = shift( @_ );
    my $r = $self->request;
    my $host = $r->get_server_name;
    my $port = $r->get_server_port;
    my $proto = ( $port == 443 ) ? 'https' : 'http';
    my $path = $r->unparsed_uri;
    return( URI->new( "${proto}://${host}:${port}${path}" ) );
}

sub url_decode { return( shift->decode( @_ ) ); }

sub url_encode { return( shift->encode( @_ ) ); }

sub user { return( shift->_try( 'request', 'user' ) ); }

sub user_agent { return( shift->headers->{ 'User-Agent' } ); }

sub _find_bin
{
    my $self = shift( @_ );
    my $bin  = shift( @_ ) || return( '' );
    return( File::Which::which( $bin ) );
}

sub _headers
{
    my $self = shift( @_ );
    my $type = shift( @_ ) ||
        return( $self->error({
            message => "No header type was specified.",
            want => [qw( hash )],
        }) );
    # NOTE: different from the _headers method in Apache2::API::Response, which uses _request
    my $req = $self->request ||
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

sub _try
{
    my $self = shift( @_ );
    my $pack = shift( @_ ) || return( $self->error( "No Apache package name was provided to call method" ) );
    my $meth = shift( @_ ) || return( $self->error( "No method name was provided to try!" ) );
    # my $r = Apache2::RequestUtil->request;
    my $r = $self->request;
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

Apache2::API::Request - Apache2 Incoming Request Access and Manipulation

=head1 SYNOPSIS

    use Apache2::API::Request;
    # $r is the Apache2::RequestRec object
    my $req = Apache2::API::Request->new( request => $r, debug => 1 );
    # or, to test it outside of a modperl environment:
    my $req = Apache2::API::Request->new( request => $r, debug => 1, checkonly => 1 );

    # Tells whether the connection has been aborted or not
    $req->aborted;

    # e.g.: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    my $accept = $req->accept;

    # Returns an array object
    my $all = $req->acceptable;
    $req->acceptable( $array_ref );

    # Returns an array object
    my $all = $req->acceptables;

    my $charset = $req->accept_charset;

    # e.g.: gzip, deflate, br
    my $encoding = $req->accept_encoding;

    # en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2
    my $lang = $req->accept_language;

    my $type = $req->accept_type;

    my $version = $req->accept_version;

    # GET, POST, PUT, OPTIONS, HEAD, etc
    my $methods = $req->allowed;

    # get an APR::Request::Apache2 object
    my $apr = $req->apr;

    # query string as an hash reference
    my $hash_ref = $req->args; # also an APR::Request::Param::Table object

    my $status = $req->args_status;

    # HTTP query
    my $string = $req->as_string;

    my $auth = $req->auth;
    my $auth = $req->authorization;
    my $auth_type = $req->auth_type;

    $req->auto_header(1);

    # returns an APR::Request::Param::Table object similar to APR::Table
    my $body = $req->body;

    my $status = $req->body_status;

    my $limit = $req->brigade_limit;

    my $charset = $req->charset;

    $req->child_terminate;

    my $api_version = $req->client_api_version;

    # close client connection
    $req->close;

    my $status_code = $req->code;

    # Apache2::Connection
    my $conn = $req->connection;
    my $id = $req->connection_id;

    # content of the request filename
    my $content = $req->content;

    my $encoding = $req->content_encoding;

    my $langs_array_ref = $req->content_languages;

    my $len = $req->content_length;

    # text/plain
    my $ct = $req->content_type;

    # Get a Cookie object
    my $cookie = $req->cookie( $name );
    # Cookie::Jar object
    my $jar = $req->cookies;

    # get data string sent by client
    my $data = $req->data;

    my $formatter = $req->datetime;
    my $decoded = $req->decode( $string );

    my $do_not_track = $req->dnt;

    my $encoded = $req->encode( $string );

    $req->discard_request_body(1);

    my $document_root = $req->document_root;
    my $url = $req->document_uri;
    # APR::Table object
    my $hash_ref = $req->env;
    my $headers = $req->err_headers_out;
    # request filename
    my $filename = $req->filename;
    # APR::Finfo object
    my $finfo = $req->finfo;
    # e.g.: CGI/1.1
    my $gateway = $req->gateway_interface;
    my $code_ref = $req->get_handlers( $name );

    # 404 Not Found
    my $str = $req->get_status_line(404);
    my $r = $req->global_request;
    my $is_head = $req->header_only;
    # same
    my $is_head = $req->is_header_only;

    my $content_type = $req->headers( 'Content-Type' );
    # or (since it is case insensitive)
    my $content_type = $req->headers( 'content-type' );
    # or
    my $content_type = $req->headers->{'Content-Type'};
    $req->headers( 'Content-Type' => 'text/plain' );
    # or
    $req->headers->{'Content-Type'} = 'text/plain';
    # APR::Table object
    my $headers = $req->headers;

    my $hash_ref = $req->headers_as_hashref;
    my $json = $req->headers_as_json;
    my $headers = $req->headers_in;
    my $out = $req->headers_out;

    my $hostname = $req->hostname;
    my $uri_host = $req->http_host;

    my $conn_id = $req->id;

    my $if_mod = $req->if_modified_since;
    my $if_no_match = $req->if_none_match;

    my $filters = $req->input_filters;

    my $bool = $req->is_aborted;

    my $enabled = $req->is_perl_option_enabled;
    # running under https?
    my $secure = $req->is_secure;

    # JSON object
    my $json = $req->json;
    my $keepalive = $req->keepalive;
    my $keepalives = $req->keepalives;

    my $ok_languages = $req->languages;
    my $nbytes = $req->length;
    # APR::SockAddr object
    my $addr = $req->local_addr;
    my $host = $req->local_host;
    my $str = $req->local_ip;
    my $loc = $req->location;
    $req->log_error( "Oh no!" );

    # 200kb
    $req->max_size(204800);

    my $http_method = $req->method;
    my $meth_num = $req->method_number;
    # mod_perl/2.0.11
    my $mod_perl = $req->mod_perl;
    my $vers = $req->mod_perl_version;
    my $seconds = $req->mtime;
    my $req2 = $req->next;
    $req->no_cache(1);

    # APR::Table object
    my $notes = $req->notes;
    my $notes = $req->pnotes;

    my $filters = $req->output_filters;
    my $val = $req->param( $name );
    my $hash_ref = $req->params;

    my $dt = $req->parse_date( $http_date_string );

    my $path = $req->path;
    my $path_info = $req->path_info;
    # for JSON payloads
    my $hash_ref = $req->payload;
    my $val = $req->per_dir_config( $my_config_name );
    # APR::Pool object
    my $pool = $req->pool;

    my $best_lang = $req->preferred_language( $lang_array_ref );

    my $req0 = $req->prev;
    my $proto = $req->protocol;
    $req->proxyreq( Apache2::Const::PROXYREQ_PROXY );
    $req->push_handlers( $name => $code_ref );

    # get hash reference from the query string using Apache2::API::Query instead of APR::Body->args
    # To use APR::Body->args, call args() instead
    my $hash_ref = $req->query;
    my $string = $req->query_string;

    my $nbytes = $req->read( $buff, 1024 );
    my $notes = $req->redirect_error_notes;
    my $qs = $req->redirect_query_string;
    my $status = $req->redirect_status;
    my $url = $req->redirect_url;
    my $referrer = $req->referer;

    # APR::SockAddr object
    my $addr = $req->remote_addr;
    my $host = $req->remote_host;
    my $string = $req->remote_ip;
    my $port = $req->remote_port;

    $req->reply( Apache2::Const::FORBIDDEN => { message => "Get away" } );

    # Apache2::RequestRec
    my $r = $req->request;
    my $scheme = $req->request_scheme;
    # DateTime object
    my $dt = $req->request_time;
    my $uri = $req->request_uri;
    my $filename = $req->script_filename;
    my $name = $req->script_name;
    my $uri = $req->script_uri;
    # Apache2::ServerUtil object
    my $server = $req->server;
    my $addr = $req->server_addr;
    my $admin = $req->server_admin;
    my $hostname = $req->server_hostname;
    my $name = $req->server_name;
    my $port = $req->server_port;
    my $proto = $req->server_protocol;
    my $sig = $req->server_signature;
    my $software = $req->server_software;
    my $vers = $req->server_version;
    $req->set_basic_credentials( $user => $password );
    $req->set_handlers( $name => $code_ref );
    my $data = $req->slurp_filename;
    # Apache2::Connection object
    my $socket = $req->socket;
    my $status = $req->status;
    my $line = $req->status_line;

    my $dt = $req->str2datetime( $http_date_string );
    my $rc = $req->subnet_of( $ip, $mask );
    # APR::Table object
    my $env = subprocess_env;

    my $dir = $req->temp_dir;

    my $r = $req->the_request;
    my $dt = $req->time2datetime( $time );
    say $req->time2str( $seconds );

    # text/plain
    my $type = $req->type;
    my $raw = $req->unparsed_uri;

    # Apache2::API::Request::Params
    my $uploads = $req->uploads;
    my $uri = $req->uri;
    my $decoded = $req->url_decode( $url );
    my $encoded = $req->url_encode( $url );
    my $user = $req->user;
    my $agent = $req->user_agent;

=head1 VERSION

    v0.4.0

=head1 DESCRIPTION

The purpose of this module is to provide an easy access to various methods designed to process and manipulate incoming requests.

This is designed to work under modperl.

Normally, one would need to know which method to access across various Apache2 mod perl modules, which makes development more time consuming and even difficult, because of the scattered documentation and even sometime outdated.

This module alleviate this problem by providing all the necessary methods in one place. Also, at the contrary of L<Apache2> modules suit, all the methods here are die safe. When an error occurs, it will always return undef() and the error will be able to be accessed using B<error> object, which is a L<Module::Generic::Exception> object.

For its alter ego to manipulate outgoing HTTP response, use the L<Apache2::API::Response> module.

Throughout this documentation, we refer to C<$r> as the L<Apache request object|Apache2::RequestRec> and C<$req> as an object from this module.

=head1 CONSTRUCTORS

=head2 new

This takes an optional hash or hash reference of options and instantiate a new object.

It takes the following parameters:

=over 4

=item * C<checkonly>

If true, it will not perform the initialisation it would usually do under modperl.

=item * C<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=item * C<max_size>

Optional. This is the maximum size of the data that can be sent to us over HTTP. By default, there is no limit.

=item * C<request>

This is a required parameter to be sent with a value set to a L<Apache2::RequestRec> object

=back

=head1 METHODS

=head2 aborted

Tells whether the connection has been aborted or not, by calling L<Apache2::Connection/aborted>

=head2 accept

Returns the HTTP C<Accept> header value, such as C<text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8>

See also L</headers>

=head2 accept_charset

Sets or gets the acceptable character set. This is computed upon object instantiation by looking at the C<Accept> header:

    Accept: application/json; version=1.0; charset=utf-8

Here, it would be C<utf-8>

=head2 accept_encoding

Returns the HTTP C<Accept-Encoding> header value.

    Accept-Encoding: gzip, deflate;q=1.0, *;q=0.5
    Accept-Encoding: gzip, deflate, br

See also L</headers> and L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding>

=head2 accept_language

Returns the HTTP C<Accept-Language> header value such as C<en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2>

See also L</headers>

=head2 accept_type

Sets or gets the acceptable content type. This is computed upon object instantiation by looking at the C<Accept> header:

    Accept: application/json; version=1.0; charset=utf-8

Here, it would be C<application/json>

=head2 accept_version

Sets or gets the version of the api being queried. This is computed upon object instantiation by looking at the C<Accept> header:

    Accept: application/json; version=1.0; charset=utf-8

Here, it would be C<1.0>

=head2 acceptable

This method parse the request header C<Accept>, by calling L</acceptables>, which could be, for example:

    application/json, text/javascript, */*

And return an L<array object|Module::Generic::Array> of acceptable content types.

    my $all = $req->acceptable;
    my $first = $req->acceptable->first;

You can also sets its array reference by passing either a list of value or an array reference.

=head2 acceptables

This takes the value from the C<Accept> header, splits them using L<Module::Generic::HeaderValue/new_from_multi> and returns an L<array object|Module::Generic::Array> of L<Module::Generic::HeaderValue> objects with their L<value|Module::Generic::HeaderValue/value> and L<param|Module::Generic::HeaderValue/param> methods, which gives access to key-value pairs of possible attributes to this acceptable value.

So, if the C<Accept> header value was C<application/json, text/javascript, */*>, the array object returned would contain 3 L<Module::Generic::HeaderValue> objects with each C<< $hdr->value->first >> method returning:

=over 4

=item 1. C<application/json>

=item 2. C<text/javascript>

=item 3. C<*/*>

=back

=head2 allowed

Gets or sets the allowed methods bitmask such as GET, POST, PUT, OPTIONS, HEAD, etc, by calling L<Apache2::RequestRec/allowed>

It returns a bitvector of the allowed methods.

For example, if the module can handle only C<GET> and C<POST> methods it could start with:

    use Apache2::API;
    unless( $r->method_number == Apache2::Const::M_GET || 
            $r->method_number == Apache2::Const::M_POST )
    {
        $r->allowed( $r->allowed | ( 1 << Apache2::Const::M_GET ) | ( 1 << Apache2::Const::M_POST ) );
        return( Apache2::Const::HTTP_METHOD_NOT_ALLOWED );
    }

See also L</allowed_methods>

=head2 allow_methods

    $req->allow_methods( $reset );
    $req->allow_methods( $reset, @methods );

Provided with a reset boolean and a list of HTTP methods, and this will set the allowed methods such as GET, POST, PUT, OPTIONS, HEAD, etc, by calling L<Apache2::Access/allow_methods>

If the reset boolean passed is a true value, then all the previously allowed methods are removed, otherwise they are left unchanged.

For example, to allow only C<GET> and C<POST>, notwithstanding what was set previously:

    $req->allow_methods( 1, qw( GET POST ) );

It does not return anything. This is used only to set the allowed method. To retrieve them, see L</allowed>

=head2 allow_methods_list

    my $names = $r->allow_methods_list;
    $r->print( "Allowed methods: " . join( ', ', @$methods ) . "\n" ); # GET, POST

Returns an array reference containing the list of HTTP method names currently allowed for the request, as reported by L<Apache2::RequestRec/allowed>

The list is made up of uppercase method names such as C<GET>, C<POST>, C<OPTIONS>. Only methods whose corresponding bit is set in the request’s L<allowed mask|Apache2::RequestRec/allowed> are included.

In addition, this method mirrors Apache’s internal behaviour: if C<GET> is allowed, then C<HEAD> is automatically added to the list, even if it was not explicitly marked as allowed.

This can be used, for instance, to build an C<Allow:> response header for an C<OPTIONS> request or to emit clearer diagnostics.

On success, returns an array reference of strings. On error, it sets an L<error|Module::Generic/error> and returns C<undef> in scalar context and an empty list in list context.

=head2 allow_options

    my $bitmask = $req->allow_options;

Retrieve the bitmask value of Apache configuration directive C<Options> for this request, by calling L<Apache2::Access/allow_options>

You would need to use Apache constants against the returned value.

For example if the configuration for the current request was:

    Options None
    Options Indexes FollowSymLinks

The following applies:

    use Apache2::API;
    $req->allow_options & Apache2::Const::OPT_INDEXES;   # true
    $req->allow_options & Apache2::Const::OPT_SYM_LINKS; # true
    $req->allow_options & Apache2::Const::OPT_EXECCGI;   # false

=head2 allow_overrides

    my $bitmask = $req->allow_overrides;

Retrieve the bitmask value of C<AllowOverride> for this request by calling L<Apache2::Access/allow_overrides>

You would need to use Apache constants against the returned value.

For example if the configuration for the current request was:

    AllowOverride AuthConfig

The following applies:

    use Apache2::API;
    $req->allow_overrides & Apache2::Const::OR_AUTHCFG; # true
    $req->allow_overrides & Apache2::Const::OR_LIMIT; # false

See also L<https://httpd.apache.org/docs/2.4/en/mod/core.html#allowoverride>

=head2 allow_override_opts

    my $bitmask = $req->allow_override_opts;

Retrieve the bitmask value of allowed C<Options> set by C<AllowOverride Options> Apache configuration directive, by calling L<Apache2::Access/allow_override_opts>

You would need to use Apache constants against the returned value.

For example if the configuration for the current request was:

    AllowOverride Options=Indexes,ExecCGI

The following applies:

    use Apache2::API;
    $req->allow_override_opts & Apache2::Const::OPT_EXECCGI; # true
    $req->allow_override_opts & Apache2::Const::OPT_SYM_LINKS; # false

Note that enabling single options was introduced in Apache 2.2. For Apache 2.0 this function returns:

    Apache2::Const::OPT_UNSET | Apache2::Const::OPT_ALL | Apache2::Const::OPT_INCNOEXEC | Apache2::Const::OPT_SYM_OWNER | Apache2::Const::OPT_MULTI

which corresponds to the default value (if not set) for Apache 2.2.

See also L<https://httpd.apache.org/docs/2.4/en/mod/core.html#allowoverride>

=head2 apr

Returns a L<Apache2::API::Request::Param> object used to access Apache mod_perl methods to manipulate request data.

=head2 args

    my $hash_ref = $req->args;
    my @names = $req->args;
    my $first_value = $req->args( $name );
    my @values = $req->args( $name );

    my $table = $req->args;
    # The keys are case-insensitive.
    $table->set( $key => $val );
    $table->unset( $key );
    $table->add( $key, $val );
    $val = $table->get( $key );
    @val = $table->get( $key );
    $table->merge( $key => $val );
    $table_overlay = $table_base->overlay( $table_overlay, $pool );
    $table_overlay->compress( APR::Const::OVERLAP_TABLES_MERGE );

    $table_a->overlap( $table_b, APR::Const::OVERLAP_TABLES_SET );

Get or sets the query string data by calling L<APR::Body/args>

With no arguments, this method returns a tied L<APR::Request::Param::Table> object (or undef if the query string is absent) in scalar context, or the names (in order, with repetitions) of all the parsed query-string arguments in list context.

With the $key argument, in scalar context this method fetches the first matching query-string arg. In list context it returns all matching args.

See also L</query> for the equivalent, but using L<Apache2::API::Query> instead of L<APR::Body/args>

See also L</query_string> to set or get the query string as a string.

=head2 args_status

    my $int = $req->args_status; # should be 0

Returns the final status code of the query-string parser.

=head2 as_string

Returns the HTTP request as a string by calling L<Apache2::RequestUtil/as_string>

=head2 auth

Returns the C<Authorization> header value if any. This ill have been processed upon object initiation phase.

=head2 auth_headers

    $req->auth_headers;

Setup the output headers so that the client knows how to authenticate itself the next time, if an authentication request failed. This function works only for basic and digest authentication, by calling L<Apache2::Access/note_auth_failure>

This method requires C<AuthType> to be set to C<Basic> or C<Digest>. Depending on the setting it will call either L</auth_headers_basic> or L</auth_headers_digest>.

It does not return anything.

=head2 auth_headers_basic

    $req->auth_headers_basic;

Setup the output headers so that the client knows how to authenticate itself the next time, if an authentication request failed. This function works only for basic authentication.

It does not return anything.

=head2 auth_headers_digest

    $req->auth_headers_digest;

Setup the output headers so that the client knows how to authenticate itself the next time, if an authentication request failed. This function works only for digest authentication.

It does not return anything.

=head2 auth_name

    my $auth_name = $req->auth_name();
    my $auth_name = $req->auth_name( $new_auth_name );

Sets or gets the current Authorization realm, i.e. the per directory configuration directive C<AuthName>

The C<AuthName> directive creates protection realm within the server document space. To quote RFC 1945 "These realms allow the protected resources on a server to be partitioned into a set of protection spaces, each with its own authentication scheme and/or authorization database."

The client uses the root URL of the server to determine which authentication credentials to send with each HTTP request. These credentials are tagged with the name of the authentication realm that created them. Then during the authentication stage the server uses the current authentication realm, from C<auth_name>, to determine which set of credentials to authenticate.

=head2 auth_type

    my $auth_type = $req->auth_type();
    my $auth_type = $req->auth_type( $new_auth_type );

Sets or gets the type of authorization required for this request, i.e. the per directory configuration directive C<AuthType>

Normally C<AuthType> would be set to C<Basic> to use the basic authentication scheme defined in RFC 1945, Hypertext Transfer Protocol (HTTP/1.0). However, you could set to something else and implement your own authentication scheme.

=head2 authorization

Returns the HTTP C<authorization> header value. This is similar to L</auth>.

See also L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization>

=head2 auth_type

Returns the authentication type by calling L<Apache2::RequestRec/auth_type>

    my $auth_type = $req->auth_type; # Basic

=head2 auto_header

Given a boolean value, this enables the auto header or not by calling the method L<Apache2::RequestRec/assbackwards>

If this is disabled, you need to make sure to manually update the counter, such as:

    $req->connection->keepalives( $req->connection->keepalives + 1 );

See L<Apache2::RequestRec> for more information on this.

=head2 basic_auth_passwd

    my( $rc, $passwd ) = $req->basic_auth_passwd;

Get the details from the basic authentication, by calling L<Apache2::Access/get_basic_auth_pw>

It returns:

=over 4

=item 1. the value of an Apache constant

This would be C<Apache2::Const::OK> if the password value is set (and assured a correct value in L</user>); otherwise it returns an error code, either C<Apache2::Const::HTTP_INTERNAL_SERVER_ERROR> if things are really confused, C<Apache2::Const::HTTP_UNAUTHORIZED> if no authentication at all seemed to be in use, or C<Apache2::Const::DECLINED> if there was authentication, but it was not C<Basic> (in which case, the handler should presumably decline as well).

=item 2. the password as set in the headers (decoded)

=back

Note that if C<AuthType> is not set, L<Apache2::Access/get_basic_auth_pw> first sets it to C<Basic>.

=head2 body

Returns an L<APR::Request::Param::Table|APR::Request::Param> object containing the C<POST> data parameters of the L<Apache2::Request> object.

    my $body = $req->body;
    my @body_names = $req->body;

If there is no request body, then this would return C<undef>. So, for example, if you do a C<POST> query without any content, this would return C<undef>

An optional name parameter can be passed to return the POST (or other similar query types) data parameter associated with the given name:

    my $foo_body = $req->body("foo");

In scalar context this method fetches the first matching body param.  In list context it returns all matching body params.

This is similar to the C<param> method. The main difference is that modifications to the scalar C<< $req->body() >> table affect the underlying C<apr_table_t> attribute in C<apreq_request_t>, so their impact will be noticed by all C<libapreq2> applications during this request.

Contrary to perl hash, this uses L<APR::Table> and the order in the hash is preserved, so you could do:

    my @body_names = $req->body;
    my @body_names = %$body;

would yield the same thing.

This will throw an L<APR::Request::Error> object whenever L</body_status> returns a non-zero value.

Check L<Apache2::Request> and L<APR::Table> for more information.

=head2 body_status

    my $int = $req->body_status; # should return 0

Returns the final status code of the body parser.

=head2 brigade_limit

    my $int = $req->brigade_limit;
    $req->brigade_limit( $int );

Get or set the brigade_limit for the current parser. This limit determines how many bytes of a file upload that the parser may spool into main memory. Uploads exceeding this limit are written directly to disk.

See also L</temp_dir>

=head2 call

Provided with an Apache2 API method name, and optionally with some additional arguments, and this will call that Apache2 method and return its result.

This is designed to allow you to call arbitrary Apache2 method that, possibly, are not covered here.

For example:

    my $bitmask = $req->call( 'allow_override_opts' );

It returns whatever value this call returns.

=head2 charset

Returns the charset, if any, found in the HTTP request received and processed upon initialisation of this module object.

So for example, if the HTTP request C<Content-type> is

    Content-Type: application/json; charset=utf-8

Then, L</charset> would return C<utf-8>

See also L</type> to retrieve only the content type, i.e without other information such as charset.

See also L</client_api_version> which would contain the requested api version, if any.

See also L<charset> for the charset provided, if any. For example C<utf-8>

=head2 checkonly

This is also an object initialisation property.

If true, this will discard the normal processing of incoming HTTP request under modperl.

This is useful and intended when testing this module offline.

=head2 child_terminate

Terminate the current worker process as soon as the current request is over, by calling L<Apache2::RequestRec/child_terminate>

This is not supported in threaded MPMs.

See L<Apache2::RequestUtil> for more information.

=head2 client_api_version

Returns the client api version requested, if provided. This is set during the object initialisation phase.

An example header to require api version C<1.0> would be:

    Accept: application/json; version=1.0; charset=utf-8

In this case, this would return C<1.0>

=head2 close

This close the client connection, by calling L<Apache2::Connection/socket>, which returns a L<APR::Socket>

This is not implemented in by L<APR::Socket>, so this is an efficient work around.

If the socket is writable, it is closed and returns the value from closing it, otherwise returns C<0>

However, a word of caution, you most likely do not need or want to close manually the client connection and instea have your method return Apache2::Const::OK or any other constant matching the HTTP code you want to return.

=head2 code

Sets or gets the response status code, by calling L<Apache2::RequestRec/status>

From the L<Apache2::RequestRec> documentation:

Usually you will set this value indirectly by returning the status code as the handler's function result. However, there are rare instances when you want to trick Apache into thinking that the module returned an C<Apache2::Const::OK> status code, but actually send the browser a non-OK status. This may come handy when implementing an HTTP proxy handler. The proxy handler needs to send to the client, whatever status code the proxied server has returned, while returning C<Apache2::Const::OK> to Apache. e.g.:

    $req->status( $some_code );
    return( Apache2::Const::OK );

=head2 connection

Returns a L<Apache2::Connection> object.

=head2 connection_id

Returns the connection id; unique at any point in time by calling L<Apache2::Connection/id>.

See L<Apache2::Connection> for more information.

=head2 content

Returns the content of the file specified with C<< $req->filename >>. It calls L<Apache2::RequestRec/slurp_filename>, but instead of returning a scalar reference, which L<Apache2::RequestRec/slurp_filename> does, it returns the data itself.

See L</slurp_filename> to get a scalar reference instead.

=head2 content_encoding

Returns the value of the C<Content-Encoding> HTTP response header.

See also L</headers>

=head2 content_languages

    my $array_ref = $req->content_languages();
    my $array_ref = $req->content_languages( $array_reference );

Sets or gets the value of the C<Content-Language> HTTP header, by calling L<Apache2::RequestRec/content_languages>

Content languages are string like C<en> or C<fr>.

If a new value is provided, it must be an array reference of language codes.

It returns the language codes as an array reference.

=head2 content_length

Returns the length in byte of the request body, by getting the header C<Content-Length> value.

See also L</headers>

=head2 content_type

Retrieves the value of the C<Content-type> header value. See L<Apache2::RequestRec> for more information.

For example:

    application/json; charset=utf-8

See also L</type> to retrieve only the content type, i.e without other information such as charset.

See also L</client_api_version> which would contain the requested api version, if any.

See also L<charset> for the charset provided, if any. For example C<utf-8>

=head2 cookie

Returns the current value for the given cookie name, which may be C<undef> if nothing is found.

This works by calling the L</cookies> method, which returns a L<cookie jar object|Cookie::Jar>.

=head2 cookies

Returns a L<Cookie::Jar> object acting as a jar with various methods to access, manipulate and create cookies.

=head2 data

This method reads the data sent by the client. It can be used as an accessor, and it will return a cached data, if any, or read the data from L<APR::Bucket>, or it can be used as a mutator to artificially set a payload.

Internally it uses L<Apache2::RequestUtil/pnotes> to cache the processed request body and stores it in C<REQUEST_BODY>, and set the shared property C<REQUEST_BODY_PROCESSED> to C<1>. Thus, the processed raw request body is always for other handlers who call C<data>.

It takes an optional hash or hash reference of the following options:

=over 4

=item * C<data>

When provided, this will set the request body to the value provided.

=item * C<max_size>

The maximum size of the data that can be transmitted to us over HTTP. By default, there is no limit.

=back

Finally, if a charset is specified, this will also decode it from its encoded charset into perl internal utf8.

This is specifically designed for C<JSON> payload.

It returns a string of data upon success, or sets an L<error|Module::Generic/error> and return C<undef> or an empty list depending on the context.

You can also set a maximum size to read by setting the attribute C<PAYLOAD_MAX_SIZE> in Apache configuration file.

For example:

    <Directory /home/john/www>
        PerlOptions +GlobalRequest
        SetHandler modperl
        # package inheriting from Apache2::API
        PerlResponseHandler My::API
        # 2Mb upload limit
        PerlSetVar PAYLOAD_MAX_SIZE 2097152
    </Directory>

This is just an example and not a recommandation. Your mileage may vary.

=head2 datetime

Returns a new L<Apache2::API::DateTime> object, which is used to parse and format dates for HTTP.

See L<Apache2::API/parse_datetime> and L<Apache2::API/format_datetime>

=head2 decode

Given a url-encoded string, this returns the decoded string, by calling L<APR::Request/decode>

This uses L<APR::Request> XS method.

See also L<rfc3986|https://datatracker.ietf.org/doc/html/rfc3986>

=head2 discard_request_body

    my $rc = $req->discard_request_body;

In C<HTTP/1.1>, any method can have a body. However, most C<GET> handlers would not know what to do with a request body if they received one. This helper routine tests for and reads any message body in the request, simply discarding whatever it receives. We need to do this because failing to read the request body would cause it to be interpreted as the next request on a persistent connection.

Returns C<Apache2::Const::OK> upon success.

    use Apache2::API;
    my $rc = $req->discard_request_body;
    return( $rc ) if( $rc != Apache2::Const::OK );

This method calls L<Apache2::RequestIO/discard_request_body>

=head2 dnt

Sets or gets the environment variable C<HTTP_DNT> using L<Apache2::RequestRec/subprocess_env>. See L</env> below for more on that.

This is an abbreviation for C<Do not track>

If available, typical value is a boolean such as C<0> or C<1>

=head2 document_root

Sets or retrieve the document root for this server.

If a value is provided, it sets the document root to a new value only for the duration of the current request.

See L<Apache2::RequestUtil> for more information.

=head2 document_uri

Get the value for the environment variable C<DOCUMENT_URI>.

=head2 encode

Given a string, this returns its url-encoded version

This uses L<APR::Request> XS method.

=head2 env

    my $val = $req->env( $name );
    $req->env( $name, $value );

Using the Apache C<subprocess_env> table, this sets or gets environment variables. This is the equivalent of this:

                 $req->subprocess_env;
    $env_table = $req->subprocess_env;

           $req->subprocess_env( $key => $val );
    $val = $req->subprocess_env( $key );

where C<$req> is this module object.

If one argument is provided, it will return the corresponding environment value.

If one or more sets of key-value pair are provided, they are set accordingly.

If nothing is provided, it returns a L<APR::Table> object.

=head2 err_headers_out

Get or sets HTTP response headers, which are printed out even on errors and persist across internal redirects.

According to the L<Apache2::RequestRec> documentation:

The difference between L</headers_out> (L<Apache2::RequestRec/headers_out>) and L</err_headers_out> (L<Apache2::RequestRec/err_headers_out>), is that the latter are printed even on error, and persist across internal redirects (so the headers printed for C<ErrorDocument> handlers will have them).

For example, if a handler wants to return a C<404> response, but nevertheless to set a cookie, it has to be:

    $req->err_headers_out->add( 'Set-Cookie' => $cookie );
    return( Apache2::Const::NOT_FOUND );

If the handler does:

    $req->headers_out->add( 'Set-Cookie' => $cookie );
    return( Apache2::Const::NOT_FOUND );

the C<Set-Cookie> header will not be sent.

See L<Apache2::RequestRec> for more information.

=head2 filename

Get or sets the filename (full file path) on disk corresponding to this request or response, by calling L<Apache2::RequestRec/filename>

See L<Apache2::RequestRec/filename> for more information.

=head2 finfo

Get and set the finfo request record member, by calling L<Apache2::RequestRec/finfo>

See L<Apache2::RequestRec/finfo> for more information.

=head2 gateway_interface

Sets or gets the environment variable C<GATEWAY_INTERFACE> using L</env>

Typical value returned from the environment variable C<GATEWAY_INTERFACE> is C<CGI/1.1>

=head2 get_handlers

Returns a reference to a list of handlers enabled for a given phase.

    $handlers_list = $req->get_handlers( $hook_name );

Example, a list of handlers configured to run at the response phase:

    my @handlers = @{ $req->get_handlers('PerlResponseHandler') || [] };

=head2 get_status_line

Return the C<Status-Line> for a given status code (excluding the HTTP-Version field), by calling L<Apache2::RequestRec/status_line>

For example:

    print( $req->get_status_line( 400 ) );

will print:

    400 Bad Request

See also L</status_line>

=head2 global_request

Returns the L<Apache2::RequestRec> object made global with the proper directive in the Apache VirtualHost configuration.

This calls L<Apache2::RequestUtil/request> to retrieve this value.

For example:

    <Location /some/where/>
        SetHandler perl-script
        PerlOptions +GlobalRequest
        # ...
    </Location>

See also L<https://perl.apache.org/docs/2.0/user/config/config.html#C_GlobalRequest_>

=head2 has_auth

    my $need_auth = $r->has_auth;

Check if any authentication is required for the current request, by calling L<Apache2::Access/some_auth_required>

It returns a boolean value.

See also L</is_auth_required>, which is an alias of this method.

=head2 headers

Gets or sets the HTTP request headers using L<APR::Table> by calling L</Apache2::RequestRec/headers_in>

This takes zero, one or sets or C<< key => value >> pairs.

When no argument is provided, this returns the L<APR::Table> object.

When one argument is provided, it returns the corresponding HTTP header value, if any.

You can set multiple key-value pairs, like so:

    $req->headers( $var1 => $val1, $var2 => $val2 );

If a value provided is C<undef>, it will remove the corresponding HTTP headers.

With the L<APR::Table> object, you can access and set header fields directly, such as:

    my $accept = $req->headers->{Accept};
    $req->headers->{Accept} = 'application/json';
    $req->headers->{Accept} = undef; # unset it

or

    my $accept = $req->headers->get( 'Accept' );
    $req->headers->set( Accept => 'application/json' );
    $req->headers->unset( 'Accept' );
    $req->headers->add( Vary => 'Accept-Encoding' );
    # Very useful for this header
    $req->headers->merge( Vary => 'Accept-Encoding' );
    # Empty the headers
    $req->headers->clear;
    use APR::Const qw( :table );
    # to merge: multiple values for the same key are flattened into a comma-separated list.
    $req->headers->compress( APR::Const::OVERLAP_TABLES_MERGE );
    # to overwrite: each key will be set to the last value seen for that key.
    $req->headers->compress( APR::Const::OVERLAP_TABLES_SET );
    my $table = $req->headers->copy( $req2->pool );
    my $headers = $req->headers;
    $req->headers->do(sub
    {
        my( $key, $val ) = @_;
        # Do something
        # return(0) to abort
    }, keys( %$headers ) );
    # or without any filter keys
    $req->headers->do(sub
    {
        my( $key, $val ) = @_;
        # Do something
        # return(0) to abort
    });
    # To prepare a table of 20 elements, but the table can still grow
    my $table = APR::Table::make( $req->pool, 20 );
    my $table2 = $req2->headers;
    # overwrite any existing keys in our table $table
    $table->overlap( $table2, APR::Const::OVERLAP_TABLES_SET );
    # key, value pairs are added, regardless of whether there is another element with the same key in $table
    $table->overlap( $table2, APR::Const::OVERLAP_TABLES_MERGE );
    my $table3 = $table->overlay( $table2, $pool3 );

See L<APR::Table> for more information.

=head2 header_only

This is the same as L</is_header_only>

=head2 headers_as_hashref

Returns the list of headers as an hash reference, by calling L<Apache2::RequestRec/headers_in>

Since the call to L<Apache2::RequestRec> returns a L<APR::Table> object, we may get 2 or more same key name, and in that case, the hash with that key will have as a value an array reference.

=head2 headers_as_json

Returns the list of headers as a json data, by retrieving the hash from L</headers_as_hashref> and encode it with L<JSON>

=head2 headers_in

Returns the list of the headers as special hash, which is actually an L<APR::Table> object.

If a header name is provided, you can retrieve its value like so:

    my $cookie = $req->headers_in->{Cookie} || '';

=head2 headers_out

This is identical to L</headers_in>, as it returns a L<APR::Table> object.

Returns or sets the key => value pairs of outgoing HTTP headers, only on 2xx responses.

See also L</err_headers_out>, which allows to set headers for non-2xx responses and persist across internal redirects.

More information at L<Apache2::RequestRec/headers_out>

=head2 hostname

Retrieve or set the HTTP server host name, such as C<www.example.com>, by calling L<Apache2::RequestRec/hostname>

This is not the machine hostname.

More information at L<Apache2::RequestRec>

=head2 http_host

Returns an C<URI> object of the HTTP host being accessed. This is created during object initiation phase.

This calls the method C<host> on the L<URI> object returned by L</uri>

=head2 id

Returns the connection id; unique at any point in time, by calling L<Apache2::Connection/id>.

See L<Apache2::Connection> for more information.

This is the same as L</connection_id>

=head2 if_modified_since

Returns the value of the HTTP header If-Modified-Since as a C<DateTime> object.

If no such header exists, it returns C<undef> or an empty list depending on the context.

=head2 if_none_match

Sets or gets the value of the HTTP header C<If-None-Match>

See also L</headers>

=head2 input_filters

Get or sets the first filter in a linked list of request level input filters. It returns a L<Apache2::Filter> object.

    $input_filters      = $req->input_filters();
    $prev_input_filters = $req->input_filters( $new_input_filters );

According to the L<Apache2::RequestRec> documentation:

For example instead of using C<< $req->read() >> to read the C<POST> data, one could use an explicit walk through incoming bucket brigades to get that data. The following function C<read_post()> does just that (in fact that's what C<< $req->read() >> does behind the scenes):

     use APR::Brigade ();
     use APR::Bucket ();
     use Apache2::Filter ();

     use Apache2::Const -compile => qw( MODE_READBYTES );
     use APR::Const    -compile => qw( SUCCESS BLOCK_READ );

     use constant IOBUFSIZE => 8192;

     sub read_post {
         my $r = shift;

         my $bb = APR::Brigade->new( $req->pool,
                                     $req->connection->bucket_alloc );

         my $data = '';
         my $seen_eos = 0;
         do {
             $req->input_filters->get_brigade( $bb, Apache2::Const::MODE_READBYTES,
                                             APR::Const::BLOCK_READ, IOBUFSIZE );

             for (my $b = $bb->first; $b; $b = $bb->next( $b )) {
                 if ($b->is_eos) {
                     $seen_eos++;
                     last;
                 }

                 if ($b->read(my $buf)) {
                     $data .= $buf;
                 }

                 $b->remove; # optimization to reuse memory
             }

         } while (!$seen_eos);

         $bb->destroy;

         return $data;
     }

As you can see C<< $req->input_filters >> gives us a pointer to the last of the top of the incoming filters stack.

=head2 is_aborted

This is a more subtle implementation of Apache L<aborted method|Apache2::Connection/aborted> and is described in L<its documentation|https://perl.apache.org/docs/1.0/guide/debug.html#toc_Detecting_Aborted_Connections>.

It attempts to print a null-byte to the connection, L<flush|Apache2::RequestIO/rflush> the Apache buffer and then checks if the connection was L<aborted|Apache2::Connection>.

The reason L<as explained in Apache documentation|https://perl.apache.org/docs/1.0/guide/debug.html#toc_Detecting_Aborted_Connections> is that Apache does not detect if the user dropped the connection until it attempts to read from or write back to it. Thus, as suggested in the documentation, an attempt to write back a null-byte character remedies that. Only calling L<aborted|/aborted> will not suffice.

It returns true if the connection was aborted, and false otherwise.

=head2 is_auth_required

    my $need_auth = $r->is_auth_required;

Check if any authentication is required for the current request, by calling L<Apache2::Access/some_auth_required>

It returns a boolean value.

See also L</has_auth>, which is an alias of this method.

=head2 is_header_only

Returns a boolean value on whether the request is a C<HEAD> request or not, by calling L<Apache2::RequestRec/header_only>

So, it returns true if the client is asking for headers only, false otherwise.

=head2 is_perl_option_enabled

Sets or gets whether a directory level C<PerlOptions> flag is enabled or not. This returns a boolean value, by calling L<Apache2::RequestUtil/is_perl_option_enabled>

For example to check whether the C<SetupEnv> option is enabled for the current request (which can be disabled with C<PerlOptions -SetupEnv>) and populate the environment variables table if disabled:

     $req->subprocess_env unless $req->is_perl_option_enabled('SetupEnv');

See also: PerlOptions and the equivalent function for server level PerlOptions flags.

See the L<Apache2::RequestUtil> module documentation for more information.

=head2 is_initial_req

    # Are we in the main request?
    $is_initial = $req->is_initial_req;

Determines whether the current request is the main request or a sub-request.

This returns a boolean value.

See also L<main|/main>, which returns the main request object.

=head2 is_secure

Returns true (1) if the connection is made under ssl, i.e. of the environment variable C<HTTPS> is set to C<on>, other it returns false (0).

This is done by checking if the environment variable C<HTTPS> is set to C<on> or not.

=head2 json

Returns a L<JSON> object with the C<relaxed> attribute enabled so that it allows more relaxed C<JSON> data.

You can provide an optional hash or hash reference of properties to enable or disable:

    my $J = $api->json( pretty => 1, relaxed => 1 );

Each property corresponds to one that is supported by L<JSON>

It also supports C<ordered>, C<order> and C<sort> as an alias to C<canonical>

=head2 keepalive

    $status = $c->keepalive();
    $status = $c->keepalive($new_status);

This method answers the question: Should the the connection be kept alive for another HTTP request after the current request is completed?

This sets or gets the status by calling L<Apache2::Connection/keepalive>

     use Apache2::Const -compile => qw(:conn_keepalive);
     # ...
     my $c = $req->connection;
     if ($c->keepalive == Apache2::Const::CONN_KEEPALIVE) {
         # do something
     }
     elsif ($c->keepalive == Apache2::Const::CONN_CLOSE) {
         # do something else
     }
     elsif ($c->keepalive == Apache2::Const::CONN_UNKNOWN) {
         # do yet something else
     }
     else {
         # die "unknown state";
     }

Notice that new states could be added later by Apache, so your code should make no assumptions and do things only if the desired state matches.

The method does not return true or false, but one of the states which can be compared against Apache constants (C<:conn_keepalive constants>).

See L<Apache2::Connection> for more information.

=head2 keepalives

    my $served = $req->connection->keepalives();
    my $served = $req->connection->keepalives( $new_served );

This returns an integer representing how many requests were already served over the current connection.

This method calls L<Apache2::Connection/keepalives>

This method is only relevant for keepalive connections. The core connection output filter C<ap_http_header_filter> increments this value when the response headers are sent and it decides that the connection should not be closed (see "ap_set_keepalive()").

If you send your own set of HTTP headers with C<< $req->assbackwards >>, which includes the C<Keep-Alive> HTTP response header, you must make sure to increment the C<keepalives> counter.

See L<Apache2::Connection> for more information.

=head2 languages

This will check the C<Accept-Languages> HTTP headers and derive a list of priority ordered user preferred languages and return an L<array object|Module::Generic::Array>.

See also the L</preferred_language> method.

=head2 length

Returns an integer representing the length in bytes of the request body, by calling L<Apache2::RequestRec/bytes_sent>

=head2 local_addr

Returns our server local address as a L<APR::SockAddr> object, by calling L<Apache2::Connection/local_addr>

    my $local_sock_addr  = $req->connection->local_addr;
    my $port = $local_sock_addr->port;
    my $ip   = $local_sock_addr->ip_get; # e.g.: 192.168.1.2

=head2 local_host

Used for C<ap_get_server_name> when C<UseCanonicalName> is set to C<DNS> (ignores setting of HostnameLookups)

This calls L<Apache2::Connection/local_host>

Better to use the L</server_name> instead.

=head2 local_ip

Return our server IP address as string, by calling L<Apache2::Connection/local_ip>

=head2 location

Get the path of the <Location> section from which the current C<Perl*Handler> is being called.

This calls L<Apache2::RequestUtil/location>

Returns a string.

=head2 log

    $req->log->emerg( "Urgent message." );
    $req->log->alert( "Alert!" );
    $req->log->crit( "Critical message." );
    $req->log->error( "Error message." );
    $req->log->warn( "Warning..." );
    $req->log->notice( "You should know." );
    $req->log->info( "This is for your information." );
    $req->log->debug( "This is debugging message." );

Returns a L<Apache2::Log::Request> object.

=head2 log_error

Returns the value from L<Apache2::Request/log_error> by passing it whatever arguments were received.

=head2 main

Get the main request record and returns a L<Apache2::RequestRec> object, by calling L<Apache2::RequestRec/main>

If the current request is a sub-request, this method returns a blessed reference to the main request structure. If the current request is the main request, then this method returns C<undef>.

To figure out whether you are inside a main request or a sub-request/internal redirect, use C<< $req->is_initial_req >>.

=head2 method

    $method     = $req->method();
    $pre_method = $req->method($new_method);

Get or sets the current request method (e.g. C<GET>, C<HEAD>, C<POST>, etc.), by calling L<Apache2::RequestRec/method>

if a new value was passed the previous value is returned.

=head2 method_bit

    my $bit = $req->method_bit( $name );

    if( $req->allowed & ( 1 << $req->method_bit('POST') ) )
    {
        $req->print( "POST is allowed\n") ;
    }

Given a string C<$name> representing an HTTP method such as C<GET>, C<POST>, C<DELETE>, this method returns the corresponding C<Apache2::Const::M_*> constant value (an integer suitable for bitwise comparison with L</allowed>

The comparison is case-insensitive: the provided name is converted to uppercase internally.

On success, returns an integer as set in L<Apache2::Const/methods>. On error, such as when no name was provided or the given name does not match any known method, this sets an L<Module::Generic/error>, and returns C<undef> in scalar context, and an empty list in list context.

=head2 method_name

    my $name = $req->method_name( $bit );

Given an integer C<$bit> corresponding to one of the C<Apache2::Const::M_*> constants, this method returns the canonical uppercase HTTP method name, such as C<GET>, C<POST>.

This is essentially the reverse mapping of L</method_bit>. It is useful
when you already have a numeric constant (for example when iterating over
keys in C<$r->allowed>).

On success, returns a string. If the provided argument is not an integer,
or if no method name is defined for the given bit value, the method
returns false and calls L</error>.

Example:

    for my $bit ( keys %$methods_bit_to_name ) {
        next unless $r->allowed & (1 << $bit);
        my $name = $r->method_name($bit);
        $r->print("Allowed: $name\n");
    }

=head2 method_number

    my $methnum      = $req->method_number();
    my $prev_methnum = $req->method_number( $new_methnum );

This sets or gets the client method used, as a number, by calling L<Apache2::RequestRec/method_number>

It returns the current method as a number (an L<Apache2::Const>)

For example if the response handler handles only C<GET> and C<POST> methods, and not C<OPTIONS>, it may want to say:

   use Apache2::API;
   if( $req->method_number == Apache2::Const::M_OPTIONS )
   {
       $req->allowed( $req->allowed | ( 1 << Apache2::Const::M_GET ) | ( 1 << Apache2::Const::M_POST ) );
       return( Apache2::Const::DECLINED );
   }

For example, if the module can handle only POST method it could start with:

   use Apache2::API;
   unless( $req->method_number == Apache2::Const::M_POST )
   {
       $req->allowed( $req->allowed | ( 1 << Apache2::Const::M_POST ) );
       return( Apache2::Const::HTTP_METHOD_NOT_ALLOWED );
   }

=head2 mod_perl

Returns the value for the environment variable C<MOD_PERL>.

If a value is provided, it will set the environment variable accordingly.

    $req->mod_perl( "mod_perl/2.0.11" );

=head2 mod_perl_version

Read-only. This is based on the value returned by L</mod_perl>.

This returns a L<version> object of the mod perl version being used, so you can call it like:

    my $min_version = version->declare( 'v2.0.11' );
    if( $req->mod_perl_version >= $min_version )
    {
        # ok
    }

=head2 mtime

Last modified time of the requested resource.

Returns a timestamp in second since epoch by calling L<Apache2::RequestRec/mtime>

=head2 next

Pointer to the redirected request if this is an external redirect.

Returns a L<Apache2::RequestRec> blessed reference to the next (internal) request structure or C<undef> if there is no next request.

=head2 no_cache

Add/remove cache control headers by calling L<Apache2::RequestUtil/no_cache>. A true value sets the C<no_cache> request record member to a true value and inserts:

     Pragma: no-cache
     Cache-control: no-cache

into the response headers, indicating that the data being returned is volatile and the client should not cache it.

A false value unsets the C<no_cache> request record member and the mentioned headers if they were previously set.

This method should be invoked before any response data has been sent out.

See L<Apache2::RequestUtil> for more information.

=head2 notes

Get or sets text notes for the duration of this request by calling L<Apache2::RequestUtil/pnotes>. These notes can be passed from one module to another (not only mod_perl, but modules in any other language).

If a new value was passed, returns the previous value.

The returned value is a L<APR::Table> object by calling L<Apache2::RequestUtil/notes>

=head2 output_filters

    my $output_filters = $req->connection->output_filters();
    my $prev_output_filters = $req->output_filters( $new_output_filters );

Set or get the first filter in a linked list of request level output filters by calling L</output_filters>. It returns a L<Apache2::Filter> object.

If a new output filters was passed, returns the previous value.

According to the L<Apache2::RequestRec> documentation:

For example instead of using C<< $req->print() >> to send the response body, one could send the data directly to the first output filter. The following function C<send_response_body()> does just that:

     use APR::Brigade ();
     use APR::Bucket ();
     use Apache2::Filter ();

     sub send_response_body 
     {
         my( $req, $data ) = @_;

         my $bb = APR::Brigade->new( $req->pool,
                                     $req->connection->bucket_alloc );

         my $b = APR::Bucket->new( $bb->bucket_alloc, $data );
         $bb->insert_tail( $b );
         $req->output_filters->fflush( $bb );
         $bb->destroy;
     }

In fact that's what C<< $req->read() >> does behind the scenes. But it also knows to parse HTTP headers passed together with the data and it also implements buffering, which the above function does not.

=head2 param

Provided a name, this returns its equivalent value, using L<Apache2::API::Request::Params/param>.

If C<$name> is an upload field, ie part of a multipart post data, it returns an L<Apache2::API::Request::Upload> object instead.

If a value is provided, this calls L<Apache2::API::Request::Param/param> providing it with the name ane value. This uses L<APR::Request::Param>.

=head2 params

Get the request parameters (using case-insensitive keys) by mimicing the OO interface of L<CGI::param>.

It can take as argument, only a key and it will then retrieve the corresponding value, or it can take a key and value pair to set them using L<Apache2::API::Request::Params/param>

If the value is an array, this will set multiple entry of the key for each value provided.

This uses Apache L<APR::Table> and works for both C<POST> and C<GET> methods.

If the methods received was a C<GET> method, this method returns the value of the L</query> method instead.

=head2 parse_date

Alias to L<Apache2::API::DateTime/parse_date>

=head2 path

Get the value for the environment variable C<PATH>

See also L</env>

=head2 path_info

    my $path_info      = $req->path_info();
    my $prev_path_info = $req->path_info( $path_info );

Get or set the C<PATH_INFO>, what is left in the path after the C<< URI --> filename >> translation, by calling L<Apache2::RequestRec/path_info>

Return a string as the current value.

=head2 payload

Returns the JSON data decoded into a perl structure. This is set at object initiation phase and calls the L</data> method to read the incoming data and decoded it into perl internal utf8.

=head2 per_dir_config

Get the dir config vector, by calling L<Apache2::RequestRec/per_dir_config>. Returns a L<Apache2::ConfVector> object.

For an in-depth discussion, refer to the Apache Server Configuration Customization in Perl chapter.

=head2 pnotes

Share Perl variables between Perl HTTP handlers, using L<Apache2::RequestUtil/pnotes>.

     # to share variables by value and not reference, $val should be a lexical.
     $old_val  = $req->pnotes( $key => $val );
     $val      = $req->pnotes( $key );
     $hash_ref = $req->pnotes();

Note: sharing variables really means it. The variable is not copied.  Only its reference count is incremented. If it is changed after being put in pnotes that change also affects the stored value. The following example illustrates the effect:

     my $v = 1;                   my $v = 1;
     $req->pnotes( 'v'=> $v );    $req->pnotes->{v} = $v;
     $v++;                        $v++;
     my $x = $req->pnotes('v');   my $x = $req->pnotes->{v};

=head2 pool

Returns the pool associated with the request as a L<APR::Pool> object of the L<Apache2 connection|Apache2::Connection>. If you rather want access to the pool object of the Apache2 request itself, use L</request>, such as:

    # $rest being a Apache2::API object
    my $request_pool = $req->pool;
    $request_pool->cleanup_register( \&cleanup );

=head2 preferred_language

Given an array reference of supported languages, this method will get the client accepted languages by calling L</accept_language> and derive the best match, ie the client preferred language, using L<HTTP::AcceptLanguage>,.

It returns a string representing a language code.

Note that it does not matter if the array reference of supported language use underscore or dash, so both of the followings are equivalent:

    my $best_lang = $req->preferred_language( [qw( en_GB fr_FR ja_JP ko_KR )] );

and

    my $best_lang = $req->preferred_language( [qw( en-GB fr-FR ja-JP ko-KR )] );

If somehow, no suitable language could be found, it will return an empty string, and it will return C<undef> in scalar context, or an empty list in list context upon error, so check if the return value is defined or not.

See also: L</languages> and L</accept_language>

=head2 prev

    my $prev_r = $req->prev();

Pointer to the previous request if this is an internal redirect, by calling L<Apache2::RequestRec/prev>.

Returns a L<Apache2::RequestRec> blessed reference to the previous (internal) request structure or C<undef> if there is no previous request.

=head2 protocol

    my $protocol = $req->protocol();

Get a string identifying the protocol that the client speaks, such as C<HTTP/1.0> or C<HTTP/1.1>, by calling L<Apache2::RequestRec/protocol>

=head2 proxyreq

    my $status = $req->proxyreq( $val );

Get or set the proxyrec request record member and optionally adjust other related fields, by calling L<Apache2::RequestRec/proxyreq>.

Valid values are: C<PROXYREQ_NONE>, C<PROXYREQ_PROXY>, C<PROXYREQ_REVERSE>, C<PROXYREQ_RESPONSE>

According to the L<Apache2::RequestRec> documentation:

For example to turn a normal request into a proxy request to be handled on the same server in the C<PerlTransHandler> phase run:

     my $real_url = $req->unparsed_uri;
     $req->proxyreq( Apache2::Const::PROXYREQ_PROXY );
     $req->uri( $real_url );
     $req->filename( "proxy:$real_url" );
     $req->handler( 'proxy-server' );

Also remember that if you want to turn a proxy request into a non-proxy request, it is not enough to call:

     $req->proxyreq( Apache2::Const::PROXYREQ_NONE );

You need to adjust C<< $req->uri >> and C<< $req->filename >> as well if you run that code in C<PerlPostReadRequestHandler> phase, since if you do not -- C<mod_proxy>'s own post_read_request handler will override your settings (as it will run after the mod_perl handler).

And you may also want to add

     $req->set_handlers( PerlResponseHandler => [] );

so that any response handlers which match apache directives will not run in addition to the mod_proxy content handler.

=head2 psignature

    my $sig = $req->psignature;
    my $sig = $req->psignature( $prefix );

Get HTML describing the address and (optionally) admin of the server. It takes an optional C<$prefix> that will be prepended to the return value.

Note that depending on the value of the C<ServerSignature> directive, the function may return the address, including the admin information or nothing at all.

=head2 push_handlers

Add one or more handlers to a list of handlers to be called for a given phase, by calling L<Apache2::RequestUtil/push_handlers>.

     my $ok = $req->push_handlers( $hook_name => \&handler );
     my $ok = $req->push_handlers( $hook_name => ['Foo::Bar::handler', \&handler2] );

It returns a true value on success, otherwise a false value

Examples:

A single handler:

     $req->push_handlers( PerlResponseHandler => \&handler );

Multiple handlers:

     $req->push_handlers( PerlFixupHandler => ['Foo::Bar::handler', \&handler2] );

Anonymous functions:

     $req->push_handlers( PerlLogHandler => sub { return Apache2::Const::OK } );

See L<Apache2::RequestUtil> for more information.

=head2 query

Check the query string sent in the HTTP request, which obviously should be a C<GET>, but not necessarily, and parse it with L<Apache2::API::Query> and return an hash reference, by calling L<Apache2::API::Query>

=head2 query_string

    my $string      = $req->args(); # q=hello&lang=ja_JP
    my $prev_string = $req->args( $new_string );

Actually calls L<Apache2::RequestRec/args> behind the scene.

This sets or gets the request query string.

=head2 read

Read data from the client and returns the number of characters actually read.

     $cnt = $req->read( $buffer, $len );
     $cnt = $req->read( $buffer, $len, $offset );

This method shares a lot of similarities with the Perl core C<read()> function. The main difference in the error handling, which is done via L<APR::Error> exceptions

See L<Apache2::RequestIO> for more information.

=head2 redirect_error_notes

Gets or sets the value for the environment variable C<REDIRECT_ERROR_NOTES>

=head2 redirect_query_string

Gets or sets the value for the environment variable C<REDIRECT_QUERY_STRING>

=head2 redirect_status

Gets or sets the value for the environment variable C<REDIRECT_STATUS>

=head2 redirect_url

Gets or sets the value for the environment variable C<REQUEST_URI>

=head2 referer

Returns the value of the HTTP C<Referer> header, if any.

See also L</headers>

=head2 remote_addr

Returns the remote host socket address as a L<APR::SockAddr> object.

Because the Apache2 mod_perl api has changed, before the method to call was C<client_addr> and is now C<remote_addr>

    my $remote_sock_addr = $req->remote_addr();
    my $local_sock_addr  = $req->local_addr();

    my $ip = $remote_sock_addr->ip_get; # e.g.: 192.168.1.2
    my $port = $soremote_sock_addrck_addr->port;

The above would be the equivalent in conventional perl of:

    use Socket 'sockaddr_in';
    my( $port, $ip ) = sockaddr_in( getpeername( $remote_sock ) );

See L<Apache2::Connection> for more information.

=head2 remote_host

Returns the remote client host name, by calling L<Apache2::Connection/get_remote_host>

Calling C<get_remote_host> is the recommended method over C<remote_host>

If the configuration directive C<HostNameLookups> is set to C<off>, this returns the dotted decimal representation of the client's IP address instead. Might return C<undef> if the hostname is not known.

    my $remote_host = $req->remote_host();
    my $remote_host = $req->remote_host( $type );
    my $remote_host = $req->remote_host( $type, $dir_config );

If C<$type> is provided, it must be a C<:remotehost> constant (see L<Apache2::Const>):

=over 4

=item C<Apache2::Const::REMOTE_DOUBLE_REV>

Will always force a DNS lookup, and also force a double reverse lookup, regardless of the "HostnameLookups" setting. The result is the (double reverse checked) hostname, or C<undef> if any of the lookups fail.

=item C<Apache2::Const::REMOTE_HOST>

Returns the hostname, or C<undef> if the hostname lookup fails. It will force a DNS lookup according to the C<HostnameLookups> setting.

=item C<Apache2::Const::REMOTE_NAME>

Returns the hostname, or the dotted quad if the hostname lookup fails. It will force a DNS lookup according to the C<HostnameLookups> setting.

=item C<Apache2::Const::REMOTE_NOLOOKUP>

Is like C<Apache2::Const::REMOTE_NAME> except that a DNS lookup is never forced.

If C<$dir_config> is provided, this is the directory config vector from the request. It is needed to find the container in which the directive C<HostnameLookups> is set. To get one for the current request use C<< $req->per_dir_config >>.

By default, C<undef> is passed, in which case it is the same as if C<HostnameLookups> was set to C<Off>.

=back

Default value is C<Apache2::Const::REMOTE_NAME>

=head2 remote_ip

    my $remote_ip      = $req->connection->remote_ip();
    my $prev_remote_ip = $req->connection->remote_ip( $new_remote_ip );

Sets or gets the ip address of the client, ie remote host making the request, by calling L<Apache2::Connection/client_ip> or L<Apache2::Connection/remote_ip>

It returns a string representing an ip address,

=head2 remote_port

It returns the value for the environment variable C<REMOTE_PORT> or set its value with the argument provided if any.

    $req->remote_port( 51234 );
    print( "Remote port is: ", $req->remote_port, "\n" );

=head2 request

Returns the embedded L<Apache2::RequestRec> object provided initially at object instantiation.

=head2 request_scheme

Gets or sets the environment variable C<REQUEST_SCHEME>

=head2 request_time

Read-only.

Returns the time when the request started as a L<DateTime> object with L<Apache2::API::DateTime> as the formatter.

=head2 request_uri

This returns the current value for the environment variable C<REQUEST_URI>, or set its value if an argument is provided.

The uri provided by this environment variable include the path info if any.

For example, assuming you have a cgi residing in C</cgi-bin/prog.cgi> and it is called with the path info C</some/value>, the value returned would then be C</cgi-bin/prog.cgi/some/value>

=head2 requires

    $requires = $req->requires;

Retrieve information about all of the requires directives for this request, by calling L<Apache2::Access/requires>

It returns an array reference of hash references, containing information related to the C<require> directive.

For example if the configuration had the following require directives:

    Require user  goo bar
    Require group bar tar
    <Limit POST>
        Require valid-user
    </Limit>

this method will return the following datastructure:

    [
        {
            method_mask => -1,
            requirement => 'user goo bar'
        },
        {
            method_mask => -1,
            requirement => 'group bar tar'
        },
        {
            method_mask => 4,
            requirement => 'valid-user'
        }
    ];

The requirement field is what was passed to the "Require" directive. The method_mask field is a bitmask which can be modified by the C<Limit> directive, but normally it can be safely ignored as it's mostly used internally.

See also L<https://httpd.apache.org/docs/2.4/en/howto/access.html>

=head2 satisfies

    my $satisfy = $req->satisfies;

Get the applicable value of the C<Satisfy> directive, by calling L<Apache2::Access/satisfies>

It returns one of the L<Apache2::Const> C<:satisfy> constants:

=over 4

=item * C<Apache2::Const::SATISFY_ANY>

Any of the requirements must be met.

=item * C<Apache2::Const::SATISFY_ALL>

All of the requirements must be met.

=item * C<Apache2::Const::SATISFY_NOSPEC>

There are no applicable C<satisfy> lines.

=back

=head2 script_filename

This returns the current value for the environment variable C<SCRIPT_FILENAME>, or set its value if an argument is provided.

For example, if the file being served resides at the uri C</about.html> and your document root is C</var/www>, the the value returned would be C</var/www/about.html>

It is noteworthy that this environment variable does not include any path info set, if any.

=head2 script_name

This returns the current value for the environment variable C<SCRIPT_NAME>, or set its value if an argument is provided.

For example, if the file being served resides at the uri C</about.html>, the value returned would be C</about.html>.

Even though the environment variable name is C<SCRIPT_NAME>, its value is any file being served and contrary to what you might believe, it is not limited to a script, such as a program.

=head2 script_uri

This returns the current value for the environment variable C<SCRIPT_URI>, or set its value if an argument is provided.

It is similar to L</request_uri>, except this returns a full uri including the protocol and host name. For example: C<https://example.com/cgi-bin/prog.cgi/path/info>

=head2 script_url

This returns the current value for the environment variable C<SCRIPT_URL>, or set its value if an argument is provided.

The value returned is identical to that of L</request_uri>, i.e, for example: C</cgi-bin/prog.cgi/path/info>

=head2 server

Get the L<Apache2::ServerRec> object for the server the request C<$r> is running under.

=head2 server_addr

This returns the current value for the environment variable C<SERVER_ADDR>, or set its value if an argument is provided.

Typical value is an ip address.

=head2 server_admin

Returns the server admin as provided by L<Apache2::ServerRec/server_admin>

=head2 server_hostname

Returns the server host name as provided by L<Apache2::ServerRec/server_hostname>

=head2 server_name

Get the current request's server name as provided by L<Apache2::RequestUtil/get_server_name>

See L<Apache2::RequestUtil> for more information.

=head2 server_port

Get the current server port as provided by L<Apache2::RequestUtil/get_server_port>

See L<Apache2::RequestUtil> for more information.

=head2 server_protocol

This returns the current value for the environment variable C<SERVER_PROTOCOL>, or set its value if an argument is provided.

Typical value is C<HTTP/1.1>

=head2 server_signature

This returns the current value for the environment variable C<SERVER_SIGNATURE>, or set its value if an argument is provided.

The value of this environment variable can be empty if the Apache configuration parameter C<ServerSignature> is set to C<Off>

=head2 server_software

This returns the current value for the environment variable C<SERVER_SOFTWARE>, or set its value if an argument is provided.

This is typically something like C<Apache/2.4.41 (Ubuntu)>

=head2 server_version

This will endeavour to find out the Apache version.

When called multiple times, it will return a cached value and not recompute each time.

It first tries L<Apache2::ServerUtil/get_server_description>

Otherwise, it tries to find the binary C<apxs> on the filesystem, and if found, calls it like:

    apxs -q -v HTTPD_VERSION

If this does not work too, it will try to call the Apache binary (C<apache2> or C<httpd>) like:

    apache2 -v

and extract the version.

It returns the version found as a L<version> object, or an empty string if nothing could be found.

=head2 set_basic_credentials

Provided with a user name and a password, this populates the incoming request headers table (C<headers_in>) with authentication headers for Basic Authorization as if the client has submitted those in first place:

    $req->set_basic_credentials( $username, $password );

See L<Apache2::RequestUtil> for more information.

=head2 set_handlers

Set a list of handlers to be called for a given phase. Any previously set handlers are forgotten.

See L<Apache2::RequestUtil/set_handlers> for more information.

     $ok = $req->set_handlers( $hook_name => \&handler );
     $ok = $req->set_handlers( $hook_name => ['Foo::Bar::handler', \&handler2] );
     $ok = $req->set_handlers( $hook_name => [] );
     $ok = $req->set_handlers( $hook_name => undef );

=head2 slurp_filename

Slurp the contents of C<< $req->filename >>:

This returns a scalar reference instead of the actual string. To get the string, use L</content>

Note that if you assign to C<$req->filename> you need to update its stat record.

=head2 socket

Get or sets the client socket and returns a L<APR::Socket> object.

This calls L<Apache2::Connection/client_socket> package.

=head2 status

    my $status      = $req->status();
    my $prev_status = $req->status( $new_status );

Get or set thes reply status for the client request, which is an integer, by calling L<Apache2::RequestRec/status>

Normally you would use some L<Apache2::Const> constant, e.g. L<Apache2::Const::REDIRECT>.

From the L<Apache2::RequestRec> documentation:

Usually you will set this value indirectly by returning the status code as the handler's function result. However, there are rare instances when you want to trick Apache into thinking that the module returned an C<Apache2::Const:OK> status code, but actually send the browser a non-OK status. This may come handy when implementing an HTTP proxy handler. The proxy handler needs to send to the client, whatever status code the proxied server has returned, while returning L<Apache2::Const::OK> to Apache. e.g.:

    $req->status( $some_code );
    return( Apache2::Const::OK );

See also C<< $req->status_line >>, which. if set, overrides C<< $req->status >>.

=head2 status_line

    my $status_line      = $req->status_line();
    my $prev_status_line = $req->status_line( $new_status_line );

Get or sets the response status line. The status line is a string like C<200 Document follows> and it will take precedence over the value specified using the C<< $req->status() >> described above.

According to the L<Apache2::RequestRec> documentation:

When discussing C<< $req->status >> we have mentioned that sometimes a handler runs to a successful completion, but may need to return a different code, which is the case with the proxy server. Assuming that the proxy handler forwards to the client whatever response the proxied server has sent, it will usually use C<status_line()>, like so:

     $req->status_line( $response->code() . ' ' . $response->message() );
     return( Apache2::Const::OK );

In this example C<$response> could be for example an L<HTTP::Response> object, if L<LWP::UserAgent> was used to implement the proxy.

This method is also handy when you extend the HTTP protocol and add new response codes. For example you could invent a new error code and tell Apache to use that in the response like so:

     $req->status_line( "499 We have been FooBared" );
     return( Apache2::Const::OK );

Here 499 is the new response code, and We have been FooBared is the custom response message.

=head2 str2datetime

Alias to L<Apache2::API::DateTime/str2datetime>

=head2 str2time

Alias to L<Apache2::API::DateTime/str2time>

=head2 subnet_of

Provided with an ip address (v4 or v6), and optionally a subnet mask, and this will return a boolean value indicating if the current connection ip address is part of the provided subnet.

The mask can be a string or a number of bits.

It uses L<APR::IpSubnet> and performs the test using the object from L<APR::SockAddr> as provided with L</remote_addr>

    my $ok = $req->subnet_of( '127.0.0.1' );
    my $ok = $req->subnet_of( '::1' );
    my $ok = $req->subnet_of( '127.0.0.1', '255.0.0.0' );
    my $ok = $req->subnet_of( '127.0.0.1', 15 );

    if( !$req->subnet_of( '127.0.0.1' ) )
    {
        print( "Sorry, only local connections allowed\n" );
    }

=head2 subprocess_env

Get or sets the L<Apache2::RequestRec> C<subprocess_env> table, or optionally set the value of a named entry.

From the L<Apache2::RequestRec> documentation:

When called in void context with no arguments, it populate C<%ENV> with special variables (e.g. C<$ENV{QUERY_STRING}>) like mod_cgi does.

When called in a non-void context with no arguments, it returns an C<APR::Table object>.

When the $key argument (string) is passed, it returns the corresponding value (if such exists, or C<undef>. The following two lines are equivalent:

     $val = $req->subprocess_env( $key );
     $val = $req->subprocess_env->get( $key );

When the $key and the $val arguments (strings) are passed, the value is set. The following two lines are equivalent:

     $req->subprocess_env( $key => $val );
     $req->subprocess_env->set( $key => $val );

The C<subprocess_env> C<table> is used by L<Apache2::SubProcess>, to pass environment variables to externally spawned processes. It is also used by various Apache modules, and you should use this table to pass the environment variables. For example if in C<PerlHeaderParserHandler> you do:

      $req->subprocess_env( MyLanguage => "de" );

you can then deploy C<mod_include> and write in C<.shtml> document:

      <!--#if expr="$MyLanguage = en" -->
      English
      <!--#elif expr="$MyLanguage = de" -->
      Deutsch
      <!--#else -->
      Sorry
      <!--#endif -->

=head2 temp_dir

    my $dir = $req->temp_dir;
    $req->temp_dir( $dir );

Get or set the spool directory for uploads which exceed the configured brigade_limit.

=head2 the_request

    my $request = $req->the_request();
    my $old_request = $req->uri( $new_request );

Get or set the first HTTP request header as a string by calling L<Apache2::RequestRec/the_request>. For example:

    GET /foo/bar/my_path_info?args=3 HTTP/1.0

=head2 time2datetime

Alias to L<Apache2::API::DateTime/time2datetime>

=head2 time2str

Alias to L<Apache2::API::DateTime/time2str>

=head2 type

Returns the content type of the request received. This value is set at object initiation phase.

So for example, if the HTTP request C<Content-type> is

    Content-Type: application/json; charset=utf-8

Then, L</type> would return C<application/json>

=head2 unparsed_uri

The URI without any parsing performed.

If for example the request was:

     GET /foo/bar/my_path_info?args=3 HTTP/1.0

C<< $req->uri >> returns:

     /foo/bar/my_path_info

whereas C<< $req->unparsed_uri >> returns:

     /foo/bar/my_path_info?args=3

=head2 uploads

Returns an L<array object|Module::Generic::Array> of L<Apache2::API::Request::Upload> objects.

=head2 uri

Returns a L<URI> object representing the full uri of the request.

This is different from the original L<Apache2::RequestRec> which only returns the path portion of the URI.

So, to get the path portion using our L</uri> method, one would simply do C<< $req->uri->path() >>

This L<URI> object is built using L<Apache2::RequestUtil/get_server_name> for the C<host>, L<Apache2::RequestUtil/get_server_port> for the port number, and the scheme is C<https> if the port is C<443>, otherwise C<http>. It is followed then by the path build by calling L<Apache2::RequestRec/unparsed_uri>

=head2 url_decode

This is merely a convenient pointer to L</decode>

=head2 url_encode

This is merely a convenient pointer to L</encode>

=head2 user

Get the user name, if an authentication process was successful. Or set it, by calling L<Apache2::RequestRec/user>

For example, let's print the username passed by the client:

     my( $res, $sent_pw ) = $req->get_basic_auth_pw;
     return( $res ) if( $res != Apache2::Const::OK );
     print( "User: ", $req->user );

=head2 user_agent

Returns the user agent, ie the browser signature as provided in the request headers received under the HTTP header C<User-Agent>

=head2 _find_bin( string )

Given a binary, this will search for it in the path.

=head2 _try( object type, method name, @_ )

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
