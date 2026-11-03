[![Actions Status](https://github.com/nigelhorne/CGI-Buffer/workflows/.github/workflows/all.yml/badge.svg)](https://github.com/nigelhorne/CGI-Buffer/actions)
[![Travis Status](https://travis-ci.org/nigelhorne/CGI-Buffer.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-Buffer)
[![Appveyor status](https://ci.appveyor.com/api/projects/status/2uhepmj5sd1nspjg?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-buffer)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/CGI-Buffer/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-Buffer?branch=master)
[![CPAN](https://img.shields.io/cpan/v/CGI-Buffer.svg)](http://search.cpan.org/~nhorne/CGI-Buffer/)
<!--
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/)
-->
[![Kwalitee](https://cpants.cpanauthors.org/dist/CGI-Buffer.png)](http://cpants.cpanauthors.org/dist/CGI-Buffer)

## Name

CGI::Buffer - Verify, Cache and Optimise CGI Output

## Version

Version 0.89

## Synopsis

CGI::Buffer verifies the HTML that you produce by passing it through
`HTML::Lint`.

CGI::Buffer optimises CGI programs by reducing, filtering and compressing
output to speed up the transmission and by nearly seamlessly making use of
client and server caches.

To make use of client caches, that is to say to reduce needless calls
to your server asking for the same data, all you need to do is to
include the package, and it does the rest.

```perl
use CGI::Buffer;
# ...
```

To also make use of server caches, that is to say to save regenerating
output when different clients ask you for the same data, you will need
to create a cache.
But that's simple:

```perl
use CHI;
use CGI::Buffer;

# Put this at the top before you output anything
if(CGI::Buffer::init(cache => CHI->new(driver => 'File'))->is_cached()) {
    # Nothing has changed - use the version in the cache
    exit;
}

# ...
```

To temporarily prevent the use of server-side caches, for example whilst
debugging before publishing a code change, set the NO\_CACHE environment variable
to any non-zero value.
If you get errors about Wide characters in print it means that you've
forgotten to emit pure HTML on non-ASCII characters.
See [HTML::Entities](https://metacpan.org/pod/HTML%3A%3AEntities).
As a hack work around you could also remove accents and the like by using
[Text::Unidecode](https://metacpan.org/pod/Text%3A%3AUnidecode),
which works well but isn't really what you want.

### How the Output Is Sent

When the script ends, CGI::Buffer:

- optimises (`optimise_content`) and checks (`lint_content`) HTML;
- answers conditional requests (If-None-Match, If-Modified-Since) with
304, or 412 for methods other than GET and HEAD;
- answers a single byte Range with 206, or 416 if it can't be met, when
there's no server-side cache;
- compresses with the first encoding in Accept-Encoding that it can
produce (gzip, br or zstd);
- stores the output in, or sends it from, the server-side cache;
- sends one Status header, and a Content-Length worked out from what is
actually sent.

If any of that fails, a warning is given and the output is sent as the script
printed it.

## Subroutines/Methods

### Init

Set various options and override default values.

#### Purpose

Configures CGI::Buffer.  Options which affect the server-side cache must be given
before anything is printed; the others can be given at any time before the
script ends.

#### Arguments

A hash or a hash reference of options, any of which may be left out:

- `generate_etag` - send an ETag, and answer If-None-Match with 304.
By default, on if the protocol is HTTP/1.1 or later.
- `generate_last_modified` - send a Last-Modified header, default on.
It needs a cache or an `info` object.
- `generate_304` - answer conditional requests with 304, default on.
- `compress_content` - compress the output if the client accepts it,
default on.
- `optimise_content` - 0 (default) leaves HTML alone, 1 optimises the
HTML and CSS, 2 also does aggressive JavaScript optimisations which may fail.
- `lint_content` - check the HTML with [HTML::Lint](https://metacpan.org/pod/HTML%3A%3ALint), default off.
Errors are sent to the client as a 500, so only use this when developing.
- `cache` - a server-side cache: an object that understands get\_object(),
set(), get() and remove(), whose objects understand value() and created\_at(),
such as a [CHI](https://metacpan.org/pod/CHI) object.  Undef turns the cache off.
- `cache_key` - the key for this page in the cache.  If not given, one
is generated which may not be unique.  It should be a unique value dependent
upon the values set by the browser.
- `cache_duration` - how long to keep pages in the cache, default
'10 minutes'.  `cache_age` is an old name for this.
- `logger` - an object that understands trace(), debug(), info(),
warn() and error(), such as a [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) logger.
- `lingua` - a [CGI::Lingua](https://metacpan.org/pod/CGI%3A%3ALingua) object; the language becomes part of the
generated cache key.
- `info` - a [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) object.  One is created when needed if it isn't
given.  It's only taken from the first call.
- `messages` - a hash of message keys to replacement text, e.g. to
translate the messages, see ["MESSAGES"](#messages).

Items stay in the server-side cache by default for 10 minutes.
This can be overridden by the max-age directive of the Cache-Control HTTP header
in the request, if it's a number no larger than 600 seconds, and
the default can be changed by the cache\_duration argument to init().

Responses aren't stored in the server-side cache if their headers include
Set-Cookie,
a Cache-Control of no-store, no-cache or private,
or a Vary on anything other than Accept-Encoding
(or Accept-Language when lingua is given),
since they would be given to clients that they weren't meant for.
Neither are HTML pages with no &lt;/html>,
which suggests that the script died.
A page that includes the value of the client's `csrf_token` cookie is never
stored.
The `csrf_token` and Google Analytics cookies aren't part of the generated
cache key, other cookies and PATH\_INFO are.

#### Returns

The string 'CGI::Buffer', so that calls can be chained, e.g.
`CGI::Buffer::init(...)->is_cached()`.

#### Side Effects

Sets the options for the rest of the request.
Gives a warning for each unknown or invalid option, which is ignored,
and if the cache is given after output has started.

#### Example

```perl
# Put this toward the top of your program before you do anything
use CHI;
use CGI::Lingua;
use CGI::Buffer;

CGI::Buffer::init(
    generate_etag => 1,     # make good use of client's cache
    generate_last_modified => 1,    # more use of client's cache
    compress_content => 1,  # gzip the output
    optimise_content => 0,  # optimise your program's HTML, CSS and JavaScript
    cache => CHI->new(driver => 'File'),    # cache requests
    cache_key => 'string',  # key for the cache
    cache_duration => '10 minutes', # how long to store responses in the cache
    logger => $logger,
    lint_content => 0,      # Pass through HTML::Lint
    generate_304 => 1,      # Generate 304: Not modified
    lingua => CGI::Lingua->new(supported => ['en']),
);
```

Init allows a reference of the options to be passed. So both of these work:

```perl
CGI::Buffer::init(generate_etag => 1);
CGI::Buffer::init({ generate_etag => 1, info => CGI::Info->new() });
```

Generally speaking, passing by reference is better since it copies less on to
the stack.

Alternatively you can give the options when loading the package:

```perl
use CGI::Buffer { optimise_content => 1 };
```

#### Api Specification

##### Input

```perl
    {
            generate_etag => { type => 'boolean', optional => 1 },
            generate_last_modified => { type => 'boolean', optional => 1 },
            generate_304 => { type => 'boolean', optional => 1 },
            compress_content => { type => 'boolean', optional => 1 },
            lint_content => { type => 'boolean', optional => 1 },
            optimise_content => { type => 'integer', min => 0, optional => 1 },
            cache => { type => 'object', can => ['get_object', 'set'], optional => 1 },
            cache_key => { type => 'string', optional => 1 },
            cache_duration => { type => 'string', optional => 1 },
            cache_age => { type => 'string', optional => 1 },
            logger => { type => 'object', can => ['trace', 'debug', 'info', 'warn', 'error'], optional => 1 },
            lingua => { type => 'object', can => 'language', optional => 1 },
            info => { type => 'object', can => ['status', 'host_name'], optional => 1 },
            messages => { type => 'hashref', optional => 1 },
    }
```

##### Output

```perl
    { type => 'string', value => 'CGI::Buffer' }
```

#### Messages

```
Key             Meaning                                   Resolution
--------------  ----------------------------------------  ---------------------------------
unknown_option  An option that init() doesn't know about  Check the spelling, see above
bad_option      An option of the wrong type               Pass the type listed above
logger_method   The logger lacks a method, so is ignored  Use a logger with all five methods
too_late        The cache was set up after printing       Call init() before printing
```

#### Formal Specification

```
┌─ Init ──────────────────────────────────────────────┐
│ ΔOptions                                            │
│ params? : OPTION ⇸ VALUE                            │
│ printed : ℕ                                         │
│ result! : STRING                                    │
├─────────────────────────────────────────────────────┤
│ valid == { o : dom params? | o ∈ dom INIT_OPTIONS ∧ │
│            params?(o) ∈ INIT_OPTIONS(o) }           │
│ ∀ o : valid \ {cache} • options'(o) = params?(o)    │
│ cache ∈ valid ∧ params?(cache) = ⊥ ⇒                │
│     options'(cache) = ⊥                             │
│ cache ∈ valid ∧ params?(cache) ≠ ⊥ ∧ can_cache ⇒    │
│     options'(cache) = params?(cache)                │
│ result! = "CGI::Buffer"                             │
└─────────────────────────────────────────────────────┘
```

#### Pseudocode

```perl
get the options from a hash or a hash reference
for each option
    warn about, and drop, those that are unknown or of the wrong type
replace any messages first, so that the warnings below use them
set each option that can be changed at any time
if anything has been printed, warn that it's too late
if the cache option was given
    if it's undef, turn the cache off
    else if this request may use the cache
        work out how long to keep pages for
        remember the cache and its key
return 'CGI::Buffer'
```

### Set\_Options

Synonym for init, kept for historical reasons.

#### Purpose, Arguments, Returns and Side Effects

As for ["init"](#init).

#### Example

```perl
CGI::Buffer::set_options(optimise_content => 1);
```

#### Api Specification

##### Input

As for ["init"](#init).

##### Output

```perl
    { type => 'string', value => 'CGI::Buffer' }
```

#### Messages

As for ["init"](#init).

#### Formal Specification

```
SetOptions ≙ Init
```

### Can\_Cache

Returns true if the server is allowed to store the results locally.

#### Purpose

Says whether this request may use the server-side cache.
The cache isn't used if the NO\_CACHE or NO\_STORE environment variables are set,
if the request method isn't GET or HEAD,
if the client has logged in (the Authorization header or REMOTE\_USER is set),
or if the client's Cache-Control header includes any of no-store, no-cache,
private or max-age=0.

#### Arguments

None.

#### Returns

1 if the cache may be used, otherwise 0.

#### Side Effects

The answer is decided on the first call, and doesn't change for the rest of the
request.

#### Example

```perl
if(CGI::Buffer::can_cache()) {
    CGI::Buffer::init(cache => CHI->new(driver => 'File'));
}
```

#### Api Specification

##### Input

None.

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

None.

#### Formal Specification

```
┌─ CanCache ──────────────────────────────────────────┐
│ ΞEnvironment                                        │
│ result! : 𝔹                                         │
├─────────────────────────────────────────────────────┤
│ result! = true ⇔                                    │
│   {NO_CACHE, NO_STORE, HTTP_AUTHORIZATION,          │
│    REMOTE_USER} ∩ dom env = ∅ ∧                     │
│   (REQUEST_METHOD ∉ dom env ∨                       │
│    env(REQUEST_METHOD) ∈ {GET, HEAD}) ∧             │
│   directives(env(HTTP_CACHE_CONTROL)) ∩             │
│    {no-store, no-cache, private, max-age=0} = ∅     │
└─────────────────────────────────────────────────────┘
```

### Is\_Cached

Returns true if the output is cached. If it is then it means that all of the
expensive routines in the CGI script can be by-passed because we already have
the result stored in the cache.

#### Purpose

Says whether the page is in the server-side cache, in which case the script can
exit without printing anything, and the cached copy is sent.

#### Arguments

None.  Any that are given, e.g. the class name when chained after init(), are
ignored.

#### Returns

1 if the page is in the cache, otherwise 0.

An entry that has expired isn't cached,
and neither is any entry if the script's file has changed since,
or if the age of the script can't be determined.
If the cache fails, a warning is given and the output isn't cached.

#### Side Effects

Remembers the cache entry for when the output is sent.
An entry made before the script was last changed is removed from the cache.

#### Example

```perl
# Put this toward the top of your program before you do anything

# Example key generation - use whatever you want as something
# unique for this call, so that subsequent calls with the same
# values match something in the cache
use CGI::Info;
use CGI::Lingua;
use CGI::Buffer;

my $i = CGI::Info->new();
my $l = CGI::Lingua->new(supported => ['en']);

# To use server side caching you must give the cache argument, however
# the cache_key argument is optional - if you don't give one then one will
# be generated for you
if(CGI::Buffer::can_cache()) {
    CGI::Buffer::init(
        cache => CHI->new(driver => 'File'),
        cache_key => $i->domain_name() . '/' . $i->script_name() . '/' . $i->as_string() . '/' . $l->language()
    );
    if(CGI::Buffer::is_cached()) {
        # Output will be retrieved from the cache and sent automatically
        exit;
    }
}
# Not in the cache, so now do our expensive computing to generate the
# results
print "Content-type: text/html\n";
# ...
```

#### Api Specification

##### Input

None.

##### Output

```perl
    { type => 'boolean' }
```

#### Messages

```
Key             Meaning                                   Resolution
--------------  ----------------------------------------  ---------------------------------
failed          The cache couldn't be read                Check the cache's configuration
no_script_path  CGI::Info can't find the script (fatal)   Check SCRIPT_FILENAME/SCRIPT_NAME
no_script_age   The script's file can't be read (logged)  Check the script's permissions
```

#### Formal Specification

```
┌─ IsCached ──────────────────────────────────────────┐
│ ΞCache                                              │
│ key : KEY                                           │
│ script_mtime : TIME                                 │
│ now : TIME                                          │
│ result! : 𝔹                                         │
├─────────────────────────────────────────────────────┤
│ result! = true ⇔                                    │
│   key ∈ dom cache ∧                                 │
│   cache(key).value ≠ ⊥ ∧                            │
│   cache(key).expires_at > now ∧                     │
│   script_mtime ≤ cache(key).created_at              │
└─────────────────────────────────────────────────────┘
```

#### Pseudocode

```
if there's no cache, the page isn't cached
look up the key, ignoring expired entries and a failing cache
if there's no entry, or it has no data, the page isn't cached
if the script's age can't be found, the page isn't cached
if the script has changed since the entry was made
    remove the entry, the page isn't cached
otherwise the page is cached
```

## Messages

Every message that CGI::Buffer gives starts with "CGI::Buffer: ".
Each can be replaced, for example to translate it, by giving init() a
`messages` hash.
Placeholders are written `%{name}` followed by a sprintf conversion, e.g.
`%{key}s`.
A message may instead be a hash of plural forms, `one` and `other`, chosen by
its count.

```perl
CGI::Buffer::init(messages => {
    unknown_option => 'init: option inconnue %{option}s ignoree',
    too_late => {
        one => 'Trop tard, %{count}d caractere a ete imprime',
        other => 'Trop tard, %{count}d caracteres ont ete imprimes',
    },
});

Key             Placeholders      Meaning
--------------  ----------------  ------------------------------------------
too_late        count             The cache was set up after printing
unknown_option  option            init() was given an option it doesn't know
bad_option      option, reason    init() was given an option of the wrong type
failed          what, error       Something non-essential, e.g. the cache, failed
no_cache_data   key               The page was cached, but now can't be read
no_cache_body   key, fields       A cache entry has no body, so is removed
logger_method   method            The logger lacks a method, so is ignored
no_script_path  -                 CGI::Info can't find the script (fatal)
no_script_age   path, error       The script's file can't be read (logged)
no_info         -                 A CGI::Info object can't be created (fatal)
send_failed     error             Processing the output failed; it's sent as is
lint            where, text       An error found by HTML::Lint
```

None of the messages refers to a person, so there are no gendered forms.

## Limitations

- All of the state is in package variables, and the work is done in an
END block.
That fits CGI, where each request is a new process, but it means CGI::Buffer
can't be used for more than one request, can't be reset, and can only be tested
by running a script in another process.
[FCGI::Buffer](https://metacpan.org/pod/FCGI%3A%3ABuffer) is the object-oriented version for persistent processes.
- HTML is optimised with regular expressions, not an HTML parser.
They are written to run in linear time and to leave `<pre>` and
`<textarea>` alone, but HTML that's unusual enough can still be changed in
ways that are visible, e.g. whitespace in an element styled with
`white-space: pre`.
[HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker) can take quadratic time on many unterminated `<script>`
tags.
- Links to this site are shortened to absolute paths
(`/foo/bar.htm`), not relative ones (`../bar.htm`).
Relative links would save a few more bytes, but break pages that use
`<base href>`, and pages reached through more than one path.
- Only one byte range is supported, and Range is ignored when there's a
server-side cache.
- The server-side cache key can't include headers named by Vary, since
it's needed before the script prints them; such pages aren't stored.
- Only HTML is checked for having been cut short by the script dying.
- lint\_content sends HTML::Lint's errors to the client, and the
X-CGI-Buffer header gives the version of CGI::Buffer.
Neither should be relied upon in production.
- init()'s options are checked by hand, rather than with
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict), and private routines are private by convention
rather than enforced with [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate).
Both add about 50ms to every request, since a CGI program is compiled afresh
each time.
For the same reason CGI::Info is only loaded when it's needed, so a script that
uses CGI::Info must load it itself.
- The server-side cache's duration isn't taken from the Expires or
Cache-Control: max-age headers that the script gives.

## Author

Nigel Horne, `<njh at bandsman.co.uk>`

## Bugs

CGI::Buffer should be safe even in scripts which produce lots of different
output, e.g. e-commerce situations.
On such pages, however, I strongly urge to setting generate\_304 to 0 and
sending the HTTP header "Cache-Control: no-cache".

When using [Template](https://metacpan.org/pod/Template), ensure that you don't use it to output to STDOUT,
instead you will need to capture into a variable and print that.
For example:

```perl
my $output;
$template->process($input, $vars, \$output) || ($output = $template->error());
print $output;
```

Can produce buggy JavaScript if you use the &lt;!-- HIDING technique.
This is a bug in [JavaScript::Packer](https://metacpan.org/pod/JavaScript%3A%3APacker), not CGI::Buffer.
See https://github.com/nevesenin/javascript-packer-perl/issues/1#issuecomment-4356790

Mod\_deflate can confuse this when compressing output.
Ensure that deflation is off for .pl files:

```
SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|pl)$ no-gzip dont-vary
```

If-None-Match uses the weak comparison of RFC 9110, so a client that has the
compressed version of a page is sent a 304 when it asks for the uncompressed
one, and vice versa.

I advise adding CGI::Buffer as the last use statement so that it is
cleared up first.  In particular it should be loaded after
[Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl), if you're using that, so that any messages it
produces are printed after the HTTP headers have been sent by
CGI::Buffer;

CGI::Buffer is not compatible with FastCGI, use [FCGI::Buffer](https://metacpan.org/pod/FCGI%3A%3ABuffer) instead.

Please report any bugs or feature requests to `bug-cgi-buffer at rt.cpan.org`,
or through the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Buffer](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Buffer).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

## See Also

[HTML::Packer](https://metacpan.org/pod/HTML%3A%3APacker), [HTML::Lint](https://metacpan.org/pod/HTML%3A%3ALint), [FCGI::Buffer](https://metacpan.org/pod/FCGI%3A%3ABuffer)

## Support

You can find documentation for this module with the perldoc command.

```
perldoc CGI::Buffer
```

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/CGI-Buffer](https://metacpan.org/release/CGI-Buffer)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Buffer](https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Buffer)

- CPANTS

    [http://cpants.cpanauthors.org/dist/CGI-Buffer](http://cpants.cpanauthors.org/dist/CGI-Buffer)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=CGI-Buffer](http://matrix.cpantesters.org/?dist=CGI-Buffer)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=CGI::Buffer](http://deps.cpantesters.org/?module=CGI::Buffer)

## Acknowledgements

The inspiration and code for some of this is cgi\_buffer by Mark
Nottingham: [https://www.mnot.net/blog/2003/04/24/etags](https://www.mnot.net/blog/2003/04/24/etags).

## License and Copyright

The licence for cgi\_buffer is:

```
"(c) 2000 Copyright Mark Nottingham <mnot@pobox.com>

This software may be freely distributed, modified and used,
provided that this copyright notice remain intact.

This software is provided 'as is' without warranty of any kind."
```

The rest of the program is Copyright 2011-2026 Nigel Horne,
and is released under the following licence: GPL2
