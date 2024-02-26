##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API.pm
## Version v0.2.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/05/30
## Modified 2024/02/16
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::API;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $DEBUG );
    use version;
    use Encode ();
    # use Apache2::Const qw( :common :http );
    use Apache2::Const -compile => qw( :cmd_how :common :config :conn_keepalive :context :filter_type :http :input_mode :log :methods :mpmq :options :override :platform :remotehost :satisfy :types :proxy );
    use APR::Const -compile => qw( :common :error :fopen :filepath :fprot :filetype :finfo :flock :hook :limit :lockmech :poll :read_type :shutdown_how :socket :status :table :uri );
    use Apache2::RequestRec ();
    use Apache2::RequestIO ();
    use Apache2::ServerUtil ();
    use Apache2::RequestUtil ();
    use Apache2::Response ();
    use Apache2::Log ();
    use Apache2::API::Request;
    use Apache2::API::Response;
    use Apache2::API::Status;
    use APR::Base64 ();
    use APR::Request ();
    use APR::UUID ();
    use Devel::Confess;
    use JSON ();
    use Scalar::Util ();
    $DEBUG   = 0;
    $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub import
{
    my( $this, @arguments ) = @_ ;
    my $class = CORE::caller();
    # my $code = qq{package ${class}; use Apache2::Const -compile => qw( @arguments );};
    # print( "Evaluating -> $code\n" );
    # eval( $code );
    # print( "\$@ -> $@\n" );

    # local $Exporter::ExportLevel = 1;
    # Apache2::Const->import( '-compile' => @arguments );
    # my @argv = grep( !/^\:http/, @arguments );
    # Apache2::Const->compile( '-compile' => @argv );
    # Apache2::Const->compile( $class => qw( AUTH_REQUIRED ) );

    Apache2::Const->compile( $class => @arguments );
}

sub init
{
    my $self = shift( @_ );
    my $r;
    $r = shift( @_ ) if( @_ % 2 );
    # my $r = shift( @_ ) || Apache2::RequestUtil->request;
    $self->{request}                = undef unless( $self->{request} );
    $self->{response}               = undef unless( $self->{response} );
    $self->{apache_request}         = $r unless( $self->{apache_request} );
    # 200Kb
    $self->{compression_threshold}  = 204800 unless( length( $self->{compression_threshold} ) );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    unless( $r = $self->apache_request )
    {
        $r ||= Apache2::RequestUtil->request;
        return( $self->error( "No Apache2::RequestRec object was provided." ) ) if( !$r );
        $self->apache_request( $r ) || return( $self->pass_error );
    }
    my( $req, $resp );
    unless( $req = $self->request )
    {
        $req = Apache2::API::Request->new( $r, debug => $self->debug ) ||
            return( $self->pass_error( Apache2::API::Request->error ) );
        $self->request( $req );
    }
    unless( $resp = $self->response )
    {
        $resp = Apache2::API::Response->new( request => $req, debug => $self->debug ) ||
            return( $self->pass_error( Apache2::API::Response->error ) );
        $self->response( $resp );
    }
    return( $self );
}

sub apache_request { return( shift->_set_get_object_without_init( 'apache_request', 'Apache2::RequestRec', @_ ) ); }

sub bailout
{
    my $self = shift( @_ );
    my $msg;
    if( ref( $_[0] ) eq 'HASH' )
    {
        $msg = shift( @_ );
    }
    else
    {
        $msg = { code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR };
        $msg->{message} = join( '', @_ ) if( @_ );
    }
    # We send the error to our error method
    $msg->{code} ||= Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    $self->error( $msg ) if( $msg->{message} );
    CORE::delete( $msg->{skip_frames} );
    # So it gets logged or displayed on terminal
    my( $pack, $file, $line ) = caller;
    my $sub_str = ( caller( 1 ) )[3];
    my $sub = CORE::index( $sub_str, '::' ) != -1 ? substr( $sub_str, rindex( $sub_str, '::' ) + 2 ) : $sub_str;
    # Now we tweak the hash to send it to the client
    $msg->{message} = CORE::delete( $msg->{public_message} ) || 'An unexpected server error has occurred';
    # Give it a chance to be localised
    $msg->{message} = $self->gettext( $msg->{message} );
    my $ctype = $self->response->content_type;
    if( $ctype eq 'application/json' )
    {
        return( $self->reply( $msg->{code}, { error => $msg->{message} } ) );
    }
    else
    {
        # try-catch
        local $@;
        my $rv = eval
        {
            my $r = $self->apache_request;
            $r->status( $msg->{code} );
            $r->rflush;
            $r->print( $msg->{message} );
            return( $msg->{code} );
        };
        if( $@ )
        {
            return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        }
        return( $rv );
    }
}

sub compression_threshold { return( shift->_set_get_number( 'compression_threshold', @_ ) ); }

