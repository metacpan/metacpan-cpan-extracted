package CookieTest;
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Apache2::Connection ();
    use Apache2::Const -compile => qw( :common :http OK DECLINED );
    use Apache2::RequestIO ();
    use Apache2::RequestRec ();
    # so we can get the request as a string
    use Apache2::RequestUtil ();
    use APR::URI ();
    use Cookie::Jar;
    # 2021-11-1T167:12:10+0900
    use Test::Time time => 1635754330;
    eval( "use Crypt::Cipher::AES" );
    use constant HAS_CRYPT => ( $@ ? 0 : 1 );
    eval( "use Bytes::Random::Secure" );
    use constant HAS_RAND_BYTES => ( $@ ? 0 : 1 );
    use constant HAS_SSL => ( $ENV{HTTPS} || ( defined( $ENV{SCRIPT_URI} ) && substr( lc( $ENV{SCRIPT_URI} ), 0, 5 ) eq 'https' ) ) ? 1 : 0;
    # For AES encryption, the requirements are key of minimum 32 bytes and IV of 16 bytes
    our $CRYPT_KEY = '501213571d199667011fc6b37a9651bf';
    our $CRYPT_IV  = 'ee60150eca7743a9';
};

sub handler : method
{
    my( $class, $r ) = @_;
    my $debug = $r->dir_config( 'COOKIES_DEBUG' );
    $r->log_error( "${class}: Received request for uri \"", $r->uri, "\" matching file \"", $r->filename, "\": ", $r->as_string );
    my $uri = APR::URI->parse( $r->pool, $r->uri );
    my $path = [split( '/', $uri->path )]->[-1];
    my $jar = Cookie::Jar->new( $r, debug => $debug ) || do
    {
        $r->log_error( "$class: Error instantiating Cookie::Jar object: ", Cookie::Jar->error );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    };
    $jar->fetch || do
    {
        $r->log_error( "$class: Error fetching cookies from http request: ", $jar->error );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    };
    my $self = bless( { request => $r, jar => $jar, debug => int( $r->dir_config( 'COOKIES_DEBUG' ) ) } => $class );
    my $code = $self->can( $path );
    if( !defined( $code ) )
    {
        $r->log_error( "No method \"$path\" for testing." );
        return( Apache2::Const::DECLINED );
    }
    $r->err_headers_out->set( 'Test-No' => $path );
    $self->message( "Calling method \"$path\"." );
    my $rc = $code->( $self );
    $r->log_error( "$class: Returning http code '$rc' for method '$path'" );
    if( $rc == Apache2::Const::HTTP_OK )
    {
        # https://perl.apache.org/docs/2.0/user/handlers/intro.html#item_RUN_FIRST
        # return( Apache2::Const::DONE );
        return( Apache2::Const::OK );
    }
    else
    {
        return( $rc );
    }
    # $r->connection->client_socket->close();
    exit(0);
}

