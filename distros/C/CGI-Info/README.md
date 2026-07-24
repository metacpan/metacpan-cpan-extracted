CGI-Info
========

[![Appveyor Status](https://ci.appveyor.com/api/projects/status/1t1yhvagx00c2qi8?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-info)
[![CircleCI](https://dl.circleci.com/status-badge/img/circleci/8CE7w65gte4YmSREC2GBgW/THucjGauwLPtHu1MMAueHj/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/circleci/8CE7w65gte4YmSREC2GBgW/THucjGauwLPtHu1MMAueHj/tree/main)
[![Coveralls Status](https://coveralls.io/repos/github/nigelhorne/CGI-Info/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-Info?branch=master)
[![CPAN](https://img.shields.io/cpan/v/CGI-Info.svg)](http://search.cpan.org/~nhorne/CGI-Info/)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/nigelhorne/cgi-info/test.yml?branch=master)
![Perl Version](https://img.shields.io/badge/perl-5.10+-blue)
[![Security Policy](https://img.shields.io/badge/security-policy-blue.svg)](SECURITY.md)
<!-- [![Travis Status](https://travis-ci.org/nigelhorne/CGI-Info.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-Info) -->
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://x.com/intent/tweet?text=Information+about+the+CGI+Environment+#perl+#CGI&url=https://github.com/nigelhorne/cgi-info&via=nigelhorne)

# NAME

CGI::Info - Information about the CGI environment

# VERSION

Version 1.14

# SYNOPSIS

The `CGI::Info` module is a Perl library designed to provide information about the environment in which a CGI script operates.
It aims to eliminate hard-coded script details,
enhancing code readability and portability.
Additionally, it offers a simple web application firewall to add a layer of security.

All too often,
Perl programs have information such as the script's name
hard-coded into their source.
Generally speaking,
hard-coding is a bad style since it can make programs difficult to read and reduces readability and portability.
CGI::Info attempts to remove that.

Furthermore, to aid script debugging, CGI::Info attempts to do sensible
things when you're not running the program in a CGI environment.

Whilst you shouldn't rely on it alone to provide security to your website,
it is another layer and every little helps.

    use CGI::Info;

    my $info = CGI::Info->new(allow => { id => qr/^\d+$/ });
    my $params = $info->params();

    if($info->is_mobile()) {
        print "Mobile view\n";
    } else {
        print "Desktop view\n";
    }

    my $id = $info->param('id');        # Validated against allow schema

# SUBROUTINES/METHODS

## new

Creates a CGI::Info object.

It takes four optional arguments: allow, logger, expect and upload\_dir,
which are documented in the params() method.

It takes other optional parameters:

- `auto_load`

    Enable/disable the AUTOLOAD feature.
    The default is to have it enabled.

- `config_dirs`

    Where to look for `config_file`

- `config_file`

    Points to a configuration file which contains the parameters to `new()`.
    The file can be in any common format,
    including `YAML`, `XML`, and `INI`.
    This allows the parameters to be set at run time.

    On non-Windows system,
    the class can be configured using environment variables starting with "CGI::Info::".
    For example:

        export CGI::Info::max_upload_size=65536

    It doesn't work on Windows because of the case-insensitive nature of that system.

    If the configuration file has a section called `CGI::Info`,
    only that section,
    and the `global` section,
    if any exists,
    is used.

- `syslog`

    Takes an optional parameter syslog, to log messages to
    [Sys::Syslog](https://metacpan.org/pod/Sys%3A%3ASyslog).
    It can be a boolean to enable/disable logging to syslog, or a reference
    to a hash to be given to Sys::Syslog::setlogsock.

- `cache`

    An object that is used to cache IP lookups.
    This cache object is an object that understands get() and set() messages,
    such as a [CHI](https://metacpan.org/pod/CHI) object.

- `max_upload_size`

    The maximum file size in bytes you can upload.
    Use `-1` for no limit.
    The default is 512 KB (524288 bytes).

The class can be configured at runtime using environment variables and configuration
files; for example, setting `$ENV{'CGI__INFO__carp_on_warn'}` causes warnings to
use [Carp](https://metacpan.org/pod/Carp).  For more information see [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

### API SPECIFICATION

#### INPUT

    {
      allow          => { type => 'hashref',  optional => 1 },
      auto_load      => { type => 'boolean',  optional => 1 },
      cache          => { type => 'object',   optional => 1 },
      carp_on_warn   => { type => 'boolean',  optional => 1 },
      config_dirs    => { type => 'arrayref', optional => 1 },
      config_file    => { type => 'string',   optional => 1 },
      logger         => { type => 'object',   optional => 1 },
      max_upload_size=> { type => 'integer',  optional => 1, min => -1 },
      upload_dir     => { type => 'string',   optional => 1 },
    }

#### OUTPUT

    { type => 'object', isa => 'CGI::Info' }

### MESSAGES

- `use ->new() not ::new() to instantiate`

    **Level**: fatal (croak).
    **Cause**: called as `CGI::Info::new()` (double-colon) instead of `CGI::Info->new()`.
    **Action**: change the call-site to use the arrow notation.

- `Logger must be an object with info() and error() methods`

    **Level**: fatal (croak).
    **Cause**: the `logger` argument is not a blessed object, or does not
    implement `info()`, `warn()`, and `error()` methods.
    **Action**: pass a compliant logger such as a [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)-based object.

- `expect has been deprecated, use allow instead`

    **Level**: fatal (croak).
    **Cause**: the removed `expect` parameter was passed to `new()`.
    **Action**: replace `expect => [...]` with `allow => { key => qr/.../ }`.

## script\_name

Retrieves the name of the executing CGI script.
This is useful for POSTing,
thus avoiding hard-coded paths into forms.

        use CGI::Info;

        my $info = CGI::Info->new();
        my $script_name = $info->script_name();
        # ...
        print "<form method=\"POST\" action=$script_name name=\"my_form\">\n";

### API SPECIFICATION

#### INPUT

None.

#### OUTPUT

    {
      type => 'string',
      'min' => 1,
      'nomatch' => qr/^[\/\\]/    # Does not return absolute path
    }

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

        print 'HTML files are normally stored in ', $info->script_dir(), '/', File::Spec->updir(), "\n";

        # or
        use lib CGI::Info::script_dir() . '../lib';

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
Usually it will be similar to host\_name, but will lack the http:// or www prefixes.

Can be called as a class method.

## cgi\_host\_url

Return the URL of the machine running the CGI script.

## params

Returns a reference to a hash list of the CGI arguments.

CGI::Info helps you to test your script before deployment on a website:
if it is not in a CGI environment (e.g., the script is being tested from the
command line), the program's command line arguments (a list of key=value pairs)
are used, if there are no command line arguments,
then they are read from stdin as a list of key=value lines.
Also,
you can give one of --tablet, --search-engine,
\--mobile and --robot to mimic those agents. For example:

        ./script.cgi --mobile name=Nigel

Returns undef if the parameters can't be determined or if none were given.

If an argument is given twice or more, then the values are put in a comma
separated string.

The returned hash value can be passed into [CGI::Untaint](https://metacpan.org/pod/CGI%3A%3AUntaint).

Takes four optional parameters: allow, logger and upload\_dir.
The parameters are passed in a hash, or a reference to a hash.
The latter is more efficient since it puts less on the stack.

Allow is a reference to a hash list of CGI parameters that you will allow.
The value for each entry is either a permitted value,
a regular expression of permitted values for
the key,
a code reference,
or a hash of [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) rules.
Subroutine exceptions propagate normally, allowing custom error handling.
This works alongside existing regex and Params::Validate::Strict patterns.
A undef value means that any value will be allowed.
Arguments not in the list are silently ignored.
This is useful to help to block attacks on your site.

Upload\_dir is a string containing a directory where files being uploaded are to
be stored.
It must be a writeable directory in the temporary area.

Takes an optional parameter logger, which is used for warnings and traces.
It can be an object that understands warn() and trace() messages,
such as a [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) or [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) object,
a reference to code,
a reference to an array,
or a filename.

The allow, logger and upload\_dir arguments can also be passed to the
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
                foo => qr/^\d*$/,       # foo must be a number, or empty
                bar => undef,           # bar can be given and be any value
                xyzzy => qr/^[\w\s-]+$/,        # must be alphanumeric
                                                # to prevent XSS, and non-empty
                                                # as a sanity check
        };
        # or
        $allowed = {
                email => { type => 'string', matches => qr/^[^@]+@[^@]+\.[^@]+$/ }, # String, basic email format check
                age => { type => 'integer', min => 0, max => 150 }, # Integer between 0 and 150
                bio => { type => 'string', optional => 1 }, # String, optional
                ip_address => { type => 'string', matches => qr/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/ }, #Basic IPv4 validation
        };
        my $paramsref = $info->params(allow => $allowed);
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
        # ...
        my $info = CGI::Info->new();
        my $paramsref = $info->params();        # See BUGS below
        my $xml = $$paramsref{'XML'};
        # ... parse and process the XML request in $xml

Carp if logger is not set and we detect something serious.

Blocks some attacks,
such as SQL and XSS injections,
mustleak and directory traversals,
thus creating a primitive web application firewall (WAF).
Warning - this is an extra layer, not a replacement for your other security layers.

### Validation Subroutine Support

The `allow` parameter accepts subroutine references for dynamic validation,
enabling complex parameter checks beyond static regex patterns.
These callbacks:

- Receive three arguments: the parameter key, value and the `CGI::Info` instance
- Must return a true value to allow the parameter, false to reject
- Can access other parameters through the instance for contextual validation

Basic usage:

    CGI::Info->new(
        allow => {
            # Simple value check
            even_number => sub { ($_[1] % 2) == 0 },

            # Context-aware validation
            child_age => sub {
                my ($key, $value, $info) = @_;
                $info->param('is_parent') ? $value <= 18 : 0
            }
        }
    );

Advanced features:

    # Combine with regex validation
    mixed_validation => {
        email => qr/@/,  # Regex check
        promo_code => \&validate_promo_code  # Subroutine check
    }

    # Throw custom exceptions
    dangerous_param => sub {
        die 'Hacking attempt!' if $_[1] =~ /DROP TABLE/;
        return 1;
    }

## param($field)

Get a single CGI parameter value by name.
When called without arguments it delegates to `params()` and returns all parameters.
When called with a field name it returns that parameter's (sanitised) value,
or `undef` if the parameter was not supplied or is not in the allow list.

        use CGI::Info;
        my $info = CGI::Info->new();
        my $bar  = $info->param('foo');

        # With an allow list:
        my $info2 = CGI::Info->new();
        my $allowed = { foo => qr/\d+/ };
        $info2->params(allow => $allowed);
        my $bar2 = $info2->param('bar');   # logs a warning; returns undef

- $field

    Optional. The name of the CGI parameter to retrieve.
    If omitted, all parameters (as a hash-ref) are returned via `params()`.

### API SPECIFICATION

#### Input

        {
                field => { type => 'scalar', optional => 1 },
        }

#### Output

        # When $field is supplied
        { type => 'scalar', optional => 1 }
        # When $field is omitted (delegates to params())
        { type => 'hashref', optional => 1 }

### MESSAGES

        | Level | Message                                  | Meaning                              | Action                                  |
        |-------|------------------------------------------|--------------------------------------|-----------------------------------------|
        | warn  | param: <field> isn't in the allow list   | Caller requested a parameter outside | Review the allow list passed to new()   |
        |       |                                          | the schema set by params(allow=>\%h) | or params(); add the key if legitimate  |

## is\_mobile

Returns a boolean if the website is being viewed on a mobile
device such as a smartphone.
All tablets are mobile, but not all mobile devices are tablets.

Can be overridden by the IS\_MOBILE environment setting

## is\_tablet

Returns a boolean if the website is being viewed on a tablet such as an iPad.

## as\_string

Converts CGI parameters into a formatted string representation with optional raw mode (no escaping of special characters).
Useful for debugging or generating keys for a cache.

    my $string_representation = $info->as_string();
    my $raw_string = $info->as_string({ raw => 1 });

### API SPECIFICATION

#### INPUT

    {
      raw => {
        'type' => 'boolean',
        'optional' => 1,
      }
    }

#### OUTPUT

    {
      type => 'string',
      optional => 1,
    }

## protocol

Returns the connection protocol, presumably 'http' or 'https', or undef if
it can't be determined.

## tmpdir

Returns the name of a directory that you can use to create temporary files
in.

The routine is preferable to ["tmpdir" in File::Spec](https://metacpan.org/pod/File%3A%3ASpec#tmpdir) since CGI programs are
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
        $dir = $info->tmpdir({ default => '/var/tmp' });

        # or

        my $dir = CGI::Info->tmpdir();

## rootdir

Returns the document root.  This is preferable to looking at DOCUMENT\_ROOT
in the environment because it will also work when we're not running as a CGI
script, which is useful for script debugging.

This can be run as a class or object method.

        use CGI::Info;

        print CGI::Info->rootdir();

## root\_dir

Synonym of rootdir(), for compatibility with [CHI](https://metacpan.org/pod/CHI).

## documentroot

Synonym of rootdir(), for compatibility with Apache.

## logdir($dir)

Gets and sets the name of a directory where you can store logs.

- $dir

    Path to the directory where logs will be stored.

## is\_robot

Is the visitor a real person or a robot?

        use CGI::Info;

        my $info = CGI::Info->new();
        unless($info->is_robot()) {
                # update site visitor statistics
        }

If the client is seen to be attempting an SQL injection,
set the HTTP status to 403,
and return 1.

## is\_search\_engine

Is the visitor a search engine?

    if(CGI::Info->new()->is_search_engine()) {
        # display generic information about yourself
    } else {
        # allow the user to pick and choose something to display
    }

Can be overridden by the IS\_SEARCH\_ENGINE environment setting

## is\_ai

Returns a boolean indicating whether the visitor is a known AI training or
inference crawler (e.g. GPTBot, ClaudeBot, PerplexityBot).

Use this to withhold training data, serve an opt-out notice, or log AI traffic
separately from regular robot traffic.

**Invariant**: when `is_ai()` returns true, `is_robot()` also returns true,
regardless of the order in which the two methods are called.

Can be overridden by the `IS_AI` environment variable.

### EXAMPLE

    use CGI::Info;

    my $info = CGI::Info->new();
    if ($info->is_ai()) {
        # Decline to serve training data to AI scrapers
        print "Status: 403 Forbidden\r\n\r\n";
        exit;
    }

    # Route AI crawlers to a lightweight page instead of blocking them
    if ($info->is_ai()) {
        serve_ai_summary();
    } else {
        serve_full_page();
    }

### API SPECIFICATION

#### Input

No arguments beyond the implicit object reference (`$self`).

    # Params::Validate::Strict schema -- no parameters
    {}

#### Output

    # Return::Set schema
    {
        type    => SCALAR,
        values  => [ 0, 1 ],
    }

Returns `1` if the visiting client is identified as an AI training or
inference crawler; `0` otherwise.

### MESSAGES

This method produces no log messages of its own.  Upstream callers such as
`is_robot()` may emit WAF warnings; see ["is\_robot"](#is_robot) for that table.

### PSEUDOCODE

    function is_ai(self):
        if self.{is_ai} is defined:
            return self.{is_ai}                    # instance-level cache

        if IS_AI environment variable is set:
            return self.{is_ai} = IS_AI ? 1 : 0   # override; no robot sync needed
                                                   # because is_robot() calls is_ai()

        ua     = HTTP_USER_AGENT
        remote = REMOTE_ADDR

        if not (remote and ua):
            return 0                               # not a CGI request; assume human

        if ua matches any AI_PAT token (case-insensitive):
            self.{is_robot} = 1                    # enforce is_ai => is_robot
            return self.{is_ai} = 1

        return self.{is_ai} = 0

## browser\_type

Returns a string classifying the visitor's client.  The possible values are:

- `'mobile'` -- smartphone or tablet (checked first)
- `'ai'` -- known AI training or inference crawler (see ["is\_ai"](#is_ai))
- `'search'` -- search-engine crawler
- `'robot'` -- other automated client
- `'web'` -- ordinary desktop or laptop browser

    use Carp;
    use Template;
    use CGI::Info;

    my $info = CGI::Info->new();
    my $dir  = $info->rootdir() . '/templates/' . $info->browser_type();

    my $filename = ref($info);
    $filename =~ s/::/\//g;
    $filename = "$dir/$filename.tmpl";

    (-f $filename && -r $filename)
        or croak "Cannot open template '$filename'";

    my $template = Template->new();
    $template->process($filename, {}) or croak $template->error();

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
API is the same as "param",
it will replace the "get\_cookie" method in the future.

    use CGI::Info;

    my $name = CGI::Info->new()->cookie('name');
    print "Your name is $name\n";

### API SPECIFICATION

#### INPUT

    {
      cookie_name => {
        'type' => 'string',
        'min' => 1,
        'matches' => qr/^[!#-'*+\-.\^_`|~0-9A-Za-z]+$/    # RFC6265
      }
    }

#### OUTPUT

Cookie not set: `undef`

Cookie set:

    {
      type => 'string',
      optional => 1,
      matches => qr/      # RFC6265
        ^
        (?:
          "[\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]*"   # quoted
        | [\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]*     # unquoted
        )
        $
      /x
    }

## status($status)

Sets or returns the status of the object,
200 for OK,
otherwise an HTTP error code

- $status

    Optional integer value to be set or retrieved.
    If omitted, the value is retrieved.

## messages

Returns the messages that the object has generated as a ref to an array of hashes.

    my @messages;
    if(my $w = $info->messages()) {
        @messages = map { $_->{'message'} } @{$w};
    } else {
        @messages = ();
    }
    print STDERR join(';', @messages), "\n";

## messages\_as\_string

Returns the messages of that the object has generated as a string.

## cache($cache)

Get/set the internal cache system.

Use this rather than pass the cache argument to `new()` if you see these error messages,
"(in cleanup) Failed to get MD5\_CTX pointer".
It's some obscure problem that I can't work out,
but calling this after `new()` works.

- $cache

    Optional cache object.
    When not given,
    returns the current cache object.

## set\_logger

Sets the class, array, code reference, or file that will be used for logging.

Sometimes you don't know what the logger is until you've instantiated the class.
This function fixes the catch-22 situation.

## reset

Class method to reset the class.
You should do this in an FCGI environment before instantiating,
but nowhere else.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

is\_tablet() only currently detects the iPad and Windows PCs. Android strings
don't differ between tablets and smartphones.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

# SEE ALSO

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/CGI-Info/coverage/)
- [HTTP::BrowserDetect](https://metacpan.org/pod/HTTP%3A%3ABrowserDetect)
- [https://github.com/mitchellkrogza/apache-ultimate-bad-bot-blocker](https://github.com/mitchellkrogza/apache-ultimate-bad-bot-blocker)

# REPOSITORY

[https://github.com/nigelhorne/CGI-Info](https://github.com/nigelhorne/CGI-Info)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-cgi-info at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Info](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Info).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc CGI::Info

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/CGI-Info](https://metacpan.org/dist/CGI-Info)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Info](https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Info)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=CGI-Info](http://matrix.cpantesters.org/?dist=CGI-Info)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=CGI::Info](http://deps.cpantesters.org/?module=CGI::Info)

## FORMAL SPECIFICATION

### new

    -- CGI::Info construction
    new : ClassName x Params --> CGIInfo

    -- Normal (non-clone) path
    new(class, params) ^=
      let configured == Object::Configure::configure(class, params)
      in  CGIInfo {
            max_upload_size |-> configured.max_upload_size ?? MAX_UPLOAD_SIZE_DEFAULT,
            allow           |-> configured.allow ?? null,
            upload_dir      |-> configured.upload_dir ?? null,
            ...configured
          }

    -- Pre-conditions
    pre new(class, params) ^=
      params.logger = null
      v (blessed(params.logger)
         ^ params.logger.can('warn')
         ^ params.logger.can('info')
         ^ params.logger.can('error'))
      ^ params.expect = null

    -- Clone path (invocant is an existing object)
    clone : CGIInfo x Params --> CGIInfo
    clone(self, params) ^=
      let merged == (self (+) params) \ {paramref}
      in  CGIInfo { ...merged }

### param

Let F be the set of all possible CGI field names, V be the set of all
possible (sanitised) scalar values, and allow : F -> Regex | undef be the
current allow-list schema (undef means all fields are permitted).

    param : F? -> V | HashRef | undef

    param() =  params()

    param(f) =
      f not in dom(allow) /\ allow /= undef =>  warn; undef
      f in params()                          =>  params()(f)
      otherwise                              =>  undef

Safety invariant: for all f, param(f) /= undef => f in dom(allow) \\/ allow = undef.

## is\_ai

    -- is_ai ---------------------------------------------------------
    -- Given CGIInfo state i, returns a boolean result.
    --
    -- AI_PAT is the set of known AI crawler token strings.
    --
    -- ENV denotes the process environment (a partial function from
    -- name to value).
    --
    AI_PAT == {ClaudeBot, Claude-Web, anthropic-ai, GPTBot,
               ChatGPT-User, OAI-SearchBot, Google-Extended,
               meta-externalagent, FacebookBot, Applebot-Extended,
               PerplexityBot, Amazonbot, YouBot, Diffbot,
               cohere-ai, CCBot, Bytespider, AI2Bot, TimpiBot}

    is_ai ≜ λ i : CGIInfo •
      -- Environment override takes absolute priority
      IS_AI ∈ dom ENV ⟹
          (ENV IS_AI ≠ '0' ∧ ENV IS_AI ≠ '')

      -- Without both IP and UA we cannot classify
    ∧ IS_AI ∉ dom ENV ∧
      (REMOTE_ADDR ∉ dom ENV ∨ HTTP_USER_AGENT ∉ dom ENV)
          ⟹ false

      -- UA-pattern match (case-insensitive substring)
    ∧ IS_AI ∉ dom ENV ∧
      REMOTE_ADDR ∈ dom ENV ∧ HTTP_USER_AGENT ∈ dom ENV
          ⟹ (∃ p : AI_PAT • p ⊑ᵢ ENV HTTP_USER_AGENT)

      -- Invariant: is_ai ⟹ is_robot
    ∧ is_ai i = true ⟹ is_robot i = true
    -- ---------------------------------------------------------------

# LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