# <https://perl.apache.org/docs/2.0/api/APR/Base64.html#toc_C_decode_>
sub decode_base64
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    # try-catch
    local $@;
    my $rv = eval
    {
        return( APR::Base64::decode( $data ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to base64 decode data: $@" ) );
    }
    return( $rv );
}

sub decode_json
{
    my $self = shift( @_ );
    my $raw  = shift( @_ ) || return( $self->error( "No json data was provided to decode." ) );
    my $json = $self->json;
    my $hash;
    # try-catch
    local $@;
    eval
    {
        $hash = $json->utf8->decode( $raw );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to decode json payload: $@" ) );
    }
    return( $hash );
}

sub decode_url
{
    my $self = shift( @_ );
    return( APR::Request::decode( shift( @_ ) ) );
}

sub decode_utf8
{
    my $self = shift( @_ );
    my $v = shift( @_ );
    my $rv = eval
    {
        ## utf8 is more lax than the strict standard of utf-8; see Encode man page
        Encode::decode( 'utf8', $v, Encode::FB_CROAK );
    };
    if( $@ )
    {
        $self->error( "Error while decoding text: $@" );
        return( $v );
    }
    return( $rv );
}

# https://perl.apache.org/docs/2.0/api/APR/Base64.html#toc_C_encode_
# sub encode_base64 { return( APR::Base64::encode( @_ ) ); }
sub encode_base64
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    return( $self->error( "No valid to base64 encode was provided." ) ) if( !length( $data ) );
    # try-catch
    local $@;
    my $rv = eval
    {
        return( APR::Base64::encode( $data ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to base64 encode data: $@" ) );
    }
    return( $rv );
}

sub encode_json
{
    my $self = shift( @_ );
    my $hash = shift( @_ ) || return( $self->error( "No perl hash reference was provided to encode." ) );
    return( $self->error( "Hash provided ($hash) is not a hash reference." ) ) if( !$self->_is_hash( $hash ) );
    my $json = $self->json->allow_nonref->allow_blessed->convert_blessed->relaxed;
    my $data;
    # try-catch
    local $@;
    eval
    {
        $data = $json->encode( $hash );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to encode perl data: $@\nPerl data are: ", sub{ $self->SUPER::dump( $hash ) } ) );
    }
    return( $data );
}

sub encode_url
{
    my $self = shift( @_ );
    return( APR::Request::encode( shift( @_ ) ) );
}

sub encode_utf8
{
    my $self = shift( @_ );
    my $v = shift( @_ );
    my $rv = eval
    {
        ## utf8 is more lax than the strict standard of utf-8; see Encode man page
        Encode::encode( 'utf8', $v, Encode::FB_CROAK );
    };
    if( $@ )
    {
        $self->error( "Error while encoding text: $@" );
        return( $v );
    }
    return( $rv );
}

# <https://perl.apache.org/docs/2.0/api/APR/UUID.html>
sub generate_uuid
{
    my $self = shift( @_ );
    # try-catch
    local $@;
    my $rv = eval
    {
        return( APR::UUID->new->format );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to generate an uuid using APR::UUID package: $@" ) );
    }
    return( $rv );
}

# rfc 6750 <https://tools.ietf.org/html/rfc6750>
sub get_auth_bearer
{
    my $self = shift( @_ );
    my $bearer = $self->request->authorization;
    # Found a bearer
    if( $bearer )
    {
        # https://jwt.io/introduction/
        # https://tools.ietf.org/html/rfc7519
        # if( $bearer =~ /^Bearer[[:blank:]]+([a-zA-Z0-9][a-zA-Z0-9\-\_\~\+\/\=]+(?:\.[a-zA-Z0-9\_][a-zA-Z0-9\-\_\~\+\/\=]+){2,4})$/i )
        if( $bearer =~ /^Bearer[[:blank:]]+([a-zA-Z0-9][a-zA-Z0-9\-\_\~\+\/\=]+(?:\.[a-zA-Z0-9\_][a-zA-Z0-9\-\_\~\+\/\=]+)*)$/i )
        {
            my $token = $1;
            return( $token );
        }
        else
        {
            return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "Bad bearer authorization format" }) );
        }
    }
    else
    {
        # Return empty, not undef, because undef is for errors
        return( '' );
    }
}

# <https://perl.apache.org/docs/2.0/api/Apache2/ServerUtil.html>
sub get_handlers { return( shift->_try( 'server', 'get_handlers', @_ ) ); }

# Does nothing and it should be superseded by a class inheriting our module
# This gives a chance to return a localised version of our string to the user
sub gettext { return( $_[1] ); }