sub error
{
    my $self = shift( @_ );
    my $r = $self->request;
    $r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    my $ref = [@_];
    my $error = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : ( $_ // '' ), @$ref ) );
    warn( $error );
    $r->log_error( $error );
    $r->print( $error );
    $r->rflush;
    return;
}

sub failure { return( shift->reply( Apache2::Const::HTTP_EXPECTATION_FAILED => 'failed' ) ); }

sub is
{
    my $self = shift( @_ );
    my( $what, $expect ) = @_;
    return( $self->success ) if( $what eq $expect );
    return( $self->reply( Apache2::Const::HTTP_EXPECTATION_FAILED => "failed\nI was expecting \"$expect\", but got \"$what\"." ) );
}

sub jar { return( shift->{jar} ); }

sub message
{
    my $self = shift( @_ );
    return unless( $self->{debug} );
    my $class = ref( $self );
    my $r = $self->request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $ref = [@_];
    my $sub = (caller(1))[3] // '';
    my $line = (caller())[2] // '';
    $sub = substr( $sub, rindex( $sub, ':' ) + 1 );
    $r->log_error( "${class} -> $sub [$line]: ", join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : ( $_ // '' ), @$ref ) ) );
    return( $self );
}

sub ok
{
    my $self = shift( @_ );
    my $cond = shift( @_ );
    $self->message( "Is ok? ", $cond ? 'yes' : 'no' );
    return( $cond ? $self->success : $self->failure );
}

sub reply
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    my $r = $self->request;
    $r->content_type( 'text/plain' );
    $r->status( $code );
    $r->rflush;
    $r->print( @_ );
    return( $code );
}

sub request { return( shift->{request} ); }

sub success { return( shift->reply( Apache2::Const::HTTP_OK => 'ok' ) ); }
# From 01 to 19 those are the Apache2::SSI::URI test units
sub test01
{
    my $self = shift( @_ );
    my $token = q{eyJleHAiOjE2MzYwNzEwMzksImFsZyI6IkhTMjU2In0.eyJqdGkiOiJkMDg2Zjk0OS1mYWJmLTRiMzgtOTE1ZC1hMDJkNzM0Y2ZmNzAiLCJmaXJzdF9uYW1lIjoiSm9obiIsImlhdCI6MTYzNTk4NDYzOSwiYXpwIjoiNGQ0YWFiYWQtYmJiMy00ODgwLThlM2ItNTA0OWMwZTczNjBlIiwiaXNzIjoiaHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20iLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwibGFzdF9uYW1lIjoiRG9lIiwic3ViIjoiYXV0aHxlNzg5OTgyMi0wYzlkLTQyODctYjc4Ni02NTE3MjkyYTVlODIiLCJjbGllbnRfaWQiOiJiZTI3N2VkYi01MDgzLTRjMWEtYTM4MC03Y2ZhMTc5YzA2ZWQiLCJleHAiOjE2MzYwNzEwMzksImF1ZCI6IjRkNGFhYmFkLWJiYjMtNDg4MC04ZTNiLTUwNDljMGU3MzYwZSJ9.VSiSkGIh41xXIVKn9B6qGjfzcLlnJAZ9jGOPVgXASp0};
    my $rv;
    my $jar = $self->jar;
    my $r = $self->request;
    my $c = $jar->make( name => 'session_token' => value => $token, path => '/', expires => "Monday, 01-Nov-2021 17:12:40 GMT" ) ||
    do
    {
        $self->message( "Unable to create cookie session_token: ", $jar->error );
        return( $self->ok(0) );
    };
    
    defined( $rv = $jar->set( $c ) ) || do
    {
        $self->message( "setting cookie header for cookie 'session_token' returned an error: ", $jar->error );
        return( $self->ok(0) );
    };
    my @set_values = $r->err_headers_out->get( 'Set-Cookie' );
    # $self->message( "Set-Cookie headers set are: ", sub{ join( "\n", @set_values ) } );
    $self->message( "test01 is ok? ", "@set_values" =~ /(^|\b)session_token=$token/ ? 'yes' : 'no' );
    # Need to set the call context for the regexp to scalar (boolean) so that the 'ok' method received the right value
    # Otherwise, the regexp would return nothing in list context and would render the test false even if it were true.
    return( $self->ok( "@set_values" =~ /(^|\b)session_token=$token/ ? 1 : 0 ) );
}

sub test02
{
    my $self = shift( @_ );
    my $rv;
    my $jar = $self->jar;
    my $r = $self->request;
    # For double authentication cookie scheme for example
    # See: <https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#double-submit-cookie>
    my $csrf = q{9849724969dbcffd48c074b894c8fbda14610dc0ae62fac0f78b2aa091216e0b.1635825594};
    my $c = $jar->make( name => 'csrf_token', value => $csrf, path => '/' ) || do
    {
        $self->message( "Unable to create csrf cookie: ", $jar->error );
        return( $self->ok(0) );
    };
    # $resp->header( 'Set-Cookie' => qq{csrf_token=${csrf}; path=/} );
    defined( $rv = $jar->set( $c ) ) || do
    {
        $self->message( "set cookie headr for cookie 'csrf_token' returned an error: ", $jar->error );
        return( $self->ok(0) );
    };
    my @set_values = $r->err_headers_out->get( 'Set-Cookie' );
    return( $self->ok( "@set_values" =~ /(^|\b)csrf_token=$csrf/ ? 1 : 0 ) );
}

sub test03
{
    my $self = shift( @_ );
    my $jar = $self->jar;
    return( $self->ok( $jar->exists( 'session_token' ) && $jar->exists( 'csrf_token' ) ) );
}

sub test04
{
    my $self = shift( @_ );
    my $rv;
    my $jar = $self->jar;
    my $r = $self->request;
    my $c = $jar->make( name => 'site_prefs', value => "lang=en-GB", path => '/account' ) || do
    {
        $self->message( "Unable to create cookie site_prefs: ", $jar->error );
        return( $self->ok(0) );
    };
    defined( $rv = $jar->set( $c ) ) || do
    {
        $self->message( "set cookie header for cookie 'site_prefs' returned an error: ", $jar->error );
        return( $self->ok(0) );
    };
    my @set_values = $r->err_headers_out->get( 'Set-Cookie' );
    return( $self->ok( "@set_values" =~ /(^|\b)site_prefs=lang%3Den-GB/ ? 1 : 0 ) );
}

# Check we have received 2 cookies and not 3.
# The 3rd one is only sent in a sub folder.
sub test05
{
    my $self = shift( @_ );
    my $jar = $self->jar;
    return( $self->ok( $jar->exists( 'session_token' ) && $jar->exists( 'csrf_token' ) ) );
}

sub test06
{
    my $self = shift( @_ );
    my $rv;
    my $jar = $self->jar;
    my $csrf = $jar->get( 'csrf_token' ) || do
    {
        $self->message( "Could not find the csrf_token cookie from what the http client sent me." );
        return( $self->ok(0) );
    };
    # To properly elapse the cookie, it needs to have the same property values
    $csrf->elapse;
    $csrf->path( '/' );
    defined( $rv = $jar->set( $csrf ) ) || do
    {
        $self->message( "add_response_header returned an error: ", $jar->error );
        return( $self->ok(0) );
    };
    return( $self->ok( $jar->exists( 'site_prefs' ) ) );
}

sub test07
{
    my $self = shift( @_ );
    my $rv;
    my $r = $self->request;
    my $jar  = $self->jar;
    my $c = $jar->make(
        name      => 'secret_cookie',
        value     => 'My big secret',
        path      => '/',
        expires   => '+10d',
        secure    => HAS_SSL,
        http_only => 1,
        same_site => 'Lax',
        key       => $CRYPT_KEY,
        algo      => 'AES',
        encrypt   => 1,
        # We declare it, because we need to reproduce it for checking
        iv        => $CRYPT_IV,
        debug     => $self->{debug},
    );
    defined( $c ) || do
    {
        $self->message( "make returned an error: ", $jar->error );
        return( $self->ok(0) );
    };
    
    defined( $rv = $jar->set( $c ) ) || do
    {
        $self->message( "set returned an error: ", $jar->error );
        return( $self->ok(0) );
    };
    # return( $self->ok( $jar->exists( 'secret_cookie' ) ) );
    my @set_values = $r->err_headers_out->get( 'Set-Cookie' );
    return( $self->ok( "@set_values" =~ /(^|\b)secret_cookie=/ ? 1 : 0 ) );
}

sub test08
{
    my $self = shift( @_ );
    my $jar  = $self->jar;
    my $c = $jar->get( 'secret_cookie' ) || do
    {
        $self->message( "Could not find the secret_cookie cookie from what the http client sent me." );
        return( $self->ok(0) );
    };
    my $val = $c->value;
    if( !$val->length )
    {
        $self->message( "Cookie secret_cookie value is empty." );
        return( $self->ok(0) );
    }
    my $rv = $c->decrypt( key => $CRYPT_KEY, iv => $CRYPT_IV, algo => 'AES' );
    if( !defined( $rv ) )
    {
        $self->message( "Failed to decrypt the secret_cookie cookie value '$val': ", $c->error );
        return( $self->ok(0) );
    }
    return( $self->ok(1) );
}

# Same as test08, except that the test should not pass
# So if we cannot decrypt the value, it is ok
sub test09
{
    my $self = shift( @_ );
    my $jar  = $self->jar;
    my $c = $jar->get( 'secret_cookie' ) || do
    {
        $self->message( "Could not find the cookie secret_cookie from what the http client sent me." );
        return( $self->ok(0) );
    };
    my $val = $c->value;
    if( !$val->length )
    {
        $self->message( "Cookie secret_cookie value is empty." );
        return( $self->ok(0) );
    }
    my $rv = $c->decrypt( key => $CRYPT_KEY, iv => $CRYPT_IV, algo => 'AES' );
    if( !$rv )
    {
        $self->message( "Ok, the decryption failed as it was supposed to for cookie secret_cookie for value '$val'." );
        return( $self->ok(1) );
    }
    return( $self->ok(0) );
}

sub test10
{
    my $self = shift( @_ );
    my $jar  = $self->jar;
    my $r = $self->request;
    my $rv;
    my $c = $jar->make(
        name      => 'signed_cookie',
        value     => 'lang=en-GB',
        path      => '/',
        expires   => '+10d',
        # Normally you would want this cookie to be sent only over ssl
        # but for the matter of testing, I have not set up ssl certificates
        secure    => HAS_SSL,
        http_only => 1,
        same_site => 'Lax',
        key       => $CRYPT_KEY,
        sign      => 1,
        debug     => $self->{debug},
    );
    defined( $c ) || do
    {
        $self->message( "make returned an error: ", $jar->error );
        return( $self->ok(0) );
    };
    defined( $rv = $jar->set( $c ) ) || do
    {
        $self->message( "set returned an error: ", $jar->error );
        return( $self->ok(0) );
    };
    my @set_values = $r->err_headers_out->get( 'Set-Cookie' );
    return( $self->ok( "@set_values" =~ /(^|\b)signed_cookie=/ ? 1 : 0 ) );
}

sub test11
{
    my $self = shift( @_ );
    my $jar  = $self->jar;
    my $c = $jar->get( 'signed_cookie' ) || do
    {
        $self->message( "Could not find the signed_cookie cookie from what the http client sent me." );
        return( $self->ok(0) );
    };
    my $val = $c->value;
    if( !$val->length )
    {
        $self->message( "Cookie signed_cookie value is empty." );
        return( $self->ok(0) );
    }
    if( !$c->is_valid( key => $CRYPT_KEY ) )
    {
        $self->message( "Failed to validate the signed_cookie cookie value '$val'." );
        return( $self->ok(0) );
    }
    return( $self->ok(1) );
}

sub test12
{
    my $self = shift( @_ );
    my $jar  = $self->jar;
    my $c = $jar->get( 'signed_cookie' ) || do
    {
        $self->message( "Could not find the signed_cookie cookie from what the http client sent me." );
        return( $self->ok(0) );
    };
    my $val = $c->value;
    if( !$val->length )
    {
        $self->message( "Cookie signed_cookie value is empty." );
        return( $self->ok(0) );
    }
    if( !$c->is_valid( key => $CRYPT_KEY ) )
    {
        $self->message( "Ok, the validation failed as it was supposed to for cookie signed_cookie for value '$val'." );
        return( $self->ok(1) );
    }
    return( $self->ok(0) );
}

1;

__END__

=encoding utf8

=head1 NAME

CookieTest - Cookie Testing Class

=head1 SYNOPSIS

In the Apache test conf:

    PerlModule Cookie::Jar
    PerlOptions +GlobalRequest
    PerlSetupEnv On
    <Directory "@documentroot@">
        SetHandler modperl
        PerlResponseHandler CookieTest
        AcceptPathInfo On
    </Directory>

In the test unit:

    use Apache::Test;
    use Apache::TestRequest;
    use HTTP::Request;

    my $config = Apache::Test::config();
    my $hostport = Apache::TestRequest::hostport( $config ) || '';
    my $jar = Cookie::Jar->new( debug => $DEBUG );
    my $ua = Apache::TestRequest->new;
    my $req = HTTP::Request->new( GET => "http://${hostport}/tests/test01" );
    $req->header( Host => $hostport );
    my $resp = $ua->request( $req );
    ok( $resp->content, 'ok' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a package for testing the L<Cookie> module under Apache2/modperl2

=head1 METHODS

=head2 handler

The main handler method called by modperl.

It calls the right method based on the last fragment of the path. For example an http request to C</test/test02> would call the method C<test02>

It returns the value returned by the method called, which should be an Apache constant.

=head2 failure

Calls L</reply> with C<Apache2::Const::HTTP_EXPECTATION_FAILED> and C<failed> and returns its value, which is the http code.

=head2 is

Provided with a resulting value and an expected value and this returns C<ok> if both match, or a string explaining the failure to match.

=head2 ok

Provided with a boolean value, and this returns the value returned by L</success> or L</failure> otherwise.

=head2 reply

Provided with a response http code and some text data, and this will return the response to the http client.

=head2 success

Calls L</reply> with C<Apache2::Const::HTTP_OK> and C<ok> and returns its value, which is the http code.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Cookie::Jar>, L<Cookie>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
