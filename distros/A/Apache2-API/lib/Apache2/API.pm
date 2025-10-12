##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API.pm
## Version v0.4.1
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
package Apache2::API;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $DEBUG @EXPORT );
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
    use Exporter ();
    use JSON ();
    use Scalar::Util ();
    our @EXPORT = qw( apr1_md5 );
    $DEBUG   = 0;
    $VERSION = 'v0.4.1';
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
    Exporter::export_to_level( $this, 1, @EXPORT );
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

sub apr1_md5
{
    my( $passwd, $salt ) = @_;
    my $ht = Apache2::API::Password->new( $passwd, create => 1, algo => 'md5', ( defined( $salt ) ? ( salt => $salt ) : () ) ) ||
        die( Apache2::API::Password->error );
    return( $ht->hash );
}

sub bailout
{
    my $self = shift( @_ );
    my $msg;
    if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
    {
        $msg = shift( @_ );
    }
    elsif( scalar( @_ ) == 1 && $self->_is_a( $_[0] => 'Module::Generic::Exception' ) )
    {
        my $ex = shift( @_ );
        $msg = {};
        if( my $code = $ex->code )
        {
            $msg->{code} = $code;
        }
        else
        {
            $msg->{code} = Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
        }
        $msg->{message} = $ex->message;
        my $lang;
        if( $ex->can( 'type' ) && ( my $type = $ex->type ) )
        {
            $msg->{type} = $type;
        }
        if( !$msg->{lang} && $ex->can( 'lang' ) && ( $lang = $ex->lang ) )
        {
            $msg->{lang} = $lang;
        }
        elsif( !$msg->{lang} && $ex->can( 'locale' ) && ( $lang = $ex->locale ) )
        {
            $msg->{lang} = $lang;
        }
        warn( $msg->{message} ) if( $msg->{message} );
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
    my $sub_str = ( caller(1) )[3];
    my $sub = CORE::index( $sub_str, '::' ) != -1 ? substr( $sub_str, rindex( $sub_str, '::' ) + 2 ) : $sub_str;
    # Now we tweak the hash to send it to the client
    $msg->{message} = CORE::delete( $msg->{public_message} ) || 'An unexpected server error has occurred';
    # Give it a chance to be localised
    $msg->{message} = $self->gettext( $msg->{message} );
    # For example, if the message is a Text::PO::Gettext::String object
    if( !$msg->{lang} && $self->_can( $msg->{message} => 'lang' ) )
    {
        $msg->{lang} = $msg->{message}->lang;
    }
    elsif( !$msg->{lang} && $self->_can( $msg->{message} => 'locale' ) )
    {
        $msg->{lang} = $msg->{message}->locale;
    }
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

sub htpasswd
{
    my $self = shift( @_ );
    my $rv = Apache2::API::Password->new( @_ );
    if( !defined( $rv ) && Apache2::API::Password->error )
    {
        return( $self->pass_error( Apache2::API::Password->error ) );
    }
    return( $rv );
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

# Would return a Apache2::Log::Request
sub log { return( shift->_try( 'apache_request', 'log', @_ ) ); }

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
    $self->response->content_type( 'application/json; charset=utf-8' );
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
    if( !$self->print( $json ) )
    {
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    return( $code );
}

# Special reply for Server-Sent Event that need to close the connection if there was an error
sub reply_sse
{
    my $self = shift( @_ );
    my $code = $self->reply( @_ );
    $code //= 500;
    if( Apache2::API::Status->is_error( $code ) )
    {
        my $req = $self->request;
        $req->request->pool->cleanup_register(sub
        {
            $req->close;
        });
    }
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

# NOTE: Apache2::API::Password
package Apache2::API::Password;
use parent qw( Module::Generic );
use strict;
use warnings;
use vars qw( $VERSION $APR1_RE $BCRYPT_RE $SHA_RE );
# Compile the regular expression once
our $APR1_RE   = qr/\$apr1\$(?<salt>[.\/0-9A-Za-z]{1,8})\$[.\/0-9A-Za-z]{22}/;
our $BCRYPT_RE = qr/\$2[aby]\$(?<bcrypt_cost>\d{2})\$(?<salt>[A-Za-z0-9.\/]{22})[A-Za-z0-9.\/]{31}/;
our $SHA_RE    = qr/\$(?<sha_size>[56])\$(?:rounds=(?<rounds>\d+)\$)?(?<salt>[A-Za-z0-9.\/]{1,16})\$[A-Za-z0-9.\/]+/;
our $VERSION   = 'v0.1.0';

sub init
{
    my $self = shift( @_ );
    my $pwd  = shift( @_ );
    return( $self->error( "No password was provided." ) ) if( !defined( $pwd ) );
    $self->{create}        = 0     if( !exists( $self->{create} ) );
    # md5 | bcrypt | sha256 | sha512
    $self->{algo}          = 'md5' if( !exists( $self->{algo} ) );
    # 04..31
    $self->{bcrypt_cost}   = 12    if( !exists( $self->{bcrypt_cost} ) );
    # undef => default (5000)
    $self->{sha_rounds}    = undef if( !exists( $self->{sha_rounds} ) );
    # By default, like Apache does, we use Apache md5 algorithm
    # Other possibilities are bcrypt (Blowfish)
    $self->SUPER::init( @_ ) ||
        return( $self->pass_error );
    if( $self->{create} )
    {
        my $hash = $self->make( $pwd ) ||
            return( $self->pass_error );
        $self->hash( $hash );
    }
    # Existing hash path: validate by known prefixes, also extract salt into ->salt
    elsif( $pwd =~ /\A$APR1_RE\z/ ||
           $pwd =~ /\A$BCRYPT_RE\z/ ||
           $pwd =~ /\A$SHA_RE\z/ )
    {
        $self->hash( $pwd );
    }
    else
    {
        return( $self->error(
            "Value provided is not a recognized hash (APR1/bcrypt/SHA-crypt). " .
            "If you want to create one from clear text, use the 'create' option."
        ) );
    }
    return( $self );
}

sub algo { return( shift->_set_get_enum({
    field => 'algo',
    allowed => [qw( md5 bcrypt sha256 sha512 )],
}, @_ ) ); }

sub bcrypt_cost { return( shift->_set_get_scalar({
    field => 'bcrypt_cost',
    check => sub
    {
        my( $self, $v ) = @_;
        return(1) unless( defined( $v ) );
        unless( $v =~ /^\d+$/ && 
                $v >= 4 &&
                $v <= 31 )
        {
            return( $self->error( "bcrypt_cost must be between 4 and 31" ) );
        }
        return(1);
    },
}, @_ ) ); }

sub create { return( shift->_set_get_boolean( 'create', @_ ) ); }

sub hash { return( shift->_set_get_scalar({
    field => 'hash',
    callbacks =>
    {
        set => sub
        {
            my( $self, $v ) = @_;
            if( $v =~ /\A$APR1_RE\z/ )
            {
                $self->{salt} = $+{salt}
            }
            elsif( $v =~ /\A$BCRYPT_RE\z/ )
            {
                $self->{salt} = $+{salt};
                $self->{bcrypt_cost} = $+{bcrypt_cost};
            }
            elsif( $v =~ /\A$SHA_RE\z/ )
            {
                $self->{salt} = $+{salt};
                $self->{sha_rounds} = $+{rounds} if( defined( $+{rounds} ) );
            }
            else
            {
                return( $self->error( "Not a valid Apache hash (APR1/bcrypt/SHA-crypt)" ) );
            }
            return( $v );
        },
    },
}, @_ ) ); }

sub make
{
    my $self = shift( @_ );
    my( $passwd, $salt ) = @_;

    my $algo = lc( $self->{algo} || 'md5' );
    # md5, bcrypt, sha256, sha512
    my $code = $self->can( "make_${algo}" ) ||
        return( $self->error( "No method defined to handle algorithm '$algo'." ) );
    return( $code->( $self, $passwd, $salt ) );
}

sub make_bcrypt
{
    my $self = shift( @_ );
    my $passwd = shift( @_ );
    my $salt = shift( @_ ) || $self->{salt};

    my $cost = $self->bcrypt_cost;
    $cost = 12 if( !defined( $cost ) || $cost < 4 || $cost > 31 );

    # Generate a 22-char bcrypt-base64 salt. Easiest: draw from allowed alphabet.
    # (Most libc crypt() accept any 22 chars in the bcrypt alphabet.)

    # 22 chars from [./A-Za-z0-9]
    # $salt //= $self->_make_salt(22);
    $salt //= $self->_make_salt_bcrypt;
    if( $salt =~ m,[^./0-9A-Za-z], )
    {
        return( $self->error( "Salt value provided contains illegal characters." ) );
    }
    $salt = substr( $salt, 0, 22 );
    # pad if caller gave shorter
    $salt .= '.' x ( 22 - length( $salt ) ) if( length( $salt ) < 22 );

    # modular crypt format
    my $setting = sprintf( '$2y$%02d$%s', $cost, $salt );
    local $@;
    # try-catch
    my $hash = eval
    {
        crypt( $passwd, $setting );
    };
    if( !$@ && defined( $hash ) && $hash =~ /^\$2[aby]\$/ )
    {
        return( $hash );
    }

    # Save it, if any.
    my $crypt_error = $@;

    # Fallback 1: Authen::Passphrase::BlowfishCrypt
    if( $self->_load_class( 'Authen::Passphrase::BlowfishCrypt' ) )
    {
        my $ppr = eval
        {
            Authen::Passphrase::BlowfishCrypt->new(
                cost => $cost,
                salt_base64 => $salt,
                passphrase => $passwd,
            );
        };
        if( $@ )
        {
            return( $self->error( "Error instantiating a new Authen::Passphrase::BlowfishCrypt object for the bcrypt hash: $@" ) );
        }
        # $2a/$2y$...
        return( $ppr->as_crypt );
    }
    # Fallback 2: Crypt::Bcrypt
    elsif( $self->_load_class( 'Crypt::Bcrypt' ) )
    {
        my $bc = eval
        {
            Crypt::Bcrypt->new( cost => $cost, salt => $salt );
        };
        if( $@ )
        {
            return( $self->error( "Error instantiating a new Crypt::Bcrypt object for the bcrypt hash: $@" ) );
        }
        # returns $2b/$2y$...
        return( $bc->hash( $passwd ) );
    }
    # Fallback 3: Crypt::Eksblowfish::Bcrypt (settings must have bcrypt-base64 salt)
    elsif( $self->_load_class( 'Crypt::Eksblowfish::Bcrypt' ) )
    {
        $hash = eval
        {
            Crypt::Eksblowfish::Bcrypt::bcrypt( $passwd, $setting );
        };
        if( $@ )
        {
            return( $self->error( "Error generating bcrypt hash with Crypt::Eksblowfish::Bcrypt: $@" ) );
        }
        return( $hash );
    }
    elsif( $crypt_error )
    {
        return( $self->error( "Error generating bcrypt hash, and alternative modules (Authen::Passphrase::BlowfishCrypt, Crypt::Bcrypt, Crypt::Eksblowfish::Bcrypt) are not installed: $@" ) );
    }
    else
    {
        return( $self->error( "System crypt() does not support bcrypt, and alternative modules (Authen::Passphrase::BlowfishCrypt, Crypt::Bcrypt, Crypt::Eksblowfish::Bcrypt) are not installed." ) );
    }
}

sub make_md5
{
    my $self = shift( @_ );
    my $passwd = shift( @_ );
    my $salt = shift( @_ ) || $self->{salt};

    # salt: max 8 chars, allowed ./0-9A-Za-z
    $salt //= $self->_make_salt(8);
    if( $salt =~ m,[^./0-9A-Za-z], )
    {
        return( $self->error( "Salt value provided contains illegal characters." ) );
    }
    $salt = substr( $salt, 0, 8 );
    $self->_load_class( 'Digest::MD5' ) ||
        return( $self->pass_error );

    my $magic = '$apr1$';
    # 1) initial ctx: password + magic + salt
    my $ctx = Digest::MD5->new;
    local $@;
    # try-catch
    eval
    {
        $ctx->add( $passwd, $magic, $salt );
    };
    if( $@ )
    {
        return( $self->error( "Error adding string to create MD5 hash: $@" ) );
    }

    # 2) alternate sum: md5(password + salt + password)
    my $alt = Digest::MD5->new;
    eval
    {
        $alt->add( $passwd, $salt, $passwd );
    };
    if( $@ )
    {
        return( $self->error( "Error adding string to create MD5 hash: $@" ) );
    }
    # 16 bytes
    my $alt_result = $alt->digest;

    # 3) append to ctx as many full 16-byte blocks of alt_result
    my $plen = length( $passwd );
    for( my $i = $plen; $i > 0; $i -= 16 )
    {
        eval
        {
            $ctx->add( substr( $alt_result, 0, $i < 16 ? $i : 16 ) );
        };
        if( $@ )
        {
            return( $self->error( "Error adding string to create MD5 hash: $@" ) );
        }
    }

    # 4) mix in bytes based on bits of password length
    for( my $i = $plen; $i > 0; $i >>= 1 )
    {
        eval
        {
            if( $i & 1 )
            {
                $ctx->add( pack( 'C', 0 ) );
            }
            else
            {
                $ctx->add( substr( $passwd, 0, 1 ) );
            }
        };
        if( $@ )
        {
            return( $self->error( "Error adding string to create MD5 hash: $@" ) );
        }
    }

    # 16 bytes
    my $final = $ctx->digest;

    # 5) 1000 iterations "rounds"
    for( my $i = 0; $i < 1000; $i++ )
    {
        my $t = Digest::MD5->new;

        eval
        {
            if( $i & 1 )
            {
                $t->add( $passwd );
            }
            else
            {
                $t->add( $final );
            }

            if( $i % 3 )
            {
                $t->add( $salt );
            }

            if( $i % 7 )
            {
                $t->add( $passwd );
            }

            if( $i & 1 )
            {
                $t->add( $final );
            }
            else
            {
                $t->add( $passwd );
            }
        };
        if( $@ )
        {
            return( $self->error( "Error adding string to create MD5 hash: $@" ) );
        }

        $final = $t->digest;
    }

    # 6) rearrange final bytes and base64-like encode (crypt's 64-char set)
    my @b = unpack( 'C16', $final );
    my $itoa64 = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

    my $encoded = '';
    $encoded .= $self->_to64( ( $b[0] << 16 ) | ( $b[6] << 8 ) | $b[12], 4, $itoa64 );
    $encoded .= $self->_to64( ( $b[1] << 16 ) | ( $b[7] << 8 ) | $b[13], 4, $itoa64 );
    $encoded .= $self->_to64( ( $b[2] << 16 ) | ( $b[8] << 8 ) | $b[14], 4, $itoa64 );
    $encoded .= $self->_to64( ( $b[3] << 16 ) | ( $b[9] << 8 ) | $b[15], 4, $itoa64 );
    $encoded .= $self->_to64( ( $b[4] << 16 ) | ( $b[10] << 8 ) | $b[5], 4, $itoa64 );
    $encoded .= $self->_to64( $b[11], 2, $itoa64 );

    return( $magic . $salt . '$' . $encoded );
}

sub make_sha256 { return( shift->_make_sha_crypt( 5, @_ ) ); }

sub make_sha512 { return( shift->_make_sha_crypt( 6, @_ ) ); }

sub matches
{
    my $self = shift( @_ );
    my $pwd  = shift( @_ );
    my $hash = $self->{hash};
    return(0) unless( defined( $pwd ) && defined( $hash ) );
    local $@;

    if( $hash =~ /^\$apr1\$/ )
    {
        my $salt;
        # If the 'salt' is already set, we use it.
        unless( $salt = $self->{salt} )
        {
            if( $hash =~ /\A$APR1_RE\z/ )
            {
                $salt = $+{salt};
            }
            else
            {
                return(0);
            }
        }
        my $calc = $self->make_md5( $pwd, $salt ) ||
            return( $self->pass_error );
        return( $hash eq $calc );
    }
    # bcrypt
    elsif( $hash =~ /\A$BCRYPT_RE\z/ )
    {
        # crypt() verification: use the stored hash as the salt spec
        # try-catch
        my $out = eval
        {
            crypt( $pwd, $hash );
        };
        if( $@ || !defined( $out ) || $out !~ /^\$2[aby]\$/ )
        {
            # Save it, if any.
            my $crypt_error = $@;
            # Fallback 1: Authen::Passphrase::BlowfishCrypt
            if( $self->_load_class( 'Authen::Passphrase::BlowfishCrypt' ) )
            {
                # try-catch
                my $ppr = eval
                {
                    Authen::Passphrase::BlowfishCrypt->from_crypt( $hash );
                };
                if( $@ )
                {
                    return( $self->error( "Error instantiating a new Authen::Passphrase::BlowfishCrypt object for the bcrypt hash: $@" ) );
                }
                return( $ppr->match( $pwd ) );
            }
            # Fallback 2: Crypt::Bcrypt
            elsif( $self->_load_class( 'Crypt::Bcrypt' ) )
            {
                # try-catch
                my $bool = eval
                {
                    Crypt::Bcrypt::bcrypt_check( $pwd => $hash );
                };
                if( $@ )
                {
                    return( $self->error( "Error checking if password matches using Crypt::Bcrypt: $@" ) );
                }
                return( $bool );
            }
            # Fallback 3: Crypt::Eksblowfish::Bcrypt (settings must have bcrypt-base64 salt)
            elsif( $self->_load_class( 'Crypt::Eksblowfish::Bcrypt' ) )
            {
                # try-catch
                $out = eval
                {
                    Crypt::Eksblowfish::Bcrypt::bcrypt( $pwd, $hash );
                };
                if( $@ )
                {
                    return( $self->error( "Error generating bcrypt hash with Crypt::Eksblowfish::Bcrypt: $@" ) );
                }
                return( defined( $out ) && $out eq $hash );
            }
            elsif( $crypt_error )
            {
                return( $self->error( "Error checking bcrypt password: $crypt_error" ) );
            }
        }
        return( defined( $out ) && $out eq $hash );
    }
    elsif( $hash =~ /\A$SHA_RE\z/ )
    {
        # try-catch
        my $out = eval
        {
            crypt( $pwd, $hash );
        };
        if( defined( $out ) && $out eq $hash )
        {
            return(1);
        }
        # Save it, if any.
        my $crypt_error = $@;
    
        if( $self->_load_class( 'Crypt::Passwd::XS' ) )
        {
            # try-catch
            $out = eval
            {
                Crypt::Passwd::XS::crypt( $pwd, $hash );
            };
            if( $@ )
            {
                return( $self->error( "Error checking the password using Crypt::Passwd::XS: $@" ) );
            }
            return( defined( $out ) && $out eq $hash );
        }
        elsif( $crypt_error )
        {
            return( $self->error( "Error checking SHA password: $crypt_error" ) );
        }
        return(0);
    }
    else
    {
        return(0);
    }
}

sub salt { return( shift->_set_get_scalar( 'salt', @_ ) ); }

sub sha_rounds { return( shift->_set_get_number({
    field => 'sha_rounds',
    check => sub
    {
        my( $self, $n ) = @_;
        unless( $n =~ /^\d+$/ && 
                $n >= 1000 &&
                $n <= 999999999 )
        {
            return( $self->error( "sha_rounds must be between 1000 and 999999999" ) )
        }
        return(1);
    },
},  @_ ) ); }

sub _make_salt
{
    my $self = shift( @_ );
    # Default to 8 for MD5, 16 for bcrypt/SHA-2
    my $len  = shift( @_ ) || 8;
    if( $len !~ /^\d+$/ )
    {
        return( $self->error( "Length provided is not an integer." ) );
    }
    my @chars = ( '.', '/', 0..9, 'A'..'Z', 'a'..'z' );

    if( $self->_load_class( 'Crypt::URandom' ) )
    {
        my $raw = Crypt::URandom::urandom( $len );
        my $salt = '';
        for my $byte ( unpack( 'C*', $raw ) )
        {
            $salt .= $chars[ $byte % @chars ];
        }
        return( substr( $salt, 0, $len ) );
    }
    elsif( $self->_load_class( 'Bytes::Random::Secure' ) )
    {
        return( Bytes::Random::Secure::random_string_from( join( '', @chars ), $len ) );
    }

    my $salt = '';
    $salt .= $chars[ int( rand( @chars ) ) ] for 1..$len;
    return( $salt );
}

# 16 raw bytes -> 22-char bcrypt base64, using either the module helper
# or a tiny built-in encoder if the module isn't present.
sub _make_salt_bcrypt
{
    my $self = shift( @_ );
    # 1) get 16 cryptographically-strong random bytes
    my $raw;
    if( $self->_load_class( 'Crypt::URandom' ) )
    {
        $raw = Crypt::URandom::urandom(16);
    }
    elsif( $self->_load_class( 'Bytes::Random::Secure' ) )
    {
        # build 16 bytes from secure RNG
        my $rng = Bytes::Random::Secure->new;
        $raw = $rng->bytes(16);
    }
    else
    {
        # fallback: pseudo-random bytes (last resort)
        $raw = pack( 'C*', map{ int( rand(256) ) } 1..16 );
    }

    # 2) preferred: use Eksblowfish helper
    if( $self->_load_class( 'Crypt::Eksblowfish::Bcrypt' ) )
    {
        # 22 chars
        return( Crypt::Eksblowfish::Bcrypt::en_base64( $raw ) );
    }

    # 3) tiny bcrypt-base64 encoder (./A–Z a–z 0–9), 16 bytes -> 22 chars
    my $alpha = './ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    my @b = unpack( 'C*', $raw );
    my $out = '';
    for( my $i = 0; $i < @b; $i += 3 )
    {
        my $c1 = $b[$i];
        my $c2 = ( $i + 1 < @b ) ? $b[ $i + 1 ] : 0;
        my $c3 = ( $i + 2 < @b ) ? $b[ $i + 2 ] : 0;
        my $w  = ( $c1 << 16 ) | ( $c2 << 8 ) | $c3;
        # emit 4 chars, least-significant 6 bits first
        for( 1..4 )
        {
            $out .= substr( $alpha, $w & 0x3f, 1 );
            $w >>= 6;
        }
    }
    # bcrypt wants exactly 22 chars for 16-byte input
    return( substr( $out, 0, 22 ) );
}

sub _make_sha_crypt
{
    my $self = shift( @_ );
    # $which = 5 or 6
    my( $which, $passwd, $salt ) = @_;
    if( !defined( $which ) || !length( $which // '' ) )
    {
        return( $self->error( "No SHA version was provided. This should be 5 for 256, and 6 for 512." ) );
    }
    elsif( $which !~ /^\d$/ )
    {
        return( $self->error( "SHA version provided is not an integer." ) );
    }
    elsif( $which != 5 && $which != 6 )
    {
        return( $self->error( "Invalid SHA version provided. It should be either 5 or 6." ) );
    }
    # undef => default 5000
    my $rounds = $self->sha_rounds;

    $salt //= $self->_make_salt(16);
    if( $salt =~ m,[^./0-9A-Za-z], )
    {
        return( $self->error( "Salt value provided contains illegal characters." ) );
    }
    $salt = substr( $salt, 0, 16 );

    my $setting = defined( $rounds )
        ? sprintf( '$%d$rounds=%d$%s$', $which, $rounds, $salt )
        : sprintf( '$%d$%s$',           $which,          $salt );

    local $@;
    # try-catch
    my $hash = eval
    {
        crypt( $passwd, $setting );
    };
    if( !$@ && defined( $hash ) && $hash =~ /^\$[56]\$/ )
    {
        return( $hash );
    }

    my $crypt_error = $@;
    my $sha_version = ( $which == 5 ? 256 : 512 );

    # Fallback: Crypt::Passwd::XS
    if( $self->_load_class( 'Crypt::Passwd::XS' ) )
    {
        $hash = eval
        {
            # XS exposes a `crypt`-like function:
            Crypt::Passwd::XS::crypt( $passwd, $setting );
        };
        if( $@ )
        {
            return( $self->error( "Error generating a SHA-${sha_version} hash using Crypt::Passwd::XS: $@" ) );
        }
        elsif( defined( $hash ) && $hash =~ /^\$[56]\$/ )
        {
            return( $hash );
        }
        else
        {
            return( $self->error( "Unable to generate a SHA-${sha_version} hash using Crypt::Passwd::XS." ) );
        }
    }
    elsif( $crypt_error )
    {
        return( $self->error( "Error generating SHA-${sha_version} hash, and alternative modules (Crypt::Passwd::XS) are not installed: $@" ) );
    }
    else
    {
        return( $self->error( "System crypt() does not support SHA-${sha_version}, and alternative modules (Crypt::Passwd::XS) are not installed" ) );
    }
}

sub _to64
{
    my $self = shift( @_ );
    my( $v, $n, $itoa64 ) = @_;
    my $s = '';
    while( $n-- > 0 )
    {
        $s .= substr( $itoa64, $v & 0x3f, 1 );
        $v >>= 6;
    }
    return( $s );
}

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

    my $hash = apr1_md5( $clear_password );
    my $hash = apr1_md5( $clear_password, $salt );
    my $ht = $api->htpasswd( $clear_password );
    my $ht = $api->htpasswd( $clear_password, salt => $salt );
    my $hash = $ht->hash;
    say "Does our password match ? ", $ht->matches( $user_clear_password ) ? "yes" : "not";

=head1 VERSION

    v0.4.1

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

=head2 htpasswd

    my $ht = $api->htpasswd( $clear_password, create => 1 );
    my $ht = $api->htpasswd( $clear_password, create => 1, salt => $salt );
    my $ht = $api->htpasswd( $md5_password );
    my $bool = $ht->matches( $user_input_password );

This instantiates a new L<Apache2::API::Password> object by providing its constructor whatever arguments was received.

It returns a new L<Apache2::API::Password> object, or, upon error, C<undef> in scalar context, or an empty list in list context.

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

=head2 log

    $api->log->emerg( "Urgent message." );
    $api->log->alert( "Alert!" );
    $api->log->crit( "Critical message." );
    $api->log->error( "Error message." );
    $api->log->warn( "Warning..." );
    $api->log->notice( "You should know." );
    $api->log->info( "This is for your information." );
    $api->log->debug( "This is debugging message." );

Returns a L<Apache2::Log::Request> object.

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

=head2 reply_sse

Special reply for Server-Sent Event that need to close the connection if there was an error.

It takes the same arguments as L</reply>, call L</reply>, and if the return code is an HTTP error, it will close the HTTP connection.

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

=head1 CLASS FUNCTIONS

=head2 apr1_md5

    my $md5_password = apr1_md5( $clear_password );
    my $md5_password = apr1_md5( $clear_password, $salt );

This class function is exported by default.

It takes a clear password, and optionally a salt, and returns an Apache md5 encoded password.

This function merely instantiates a new L<Apache2::API::Password> object, and calls the method L<hash|Apache2::API::Password/hash> to return the encoded password.

The password returned is suitable to be used and saved in an Apache password file used in web basic authentication.

Upon error, this will die.

=head1 CONSTANTS

C<mod_perl> provides constants through L<Apache2::Constant> and L<APR::Constant>. L<Apache2::API> makes all those constants available using their respective package name, such as:

    use Apache2::API;
    say Apache2::Const::HTTP_BAD_REQUEST; # 400

You can import constants into your namespace by specifying them when loading L<Apache2::API>, such as:

    use Apache2::API qw( HTTP_BAD_REQUEST );
    say HTTP_BAD_REQUEST; # 400

Be careful, however, that there are over 400 Apache2 constants and some common constant names in L<Apache2::Constant> and L<APR::Constant>, so it is recommended to use the fully qualified constant names rather than importing them into your namespace.

Some constants are special like C<OK>, C<DECLINED> or C<DECLINE_CMD>

Apache L<underlines|https://perl.apache.org/docs/2.0/user/handlers/http.html#toc_HTTP_Request_Cycle_Phases> that "all handlers in the chain will be run as long as they return Apache2::Const::OK or Apache2::Const::DECLINED. Because stacked handlers is a special case. So don't be surprised if you've returned Apache2::Const::OK and the next handler was still executed. This is a feature, not a bug."

=over 4

=item * C<Apache2::Const::OK>

The only value that can be returned by all handlers is C<Apache2::Const::OK>, which tells Apache that the handler has successfully finished its execution.

=item * C<Apache2::Const::DECLINED>

This indicates success, but it's only relevant for phases of type RUN_FIRST (C<PerlProcessConnectionHandler>, C<PerlTransHandler>, C<PerlMapToStorageHandler>, C<PerlAuthenHandler>, C<PerlAuthzHandler>, C<PerlTypeHandler>, C<PerlResponseHandler>

Apache2 L<documentation explains|https://perl.apache.org/docs/2.0/api/Apache2/RequestRec.html#toc_C_allowed_> that "generally modules should C<Apache2::Const::DECLINED> any request methods they do not handle."

=item * C<Apache2::Const::DONE>

This "tells Apache to stop the normal HTTP request cycle and fast forward to the PerlLogHandler,"

=back

Check L<Apache documentation on handler return value|https://perl.apache.org/docs/2.0/user/handlers/intro.html#toc_Handler_Return_Values> for more information.

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
