##----------------------------------------------------------------------------
## Cookies API for Server & Client - ~/lib/Cookie.pm
## Version v0.3.5
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/10/08
## Modified 2024/02/13
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Cookie;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $SUBS $COOKIE_DEBUG );
    use DateTime;
    use DateTime::Format::Strptime;
    use Module::Generic::DateTime;
    use URI::Escape ();
    use overload (
        '""'     => \&as_string,
        bool     => sub{ return( $_[0] ) },
        # '""'     => sub{ $_[0]->as_string },
        'eq'     => \&same_as,
        '=='     => \&same_as,
        fallback => 1,
    );
    our $VERSION = 'v0.3.5';
    our $SUBS;
    our $COOKIE_DEBUG = 0;
    use constant CRYPTX_VERSION => '0.074';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    no overloading;
    $self->{name}       = undef;
    $self->{value}      = undef;
    $self->{comment}    = undef;
    $self->{commentURL} = undef;
    $self->{discard}    = 0;
    $self->{domain}     = undef;
    $self->{expires}    = undef;
    $self->{http_only}  = 0;
    # In the case of cookie sent from the server and no domain was set
    # This domain, which we need anyway, was provided implicitly or explicitly
    $self->{implicit}   = 0;
    $self->{max_age}    = undef;
    $self->{path}       = undef;
    $self->{port}       = undef;
    $self->{same_site}  = undef;
    $self->{secure}     = 0;
    $self->{accessed}   = time();
    $self->{created}    = time();
    # Ref: <https://stackoverflow.com/questions/41467012/what-is-the-difference-between-signed-and-encrypted-cookies-in-rails>
    # Integrity protection with Message Authentication Code (MAC)
    # e.g. Crypt::Mac::HMAC::hmac("SHA256","plop","Oh boy, this is cool")
    $self->{sign}       = 0;
    # Crypt::Cipher::AES
    # Crypt::Cipher
    # one of 'AES', 'Anubis', 'Blowfish', 'CAST5', 'Camellia', 'DES', 'DES_EDE',
    # 'KASUMI', 'Khazad', 'MULTI2', 'Noekeon', 'RC2', 'RC5', 'RC6',
    # 'SAFERP', 'SAFER_K128', 'SAFER_K64', 'SAFER_SK128', 'SAFER_SK64',
    # 'SEED', 'Skipjack', 'Twofish', 'XTEA', 'IDEA', 'Serpent'
    # simply any <NAME> for which there exists Crypt::Cipher::<NAME>
    # Encryption algorithm
    # Ref: <https://stackoverflow.com/questions/4147451/aes-vs-blowfish-for-file-encryption>
    $self->{algo}       = 'AES';
    $self->{encrypt}    = 0;
    $self->{initialisation_vector} = undef;
    $self->{key}        = undef;
    # Should this API be strict about the cookie names?
    # When true, this will reject cookie names with invalid characters.
    $self->{strict}     = 0;
    # Needs to be an empty string or it would be overriden by Module::Generic who would put here the package version instead
    $self->{version}    = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{fields} = [qw( name value comment commentURL discard domain expires http_only implicit max_age path port same_site secure version )];
    return( $self );
}

sub accessed_on { return( shift->_set_get_datetime( 'accessed', @_ ) ); }

sub algo
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $algo = shift( @_ );
        if( defined( $algo ) && CORE::length( $algo ) )
        {
            $self->_load_class( 'Crypt::Mode::CBC', { version => CRYPTX_VERSION } ) || return( $self->pass_error );
            # try-catch
            local $@;
            eval
            {
                # Crypt::Mode::CBC dies when it is unhappy, but we catch a null return 
                # value anyway just in case
                my $o = Crypt::Mode::CBC->new( $algo ) ||
                    die( "Unsupported algorithm \"$algo\"\n" );
                $self->_set_get_scalar_as_object( 'algo', $algo );
                $self->reset(1);
            };
            if( $@ )
            {
                return( $self->error( "Unsupported algorithm \"$algo\": $@" ) );
            }
        }
        else
        {
            $self->{algo} = undef;
        }
    }
    return( $self->_set_get_scalar_as_object( 'algo' ) );
}

sub apply
{
    my $self = shift( @_ );
    my $hash = $self->_get_args_as_hash( @_ );
    return( $self ) if( !scalar( keys( %$hash ) ) );
    if( !defined( $SUBS ) || 
        ref( $SUBS ) ne 'ARRAY' ||
        !scalar( @$SUBS ) )
    {
        $SUBS = [grep( /^(?!apply|as_hash|as_string|can|fields|import|init|reset)(?:[a-z][a-z\_]+)$/, keys( %Cookie:: ) )];
    }
    
    foreach( @$SUBS )
    {
        # Value could be undef
        # Passing an empty string to Module::Generic::Number will trigger an error (undef)
        # So if the value is empty, we simply set it directly.
        if( $_ eq 'version' && !CORE::length( $hash->{ $_ } ) )
        {
            $self->{ $_ } = $hash->{ $_ };
            next;
        }
        
        if( CORE::exists( $hash->{ $_ } ) )
        {
            if( !defined( $hash->{ $_ } ) )
            {
                $self->{ $_ } = undef;
            }
            else
            {
                $self->$_( $hash->{ $_ } );
            }
        }
    }
    return( $self );
}

sub as_hash
{
    my $self = shift( @_ );
    my $ref = {};
    foreach my $m ( qw( name value comment commentURL domain expires http_only implicit max_age path port same_site secure version created_on accessed_on ) )
    {
        $ref->{ $m } = $self->$m;
    }
    return( $ref );
}

