##----------------------------------------------------------------------------
## Cookies API for Server & Client - ~/lib/Cookie/Jar.pm
## Version v0.1.1
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/10/08
## Modified 2021/11/17
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Cookie::Jar;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    our( $MOD_PERL, $MOD_PERL_VERSION );
    if( exists( $ENV{MOD_PERL} )
        &&
        ( $MOD_PERL = $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ ) )
    {
        $MOD_PERL_VERSION = $1;
        select( ( select( STDOUT ), $| = 1 )[ 0 ] );
        require Apache2::Const;
        Apache2::Const->import( compile => qw( :common :http OK DECLINED ) );
        require APR::Pool;
        require APR::Table;
        require Apache2::RequestUtil;
        require APR::Request::Apache2;
        require APR::Request::Cookie;
    }
    use Cookie;
    use Cookie::Domain;
    use DateTime;
    use JSON;
    use Module::Generic::File qw( file );
    use Module::Generic::HeaderValue;
    use Nice::Try;
    use Scalar::Util;
    use URI::Escape ();
    our $VERSION = 'v0.1.1';
    # This flag to allow extensive debug message to be enabled
    our $COOKIES_DEBUG = 0;
};

sub init
{
    my $self = shift( @_ );
    # Apache2::RequestRec object
    my $req;
    $req = shift( @_ ) if( @_ && ( @_ % 2 ) );
    $self->{host} = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{request} = $req if( $req );
    # Repository of all objects
    $self->{_cookies} = [];
    # Index by host, path, name
    $self->{_index} = {};
    return( $self );
}

sub add
{
    my $self = shift( @_ );
    my $this;
    if( scalar( @_ ) == 1 )
    {
        $this = shift( @_ );
    }
    elsif( scalar( @_ ) )
    {
        $this = $self->_get_args_as_hash( @_ );
    }
    else
    {
        return( $self->error( "No data was provided to add a cookie in the repository." ) );
    }
    if( ref( $this ) eq 'HASH' )
    {
        $this = $self->make( $this );
        return( $self->pass_error ) if( !defined( $this ) );
    }
    # A string ?
    elsif( !ref( $this ) )
    {
        my $hv = Module::Generic::HeaderValue->new_from_header( $this, decode => 1, debug => $self->debug ) ||
            return( $self->error( Module::Generic::HeaderValue->error ) );
        my $ref = {};
        $ref->{name} = $hv->value->first;
        $ref->{value} = $hv->value->second;
        $self->message( 4, "Properties found: '", $hv->params->keys->sort->join( "', '" ), "'." ) if( $COOKIES_DEBUG );
        $hv->params->foreach(sub
        {
            my( $n, $v ) = @_;
            $ref->{ $n } = $v;
            return(1);
        });
        $ref->{secure} = 1 if( CORE::exists( $ref->{secure} ) );
        # In case those were provided too in the cookie line
        $ref->{samesite} = 1 if( CORE::exists( $ref->{samesite} ) );
        $ref->{httponly} = 1 if( CORE::exists( $ref->{httponly} ) );
        $self->message( 4, "Adding cookies with properties: ", sub{ $self->SUPER::dump( $ref ) }) if( $COOKIES_DEBUG );
        $this = $self->make( %$ref );
        return( $self->pass_error ) if( !defined( $this ) );
    }
    elsif( !$self->_is_object( $this ) || 
           ( $self->_is_object( $this ) && !$this->isa( 'Cookie' ) ) )
    {
        return( $self->error( "I was expecting an hash reference or a Cookie object, but instead I got '$this'." ) );
    }
    my $ref = $self->_cookies;
    my $idx = $self->_index;
    $this->name or return( $self->error( "No cookie name was set in this cookie." ) );
    my $key = $self->key( $this ) || return( $self->pass_error );
    $self->message( 4, "Adding cookie '", $this->name, "' with key '$key' to our repository." ) if( $COOKIES_DEBUG );
    $ref->push( $this );
    $idx->{ $key } = [] if( !CORE::exists( $idx->{ $key } ) );
    push( @{$idx->{ $key }}, $this );
    return( $this );
}

sub add_cookie_header { return( shift->add_request_header( @_ ) ); }

sub add_request_header
{
    my $self = shift( @_ );
    my $req  = shift( @_ ) || return( $self->error( "No request object was provided." ) );
    return( $self->error( "Request object provided is not an object." ) ) if( !Scalar::Util::blessed( $req ) );
    return( $self->error( "Request object provided does not support the uri or header methods." ) ) if( !$req->can( 'uri' ) || !$req->can( 'header' ) );
    my $uri = $req->uri || return( $self->error( "No uri set in the request object." ) );
    $self->message( 3, "Adding cookies to request header for uri '$uri'." ) if( $COOKIES_DEBUG );
    my $scheme = $uri->scheme;
    unless( $scheme =~ /^https?\z/ )
    {
        return( '' );
    }
    my( $host, $port, $path );
    if( $host = $req->header( 'Host' ) )
    {
        $host =~ s/:(\d+)$//;
        $host = lc( $host );
        $port = $1;
    }
    else
    {
        $host = lc( $uri->host );
    }
    my $is_secure = ( $scheme eq 'https' ? 1 : 0 );
    # URI::URL method
    if( $uri->can( 'epath' ) )
    {
        $path = $uri->epath;
    }
    else
    {
        # URI::_generic method
        $path = $uri->path;
    }
    $path = '/' unless( length( $path ) );
    $port = $uri->port if( !defined( $port ) || !length( $port ) );
    # my $now = time();
    my $now = DateTime->now;
    $path = $self->_normalize_path( $path ) if( CORE::index( $path, '%' ) != -1 );
    my $dom = Cookie::Domain->new || return( $self->pass_error( Cookie::Domain->error ) );
    my $res = $dom->stat( $host );
    return( $self->pass_error( $dom->error ) ) if( !defined( $res ) );
    if( !CORE::length( $res ) || ( $res && !$res->domain->length ) )
    {
        $self->message( 3, "No root domain found for host \"$host\"." );
        return( $self->error( "No root domain found for host \"$host\"." ) );
    }
    my $root = $res->domain;
    # rfc6265, section 5.4
    # "Either:
    # The cookie's host-only-flag is true and the canonicalized request-host is identical to the cookie's domain.
    # Or:
    # The cookie's host-only-flag is false and the canonicalized request-host domain-matches the cookie's domain."
    # Meaning, $host is, for example, www.example.or.jp and cookie domain was not set and defaulted to example.or.jp, then it matches; or
    # cookie domain was explicitly set to www.example.or.jp and matches www.example.or.jp
    # <https://datatracker.ietf.org/doc/html/rfc6265#section-5.4>
    # cookie values for the "Cookie" header
    my @values = ();
    my @ok_cookies = ();
    # Get all cookies for the canonicalised request-host and its sub domains, then we check each one found according to rfc6265 algorithm as stated above
    my $cookies = $self->get_by_domain( $root, with_subdomain => 1 );
    $self->messagef( 3, "%d cookies for for canonicalised domain '$root'", $cookies->length );
    # Ref: rfc6265, section 5.4
    # <https://datatracker.ietf.org/doc/html/rfc6265#section-5.4>
    foreach my $c ( @$cookies )
    {
        unless( $c->host_only && $root eq $c->domain ||
                !$c->host_only && $host eq $c->domain )
        {
            $self->message( 3, "This cookie '", $c->name, "' has domain '", $c->domain, "' not matching request host '$host'. Is this cookie domain a host-only domain (implicit)? ", ( $c->host_only ? 'yes' : 'no' ) );
            next;
        }
        $self->message( 3, "Cookie '", $c->name, "' expiration is '", $c->expires, "' vs now ($now)" ) if( $COOKIES_DEBUG );
        if( index( $path, $c->path ) != 0 )
        {
            $self->message( 3, "This cookie \"", $c->name, "\" does not have an applicable path (", $c->path, ")." ) if( $COOKIES_DEBUG );
            next;
        }
        elsif( !$is_secure && $c->secure )
        {
            $self->message( 3, "Requested connection is not using ssl, but this cookie require a secure connection." ) if( $COOKIES_DEBUG );
            next;
        }
        # elsif( $c->expires && $c->expires->epoch < $now )
        elsif( $c->expires && $c->expires < $now )
        {
            $self->message( 3, "The cookie has expired. Cookie expired on ", $c->expires->stringify ) if( $COOKIES_DEBUG );
            next;
        }
        elsif( $c->port && $c->port != $port )
        {
            $self->message( 3, "Cookie port '", $c->port, "' does not match request port '$port'" ) if( $COOKIES_DEBUG );
            next;
        }
        push( @ok_cookies, $c );
    }
    
    # sort cookies by path and by creation date.
    # Ref: rfc6265, section 5.4.2:
    # "Cookies with longer paths are listed before cookies with shorter paths."
    # "Among cookies that have equal-length path fields, cookies with earlier creation-times are listed before cookies with later creation-times."
    # <https://datatracker.ietf.org/doc/html/rfc6265#section-5.4>
    # The OR here actually means AND, since the <=> comparison returns false when 2 elements are equal
    # So when 2 path are the same, we differentiate them by their creation date
    foreach my $c ( sort{ $b->path->length <=> $a->path->length || $a->created_on <=> $b->created_on } @ok_cookies )
    {
        push( @values, $c->as_string({ is_request => 1 }) );
        # rfc6265, section 5.4.3
        # <https://datatracker.ietf.org/doc/html/rfc6265#section-5.4>
        # "Update the last-access-time of each cookie in the cookie-list to the current date and time."
        $c->accessed_on( time() );
    }

    if( @values )
    {
        if( my $old = $req->header( 'Cookie' ) )
        {
            unshift( @values, $old );
        }
        $req->header( Cookie => join( '; ', @values ) );
    }
    return( $req );
}

sub add_response_header
{
    my $self = shift( @_ );
    my $resp = shift( @_ );
    my $r = $self->request;
    if( $resp )
    {
        return( $self->error( "Request object provided is not an object." ) ) if( !$self->_is_object( $resp ) );
        return( $self->error( "Request object provided does not support the header methods." ) ) if( !$resp->can( 'header' ) );
    }
    my @values = ();
    my $ref = $self->_cookies;
    foreach my $c ( sort{ $a->path->length <=> $b->path->length } @$ref )
    {
        
        $c->debug( $self->debug );
        $self->message( 4, "Checking cookie '", $c->name, "' with expiration date of '", $c->expires, "'" ) if( $COOKIES_DEBUG );
        if( $c->discard )
        {
            $self->message( 3, "Cookie is marked to be discarded, skipping." ) if( $COOKIES_DEBUG );
            next;
        }
        
        if( $resp )
        {
            $self->message( 4, "Adding cookie '", $c->name, "' to response object." ) if( $COOKIES_DEBUG );
            $resp->headers->push_header( 'Set-Cookie' => "$c" );
        }
        elsif( $r )
        {
            $self->message( 4, "Adding cookie '", $c->name, "' using Apache2::RequestRec." ) if( $COOKIES_DEBUG );
            # APR::Table
            # We use 'add' and not 'set'
            $r->err_headers_out->add( 'Set-Cookie' => "$c" );
        }
        else
        {
            $self->message( 4, "Adding cookie '", $c->name, "' to list for return string." ) if( $COOKIES_DEBUG );
            push( @values, "Set-Cookie: $c" );
        }
    }
    if( @values )
    {
        return( wantarray() ? @values : join( "\015\012", @values ) );
    }
    # We return our object only if a response object or an Apache2::RequestRec was set
    # because otherwise if the user is expecting the cookie as a returned string, 
    # we do not want to return our object instead when there is no cookie to return.
    return( $self ) if( $r || $resp );
    return( '' );
}

