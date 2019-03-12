[![Linux Build Status](https://travis-ci.org/nigelhorne/CGI-Info.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-Info)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/1t1yhvagx00c2qi8?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-info)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/CGI-Info/badge)](https://dependencyci.com/github/nigelhorne/CGI-Info)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/CGI-Info/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-Info?branch=master)
[![CPAN](https://img.shields.io/cpan/v/CGI-Info.svg)](http://search.cpan.org/~nhorne/CGI-Info/)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/5642353356298438/heads/master/)

# NAME

CGI::Info - Information about the CGI environment

# VERSION

Version 0.69

# SYNOPSIS

All too often Perl programs have information such as the script's name
hard-coded into their source.
Generally speaking, hard-coding is bad style since it can make programs
difficult to read and it reduces readability and portability.
CGI::Info attempts to remove that.

Furthermore, to aid script debugging, CGI::Info attempts to do sensible
things when you're not running the program in a CGI environment.

    use CGI::Info;
    my $info = CGI::Info->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a CGI::Info object.

It takes four optional arguments allow, logger, expect and upload\_dir,
which are documented in the params() method.

Takes an optional parameter syslog, to log messages to
[Sys::Syslog](https://metacpan.org/pod/Sys::Syslog).
It can be a boolean to enable/disable logging to syslog, or a reference
to a hash to be given to Sys::Syslog::setlogsock.

Takes optional parameter logger, an object which is used for warnings

Takes optional parameter cache, an object which is used to cache IP lookups.
This cache object is an object that understands get() and set() messages,
such as a [CHI](https://metacpan.org/pod/CHI) object.

Takes optional parameter max\_upload, which is the maximum file size you can upload
(-1 for no limit), the default is 512MB.

## script\_name

Returns the name of the CGI script.
This is useful for POSTing, thus avoiding putting hardcoded paths into forms

        use CGI::Info;

        my $info = CGI::Info->new();
        my $script_name = $info->script_name();
        # ...
        print "<form method=\"POST\" action=$script_name name=\"my_form\">\n";

## script\_path

Finds the full path name of the script.

        use CGI::Info;

        my $info = CGI::Info->new();
        my $fullname = $info->script_path();
        my @statb = stat($fullname);

        if(@statb) {
                my $mtime = localtime $statb[9];
                print "Last-Modified: $mtime\n";
                # TODO: only for HTTP/1.1 connections
                # $etag = Digest::MD5::md5_hex($html);
                printf "ETag: \"%x\"\n", $statb[9];
        }

## script\_dir

Returns the file system directory containing the script.

        use CGI::Info;
        use File::Spec;

        my $info = CGI::Info->new();

        print 'HTML files are normally stored in ' .  $info->script_dir() . '/' . File::Spec->updir() . "\n";

## host\_name

Return the host-name of the current web server, according to CGI.
If the name can't be determined from the web server, the system's host-name
is used as a fall back.
This may not be the same as the machine that the CGI script is running on,
some ISPs and other sites run scripts on different machines from those
delivering static content.
There is a good chance that this will be domain\_name() prepended with either
'www' or 'cgi'.

        use CGI::Info;

        my $info = CGI::Info->new();
        my $host_name = $info->host_name();
        my $protocol = $info->protocol();
        # ...
        print "Thank you for visiting our <A HREF=\"$protocol://$host_name\">Website!</A>";

## domain\_name

Domain\_name is the name of the controlling domain for this website.
Usually it will be similar to host\_name, but will lack the http:// prefix.

## cgi\_host\_url

Return the URL of the machine running the CGI script.

## params

Returns a reference to a hash list of the CGI arguments.

CGI::Info helps you to test your script prior to deployment on a website:
if it is not in a CGI environment (e.g. the script is being tested from the
command line), the program's command line arguments (a list of key=value pairs)
are used, if there are no command line arguments then they are read from stdin
as a list of key=value lines. Also you can give one of --tablet, --search-engine,
\--mobile and --robot to mimic those agents. For example:

        ./script.cgi --mobile name=Nigel

Returns undef if the parameters can't be determined or if none were given.

If an argument is given twice or more, then the values are put in a comma
separated string.

The returned hash value can be passed into [CGI::Untaint](https://metacpan.org/pod/CGI::Untaint).

Takes four optional parameters: allow, expect, logger and upload\_dir.
The parameters are passed in a hash, or a reference to a hash.
The latter is more efficient since it puts less on the stack.

Allow is a reference to a hash list of CGI parameters that you will allow.
The value for each entry is a regular expression of permitted values for
the key.
A undef value means that any value will be allowed.
Arguments not in the list are silently ignored.
This is useful to help to block attacks on your site.

Expect is a reference to a list of arguments that you expect to see and pass on.
Arguments not in the list are silently ignored.
This is useful to help to block attacks on your site.
Its use is deprecated, use allow instead.
Expect will be removed in a later version.

Upload\_dir is a string containing a directory where files being uploaded are to
be stored.

Takes optional parameter logger, an object which is used for warnings and
traces.
This logger object is an object that understands warn() and trace() messages,
such as a [Log::Log4perl](https://metacpan.org/pod/Log::Log4perl) or [Log::Any](https://metacpan.org/pod/Log::Any) object.

The allow, expect, logger and upload\_dir arguments can also be passed to the
constructor.

        use CGI::Info;
        use CGI::Untaint;
        # ...
        my $info = CGI::Info->new();
        my %params;
        if($info->params()) {
                %params = %{$info->params()};
        }
        # ...
        foreach(keys %params) {
                print "$_ => $params{$_}\n";
        }
        my $u = CGI::Untaint->new(%params);

        use CGI::Info;
        use CGI::IDS;
        # ...
        my $info = CGI::Info->new();
        my $allowed = {
                'foo' => qr(^\d*$),     # foo must be a number, or empty
                'bar' => undef,
                'xyzzy' => qr(^[\w\s-]+$),      # must be alphanumeric
                                                # to prevent XSS, and non-empty
                                                # as a sanity check
        };
        my $paramsref = $info->params(allow => $allowed);
        # or
        my @expected = ('foo', 'bar');
        my $paramsref = $info->params({
                expect => \@expected,
                upload_dir = $info->tmpdir()
        });
        if(defined($paramsref)) {
                my $ids = CGI::IDS->new();
                $ids->set_scan_keys(scan_keys => 1);
                if($ids->detect_attacks(request => $paramsref) > 0) {
                        die 'horribly';
                }
        }

If the request is an XML request (i.e. the content type of the POST is text/xml),
CGI::Info will put the request into the params element 'XML', thus:

        use CGI::Info;
        ...
        my $info = CGI::Info->new();
        my $paramsref = $info->params();        # See BUGS below
        my $xml = $$paramsref{'XML'};
        # ... parse and process the XML request in $xml

## param

Get a single parameter.
Takes an optional single string parameter which is the argument to return. If
that parameter is not given param() is a wrapper to params() with no arguments.

        use CGI::Info;
        # ...
        my $info = CGI::Info->new();
        my $bar = $info->param('foo');

If the requested parameter isn't in the allowed list, an error message will
be thrown:

        use CGI::Info;
        my $allowed = {
                'foo' => qr(\d+),
        };
        my $xyzzy = $info->params(allow => $allowed);
        my $bar = $info->param('bar');  # Gives an error message

Returns undef if the requested parameter was not given

## is\_mobile

Returns a boolean if the website is being viewed on a mobile
device such as a smart-phone.
All tablets are mobile, but not all mobile devices are tablets.

## is\_tablet

Returns a boolean if the website is being viewed on a tablet such as an iPad.

## as\_string

Returns the parameters as a string, which is useful for debugging or
generating keys for a cache.

## protocol

Returns the connection protocol, presumably 'http' or 'https', or undef if
it can't be determined.

## tmpdir

Returns the name of a directory that you can use to create temporary files
in.

The routine is preferable to ["tmpdir" in File::Spec](https://metacpan.org/pod/File::Spec#tmpdir) since CGI programs are
often running on shared servers.  Having said that, tmpdir will fall back
to File::Spec->tmpdir() if it can't find somewhere better.

If the parameter 'default' is given, then use that directory as a
fall-back rather than the value in File::Spec->tmpdir().
No sanity tests are done, so if you give the default value of
'/non-existant', that will be returned.

Tmpdir allows a reference of the options to be passed.

        use CGI::Info;

        my $info = CGI::Info->new();
        my $dir = $info->tmpdir(default => '/var/tmp');
        my $dir = $info->tmpdir({ default => '/var/tmp' });

        # or

        my $dir = CGI::Info->tmpdir();

## rootdir

Returns the document root.  This is preferable to looking at DOCUMENT\_ROOT
in the environment because it will also work when we're not running as a CGI
script, which is useful for script debugging.

This can be run as a class or object method.

        use CGI::Info;

        print CGI::Info->rootdir();

## logdir

Gets and sets the name of a directory that you can use to store logs in.

## is\_robot

Is the visitor a real person or a robot?

        use CGI::Info;

        my $info = CGI::Info->new();
        unless($info->is_robot()) {
          # update site visitor statistics
        }

## is\_search\_engine

Is the visitor a search engine?

    use CGI::Info;

    if(CGI::Info->new()->is_search_engine()) {
        # display generic information about yourself
    } else {
        # allow the user to pick and choose something to display
    }

## browser\_type

Returns one of 'web', 'search', 'robot' and 'mobile'.

    # Code to display a different web page for a browser, search engine and
    # smartphone
    use Template;
    use CGI::Info;

    my $info = CGI::Info->new();
    my $dir = $info->rootdir() . '/templates/' . $info->browser_type();

    my $filename = ref($self);
    $filename =~ s/::/\//g;
    $filename = "$dir/$filename.tmpl";

    if((!-f $filename) || (!-r $filename)) {
        die "Can't open $filename";
    }
    my $template = Template->new();
    $template->process($filename, {}) || die $template->error();

## get\_cookie

Returns a cookie's value, or undef if no name is given, or the requested
cookie isn't in the jar.

Deprecated - use cookie() instead.

        use CGI::Info;

        my $i = CGI::Info->new();
        my $name = $i->get_cookie(cookie_name => 'name');
        print "Your name is $name\n";
        my $address = $i->get_cookie('address');
        print "Your address is $address\n";

## cookie

Returns a cookie's value, or undef if no name is given, or the requested
cookie isn't in the jar.
API is the same as "param", it will replace the "get\_cookie" method in the future.

        use CGI::Info;

        my $name = CGI::Info->new()->get_cookie(name);
        print "Your name is $name\n";

## status

Returns the status of the object, 200 for OK, otherwise an HTTP error code

## set\_logger

Sometimes you don't know what the logger is until you've instantiated the class.
This function fixes the catch22 situation.

## reset

Class method to reset the class.
You should do this in an FCGI environment before instantiating, but nowhere else.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

is\_tablet() only currently detects the iPad and Windows PCs. Android strings
don't differ between tablets and smart-phones.

Please report any bugs or feature requests to `bug-cgi-info at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Info](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Info).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

# SEE ALSO

[HTTP::BrowserDetect](https://metacpan.org/pod/HTTP::BrowserDetect)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Info

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Info](http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Info)

- CPAN Ratings

    [http://cpanratings.perl.org/d/CGI-Info](http://cpanratings.perl.org/d/CGI-Info)

- Search CPAN

    [http://search.cpan.org/dist/CGI-Info/](http://search.cpan.org/dist/CGI-Info/)

# LICENSE AND COPYRIGHT

Copyright 2010-2019 Nigel Horne.

This program is released under the following licence: GPL2