# sub as_string { return( shift->APR::Request::Cookie::as_string ); }
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
sub as_string 
{
    my $self = shift( @_ );
    # If is_request is true, we only send the name and value
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{is_request} //= 0;
    return( $self->{_cache_value} ) if( $self->{_cache_value} && !CORE::length( $self->{_reset} ) && !$opts->{is_request} );
    my $name = $self->name;
    return( $self->error( "No cookie is name in this cookie object." ) ) if( !defined( $name ) || !length( $name ) );
    if( $name =~ m/[^a-zA-Z\-\.\_\~]/ )
    {
        $name = URI::Escape::uri_escape( $name );
    }
    my $value = $self->value;
    
    if( $self->sign || $self->encrypt )
    {
        my $key = $self->key ||
            return( $self->error( "Signature or encryption has been enabled, but no key was provided." ) );
        if( $self->sign->is_true )
        {
            $self->_load_class( 'Crypt::Mac::HMAC', { version => CRYPTX_VERSION } ) || return( $self->pass_error );
            # try-catch
            local $@;
            my $signature = eval
            {
                Crypt::Mac::HMAC::hmac_b64( "SHA256", "$key", "$value" );
            };
            if( $@ )
            {
                return( $self->error( "An error occurred while trying to ", ( $self->sign ? 'sign' : 'encrypt' ), " cookie value: $@" ) );
            }
            $value = "$value.$signature";
        }
        elsif( $self->encrypt )
        {
            $self->_load_class( 'Crypt::Misc', { version => CRYPTX_VERSION } ) || return( $self->pass_error );
            my $algo = $self->algo;
            my $p = $self->_encrypt_objects( $key => $algo ) || return( $self->pass_error );
            my $crypt = $p->{crypt};
            # $value = Crypt::Misc::encode_b64( $crypt->encrypt( "$value", $p->{key}, $p->{iv} ) );
            # try-catch
            local $@;
            my $encrypted = eval
            {
                $crypt->encrypt( "$value", $p->{key}, $p->{iv} );
            };
            if( $@ )
            {
                return( $self->error( "An error occurred while trying to ", ( $self->sign ? 'sign' : 'encrypt' ), " cookie value: $@" ) );
            }
            $value = Crypt::Misc::encode_b64( $encrypted );
        }
    }
    
    # Not necessary to encode, but customary and practical
    if( CORE::length( $value ) )
    {
        my $wrapped_in_double_quotes = 0;
        if( $value =~ /^\"([^\"]+)\"$/ )
        {
            $value = $1;
            $wrapped_in_double_quotes = 1;
        }
        $value = URI::Escape::uri_escape( $value );
        $value = sprintf( '"%s"', $value ) if( $wrapped_in_double_quotes );
    }
    my @parts = ( "${name}=${value}" );
    return( $parts[0] ) if( $opts->{is_request} );
    push( @parts, sprintf( 'Domain=%s', $self->domain ) ) if( $self->domain );
    push( @parts, sprintf( 'Port=%d', $self->port ) ) if( $self->port );
    push( @parts, sprintf( 'Path=%s', $self->path ) ) if( $self->path );
    # Could be empty. If not specified, it would be a session cookie
    if( ( my $t = $self->expires ) && !$self->max_age->length )
    {
        ( my $dt_str = "$t" ) =~ s/\bUTC\b/GMT/;
        push( @parts, sprintf( 'Expires=%s', $dt_str ) );
    }
    # Number of seconds until the cookie expires
    # A zero or negative number will expire the cookie immediately.
    # If both Expires and Max-Age are set, Max-Age has precedence.
    push( @parts, sprintf( 'Max-Age=%d', $self->max_age ) ) if( CORE::length( $self->max_age ) );
    if( $self->same_site->defined && $self->same_site =~ /^(?:lax|strict|none)/i )
    {
        push( @parts, sprintf( 'SameSite=%s', ucfirst( lc( $self->same_site ) ) ) );
    }
    push( @parts, 'Secure' ) if( $self->secure );
    push( @parts, 'HttpOnly' ) if( $self->http_only );
    my $c = join( '; ', @parts );
    $self->{_cache_value} = $c;
    CORE::delete( $self->{_reset} );
    return( $c );
}

# A Version 2 cookie, which has been deprecated by protocol
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie2
sub comment { return( shift->_set_get_scalar_as_object( 'comment', @_ ) ); }

# A Version 2 cookie, which has been deprecated by protocol
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie2
sub commentURL { return( shift->_set_get_uri( 'commentURL', @_ ) ); }

sub created_on { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub decrypt
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $value = $self->value;
    return( $value ) if( !$value->length );
    $opts->{key} //= '';
    $opts->{algo} //= '';
    $opts->{iv} //= '';
    my $key = $opts->{key} || $self->key;
    my $algo = $opts->{algo} || $self->algo;
    return( $self->error( "Cookie encryption was enabled, but no key was set to decrypt it." ) ) if( !defined( $key ) || !CORE::length( "$key" ) );
    return( $self->error( "Cookie encryption was enabled, but no algorithm was set to decrypt it." ) ) if( !defined( $algo ) || !CORE::length( "$algo" ) );
    $self->_load_class( 'Crypt::Misc', { version => CRYPTX_VERSION } ) || return( $self->pass_error );
    # If IV is not provided, _encrypt_objects will generate one and save it for next time
    my $p = $self->_encrypt_objects( $key => $algo, $opts->{iv} ) || return( $self->pass_error );
    my $crypt = $p->{crypt};
    # try-catch
    local $@;
    my $rv = eval
    {
        my $bin = Crypt::Misc::decode_b64( "$value" );
        return( $crypt->decrypt( "$bin", $p->{key}, $p->{iv} ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to decrypt cookie value: $@" ) );
    }
    return( $rv );
}

sub discard { return( shift->_set_get_boolean( 'discard', @_ ) ); }

sub domain { return( shift->reset(@_)->_set_get_scalar_as_object( 'domain', @_ ) ); }

# To expire a cookie, the domain and path must match that was previously set
# <https://datatracker.ietf.org/doc/html/rfc6265#section-3.1>
sub elapse
{
    my $self = shift( @_ );
    $self->expires(0);
    return( $self );
}

sub encrypt { return( shift->reset(@_)->_set_get_boolean( 'encrypt', @_ ) ); }

# sub expires { return( shift->APR::Request::Cookie::expires( @_ ) ); }
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
# Example: Fri, 13 Dec 2019 02:27:28 GMT
sub expires
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->reset(1);
        my $exp = shift( @_ );
        my $tz;
        # DateTime::TimeZone::Local will die ungracefully if the local timezone is not set with the error:
        # "Cannot determine local time zone"
        # try-catch
        local $@;
        $tz = eval
        {
            DateTime::TimeZone->new( name => 'local' );
        };
        if( $@ )
        {
            $tz = DateTime::TimeZone->new( name => 'UTC' );
        }
        my $dt;
        # unsets the value
        if( !defined( $exp ) )
        {
            $self->{expires} = undef;
        }
        elsif( $exp =~ /^\d{1,10}$/ )
        {
            # try-catch
            local $@;
            $dt = eval
            {
                # Unexpectedly, DateTime sets the time zone ONLY after having instantiated the
                # object and set its time zone to UTC.
                # Thus, here setting to 'local' (e.g. corresponding to Asia/Tokyo) would
                # actually set the epoch to GMT+9 instead of treating the epoch time provided
                # to being in Asia/Tokyo time zone!
                # Issue #126
                # <https://github.com/houseabsolute/DateTime.pm/issues/126>
                DateTime->from_epoch( epoch => $exp, time_zone => $tz );
            };
            if( $@ )
            {
                return( $self->error( "An error occurred while setting the cookie expiration date time based on the unix timestamp '$exp': $@" ) );
            }
        }
        elsif( $self->_is_object( $exp ) && ( $exp->isa( 'DateTime' ) || $exp->isa( 'Module::Generic::Datetime' ) ) )
        {
            $dt = $exp;
        }
        elsif( $exp =~ /^([\+\-]?\d+)([YyMDdhms])?$/ )
        {
            my( $num, $unit ) = ( $1, $2 );
            $unit = 's' if( !length( $unit ) );
            my $interval =
            {
                's' => 1,
                'm' => 60,
                'h' => 3600,
                'D' => 86400,
                'd' => 86400,
                'M' => 86400 * 30,
                'Y' => 86400 * 365,
                'y' => 86400 * 365,
            };
            my $offset = ( $interval->{ $unit } || 1 ) * int( $num );
            my $ts = time() + $offset;
            $dt = DateTime->from_epoch( epoch => $ts, time_zone => $tz );
        }
        elsif( lc( $exp ) eq 'now' )
        {
            $dt = DateTime->now( time_zone => $tz );
        }
        elsif( defined( $exp ) && CORE::length( $exp ) )
        {
            $dt = $self->_parse_timestamp( $exp );
            return( $self->pass_error ) if( !defined( $dt ) );
            return( $self->error( "Provided expires value '$exp' (", overload::StrVal( $exp // 'undef' ), ") is an invalid expression." ) ) if( !CORE::length( $dt ) );
        }
        else
        {
            # Don't know what to do with '$exp'.
        }
        
        if( defined( $dt ) )
        {
            $dt = $self->_header_datetime( $dt ) if( $self->_is_a( $dt, 'DateTime' ) );
            $self->{expires} = $dt->isa( 'Module::Generic::DateTime' ) ? $dt : Module::Generic::DateTime->new( $dt );
        }
    }
    return( $self->_set_get_datetime( 'expires' ) );
}

sub fields { return( shift->_set_get_array_as_object( 'fields', @_ ) ); }

sub host { return( shift->domain( @_ ) ); }

sub host_only { return( shift->implicit( @_ ) ); }

sub http_only { return( shift->reset(@_)->_set_get_boolean( 'http_only', @_ ) ); }

sub httponly { return( shift->http_only( @_ ) ); }

sub implicit { return( shift->reset(@_)->_set_get_boolean( 'implicit', @_ ) ); }

# For cookie encryption
sub initialisation_vector { return( shift->_set_get_scalar_as_object( 'initialisation_vector', @_ ) ); }

sub is_expired
{
    my $self = shift( @_ );
    my $exp = $self->expires;
    my $max_age = $self->max_age;
    return( $self->false ) if( !defined( $exp ) && !defined( $max_age ) );
    if( ( defined( $exp ) && !$self->_is_a( $exp, 'Module::Generic::DateTime' ) && !$self->_is_a( $exp, 'DateTime' ) ) ||
        ( defined( $max_age ) && $max_age !~ /\-?\d+$/ ) )
    {
        return( $self->false );
    }
    my $now = DateTime->now;
    if( ( defined( $max_age ) && $max_age <= 0 ) || 
        ( defined( $exp ) && $exp < $now ) )
    {
        return( $self->true );
    }
    else
    {
        return( $self->false );
    }
}

sub is_persistent { return( !shift->is_session ); }

sub is_session
{
    my $self = shift( @_ );
    return( defined( $self->expires ) || defined( $self->max_age ) ? $self->false : $self->true );
}

sub is_tainted { return( shift->_set_get_boolean( 'is_tainted', @_ ) ); }

sub is_valid
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{key} ||= $self->key || '';
    return( $self->true ) if( !$self->sign && !CORE::length( $opts->{key} ) );
    return( $self->error( "Signature validation is required, but no key has been set." ) ) if( !$self->key->length && !CORE::exists( $opts->{key} ) || ( CORE::exists( $opts->{key} ) && !CORE::length( $opts->{key} ) ) );
    my $value = $self->value;
    return( $self->true ) if( !$value->length );
    if( $value->index( '.' ) == -1 )
    {
        # Not an error, so we only issue a warning if warnings are enabled
        warnings::warn( "The cookie does not have a signature attached to it." ) if( warnings::enabled() );
        return( $self->false );
    }
    my @parts = $value->split( '.' );
    # We take the last one, because the cookie name, itself, could potentially contain dots.
    # The value must be an uri unescaped value
    my $sig = pop( @parts );
    my $orig = join( '.', @parts );
    my $key = $opts->{key};
    $self->_load_class( 'Crypt::Mac::HMAC', { version => CRYPTX_VERSION } ) || return( $self->pass_error );
    # try-catch
    local $@;
    my $check = eval
    {
        Crypt::Mac::HMAC::hmac_b64( 'SHA256', "$key", "$orig" );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to check the cookie signature validation: $@" ) );
    }
    return( "$check" eq "$sig" );
}

sub iv { return( shift->initialisation_vector( @_ ) ); }

sub key { return( shift->_set_get_scalar_as_object( 'key', @_ ) ); }

# Check if the cookie domain is within the host provided, i.e.
# wether this cookie should be sent as part of the request
sub match_host
{
    my $self = shift( @_ );
    # e.g. www.example.com
    my $host = shift( @_ ) || return(0);
    $host = lc( $host );
    # and ours could be just example.com
    my $dom = $self->domain;
    return(1) if( $host eq $dom );
    # if our domain is longer than $host, then we are not a match as we should be a subset
    # e.g. ours www.ja.example.com vs $host ja.example.com
    return(0) if( CORE::length( $dom ) > CORE::length( $host ) );
    # our cookie domain has been set implicitly and since we are not an exact match, 
    # no need to go further.
    unless( $self->implicit )
    {
        return( $host =~ /\.${dom}$/ ? 1 : 0 );
    }
    return(0);
}

# sub max_age { return( shift->reset(@_)->_set_get_scalar( 'max_age', @_ ) ); }
sub max_age
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->reset( @_ );
        my $v = shift( @_ );
        if( !defined( $v ) )
        {
            $self->{max_age} = undef;
        }
        else
        {
            return( $self->error( "Invalid max-age value '$v'" ) ) if( $v !~ /^\-?\d+$/ );
            $v = int( $v );
            # "If both Expires and Max-Age are set, Max-Age has precedence"
            # <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>
            my $exp;
            if( $v <= 0 )
            {
                $exp = DateTime->new(
                    year   => 1970,
                    month  => 1,
                    day    => 1,
                    hour   => 0,
                    minute => 0,
                    second => 0,
                    time_zone => 'GMT',
                );
            }
            else
            {
                my $tz;
                # DateTime::TimeZone::Local will die ungracefully if the local timezeon is not set with the error:
                # "Cannot determine local time zone"
                # try-catch
                local $@;
                $tz = eval
                {
                    DateTime::TimeZone->new( name => 'local' );
                };
                if( $@ )
                {
                    $tz = DateTime::TimeZone->new( name => 'UTC' );
                }
                $exp = DateTime->now( time_zone => $tz );
                $exp->add( seconds => $v );
            }
            $self->expires( $exp );
            return( $self->_set_get_number( 'max_age' => $v ) );
        }
    }
    return( $self->_set_get_number( 'max_age' ) );
}

sub maxage { return( shift->max_age( @_ ) ); }

sub name
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->reset( @_ );
        my $name = shift( @_ );
        # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
        if( $name =~ /[\(\)\<\>\@\,\;\:\\\"\/\[\]\?\=\{\}]/ && $self->strict )
        {
            return( $self->error( "A cookie name can only contain US ascii characters. Cookie name provided was '$name'." ) );
        }
        if( $name =~ s/^__Secure\-// )
        {
            $self->secure(1);
        }
        elsif( $name =~ s/^__Host\-// )
        {
            $self->secure(1);
            $self->path( '/' ) if( !$self->path->length );
        }
        $self->_set_get_scalar_as_object( 'name' => $name );
    }
    return( $self->_set_get_scalar_as_object( 'name' ) );
}

sub path { return( shift->reset(@_)->_set_get_scalar_as_object( 'path', @_ ) ); }

sub port { return( shift->reset(@_)->_set_get_number( 'port', @_ ) ); }

sub reset
{
    my $self = shift( @_ );
    $self->{_reset} = scalar( @_ ) if( !CORE::length( $self->{_reset} ) && scalar( @_ ) );
    return( $self );
}

sub same_as
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return(0) if( !$this || !$self->_is_object( $this ) );
    my $fields = $self->fields;
    foreach my $f ( @$fields )
    {
        my $v = $self->$f;
        my $code = $this->can( $f );
        return(0) if( !$code );
        my $v2 = $code->( $this );
        if( ( !defined( $v ) && defined( $v2 ) ) ||
            ( defined( $v ) && !defined( $v2 ) ) ||
            ( defined( $v ) && length( "$v" ) != length( "$v2" ) ) ||
            ( defined( $v ) && defined( $v2 ) && "$v" ne "$v2" ) )
        {
            return(0);
        }
    }
    return(1);
}

sub same_site { return( shift->reset(@_)->_set_get_scalar_as_object( 'same_site', @_ ) ); }

sub samesite { return( shift->same_site( @_ ) ); }

sub secure { return( shift->reset(@_)->_set_get_boolean( 'secure', @_ ) ); }

sub sign { return( shift->reset(@_)->_set_get_boolean( 'sign', @_ ) ); }

sub strict { return( shift->reset(@_)->_set_get_boolean( 'strict', @_ ) ); }

sub uri
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->reset( @_ );
        my $uri = $self->_set_get_uri( 'uri', @_ ) || return;
        $self->port( $uri->port );
        $self->path( $uri->path );
        $self->domain( $uri->host );
    }
    elsif( $self->domain )
    {
        my $uri = 
            ( $self->secure ? 'https' : 'http' ) . '://' . 
            $self->domain . 
            ( $self->port ? ':' . $self->port : '' ) . 
            ( $self->path ? $self->path : '/' );
        return( $self->_set_get_uri( 'uri' => $uri ) );
    }
    return( $self->_set_get_uri( 'uri' ) );
}