sub header_datetime
{
    my $self = shift( @_ );
    my $dt;
    if( @_ )
    {
        return( $self->error( "Date time provided (", ( $_[0] // 'undef' ), ") is not an object." ) ) if( !Scalar::Util::blessed( $_[0] ) );
        return( $self->error( "Object provided (", ref( $_[0] ), ") is not a DateTime object." ) ) if( !$_[0]->isa( 'DateTime' ) );
        $dt = shift( @_ );
    }
    $dt = DateTime->now if( !defined( $dt ) );
    my $fmt = Apache2::API::DateTime->new;
    $dt->set_formatter( $fmt );
    return( $dt );
}

sub is_perl_option_enabled { return( shift->_try( 'request', 'is_perl_option_enabled', @_ ) ); }

# We return a new object each time, because if we cached it, some routine might set the utf8 bit flagged on while some other would not want it
sub json
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $j = JSON->new;
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

sub lang { return( shift->_set_get_scalar( 'lang', @_ ) ); }

sub lang_unix
{
    my $self = shift( @_ );
    my $lang = $self->{lang};
    $lang =~ tr/-/_/;
    return( $lang );
}

sub lang_web
{
    my $self = shift( @_ );
    my $lang = $self->{lang};
    $lang =~ tr/_/-/;
    return( $lang );
}

sub log_error { return( shift->_try( 'apache_request', 'log_error', @_ ) ); }

sub print
{
    my $self = shift( @_ );
    my $opts = {};
    if( scalar( @_ ) == 1 && ref( $_[0] ) )
    {
        $opts = shift( @_ );
    }
    else
    {
        $opts->{data} = join( '', @_ );
    }
    return( $self->error( "No data was provided to print out." ) ) if( !CORE::length( $opts->{data} ) );
    my $r = $self->apache_request;
    my $json = $opts->{data};
    my $bytes = 0;
    # Before we use this, we have to make sure all Apache module that deal with content encoding are de-activated because they would interfere
    my $threshold = $self->compression_threshold || 0;
    # rfc1952
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding
    my $z;
    if( CORE::length( $json ) > $threshold && 
        $self->request->accept_encoding =~ /\bgzip\b/i && 
        $self->_load_class( 'IO::Compress::Gzip' ) && 
        ( $z = IO::Compress::Gzip->new( '-', Minimal => 1 ) ) )
    {
        #require Compress::Zlib;
        #$r->print( Compress::Zlib::memGzip( $json ) );
        # $r->content_encoding( 'gzip' );
        $self->response->content_encoding( 'gzip' );
        $self->response->headers->set( 'Content-Encoding' => 'gzip' );
        # Why Vary? https://blog.stackpath.com/accept-encoding-vary-important/
        # We use merge, because another value may already be set
        $self->response->headers->merge( 'Vary' => 'Accept-Encoding' );
        # $r->send_http_header;
        $z->print( $json );
        $z->close;
    }
    elsif( CORE::length( $json ) > $threshold && 
        $self->request->accept_encoding =~ /\bbzip2\b/i &&
        $self->_load_class( 'IO::Compress::Bzip2' ) &&
        ( $z = IO::Compress::Bzip2->new( '-' ) ) )
    {
        # $r->content_encoding( 'bzip2' );
        $self->response->content_encoding( 'bzip2' );
        $self->response->headers->set( 'Content-Encoding' => 'bzip2' );
        $self->response->headers->merge( 'Vary' => 'Accept-Encoding' );
        # $r->send_http_header;
        $z->print( $json );
        $z->close;
    }
    elsif( CORE::length( $json ) > $threshold && 
        $self->request->accept_encoding =~ /\bdeflate\b/i && 
        $self->_load_class( 'IO::Compress::Deflate' ) &&
        ( $z = IO::Compress::Deflate->new( '-' ) ) )
    {
        ## $r->content_encoding( 'deflate' );
        $self->response->content_encoding( 'deflate' );
        $self->response->headers->set( 'Content-Encoding' => 'deflate' );
        $self->response->headers->merge( 'Vary' => 'Accept-Encoding' );
        # $r->send_http_header;
        $z->print( $json );
        $z->close;
    }
    else
    {
        $self->response->headers->unset( 'Content-Encoding' );
        # $self->response->content_encoding( undef() );
        # $r->send_http_header;
        # $r->print( $json );
        # $json = Encode::encode_utf8( $json ) if( utf8::is_utf8( $json ) );
        # try-catch
        local $@;
        eval
        {
            my $bytes = $r->print( $json );
        };
        if( $@ )
        {
        }
    }
    # $r->rflush;
    # Flush any buffered data to the client using Apache2::RequestIO
    $self->response->rflush;
    return( $self );
}

# push_handlers($hook_name => \&handler);
# push_handlers($hook_name => [\&handler, \&handler2]);
sub push_handlers { return( shift->_try( 'server', 'push_handlers', @_ ) ); }

sub reply
{
    my $self = shift( @_ );
    my( $code, $ref );
    # $self->reply( Apache2::Const::HTTP_OK, { message => "All is well" } );
    if( scalar( @_ ) == 2 )
    {
        ( $code, $ref ) = @_;
    }
    elsif( scalar( @_ ) == 1 &&
        $self->_can( $_[0] => 'code' ) && 
        $self->_can( $_[0] => 'message' ) )
    {
        my $ex = shift( @_ );
        $code = $ex->code;
        $ref = 
        {
            message => $ex->message,
            ( $ex->can( 'public_message' ) ? ( public_message => $ex->public_message ) : () ),
            ( $ex->can( 'locale' ) ? ( locale => $ex->locale ) : () ),
        };
    }
    # $self->reply({ code => Apache2::Const::HTTP_OK, message => "All is well" } );
    elsif( ref( $_[0] ) eq 'HASH' )
    {
        $ref = shift( @_ );
        $code = $ref->{code} if( CORE::length( $ref->{code} ) );
    }
    my $r = $self->apache_request;
    if( $code !~ /^[0-9]+$/ )
    {
        $self->response->code( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        $self->response->rflush;
        $self->response->print( $self->json->utf8->encode({ error => 'An unexpected server error occured', code => 500 }) );
        $self->error( "http code to be used '$code' is invalid. It should be only integers." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    if( ref( $ref ) ne 'HASH' )
    {
        $self->response->code( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        $self->response->rflush;
        # $r->send_http_header;
        $self->response->print( $self->json->utf8->encode({ error => 'An unexpected server error occured', code => 500 }) );
        $self->error( "Data provided to send is not an hash ref." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    
    my $msg;
    if( CORE::exists( $ref->{success} ) )
    {
        $msg = $ref->{success};
    }
    # Maybe error is a string, or maybe it is already an error hash like { error => { message => '', code => '' } }
    elsif( CORE::exists( $ref->{error} ) && !Apache2::API::Status->is_success( $code ) )
    {
        if( ref( $ref->{error} ) eq 'HASH' )
        {
            $msg = $ref->{error}->{message};
        }
        else
        {
            $msg = $ref->{error};
            $ref->{error} = {};
        }
        $ref->{error}->{code} = $code if( !CORE::length( $ref->{error}->{code} ) );
        $ref->{error}->{message} = "$msg" if( !CORE::length( $ref->{error}->{message} ) && ( !ref( $msg ) || overload::Method( $msg => "''" ) ) );
        CORE::delete( $ref->{message} ) if( CORE::length( $ref->{message} ) );
        CORE::delete( $ref->{code} ) if( CORE::length( $ref->{code} ) );
    }
    elsif( CORE::exists( $ref->{message} ) )
    {
        $msg = $ref->{message};
        # We format the message like in bailout, ie { error => { message => '', code => '' } }
        if( $self->response->is_error( $code ) )
        {
            $ref->{error} = {} if( ref( $ref->{error} ) ne 'HASH' );
            $ref->{error}->{code} = $code if( !CORE::length( $ref->{error}->{code} ) );
            $ref->{error}->{message} = $ref->{message} if( !CORE::length( $ref->{error}->{message} ) );
            CORE::delete( $ref->{message} ) if( CORE::length( $ref->{message} ) );
            CORE::delete( $ref->{code} ) if( CORE::length( $ref->{code} ) );
        }
        else
        {
            # All is good already
        }
    }
    elsif( $self->response->is_error( $code ) )
    {
        $ref->{error} = {} if( !CORE::exists( $ref->{error} ) || ref( $ref->{error} ) ne 'HASH' );
        $ref->{error}->{code} = $code if( !CORE::length( $ref->{error}->{code} ) );
        CORE::delete( $ref->{code} ) if( CORE::length( $ref->{code} ) );
    }

    my $frameOffset = 0;
    my $sub = ( caller( $frameOffset + 1 ) )[3];
    $frameOffset++ if( substr( $sub, rindex( $sub, '::' ) + 2 ) eq 'reply' );
    my( $pack, $file, $line ) = caller( $frameOffset );
    $sub = ( caller( $frameOffset + 1 ) )[3];
    # Without an Access-Control-Allow-Origin field, this would trigger an erro ron the web browser
    # So we make sure it is there if not set already
    unless( $self->response->headers->get( 'Access-Control-Allow-Origin' ) )
    {
        $self->response->headers->set( 'Access-Control-Allow-Origin' => '*' );
    }
    # As an api, make sure there is no caching by default unless the field has already been set.
    unless( $self->response->headers->get( 'Cache-Control' ) )
    {
        $self->response->headers->set( 'Cache-Control' => 'private, no-cache, no-store, must-revalidate' );
    }
    $self->response->content_type( 'application/json' );
    # $r->status( $code );
    $self->response->code( $code );
    if( defined( $msg ) && $self->apache_request->content_type ne 'application/json' )
    {
        # $r->custom_response( $code, $msg );
        $self->response->custom_response( $code, $msg );
    }
    else
    {
        # $r->custom_response( $code, '' );
        $self->response->custom_response( $code, '' );
        #$r->status( $code );
    }
    
    # We make sure the code is set
    if( CORE::exists( $ref->{error} ) && !$self->response->is_success( $code ) )
    {
        $ref->{error}->{code} = $code if( ref( $ref->{error} ) eq 'HASH' && !CORE::length( $ref->{error}->{code} ) );
        my $lang = $self->lang_unix;
        if( !length( "$lang" ) && $ref->{locale} )
        {
            $lang = $ref->{locale};
        }
        
        unless( length( "$lang" ) )
        {
            $lang = $self->request->preferred_language( Apache2::API::Status->supported_languages );
            # Make sure we are dealing with unix style language code
            $lang =~ tr/-/_/;
            if( CORE::length( $lang ) == 2 )
            {
                $lang = Apache2::API::Status->convert_short_lang_to_long( $lang );
            }
            # We have something weird, like maybe eng?
            elsif( $lang !~ /^[a-z]{2}_[A-Z]{2}$/ )
            {
                $lang = Apache2::API::Status->convert_short_lang_to_long( substr( $lang, 0, 2 ) );
            }
        }
        my $err_description;
        if( !$ref->{error}->{error_description} && ( $err_description = $self->response->get_http_message( $code, $lang ) ) )
        {
            $ref->{error}->{error_description} = $err_description;
        }
        else
        {
            $ref->{error}->{error_description} = $self->gettext( $self->response->get_http_message( $code ) );
        }

        if( !exists( $ref->{error}->{locale} ) &&
            defined( $msg ) && 
            $self->_is_a( $msg => 'Text::PO::String' ) && 
            defined( my $locale = $msg->locale ) )
        {
            $ref->{error}->{locale} = $locale if( length( "$locale" ) );
        }
        elsif( !exists( $ref->{error}->{locale} ) &&
               defined( $lang ) &&
               length( "$lang" ) )
        {
            $ref->{error}->{locale} = $lang;
        }
    }
    else
    {
        $ref->{code} = $code if( !CORE::length( $ref->{code} ) );
        if( !exists( $ref->{locale} ) &&
            defined( $msg ) && 
            $self->_is_a( $msg => 'Text::PO::String' ) && 
            defined( my $locale = $msg->locale ) )
        {
            $ref->{locale} = $locale if( length( "$locale" ) );
        }
    }
    
    if( CORE::exists( $ref->{cleanup} ) &&
        defined( $ref->{cleanup} ) &&
        ref( $ref->{cleanup} ) eq 'CODE' )
    {
        my $cleanup = CORE::delete( $ref->{cleanup} );
        # See <https://perl.apache.org/docs/2.0/user/handlers/http.html#PerlCleanupHandler>
        $self->request->request->pool->cleanup_register( $cleanup, $self );
        # $r->push_handlers( PerlCleanupHandler => $cleanup );
    }
    
    # Our print() will possibly change the HTTP headers, so we do not flush now just yet.
    my $json = $self->json->utf8->relaxed(0)->allow_blessed->convert_blessed->encode( $ref );
    # Before we use this, we have to make sure all Apache module that deal with content encoding are de-activated because they would interfere
    $self->print( $json ) || do
    {
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    };
    return( $code );
}

sub request { return( shift->_set_get_object( 'request', 'Apache2::API::Request', @_ ) ); }

sub response { return( shift->_set_get_object( 'response', 'Apache2::API::Response', @_ ) ); }

sub server
{
    my $self = shift( @_ );
    # try-catch
    local $@;
    my $rv = eval
    {
        my $r = $self->apache_request;
        return( $r->server ) if( $r );
        return( Apache2::ServerUtil->server );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to get the Apache server object: $@" ) );
    }
    return( $rv );
}

# sub server_version { return( version->parse( Apache2::ServerUtil::get_server_version ) ); }
# Or maybe the environment variable SERVER_SOFTWARE, e.g. Apache/2.4.18
# sub server_version { return( version->parse( Apache2::ServerUtil::get_server_version ) ); }
sub server_version 
{
    my $self = shift( @_ );
    my $v = $self->request->server_version || return( $self->pass_error( $self->request->error ) );
    return( version->parse( $v ) );
}

# $ok = $s->set_handlers($hook_name => \&handler);
# $ok = $s->set_handlers($hook_name => [\&handler, \&handler2]);
# $ok = $s->set_handlers($hook_name => []);
# $ok = $s->set_handlers($hook_name => undef);
# https://perl.apache.org/docs/2.0/api/Apache2/ServerUtil.html#C_set_handlers_
sub set_handlers { return( shift->_try( 'server', 'set_handlers', @_ ) ); }

sub warn
{
    my $self = shift( @_ );
    my $txt = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
    my( $pkg, $file, $line, @otherInfo ) = caller;
    my $sub = ( caller( 1 ) )[3];
    my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
    my $trace = $self->_get_stack_trace();
    my $frame = $trace->next_frame;
    my $frame2 = $trace->next_frame;
    my $r = $self->apache_request;
    $txt = sprintf( "$txt called from %s in package %s in file %s at line %d\n%s\n",  $frame2->subroutine, $frame->package, $frame->filename, $frame->line, $trace->as_string );
    return( $r->warn( $txt ) ) if( $r );
    return( CORE::warn( $txt ) );
}

sub _try
{
    my $self = shift( @_ );
    my $pack = shift( @_ ) || return( $self->error( "No Apache package name was provided to call method" ) );
    my $meth = shift( @_ ) || return( $self->error( "No method name was provided to try!" ) );
    my $r = Apache2::RequestUtil->request;
    # $r->log_error( "Apache2::API::_try to call method \"$meth\" in package \"$pack\"." );
    # try-catch
    local $@;
    my $rv = eval
    {
        return( $self->$pack->$meth ) if( !scalar( @_ ) );
        return( $self->$pack->$meth( @_ ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to call Apache ", ucfirst( $pack ), " method \"$meth\": $@" ) );
    }
    return( $rv );
}

# NOTE: sub FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Apache2::API - Apache2 API Framework

=head1 SYNOPSIS

    use Apache2::API
    # To import in your namespace
    # use Apache2::API qw( :common :http );
    
    # $r is an Apache2::RequestRec object that you can get from within an handler or 
    # with Apache2::RequestUtil->request
    my $api = Apache2::API->new( $r, compression_threshold => 204800 ) ||
        die( Apache2::API->error );
    # or:
    my $api = Apache2::API->new( apache_request => $r, compression_threshold => 204800 ) ||
        die( Apache2::API->error );

    # or even inside your mod_perl script/cgi:
    #!/usr/bin/perl
    use strict;
    use warnings;
    use Apache2::API;
    
    my $r = shift( @_ );
    my $api = Apache2::API->new( $r );
    # for example:
    return( $api->reply( Apache2::Const::HTTP_OK => { message => "Hello world" } ) );

    my $r = $api->apache_request;
    return( $api->bailout({
        message => "Oops",
        code => Apache2::Const::BAD_REQUEST,
        public_message => "An unexpected error occurred.",
    }) );
    # or
    return( $api->bailout( @some_reasons ) );
    
    # 100kb
    $api->compression_threshold(102400);
    my $decoded = $api->decode_base64( $b64_string );
    my $ref = $api->decode_json( $json_data );
    my $decoded = $api->decode_url;
    my $perl_utf8 = $api->decode_utf8( $data );
    my $b64_string = $api->encode_base64( $data );
    my $json_data = $api->encode_json( $ref );
    my $encoded = $api->encode_url( $uri );
    my $utf8 = $api->encode_utf8( $data );
    my $uuid = $api->generate_uuid;
    my $auth = $api->get_auth_bearer;
    my $handlers = $api->get_handlers;
    my $dt = $api->header_datetime( $http_datetime );
    my $bool = $api->is_perl_option_enabled;
    # JSON object
    my $json = $api->json( pretty => 1, sorted => 1, relaxed => 1 );
    my $lang = $api->lang( 'en_GB' );
    # en_GB
    my $lang = $api->lang_unix;
    # en-GB
    my $lang = $api->lang_web;
    $api->log_error( "Oops" );
    $api->print( @some_data );
    $api->push_handlers( $name => $code_reference );
    return( $api->reply( Apache2::Const::HTTP_OK => {
        message => "All good!",
        # arbitrary property
        client_id => "efe4bcf3-730c-4cb2-99df-25d4027ec404",
        # special property
        cleanup => sub
        {
            # Some code here to be executed after the reply is sent out to the client.
        }
    }) );
    # Apache2::API::Request
    my $req = $api->request;
    # Apache2::API::Response
    my $req = $api->response;
    my $server = $api->server;
    my $version = $api->server_version;
    $api->set_handlers( $name => $code_reference );
    $api->warn( @some_warnings );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module provides a comprehensive, powerful, yet simple framework to access L<Apache mod_perl's API|https://perl.apache.org/docs/2.0/api/> and documented appropriately.

Apache mod_perl is an awesome framework, but quite complexe with a steep learning curve and methods all over the place. So much so that L<they have developed a module dedicated to find appropriate methods|https://perl.apache.org/docs/2.0/user/coding/coding.html#toc_Where_the_Methods_Live> with L<ModPerl::MethodLookup>

=head1 METHODS

=head2 new

    my $api = Apache2::API->new( $r, $hash_ref_of_options );
    # or
    my $api = Apache2::API->new( apache_request => $r, compression_threshold => 102400 );

This initiates the package and takes an L<Apache2::RequestRec> object and an hash or hash reference of parameters, or only an hash or hash reference of parameters:

=over 4

=item * C<apache_request>

See L</apache_request>

=item * C<compression_threshold>

See L</compression_threshold>

=item * C<debug>

Optional. If set with a positive integer, this will activate debugging message

=back

=head2 apache_request

Returns the L<Apache2::RequestRec> object that was provided upon object instantiation.

=head2 bailout

    $api->bailout( $error_string );
    $api->bailout( { code => 400, message => $internal_message } );
    $api->bailout( { code => 400, message => $internal_message, public_message => "Sorry!" } );

Given an error message, this will prepare the HTTP header and response accordingly.

It will call L</gettext> to get the localised version of the error message, so this method is expected to be overriden by inheriting package.

If the outgoing content type set is C<application/json> then this will return a properly formatted standard json error, such as:

    { "error": { "code": 401, "message": "Something went wrong" } }

Otherwise, it will send to the client the message as is.

=head2 compression_threshold( $integer )

The number of bytes threshold beyond which, the L</reply> method will gzip compress the data returned to the client.

=head2 decode_base64( $data )

Given some data, this will decode it using base64 algorithm. It uses L<APR::Base64/decode> in the background.

=head2 decode_json( $data )

This decode from utf8 some data into a perl structure using L<JSON>

If an error occurs, it will return undef and set an exception that can be accessed with the L<error|Module::Generic/error> method.

=head2 decode_url( $string )

Given a url-encoded string, this returns the decoded string using L<APR::Request/decode>

=head2 decode_utf8( $data )

Decode some data from ut8 into perl internal utf8 representation using L<Encode>

If an error occurs, it will return undef and set an exception that can be accessed with the L<error|Module::Generic/errir> method.

=head2 encode_base64( $data )

Given some data, this will encode it using base64 algorithm. It uses L<APR::Base64/encode>.

=head2 encode_json( $hash_reference )

Given a hash reference, this will encode it into a json data representation.

However, this will not utf8 encode it, because this is done upon printing the data and returning it to the client.

The JSON object has the following properties enabled: C<allow_nonref>, C<allow_blessed>, C<convert_blessed> and C<relaxed>

=head2 encode_url( $string )

Given a string, this returns its url-encoded version using L<APR::Request/encode>

=head2 encode_utf8( $data )

This encode in ut8 the data provided and return it.

If an error occurs, it will return undef and set an exception that can be accessed with the B<error> method.

=head2 generate_uuid

Generates an uuid string and return it. This uses L<APR::UUID>

=head2 get_auth_bearer

Checks whether an C<Authorization> HTTP header was provided, and get the Bearer value.

If no header was found, it returns an empty string.

If an error occurs, it will return undef and set an exception that can be accessed with the B<error> method.

=head2 get_handlers

Returns a reference to a list of handlers enabled for a given phase.

    $handlers_list = $res->get_handlers( $hook_name );

A list of handlers configured to run at the child_exit phase:

    @handlers = @{ $res->get_handlers( 'PerlChildExitHandler' ) || []};

=head2 gettext( 'string id' )

Get the localised version of the string passed as an argument.

This is supposed to be superseded by the package inheriting from L<Apache2::API>, if any.

=head2 header_datetime( DateTime object )

Given a L<DateTime> object, this sets it to GMT time zone and set the proper formatter (L<Apache2::API::DateTime>) so that the stringification is compliant with HTTP headers standard.

=head2 is_perl_option_enabled

Checks if perl option is enabled in the Virtual Host and returns a boolean value

=head2 json

Returns a JSON object.

You can provide an optional hash or hash reference of properties to enable or disable:

    my $J = $api->json( pretty => 1, relaxed => 1 );

Each property corresponds to one that is supported by L<JSON>

It also supports C<ordered>, C<order> and C<sort> as an alias to C<canonical>

=head2 lang( $string )

Set or get the language for the API. This would typically be the HTTP preferred language.

=head2 lang_unix( $string )

Given a language, this returns a language code formatted the unix way, ie en-GB would become en_GB

=head2 lang_web( $string )

Given a language, this returns a language code formatted the web way, ie en_GB would become en-GB

=head2 log_error( $string )

Given a string, this will log the data into the error log.

When log_error is accessed with the L<Apache2::RequestRec> the error gets logged into the Virtual Host log, but when log_error gets accessed via the L<Apache2::ServerUtil> object, the error get logged into the Apache main error log.

=head2 print( @list )

print out the list of strings and returns the number of bytes sent.

The data will possibly be compressed if the HTTP client L<acceptable encoding|HTTPs://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding> and if the data exceeds the value set in L</compression_threshold>

It will gzip it if the HTTP client acceptable encoding is C<gzip> and if L<IO::Compress::Gzip> is installed.

It will bzip it if the HTTP client acceptable encoding is C<bzip2> and if L<IO::Compress::Bzip2> is installed.

It will deflate if if the HTTP client acceptable encoding is C<deflate> and L<IO::Compress::Deflate> is installed.

If none of the above is possible, the data will be returned uncompressed.

Note that the HTTP header C<Vary> will be added the C<Accept-Encoding> value.

=head2 push_handlers

Returns the values from L<Apache2::Server/push_handlers> by passing it whatever arguments were provided.

=head2 reply

This takes an HTTP code and a message, or an exception object such as L<Module::Generic::Exception> or any other object that supports the C<code> and C<message> method, or just a hash reference, B<reply> will find out if the code provided is an error and format the replied json appropriately like:

    { "error": { "code": 400, "message": "Some error" } }

It will json encode the returned data and print it out back to the client after setting the HTTP returned code.

If a C<cleanup> hash property is provided with a callback code reference as a value, it will be set as a cleanup callback by calling C<< $r->pool->cleanup_register >>. See L<https://perl.apache.org/docs/2.0/user/handlers/http.html#PerlCleanupHandler>

The L<Apache2::API> object will be passed as the first and only argument to the callback routine.

=head2 request()

Returns the L<Apache2::API::Request> object. This object is set upon instantiation.

=head2 response

Returns the L<Apache2::API::Response> object. This object is set upon instantiation.

=head2 server()

Returns a L<Apache2::Server> object

=head2 server_version()

Tries hard to find out the version number of the Apache server. This returns the value from L<Apache2::API::Request/server_version>

=head2 set_handlers()

Returns the values from L<Apache2::Server/set_handlers> by passing it whatever arguments were provided.

=head2 warn( @list )

Given a list of string, this sends a warning using L<Apache2::Log/warn>

=head2 _try( $object_type, $method_name, @_ )

Given an object type, a method name and optional parameters, this attempts to call it, passing it whatever arguments were provided and return its return values.

Apache2 methods are designed to die upon error, whereas our model is based on returning C<undef> and setting an exception with L<Module::Generic::Exception>, because we believe that only the main program should be in control of the flow and decide whether to interrupt abruptly the execution, not some sub routines.

=head1 CONSTANTS

C<mod_perl> provides constants through L<Apache2::Constant> and L<APR::Constant>. L<Apache2::API> makes all those constants available using their respective package name, such as:

    use Apache2::API;
    say Apache2::Const::HTTP_BAD_REQUEST; # 400

You can import constants into your namespace by specifying them when loading L<Apache2::API>, such as:

    use Apache2::API qw( HTTP_BAD_REQUEST );
    say HTTP_BAD_REQUEST; # 400

Be careful, however, that there are over 400 Apache2 constants and some common constant names in L<Apache2::Constant> and L<APR::Constant>, so it is recommended to use the fully qualified constant names rather than importing them into your namespace.

=head1 INSTALLATION

As usual, to install this module, you can do:

    perl Makefile.PL
    make
    make test
    # or
    # t/TEST
    sudo make install

If you have Apache/modperl2 installed, this will also prepare the Makefile and run test under modperl.

The Makefile.PL tries hard to find your Apache configuration, but you can give it a hand by specifying some command line parameters.

For example:

    perl Makefile.PL -apxs /usr/bin/apxs -port 1234
    # which will also set the path to httpd_conf, otherwise
    perl Makefile.PL -httpd_conf /etc/apache2/apache2.conf

    # then
    make
    make test
    # or
    # t/TEST
    sudo make install

You can also enable a lot of debugging output with:

    API_DEBUG=1 perl Makefile.PL

And if your terminal supports it, you can show output in colours with:

    APACHE_TEST_COLOR=1 perl Makefile.PL

See also L<modperl testing documentation|https://perl.apache.org/docs/general/testing/testing.html>

But, if for some reason, you do not want to perform the mod_perl tests, you can use C<NO_MOD_PERL=1> when calling C<perl Makefile.PL>, such as:

    NO_MOD_PERL=1 perl Makefile.PL
    make
    make test
    sudo make install

To run individual test, you can do, for example:

    t/TEST t/01.api.t

or, in verbose mode:

    t/TEST -verbose t/01.api.t

=head2 Makefile.PL options

Here are the available options to use when building the C<Makefile.PL>:

=over 4

=item C<-access_module_name>

access module name

=item C<-apxs>

location of apxs (default is from L<Apache2::BuildConfig>)

=item C<-auth_module_name>

auth module name

=item C<-bindir>

Apache bin/ dir (default is C<apxs -q BINDIR>)

=item C<-cgi_module_name>

cgi module name

=item C<-defines>

values to add as C<-D> defines (for example, C<"VAR1 VAR2">)

=item C<-documentroot>

DocumentRoot (default is C<$ServerRoot/htdocs>

=item C<-group>

Group to run test server as (default is C<$GROUP>)

=item C<-httpd>

server to use for testing (default is C<$bindir/httpd>)

=item C<-httpd_conf>

inherit config from this file (default is apxs derived)

=item C<-httpd_conf_extra>

inherit additional config from this file

=item C<-libmodperl>

path to mod_perl's .so (full or relative to LIBEXECDIR)

=item C<-limitrequestline>

global LimitRequestLine setting (default is C<128>)

=item C<-maxclients>

maximum number of concurrent clients (default is minclients+1)

=item C<-minclients>

minimum number of concurrent clients (default is C<1>)

=item C<-perlpod>

location of perl pod documents (for testing downloads)

=item C<-php_module_name>

php module name

=item C<-port>

Port [port_number|select] (default C<8529>)

=item C<-proxyssl_url>

url for testing ProxyPass / https (default is localhost)

=item C<-sbindir>

Apache sbin/ dir (default is C<apxs -q SBINDIR>)

=item C<-servername>

ServerName (default is C<localhost>)

=item C<-serverroot>

ServerRoot (default is C<$t_dir>)

=item C<-src_dir>

source directory to look for C<mod_foos.so>

=item C<-ssl_module_name>

ssl module name

=item C<-sslca>

location of SSL CA (default is C<$t_conf/ssl/ca>)

=item C<-sslcaorg>

SSL CA organization to use for tests (default is asf)

=item C<-sslproto>

SSL/TLS protocol version(s) to test

=item C<-startup_timeout>

seconds to wait for the server to start (default is C<60>)

=item C<-t_conf>

the conf/ test directory (default is C<$t_dir/conf>)

=item C<-t_conf_file>

test httpd.conf file (default is C<$t_conf/httpd.conf>)

=item C<-t_dir>

the t/ test directory (default is C<$top_dir/t>)

=item C<-t_logs>

the logs/ test directory (default is C<$t_dir/logs>)

=item C<-t_pid_file>

location of the pid file (default is C<$t_logs/httpd.pid>)

=item C<-t_state>

the state/ test directory (default is C<$t_dir/state>)

=item C<-target>

name of server binary (default is C<apxs -q TARGET>)

=item C<-thread_module_name>

thread module name

=item C<-threadsperchild>

number of threads per child when using threaded MPMs (default is C<10>)

=item C<-top_dir>

top-level directory (default is C<$PWD>)

=item C<-user>

User to run test server as (default is C<$USER>)

=back

See also L<Apache::TestMM> for available parameters or you can type on the command line:

    perl -MApache::TestConfig -le 'Apache::TestConfig::usage()'

=head2 Tesging options

For example, specifying a port to use:

    t/TEST -start-httpd -port=34343
    t/TEST -run-tests
    t/TEST -stop-httpd

You can run C<< t/TEST -help >> to get the list of options. See below as well:

=over 4

=item C<-breakpoint=bp>

set breakpoints (multiply bp can be set)

=item C<-bugreport>

print the hint how to report problems

=item C<-clean>

remove all generated test files

=item C<-configure>

force regeneration of httpd.conf  (tests will not be run)

=item C<-debug[=name]>

start server under debugger name (gdb, ddd, etc.)

=item C<-get>

GET url

=item C<-head>

HEAD url

=item C<-header>

add headers to (get|post|head) request

=item C<-help>

display this message

=item C<-http11>

run all tests with C<HTTP/1.1> (keep alive) requests

=item C<-no-httpd>

run the tests without configuring or starting httpd

=item C<-one-process>

run the server in single process mode

=item C<-order=mode>

run the tests in one of the modes: (repeat|random|SEED)

=item C<-ping[=block]>

test if server is running or port in use

=item C<-post>

POST url

=item C<-postamble>

config to add at the end of C<httpd.conf>

=item C<-preamble>

config to add at the beginning of C<httpd.conf>

=item C<-proxy>

proxy requests (default proxy is localhost)

=item C<-run-tests>

run the tests

=item C<-ssl>

run tests through ssl

=item C<-start-httpd>

start the test server

=item C<-stop-httpd>

stop the test server

=item C<-trace=T>

change tracing default to: warning, notice, info, debug, ...

=item C<-verbose[=1]>

verbose output

=back

See for more information L<https://perl.apache.org/docs/general/testing/testing.html>

=head2 API CORE MODULES

L<Apache2::RequestIO>, L<Apache2::RequestRec>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API::DateTime>, L<Apache2::API::Query>, L<Apache2::API::Request>, L<Apache2::API::Request::Params>, L<Apache2::API::Request::Upload>, L<Apache2::API::Response>, L<Apache2::API::Status>

L<Apache2::Request>, L<Apache2::RequestRec>, L<Apache2::RequestUtil>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