sub delete
{
    my $self = shift( @_ );
    my $ref = $self->_cookies;
    my $idx = $self->_index;
    if( scalar( @_ ) == 1 && $self->_is_a( $_[0], 'Cookie' ) )
    {
        my $c = shift( @_ );
        $self->message( 4, "Trying to remove cookie name '", $c->name, "' with host '", $c->domain, "' and path '", $c->path, "'." ) if( $COOKIES_DEBUG );
        my $addr = Scalar::Util::refaddr( $c );
        my $removed = $self->new_array;
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            my $this = $ref->[$i];
            $self->message( 4, "Checking target cookie '", $c->name, "' against this cookie '", $this->name, "'." ) if( $COOKIES_DEBUG );
            if( Scalar::Util::refaddr( $this ) eq $addr )
            {
                my $key = $self->key( $this );
                $self->message( 4, "Target cookie with address '$addr' matches this cookie. Now checking if index '$key' exists." ) if( $COOKIES_DEBUG );
                if( CORE::exists( $idx->{ $key } ) )
                {
                    # if( !$self->_is_array( $idx->{ $key } ) )
                    if( !Scalar::Util::reftype( $idx->{ $key } ) eq 'ARRAY' )
                    {
                        $self->message( 4, "I was expecting an array for key '$key', but got '", overload::StrVal( $idx->{ $key } ), "' (", ref( $idx->{ $key } ), ")" ) if( $COOKIES_DEBUG );
                        return( $self->error( "I was expecting an array for key '$key', but got '", overload::StrVal( $idx->{ $key } ), "' (", ref( $idx->{ $key } ), ")" ) );
                    }
                    $self->message( 4, "Found matching index entry for key '$key'." ) if( $COOKIES_DEBUG );
                    for( my $j = 0; $j < scalar( @{$idx->{ $key }} ); $j++ )
                    {
                        if( Scalar::Util::refaddr( $idx->{ $key }->[$j] ) eq $addr )
                        {
                            $self->message( 4, "Removing cookie match by address at offset $j of index '$key'" ) if( $COOKIES_DEBUG );
                            CORE::splice( @{$idx->{ $key }}, $j, 1 );
                            $j--;
                        }
                    }
                    # Cleanup
                    CORE::delete( $idx->{ $key } ) if( scalar( @{$idx->{ $key }} ) == 0 );
                }
                $self->message( 4, "Removing object from object repository." ) if( $COOKIES_DEBUG );
                CORE::splice( @$ref, $i, 1 );
                $removed->push( $c );
            }
        }
        return( $removed );
    }
    else
    {
        my( $name, $host, $path ) = @_;
        $host ||= $self->host || '';
        $path //= '';
        return( $self->error( "No cookie object provided nor any cookie name either." ) ) if( !defined( $name ) || !CORE::length( "$name" ) );
        my $key = $self->key( $name => $host, $path );
        my $removed = $self->new_array;
        return( $removed ) if( !CORE::exists( $idx->{ $key } ) );
        return( $self->error( "I was expecting an array for key '$key', but got '", overload::StrVal( $idx->{ $key } ), "'" ) ) if( !$self->_is_array( $idx->{ $key } ) );
        $removed->push( @{$idx->{ $key }} );
        foreach my $c ( @$removed )
        {
            next if( !ref( $c ) || !$self->_is_a( $c, 'Cookie' ) );
            my $addr = Scalar::Util::refaddr( $c );
            for( my $i = 0; $i < scalar( @$ref ); $i++ )
            {
                if( Scalar::Util::refaddr( $ref->[$i] ) eq $addr )
                {
                    CORE::splice( @$ref, $i, 1 );
                    last;
                }
            }
        }
        # Remove cookie and return the previous entry
        CORE::delete( $idx->{ $key } );
        return( $removed );
    }
}

sub do
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No callback code was provided." ) );
    return( $self->error( "Callback code provided is not a code." ) ) if( ref( $code ) ne 'CODE' );
    my $ref = $self->_cookies;
    my $all = $self->new_array;
    foreach my $c ( @$ref )
    {
        next if( !ref( $c ) || !$self->_is_a( $c, 'Cookie' ) );
        try
        {
            local $_ = $c;
            my $rv = $code->( $c );
            if( !defined( $rv ) )
            {
                last;
            }
            elsif( $rv )
            {
                $all->push( $c );
            }
        }
        catch( $e )
        {
            return( $self->error( "An unexpected error occurred while calling code reference on cookie named \"", $ref->{ $n }->name, "\": $e" ) );
        }
    }
    return( $all );
}

sub exists
{
    my $self = shift( @_ );
    my( $name, $host, $path ) = @_;
    $host ||= $self->host || '';
    $path //= '';
    return( $self->error( "No cookie name was provided to check if it exists." ) ) if( !defined( $name ) || !CORE::length( $name ) );
    $self->message( 3, "Checking cookie '$name' exists using host '$host' and path '$path'" ) if( $COOKIES_DEBUG );
    my $c = $self->get( $name => $host, $path );
    return( defined( $c ) ? 1 : 0 );
}

