# NAME

CatalystX::ASP - PerlScript/ASP on Catalyst

# VERSION

version 1.12

# SYNOPSIS

    package MyApp;
    use Moose;
    use Catalyst;
    extends 'Catalyst';

    with 'CatalystX::ASP::Role';

    1;

# DESCRIPTION

CatalystX::ASP is a plugin for Catalyst to support ASP (PerlScript). This is
largely based off of Joshua Chamas's [Apache::ASP](https://metacpan.org/pod/Apache::ASP), as the application I've been
working with was written for [Apache::ASP](https://metacpan.org/pod/Apache::ASP). Thus, this was designed to be
almost a drop-in replacement. However, there were many features that I chose not
to implement.

This plugin basically creates a Catalyst View which can process ASP scripts. As
an added bonus, a simple [CatalystX::ASP::Role](https://metacpan.org/pod/CatalystX::ASP::Role) can be included to allow for
automatical processing of files with _.asp_ extension in the application
_root_ directory.

Just to be clear, the [Parser](https://metacpan.org/pod/CatalystX::ASP::Parser) is almost totally ripped
off of Joshua Chamas's parser in [Apache::ASP](https://metacpan.org/pod/Apache::ASP). Similarly with the
[Compiler](https://metacpan.org/pod/CatalystX::ASP::Compiler) and [GlobalASA](https://metacpan.org/pod/CatalystX::ASP::GlobalASA).
However, the other components are reimplementations.

# CONFIGURATION

You can configure CatalystX::ASP in Catalyst under the `CatalystX::ASP` section
of the configuration

    __PACKAGE__->config('CatalystX::ASP' => {
      Global        => 'lib',
      GlobalPackage => 'MyApp',
      IncludesDir   => 'templates',
      MailHost      => 'localhost',
      MailFrom      => 'myapp@localhost',
      XMLSubsMatch  => '(?:myapp):\w+',
      Debug         => 0,
    }):

The following documentation is also plagiarized from Joshua Chamas.

- Global

    Global is the nerve center of an Apache::ASP application, in which the
    global.asa may reside defining the web application's event handlers.

    Includes, specified with `<!--#include file=somefile.inc-->` or
    `$Response->Include()` syntax, may also be in this directory, please see
    section on includes for more information.

- GlobalPackage

    Perl package namespace that all scripts, includes, & global.asa events are
    compiled into.  By default, GlobalPackage is some obscure name that is uniquely
    generated from the file path of the Global directory, and global.asa file. The
    use of explicitly naming the GlobalPackage is to allow scripts access to globals
    and subs defined in a perl module that is included with commands like:

        __PACKAGE__->config('CatalystX::ASP' => {
          GlobalPackage => 'MyApp' });

- IncludesDir

    No default. If set, this directory will also be used to look for includes when
    compiling scripts. By default the directory the script is in, and the Global
    directory are checked for includes.

    This extension was added so that includes could be easily shared between ASP
    applications, whereas placing includes in the Global directory only allows
    sharing between scripts in an application.

        __PACKAGE__->config('CatalystX::ASP' => {
          IncludeDirs => '.' });

    Also, multiple includes directories may be set:

        __PACKAGE__->config('CatalystX::ASP' => {
          IncludeDirs => ['../shared', '/usr/local/asp/shared'] });

    Using IncludesDir in this way creates an includes search path that would look
    like `.`, `Global`, `../shared`, `/usr/local/asp/shared`. The current
    directory of the executing script is checked first whenever an include is
    specified, then the `Global` directory in which the `global.asa` resides, and
    finally the `IncludesDir` setting.

- MailHost

    The mail host is the SMTP server that the below Mail\* config directives will
    use when sending their emails. By default [Net::SMTP](https://metacpan.org/pod/Net::SMTP) uses SMTP mail hosts
    configured in [Net::Config](https://metacpan.org/pod/Net::Config), which is set up at install time, but this setting
    can be used to override this config.

    The mail hosts specified in the Net::Config file will be used as backup SMTP
    servers to the `MailHost` specified here, should this primary server not be
    working.

        __PACKAGE__->config('CatalystX::ASP' => {
          MailHost => 'smtp.yourdomain.com.foobar' });

- MailFrom

    No default. Set this to specify the default mail address placed in the `From:`
    mail header for the `$Server->Mail()` API extension

        __PACKAGE__->config('CatalystX::ASP' => {
          MailFrom => 'youremail@yourdomain.com.foobar' });

- XMLSubsMatch

    Default is not defined. Set to some regexp pattern that will match all XML and
    HTML tags that you want to have perl subroutines handle. The is
    ["XMLSubs" in Apache::ASP](https://metacpan.org/pod/Apache::ASP#XMLSubs)'s custom tag technology ported to CatalystX::ASP, and can
     be used to create powerful extensions to your XML and HTML rendering.

    Please see XML/XSLT section for instructions on its use.

        __PACKAGE__->config('CatalystX::ASP' => {
          XMLSubsMatch => 'my:[\w\-]+' });

- Debug

    Currently only a placeholder. Only effect is to turn on stacktrace on `__DIE__`
    signal.

# OBJECTS

The beauty of the ASP Object Model is that it takes the burden of CGI and
Session Management off the developer, and puts them in objects accessible from
any ASP script and include. For the perl programmer, treat these objects as
globals accessible from anywhere in your ASP application.

The CatalystX::ASP object model supports the following:

    Object        Function
    ------        --------
    $Session      - user session state
    $Response     - output to browser
    $Request      - input from browser
    $Application  - application state
    $Server       - general methods

These objects, and their methods are further defined in their respective
pod.

- [CatalystX::ASP::Session](https://metacpan.org/pod/CatalystX::ASP::Session)
- [CatalystX::ASP::Response](https://metacpan.org/pod/CatalystX::ASP::Response)
- [CatalystX::ASP::Request](https://metacpan.org/pod/CatalystX::ASP::Request)
- [CatalystX::ASP::Application](https://metacpan.org/pod/CatalystX::ASP::Application)
- [CatalystX::ASP::Server](https://metacpan.org/pod/CatalystX::ASP::Server)

If you would like to define your own global objects for use in your scripts and
includes, you can initialize them in the `global.asa` `Script_OnStart` like:

    use vars qw( $Form $App ); # declare globals
    sub Script_OnStart {
      $App  = MyApp->new;     # init $App object
      $Form = $Request->Form; # alias form data
    }

In this way you can create site wide application objects and simple aliases for
common functions.

# METHODS

These are methods available for the `CatalystX::ASP` object

- $self->search\_includes\_dir($include)

    Returns the full path to the include if found in IncludesDir

- $self->file\_id($file)

    Returns a file id that can be used a subroutine name when compiled

- $self->execute($c, $code)

    Eval the given `$code`. Requies the Catalyst `$context` object to be passed in
    first. The `$code` can be a ref to CODE or a SCALAR, ie. a string of code to
    execute. Alternatively, `$code` can be the absolute name of a subroutine.

- $self->cleanup()

    Cleans up objects that are transient. Get ready for the next request

# BUGS/CAVEATS

Obviously there are no bugs ;-) As of now, every known bug has been addressed.
However, a caveat is that not everything from Apache::ASP is implemented here.
Though the module touts itself to be a drop-in replacement, don't believe the
author and try it out for yourself first. You've been warned :-)

# AUTHOR

Steven Leung < sleung@cpan.org >

Joshua Chamas < asp-dev@chamas.com >

# SEE ALSO

- [Catalyst](https://metacpan.org/pod/Catalyst)
- [Apache::ASP](https://metacpan.org/pod/Apache::ASP)

# LICENSE AND COPYRIGHT

Copyright (C) 2016 Steven Leung

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
