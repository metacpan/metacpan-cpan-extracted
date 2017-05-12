[![Linux Build Status](https://travis-ci.org/nigelhorne/CGI-Buffer.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-Buffer)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/2uhepmj5sd1nspjg?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-buffer)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/CGI-Buffer/badge)](https://dependencyci.com/github/nigelhorne/CGI-Buffer)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/CGI-Buffer/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-Buffer?branch=master)

# CGI::Buffer

Verify, Cache and Optimise CGI Output

# VERSION

Version 0.79

# SYNOPSIS

CGI::Buffer verifies the HTML that you produce by passing it through
`HTML::Lint`.

CGI::Buffer optimises FCGI programs by reducing, filtering and compressing
output to speed up the transmission and by nearly seamlessly making use of
client and server caches.

To make use of client caches, that is to say to reduce needless calls
to your server asking for the same data, all you need to do is to
include the package, and it does the rest.

    use CGI::Buffer;
    # ...

To also make use of server caches, that is to say to save regenerating
output when different clients ask you for the same data, you will need
to create a cache.
But that's simple:

    use CHI;
    use CGI::Buffer;

    # Put this at the top before you output anything
    CGI::Buffer::init(
        cache => CHI->new(driver => 'File')
    );
    if(CGI::Buffer::is_cached()) {
        # Nothing has changed - use the version in the cache
        exit;
    }

    # ...

To temporarily prevent the use of server-side caches, for example whilst
debugging before publishing a code change, set the NO\_CACHE environment variable
to any non-zero value.
If you get errors about Wide characters in print it means that you've
forgotten to emit pure HTML on non-ascii characters.
See [HTML::Entities](https://metacpan.org/pod/HTML::Entities).
As a hack work around you could also remove accents and the like by using
[Text::Unidecode](https://metacpan.org/pod/Text::Unidecode),
which works well but isn't really what you want.

# SUBROUTINES/METHODS

## init

Set various options and override default values.

    # Put this toward the top of your program before you do anything
    # By default, generate_tag, generate_304 and compress_content are ON,
    # optimise_content and lint_content are OFF.  Set optimise_content to 2 to
    # do aggressive JavaScript optimisations which may fail.
    use CGI::Buffer;
    CGI::Buffer::init(
        generate_etag => 1,     # make good use of client's cache
        generate_last_modified => 1,    # more use of client's cache
        compress_content => 1,  # if gzip the output
        optimise_content => 0,  # optimise your program's HTML, CSS and JavaScript
        cache => CHI->new(driver => 'File'),    # cache requests
        cache_key => 'string',  # key for the cache
        cache_age => '10 minutes',      # how long to store responses in the cache
        logger => $logger,
        lint_content => 0,      # Pass through HTML::Lint
        generate_304 => 1,      # Generate 304: Not modified
        lingua => CGI::Lingua->new(),
    );

If no cache\_key is given, one will be generated which may not be unique.
The cache\_key should be a unique value dependent upon the values set by the
browser.

The cache object will be an object that understands get\_object(),
set(), remove() and created\_at() messages, such as an [CHI](https://metacpan.org/pod/CHI) object. It is
used as a server-side cache to reduce the need to rerun database accesses.

Items stay in the server-side cache by default for 10 minutes.
This can be overridden by the cache\_control HTTP header in the request, and
the default can be changed by the cache\_age argument to init().

Logger will be an object that understands debug() such as an [Log::Log4perl](https://metacpan.org/pod/Log::Log4perl)
object.

To generate a last\_modified header, you must give a cache object.

Init allows a reference of the options to be passed. So both of these work:
    use CGI::Buffer;
    #...
    CGI::Buffer::init(generate\_etag => 1);
    CGI::Buffer::init({ generate\_etag => 1, info => CGI::Info->new() });

Generally speaking, passing by reference is better since it copies less on to
the stack.

Alternatively you can give the options when loading the package:
    use CGI::Buffer { optimise\_content => 1 };

## set\_options

Synonym for init, kept for historical reasons.

## can\_cache

Returns true if the server is allowed to store the results locally.

## is\_cached

Returns true if the output is cached. If it is then it means that all of the
expensive routines in the CGI script can be by-passed because we already have
the result stored in the cache.

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

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

CGI::Buffer should be safe even in scripts which produce lots of different
output, e.g. e-commerce situations.
On such pages, however, I strongly urge to setting generate\_304 to 0 and
sending the HTTP header "Cache-Control: no-cache".

When using [Template](https://metacpan.org/pod/Template), ensure that you don't use it to output to STDOUT,
instead you will need to capture into a variable and print that.
For example:

    my $output;
    $template->process($input, $vars, \$output) || ($output = $template->error());
    print $output;

Can produce buggy JavaScript if you use the &lt;!-- HIDING technique.
This is a bug in [JavaScript::Packer](https://metacpan.org/pod/JavaScript::Packer), not CGI::Buffer.
See https://github.com/nevesenin/javascript-packer-perl/issues/1#issuecomment-4356790

Mod\_deflate can confuse this when compressing output.
Ensure that deflation is off for .pl files:

    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|pl)$ no-gzip dont-vary

If you request compressed output then uncompressed output (or vice
versa) on input that produces the same output, the status will be 304.
The letter of the spec says that's wrong, so I'm noting it here, but
in practice you should not see this happen or have any difficulties
because of it.

CGI::Buffer is not compatible with FastCGI.

I advise adding CGI::Buffer as the last use statement so that it is
cleared up first.  In particular it should be loaded after
[Log::Log4Perl](https://metacpan.org/pod/Log::Log4Perl), if you're using that, so that any messages it
produces are printed after the HTTP headers have been sent by
CGI::Buffer;

CGI::Buffer is not compatible with FCGI, use [FCGI::Buffer](https://metacpan.org/pod/FCGI::Buffer) instead.

Please report any bugs or feature requests to `bug-cgi-buffer at rt.cpan.org`,
or through the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Buffer](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Buffer).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SEE ALSO

HTML::Packer, HTML::Lint

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Buffer

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Buffer](http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Buffer)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/CGI-Buffer](http://annocpan.org/dist/CGI-Buffer)

- CPAN Ratings

    [http://cpanratings.perl.org/d/CGI-Buffer](http://cpanratings.perl.org/d/CGI-Buffer)

- Search CPAN

    [http://search.cpan.org/dist/CGI-Buffer/](http://search.cpan.org/dist/CGI-Buffer/)

# ACKNOWLEDGEMENTS

The inspiration and code for some of this is cgi\_buffer by Mark
Nottingham: http://www.mnot.net/cgi\_buffer.

# LICENSE AND COPYRIGHT

The licence for cgi\_buffer is:

    "(c) 2000 Copyright Mark Nottingham <mnot@pobox.com>

    This software may be freely distributed, modified and used,
    provided that this copyright notice remain intact.

    This software is provided 'as is' without warranty of any kind."

The rest of the program is Copyright 2011-2017 Nigel Horne,
and is released under the following licence: GPL
