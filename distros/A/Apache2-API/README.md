# NAME

Apache2::API - Apache2 API Framework

# SYNOPSIS

# VERSION

    v0.8.2

# DESCRIPTION

Apache mod\_perl is an awesome framework, but quite complexe with a steep learning curve and methods all over the place. So much so that [they have developed a module dedicated to find appropriate methods](https://perl.apache.org/docs/2.0/user/coding/coding.html#toc_Where_the_Methods_Live) with [ModPerl::MethodLookup](https://metacpan.org/pod/ModPerl%3A%3AMethodLookup)

This module provides a powerful, yet simple framework to access all of Apache mod\_perl's methods and documented appropriately.

# METHODS

## new( $r, $hash )

This initiates the package and takes an [Apache2::RequestRec](https://metacpan.org/pod/Apache2%3A%3ARequestRec) object and an hash or hash reference of parameters:

- `debug`

    Optional. If set with a positive integer, this will activate debugging message

## apache\_request

Returns the [Apache2::RequestRec](https://metacpan.org/pod/Apache2%3A%3ARequestRec) object.

## bailout( $error\_string )

Given an error message, this will prepare the http header and response accordingly.

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

## generate\_uuid()

Generates an uuid string and return it. This uses [APR::UUID](https://metacpan.org/pod/APR%3A%3AUUID)

## get\_auth\_bearer()

Checks whether an `Authorization` http header was provided, and get the Bearer value.

If no header was found, it returns an empty string.

If an error occurs, it will return undef and set an exception that can be accessed with the **error** method.

## get\_handlers()

Returns a reference to a list of handlers enabled for a given phase.

    $handlers_list = $res->get_handlers( $hook_name );

A list of handlers configured to run at the child\_exit phase:

    @handlers = @{ $res->get_handlers( 'PerlChildExitHandler' ) || []};

## gettext( 'string id' )

Get the localised version of the string passed as an argument.

This is supposed to be superseded by the package inheriting from [Apache2::API](https://metacpan.org/pod/Apache2%3A%3AAPI), if any.

## header\_datetime( DateTime object )

Given a [DateTime](https://metacpan.org/pod/DateTime) object, this sets it to GMT time zone and set the proper formatter ([Apache2::API::DateTime](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ADateTime)) so that the stringification is compliant with http headers standard.

## is\_perl\_option\_enabled

Checks if perl option is enabled in the Virtual Host and returns a boolean value

## json()

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

## log\_error( $string )

Given a string, this will log the data into the error log.

When log\_error is accessed with the [Apache2::RequestRec](https://metacpan.org/pod/Apache2%3A%3ARequestRec) the error gets logged into the Virtual Host log, but when log\_error gets accessed via the [Apache2::ServerUtil](https://metacpan.org/pod/Apache2%3A%3AServerUtil) object, the error get logged into the Apache main error log.

## print( @list )

print out the list of strings and returns the number of bytes sent.

The data will possibly be compressed if the HTTP client [acceptable encoding](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding) and if the data exceeds the value set in ["compression\_threshold"](#compression_threshold)

It will gzip it if the HTTP client acceptable encoding is `gzip` and if [IO::Compress::Gzip](https://metacpan.org/pod/IO%3A%3ACompress%3A%3AGzip) is installed.

It will bzip it if the HTTP client acceptable encoding is `bzip2` and if [IO::Compress::Bzip2](https://metacpan.org/pod/IO%3A%3ACompress%3A%3ABzip2) is installed.

It will deflate if if the HTTP client acceptable encoding is `deflate` and [IO::Compress::Deflate](https://metacpan.org/pod/IO%3A%3ACompress%3A%3ADeflate) is installed.

If none of the above is possible, the data will be returned uncompressed.

Note that the HTTP header `Vary` will be added the `Accept-Encoding` value.

## push\_handlers

Returns the values from ["push\_handlers" in Apache2::Server](https://metacpan.org/pod/Apache2%3A%3AServer#push_handlers) by passing it whatever arguments were provided.

## reply

This takes an http code and a message, or just a hash reference, **reply** will find out if the code provided is an error and format the replied json appropriately like:

    { "error": { "code": 400, "message": "Some error" } }

It will json encode the returned data and print it out back to the client after setting the http returned code.

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

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[Apache2::API::DateTime](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ADateTime), [Apache2::API::Query](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3AQuery), [Apache2::API::Request](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ARequest), [Apache2::API::Request::Params](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ARequest%3A%3AParams), [Apache2::API::Request::Upload](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3ARequest%3A%3AUpload), [Apache2::API::Response](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3AResponse), [Apache2::API::Status](https://metacpan.org/pod/Apache2%3A%3AAPI%3A%3AStatus)

[Apache2::Request](https://metacpan.org/pod/Apache2%3A%3ARequest), [Apache2::RequestRec](https://metacpan.org/pod/Apache2%3A%3ARequestRec), [Apache2::RequestUtil](https://metacpan.org/pod/Apache2%3A%3ARequestUtil)

# COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
