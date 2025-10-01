# NAME

Apache2::API - Apache2 API Framework

# SYNOPSIS

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

# VERSION

    v0.4.0

# DESCRIPTION

This module provides a comprehensive, powerful, yet simple framework to access [Apache mod\_perl's API](https://perl.apache.org/docs/2.0/api/) and documented appropriately.

Apache mod\_perl is an awesome framework, but quite complexe with a steep learning curve and methods all over the place. So much so that [they have developed a module dedicated to find appropriate methods](https://perl.apache.org/docs/2.0/user/coding/coding.html#toc_Where_the_Methods_Live) with [ModPerl::MethodLookup](https://metacpan.org/pod/ModPerl%3A%3AMethodLookup)

# METHODS

## new

    my $api = Apache2::API->new( $r, $hash_ref_of_options );
    # or
    my $api = Apache2::API->new( apache_request => $r, compression_threshold => 102400 );

This initiates the package and takes an [Apache2::RequestRec](https://metacpan.org/pod/Apache2%3A%3ARequestRec) object and an hash or hash reference of parameters, or only an hash or hash reference of parameters:

- `apache_request`

    See ["apache\_request"](#apache_request)

- `compression_threshold`

    See ["compression\_threshold"](#compression_threshold)

- `debug`

    Optional. If set with a positive integer, this will activate debugging message

## apache\_request

Returns the [Apache2::RequestRec](https://metacpan.org/pod/Apache2%3A%3ARequestRec) object that was provided upon object instantiation.

## bailout

    $api->bailout( $error_string );
    $api->bailout( { code => 400, message => $internal_message } );
    $api->bailout( { code => 400, message => $internal_message, public_message => "Sorry!" } );

Given an error message, this will prepare the HTTP header and response accordingly.

It will call ["gettext"](#gettext) to get the localised version of the error message, so this method is expected to be overriden by inheriting package.

If the outgoing content type set is `application/json` then this will return a properly formatted standard json error, such as:

    { "error": { "code": 401, "message": "Something went wrong" } }

Otherwise, it will send to the client the message as is.

## compression\_threshold( $integer )

The number of bytes threshold beyond which, the ["reply"](#reply) method will gzip compress the data returned to the client.

## decode\_base64( $data )

Given some data, this will decode it using base64 algorithm. It uses ["decode" in APR::Base64](https://metacpan.org/pod/APR%3A%3ABase64#decode) in the background.

## decode\_json( $data )

This decode from utf8 some data into a perl structure using [JSON](https://metacpan.org/pod/JSON)

If an error occurs, it will return undef and set an exception that can be accessed with the [error](https://metacpan.org/pod/Module%3A%3AGeneric#error) method.

## decode\_url( $string )

Given a url-encoded string, this returns the decoded string using ["decode" in APR::Request](https://metacpan.org/pod/APR%3A%3ARequest#decode)

## decode\_utf8( $data )

Decode some data from ut8 into perl internal utf8 representation using [Encode](https://metacpan.org/pod/Encode)

If an error occurs, it will return undef and set an exception that can be accessed with the [error](https://metacpan.org/pod/Module%3A%3AGeneric#errir) method.

## encode\_base64( $data )

Given some data, this will encode it using base64 algorithm. It uses ["encode" in APR::Base64](https://metacpan.org/pod/APR%3A%3ABase64#encode).

## encode\_json( $hash\_reference )

Given a hash reference, this will encode it into a json data representation.

However, this will not utf8 encode it, because this is done upon printing the data and returning it to the client.

The JSON object has the following properties enabled: `allow_nonref`, `allow_blessed`, `convert_blessed` and `relaxed`

## encode\_url( $string )

Given a string, this returns its url-encoded version using ["encode" in APR::Request](https://metacpan.org/pod/APR%3A%3ARequest#encode)

## encode\_utf8( $data )

This encode in ut8 the data provided and return it.

If an error occurs, it will return undef and set an exception that can be accessed with the **error** method.

## generate\_uuid

Generates an uuid string and return it. This uses [APR::UUID](https://metacpan.org/pod/APR%3A%3AUUID)

## get\_auth\_bearer

Checks whether an `Authorization` HTTP header was provided, and get the Bearer value.

If no header was found, it returns an empty string.

If an error occurs, it will return undef and set an exception that can be accessed with the **error** method.

## get\_handlers

Returns a reference to a list of handlers enabled for a given phase.

    $handlers_list = $res->get_handlers( $hook_name );

A list of handlers configured to run at the child\_exit phase:

    @handlers = @{ $res->get_handlers( 'PerlChildExitHandler' ) || []};

## gettext( 'string id' )

Get the localised version of the string passed as an argument.

This is supposed to be superseded by the package inheriting from [Apache2::API](https://metacpan.org/pod/Apache2%3A%3AAPI), if any.

## header\_datetime( DateTime object )

Given a [DateTime](https://metacpan.org/pod/DateTime) object, this sets it to GMT time zone and set the proper formatter ([Apache2::API::DateTime](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ADateTime)) so that the stringification is compliant with HTTP headers standard.

## is\_perl\_option\_enabled

Checks if perl option is enabled in the Virtual Host and returns a boolean value

## json

Returns a JSON object.

You can provide an optional hash or hash reference of properties to enable or disable:

    my $J = $api->json( pretty => 1, relaxed => 1 );

Each property corresponds to one that is supported by [JSON](https://metacpan.org/pod/JSON)

It also supports `ordered`, `order` and `sort` as an alias to `canonical`

## lang( $string )

Set or get the language for the API. This would typically be the HTTP preferred language.

## lang\_unix( $string )

Given a language, this returns a language code formatted the unix way, ie en-GB would become en\_GB

## lang\_web( $string )

Given a language, this returns a language code formatted the web way, ie en\_GB would become en-GB

## log

    $api->log->emerg( "Urgent message." );
    $api->log->alert( "Alert!" );
    $api->log->crit( "Critical message." );
    $api->log->error( "Error message." );
    $api->log->warn( "Warning..." );
    $api->log->notice( "You should know." );
    $api->log->info( "This is for your information." );
    $api->log->debug( "This is debugging message." );

Returns a [Apache2::Log::Request](https://metacpan.org/pod/Apache2%3A%3ALog%3A%3ARequest) object.

## log\_error( $string )

Given a string, this will log the data into the error log.

When log\_error is accessed with the [Apache2::RequestRec](https://metacpan.org/pod/Apache2%3A%3ARequestRec) the error gets logged into the Virtual Host log, but when log\_error gets accessed via the [Apache2::ServerUtil](https://metacpan.org/pod/Apache2%3A%3AServerUtil) object, the error get logged into the Apache main error log.

## print( @list )

print out the list of strings and returns the number of bytes sent.

The data will possibly be compressed if the HTTP client [acceptable encoding](HTTPs://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding) and if the data exceeds the value set in ["compression\_threshold"](#compression_threshold)

It will gzip it if the HTTP client acceptable encoding is `gzip` and if [IO::Compress::Gzip](https://metacpan.org/pod/IO%3A%3ACompress%3A%3AGzip) is installed.

It will bzip it if the HTTP client acceptable encoding is `bzip2` and if [IO::Compress::Bzip2](https://metacpan.org/pod/IO%3A%3ACompress%3A%3ABzip2) is installed.

It will deflate if if the HTTP client acceptable encoding is `deflate` and [IO::Compress::Deflate](https://metacpan.org/pod/IO%3A%3ACompress%3A%3ADeflate) is installed.

If none of the above is possible, the data will be returned uncompressed.

Note that the HTTP header `Vary` will be added the `Accept-Encoding` value.

## push\_handlers

Returns the values from ["push\_handlers" in Apache2::Server](https://metacpan.org/pod/Apache2%3A%3AServer#push_handlers) by passing it whatever arguments were provided.

## reply

This takes an HTTP code and a message, or an exception object such as [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) or any other object that supports the `code` and `message` method, or just a hash reference, **reply** will find out if the code provided is an error and format the replied json appropriately like:

    { "error": { "code": 400, "message": "Some error" } }

It will json encode the returned data and print it out back to the client after setting the HTTP returned code.

If a `cleanup` hash property is provided with a callback code reference as a value, it will be set as a cleanup callback by calling `$r->pool->cleanup_register`. See [https://perl.apache.org/docs/2.0/user/handlers/http.html#PerlCleanupHandler](https://perl.apache.org/docs/2.0/user/handlers/http.html#PerlCleanupHandler)

The [Apache2::API](https://metacpan.org/pod/Apache2%3A%3AAPI) object will be passed as the first and only argument to the callback routine.

## request()

Returns the [Apache2::API::Request](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ARequest) object. This object is set upon instantiation.

## response

Returns the [Apache2::API::Response](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3AResponse) object. This object is set upon instantiation.

## server()

Returns a [Apache2::Server](https://metacpan.org/pod/Apache2%3A%3AServer) object

## server\_version()

Tries hard to find out the version number of the Apache server. This returns the value from ["server\_version" in Apache2::API::Request](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ARequest#server_version)

## set\_handlers()

Returns the values from ["set\_handlers" in Apache2::Server](https://metacpan.org/pod/Apache2%3A%3AServer#set_handlers) by passing it whatever arguments were provided.

## warn( @list )

Given a list of string, this sends a warning using ["warn" in Apache2::Log](https://metacpan.org/pod/Apache2%3A%3ALog#warn)

## \_try( $object\_type, $method\_name, @\_ )

Given an object type, a method name and optional parameters, this attempts to call it, passing it whatever arguments were provided and return its return values.

Apache2 methods are designed to die upon error, whereas our model is based on returning `undef` and setting an exception with [Module::Generic::Exception](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException), because we believe that only the main program should be in control of the flow and decide whether to interrupt abruptly the execution, not some sub routines.

# CONSTANTS

`mod_perl` provides constants through [Apache2::Constant](https://metacpan.org/pod/Apache2%3A%3AConstant) and [APR::Constant](https://metacpan.org/pod/APR%3A%3AConstant). [Apache2::API](https://metacpan.org/pod/Apache2%3A%3AAPI) makes all those constants available using their respective package name, such as:

    use Apache2::API;
    say Apache2::Const::HTTP_BAD_REQUEST; # 400

You can import constants into your namespace by specifying them when loading [Apache2::API](https://metacpan.org/pod/Apache2%3A%3AAPI), such as:

    use Apache2::API qw( HTTP_BAD_REQUEST );
    say HTTP_BAD_REQUEST; # 400

Be careful, however, that there are over 400 Apache2 constants and some common constant names in [Apache2::Constant](https://metacpan.org/pod/Apache2%3A%3AConstant) and [APR::Constant](https://metacpan.org/pod/APR%3A%3AConstant), so it is recommended to use the fully qualified constant names rather than importing them into your namespace.

Some constants are special like `OK`, `DECLINED` or `DECLINE_CMD`

Apache [underlines](https://perl.apache.org/docs/2.0/user/handlers/http.html#toc_HTTP_Request_Cycle_Phases) that "all handlers in the chain will be run as long as they return Apache2::Const::OK or Apache2::Const::DECLINED. Because stacked handlers is a special case. So don't be surprised if you've returned Apache2::Const::OK and the next handler was still executed. This is a feature, not a bug."

- `Apache2::Const::OK`

    The only value that can be returned by all handlers is `Apache2::Const::OK`, which tells Apache that the handler has successfully finished its execution.

- `Apache2::Const::DECLINED`

    This indicates success, but it's only relevant for phases of type RUN\_FIRST (`PerlProcessConnectionHandler`, `PerlTransHandler`, `PerlMapToStorageHandler`, `PerlAuthenHandler`, `PerlAuthzHandler`, `PerlTypeHandler`, `PerlResponseHandler`

    Apache2 [documentation explains](https://perl.apache.org/docs/2.0/api/Apache2/RequestRec.html#toc_C_allowed_) that "generally modules should `Apache2::Const::DECLINED` any request methods they do not handle."

- `Apache2::Const::DONE`

    This "tells Apache to stop the normal HTTP request cycle and fast forward to the PerlLogHandler,"

Check [Apache documentation on handler return value](https://perl.apache.org/docs/2.0/user/handlers/intro.html#toc_Handler_Return_Values) for more information.

# INSTALLATION

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

See also [modperl testing documentation](https://perl.apache.org/docs/general/testing/testing.html)

But, if for some reason, you do not want to perform the mod\_perl tests, you can use `NO_MOD_PERL=1` when calling `perl Makefile.PL`, such as:

    NO_MOD_PERL=1 perl Makefile.PL
    make
    make test
    sudo make install

To run individual test, you can do, for example:

    t/TEST t/01.api.t

or, in verbose mode:

    t/TEST -verbose t/01.api.t

## Makefile.PL options

Here are the available options to use when building the `Makefile.PL`:

- `-access_module_name`

    access module name

- `-apxs`

    location of apxs (default is from [Apache2::BuildConfig](https://metacpan.org/pod/Apache2%3A%3ABuildConfig))

- `-auth_module_name`

    auth module name

- `-bindir`

    Apache bin/ dir (default is `apxs -q BINDIR`)

- `-cgi_module_name`

    cgi module name

- `-defines`

    values to add as `-D` defines (for example, `"VAR1 VAR2"`)

- `-documentroot`

    DocumentRoot (default is `$ServerRoot/htdocs`

- `-group`

    Group to run test server as (default is `$GROUP`)

- `-httpd`

    server to use for testing (default is `$bindir/httpd`)

- `-httpd_conf`

    inherit config from this file (default is apxs derived)

- `-httpd_conf_extra`

    inherit additional config from this file

- `-libmodperl`

    path to mod\_perl's .so (full or relative to LIBEXECDIR)

- `-limitrequestline`

    global LimitRequestLine setting (default is `128`)

- `-maxclients`

    maximum number of concurrent clients (default is minclients+1)

- `-minclients`

    minimum number of concurrent clients (default is `1`)

- `-perlpod`

    location of perl pod documents (for testing downloads)

- `-php_module_name`

    php module name

- `-port`

    Port \[port\_number|select\] (default `8529`)

- `-proxyssl_url`

    url for testing ProxyPass / https (default is localhost)

- `-sbindir`

    Apache sbin/ dir (default is `apxs -q SBINDIR`)

- `-servername`

    ServerName (default is `localhost`)

- `-serverroot`

    ServerRoot (default is `$t_dir`)

- `-src_dir`

    source directory to look for `mod_foos.so`

- `-ssl_module_name`

    ssl module name

- `-sslca`

    location of SSL CA (default is `$t_conf/ssl/ca`)

- `-sslcaorg`

    SSL CA organization to use for tests (default is asf)

- `-sslproto`

    SSL/TLS protocol version(s) to test

- `-startup_timeout`

    seconds to wait for the server to start (default is `60`)

- `-t_conf`

    the conf/ test directory (default is `$t_dir/conf`)

- `-t_conf_file`

    test httpd.conf file (default is `$t_conf/httpd.conf`)

- `-t_dir`

    the t/ test directory (default is `$top_dir/t`)

- `-t_logs`

    the logs/ test directory (default is `$t_dir/logs`)

- `-t_pid_file`

    location of the pid file (default is `$t_logs/httpd.pid`)

- `-t_state`

    the state/ test directory (default is `$t_dir/state`)

- `-target`

    name of server binary (default is `apxs -q TARGET`)

- `-thread_module_name`

    thread module name

- `-threadsperchild`

    number of threads per child when using threaded MPMs (default is `10`)

- `-top_dir`

    top-level directory (default is `$PWD`)

- `-user`

    User to run test server as (default is `$USER`)

See also [Apache::TestMM](https://metacpan.org/pod/Apache%3A%3ATestMM) for available parameters or you can type on the command line:

    perl -MApache::TestConfig -le 'Apache::TestConfig::usage()'

## Tesging options

For example, specifying a port to use:

    t/TEST -start-httpd -port=34343
    t/TEST -run-tests
    t/TEST -stop-httpd

You can run `t/TEST -help` to get the list of options. See below as well:

- `-breakpoint=bp`

    set breakpoints (multiply bp can be set)

- `-bugreport`

    print the hint how to report problems

- `-clean`

    remove all generated test files

- `-configure`

    force regeneration of httpd.conf  (tests will not be run)

- `-debug[=name]`

    start server under debugger name (gdb, ddd, etc.)

- `-get`

    GET url

- `-head`

    HEAD url

- `-header`

    add headers to (get|post|head) request

- `-help`

    display this message

- `-http11`

    run all tests with `HTTP/1.1` (keep alive) requests

- `-no-httpd`

    run the tests without configuring or starting httpd

- `-one-process`

    run the server in single process mode

- `-order=mode`

    run the tests in one of the modes: (repeat|random|SEED)

- `-ping[=block]`

    test if server is running or port in use

- `-post`

    POST url

- `-postamble`

    config to add at the end of `httpd.conf`

- `-preamble`

    config to add at the beginning of `httpd.conf`

- `-proxy`

    proxy requests (default proxy is localhost)

- `-run-tests`

    run the tests

- `-ssl`

    run tests through ssl

- `-start-httpd`

    start the test server

- `-stop-httpd`

    stop the test server

- `-trace=T`

    change tracing default to: warning, notice, info, debug, ...

- `-verbose[=1]`

    verbose output

See for more information [https://perl.apache.org/docs/general/testing/testing.html](https://perl.apache.org/docs/general/testing/testing.html)

## API CORE MODULES

[Apache2::RequestIO](https://metacpan.org/pod/Apache2%3A%3ARequestIO), [Apache2::RequestRec](https://metacpan.org/pod/Apache2%3A%3ARequestRec)

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[Apache2::API::DateTime](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ADateTime), [Apache2::API::Query](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3AQuery), [Apache2::API::Request](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ARequest), [Apache2::API::Request::Params](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ARequest%3A%3AParams), [Apache2::API::Request::Upload](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ARequest%3A%3AUpload), [Apache2::API::Response](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3AResponse), [Apache2::API::Status](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3AStatus)

[Apache2::Request](https://metacpan.org/pod/Apache2%3A%3ARequest), [Apache2::RequestRec](https://metacpan.org/pod/Apache2%3A%3ARequestRec), [Apache2::RequestUtil](https://metacpan.org/pod/Apache2%3A%3ARequestUtil)

# COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
