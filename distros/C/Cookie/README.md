SYNOPSIS
========

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

VERSION
=======

        v0.1.1

DESCRIPTION
===========

This is a module to handle
[cookies](https://metacpan.org/pod/Cookie){.perl-module}, according to
the latest standard as set by
[rfc6265](https://datatracker.ietf.org/doc/html/rfc6265){.perl-module},
both by the http server and the client. Most modules out there are
either antiquated, i.e. they do not support latest cookie
[rfc6265](https://datatracker.ietf.org/doc/html/rfc6265){.perl-module},
or they focus only on http client side.

For example, Apache2::Cookie does not work well in decoding cookies, and
[Cookie::Baker](https://metacpan.org/pod/Cookie::Baker){.perl-module}
`Set-Cookie` timestamp format is wrong. They use Mon-09-Jan 2020
12:17:30 GMT where it should be, as per rfc 6265 Mon, 09 Jan 2020
12:17:30 GMT

Also
[APR::Request::Cookie](https://metacpan.org/pod/APR::Request::Cookie){.perl-module}
and
[Apache2::Cookie](https://metacpan.org/pod/Apache2::Cookie){.perl-module}
which is a wrapper around
[APR::Request::Cookie](https://metacpan.org/pod/APR::Request::Cookie){.perl-module}
return a cookie object that returns the value of the cookie upon
stringification instead of the full `Set-Cookie` parameters. Clearly
they designed it with a bias leaned toward collecting cookies from the
browser.

This module supports modperl and uses a
[Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec){.perl-module}
if provided, or can use package objects that implement similar interface
as [HTTP::Request](https://metacpan.org/pod/HTTP::Request){.perl-module}
and
[HTTP::Response](https://metacpan.org/pod/HTTP::Response){.perl-module},
or if none of those above are available or provided, this module returns
its results as a string.

This module is also compatible with
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent){.perl-module},
so you can use like this:

        use LWP::UserAgent;
        use Cookie::Jar;
     
        my $ua = LWP::UserAgent->new(
            cookie_jar => Cookie::Jar->new
        );

This module does not die upon error, but instead returns `undef` and
sets an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module},
so you should always check the return value of a method.

METHODS
=======

new
---

This initiates the package and takes the following parameters:

*request*

:   This is an optional parameter to provide a
    [Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec){.perl-module}
    object. When provided, it will be used in various methods to get or
    set cookies from or onto http headers.

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

*debug*

:   Optional. If set with a positive integer, this will activate verbose
    debugging message

add
---

Provided with an hash or hash reference of cookie parameters (see
[Cookie](https://metacpan.org/pod/Cookie){.perl-module}) and this will
create a new [cookie](https://metacpan.org/pod/Cookie){.perl-module} and
add it to the cookie repository.

Alternatively, you can also provide directly an existing [cookie
object](https://metacpan.org/pod/Cookie){.perl-module}

        my $c = $jar->add( $cookie_object ) || die( $jar->error );

add\_cookie\_header
-------------------

This is an alias for
[\"add\_request\_header\"](#add_request_header){.perl-module} for
backward compatibility with
[HTTP::Cookies](https://metacpan.org/pod/HTTP::Cookies){.perl-module}

add\_request\_header
--------------------

Provided with a request object, such as, but not limited to
[HTTP::Request](https://metacpan.org/pod/HTTP::Request){.perl-module}
and this will add all relevant cookies in the repository into the
`Cookie` http request header.

As long as the object provided supports the `uri` and `header` method,
you can provide any class of object you want.

Please refer to the
[rfc6265](https://datatracker.ietf.org/doc/html/rfc6265){.perl-module}
for more information on the applicable rule when adding cookies to the
outgoing request header.

Basically, it will add, for a given domain, first all cookies whose path
is longest and at path equivalent, the cookie creation date is used,
with the earliest first. Cookies who have expired are not sent, and
there can be cookies bearing the same name for the same domain in
different paths.

add\_response\_header
---------------------

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

This is the alter ego to
[\"add\_request\_header\"](#add_request_header){.perl-module}, in that
it performs the equivalent function, but for the server side.

You can optionally provide, as unique argument, an object, such as but
not limited to,
[HTTP::Response](https://metacpan.org/pod/HTTP::Response){.perl-module},
as long as that class supports the `header` method

Alternatively, if an [Apache
object](https://metacpan.org/pod/Apache2::RequestRec){.perl-module} has
been set upon object instantiation or later using the
[\"request\"](#request){.perl-module} method, then it will be used to
set the outgoing `Set-Cookie` headers (there is one for every cookie
sent).

If no response, nor Apache2 object were set, then this will simply
return a list of `Set-Cookie` in list context, or a string of possibly
multiline `Set-Cookie` headers, or an empty string if there is no cookie
found to be sent.

Be careful not to do the following:

        # get cookies sent by the http client
        $jar->fetch || die( $jar->error );
        # set the response headers with the cookies from our repository
        $jar->add_response_header;

Why? Well, because [\"fetch\"](#fetch){.perl-module} retrieves the
cookies sent by the http client and store them into the repository.
However, cookies sent by the http client only contain the cookie name
and value, such as:

        GET /my/path/ HTTP/1.1
        Host: www.example.org
        Cookie: session_token=eyJleHAiOjE2MzYwNzEwMzksImFsZyI6IkhTMjU2In0.eyJqdGkiOiJkMDg2Zjk0OS1mYWJmLTRiMzgtOTE1ZC1hMDJkNzM0Y2ZmNzAiLCJmaXJzdF9uYW1lIjoiSm9obiIsImlhdCI6MTYzNTk4NDYzOSwiYXpwIjoiNGQ0YWFiYWQtYmJiMy00ODgwLThlM2ItNTA0OWMwZTczNjBlIiwiaXNzIjoiaHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20iLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwibGFzdF9uYW1lIjoiRG9lIiwic3ViIjoiYXV0aHxlNzg5OTgyMi0wYzlkLTQyODctYjc4Ni02NTE3MjkyYTVlODIiLCJjbGllbnRfaWQiOiJiZTI3N2VkYi01MDgzLTRjMWEtYTM4MC03Y2ZhMTc5YzA2ZWQiLCJleHAiOjE2MzYwNzEwMzksImF1ZCI6IjRkNGFhYmFkLWJiYjMtNDg4MC04ZTNiLTUwNDljMGU3MzYwZSJ9.VSiSkGIh41xXIVKn9B6qGjfzcLlnJAZ9jGOPVgXASp0; csrf_token=9849724969dbcffd48c074b894c8fbda14610dc0ae62fac0f78b2aa091216e0b.1635825594; site_prefs=lang%3Den-GB

As you can see, 3 cookies were sent: `session_token`, `csrf_token` and
`site_prefs`

So, when [\"fetch\"](#fetch){.perl-module} creates an object for each
one and store them, those cookies have no `path` value and no other
attribute, and when
[\"add\_response\_header\"](#add_response_header){.perl-module} is then
called, it stringifies the cookies and create a `Set-Cookie` header for
each one, but only with their value and no other attribute.

The http client, when receiving those cookies will derive the missing
cookie path to be `/my/path`, i.e. the current uri path, and will
override the previously stored cookie with the same name for that host
that had the path set to `/`

So you can create a repository and use it to store the cookies sent by
the http client using [\"fetch\"](#fetch){.perl-module}, but in
preparation of the server response, either use a separate repository
with, for example, `my $jar_out = Cookie::Jar-`new\> or use
[\"set\"](#set){.perl-module} which will still add the cookie to the
repository, but also before set the `Set-Cookie` header for that cookie.

        # Add Set-Cookie header for that cookie and add cookie to repository
        $jar->set( $cookie_object );

delete
------

Given a cookie name, an optional host and optional path or a
[Cookie](https://metacpan.org/pod/Cookie){.perl-module} object, and this
will remove it from the cookie repository.

It returns an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
upon success, or [\"undef\" in
perlfunc](https://metacpan.org/pod/perlfunc#undef){.perl-module} and
sets an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}.
Note that the array object may be empty.

However, this will NOT remove it from the web browser by sending a
Set-Cookie header. For that, you might want to look at the [\"elapse\"
in Cookie](https://metacpan.org/pod/Cookie#elapse){.perl-module} method.

It returns an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
of cookie objects removed.

        my $arr = $jar->delete( 'my-cookie' );
        # alternatively
        my $arr = $jar->delete( 'my-cookie' => 'www.example.org' );
        # or
        my $arr = $jar->delete( $my_cookie_object );
        printf( "%d cookie(s) removed.\n", $arr->length );
        print( "Cookie value removed was: ", $arr->first->value, "\n" );

If you are interested in telling the http client to remove all your
cookies, you can set the `Clear-Site-Data` header:

        Clear-Site-Data: "cookies"

You can instruct the http client to remove other data like local
storage:

        Clear-Site-Data: "cookies", "cache", "storage", "executionContexts"

Although this is widely supported, there is no guarantee the http client
will actually comply with this request.

See [Mozilla
documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data){.perl-module}
for more information.

do
--

Provided with an anonymous code or reference to a subroutine, and this
will call that code for every cookie in the repository, passing it the
cookie object as the sole argument. Also, that cookie object is
accessible using `$_`.

If the code return `undef`, it will end the loop, and it the code
returns true, this will have the current cookie object added to an
[array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
returned upon completion of the loop.

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

exists
------

Given a cookie name, this will check if it exists.

It returns 1 if it does, or 0 if it does not.

extract
-------

Provided with a response object, such as, but not limited to
[HTTP::Response](https://metacpan.org/pod/HTTP::Response){.perl-module},
and this will retrieve any cookie sent from the remote server, parse
them and add their respective to the repository.

As per the [rfc6265, section 5.3.11
specifications](https://datatracker.ietf.org/doc/html/rfc6265#section-5.3){.perl-module}
if there are duplicate cookies for the same domain and path, only the
last one will be retained.

If the cookie received does not contain any `Domain` specification,
then, in line with rfc6265 specifications, it will take the root of the
current domain as the default domain value. Since finding out what is
the root for a domain name is a non-trivial exercise, this method relies
on
[Cookie::Domain](https://metacpan.org/pod/Cookie::Domain){.perl-module}.

extract\_cookies
----------------

This is an alias for [\"extract\"](#extract){.perl-module} for backward
compatibility with
[HTTP::Cookies](https://metacpan.org/pod/HTTP::Cookies){.perl-module}

fetch
-----

This method does the equivalent of
[\"extract\"](#extract){.perl-module}, but for the server.

It retrieves all possible cookies from the http request received from
the web browser.

It takes an optional hash or hash reference of parameters, such as
`host`. If it is not provided, the value set with
[\"host\"](#host){.perl-module} is used instead.

If the parameter `request` containing an http request object, such as,
but not limited to
[HTTP::Request](https://metacpan.org/pod/HTTP::Request){.perl-module},
is provided, it will use it to get the `Cookie` header value.

Alternatively, if a value for [\"request\"](#request){.perl-module} has
been set, it will use it to get the `Cookie` header value from Apache
modperl.

You can also provide the `Cookie` string to parse by providing the
`string` option to this method.

        $jar->fetch( string => q{foo=bar; site_prefs=lang%3Den-GB} ) ||
            die( $jar->error );

Ultimately, if none of those are available, it will use the environment
variable `HTTP_COOKIE`

In void context, this method, will add the fetched cookies to its
[repository](#repo){.perl-module}.

It returns an hash reference of cookie key =\> [cookie
object](https://metacpan.org/pod/Cookie){.perl-module}

A cookie key is made of the host (possibly empty) and the cookie name
separated by `;`

        # Cookies added to the repository
        $jar->fetch || die( $jar->error );
        # Cookies returned, but NOT added to the repository
        my $cookies = $jar->fetch || die( $jar->error );

get
---

Given a cookie name, an optional host and an optional path, this will
retrieve its value and return it.

If not found, it will try to return a value with just the cookie name.

If nothing is found, this will return and empty list in list context or
`undef` in scalar context.

You can `get` multiple cookies and this method will return a list in
list context and the first cookie found in scalar context.

        # Wrong, an undefined returned value here only means there is no such cookie
        my $c = $jar->get( 'my-cookie' );
        die( $jar->error ) if( !defined( $c ) );
        # Correct
        my $c = $jar->get( 'my-cookie' ) || die( "No cookie my-cookie found\n" );
        # Possibly get multiple cookie object for the same name
        my @cookies = $jar->get( 'my_same_name' ) || die( "No cookies my_same_name found\n" );
        # or
        my @cookies = $jar->get( 'my_same_name' => 'www.example.org', '/private' ) || die( "No cookies my_same_name found\n" );

get\_by\_domain
---------------

Provided with a host and an optional hash or hash reference of
parameters, and this returns an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
of [cookie objects](https://metacpan.org/pod/Cookie){.perl-module}
matching the domain specified.

If a `sort` parameter has been provided and its value is true, this will
sort the cookies by path alphabetically. If the sort value exists, but
is false, this will sort the cookies by path but in a reverse
alphabetical order.

By default, the cookies are sorted.

host
----

Sets or gets the default host. This is especially useful for cookies
repository used on the server side.

key
---

Provided with a cookie name and an optional host and this returns a key
used to add an entry in the hash repository.

If no host is provided, the key is just the cookie, otherwise the
resulting key is the cookie name and host separated just by `;`

You should not need to use this method as it is used internally only.

load
----

        $jar->load( '/home/joe/cookies.json' ) || die( $jar->error );

        # or loading cookies from encrypted file
        $jar->load( '/home/joe/cookies_encrypted.json',
        {
            decrypt => 1,
            key => $key,
            iv  => $iv,
            algo => 'AES'
        }) || die( $jar->error );

Give a json cookie file, and an hash or hash reference of options, and
this will load its data into the repository. If there are duplicates
(same cookie name and host), the latest one added takes precedence, as
per the rfc6265 specifications.

Supported options are:

*algo* string

:   Algorithm to use to decrypt the cookie file.

    It can be any of
    [AES](https://metacpan.org/pod/Crypt::Cipher::AES){.perl-module},
    [Anubis](https://metacpan.org/pod/Crypt::Cipher::Anubis){.perl-module},
    [Blowfish](https://metacpan.org/pod/Crypt::Cipher::Blowfish){.perl-module},
    [CAST5](https://metacpan.org/pod/Crypt::Cipher::CAST5){.perl-module},
    [Camellia](https://metacpan.org/pod/Crypt::Cipher::Camellia){.perl-module},
    [DES](https://metacpan.org/pod/Crypt::Cipher::DES){.perl-module},
    [DES\_EDE](https://metacpan.org/pod/Crypt::Cipher::DES_EDE){.perl-module},
    [KASUMI](https://metacpan.org/pod/Crypt::Cipher::KASUMI){.perl-module},
    [Khazad](https://metacpan.org/pod/Crypt::Cipher::Khazad){.perl-module},
    [MULTI2](https://metacpan.org/pod/Crypt::Cipher::MULTI2){.perl-module},
    [Noekeon](https://metacpan.org/pod/Crypt::Cipher::Noekeon){.perl-module},
    [RC2](https://metacpan.org/pod/Crypt::Cipher::RC2){.perl-module},
    [RC5](https://metacpan.org/pod/Crypt::Cipher::RC5){.perl-module},
    [RC6](https://metacpan.org/pod/Crypt::Cipher::RC6){.perl-module},
    [SAFERP](https://metacpan.org/pod/Crypt::Cipher::SAFERP){.perl-module},
    [SAFER\_K128](https://metacpan.org/pod/Crypt::Cipher::SAFER_K128){.perl-module},
    [SAFER\_K64](https://metacpan.org/pod/Crypt::Cipher::SAFER_K64){.perl-module},
    [SAFER\_SK128](https://metacpan.org/pod/Crypt::Cipher::SAFER_SK128){.perl-module},
    [SAFER\_SK64](https://metacpan.org/pod/Crypt::Cipher::SAFER_SK64){.perl-module},
    [SEED](https://metacpan.org/pod/Crypt::Cipher::SEED){.perl-module},
    [Skipjack](https://metacpan.org/pod/Crypt::Cipher::Skipjack){.perl-module},
    [Twofish](https://metacpan.org/pod/Crypt::Cipher::Twofish){.perl-module},
    [XTEA](https://metacpan.org/pod/Crypt::Cipher::XTEA){.perl-module},
    [IDEA](https://metacpan.org/pod/Crypt::Cipher::IDEA){.perl-module},
    [Serpent](https://metacpan.org/pod/Crypt::Cipher::Serpent){.perl-module}
    or simply any \<NAME\> for which there exists
    Crypt::Cipher::\<NAME\>

*decrypt* boolean

:   Must be set to true to enable decryption.

*iv* string

:   Set the [Initialisation
    Vector](https://en.wikipedia.org/wiki/Initialization_vector){.perl-module}
    used for file encryption and decryption. This must be the same value
    used for encryption. See [\"save\"](#save){.perl-module}

*key* string

:   Set the encryption key used to decrypt the cookies file.

    The key must be the same one used to encrypt the file. See
    [\"save\"](#save){.perl-module}

[\"load\"](#load){.perl-module} returns the current object upon success
and `undef` and sets an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
upon error.

load\_as\_lwp
-------------

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

Given a file path to an LWP-style cookie file (see below a snapshot of
what it looks like), and an hash or hash reference of options, and this
method will read the cookies from the file and add them to our
repository, possibly overwriting previous cookies with the same name and
domain name.

The supported options are the same as for
[\"load\"](#load){.perl-module}

LWP-style cookie files are ancient, and barely used anymore, but no
matter; if you need to load cookies from such file, it looks like this:

        #LWP-Cookies-1.0
        Set-Cookie3: cookie1=value1; domain=example.com; path=; path_spec; secure; version=2
        Set-Cookie3: cookie2=value2; domain=api.example.com; path=; path_spec; secure; version=2
        Set-Cookie3: cookie3=value3; domain=img.example.com; path=; path_spec; secure; version=2

It returns the current object upon success, or `undef` and sets an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
upon error.

load\_as\_netscape
------------------

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

Given a file path to a Netscape-style cookie file, and this method will
read cookies from the file and add them to our repository, possibly
overwriting previous cookies with the same name and domain name.

It returns the current object upon success, or `undef` and sets an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
upon error.

make
----

Provided with some parameters and this will instantiate a new
[Cookie](https://metacpan.org/pod/Cookie){.perl-module} object with
those parameters and return the new object.

This does not add the newly created cookie object to the cookies
repository.

For a list of supported parameters, refer to the [Cookie
documentation](https://metacpan.org/pod/Cookie){.perl-module}

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

merge
-----

Provided with another
[Cookie::Jar](https://metacpan.org/pod/Cookie::Jar){.perl-module}
object, or at least an object that supports the
[\"do\"](#do){.perl-module} method, which takes an anonymous code as
argument, and that calls that code passing it each cookie object found
in the alternate repository, and this method will add all those cookies
in the alternate repository into the current repository.

        $jar->merge( $other_jar ) || die( $jar->error );

If the cookie objects passed to the anonymous code in this method, are
not [Cookie](https://metacpan.org/pod/Cookie){.perl-module} object, then
at least they must support the methods `name`, `value`, `domain`,
`path`, `port`, `secure`, `max_age`, `secure`, `same_site` and ,
`http_only`

This method also takes an hash or hash reference of options:

*die* boolean

:   If true, the anonymous code passed to the `do` method called, will
    die upon error. Default to false.

    By default, if an error occurs, `undef` is returned and the
    [error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
    is set.

*overwrite* boolean

:   If true, when an existing cookie is found it will be overwritten by
    the new one. Default to false.

<!-- -->

        use Nice::Try;
        try
        {
            $jar->merge( $other_jar, die => 1, overwrite => 1 );
        }
        catch( $e )
        {
            die( "Failed to merge cookies repository: $e\n" );
        }

Upon success this will return the current object, and if there was an
error, this returns [\"undef\" in
perlfunc](https://metacpan.org/pod/perlfunc#undef){.perl-module} and
sets an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}

parse
-----

This method is used by [\"fetch\"](#fetch){.perl-module} to parse
cookies sent by http client. Parsing is much simpler than for http
client receiving cookies from server.

It takes the raw `Cookie` string sent by the http client, and returns an
hash reference (possibly empty) of cookie name to cookie value pairs.

        my $cookies = $jar->parse( 'foo=bar; site_prefs=lang%3Den-GB' );
        # You can safely do as well:
        my $cookies = $jar->parse( '' );

purge
-----

Thise takes no argument and will remove from the repository all cookies
that have expired. A cookie that has expired is a
[Cookie](https://metacpan.org/pod/Cookie){.perl-module} that has its
`expires` property set and whose value is in the past.

This returns an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
of all the cookies thus removed.

        my $all = $jar->purge;
        printf( "Cookie(s) removed were: %s\n", $all->map(sub{ $_->name })->join( ',' ) );
        # or
        printf( "%d cookie(s) removed from our repository.\n", $jar->purge->length );

replace
-------

Provided with a [Cookie](https://metacpan.org/pod/Cookie){.perl-module}
object, and an optional other
[Cookie](https://metacpan.org/pod/Cookie){.perl-module} object, and this
method will replace the former cookie provided in the second parameter
with the new one provided in the first parameter.

If only one parameter is provided, the cookies to be replaced will be
derived from the replacement cookie\'s properties, namely: `name`,
`domain` and `path`

It returns an [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
of cookie objects replaced upon success, or `undef` and set an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}
upon error.

repo
----

Set or get the [array
object](https://metacpan.org/pod/Module::Generic::Array){.perl-module}
used as the cookie jar repository.

        printf( "%d cookies found\n", $jar->repo->length );

request
-------

Set or get the
[Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec){.perl-module}
object. This object is used to set the `Set-Cookie` header within
modperl.

save
----

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

Provided with a file, and an hash or hash reference of options, and this
will save the repository of cookies as json data.

The hash saved to file contains 2 top properties: `updated_on`
containing the last update date and `cookies` containing an hash of
cookie name to cookie properties pairs.

It returns the current object. If an error occurred, it will return
`undef` and set an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}

Supported options are:

*algo* string

:   Algorithm to use to encrypt the cookie file.

    It can be any of
    [AES](https://metacpan.org/pod/Crypt::Cipher::AES){.perl-module},
    [Anubis](https://metacpan.org/pod/Crypt::Cipher::Anubis){.perl-module},
    [Blowfish](https://metacpan.org/pod/Crypt::Cipher::Blowfish){.perl-module},
    [CAST5](https://metacpan.org/pod/Crypt::Cipher::CAST5){.perl-module},
    [Camellia](https://metacpan.org/pod/Crypt::Cipher::Camellia){.perl-module},
    [DES](https://metacpan.org/pod/Crypt::Cipher::DES){.perl-module},
    [DES\_EDE](https://metacpan.org/pod/Crypt::Cipher::DES_EDE){.perl-module},
    [KASUMI](https://metacpan.org/pod/Crypt::Cipher::KASUMI){.perl-module},
    [Khazad](https://metacpan.org/pod/Crypt::Cipher::Khazad){.perl-module},
    [MULTI2](https://metacpan.org/pod/Crypt::Cipher::MULTI2){.perl-module},
    [Noekeon](https://metacpan.org/pod/Crypt::Cipher::Noekeon){.perl-module},
    [RC2](https://metacpan.org/pod/Crypt::Cipher::RC2){.perl-module},
    [RC5](https://metacpan.org/pod/Crypt::Cipher::RC5){.perl-module},
    [RC6](https://metacpan.org/pod/Crypt::Cipher::RC6){.perl-module},
    [SAFERP](https://metacpan.org/pod/Crypt::Cipher::SAFERP){.perl-module},
    [SAFER\_K128](https://metacpan.org/pod/Crypt::Cipher::SAFER_K128){.perl-module},
    [SAFER\_K64](https://metacpan.org/pod/Crypt::Cipher::SAFER_K64){.perl-module},
    [SAFER\_SK128](https://metacpan.org/pod/Crypt::Cipher::SAFER_SK128){.perl-module},
    [SAFER\_SK64](https://metacpan.org/pod/Crypt::Cipher::SAFER_SK64){.perl-module},
    [SEED](https://metacpan.org/pod/Crypt::Cipher::SEED){.perl-module},
    [Skipjack](https://metacpan.org/pod/Crypt::Cipher::Skipjack){.perl-module},
    [Twofish](https://metacpan.org/pod/Crypt::Cipher::Twofish){.perl-module},
    [XTEA](https://metacpan.org/pod/Crypt::Cipher::XTEA){.perl-module},
    [IDEA](https://metacpan.org/pod/Crypt::Cipher::IDEA){.perl-module},
    [Serpent](https://metacpan.org/pod/Crypt::Cipher::Serpent){.perl-module}
    or simply any \<NAME\> for which there exists
    Crypt::Cipher::\<NAME\>

*encrypt* boolean

:   Must be set to true to enable decryption.

*iv* string

:   Set the [Initialisation
    Vector](https://en.wikipedia.org/wiki/Initialization_vector){.perl-module}
    used for file encryption. If you do not provide one, it will be
    automatically generated. If you want to provide your own, make sure
    the size meets the encryption algorithm size requirement. You also
    need to keep this to decrypt the cookies file.

    To find the right size for the Initialisation Vector, for example
    for algorithm `AES`, you could do:

            perl -MCrypt::Cipher::AES -lE 'say Crypt::Cipher::AES->blocksize'

    which would yield `16`

*key* string

:   Set the encryption key used to encrypt the cookies file.

    The key must be the same one used to decrypt the file and must have
    a size big enough to satisfy the encryption algorithm requirement,
    which you can check with, say for `AES`:

            perl -MCrypt::Cipher::AES -lE 'say Crypt::Cipher::AES->keysize'

    In this case, it will yield `32`. Replace above `AES`, byt whatever
    algorithm you have chosen.

            perl -MCrypt::Cipher::Blowfish -lE 'say Crypt::Cipher::Blowfish->keysize'

    would yield `56` for `Blowfish`

    You can use [\"random\_bytes\" in
    Bytes::Random::Secure](https://metacpan.org/pod/Bytes::Random::Secure#random_bytes){.perl-module}
    to generate a random key:

            # will generate a 32 bytes-long key
            my $key = Bytes::Random::Secure::random_bytes(32);

When encrypting the cookies file, this method will encode the encrypted
data in base64 before saving it to file.

save\_as\_lwp
-------------

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

Provided with a file, and an hash or hash reference of options, and this
save the cookies repository as a LWP-style data.

The supported options are the same as for
[\"save\"](#save){.perl-module}

It returns the current object. If an error occurred, it will return
`undef` and set an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}

save\_as\_netscape
------------------

Provided with a file and this save the cookies repository as a
Netscape-style data.

It returns the current object. If an error occurred, it will return
`undef` and set an
[error](https://metacpan.org/pod/Module::Generic#error){.perl-module}

scan
----

This is an alias for [\"do\"](#do){.perl-module}

set
---

Given a cookie object, and an optional hash or hash reference of
parameters, and this will add the cookie to the outgoing http headers
using the `Set-Cookie` http header. To do so, it uses the
[Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec){.perl-module}
value set in [\"request\"](#request){.perl-module}, if any, or a
[HTTP::Response](https://metacpan.org/pod/HTTP::Response){.perl-module}
compatible response object provided with the `response` parameter.

        $jar->set( $c, response => $http_response_object ) ||
            die( $jar->error );

Ultimately if none of those two are provided it returns the `Set-Cookie`
header as a string.

        # Returns something like:
        # Set-Cookie: my-cookie=somevalue
        print( STDOUT $jar->set( $c ), "\015\012" );

Unless the latter, this method returns the current object.

IMPORTING COOKIES
=================

To import cookies, you can either use the methods
[scan](https://metacpan.org/pod/HTTP::Cookies#scan){.perl-module} from
[HTTP::Cookies](https://metacpan.org/pod/HTTP::Cookies){.perl-module},
such as:

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

or you could also load a cookie file.
[Cookie::Jar](https://metacpan.org/pod/Cookie::Jar){.perl-module}
supports [LWP](https://metacpan.org/pod/LWP){.perl-module} format and
old Netscape format:

        $jar->load_as_lwp( '/home/joe/lwp_cookies.txt' );
        $jar->load_as_netscape( '/home/joe/netscape_cookies.txt' );

And of course, if you are using
[Cookie::Jar](https://metacpan.org/pod/Cookie::Jar){.perl-module} json
cookies file, you can import them with:

        $jar->load( '/home/joe/cookies.json' );

ENCRYPTION
==========

This package supports encryption and decryption of cookies file, and
also the cookies values themselve.

See methods [\"save\"](#save){.perl-module} and
[\"load\"](#load){.perl-module} for encryption options and the
[Cookie](https://metacpan.org/pod/Cookie){.perl-module} package for
options to encrypt or sign cookies value.

INSTALLATION
============

As usual, to install this module, you can do:

        perl Makefile.PL
        make
        make test
        sudo make install

If you have Apache/modperl2 installed, this will also prepare the
Makefile and run test under modperl.

The Makefile.PL tries hard to find your Apache configuration, but you
can give it a hand by specifying some command line parameters. See
[Apache::TestMM](https://metacpan.org/pod/Apache::TestMM){.perl-module}
for available parameters or you can type on the command line:

        perl -MApache::TestConfig -le 'Apache::TestConfig::usage()'

For example:

        perl Makefile.PL -apxs /usr/bin/apxs -port 1234
        # which will also set the path to httpd_conf, otherwise
        perl Makefile.PL -httpd_conf /etc/apache2/apache2.conf

        # then
        make
        make test
        sudo make install

See also [modperl testing
documentation](https://perl.apache.org/docs/general/testing/testing.html){.perl-module}

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55a2c78baf58)"}\>

SEE ALSO
========

[Apache2::Cookies](https://metacpan.org/pod/Apache2::Cookies){.perl-module},
[APR::Request::Cookie](https://metacpan.org/pod/APR::Request::Cookie){.perl-module},
[Cookie::Baker](https://metacpan.org/pod/Cookie::Baker){.perl-module}

[Latest tentative version of the cookie
standard](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-09){.perl-module}

[Mozilla documentation on
Set-Cookie](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie){.perl-module}

[Information on double submit
cookies](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#double-submit-cookie){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright (c) 2019-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