# From http client point of view
sub extract
{
    my $self = shift( @_ );
    my $resp = shift( @_ ) || return( $self->error( "No response object was provided." ) );
    return( $self->error( "Response object provided is not an object." ) ) if( !Scalar::Util::blessed( $resp ) );
    my $uri;
    if( $self->_is_a( $resp, 'HTTP::Response' ) )
    {
        $self->message( 3, "Response object provided is of class HTTP::Response" ) if( $COOKIES_DEBUG );
        my $req = $resp->request;
        return( $self->error( "No HTTP::Request object is set in this HTTP::Response." ) ) if( !$resp->request );
        $uri = $resp->request->uri;
    }
    elsif( $resp->can( 'uri' ) && $resp->can( 'header' ) )
    {
        $self->message( 3, "Response object provided is not an HTTP::Response object, but has the uri and header methods." ) if( $COOKIES_DEBUG );
        $uri = $resp->uri;
    }
    else
    {
        return( $self->error( "Response object provided does not support the uri or scheme methods and is not a class or subclass of HTTP::Response either." ) );
    }
    $self->message( 3, "Set-Cookie header is: ", sub{ $self->SUPER::dump( [$resp->header( 'Set-Cookie' )] ) } ) if( $COOKIES_DEBUG );
    my $all = Module::Generic::HeaderValue->new_from_multi( [$resp->header( 'Set-Cookie' )], debug => $self->debug, decode => 1 ) ||
        return( $self->pass_error( Module::Generic::HeaderValue->error ) );
    return( $resp ) unless( $all->length );
    $uri || return( $self->error( "No uri set in the response object." ) );
    $self->message( 3, "URI is '$uri'" ) if( $COOKIES_DEBUG );
    my( $host, $port, $path );
    if( $host = $resp->header( 'Host' ) ||
        ( $resp->request && ( $host = $resp->request->header( 'Host' ) ) ) )
    {
        $host =~ s/:(\d+)$//;
        $host = lc( $host );
        $port = $1;
    }
    else
    {
        $host = lc( $uri->host );
    }
    
    # URI::URL method
    if( $uri->can( 'epath' ) )
    {
        $path = $uri->epath;
    }
    else
    {
        # URI::_generic method
        $path = $uri->path;
    }
    $path = '/' unless( length( $path ) );
    $port = $uri->port if( !defined( $port ) || !length( $port ) );
    my $dom = Cookie::Domain->new || return( $self->pass_error( Cookie::Domain->error ) );
    $self->message( 3, "Guessing root domain for host '$host'." ) if( $COOKIES_DEBUG );
    my $res = $dom->stat( $host );
    if( !defined( $res ) )
    {
        $self->message( 3, "Error found while trying to get root domain for host \"$host\"." ) if( $COOKIES_DEBUG );
        return( $self->pass_error( $dom->error ) );
    }
    # Possibly empty
    $self->message( 3, "No root found in public suffix for host \"$host\"." ) if( !$res );
    my $root = $res ? $res->domain : '';
    
    foreach my $o ( @$all )
    {
        my( $name, $value ) = $o->value->list;
        $self->message( 3, "Creating cookie with name '$name' and value '$value'" );
        my $c = Cookie->new( name => $name, value => $value ) || 
            return( $self->pass_error( Cookie->error ) );
        if( CORE::length( $o->param( 'expires' ) ) )
        {
            my $dt = $self->_parse_timestamp( $o->param( 'expire' ) );
            if( $dt )
            {
                $c->expires( $dt );
            }
            else
            {
                $c->expires( $o->param( 'expires' ) );
            }
        }
        elsif( CORE::length( $o->param( 'max-age' ) ) )
        {
            $c->max_age( $o->param( 'max-age' ) );
        }
        
        if( $o->param( 'domain' ) )
        {
            $self->message( 3, "Using domain specified in cookie attribute '", $o->param( 'domain' ), "'." ) if( $COOKIES_DEBUG );
            # rfc6265, section 5.2.3:
            # "If the first character of the attribute-value string is %x2E ("."): Let cookie-domain be the attribute-value without the leading %x2E (".") character."
            # Ref: <https://datatracker.ietf.org/doc/html/rfc6265#section-5.2.3>
            my $c_dom = $o->param( 'domain' );
            # Remove leading dot as per rfc specifications
            $c_dom =~ s/^\.//g;
            # "Convert the cookie-domain to lower case."
            $c_dom = lc( $c_dom );
            # Check the domain name is legitimate, i.e.s ent from a host that has authority
            # "The user agent will reject cookies unless the Domain attribute specifies a scope for the cookie that would include the origin server.  For example, the user agent will accept a cookie with a Domain attribute of "example.com" or of "foo.example.com" from foo.example.com, but the user agent will not accept a cookie with a Domain attribute of "bar.example.com" or of "baz.foo.example.com"."
            # <https://tools.ietf.org/html/rfc6265#section-4.1.2.3>
            if( CORE::length( $c_dom ) >= CORE::length( $root ) && 
                ( $c_dom eq $host || $host =~ /\.$c_dom$/ ) )
            {
                $c->domain( $c_dom );
            }
            else
            {
                $self->message( 3, "This cookie '$name' has a domain '$c_dom' that is either set to the public prefix or is not same as the remote host '$host' nor is it a domain higher in hierarchy." ) if( $COOKIES_DEBUG );
                next;
            }
        }
        # "If omitted, defaults to the host of the current document URL, not including subdomains."
        # <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>
        else
        {
            if( $root )
            {
                $self->message( 3, "Using root '$root'" ) if( $COOKIES_DEBUG );
                $c->domain( $root );
                $c->implicit(1);
            }
            else
            {
                $self->message( 3, "No suitable domain derived from host '$host'" ) if( $COOKIES_DEBUG );
            }
        }
        
        $self->message( 3, "Cookie specified path is '", $o->param( 'path' ), "'." ) if( $COOKIES_DEBUG );
        # rfc6265: "If the server omits the Path attribute, the user agent will use the "directory" of the request-uri's path component as the default value."
        if( defined( $o->param( 'path' ) ) && CORE::length( $o->param( 'path' ) ) )
        {
            $c->path( $o->param( 'path' ) );
            $self->message( 3, "Using cookie specified path '", $o->param( 'path' ), "'." ) if( $COOKIES_DEBUG );
        }
        else
        {
            my $frag = $self->new_array( [split( /\//, $path )] );
            # Not perfect
            if( $path eq '/' || substr( $path, -1, 1 ) eq '/' )
            {
                $c->path( $path );
                $self->message( 3, "Path ($path) end with a /, so using this as the path directory." ) if( $COOKIES_DEBUG );
            }
            else
            {
                $frag->pop;
                $c->path( $frag->join( '/' )->scalar );
                $self->message( 3, "Using path ($path) upper directory as path -> '", $c->path, "'." ) if( $COOKIES_DEBUG );
            }
        }
        $c->port( $port ) if( defined( $port ) );
        $self->message( 3, "Port is set to '", $c->port, "'." ) if( $COOKIES_DEBUG );
        $c->http_only(1) if( $o->param( 'httponly' ) );
        $c->secure(1) if( $o->param( 'secure' ) );
        $c->same_site(1) if( $o->param( 'samesite' ) );
        
        $self->message( 4, "Checking if we already have a cookie for name '", $c->name, "', host '", $c->domain, "' and path '", $c->path, "'." ) if( $COOKIES_DEBUG );
        my @old = $self->get({ name => $c->name, host => $c->domain, path => $c->path });
        $self->messagef( 4, "Found %d cookie(s) matching ours.", scalar( @old ) );
        if( scalar( @old ) )
        {
            $c->created_on( $old[0]->created_on ) if( $old[0]->created_on );
            $self->messagef( 4, "Removing %d cookie(s) identical to this new one.", scalar( @old ) );
            # $self->replace( $c );
            for( @old )
            {
                my $arr;
                $arr = $self->delete( $_ ) || do
                {
                    $self->message( 4, "Error trying to remove cookie '", $_->name, "': ", $self->error ) if( $COOKIES_DEBUG );
                };
                $self->messagef( 4, "%d cookie objects removed.", $arr->length ) if( $COOKIES_DEBUG );
            }
        }
        $self->message( 3, "Adding cookie name '", $c->name, "'." ) if( $COOKIES_DEBUG );        
        $self->add( $c ) || return( $self->pass_error );
    }
    return( $self );
}

sub extract_cookies { return( shift->extract( @_ ) ); }

# From server point of view
sub fetch
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{string} //= '';
    $opts->{store} = 1 if( !CORE::exists( $opts->{store} ) );
    my $host = $opts->{host} || $self->host || '';
    my $cookie_header;
    my $r = $self->request;
    my $cookies = [];
    if( $r )
    {
        $self->message( 3, "Fetching cookie from Apache headers: ", $r->as_string ) if( $COOKIES_DEBUG );
        try
        {
            my $pool = $r->pool;
            $self->message( 3, "Getting an APR Table object instance." ) if( $COOKIES_DEBUG );
            # my $o = APR::Request::Apache2->handle( $r->pool );
            my $o = APR::Request::Apache2->handle( $r );
            if( $o->jar_status =~ /^(?:Missing input data|Success)$/ )
            {
                # all cookie names in order of appearance in the Cookie request header
                my @all = $o->jar;
                foreach my $cookie_name ( @all )
                {
                    my @values = $o->jar( $cookie_name );
                    foreach my $v ( @values )
                    {
                        # And of course, Apache/modperl does not uri decode the cookie value...
                        $v = URI::Escape::uri_unescape( $v );
                        my $c = $self->make( name => $cookie_name, value => $v );
                        push( @$cookies, $c );
                    }
                }
                $self->messagef( 3, "%d cookies found using APR::Request::Apache2.", scalar( @$cookies ) );
            }
            else
            {
                $self->message( 3, "Malformed cookie found: ", $o->jar_status );
            }
        }
        catch( $e )
        {
            $self->message( 3, "An error occurred while trying to get cookies using APR::Request::Apache2, reverting to Cookie header: $e" );
        }
        $cookie_header = $r->headers_in->get( 'Cookie' );
    }
    elsif( $opts->{request} && $self->_is_object( $opts->{request} ) && $opts->{request}->can( 'header' ) )
    {
        $cookie_header = $opts->{request}->header( 'Cookie' );
    }
    elsif( CORE::length( $opts->{string} ) )
    {
        $cookie_header = $opts->{string};
    }
    else
    {
        $cookie_header = $ENV{HTTP_COOKIE} // '';
    }
    $self->message( 3, "Raw cookie header found is '$cookie_header'" );
    if( !scalar( @$cookies ) )
    {
        my $ref = $self->parse( $cookie_header );
        foreach my $def ( @$ref )
        {
            my $c = $self->make( name => $def->{name}, value => $def->{value} ) ||
                return( $self->pass_error );
            push( @$cookies, $c );
        }
        $self->messagef( 3, "%d cookies found using Cookie header: %s", scalar( @$cookies ), join( ', ', map( $_->name, @$cookies ) ) );
    }
    # We are called in void context like $jar->fetch which means we fetch the cookies and add them to our stack internally
    if( $opts->{store} )
    {
        foreach my $c ( @$cookies )
        {
            $self->add( $c ) || return( $self->pass_error );
        }
    }
    return( $self->new_array( $cookies ) );
}

sub get
{
    my $self = shift( @_ );
    # If called on the server side, $host and $path would likely be undefined
    # my( $name, $host, $path ) = @_;
    my( $name, $host, $path );
    if( scalar( @_ ) == 1 && $self->_is_a( $_[0], 'Cookie' ) )
    {
        my $c = shift( @_ );
        $name = $c->name;
        $host = $c->host;
        $path = $c->path;
    }
    elsif( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
    {
        my $this = shift( @_ );
        ( $name, $host, $path ) = @$this{qw( name host path )};
    }
    elsif( scalar( @_ ) > 0 && scalar( @_ ) <= 3 )
    {
        ( $name, $host, $path ) = @_;
    }
    else
    {
        return( $self->error( "Error calling get: I was expecting either a Cookie object, or a list or hash reference of parameters." ) );
    }
    return( $self->error( "No cookie name was provided to get its object." ) ) if( !defined( $name ) || !CORE::length( $name ) );
    $host //= $self->host || '';
    $path //= '';
    my $ref = $self->_cookies;
    my $idx = $self->_index;
    my $key = $self->key( $name => $host, $path );
    # Return immediately if we found a perfect match
    if( CORE::exists( $idx->{ $key } ) )
    {
        return( wantarray() ? @{$idx->{ $key }} : $idx->{ $key }->[0] );
    }
    # If it does not exist, we check each of our cookie to see if it is a higher level cookie.
    # For example, $host is www.example.org and our cookie key host part is example.org
    # In this case, example.org would match, because the cookie would apply also to sub domains.
    my @found = ();
    foreach my $c ( @$ref )
    {
        my $c_name = $c->name;
        my $c_host = $c->domain;
        my $c_path = $c->path;
        $self->message( 4, "Checking name '", ( $name // '' ), "' and host '", ( $host // '' ), "' against this cookie '", ( $c_name // '' ), "' with host '", ( $c_host // '' ), "' and path '", ( $c_path // '' ), "'." ) if( $COOKIES_DEBUG );
        
        $self->message( 4, "Does name '", ( $name // '' ), "' matches this cookie name '", ( $c_name // '' ), "'? ", ( $name eq $c_name ? 'yes' : 'no' ) ) if( $COOKIES_DEBUG );
        next unless( $c_name eq $name );
        
        $self->message( 4, "Is host '", ( $host // '' ), "' empty? ", ( !defined( $host ) || !CORE::length( $host ) ? 'yes' : 'no' ) ) if( $COOKIES_DEBUG );
        
        if( !defined( $host ) || !CORE::length( $host ) )
        {
            $self->message( 4, "Adding cookie '$name' that matched this cookie" ) if( $COOKIES_DEBUG );
            push( @found, $c );
            next;
        }
        
        $self->message( 4, "Checking now if host '", ( $host // '' ), "' is part of '.", ( $c_host // '' ), "'" ) if( $COOKIES_DEBUG );
        if( defined( $c_host ) && 
            ( $host eq $c_host || index( reverse( $host ), reverse( ".${c_host}" ) ) == 0 ) )
        {
            $self->message( 3, "Found cookie '$c_name' with domain '$c_host' matching perfectly or being a higher host than '$host'." ) if( $COOKIES_DEBUG );
            if( defined( $path ) && CORE::length( "$path" ) )
            {
                $self->message( 4, "Checking path '$path' against this cookie path '$c_path'" ) if( $COOKIES_DEBUG );
                if( index( $path, $c_path ) == 0 )
                {
                $self->message( 4, "Found cookie path '$c_path' matching path '$path', returning it." ) if( $COOKIES_DEBUG );
                    push( @found, $c );
                }
            }
            else
            {
                $self->message( 4, "No requested path provided, returning cookie based on name and host match only." ) if( $COOKIES_DEBUG );
                push( @found, $c );
            }
        }
    }
    
    if( scalar( @found ) )
    {
        return( wantarray() ? @found : $found[0] );
    }
    
    $self->message( 4, "Keys in index are: '", join( "', '", sort( keys( %$idx ) ) ), "'" ) if( $COOKIES_DEBUG );
    # Ultimately, check if there is a cookie entry with just the cookie name and no host
    # which happens for cookies repository on server side
    if( CORE::exists( $idx->{ $name } ) )
    {
        $self->message( 3, "Found cookie name '$name' without any host" ) if( $COOKIES_DEBUG );
        return( wantarray() ? @{$idx->{ $name }} : $idx->{ $name }->[0] );
    }
    $self->message( 3, "Did not find anything." ) if( $COOKIES_DEBUG );
    return;
}

sub get_by_domain
{
    my $self = shift( @_ );
    my $host = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{with_subdomain} = 0;
    $opts->{sort} = 1 if( !CORE::exists( $opts->{sort} ) );
    my $all  = $self->new_array;
    return( $all ) if( !defined( $host ) || !length( $host ) );
    $host = lc( $host );
    my $ref = $self->_cookies;
    foreach my $c ( @$ref )
    {
        my $dom = $c->domain; 
        $all->push( $c ) if( $dom eq $host || ( $opts->{with_subdomain} && $host =~ /\.$dom$/ ) );
    }
    my $new = [];
    if( $opts->{sort} )
    {
        $new = [sort{ $a->path cmp $b->path } @$all];
    }
    else
    {
        $new = [sort{ $b->path cmp $a->path } @$all];
    }
    return( $self->new_array( $new ) );
}

sub host { return( shift->_set_get_scalar_as_object( 'host', @_ ) ); }

sub iv { return( shift->_initialisation_vector( @_ ) ); }

sub key
{
    my $self = shift( @_ );
    my( $name, $host, $path );
    if( scalar( @_ ) == 1 && $self->_is_a( $_[0], 'Cookie' ) )
    {
        my $c = shift( @_ );
        $name = $c->name;
        $host = $c->domain;
        $path = $c->path;
    }
    else
    {
        ( $name, $host, $path ) = @_;
        return( $self->error( "Received cookie object '", overload::StrVal( $name ), "' along with cookie host '$host' and path '$path' while I was expecting cookie name, host and path. If you want to call key() with a cookie object, pass it with no other argument." ) ) if( ref( $name ) && $self->_is_a( $name, ref( $self ) ) );
    }
    return( $self->error( "No cookie name was provided to get its key." ) ) if( !CORE::length( $name ) );
    return( join( ';', $host, $path, $name ) ) if( defined( $host ) && CORE::length( $host ) );
    return( $name );
}

# Load cookie data from json cookie file
sub load
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No filename was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{host} //= '';
    $opts->{decrypt} //= 0;
    $opts->{secret} //= '';
    $opts->{algo} //= '';
    # Initialisation Vector for encryption
    # Re-use it if it was previously set
    $opts->{iv} //= $self->_initialisation_vector->scalar || '';
    my $host = $opts->{host} || $self->host || '';
    my $f = file( $file );
    my $json = $f->load;
    return( $self->pass_error( $f->error ) ) if( !defined( $json ) );
    # No need to go further
    if( !CORE::length( $json ) )
    {
        $self->message( 3, "Cookie json file provided \"$file\" is empty." ) if( $COOKIES_DEBUG );
        return( $self );
    }
    
    if( $opts->{decrypt} )
    {
        my $key = $opts->{key};
        my $algo = $opts->{algo};
        return( $self->error( "Cookies file encryption was enabled, but no key was set to decrypt it." ) ) if( !defined( $key ) || !CORE::length( "$key" ) );
        return( $self->error( "Cookies file encryption was enabled, but no algorithm was set to decrypt it." ) ) if( !defined( $algo ) || !CORE::length( "$algo" ) );
        $self->message( 4, "Value to decrypt is ", CORE::length( $json ), " bytes big." ) if( $COOKIES_DEBUG );
        try
        {
            $self->_load_class( 'Crypt::Misc' ) || return( $self->pass_error );
            my $p = $self->_encrypt_objects( @$opts{qw( key algo iv )} ) || return( $self->pass_error );
            my $crypt = $p->{crypt};
            my $bin = Crypt::Misc::decode_b64( "$json" );
            $self->message( 4, "Base64 decoded value is ", CORE::length( $bin ), " bytes big." ) if( $COOKIES_DEBUG );
            $json = $crypt->decrypt( "$bin", @$p{qw( key iv )} );
        }
        catch( $e )
        {
            return( $self->error( "An error occurred while trying to decrypt cookies file \"$file\": $e" ) );
        }
    }
    
    my $j = JSON->new->relaxed->utf8;
    my $hash;
    try
    {
        $hash = $j->decode( $json );
    }
    catch( $e )
    {
        return( $self->error( "Unable to decode ", CORE::length( $json ), " bytes of json data to perl: $e" ) );
    }
    if( ref( $hash ) ne 'HASH' )
    {
        return( $self->error( "Data retrieved from json cookie file \"$file\" does not contain an hash as expected, but instead I got '$hash'." ) );
    }
    my $last_update = CORE::delete( $hash->{last_update} );
    my $repo = CORE::delete( $hash->{cookies} );
    return( $self->error( "I was expecting the JSON cookies properties to be an array, but instead I got '$repo'" ) ) if( ref( $repo ) ne 'ARRAY' );
    foreach my $def ( @$repo )
    {
        if( !CORE::exists( $def->{name} ) ||
            !CORE::exists( $def->{value} ) )
        {
            $self->message( 3, "Cookie found from json cookie file \"$file\" that is missing core properties (name or value: ", sub{ $self->SUPER::dump( $def ) } ) if( $COOKIES_DEBUG );
            next;
        }
        elsif( !defined( $def->{name} ) || !CORE::length( $def->{name} ) )
        {
            $self->message( 3, "Found a cookie in cookie file \"$file\" who name is empty: ", sub{ $self->SUPER::dump( $def ) }) if( $COOKIES_DEBUG );
            next:
        }
        my $c = $self->make( $def ) || do
        {
            $self->message( 3, "Unable to create a cookie object for cookie \"$n\": ", $self->error ) if( $COOKIES_DEBUG );
            next;
        };
        $self->message( 4, "Saving loaded cookie '", $c->name, "' to repo." ) if( $COOKIES_DEBUG );
        $self->add( $c ) || return( $self->pass_error );
    }
    return( $self );
}

sub load_as_lwp
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No filename was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{decrypt} //= 0;
    $opts->{secret} //= '';
    $opts->{algo} //= '';
    # Initialisation Vector for encryption
    # Re-use it if it was previously set
    $opts->{iv} //= $self->_initialisation_vector->scalar || '';
    my $f = $self->new_file( $file );
    my $host = $opts->{host} || $self->host || '';
    $f->open( '<', { binmode => ( $opts->{decrypt} ? 'raw' : 'utf-8' ) }) || return( $self->pass_error( $f->error ) );
    my $code = sub
    {
        $self->message( 4, "Found line '$_'" ) if( $COOKIES_DEBUG );
        if( /^Set-Cookie3:[[:blank:]\h]*(.*?)$/ )
        {
            my $c = $self->add( $1 );
        }
        else
        {
            $self->message( 4, "Line does not match regep." ) if( $COOKIES_DEBUG );
        }
    };
    
    if( $opts->{decrypt} )
    {
        my $raw = $f->load;
        $f->close;
        my $key = $opts->{key};
        my $algo = $opts->{algo};
        return( $self->error( "Cookies file encryption was enabled, but no key was set to decrypt it." ) ) if( !defined( $key ) || !CORE::length( "$key" ) );
        return( $self->error( "Cookies file encryption was enabled, but no algorithm was set to decrypt it." ) ) if( !defined( $algo ) || !CORE::length( "$algo" ) );
        $self->message( 4, "Value to decrypt is ", CORE::length( $raw ), " bytes big." ) if( $COOKIES_DEBUG );
        try
        {
            $self->_load_class( 'Crypt::Misc' ) || return( $self->pass_error );
            my $p = $self->_encrypt_objects( @$opts{qw( key algo iv )} ) || return( $self->pass_error );
            my $crypt = $p->{crypt};
            my $bin = Crypt::Misc::decode_b64( "$raw" );
            $self->message( 4, "Base64 decoded value is ", CORE::length( $bin ), " bytes big." ) if( $COOKIES_DEBUG );
            my $data = $crypt->decrypt( "$bin", @$p{qw( key iv )} );
            $self->message( 4, "Decrypted data is: '$data'" ) if( $COOKIES_DEBUG );
            my $scalar = $self->new_scalar( \$data );
            my $io = $scalar->open || return( $self->pass_error( $! ) );
            $io->line( $code, chomp => 1, auto_next => 1 ) || return( $self->pass_error( $f->error ) );
            $io->close;
        }
        catch( $e )
        {
            return( $self->error( "An error occurred while trying to decrypt cookies file \"$file\": $e" ) );
        }
    }
    else
    {
        $f->line( $code, chomp => 1, auto_next => 1 ) || return( $self->pass_error( $f->error ) );
        $f->close;
    }
    return( $self );
}

sub load_as_netscape
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No filename was provided." ) );
    my $f = $self->new_file( $file );
    my $opts = $self->_get_args_as_hash( @_ );
    my $host = $opts->{host} || $self->host || '';
    $f->open || return( $self->pass_error( $f->error ) );
    $f->line(sub
    {
        my( $domain, $sub_too, $path, $secure, $expires, $name, $value ) = split( /\t/, $_ );
        $secure = ( lc( $secure ) eq 'true' ? 1 : 0 );
        # rfc6265 makes obsolete domains prepended with a dot.
        $domain = substr( $domain, 1 ) if( substr( $domain, 1, 1 ) eq '.' );
        $self->add({
            name    => $name,
            value   => $value,
            domain  => $domain,
            path    => $path,
            expires => $expires,
            secure  => $secure,
        });
    }, chomp => 1, auto_next => 1 ) || return( $self->pass_error( $f->error ) );
    return( $self );
}

sub make
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    no overloading;
    return( $self->error( "Cookie name was not provided." ) ) if( !$opts->{name} );
    $opts->{debug} = $self->debug;
    $self->message( 3, "Creating cookie with following parameters: ", sub{ $self->SUPER::dump( $opts ) } ) if( $COOKIES_DEBUG );
    my $c = Cookie->new( debug => $self->debug );
    return( $self->pass_error( Cookie->error ) ) if( !defined( $c ) );
    $self->message( 4, "Applying values -> ", sub{ $self->SUPER::dump( $opts ) } ) if( $COOKIES_DEBUG );
    $c->apply( $opts ) || return( $self->pass_error( $c->error ) );
    $self->message( 4, "Returning cookie object." ) if( $COOKIES_DEBUG );
    return( $c );
}

sub merge
{
    my $self = shift( @_ );
    my $jar  = shift( @_ ) || return( $self->error( "No Cookie::Jar object was provided to merge." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Cookie::Jar object provided (", overload::StrVal( $jar ), ") is not a Cookie::Jar object." ) ) if( !$self->_is_a( $jar, 'Cookie::Jar' ) );
    # We require the do method on purpose, because the scan method is from the old HTTP::Cookies api which does not send an object, but a list of cookie property value
    return( $self->error( "Cookie::Jar object provided does not have a method \"do\"." ) ) if( !$jar->can( 'do' ) );
    $opts->{overwrite} //= 0;
    $opts->{host} //= $self->host || '';
    $opts->{die} //= 0;
    my $n = 0;
    my $error;
    $jar->do(sub
    {
        # Skip the rest if we already found an error
        return if( defined( $error ) );
        my $c = shift( @_ );
        if( $self->_is_object( $c ) )
        {
            if( $self->_is_a( $c, 'Cookie' ) )
            {
                if( $opts->{overwrite} )
                {
                    $self->replace( $c );
                }
                else
                {
                    $self->add( $c );
                }
                $n++;
            }
            elsif( $c->can( 'name' ) && 
                   $c->can( 'value' ) && 
                   $c->can( 'domain' ) &&
                   $c->can( 'path' ) && 
                   $c->can( 'expires' ) && 
                   $c->can( 'max_age' ) && 
                   $c->can( 'port' ) && 
                   $c->can( 'secure' ) && 
                   $c->can( 'same_site' ) && 
                   $c->can( 'http_only' ) )
            {
                my $new = $jar->make(
                    name => $c->name,
                    value => $c->value,
                    domain => $c->domain,
                    path => $c->path,
                    expires => $c->expires,
                    max_age => $c->max_age,
                    http_only => $c->http_only,
                    same_site => $c->same_site,
                    secure => $c->secure,
                );
                if( !defined( $new ) )
                {
                    $error = $jar->error;
                    die( $error ) if( $opts->{die} );
                }
                else
                {
                    if( $opts->{overwrite} )
                    {
                        $self->replace( $new );
                    }
                    else
                    {
                        $self->add( $new );
                    }
                    $n++;
                }
            }
            else
            {
                $error = "Cookie object received (" . overload::StrVal( $c ) . ") is not a Cookie object and does not support the methods name, value, domain, path, port, expires, max_age, secure, same_site and http_only";
                die( $error ) if( $opts->{die} );
            }
        }
    });
    return( $self->error( $error ) ) if( defined( $error ) );
    $self->message( 3, "Added $n cookies from the repository to ours." ) if( $COOKIES_DEBUG );
    return( $self );
}

# Swell:
# "if the Cookie header field contains two cookies with the same name (e.g., that were set with different Path or Domain attributes), servers SHOULD NOT rely upon the order in which these cookies appear in the header field."
# <https://datatracker.ietf.org/doc/html/rfc6265#section-4.2.2>
sub parse
{
    my $self = shift( @_ );
    my $raw  = shift( @_ );
    my $ref = $self->new_array;
    return( $ref ) unless( defined( $raw ) && length( $raw ) );
    my @pairs = grep( /=/, split( /; ?/, $raw ) );
    foreach my $pair ( @pairs )
    {
        # Remove leading and trailing whitespaces
        $pair =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
        my( $k, $v ) = split( '=', $pair, 2 );
        $k = URI::Escape::uri_unescape( $k );
        $v = '' unless( defined( $v ) );
        $v =~ s/\A"(.*)"\z/$1/;
        $v = URI::Escape::uri_unescape( $v );
        $ref->push( { name => $k, value => $v } );
    }
    return( $ref );
}

sub purge
{
    my $self = shift( @_ );
    my $ref  = $self->_cookies;
    my $removed = $self->new_array;
    for( my $i = 0; $i < scalar( @$ref ); $i++ )
    {
        my $c = $ref->[$i];
        if( $c->is_expired )
        {
            $self->delete( $c ) || return( $self->pass_error );
            $removed->push( $c );
        }
    }
    return( $removed );
}

sub repo { return( shift->_set_get_array_as_object( '_cookies', @_ ) ); }

sub replace
{
    my $self = shift( @_ );
    my( $c, $old ) = @_;
    my $idx = $self->_index;
    my $ref = $self->_cookies;
    return( $self->error( "No cookie object was provided." ) ) if( !defined( $c ) );
    return( $self->error( "Cookie object provided is not a Cookie object." ) ) if( !$self->_is_a( $c, 'Cookie' ) );
    my $replaced = $self->new_array;
    if( defined( $old ) )
    {
        return( $self->error( "Old cookie object to be replaced is not a Cookie object." ) ) if( !$self->_is_a( $old, 'Cookie' ) );
        if( $c->name ne $old->name ||
            $c->domain ne $old->domain ||
            $c->path ne $old->path )
        {
            return( $self->error( "New cookie name '", $c->name, "' with host '", $c->domain, "' and path '", $c->path, "' does not match old cookie name '", $old->name, "' with host '", $old->host, "' and path '", $old->path, "'" ) );
        }
        my $key = $self->key( $old ) || return( $self->pass_error );
        my $addr = Scalar::Util::refaddr( $old );
        if( CORE::exists( $idx->{ $key } ) )
        {
            for( my $i = 0; $i < scalar( @{$idx->{ $key }} ); $i++ )
            {
                if( Scalar::Util::refaddr( $idx->{ $key }->[$i] ) eq $addr )
                {
                    $idx->{ $key }->[$i] = $c;
                    last;
                }
            }
        }
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            if( Scalar::Util::refaddr( $ref->[$i] ) eq $addr )
            {
                $replaced->push( $ref->[$i] );
                $ref->[$i] = $c;
                last;
            }
        }
    }
    else
    {
        my $key = $self->key( $c ) || return( $self->pass_error );
        $replaced->push( CORE::exists( $idx->{ $key } ) ? @{$idx->{ $key }} : () );
        foreach my $old ( @$replaced )
        {
            my $addr = Scalar::Util::refaddr( $old );
            for( my $j = 0; $j < scalar( @$ref ); $j++ )
            {
                if( Scalar::Util::refaddr( $ref->[$j] ) eq $addr )
                {
                    CORE::splice( @$ref, $i, 1 );
                    $i--;
                    last;
                }
            }
        }
        $idx->{ $key } = [ $c ];
    }
    return( $replaced );
}

sub request { return( shift->_set_get_object_without_init( 'request', 'Apache2::RequestRec', @_ ) ); }

sub save
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No filename was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{encrypt} //= 0;
    $opts->{secret} //= '';
    $opts->{algo} //= '';
    # Initialisation Vector for encryption
    # Re-use it if it was previously set
    $opts->{iv} //= $self->_initialisation_vector->scalar || '';
    $opts->{format} //= '';
    return( $self->save_as_lwp( $opts ) ) if( $opts->{format} eq 'lwp' );
    my $all = [];
    my $ref = $self->_cookies;
    foreach my $c ( @$ref )
    {
        push( @$all, $c->as_hash );
    }
    my $today = DateTime->now( time_zone => 'local' );
    my $dt_fmt = DateTime::Format::Strptime->new(
        pattern => '%FT%T%z',
        locale => 'en_GB',
        time_zone => 'local',
    );
    $today->set_formatter( $dt_fmt );
    my $data = { cookies => $all, updated_on => "$today" };
    
    my $f = file( $file );
    my $j = JSON->new->allow_nonref->pretty->canonical->convert_blessed;
    my $json;
    try
    {
        $json = $j->encode( $data );
    }
    catch( $e )
    {
        return( $self->error( "Unable to encode data to json: $e" ) );
    }

    $f->open( '>', { binmode => ( $opts->{encrypt} ? 'raw' : 'utf8' ) }) ||
        return( $self->pass_error( $f->error ) );
    if( $opts->{encrypt} )
    {
        $self->_load_class( 'Crypt::Misc' ) || return( $self->pass_error );
        my $p = $self->_encrypt_objects( @$opts{qw( key algo iv )} ) || return( $self->pass_error );
        my $crypt = $p->{crypt};
        # $value = Crypt::Misc::encode_b64( $crypt->encrypt( "$value", $p->{key}, $p->{iv} ) );
        $self->message( 4, "Key size '", CORE::length( $p->{key} ), " and IV size '", CORE::length( $p->{iv} ), "'." ) if( $COOKIES_DEBUG );
        my $encrypted = $crypt->encrypt( "$json", @$p{qw( key iv )} );
        $self->message( 4, "Encrypted data is now '$encrypted'" ) if( $COOKIES_DEBUG );
        my $b64 = Crypt::Misc::encode_b64( $encrypted );
        $f->unload( $b64 );
    }
    else
    {
        $f->unload( $json );
    }
    $f->close;
    return( $self );
}

sub save_as_lwp
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No filename was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{encrypt} //= 0;
    $opts->{secret} //= '';
    $opts->{algo} //= '';
    # Initialisation Vector for encryption
    # Re-use it if it was previously set
    $opts->{iv} //= $self->_initialisation_vector->scalar || '';
    $opts->{skip_discard} //= 0;
    $opts->{skip_expired} //= 0;
    return( $self->error( "No file to write cookies was specified." ) ) if( !$file );
    my $f = file( $file );
    
    my $raw = '';
    my $p = {};
    if( $opts->{encrypt} )
    {
        $self->_load_class( 'Crypt::Misc' ) || return( $self->pass_error );
        $p = $self->_encrypt_objects( @$opts{qw( key algo iv )} ) || return( $self->pass_error );
        $self->message( 4, "Key size '", CORE::length( $p->{key} ), " and IV size '", CORE::length( $p->{iv} ), "'." ) if( $COOKIES_DEBUG );
    }
    
    my $io = $f->open( '>', { binmode => ( $opts->{encrypt} ? 'raw' : 'utf-8' ) }) || 
        return( $self->error( "Unable to write cookies to file \"$file\": ", $f->error ) );
    if( $opts->{encrypt} )
    {
        $raw = "#LWP-Cookies-1.0\n";
    }
    else
    {
        $io->print( "#LWP-Cookies-1.0\n" ) || return( $self->error( "Unable to write to cookie file \"$file\": $!" ) );
    }
    my $now = DateTime->now;
    $self->scan(sub
    {
        my $c = shift( @_ );
        return(1) if( $c->discard && $opts->{skip_discard} );
        return(1) if( $c->expires && $c->expires < $now && $opts->{skip_expired} );
        my $vals = $c->as_hash;
        $vals->{path_spec} = 1 if( length( $vals->{path} ) );
        # In HTTP::Cookies logic, version 1 is rfc2109, version 2 is rfc6265
        $vals->{version} = 2;
        my $hv = Module::Generic::HeaderValue->new( [CORE::delete( @$vals{qw( name value )} )] );
        $hv->param( path => sprintf( '"%s"', $vals->{path} ) );
        $hv->param( domain => $vals->{domain} );
        $hv->param( port => $vals->{port} ) if( defined( $vals->{port} ) && length( $vals->{port} ) );
        $hv->param( path_spec => undef() ) if( defined( $vals->{path_spec} ) && $vals->{path_spec} );
        $hv->param( secure => undef() ) if( defined( $vals->{secure} ) && $vals->{secure} );
        $hv->param( expires => sprintf( '"%s"', "$vals->{expires}" ) ) if( defined( $vals->{secure} ) && $vals->{expires} );
        $hv->param( discard => undef() ) if( defined( $vals->{discard} ) && $vals->{discard} );
        if( defined( $vals->{comment} ) && length( $vals->{comment} ) )
        {
            $vals->{comment} =~ s/(?<!\\)\"/\\\"/g;
            $hv->param( comment => sprintf( '"%s"', $vals->{comment} ) );
        }
        $hv->param( commentURL => $vals->{commentURL} ) if( defined( $vals->{commentURL} ) && length( $vals->{commentURL} ) );
        $hv->param( version => $vals->{version} );
        if( $opts->{encrypt} )
        {
            $raw .= 'Set-Cookie3: ' . $hv->as_string . "\n";
        }
        else
        {
            $io->print( 'Set-Cookie3: ', $hv->as_string, "\n" ) || return( $self->error( "Unable to write to cookie file \"$file\": $!" ) );
        }
    });
    if( $opts->{encrypt} )
    {
        my $crypt = $p->{crypt};
        my $encrypted = $crypt->encrypt( "$raw", @$p{qw( key iv )} );
        $self->message( 4, "Encrypted data is now '$encrypted'" ) if( $COOKIES_DEBUG );
        my $b64 = Crypt::Misc::encode_b64( $encrypted );
        $io->print( $b64 );
    }
    $io->close;
    return( $self );
}

sub save_as_netscape
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{file} //= '';
    $opts->{skip_discard} //= 0;
    $opts->{skip_expired} //= 0;
    return( $self->error( "No file to write cookies was specified." ) ) if( !$opts->{file} );
    my $f = file( $opts->{file} );
    my $io = $f->open( '>', { binmode => 'utf-8' }) || 
        return( $self->error( "Unable to write cookies to file \"$opts->{file}\": ", $f->error ) );
    $io->print( "# Netscape HTTP Cookie File:\n" );
    my $now = DateTime->now;
    $self->scan(sub
    {
        my $c = shift( @_ );
        return(1) if( $c->discard && $opts->{skip_discard} );
        return(1) if( $c->expires && $c->expires < $now && $opts->{skip_expired} );
        my @temp = ( $c->domain );
        push( @temp, $c->domain->substr( 1, 1 ) eq '.' ? 'TRUE' : 'FALSE' );
        push( @temp, $c->path );
        push( @temp, $c->secure ? 'TRUE' : 'FALSE' );
        push( @temp, $c->expires );
        push( @temp, $c->name );
        push( @temp, $c->value );
        $io->print( join( "\t", @temp ), "\n" );
    });
    $io->close;
    return( $self );
}

# For backward compatibility with HTTP::Cookies
sub scan { return( shift->do( @_ ) ); }

sub set
{
    my $self = shift( @_ );
    my $c    = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No cookie name was provided to set." ) ) if( !$c->name->length );
    return( $self->error( "Cookie value should be an object." ) ) if( !Scalar::Util::blessed( $c ) );
    return( $self->error( "Cookie object does not have any as_string method." ) ) if( !$c->can( 'as_string' ) );
    $opts->{response} //= '';
    my $r = $self->request;
    if( $r )
    {
        $r->err_headers_out->add( 'Set-Cookie', $c->as_string );
    }
    elsif( $opts->{response} && $self->_is_object( $opts->{response} ) && $opts->{response}->can( 'header' ) )
    {
        $opts->{response}->header( 'Set-Cookie' => $c->as_string );
    }
    else
    {
        return( "Set-Cookie: " . $c->as_string );
    }
    return( $self );
}

sub _cookies { return( shift->_set_get_array_as_object( '_cookies', @_ ) ); }

sub _encrypt_objects
{
    my $self = shift( @_ );
    my( $key, $algo, $iv ) = @_;
    return( $self->error( "Key provided is empty!" ) ) if( !defined( $key ) || !CORE::length( "$key" ) );
    return( $self->error( "No algorithm was provided to encrypt cookie value. You can choose any <NAME> for which there exists Crypt::Cipher::<NAME>" ) ) if( !defined( $algo ) || !CORE::length( "$algo" ) );
    try
    {
        $self->_load_class( 'Crypt::Mode::CBC' ) || return( $self->pass_error );
        $self->_load_class( 'Bytes::Random::Secure' ) || return( $self->pass_error );
        my $crypt = Crypt::Mode::CBC->new( "$algo" ) || return( $self->error( "Unable to create a Crypt::Mode::CBC object." ) );
        my $class = "Crypt::Cipher::${algo}";
        $self->_load_class( $class ) || return( $self->pass_error );
        my $key_len = $class->keysize;
        my $block_len = $class->blocksize;
        $self->message( 4, "Key size: $key_len and block size: $block_len and our key size is '", CORE::length( $key ), "'." ) if( $COOKIES_DEBUG );
        return( $self->error( "The size of the key provided (", CORE::length( $key ), ") does not match the minimum key size required for this algorithm \"$algo\" (${key_len})." ) ) if( CORE::length( $key ) < $key_len );
        # Generate an "IV", i.e. Initialisation Vector based on the required block size
        if( defined( $iv ) && CORE::length( "$iv" ) )
        {
            if( CORE::length( $iv ) != $block_len )
            {
                return( $self->error( "The Initialisation Vector provided for cookie encryption has a length (", CORE::length( $iv ), ") which does not match the algorithm ($algo) size requirement ($block_len). Please refer to the Cookie::Jar package documentation." ) );
            }
        }
        else
        {
            $iv = Bytes::Random::Secure::random_bytes( $block_len );
            # Save it for decryption
            $self->_initialisation_vector( $iv );
        }
        my $key_pack = pack( 'H' x $key_len, $key );
        my $iv_pack  = pack( 'H' x $block_len, $iv );
        $self->message( 4, "Returning key size '", CORE::length( $key_pack ), "' and IV size '", CORE::length( $iv_pack ), "'." ) if( $COOKIES_DEBUG );
        return({ 'crypt' => $crypt, key => $key_pack, iv => $iv_pack });
    }
    catch( $e )
    {
        return( $self->error( "Error getting the encryption objects for algorithm \"$algo\": $e" ) );
    }
}

sub _index { return( shift->_set_get_hash_as_mix_object( '_index', @_ ) ); }

# For cookies file encryption
sub _initialisation_vector { return( shift->_set_get_scalar_as_object( '_initialisation_vector', @_ ) ); }

sub _normalize_path  # so that plain string compare can be used
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    my $x;
    $str =~ s{
        %([0-9a-fA-F][0-9a-fA-F])
    }
    {
        $x = uc( $1 );
        $x eq '2F' || $x eq '25' ? "%$x" : pack( 'C', hex( $x ) );
    }egx;
    $str =~ s/([\0-\x20\x7f-\xff])/sprintf( '%%%02X', ord( $1 ) )/eg;
    return( $str );
}

1;

# XXX POD
__END__

=encoding utf8

=head1 NAME

Cookie::Jar - Cookies API for Server & Client

=head1 SYNOPSIS

    use Cookie::Jar;
    my $jar = Cookie::Jar->new( request => $r ) ||
    return( $self->error( "An error occurred while trying to get the cookie jar." ) );
    # set the default host
    $jar->host( 'www.example.com' );
    $jar->fetch;
    # or using a HTTP::Request object
    # Retrieve cookies from Cookie header sent from client
    $jar->fetch( request => $http_request );
    if( $jar->exists( 'my-cookie' ) )
    {
        # do something
    }
    # get the cookie
    my $sid = $jar->get( 'my-cookie' );
    # get all cookies
    my @all = $jar->get( 'my-cookie', 'example.com', '/' );
    # set a new Set-Cookie header
    $jar->set( 'my-cookie' => $cookie_object );
    # Remove cookie from jar
    $jar->delete( 'my-cookie' );
    # or using the object itself:
    $jar->delete( $cookie_object );

    # Create and add cookie to jar
    $jar->add(
        name => 'session',
        value => 'lang=en-GB',
        path => '/',
        secure => 1,
        same_site => 'Lax',
    ) || die( $jar->error );
    # or add an existing cookie
    $jar->add( $some_cookie_object );

    my $c = $jar->make({
        name => 'my-cookie',
        domain => 'example.com',
        value => 'sid1234567',
        path => '/',
        expires => '+10D',
        # or alternatively
        maxage => 864000
        # to make it exclusively accessible by regular http request and not ajax
        http_only => 1,
        # should it be used under ssl only?
        secure => 1,
    });

    # Add the Set-Cookie headers
    $jar->add_response_header;
    # Alternatively, using a HTTP::Response object or equivalent
    $jar->add_response_header( $http_response );
    $jar->delete( 'some_cookie' );
    $jar->do(sub
    {
        # cookie object is available as $_ or as first argument in @_
    });

    # For client side
    # Takes a HTTP::Response object or equivalent
    # Extract cookies from Set-Cookie headers received from server
    $jar->extract( $http_response );
    # get by domain; by default sort it
    my $all = $jar->get_by_domain( 'example.com' );
    # Reverse sort
    $all = $jar->get_by_domain( 'example.com', sort => 0 );

    # Save cookies repository as json
    $jar->save( '/some/where/mycookies.json' ) || die( $jar->error );
    # Load cookies into jar
    $jar->load( '/some/where/mycookies.json' ) || die( $jar->error );

    # Save encrypted
    $jar->save( '/some/where/mycookies.json',
    {
        encrypt => 1,
        key => $key,
        iv => $iv,
        algo => 'AES',
    }) || die( $jar->error );
    # Load cookies from encrypted file
    $jar->load( '/some/where/mycookies.json',
    {
        decrypt => 1,
        key => $key,
        iv  => $iv,
        algo => 'AES'
    }) || die( $jar->error );

    # Merge repository
    $jar->merge( $jar2 ) || die( $jar->error );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This is a module to handle L<cookies|Cookie>, according to the latest standard as set by L<rfc6265|https://datatracker.ietf.org/doc/html/rfc6265>, both by the http server and the client. Most modules out there are either antiquated, i.e. they do not support latest cookie L<rfc6265|https://datatracker.ietf.org/doc/html/rfc6265>, or they focus only on http client side.

For example, Apache2::Cookie does not work well in decoding cookies, and L<Cookie::Baker> C<Set-Cookie> timestamp format is wrong. They use Mon-09-Jan 2020 12:17:30 GMT where it should be, as per rfc 6265 Mon, 09 Jan 2020 12:17:30 GMT

Also L<APR::Request::Cookie> and L<Apache2::Cookie> which is a wrapper around L<APR::Request::Cookie> return a cookie object that returns the value of the cookie upon stringification instead of the full C<Set-Cookie> parameters. Clearly they designed it with a bias leaned toward collecting cookies from the browser.

This module supports modperl and uses a L<Apache2::RequestRec> if provided, or can use package objects that implement similar interface as L<HTTP::Request> and L<HTTP::Response>, or if none of those above are available or provided, this module returns its results as a string.

This module is also compatible with L<LWP::UserAgent>, so you can use like this:

    use LWP::UserAgent;
    use Cookie::Jar;
 
    my $ua = LWP::UserAgent->new(
        cookie_jar => Cookie::Jar->new
    );

This module does not die upon error, but instead returns C<undef> and sets an L<error|Module::Generic/error>, so you should always check the return value of a method.

=head1 METHODS

=head2 new

This initiates the package and takes the following parameters:

=over 4

=item I<request>

This is an optional parameter to provide a L<Apache2::RequestRec> object. When provided, it will be used in various methods to get or set cookies from or onto http headers.

    package MyApacheHandler;
    use Apache2::Request ();
    use Cookie::Jar;
    
    sub handler : method
    {
        my( $class, $r ) = @_;
        my $jar = Cookie::Jar->new( $r );
        # Load cookies;
        $jar->fetch;
        $r->log_error( "$class: Found ", $jar->repo->length, " cookies." );
        $jar->add(
            name => 'session',
            value => 'lang=en-GB',
            path => '/',
            secure => 1,
            same_site => 'Lax',
        );
        # Will use Apache2::RequestRec object to set the Set-Cookie headers
        $jar->add_response_header || do
        {
            $r->log_reason( "Unable to add Set-Cookie to response header: ", $jar->error );
            return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        };
        # Do some more computing
        return( Apache2::Const::OK );
    }

=item I<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=back

=head2 add

Provided with an hash or hash reference of cookie parameters (see L<Cookie>) and this will create a new L<cookie|Cookie> and add it to the cookie repository.

Alternatively, you can also provide directly an existing L<cookie object|Cookie>

    my $c = $jar->add( $cookie_object ) || die( $jar->error );

=head2 add_cookie_header

This is an alias for L</add_request_header> for backward compatibility with L<HTTP::Cookies>

=head2 add_request_header

Provided with a request object, such as, but not limited to L<HTTP::Request> and this will add all relevant cookies in the repository into the C<Cookie> http request header.

As long as the object provided supports the C<uri> and C<header> method, you can provide any class of object you want.

Please refer to the L<rfc6265|https://datatracker.ietf.org/doc/html/rfc6265> for more information on the applicable rule when adding cookies to the outgoing request header.

Basically, it will add, for a given domain, first all cookies whose path is longest and at path equivalent, the cookie creation date is used, with the earliest first. Cookies who have expired are not sent, and there can be cookies bearing the same name for the same domain in different paths.

=head2 add_response_header

    # Adding cookie to the repository
    $jar->add(
        name => 'session',
        value => 'lang=en-GB',
        path => '/',
        secure => 1,
        same_site => 'Lax',
    ) || die( $jar->error );
    # then placing it onto the response header
    $jar->add_response_header;

This is the alter ego to L</add_request_header>, in that it performs the equivalent function, but for the server side.

You can optionally provide, as unique argument, an object, such as but not limited to, L<HTTP::Response>, as long as that class supports the C<header> method

Alternatively, if an L<Apache object|Apache2::RequestRec> has been set upon object instantiation or later using the L</request> method, then it will be used to set the outgoing C<Set-Cookie> headers (there is one for every cookie sent).

If no response, nor Apache2 object were set, then this will simply return a list of C<Set-Cookie> in list context, or a string of possibly multiline C<Set-Cookie> headers, or an empty string if there is no cookie found to be sent.

Be careful not to do the following:

    # get cookies sent by the http client
    $jar->fetch || die( $jar->error );
    # set the response headers with the cookies from our repository
    $jar->add_response_header;

Why? Well, because L</fetch> retrieves the cookies sent by the http client and store them into the repository. However, cookies sent by the http client only contain the cookie name and value, such as:

    GET /my/path/ HTTP/1.1
    Host: www.example.org
    Cookie: session_token=eyJleHAiOjE2MzYwNzEwMzksImFsZyI6IkhTMjU2In0.eyJqdGkiOiJkMDg2Zjk0OS1mYWJmLTRiMzgtOTE1ZC1hMDJkNzM0Y2ZmNzAiLCJmaXJzdF9uYW1lIjoiSm9obiIsImlhdCI6MTYzNTk4NDYzOSwiYXpwIjoiNGQ0YWFiYWQtYmJiMy00ODgwLThlM2ItNTA0OWMwZTczNjBlIiwiaXNzIjoiaHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20iLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwibGFzdF9uYW1lIjoiRG9lIiwic3ViIjoiYXV0aHxlNzg5OTgyMi0wYzlkLTQyODctYjc4Ni02NTE3MjkyYTVlODIiLCJjbGllbnRfaWQiOiJiZTI3N2VkYi01MDgzLTRjMWEtYTM4MC03Y2ZhMTc5YzA2ZWQiLCJleHAiOjE2MzYwNzEwMzksImF1ZCI6IjRkNGFhYmFkLWJiYjMtNDg4MC04ZTNiLTUwNDljMGU3MzYwZSJ9.VSiSkGIh41xXIVKn9B6qGjfzcLlnJAZ9jGOPVgXASp0; csrf_token=9849724969dbcffd48c074b894c8fbda14610dc0ae62fac0f78b2aa091216e0b.1635825594; site_prefs=lang%3Den-GB

As you can see, 3 cookies were sent: C<session_token>, C<csrf_token> and C<site_prefs>

So, when L</fetch> creates an object for each one and store them, those cookies have no C<path> value and no other attribute, and when L</add_response_header> is then called, it stringifies the cookies and create a C<Set-Cookie> header for each one, but only with their value and no other attribute.

The http client, when receiving those cookies will derive the  missing cookie path to be C</my/path>, i.e. the current uri path, and will override the previously stored cookie with the same name for that host that had the path set to C</>

So you can create a repository and use it to store the cookies sent by the http client using L</fetch>, but in preparation of the server response, either use a separate repository with, for example, C<my $jar_out = Cookie::Jar->new> or use L</set> which will still add the cookie to the repository, but also before set the C<Set-Cookie> header for that cookie.

    # Add Set-Cookie header for that cookie and add cookie to repository
    $jar->set( $cookie_object );

=head2 delete

Given a cookie name, an optional host and optional path or a L<Cookie> object, and this will remove it from the cookie repository.

It returns an L<array object|Module::Generic::Array> upon success, or L<perlfunc/undef> and sets an L<error|Module::Generic/error>. Note that the array object may be empty.

However, this will NOT remove it from the web browser by sending a Set-Cookie header. For that, you might want to look at the L<Cookie/elapse> method.

It returns an L<array object|Module::Generic::Array> of cookie objects removed.

    my $arr = $jar->delete( 'my-cookie' );
    # alternatively
    my $arr = $jar->delete( 'my-cookie' => 'www.example.org' );
    # or
    my $arr = $jar->delete( $my_cookie_object );
    printf( "%d cookie(s) removed.\n", $arr->length );
    print( "Cookie value removed was: ", $arr->first->value, "\n" );

If you are interested in telling the http client to remove all your cookies, you can set the C<Clear-Site-Data> header:

    Clear-Site-Data: "cookies"

You can instruct the http client to remove other data like local storage:

    Clear-Site-Data: "cookies", "cache", "storage", "executionContexts"

Although this is widely supported, there is no guarantee the http client will actually comply with this request.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data> for more information.

=head2 do

Provided with an anonymous code or reference to a subroutine, and this will call that code for every cookie in the repository, passing it the cookie object as the sole argument. Also, that cookie object is accessible using C<$_>.

If the code return C<undef>, it will end the loop, and it the code returns true, this will have the current cookie object added to an L<array object|Module::Generic::Array> returned upon completion of the loop.

    my $found = $jar->do(sub
    {
        # Part of the path
        if( index( $path, $_->path ) == 0 )
        {
            return(1);
        }
        return(0);
    });
    print( "Found cookies: ", $found->map(sub{$_->name})->join( ',' ), "\n" );

=head2 exists

Given a cookie name, this will check if it exists.

It returns 1 if it does, or 0 if it does not.

=head2 extract

Provided with a response object, such as, but not limited to L<HTTP::Response>, and this will retrieve any cookie sent from the remote server, parse them and add their respective to the repository.

As per the L<rfc6265, section 5.3.11 specifications|https://datatracker.ietf.org/doc/html/rfc6265#section-5.3> if there are duplicate cookies for the same domain and path, only the last one will be retained.

If the cookie received does not contain any C<Domain> specification, then, in line with rfc6265 specifications, it will take the root of the current domain as the default domain value. Since finding out what is the root for a domain name is a non-trivial exercise, this method relies on L<Cookie::Domain>.

=head2 extract_cookies

This is an alias for L</extract> for backward compatibility with L<HTTP::Cookies>

=head2 fetch

This method does the equivalent of L</extract>, but for the server.

It retrieves all possible cookies from the http request received from the web browser.

It takes an optional hash or hash reference of parameters, such as C<host>. If it is not provided, the value set with L</host> is used instead.

If the parameter C<request> containing an http request object, such as, but not limited to L<HTTP::Request>, is provided, it will use it to get the C<Cookie> header value.

Alternatively, if a value for L</request> has been set, it will use it to get the C<Cookie> header value from Apache modperl.

You can also provide the C<Cookie> string to parse by providing the C<string> option to this method.

    $jar->fetch( string => q{foo=bar; site_prefs=lang%3Den-GB} ) ||
        die( $jar->error );

Ultimately, if none of those are available, it will use the environment variable C<HTTP_COOKIE>

In void context, this method, will add the fetched cookies to its L<repository|/repo>.

It returns an hash reference of cookie key => L<cookie object|Cookie>

A cookie key is made of the host (possibly empty) and the cookie name separated by C<;>

    # Cookies added to the repository
    $jar->fetch || die( $jar->error );
    # Cookies returned, but NOT added to the repository
    my $cookies = $jar->fetch || die( $jar->error );

=head2 get

Given a cookie name, an optional host and an optional path, this will retrieve its value and return it.

If not found, it will try to return a value with just the cookie name.

If nothing is found, this will return and empty list in list context or C<undef> in scalar context.

You can C<get> multiple cookies and this method will return a list in list context and the first cookie found in scalar context.

    # Wrong, an undefined returned value here only means there is no such cookie
    my $c = $jar->get( 'my-cookie' );
    die( $jar->error ) if( !defined( $c ) );
    # Correct
    my $c = $jar->get( 'my-cookie' ) || die( "No cookie my-cookie found\n" );
    # Possibly get multiple cookie object for the same name
    my @cookies = $jar->get( 'my_same_name' ) || die( "No cookies my_same_name found\n" );
    # or
    my @cookies = $jar->get( 'my_same_name' => 'www.example.org', '/private' ) || die( "No cookies my_same_name found\n" );

=head2 get_by_domain

Provided with a host and an optional hash or hash reference of parameters, and this returns an L<array object|Module::Generic::Array> of L<cookie objects|Cookie> matching the domain specified.

If a C<sort> parameter has been provided and its value is true, this will sort the cookies by path alphabetically. If the sort value exists, but is false, this will sort the cookies by path but in a reverse alphabetical order.

By default, the cookies are sorted.

=head2 host

Sets or gets the default host. This is especially useful for cookies repository used on the server side.

=head2 key

Provided with a cookie name and an optional host and this returns a key used to add an entry in the hash repository.

If no host is provided, the key is just the cookie, otherwise the resulting key is the cookie name and host separated just by C<;>

You should not need to use this method as it is used internally only.

=head2 load

    $jar->load( '/home/joe/cookies.json' ) || die( $jar->error );

    # or loading cookies from encrypted file
    $jar->load( '/home/joe/cookies_encrypted.json',
    {
        decrypt => 1,
        key => $key,
        iv  => $iv,
        algo => 'AES'
    }) || die( $jar->error );

Give a json cookie file, and an hash or hash reference of options, and this will load its data into the repository. If there are duplicates (same cookie name and host), the latest one added takes precedence, as per the rfc6265 specifications.

Supported options are:

=over 4

=item I<algo> string

Algorithm to use to decrypt the cookie file.

It can be any of L<AES|Crypt::Cipher::AES>, L<Anubis|Crypt::Cipher::Anubis>, L<Blowfish|Crypt::Cipher::Blowfish>, L<CAST5|Crypt::Cipher::CAST5>, L<Camellia|Crypt::Cipher::Camellia>, L<DES|Crypt::Cipher::DES>, L<DES_EDE|Crypt::Cipher::DES_EDE>, L<KASUMI|Crypt::Cipher::KASUMI>, L<Khazad|Crypt::Cipher::Khazad>, L<MULTI2|Crypt::Cipher::MULTI2>, L<Noekeon|Crypt::Cipher::Noekeon>, L<RC2|Crypt::Cipher::RC2>, L<RC5|Crypt::Cipher::RC5>, L<RC6|Crypt::Cipher::RC6>, L<SAFERP|Crypt::Cipher::SAFERP>, L<SAFER_K128|Crypt::Cipher::SAFER_K128>, L<SAFER_K64|Crypt::Cipher::SAFER_K64>, L<SAFER_SK128|Crypt::Cipher::SAFER_SK128>, L<SAFER_SK64|Crypt::Cipher::SAFER_SK64>, L<SEED|Crypt::Cipher::SEED>, L<Skipjack|Crypt::Cipher::Skipjack>, L<Twofish|Crypt::Cipher::Twofish>, L<XTEA|Crypt::Cipher::XTEA>, L<IDEA|Crypt::Cipher::IDEA>, L<Serpent|Crypt::Cipher::Serpent> or simply any <NAME> for which there exists Crypt::Cipher::<NAME>

=item I<decrypt> boolean

Must be set to true to enable decryption.

=item I<iv> string

Set the L<Initialisation Vector|https://en.wikipedia.org/wiki/Initialization_vector> used for file encryption and decryption. This must be the same value used for encryption. See L</save>

=item I<key> string

Set the encryption key used to decrypt the cookies file.

The key must be the same one used to encrypt the file. See L</save>

=back

L</load> returns the current object upon success and C<undef> and sets an L<error|Module::Generic/error> upon error.

=head2 load_as_lwp

    $jar->load_as_lwp( '/home/joe/cookies_lwp.txt' ) ||
        die( "Unable to load cookies from file: ", $jar->error );

    # or loading an encrypted file
    $jar->load_as_lwp( '/home/joe/cookies_encrypted_lwp.txt',
    {
        encrypt => 1,
        key => $key,
        iv => $iv,
        algo => 'AES',
    }) || die( $jar->error );

Given a file path to an LWP-style cookie file (see below a snapshot of what it looks like), and an hash or hash reference of options, and this method will read the cookies from the file and add them to our repository, possibly overwriting previous cookies with the same name and domain name.

The supported options are the same as for L</load>

LWP-style cookie files are ancient, and barely used anymore, but no matter; if you need to load cookies from such file, it looks like this:

    #LWP-Cookies-1.0
    Set-Cookie3: cookie1=value1; domain=example.com; path=; path_spec; secure; version=2
    Set-Cookie3: cookie2=value2; domain=api.example.com; path=; path_spec; secure; version=2
    Set-Cookie3: cookie3=value3; domain=img.example.com; path=; path_spec; secure; version=2

It returns the current object upon success, or C<undef> and sets an L<error|Module::Generic/error> upon error.

=head2 load_as_netscape

    $jar->save_as_netscape( '/home/joe/cookies_netscape.txt' ) ||
        die( "Unable to save cookies file: ", $jar->error );

    # or saving as an encrypted file
    $jar->save_as_netscape( '/home/joe/cookies_encrypted_netscape.txt',
    {
        encrypt => 1,
        key => $key,
        iv => $iv,
        algo => 'AES',
    }) || die( $jar->error );

Given a file path to a Netscape-style cookie file, and this method will read cookies from the file and add them to our repository, possibly overwriting previous cookies with the same name and domain name.

It returns the current object upon success, or C<undef> and sets an L<error|Module::Generic/error> upon error.

=head2 make

Provided with some parameters and this will instantiate a new L<Cookie> object with those parameters and return the new object.

This does not add the newly created cookie object to the cookies repository.

For a list of supported parameters, refer to the L<Cookie documentation|Cookie>

    # Make an encrypted cookie
    use Bytes::Random::Secure ();
    my $c = $jar->make(
        name      => 'session',
        value     => $secret_value,
        path      => '/',
        secure    => 1,
        http_only => 1,
        same_site => 'Lax',
        key       => Bytes::Random::Secure::random_bytes(32),
        algo      => $algo,
        encrypt   => 1,
    ) || die( $jar->error );
    # or as an hash reference of parameters
    my $c = $jar->make({
        name      => 'session',
        value     => $secret_value,
        path      => '/',
        secure    => 1,
        http_only => 1,
        same_site => 'Lax',
        key       => Bytes::Random::Secure::random_bytes(32),
        algo      => $algo,
        encrypt   => 1,
    }) || die( $jar->error );

=head2 merge

Provided with another L<Cookie::Jar> object, or at least an object that supports the L</do> method, which takes an anonymous code as argument, and that calls that code passing it each cookie object found in the alternate repository, and this method will add all those cookies in the alternate repository into the current repository.

    $jar->merge( $other_jar ) || die( $jar->error );

If the cookie objects passed to the anonymous code in this method, are not L<Cookie> object, then at least they must support the methods C<name>, C<value>, C<domain>, C<path>, C<port>, C<secure>, C<max_age>, C<secure>, C<same_site> and , C<http_only>

This method also takes an hash or hash reference of options:

=over 4

=item I<die> boolean

If true, the anonymous code passed to the C<do> method called, will die upon error. Default to false.

By default, if an error occurs, C<undef> is returned and the L<error|Module::Generic/error> is set.

=item I<overwrite> boolean

If true, when an existing cookie is found it will be overwritten by the new one. Default to false.

=back

    use Nice::Try;
    try
    {
        $jar->merge( $other_jar, die => 1, overwrite => 1 );
    }
    catch( $e )
    {
        die( "Failed to merge cookies repository: $e\n" );
    }

Upon success this will return the current object, and if there was an error, this returns L<perlfunc/undef> and sets an L<error|Module::Generic/error>

=head2 parse

This method is used by L</fetch> to parse cookies sent by http client. Parsing is much simpler than for http client receiving cookies from server.

It takes the raw C<Cookie> string sent by the http client, and returns an hash reference (possibly empty) of cookie name to cookie value pairs.

    my $cookies = $jar->parse( 'foo=bar; site_prefs=lang%3Den-GB' );
    # You can safely do as well:
    my $cookies = $jar->parse( '' );

=head2 purge

Thise takes no argument and will remove from the repository all cookies that have expired. A cookie that has expired is a L<Cookie> that has its C<expires> property set and whose value is in the past.

This returns an L<array object|Module::Generic::Array> of all the cookies thus removed.

    my $all = $jar->purge;
    printf( "Cookie(s) removed were: %s\n", $all->map(sub{ $_->name })->join( ',' ) );
    # or
    printf( "%d cookie(s) removed from our repository.\n", $jar->purge->length );

=head2 replace

Provided with a L<Cookie> object, and an optional other L<Cookie> object, and this method will replace the former cookie provided in the second parameter with the new one provided in the first parameter.

If only one parameter is provided, the cookies to be replaced will be derived from the replacement cookie's properties, namely: C<name>, C<domain> and C<path>

It returns an L<array object|Module::Generic::Array> of cookie objects replaced upon success, or C<undef> and set an L<error|Module::Generic/error> upon error.

=head2 repo

Set or get the L<array object|Module::Generic::Array> used as the cookie jar repository.

    printf( "%d cookies found\n", $jar->repo->length );

=head2 request

Set or get the L<Apache2::RequestRec> object. This object is used to set the C<Set-Cookie> header within modperl.

=head2 save

    $jar->save( '/home/joe/cookies.json' ) || 
        die( "Failed to save cookies: ", $jar->error );

    # or saving the cookies file encrypted
    $jar->save( '/home/joe/cookies_encrypted.json',
    {
        encrypt => 1,
        key => $key,
        iv => $iv,
        algo => 'AES',
    }) || die( $jar->error );

Provided with a file, and an hash or hash reference of options, and this will save the repository of cookies as json data.

The hash saved to file contains 2 top properties: C<updated_on> containing the last update date and C<cookies> containing an hash of cookie name to cookie properties pairs.

It returns the current object. If an error occurred, it will return C<undef> and set an L<error|Module::Generic/error>

Supported options are:

=over 4

=item I<algo> string

Algorithm to use to encrypt the cookie file.

It can be any of L<AES|Crypt::Cipher::AES>, L<Anubis|Crypt::Cipher::Anubis>, L<Blowfish|Crypt::Cipher::Blowfish>, L<CAST5|Crypt::Cipher::CAST5>, L<Camellia|Crypt::Cipher::Camellia>, L<DES|Crypt::Cipher::DES>, L<DES_EDE|Crypt::Cipher::DES_EDE>, L<KASUMI|Crypt::Cipher::KASUMI>, L<Khazad|Crypt::Cipher::Khazad>, L<MULTI2|Crypt::Cipher::MULTI2>, L<Noekeon|Crypt::Cipher::Noekeon>, L<RC2|Crypt::Cipher::RC2>, L<RC5|Crypt::Cipher::RC5>, L<RC6|Crypt::Cipher::RC6>, L<SAFERP|Crypt::Cipher::SAFERP>, L<SAFER_K128|Crypt::Cipher::SAFER_K128>, L<SAFER_K64|Crypt::Cipher::SAFER_K64>, L<SAFER_SK128|Crypt::Cipher::SAFER_SK128>, L<SAFER_SK64|Crypt::Cipher::SAFER_SK64>, L<SEED|Crypt::Cipher::SEED>, L<Skipjack|Crypt::Cipher::Skipjack>, L<Twofish|Crypt::Cipher::Twofish>, L<XTEA|Crypt::Cipher::XTEA>, L<IDEA|Crypt::Cipher::IDEA>, L<Serpent|Crypt::Cipher::Serpent> or simply any <NAME> for which there exists Crypt::Cipher::<NAME>

=item I<encrypt> boolean

Must be set to true to enable decryption.

=item I<iv> string

Set the L<Initialisation Vector|https://en.wikipedia.org/wiki/Initialization_vector> used for file encryption. If you do not provide one, it will be automatically generated. If you want to provide your own, make sure the size meets the encryption algorithm size requirement. You also need to keep this to decrypt the cookies file.

To find the right size for the Initialisation Vector, for example for algorithm C<AES>, you could do:

    perl -MCrypt::Cipher::AES -lE 'say Crypt::Cipher::AES->blocksize'

which would yield C<16>

=item I<key> string

Set the encryption key used to encrypt the cookies file.

The key must be the same one used to decrypt the file and must have a size big enough to satisfy the encryption algorithm requirement, which you can check with, say for C<AES>:

    perl -MCrypt::Cipher::AES -lE 'say Crypt::Cipher::AES->keysize'

In this case, it will yield C<32>. Replace above C<AES>, byt whatever algorithm you have chosen.

    perl -MCrypt::Cipher::Blowfish -lE 'say Crypt::Cipher::Blowfish->keysize'

would yield C<56> for C<Blowfish>

You can use L<Bytes::Random::Secure/random_bytes> to generate a random key:

    # will generate a 32 bytes-long key
    my $key = Bytes::Random::Secure::random_bytes(32);

=back

When encrypting the cookies file, this method will encode the encrypted data in base64 before saving it to file.

=head2 save_as_lwp

    $jar->save_as_lwp( '/home/joe/cookies_lwp.txt' ) ||
        die( "Unable to save cookies file: ", $jar->error );

    # or saving as an encrypted file
    $jar->save_as_lwp( '/home/joe/cookies_encrypted_lwp.txt',
    {
        encrypt => 1,
        key => $key,
        iv => $iv,
        algo => 'AES',
    }) || die( $jar->error );

Provided with a file, and an hash or hash reference of options, and this save the cookies repository as a LWP-style data.

The supported options are the same as for L</save>

It returns the current object. If an error occurred, it will return C<undef> and set an L<error|Module::Generic/error>

=head2 save_as_netscape

Provided with a file and this save the cookies repository as a Netscape-style data.

It returns the current object. If an error occurred, it will return C<undef> and set an L<error|Module::Generic/error>

=head2 scan

This is an alias for L</do>

=head2 set

Given a cookie object, and an optional hash or hash reference of parameters, and this will add the cookie to the outgoing http headers using the C<Set-Cookie> http header. To do so, it uses the L<Apache2::RequestRec> value set in L</request>, if any, or a L<HTTP::Response> compatible response object provided with the C<response> parameter.

    $jar->set( $c, response => $http_response_object ) ||
        die( $jar->error );

Ultimately if none of those two are provided it returns the C<Set-Cookie> header as a string.

    # Returns something like:
    # Set-Cookie: my-cookie=somevalue
    print( STDOUT $jar->set( $c ), "\015\012" );

Unless the latter, this method returns the current object.

=head1 IMPORTING COOKIES

To import cookies, you can either use the methods L<scan|HTTP::Cookies/scan> from L<HTTP::Cookies>, such as:

    use Cookie::Jar;
    use HTTP::Cookies;
    my $jar = Cookie::Jar->new;
    my $old = HTTP::Cookies;
    $old->load( '/home/joe/old_cookies_file.txt' );
    my @keys = qw( version key val path domain port path_spec secure expires discard hash );
    $old->scan(sub
    {
        my @values = @_;
        my $ref = {};
        @$ref{ @keys } = @values;
        my $c = Cookie->new;
        $c->apply( $ref ) || die( $c->error );
        $jar->add( $c );
    });
    printf( "%d cookies now in our repository.\n", $jar->repo->length );

or you could also load a cookie file. L<Cookie::Jar> supports L<LWP> format and old Netscape format:

    $jar->load_as_lwp( '/home/joe/lwp_cookies.txt' );
    $jar->load_as_netscape( '/home/joe/netscape_cookies.txt' );

And of course, if you are using L<Cookie::Jar> json cookies file, you can import them with:

    $jar->load( '/home/joe/cookies.json' );

=head1 ENCRYPTION

This package supports encryption and decryption of cookies file, and also the cookies values themselve.

See methods L</save> and L</load> for encryption options and the L<Cookie> package for options to encrypt or sign cookies value.

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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::Cookies>, L<APR::Request::Cookie>, L<Cookie::Baker>

L<Latest tentative version of the cookie standard|https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-09>

L<Mozilla documentation on Set-Cookie|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>

L<Information on double submit cookies|https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#double-submit-cookie>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
