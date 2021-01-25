SYNOPSIS
========

        use Apache2::SSI;
        my $ssi = Apache2::SSI->new(
            ## If running outside of Apache
            document_root => '/path/to/base/directory'
            ## Default error message to display when ssi failed to parse
            ## Default to [an error occurred while processing this directive]
            errmsg => '[Oops]'
        );
        my $fh = IO::File->new( "</some/file.html" ) || die( "$!\n" );
        $fh->binmode( ':utf8' );
        my $size = -s( $fh );
        my $html;
        $fh->read( $html, $size );
        $fh->close;
        if( !defined( my $result = $ssi->parse( $html ) ) )
        {
            $ssi->throw;
        };
        print( $result );

VERSION
=======

        v0.13.3

DESCRIPTION
===========

[Apache2::SSI](https://metacpan.org/pod/Apache2::SSI){.perl-module}
implements [Apache Server Side
Include](https://httpd.apache.org/docs/current/en/howto/ssi.html){.perl-module},
a.k.a. SSI.

[Apache2::SSI](https://metacpan.org/pod/Apache2::SSI){.perl-module} is
inspired from the original work of
[Apache::SSI](https://metacpan.org/pod/Apache::SSI){.perl-module} with
the difference that
[Apache2::SSI](https://metacpan.org/pod/Apache2::SSI){.perl-module}
works well when called from within Apache mod\_perl as well as when
called outside of Apache if you want to simulate
[SSI](https://httpd.apache.org/docs/current/en/howto/ssi.html){.perl-module}.

Under Apache mod\_perl, you would implement it like this in your
`apache2.conf` or `httpd.conf`

        <Files *.phtml>
            SetHandler modperl
            # Or if you are running mod_perl 1.0
            # SetHandler perl-script
            PerlHandler Apache2::SSI
        </Files>

This would enable
[Apache2::SSI](https://metacpan.org/pod/Apache2::SSI){.perl-module} for
files whose extension is `.phtml`. You can also limit this by location,
such as:

        <Location /some/web/path>
            <Files *.html>
                SetHandler modperl
                PerlHandler Apache2::SSI
            </Files>
        </Location>

As pointed out by Ken Williams, the original author of
[Apache::SSI](https://metacpan.org/pod/Apache::SSI){.perl-module}, the
benefit for using
[Apache2::SSI](https://metacpan.org/pod/Apache2::SSI){.perl-module} is:

1. You want to subclass [Apache2::SSI](https://metacpan.org/pod/Apache2::SSI){.perl-module} and have granular control on how to render ssi

:   

2. You want to \"parse the output of other mod\_perl handlers, or send the SSI output through another handler\"

:   

3. You want to mimick SSI without activating them or without using Apache (such as in command line)

:   

METHODS
=======

new
---

This instantiate an object that is used to access other key methods. It
takes the following parameters:

*apache\_request*

:   This is the
    [Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec){.perl-module}
    object that must be provided if running under mod\_perl.

    You can get this
    [Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec){.perl-module}
    object by requiring
    [Apache2::RequestUtil](https://metacpan.org/pod/Apache2::RequestUtil){.perl-module}
    and calling its class method [\"request\" in
    Apache2::RequestUtil](https://metacpan.org/pod/Apache2::RequestUtil#request){.perl-module}
    such as `Apache2::RequestUtil-`request\> and assuming you have set
    `PerlOptions +GlobalRequest` in your Apache Virtual Host
    configuration.

*document\_root*

:   This is only necessary to be provided if this is not running under
    Apache mod\_perl. Without this value,
    [Apache2::SSI](https://metacpan.org/pod/Apache2::SSI){.perl-module}
    has no way to guess the document root and will not be able to
    function properly and will return an
    [\"error\"](#error){.perl-module}.

*document\_uri*

:   This is only necessary to be provided if this is not running under
    Apache mod\_perl. This must be the uri of the document being served,
    such as `/my/path/index.html`. So, if you are using this outside of
    the rim of Apache mod\_perl and your file resides, for example, at
    `/home/john/www/my/path/index.html` and your document root is
    `/home/john/www`, then the document uri would be
    `/my/path/index.html`

*errmsg*

:   The error message to be returned when a ssi directive fails. By
    default, it is `[an error occurred while processing this directive]`

*html*

:   The html data to be parsed. You do not have to provide that value
    now. You can provide it to [\"parse\"](#parse){.perl-module} as its
    first argument when you call it.

*sizefmt*

:   The default way to format a file size. By default, this is `abbrev`,
    which means a human readable format such as `2.5M` for 2.5
    megabytes. Other possible value is `bytes` which would have the
    `fsize` ssi directive return the size in bytes.

*timefmt*

:   The default way to format a date time. By default, this uses the
    display according to your locale, such as `ja_JP` (for Japan) or
    `en_GB` for the United Kingdoms. The time zone can be specified in
    the format, or it will be set to the local time zone, whatever it
    is.

apache\_request
---------------

Sets or gets the
[Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec){.perl-module}
object. As explained in the [\"new\"](#new){.perl-module} method, you
can get this Apache object by requiring the package
[Apache2::RequestUtil](https://metacpan.org/pod/Apache2::RequestUtil){.perl-module}
and calling [\"request\" in
Apache2::RequestUtil](https://metacpan.org/pod/Apache2::RequestUtil#request){.perl-module}
such as `Apache2::RequestUtil-`request\> assuming you have set
`PerlOptions +GlobalRequest` in your Apache Virtual Host configuration.

decode\_base64
--------------

Decode base64 data provided. When running under Apache mod\_perl, this
uses [\"decode\" in
APR::Base64](https://metacpan.org/pod/APR::Base64#decode){.perl-module}
module, otherwise it uses [\"decode\" in
MIME::Base64](https://metacpan.org/pod/MIME::Base64#decode){.perl-module}

If the decoded data contain utf8 data, this will decoded the utf8 data
using [\"decode\" in
Encode](https://metacpan.org/pod/Encode#decode){.perl-module}

If an error occurred during decoding, it will return undef and set an
[\"error\"](#error){.perl-module} object accordingly.

decode\_entities
----------------

Decode html data containing entities. This uses [\"decode\_entities\" in
HTML::Entities](https://metacpan.org/pod/HTML::Entities#decode_entities){.perl-module}

If an error occurred during decoding, it will return undef and set an
[\"error\"](#error){.perl-module} object accordingly.

Example:

        $ssi->decode_entities( 'Tous les &Atilde;&ordf;tres humains naissent libres et &Atilde;&copy;gaux en dignit&Atilde;&copy; et en droits.' );
        # Tous les êtres humains naissent libres et égaux en dignité et en droits.

decode\_uri
-----------

Decode uri encoded data. This uses [\"uri\_unescape\" in
URI::Escape](https://metacpan.org/pod/URI::Escape#uri_unescape){.perl-module}.

Not to be confused with x-www-form-urlencoded data. For that see
[\"decode\_url\"](#decode_url){.perl-module}

If an error occurred during decoding, it will return undef and set an
[\"error\"](#error){.perl-module} object accordingly.

Example:

        $ssi->decode_uri( 'https%3A%2F%2Fwww.example.com%2F' );
        # https://www.example.com/

decode\_url
-----------

Decode x-www-form-urlencoded encoded data. When using Apache mod\_perl,
this uses [\"decode\" in
APR::Request](https://metacpan.org/pod/APR::Request#decode){.perl-module},
otherwise it uses [\"url\_decode\_utf8\" in
URL::Encode](https://metacpan.org/pod/URL::Encode#url_decode_utf8){.perl-module}
(its XS version)

If an error occurred during decoding, it will return undef and set an
[\"error\"](#error){.perl-module} object accordingly.

Example:

        $ssi->decode_url( 'Tous les &ecirc;tres humains naissent libres et &eacute;gaux en dignit&eacute; et en droits.' );
        # Tous les êtres humains naissent libres et égaux en dignité et en droits.

document\_directory
-------------------

Returns an
[Apache2::SSIFile](https://metacpan.org/pod/Apache2::SSIFile){.perl-module}
object of the current directory of the
[\"document\_uri\"](#document_uri){.perl-module} provided.

document\_filename
------------------

This returns the system file path to the document uri.

document\_root
--------------

Sets or gets the document root.

Wen running under Apache mod\_perl, this value will be available
automatically, using [\"document\_root\" in
Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec#document_root){.perl-module}
method.

If it runs outside of Apache, this will use the value provided upon
instantiating the object and passing the *document\_root* parameter. If
this is not set, it will return the value of the environment variable
`DOCUMENT_ROOT`.

document\_uri
-------------

Sets or gets the document uri, which is the uri of the document being
processed.

For example:

        /index.html

Under Apache, this will get the environment variable `DOCUMENT_URI` or
calls the [\"uri\" in
Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec#uri){.perl-module}
method.

Outside of Apache, this will rely on a value being provided upon
instantiating an object, or the environment variable `DOCUMENT_URI` be
present.

The value should be an absolute uri.

echomsg
-------

The default message to be returned for the `echo` command when the
variable called is not defined.

Example:

        $ssi->echomsg( '[Value Undefined]' );
        ## or in the document itself
        <!--#config echomsg="[Value Undefined]" -->
        <!--#echo var="NON_EXISTING" encoding="none" -->

would produce:

        [Value Undefined]

encode\_base64
--------------

Encode data provided into base64. When running under Apache mod\_perl,
this uses [\"encode\" in
APR::Base64](https://metacpan.org/pod/APR::Base64#encode){.perl-module}
module, otherwise it uses [\"encode\" in
MIME::Base64](https://metacpan.org/pod/MIME::Base64#encode){.perl-module}

If the data have the perl internal utf8 flag on as checked with
[\"is\_utf8\" in
Encode](https://metacpan.org/pod/Encode#is_utf8){.perl-module}, this
will encode the data into utf8 using [\"encode\" in
Encode](https://metacpan.org/pod/Encode#encode){.perl-module} before
encoding it into base64.

Please note that the base64 encoded resulting data is all on one line,
similar to what Apache would do. The data is **NOT** broken into lines
of 76 characters.

If an error occurred during encoding, it will return undef and set an
[\"error\"](#error){.perl-module} object accordingly.

encode\_entities
----------------

Encode data into html entities. This uses [\"encode\_entities\" in
HTML::Entities](https://metacpan.org/pod/HTML::Entities#encode_entities){.perl-module}

If an error occurred during encoding, it will return undef and set an
[\"error\"](#error){.perl-module} object accordingly.

Example:

        $ssi->encode_entities( 'Tous les êtres humains naissent libres et égaux en dignité et en droits.' );
        # Tous les &Atilde;&ordf;tres humains naissent libres et &Atilde;&copy;gaux en dignit&Atilde;&copy; et en droits.

encode\_uri
-----------

Encode uri data. This uses [\"uri\_escape\_utf8\" in
URI::Escape](https://metacpan.org/pod/URI::Escape#uri_escape_utf8){.perl-module}.

Not to be confused with x-www-form-urlencoded data. For that see
[\"encode\_url\"](#encode_url){.perl-module}

If an error occurred during encoding, it will return undef and set an
[\"error\"](#error){.perl-module} object accordingly.

Example:

        $ssi->encode_uri( 'https://www.example.com/' );
        # https%3A%2F%2Fwww.example.com%2F

encode\_url
-----------

Encode data provided into an x-www-form-urlencoded string. When using
Apache mod\_perl, this uses [\"encode\" in
APR::Request](https://metacpan.org/pod/APR::Request#encode){.perl-module},
otherwise it uses [\"url\_encode\_utf8\" in
URL::Encode](https://metacpan.org/pod/URL::Encode#url_encode_utf8){.perl-module}
(its XS version)

If an error occurred during decoding, it will return undef and set an
[\"error\"](#error){.perl-module} object accordingly.

Example:

        $ssi->encode_url( 'Tous les êtres humains naissent libres et égaux en dignité et en droits.' );
        # Tous les &ecirc;tres humains naissent libres et &eacute;gaux en dignit&eacute; et en droits.

errmsg
------

Sets or gets the error message to be displayed in lieu of a faulty ssi
directive. This is the same behaviour as in Apache.

error
-----

Retrieve the error object set. This is a
[Module::Generic::Error](https://metacpan.org/pod/Module::Generic::Error){.perl-module}
object.

This module does not die nor \"croak\", but instead returns undef when
an error occurs and set the error object.

find\_file
----------

Provided with a file path, and this will resolve any variable used and
attempt to look it up as a file if the argument *file* is provided with
a file path as a value, or as a URI if the argument `virtual` is
provided as an argument.

It returns a
[Apache2::SSIFile](https://metacpan.org/pod/Apache2::SSIFile){.perl-module}
object which is stringifyable and contain the file path.

html
----

Sets or gets the html data to be processed.

lookup\_file
------------

Provided with a file path and this will look up the file.

When using Apache, this will call [\"lookup\_file\" in
Apache2::SubRequest](https://metacpan.org/pod/Apache2::SubRequest#lookup_file){.perl-module}.
Outside of Apache, this will mimick Apache\'s lookup\_file method by
searching the file relative to the directory of the current document
being served, i.e. the [\"document\_uri\"](#document_uri){.perl-module}.

As per Apache SSI documentation, you cannot specify a path starting with
`/` or `../`

It returns a
[Apache2::SSIFile](https://metacpan.org/pod/Apache2::SSIFile){.perl-module}
object.

lookup\_uri
-----------

Provided with an uri, and this will loo it up and return a
[Apache2::SSIFile](https://metacpan.org/pod/Apache2::SSIFile){.perl-module}
object.

Under Apache mod\_perl, this uses [\"lookup\_uri\" in
Apache2::SubRequest](https://metacpan.org/pod/Apache2::SubRequest#lookup_uri){.perl-module}
to achieve that. Outside of Apache it will attempt to lookup the uri
relative to the document root if it is an absolute uri or to the current
document uri.

mod\_perl
---------

Returns true when running under mod\_perl, false otherwise.

parse
-----

Provided with html data and if none is provided will use the data
specified with the method [\"html\"](#html){.perl-module}, this method
will parse the html and process the ssi directives.

It returns the html string with the ssi result.

parse\_config
-------------

Provided with an hash reference of parameters and this sets three of the
object parameters that can also be set during object instantiation:

*errmsg*

:   The value is a message that is sent back to the client if the echo
    element attempts to echo an undefined variable.

    This overrides any default value set for the parameter *echomsg*
    upon object instantiation.

*errmsg*

:   This is the default error message to be used as the result for a
    faulty ssi directive.

    See the [\"errmsg\"](#errmsg){.perl-module} method.

*sizefmt*

:   This is the format to be used to format the files size. Value can be
    either `bytes` or `abbrev`

    See the [\"sizefmt\"](#sizefmt){.perl-module} method.

*timefmt*

:   This is the format to be used to format the dates and times. The
    value is a date formatting based on [\"strftime\" in
    POSIX](https://metacpan.org/pod/POSIX#strftime){.perl-module}

    See the [\"sizefmt\"](#sizefmt){.perl-module} method.

parse\_echo
-----------

Provided with an hash reference of parameter and this process the `echo`
ssi directive and returns its output as a string.

For example:

        Query string passed: <!--#echo var="QUERY_STRING" -->

There are a number of standard environment variable accessible under SSI
on top of other environment variables set. See [\"SSI
Directives\"](#ssi-directives){.perl-module}

parse\_echo\_date\_gmt
----------------------

Returns the current date with time zone set to gmt and based on the
provided format or the format available for the current locale such as
`ja_JP` or `en_GB`.

parse\_echo\_date\_local
------------------------

Returns the current date with time zone set to the local time zone
whatever that may be and on the provided format or the format available
for the current locale such as `ja_JP` or `en_GB`.

Example:

        <!--#echo var="DATE_LOCAL" -->

parse\_echo\_document\_name
---------------------------

Returns the document name. Under Apache, this returns the environment
variable `DOCUMENT_NAME`, if set, or the base name of the value returned
by [\"filename\" in
Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec#filename){.perl-module}

Outside of Apache, this returns the environment variable
`DOCUMENT_NAME`, if set, or the base name of the value for
[\"document\_uri\"](#document_uri){.perl-module}

Example:

        <!--#echo var="DOCUMENT_NAME" -->

parse\_echo\_document\_uri
--------------------------

Returns the value of [\"document\_uri\"](#document_uri){.perl-module}

Example:

        <!--#echo var="DOCUMENT_URI" -->

parse\_echo\_last\_modified
---------------------------

This returns document last modified date. Under Apache, there is a
standard environment variable called `LAST_MODIFIED` (see the section on
[\"SSI Directives\"](#ssi-directives){.perl-module}), and if somehow
absent, it will return instead the formatted last modification datetime
for the file returned with [\"filename\" in
Apache2::RequestRec](https://metacpan.org/pod/Apache2::RequestRec#filename){.perl-module}.
The formatting of that date follows whatever format provided with
[\"timefmt\"](#timefmt){.perl-module} or by default the datetime format
for the current locale (e.g. `ja_JP`).

Outside of Apache, the similar result is achieved by returning the value
of the environment variable `LAST_MODIFIED` if available, or the
formatted datetime of the document uri as set with
[\"document\_uri\"](#document_uri){.perl-module}

Example:

        <!--#echo var="LAST_MODIFIED" -->

parse\_exec
-----------

Provided with an hash reference of parameters and this process the
`exec` ssi directives.

Example:

        <!--#exec cgi="/uri/path/to/progr.cgi" -->

or

        <!--#exec cmd="/some/system/file/path.sh" -->

parse\_elif
-----------

Parse the `elif` condition.

Example:

        <!--#if expr=1 -->
         Hi, should print
        <!--#elif expr=1 -->
         Shouldn't print
        <!--#else -->
         Shouldn't print
        <!--#endif -->

parse\_else
-----------

Parse the `else` condition.

See [\"parse\_elif\"](#parse_elif){.perl-module} above for example.

parse\_endif
------------

Parse the `endif` condition.

See [\"parse\_elif\"](#parse_elif){.perl-module} above for example.

parse\_flastmod
---------------

Process the ssi directive `flastmod`

Provided with an hash reference of parameters and this will return the
formatted date time of the file last modification time.

parse\_fsize
------------

Provided with an hash reference of parameters and this will return the
formatted file size.

The output is affected by the value of
[\"sizefmt\"](#sizefmt){.perl-module}. If its value is `bytes`, it will
return the raw size in bytes, and if its value is `abbrev`, it will
return its value formated in kilo, mega or giga units.

Example

        <!--#config sizefmt="abbrev" -->
        This file size is <!--#fsize file="/some/filesystem/path/to/archive.tar.gz" -->

would return:

This file size is 12.7M

Or:

        <!--#config sizefmt="bytes" -->
        This file size is <!--#fsize virtual="/some/filesystem/path/to/archive.tar.gz" -->

would return:

This file size is 13,316,917 bytes

The size value before formatting is a
[Module::Generic::Number](https://metacpan.org/pod/Module::Generic::Number){.perl-module}
and the output is formatted using
[Number::Format](https://metacpan.org/pod/Number::Format){.perl-module}
by calling [\"format\" in
Module::Generic::Number](https://metacpan.org/pod/Module::Generic::Number#format){.perl-module}

parse\_func\_base64
-------------------

Returns the arguments provided into a base64 string.

If the arguments are utf8 data with perl internal flag on, as checked
with [\"is\_utf8\" in
Encode](https://metacpan.org/pod/Encode#is_utf8){.perl-module}, this
will encode the data into utf8 with [\"encode\" in
Encode](https://metacpan.org/pod/Encode#encode){.perl-module} before
encoding it into base64.

Example:

        <!--#set var="payload" value='{"sub":"1234567890","name":"John Doe","iat":1609047546}' encoding="base64" -->
        <!--#if expr="$payload == 'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNjA5MDQ3NTQ2fQo='" -->
        Payload matches
        <!--#else -->
        Sorry, this failed
        <!--#endif -->

parse\_func\_env
----------------

Return first match of
[note](https://metacpan.org/pod/note){.perl-module},
[reqenv](https://metacpan.org/pod/reqenv){.perl-module}, and
[osenv](https://metacpan.org/pod/osenv){.perl-module}

Example:

        <!--#if expr="env( $QUERY_STRING ) == /\bl=ja_JP/" -->
        Showing Japanese data
        <!--#else -->
        Defaulting to English
        <!--#endif -->

parse\_func\_escape
-------------------

Escape special characters in %hex encoding.

Example:

        <!--#set var="website" value="https://www.example.com/" -->
        Please go to <a href="<!--#echo var='website' encoding='escape' -->"><!--#echo var="website" --></a>

parse\_func\_http
-----------------

Get HTTP request header; header names may be added to the Vary header.

Example:

        <!--#if expr="http('X-API-ID') == 1234567" -->
        You're good to go.
        <!--#endif -->

parse\_func\_ldap
-----------------

Escape characters as required by LDAP distinguished name escaping
(RFC4514) and LDAP filter escaping (RFC4515).

See [Apache
documentation](https://httpd.apache.org/docs/trunk/en/expr.html#page-header){.perl-module}
for more information

Example:

        <!--#set var="phrase" value="%{ldap:'Tous les êtres humains naissent libres (et égaux) en dignité et\ en\ droits.\n'}" -->
        # Tous les êtres humains naissent libres \28et égaux\29 en dignité et\5c en\5c droits.\5cn

parse\_func\_md5
----------------

Hash the string using MD5, then encode the hash with hexadecimal
encoding.

If the arguments are utf8 data with perl internal flag on, as checked
with [\"is\_utf8\" in
Encode](https://metacpan.org/pod/Encode#is_utf8){.perl-module}, this
will encode the data into utf8 with [\"encode\" in
Encode](https://metacpan.org/pod/Encode#encode){.perl-module} before
encoding it with md5.

Example:

        <!--#if expr="md5( $hash_data ) == '2f50e645b6ef04b5cfb76aed6de343eb'" -->
        You're good to go.
        <!--#endif -->

parse\_func\_note
-----------------

Lookup request note

        <!--#set var="CUSTOMER_ID" value="1234567" -->
        <!--#if expr="note('CUSTOMER_ID') == 1234567" -->
        Showing special message
        <!--#endif -->

parse\_func\_osenv
------------------

Lookup operating system environment variable

        <!--#if expr="env('LANG') =~ /en(_(GB|US))/" -->
        Showing English language
        <!--#endif -->

parse\_func\_replace
--------------------

replace(string, \"from\", \"to\") replaces all occurrences of \"from\"
in the string with \"to\".

Example:

        <!--#if expr="replace( 'John is in Tokyo', 'John', 'Jack' ) == 'Jack is in Tokyo'" -->
        This worked!
        <!--#else -->
        Nope, it failed.
        <!--#endif -->

parse\_func\_req
----------------

See [\"parse\_func\_http\"](#parse_func_http){.perl-module}

parse\_func\_reqenv
-------------------

Lookup request environment variable (as a shortcut, v can also be used
to access variables).

This is only different from
[\"parse\_func\_env\"](#parse_func_env){.perl-module} under Apache.

See [\"parse\_func\_env\"](#parse_func_env){.perl-module}

Example:

        <!--#if expr="reqenv('ProcessId') == '$$'" -->
        This worked!
        <!--#else -->
        Nope, it failed.
        <!--#endif -->

parse\_func\_req\_novary
------------------------

Same as [\"parse\_func\_req\"](#parse_func_req){.perl-module}, but
header names will not be added to the Vary header.

parse\_func\_resp
-----------------

Get HTTP response header.

Example:

        <!--#if expr="resp('X-ProcessId') == '$$'" -->
        This worked!
        <!--#else -->
        Nope, it failed.
        <!--#endif -->

parse\_func\_sha1
-----------------

Hash the string using SHA1, then encode the hash with hexadecimal
encoding.

Example:

        <!--#if expr="sha1('Tous les êtres humains naissent libres et égaux en dignité et en droits.') == '8c244078c64a51e8924ecf646df968094a818d59'" -->
        This worked!
        <!--#else -->
        Nope, it failed.
        <!--#endif -->

parse\_func\_tolower
--------------------

Convert string to lower case.

Example:

        <!--#if expr="tolower('Tous les êtres humains naissent libres et égaux en dignité et en droits.') == 'tous les êtres humains naissent libres et égaux en dignité et en droits.'" -->
        This worked!
        <!--#else -->
        Nope, it failed.
        <!--#endif -->

parse\_func\_toupper
--------------------

Convert string to upper case.

Example:

        <!--#if expr="toupper('Tous les êtres humains naissent libres et égaux en dignité et en droits.') == 'TOUS LES ÊTRES HUMAINS NAISSENT LIBRES ET ÉGAUX EN DIGNITÉ ET EN DROITS.'" -->
        This worked!
        <!--#else -->
        Nope, it failed.
        <!--#endif -->

parse\_func\_unbase64
---------------------

Decode base64 encoded string, return truncated string if 0x00 is found.

Example:

        <!--#if expr="unbase64('VG91cyBsZXMgw6p0cmVzIGh1bWFpbnMgbmFpc3NlbnQgbGlicmVzIGV0IMOpZ2F1eCBlbiBkaWduaXTDqSBldCBlbiBkcm9pdHMu') == 'Tous les êtres humains naissent libres et égaux en dignité et en droits.'" -->
        This worked!
        <!--#else -->
        Nope, it failed.
        <!--#endif -->

parse\_func\_unescape
---------------------

Unescape %hex encoded string, leaving encoded slashes alone; return
empty string if %00 is found.

Example:

        <!--#if expr="unescape('https%3A%2F%2Fwww.example.com%2F') == 'https://www.example.com/'" -->
        This worked!
        <!--#else -->
        Nope, it failed.
        <!--#endif -->

parse\_if
---------

Parse the `if` condition.

See [\"parse\_elif\"](#parse_elif){.perl-module} above for example.

parse\_include
--------------

Provided with an hash reference of parameters and this process the ssi
directive `include`, which is arguably the most used.

It will try to resolve the file to include by calling
[\"find\_file\"](#find_file){.perl-module} with the same arguments this
is called with.

Under Apache, if the previous look up succeeded, it calls [\"run\" in
Apache2::SubRequest](https://metacpan.org/pod/Apache2::SubRequest#run){.perl-module}

Outside of Apache, it reads the entire file, utf8 decode it and return
it.

parse\_perl
-----------

Provided with an hash reference of parameters and this parse some perl
command and returns the output as a string.

Example:

        <!--#perl sub="sub{ print 'Hello!' }" -->

or

        <!--#perl sub="package::subroutine" -->

parse\_printenv
---------------

This returns a list of environment variables sorted and their values.

parse\_set
----------

Provided with an hash reference of parameters and this process the ssi
directive `set`.

Possible parameters are:

*decoding*

:   The decoding of the variable before it is set. This can be `none`,
    `url`, `urlencoded`, `base64` or `entity`

*encoding*

:   This instruct to encode the variable value before display. It can
    the same possible value as for decoding.

*value*

:   The string value for the variable to be set.

*var*

:   The variable name

Example:

        <!--#set var="debug" value="2" -->
        <!--#set decoding="entity" var="HUMAN_RIGHT" value="Tous les &Atilde;&ordf;tres humains naissent libres et &Atilde;&copy;gaux en dignit&Atilde;&copy; et en droits." encoding="urlencoded" -->

See the [Apache SSI
documentation](https://httpd.apache.org/docs/current/en/mod/mod_include.html){.perl-module}
for more information.

parse\_ssi
----------

Provided with the html data as a string and this will parse its embedded
ssi directives and return its output as a string.

If it fails, it sets an [\"error\"](#error){.perl-module} and returns an
empty string.

remote\_ip
----------

Sets or gets the remote ip address of the visitor.

Under Apache mod\_perl, this will call [\"remote\_ip\" in
Apache2::Connection](https://metacpan.org/pod/Apache2::Connection#remote_ip){.perl-module},
and otherwise this will get the value from the environment variable
`REMOTE_ADDR`

This value can also be overriden by being provided during object
instantiation.

        # Pretend the ssi directives are accessed from this ip
        $ssi->remote_ip( '192.1.68.2.20' );

This is useful when one wants to check how the rendering will be when
accessed from certain ip addresses.

This is used primarily when there is an expression such as

        <!--#if expr="-R '192.168.1.0/24' -->
        Visitor is part of my private network
        <!--#endif -->

or

        <!--#if expr="v('REMOTE_ADDR') -R '192.168.1.0/24' -->
        <!--#include file="/home/john/special_hidden_login_feature.html" -->
        <!--#endif -->

sizefmt
-------

Sets or gets the formatting for file sizes. Value can be either `bytes`
or `abbrev`

timefmt
-------

Sets or gets the formatting for date and time values. The format takes
the same values as [\"strftime\" in
POSIX](https://metacpan.org/pod/POSIX#strftime){.perl-module}

SSI Directives
==============

config
------

        <!--#config errmsg="Error occurred" sizefmt="abbrev" timefmt="%B %Y" -->
        <!--#config errmsg="Oopsie" -->
        <!--#config sizefmt="bytes" -->
        # Thursday 24 December 2020
        <!--#config timefmt="%A $d %B %Y" -->

echo
----

         <!--#set var="HTMl_TITLE" value="Un sujet intéressant" -->
         <!--#echo var="HTMl_TITLE" encoding="entity" -->

Encoding can be either `entity`, `url` or `none`

exec
----

        # pwd is "print working directory" in shell
        <!--#exec cmd="pwd" -->
        <!--#exec cgi="/uri/path/to/prog.cgi" -->

include
-------

        # Filesystem file path
        <!--#include file="/home/john/var/quote_of_the_day.txt" -->
        # Relative to the document root
        <!--#include virtual="/footer.html" -->

flastmod
--------

         <!--#flastmod file="/home/john/var/quote_of_the_day.txt" -->
         <!--#flastmod virtual="/copyright.html" -->

fsize
-----

        <!--#fsize file="/download/software-v1.2.tgz" -->
        <!--#fsize virtual="/images/logo.jpg" -->

printenv
--------

        <!--#printenv -->

set
---

        <!--#set var="debug" value="2" -->

if, elif, endif and else
------------------------

        <!--#if expr="$debug > 1" -->
        I will print a lot of debugging
        <!--#else -->
        Debugging output will be reasonable
        <!--#endif -->

or with new version of Apache SSI:

        No such file or directory.
        <!--#if expr="v('HTTP_REFERER') != ''" -->
        Please let the admin of the <a href="<!--#echo encoding="url" var="HTTP_REFERER" -->"referring site</a> know about their dead link.
        <!--#endif -->

functions
---------

Apache SSI supports the following functions, as of Apache version 2.4.

See [Apache
documentation](https://httpd.apache.org/docs/current/en/expr.html#page-header){.perl-module}
for detailed description of what they do.

You can also refer to the methods `parse_func_*` documented above, which
implement those Apache functions.

*base64*

:   

*env*

:   

*escape*

:   

*http*

:   

*ldap*

:   

*md5*

:   

*note*

:   

*osenv*

:   

*replace*

:   

*req*

:   

*reqenv*

:   

*basereq\_novary64*

:   

*resp*

:   

*sha1*

:   

*tolower*

:   

*toupper*

:   

*unbase64*

:   

*unescape*

:   

variables
---------

On top of all environment variables available, Apache makes the
following ones also accessible:

DATE\_GMT

:   

DATE\_LOCAL

:   

DOCUMENT\_ARGS

:   

DOCUMENT\_NAME

:   

DOCUMENT\_PATH\_INFO

:   

DOCUMENT\_URI

:   

LAST\_MODIFIED

:   

QUERY\_STRING\_UNESCAPED

:   

USER\_NAME

:   

See [Apache
documentation](https://httpd.apache.org/docs/current/en/mod/mod_include.html#page-header){.perl-module}
and [this page
too](https://httpd.apache.org/docs/current/en/expr.html#page-header){.perl-module}
for more information.

expressions
-----------

There is reasonable, but limited support for Apache expressions. For
example, the followings are supported

In the examples below, we use the variable `QUERY_STRING`, but you can
use any other variable of course.

The regular expression are the ones PCRE compliant, so your perl regular
expressions should work.

        <!--#if expr="$QUERY_STRING = 'something'" -->
        <!--#if expr="v('QUERY_STRING') = 'something'" -->
        <!--#if expr="%{QUERY_STRING} = 'something'" -->
        <!--#if expr="$QUERY_STRING = /^something/" -->
        <!--#if expr="$QUERY_STRING == /^something/" -->
        # works also with eq, ne, lt, le, gt and ge
        <!--#if expr="9 gt 3" -->
        <!--#if expr="9 -gt 3" -->
        # Other operators work too, namely == != < <= > >= =~ !~
        <!--#if expr="9 > 3" -->
        <!--#if expr="9 !> 3" -->
        <!--#if expr="9 !gt 3" -->
        # Checks the remote ip is part of this subnet
        <!--#if expr="-R 192.168.2.0/24" -->
        <!--#if expr="192.168.2.10 -R 192.168.2.0/24" -->
        <!--#if expr="192.168.2.10 -ipmatch 192.168.2.0/24" -->
        # Checks if variable is non-empty
        <!--#if expr="-n $some_variable" -->
        # Checks if variable is empty
        <!--#if expr="-z $some_variable" -->
        # Checks if the visitor can access the uri /restricted/uri
        <!--#if expr="-A /restricted/uri" -->

For subnet checks, this uses
[Net::Subnet](https://metacpan.org/pod/Net::Subnet){.perl-module}

Expressions that would not work out side of Apache:

        <!--#expr="%{HTTP:X-example-header} in { 'foo', 'bar', 'baz' }" -->

See [Apache
documentation](http://httpd.apache.org/docs/2.4/en/expr.html){.perl-module}
for more information.

CREDITS
=======

Credits to Ken Williams for his implementation of
[Apache::SSI](https://metacpan.org/pod/Apache::SSI){.perl-module} from
which I borrowed code.

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55ed2c5198a0)"}\>

CPAN ID: jdeguest

<https://git.deguest.jp/jack/Apache2-SSI>

SEE ALSO
========

mod\_include, mod\_perl(3),
[Apache::SSI](https://metacpan.org/pod/Apache::SSI){.perl-module},
<https://httpd.apache.org/docs/current/en/mod/mod_include.html>,
<https://httpd.apache.org/docs/current/en/howto/ssi.html>,
<https://httpd.apache.org/docs/current/en/expr.html>
<https://perl.apache.org/docs/2.0/user/handlers/filters.html#C_PerlOutputFilterHandler_>

COPYRIGHT & LICENSE
===================

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