sub value { return( shift->reset(@_)->_set_get_scalar_as_object( 'value', @_ ) ); }

# Deprecated. Was a version 2 cookie spec: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie2
sub version { return( shift->_set_get_number( 'version', @_ ) ); }

sub _encrypt_objects
{
    my $self = shift( @_ );
    my( $key, $algo, $iv ) = @_;
    return( $self->error( "Key provided is empty!" ) ) if( !defined( $key ) || !CORE::length( "$key" ) );
    return( $self->error( "No algorithm was provided to encrypt cookie value. You can choose any <NAME> for which there exists Crypt::Cipher::<NAME>" ) ) if( !defined( $algo ) || !CORE::length( "$algo" ) );
    $iv //= '';

    $self->_load_class( 'Crypt::Mode::CBC', { version => CRYPTX_VERSION } ) || return( $self->pass_error );
    $self->_load_class( 'Bytes::Random::Secure' ) || return( $self->pass_error );
    my $crypt = eval
    {
        Crypt::Mode::CBC->new( "$algo" );
    };
    if( $@ )
    {
        return( $self->error( "Error getting the encryption objects for algorithm \"$algo\": $@" ) );
    }
    $crypt or return( $self->error( "Unable to create a Crypt::Mode::CBC object." ) );
    my $class = "Crypt::Cipher::${algo}";
    $self->_load_class( $class ) || return( $self->pass_error );
    my $key_len = $class->keysize;
    my $block_len = $class->blocksize;
    return( $self->error( "The size of the key provided (", CORE::length( $key ), ") does not match the minimum key size required for this algorithm \"$algo\" (${key_len})." ) ) if( CORE::length( $key ) < $key_len );
    # Generate an "IV", i.e. Initialisation Vector based on the required block size
    $iv ||= $self->initialisation_vector;
    if( defined( $iv ) && CORE::length( "$iv" ) )
    {
        if( CORE::length( "$iv" ) != $block_len )
        {
            return( $self->error( "The Initialisation Vector provided for cookie encryption has a length (", CORE::length( "$iv" ), ") which does not match the algorithm ($algo) size requirement ($block_len). Please refer to the cookie documentation Cookie" ) );
        }
    }
    else
    {
        $iv = eval
        {
            Bytes::Random::Secure::random_bytes( $block_len );
        };
        if( $@ )
        {
            return( $self->error( "Error getting $block_len random secure bytes for algorithm \"$algo\": $@" ) );
        }
        # Save it for decryption
        $self->initialisation_vector( $iv );
    }
    my $key_pack = pack( 'H' x $key_len, $key );
    my $iv_pack  = pack( 'H' x $block_len, $iv );
    return({ 'crypt' => $crypt, key => $key_pack, iv => $iv_pack });
}

sub _header_datetime
{
    my $self = shift( @_ );
    my $dt;
    if( @_ )
    {
        return( $self->error( "Date time provided ($dt) is not an object." ) ) if( !$self->_is_object( $_[0] ) );
        return( $self->error( "Object provided (", ref( $_[0] ), ") is not a DateTime object." ) ) if( !$_[0]->isa( 'DateTime' ) );
        $dt = shift( @_ );
    }
    $dt = DateTime->now if( !defined( $dt ) );
    $dt->set_time_zone( 'GMT' );
    my $fmt = DateTime::Format::Strptime->new(
        pattern => '%a, %d %b %Y %H:%M:%S GMT',
        locale  => 'en_GB',
        time_zone => 'GMT',
    );
    $dt->set_formatter( $fmt );
    return( $dt );
}

sub TO_JSON
{
    my $self = shift( @_ );
    my $fields = $self->fields;
    my $ref = {};
    foreach my $m ( @$fields )
    {
        $ref->{ $m } = $self->$m;
    }
    return( $ref );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Cookie - Cookie Object with Encryption or Signature

=head1 SYNOPSIS

    use Cookie;
    my $c = Cookie->new(
        name => 'my-cookie',
        domain => 'example.com',
        value => 'sid1234567',
        path => '/',
        expires => '+10D',
        # or alternatively
        maxage => 864000
        # to make it exclusively accessible by regular http request and not javascript
        http_only => 1,
        same_site => 'Lax',
        # should it be used under ssl only?
        secure => 1,
    );
    # make the cookie expired
    # Sets the expiration datetime to Thu, 01 Jan 1970 09:00:00 GMT
    $c->elapse;
    # Get cookie as an hash reference
    my $hash = $c->as_hash;
    print $c->as_string, "\n";
    # or
    print "$c\n";
    # If expires is set, we can use its underlying DateTime object
    my $now = DateTime->now;
    if( $c->expires && $c->expires > $now )
    {
        # ok, we're good
    }
    # Unset expiration, effectively transforming it into a session cookie
    $c->expires( undef );
    print "Is session cookie? ", $c->is_session ? 'yes' : 'no', "\n";
    $c->match_host( 'www.example.com' );
    # Set max-age (in seconds) that takes precedence over expiration
    $c->max_age( 86400 );
    # Make it expired to tell the http client to remove it:
    $c->max_age(0) # or $c->max_age(-1)
    # Unset max-age
    $c->max_age( undef );
    print "Is it same? ", $c->same_as( $other ) ? 'yes' : 'no', "\n";
    # Conveniently set port, path and domain in one go, but not the secure flag
    $c->uri( 'https://www.example.com:8080/some/where' );

    # Create encrypted cookie
    # You can generate a key or type one as long as it meets the size requirement
    use Bytes::Random::Secure ();
    my $c = Cookie->new(
        name => 'my-cookie',
        domain => 'example.com',
        value => 'sid1234567',
        path => '/',
        expires => '+10D',
        # or alternatively
        maxage => 864000
        # to make it exclusively accessible by regular http request and not ajax
        http_only => 1,
        same_site => 'Lax',
        # should it be used under ssl only?
        secure => 1,
        # Encryption parameters
        key       => Bytes::Random::Secure::random_bytes(32),
        algo      => 'AES',
        encrypt   => 1,
    );
    print( "My encrypted cookie: $c\n" );

    # Sign cookie only
    my $c = Cookie->new(
        name => 'my-cookie',
        domain => 'example.com',
        value => 'sid1234567',
        path => '/',
        expires => '+10D',
        # or alternatively
        maxage => 864000
        # to make it exclusively accessible by regular http request and not ajax
        http_only => 1,
        same_site => 'Lax',
        # should it be used under ssl only?
        secure => 1,
        # Encryption parameters
        # No size constraint for signature, but obviously the longer the better
        key       => Bytes::Random::Secure::random_bytes(32),
        sign      => 1,
    );
    print( "My signed cookie: $c\n" );

=head1 VERSION

    v0.3.5

=head1 DESCRIPTION

This is a powerful and versatile package to create and represent a cookie compliant with the latest standard as set by L<rfc6265|https://datatracker.ietf.org/doc/html/rfc6265>. This can be used as a standalone module, or can be managed as part of the cookie jar L<Cookie::Jar>

The object is overloaded and will call L</as_string> upon stringification and can also be used in comparison with other cookie object:

    if( $cookie1 eq $cookie2 )
    {
        # do something
    }

This module does not die upon error, but instead returns C<undef> and sets an L<error|Module::Generic/error>, so you should always check the return value of a method.

See also the L<Cookie::Jar> package to manage server and client side handling of cookies:

    use Cookie::Jar;
    # Possibly passing the cookie repository the Apache2::RequestRec object
    my $jar = Cookie::Jar->new( $r );
    my $c = $jar->make(
        name => 'my_cookie',
        value => 'some value',
        domain => 'example.org',
        path => '/',
        secure => 1,
        http_only => 1,
    ) || die( $jar->error );
    # Set it in the server response C<Set-Cookie> header:
    $jar->set( $c ) || die( $jar->error );

=head1 METHODS

=head2 new

Provided with an hash or hash reference of parameters, and this initiates a new cookie object and return it. Each of the following parameters has a corresponding method.

=over 4

=item * C<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=item * C<name>

String.

See also L</name>

=item * C<value>

String.

See also L</value>

=item * C<comment>

String.

See also L</comment>

=item * C<commentURL>

URI string or object.

See also L</commentURL>

=item * C<discard>

Boolean.

See also L</discard>

=item * C<domain>

String.

See also L</domain>

=item * C<expires>

Datetime str | DateTime object | integer

See also L</expires>

=item * C<http_only>

Boolean,

See also L</http_only>

=item * C<implicit>

Boolean.

See also L</implicit>

=item * C<max_age>

Integer.

See also L</max_age>

=item * C<path>

String.

See also L</path>

=item * C<port>

Integer.

See also L</port>

=item * C<same_site>

String.

See also L</same_site>

=item * C<secure>

Boolean.

See also L</secure>

=item * C<version>

Integer.

See also L</version>

=back

Other extra parameters not directly related to the cookie standard:

=over 4

=item * C<accessed_on>

Datetime.

See also L</accessed_on>

=item * C<algo>

String.

See also L</algo>

=item * C<created_on>

Datetime.

See also L</created_on>

=item * C<encrypt>

Boolean.

See also L</encrypt>

=item * C<key>

String.

See also L</key>

=item * C<sign>

Boolean.

See also L</sign>

=back

=head2 accessed_on

Set or get the datetime of the cookie object last accessed.

According to L<rfc6265, section 5.3.12.3|https://datatracker.ietf.org/doc/html/rfc6265#section-5.3>, when deciding which cookies to remove, for those who have equal removal priority:

"If two cookies have the same removal priority, the user agent MUST evict the cookie with the earliest last-access date first."

=head2 algo

This set or get the the algorithm used to encrypt the cookie value.

It can be any of L<AES|Crypt::Cipher::AES>, L<Anubis|Crypt::Cipher::Anubis>, L<Blowfish|Crypt::Cipher::Blowfish>, L<CAST5|Crypt::Cipher::CAST5>, L<Camellia|Crypt::Cipher::Camellia>, L<DES|Crypt::Cipher::DES>, L<DES_EDE|Crypt::Cipher::DES_EDE>, L<KASUMI|Crypt::Cipher::KASUMI>, L<Khazad|Crypt::Cipher::Khazad>, L<MULTI2|Crypt::Cipher::MULTI2>, L<Noekeon|Crypt::Cipher::Noekeon>, L<RC2|Crypt::Cipher::RC2>, L<RC5|Crypt::Cipher::RC5>, L<RC6|Crypt::Cipher::RC6>, L<SAFERP|Crypt::Cipher::SAFERP>, L<SAFER_K128|Crypt::Cipher::SAFER_K128>, L<SAFER_K64|Crypt::Cipher::SAFER_K64>, L<SAFER_SK128|Crypt::Cipher::SAFER_SK128>, L<SAFER_SK64|Crypt::Cipher::SAFER_SK64>, L<SEED|Crypt::Cipher::SEED>, L<Skipjack|Crypt::Cipher::Skipjack>, L<Twofish|Crypt::Cipher::Twofish>, L<XTEA|Crypt::Cipher::XTEA>, L<IDEA|Crypt::Cipher::IDEA>, L<Serpent|Crypt::Cipher::Serpent> or simply any <NAME> for which there exists Crypt::Cipher::<NAME>

See also L<Stackoverflow on the choice of encryption algorithm|https://stackoverflow.com/questions/4147451/aes-vs-blowfish-for-file-encryption>

By default, the algorithm is set to C<AES>

If the algorithm set is unsupported, this method returns an L<error|Module::Generic/error>

It returns the current value as a L<scalar object|Module::Generic::Scalar>

=head2 apply

Provided with an hash ore hash reference of cookie parameter, and this will apply them to each of their equivalent method.

    $c->apply(
        expires => 'now',
        secure => 1,
        http_only => 1,
    );

In the example above, this will call methods L</expires>, L</secure> and L</http_only> passing them the relevant values.

It returns the current object.

=head2 as_hash

Returns an hash reference of the cookie value.

The hash reference returned will contain the following keys: C<name> C<value> C<comment> C<commentURL> C<domain> C<expires> C<http_only> C<implicit> C<max_age> C<path> C<port> C<same_site> C<secure> C<version>

=head2 as_string

Returns a string representation of the object.

    my $cookie_string = $cookie->as_string;
    # or
    my $cookie_string = "$cookie";
    my-cookie="sid1234567"; Domain=example.com; Path=/; Expires=Mon, 09 Jan 2020 12:17:30 GMT; Secure; HttpOnly

If encryption is enabled with L</encrypt>, the cookie value will be encrypted using the key provided with L</key> and the L<Initialisation Vector|/initialisation_vector>. If the latter was not provided, it will be generated automatically. The resulting encrypted value is then encoded in base64 and escaped. For example:

    my $cookie_value = "toc_ok=1";
    my $key = Bytes::Random::Secure::random_bytes(32);
    # result:
    # session=PyJTlRJniAYVJJF6%2FswuPw%3D%3D; Path=/; SameSite=Lax; Secure; HttpOnly

If cookie signature is enabled for integrity protection with L</sign>, an sha256 hmac will be generated using the key provided with L</key> and the resulting hash appended to the cookie value separated by a dot. For example:

    my $cookie_value = "toc_ok=1";
    my $key = "hard to guess key";
    # I2M4/rh/TiNV5RZDSBJkhLblBvrN5k9448G6w/gp/jg=
    my $signature = Crypt::Mac::HMAC::hmac_b64( $key, $cookie_value );
    # result: toc_ok=1.I2M4/rh/TiNV5RZDSBJkhLblBvrN5k9448G6w/gp/jg=
    # ultimately the cookie value sent will be:
    # toc_ok%3D1.I2M4%2Frh%2FTiNV5RZDSBJkhLblBvrN5k9448G6w%2Fgp%2Fjg%3D

The returned value is cached so the next time, it simply return the cached version and not re-process it. You can reset it by calling L</reset>.

=head2 comment

    $cookie->comment( 'Some comment' );
    my $comment = $cookie->comment;

Sets or gets the optional comment for this cookie. This was used in version 2 of cookies but has since been deprecated.

Returns a L<Module::Generic::Scalar> object.

=head2 commentURL

    $cookie->commentURL( 'https://example.com/some/where.html' );
    my $comment = $cookie->commentURL;

Sets or gets the optional comment URL for this cookie. This was used in version 2 of cookies but has since been deprecated.

Returns an L<URI> object.

=head2 created_on

Set or get the datetime of the cookie object created. This value is primarily used by L<Cookie::Jar>, as per the rfc6265, when setting the http request header C<Cookie> to differentiate two cookies that share the same domain and path. The cookie that has their creation datetime earlier are set first:

"Among cookies that have equal-length path fields, cookies with earlier creation-times are listed before cookies with later creation-times." (L<rfc6265, section 5.4.2|https://datatracker.ietf.org/doc/html/rfc6265#section-5.4>)

=head2 decrypt

This returns the cookie decrypted value. If it used on a non-encrypted cookie, this would return C<undef> and set an L<error|Module::Generic/error>

It takes an optional hash or hash reference of parameters:

=over 4

=item I<algo> string

The algorithm to use for encryption. Defaults to the value set with L</algo>. See this method for more information on acceptable values.

=item I<iv> string

The Initialisation Vector used for encryption and decryption. Default to the value set with L</initialisation_vector>

=item I<key> string

The encryption key. Defaults to the value set with L</key>

=back

=head2 discard

Boolean. Set or get this value to true to flag this cookie to be discarded, whatever that means to you the user. This is not a standard protocol property.

This method is used in L<Cookie::Jar/save_as_lwp> and L<Cookie::Jar/save_as_netscape> with the option C<skip_discard>

It returns the current value as a L<Module::Generic::Boolean> object.

=head2 domain

    $cookie->domain( 'example.com' );
    my $dom = $cookie->domain;

Sets or gets the domain for this cookie.

Returns the current value as a L<Module::Generic::Scalar> object.

Note that you can also call it using the alias method C<host>

=head2 elapse

Set the C<expires> value for this cookie to C<0>, which, in turn, will set it to C<Thu, 01 Jan 1970 09:00:00 GMT>

When sent to the http client, this will have the effect of removing the cookie.

See L<rfc6265|https://datatracker.ietf.org/doc/html/rfc6265#section-3.1> for more information.

=head2 encrypt

Set or get the boolean value. If true, the this will tell L</as_string> to encrypt the cookie value.

To use this feature, an encryption L<key|/key> must be set and the module L<Crypt::Cipher> must be installed.

You can read more about the differences between L<sign and encryption at Stackoverflow|https://stackoverflow.com/questions/41467012/what-is-the-difference-between-signed-and-encrypted-cookies-in-rails>

=head2 expires

Sets or gets the expiration date and time for this cookie.

The value provided can be one of:

=over 4

=item A date compliant with L<rfc7231|https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.1.1>

For example: C<01 Nov 2021 08:42:17 GMT>

=item unix timestamp.

For example: C<1631099228>

=item variable time.

For example: C<30s> (30 seconds), C<5m> (5 minutes), C<12h> (12 hours), C<30D> (30 days), C<2M> (2 months), C<1Y> (1 year)

However, this is not sprintf, so you cannot combine them, thus B<you cannot do this>: C<5m1D>

=item C<now>

Special keyword

=item In last resort, the value provided will be parsed using L<Module::Generic/_parse_timestamp>. If parsing fails, it will return C<undef> and set an error.

=back

Ultimately, a L<DateTime> will be derived from those values, or C<undef> will be returned and an error will be set.

The L<DateTime> object will be set with a formatter to allow a stringification that is compliant with rfc6265.

And you can use L</max_age> alternatively.

See also L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date>

Note that a cookie without an expiration datetime is referred as a C<session cookie>, so setting the cookie expiration change a cookie from being a session cookie to being a more permanent cookie.

As L<documented|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>, if expiration is "unspecified, the cookie becomes a session cookie. A session finishes when the client shuts down, after which the session cookie is removed."

=head2 fields

Returns an L<array object|Module::Generic::Array> of cookie fields available. This is essentially used by L</apply>

=head2 host

Alias for L</domain>

=head2 host_only

This is an alias for L</implicit>. It has been added to comply with the language of L<rfc6265, section 5.3.6|https://datatracker.ietf.org/doc/html/rfc6265#section-5.3>

If the domain attribute was not provided by the server for this cookie, then:
"set the cookie's host-only-flag to true." and "set the cookie's domain to the canonicalized request-host"

Returns the current value as a L<Module::Generic::Boolean> object (that is stringifyable).

=head2 http_only

Sets or gets the boolean for C<httpOnly>

Returns a L<Module::Generic::Boolean> object.

=head2 httponly

Alias for L</http_only>

=head2 implicit

This boolean is set to true if the L<domain|/domain> was not initially set and has been derived from the current host.

Returns a L<Module::Generic::Boolean> object.

=head2 initialisation_vector

Set or get the L<Initialisation Vector|https://en.wikipedia.org/wiki/Initialization_vector> used for cookie encryption. If you do not provide one, it will be automatically generated. If you want to provide your own, make sure the size meets the encryption algorithm size requirement.

To find the right size for the Initialisation Vector, for example for algorithm C<AES>, you could do:

    perl -MCrypt::Cipher::AES -lE 'say Crypt::Cipher::AES->blocksize'

which would yield C<16>

=head2 is_expired

Returns true if this cookie has an expiration datetime set and it has expired, i.e. the expiration datetime is in the past. Otherwise, it returns false.

Return value is in the form of a L<Module::Generic::Boolean> object that stringifies to 1 or 0;

=head2 is_persistent

Boolean. This returns true if the cookie sent from the server is not a session cookie, i.e. it has an L</expires> value set.

See L<rfc62655, section 5.3.3|https://datatracker.ietf.org/doc/html/rfc6265#section-5.3>

=head2 is_session

Returns true if this is a session cookie, i.e. it has no expiration datetime nor any L</max_age> set, otherwise, it returns false.

Return value is in the form of a L<Module::Generic::Boolean> object that stringifies to 1 or 0;

=head2 is_tainted

Sets or gets the boolean value. This is a legacy method of old cookie module, but not used anymore.

Returns a L<Module::Generic::Boolean> object.

=head2 is_valid

This takes an optional hash or hash reference of parameters.

It returns true if the cookie was signed and the signature is valid, or false otherwise.

If an error occurred, this method returns C<undef> and sets an L<error|Module::Generic/error> instead, so check the return value.

    my $rv = $c->is_valid;
    die( $c->error ) if( !defined( $rv ) );
    print( "Cookie is valid? ", $rv ? 'yes' : 'no', "\n" );

Return value is in the form of a L<Module::Generic::Boolean> object that stringifies to 1 or 0;

Possible parameters are:

=over 4

=item I<key> string

The encryption key to use to sign and verify the cookie signature. Defaults to the value set with L</key>

=back

=head2 iv

This is an alias for L</initialisation_vector>

=head2 key

Set or get the encryption key used to encrypt the cookie value. This is used when L</encrypt> or L</sign> are set to true.

When used for cookie encryption, make sure the key size is big enough to satisfy the encryption algorithm requirement, which you can check with, say for C<AES>:

    perl -MCrypt::Cipher::AES -lE 'say Crypt::Cipher::AES->keysize'

In this case, it will yield C<32>. Replace above C<AES>, byt whatever algorithm you have chosen.

    perl -MCrypt::Cipher::Blowfish -lE 'say Crypt::Cipher::Blowfish->keysize'

would yield C<56> for C<Blowfish>

You can use L<Bytes::Random::Secure/random_bytes> to generate a random key:

    # will generate a 32 bytes-long key
    my $key = Bytes::Random::Secure::random_bytes(32);

=head2 match_host

Provided with an host name and this returns true if this cookie domain either is a perfect match or if the L</implicit> flag is on and the cookie domain is a subset of the host provided.

Otherwise this returns false.

=head2 max_age

Sets or gets the integer value for C<Max-Age>

This value should be an integer representing the number of seconds until this cookie expires.

As per the rfc6265, C<Max-Age> takes precedence over C<Expires> when set, so if you set this, any value set with L</expires> will be discarded.

Returns a L<Module::Generic::Number> object.

=head2 maxage

Alias for L</max_age>

=head2 name

Sets or gets the cookie name.

As per the L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>, a cookie name cannot contain any of the following charadcters:

    \(\)\<\>\@\,\;\:\\\"\/\[\]\?\=\{\}

Returns a L<Module::Generic::Scalar> object.

=head2 path

Sets or gets the path.

Returns a L<Module::Generic::Scalar> object.

=head2 port

Sets or gets the port number.

Returns a L<Module::Generic::Number> object.

=head2 reset

Set the reset flag to true, which will force L</as_string> to recompute the string value of the cookie.

=head2 same_as

Provided with another object and this returns true if it has the same property values, false otherwise.

This is used in overloaded object comparison, such as:

    print( "Same cookie\n" ) if( $c1 eq $c2 );
    # or
    print( "Same cookie\n" ) if( $c1 == $c2 );

=head2 same_site

Sets or gets the boolean value for C<Same-Site>.

The proper values should be C<Relaxed>, C<Strict> or C<None>, but this module does not enforce the value you set. Setting a proper value is your responsibility.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite> for more information.

If set to C<None>, L<secure> should be set to true.

See L<rfc 6265|https://datatracker.ietf.org/doc/html/draft-west-first-party-cookies-07> for more information.

See also L<CanIUse|https://caniuse.com/same-site-cookie-attribute>

Returns a L<Module::Generic::Scalar> object.

=head2 samesite

Alias for L</same_site>.

=head2 secure

Sets or gets the boolean value for C<Secure>.

Returns a L<Module::Generic::Boolean> object.

=head2 sign

Set or get the boolean value. If true, then the cookie value will be signed. The way this works, is that L<Crypt::Mac::HMAC/hmac_b64> will create a C<SHA256> encrypted digest using the encryption key you provided with L</key> and attach the signature to the cookie value separated by a dot. For example:

    my $cookie_value = "toc_ok=1";
    my $key = "hard to guess key";
    my $signature = Crypt::Mac::HMAC::hmac_b64( $key, $cookie_value );
    # signature is I2M4/rh/TiNV5RZDSBJkhLblBvrN5k9448G6w/gp/jg=
    # cookie resulting value before uri encoding:
    # toc_ok%3D1.I2M4/rh/TiNV5RZDSBJkhLblBvrN5k9448G6w/gp/jg=

So, you need to have the module L<Crypt::Mac> installed to be able to use this feature.

Signature are used to ensure data integrity protection for content that are not secret.

For more secret content, use L</encrypt>.

You can read more about the difference between L<sign and encryption at Stackoverflow|https://stackoverflow.com/questions/41467012/what-is-the-difference-between-signed-and-encrypted-cookies-in-rails>

=head2 strict

Boolean. Should this API be strict about the cookie names?
When true, this will reject cookie names with invalid characters.

Cookie name can contain only US ASCII characters and exclude any separators such as C<< ( ) < > @ , ; : \ " / [ ] ? = { } >>

=head2 uri

If a value is provided, it will be transformed into a L<URI> object, and its C<port>, C<path> and C<host> components will be used to set the values for L</port>, L</path> and L</domain> respectively.

Otherwise, with no value provided, this will form an L<URI> object based on the cookie secure flag, C<domain>, C<port>, and C<path>

    $c->uri( 'https://www.example.com:8080/some/where?q=find+me' );
    # sets host to www.example.com, port to 8080 and path to /some/where
    my $uri = $c->uri;
    # get an uri based on cookie properties value, such as:
    # https://www.example.com:8080/some/where

=head2 value

Sets or gets the value for this cookie.

Returns a L<Module::Generic::Scalar> object.

=head2 version

Sets or gets the cookie version. This was used in version 2 of the cookie standard, but has since been deprecated by L<rfc6265|https://datatracker.ietf.org/doc/html/rfc6265>.

Returns a L<Module::Generic::Number> object.

=head2 _header_datetime

Given a L<DateTime> object, or by default will instantiate a new one, and this will set its formatter to L<DateTime::Format::Strptime> with the appropriate format to ensure the stringification produces a rfc6265 compliant datetime string.

=head2 TO_JSON

This method is used so that if the cookie object is part of some data encoded into json, this will convert the cookie data properly to be used by L<JSON>

=head1 SIGNED COOKIES

As shown in the L</SYNOPSIS> you can sign cookies effortlessly. This package has taken all the hassle of doing it for you.

To use this feature you need to have installed L<Crypt::Mode::CBC> which is part of L<CryptX>

The methods available to use for cookie integrity protection are: L</key>, L</sign> to enable cookie signature, L</is_valid> to check if the signature is valid.

Cookie signature is performed by L<CryptX>, which is an XS module, and thus very fast.

=head1 ENCRYPTED COOKIES

As shown in the L</SYNOPSIS> you can encrypt cookies effortlessly. This package has taken all the hassle of doing it for you.

To use this feature you need to have installed L<Crypt::Mode::CBC> which is part of L<CryptX>

The methods available to use for cookie encryption are: L</algo> to set the desired algorithm, L</key>, L</encrypt> to enable encryption, L</decrypt> to decrypt the cookie value, and optionally L</initialisation_vector>.

Cookie encryption is performed by L<CryptX>, which is an XS module, and thus very fast.

=head1 INSTALLATION

As usual, to install this module, you can do:

    perl Makefile.PL
    make
    make test
    sudo make install

If you have Apache/modperl2 installed, this will also prepare the Makefile and run test under modperl.

The Makefile.PL tries hard to find your Apache configuration, but you can give it a hand by specifying some command line parameters. See L<Apache::TestMM> for available parameters or you can type on the command line:

    perl -MApache::TestConfig -le 'Apache::TestConfig::usage()'

For example:

    perl Makefile.PL -apxs /usr/bin/apxs -port 1234
    # which will also set the path to httpd_conf, otherwise
    perl Makefile.PL -httpd_conf /etc/apache2/apache2.conf

    # then
    make
    make test
    sudo make install

See also L<modperl testing documentation|https://perl.apache.org/docs/general/testing/testing.html>

But, if for some reason, you do not want to perform the mod_perl tests, you can use C<NO_MOD_PERL=1> when calling C<perl Makefile.PL>, such as:

    NO_MOD_PERL=1 perl Makefile.PL
    make
    make test
    sudo make install

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Cookie::Jar>, L<Apache2::Cookies>, L<APR::Request::Cookie>

L<rfc6265|https://datatracker.ietf.org/doc/html/rfc6265>

L<Latest tentative version of the cookie standard|https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-09>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
