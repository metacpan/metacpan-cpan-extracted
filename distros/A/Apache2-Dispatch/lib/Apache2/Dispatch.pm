package Apache2::Dispatch;

#---------------------------------------------------------------------
#
# usage: PerlHandler Apache2::Dispatch
#
#---------------------------------------------------------------------

use strict;
use warnings;

use mod_perl2 1.99023;
use Apache2::Const -compile => qw(OK DECLINED SERVER_ERROR);
use Apache2::Log         ();
use Apache2::Module      ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache::Dispatch::Util;
push @Apache2::Dispatch::ISA, qw(Apache::Dispatch::Util);

our $VERSION = 0.15;

# Initialize the directives
my $directives = __PACKAGE__->directives();

Apache2::Module::add(__PACKAGE__, $directives);

sub handler {

    #---------------------------------------------------------------------
    # initialize request object and variables
    #---------------------------------------------------------------------
    my $r = shift;

    my $dcfg;

	$dcfg =
      Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);

    my $debug        = $dcfg->{_debug} || 0;
    my $autoload     = $dcfg->{_autoload};
    my $stat         = $dcfg->{_stat};
    my $prefix       = $dcfg->{_prefix};
    my $uppercase    = $dcfg->{_uppercase} || 0;
    my $new_location = $dcfg->{_newloc};
    my $require      = $dcfg->{_require};
    my @parents      = $dcfg->{_isa} ? @{$dcfg->{_isa}} : ();
    my @extras       = $dcfg->{_extras} ? @{$dcfg->{_extras}} : ();
    my $log          = $r->server->log;
    my $uri          = $r->uri;

    my ($prehandler, $posthandler, $errorhandler, $rc);

    #---------------------------------------------------------------------
    # do some preliminary stuff...
    #---------------------------------------------------------------------

    $log->debug("Using Apache2::Dispatch, debug level $debug") if $debug;

    $log->debug("\tchecking $uri for possible dispatch...")
      if $debug > 1;

    # if the uri contains any characters we don't like, bounce...
    if (__PACKAGE__->bogus_uri($uri)) {
        if ($debug) {

            $log->debug("\t$uri has bogus characters...");
            $log->debug("Exiting Apache2::Dispatch");
        }
        return Apache2::Const::DECLINED;
    }

    $log->debug(
                    "\tapplying the following dispatch rules:",
                    "\n\t\tDispatchPrefix: ",
                    $prefix,
                    "\n\t\tDispatchUpperCase: ",
                    $uppercase,
                    "\n\t\tDispatchStat: ",
                    $stat,
                    "\n\t\tDispatchDebug: ",
                    $debug,
                    "\n\t\tDispatchLocation: ",
                    $new_location ? $new_location : "Unaltered",
                    "\n\t\tDispatchAUTOLOAD: ",
                    $autoload,
                    "\n\t\tDispatchRequire: ",
                    $require,
                    "\n\t\tDispatchExtras: ",
                    (@extras ? (join ' ', @extras) : "None"),
                    "\n\t\tDispatchISA: ",
                    (@parents ? (join ' ', @parents) : "None"),
    ) if $debug > 1;

    #---------------------------------------------------------------------
    # create the new object
    #---------------------------------------------------------------------

    my ($class, $method) =
      __PACKAGE__->_translate_uri($r, $prefix, $new_location, $log, $debug);

    unless ($class && $method) {
        $log->debug("\tclass and method could not be discovered");
        $log->debug("Exiting Apache2::Dispatch");
        return Apache2::Const::DECLINED;
    }

    if ($uppercase) {
        $class =~ s/::([a-z])/::\U$1/g;
    }

    my $object = {};

    bless $object, $class;

    #---------------------------------------------------------------------
    # set parent classes for DispatchISA
    #---------------------------------------------------------------------

    if (@parents) {
        $rc = __PACKAGE__->_set_ISA($prefix, $log, @parents);

        unless ($rc) {
            $log->error("\tDispatchISA did not return successfully!");
            $log->debug("Exiting Apache2::Dispatch") if $debug;
            return Apache2::Const::DECLINED;
        }
    }

    #---------------------------------------------------------------------
    # require the module if DispatchRequire On
    #---------------------------------------------------------------------

    if ($require) {
        $log->debug("\tattempting to require $class...") if $debug > 1;

        eval "require $class";

        if ($@) {
            $log->warn("\tcould not require $class: $@");
            $log->debug("Exiting Apache2::Dispatch") if $debug;
            return Apache2::Const::DECLINED;
        }
        else {
            $log->debug("\t$class required successfully") if $debug > 1;
        }
    }

    #---------------------------------------------------------------------
    # reload the module if DispatchStat On or ISA
    #---------------------------------------------------------------------

    if ($stat eq "ON") {
        $rc = __PACKAGE__->_stat($class, $log);

        unless ($rc) {
            $log->error("\tDispatchStat did not return successfully!");
            $log->debug("Exiting Apache2::Dispatch") if $debug;
            return Apache2::Const::DECLINED;
        }
    }
    elsif ($stat eq "ISA") {
        $rc = __PACKAGE__->_recurse_stat($class, $log);

        unless ($rc) {
            $log->error("\tDispatchStat did not return successfully!");
            $log->debug("Exiting Apache2::Dispatch") if $debug;
            return Apache2::Const::DECLINED;
        }
    }

    #---------------------------------------------------------------------
    # see if the handler is a valid method
    # if not, decline the request
    #---------------------------------------------------------------------

    my $handler = __PACKAGE__->_check_dispatch($object, $method, $autoload, $log, $debug);

    if ($handler) {
        $log->debug("\t$uri was translated into $class->$method") if $debug;
    }
    else {
        $log->error("\t$uri did not result in a valid method");
        $log->debug("Exiting Apache2::Dispatch") if $debug;
        return Apache2::Const::DECLINED;
    }

    #---------------------------------------------------------------------
    # since the uri is dispatchable, check each of the extras
    #---------------------------------------------------------------------
    foreach my $extra (@extras) {
        if ($extra eq "PRE") {
            $prehandler =
              __PACKAGE__->_check_dispatch($object, "pre_dispatch", $autoload, $log, $debug);
        }
        elsif ($extra eq "POST") {
            $posthandler =
              __PACKAGE__->_check_dispatch($object, "post_dispatch", $autoload, $log, $debug);
        }
        elsif ($extra eq "ERROR") {
            $errorhandler =
              __PACKAGE__->_check_dispatch($object, "error_dispatch", $autoload, $log, $debug);
        }
    }

    #---------------------------------------------------------------------
    # run each of the enabled methods, ignoring pre and post errors
    #---------------------------------------------------------------------

    eval { $object->$prehandler($r) } if $prehandler;

    eval { $rc = $object->$handler($r) };

    if ($errorhandler && ($@ || $rc != Apache2::Const::OK)) {

        # if the error handler dies we want to catch it, so don't eval
        $rc = $object->$errorhandler($r, $@, $rc);
    }
    elsif ($@) {
        $log->error("$class->$method died: $@");
        $rc = Apache2::Const::SERVER_ERROR;
    }

    eval { $object->$posthandler($r) } if $posthandler;

    #---------------------------------------------------------------------
    # wrap up...
    #---------------------------------------------------------------------

    $log->debug("\tApache2::Dispatch is returning $rc") if $debug;

    $log->debug("Exiting Apache2::Dispatch") if $debug;

    return $rc;
}

1;

__END__

=head1 NAME

Apache2::Dispatch - call PerlHandlers with the ease of Registry scripts

=head1 SYNOPSIS

Makefile.PL:

    # require util since it can be used outside an apache process
    PREREQ_PM    => {
        'Apache::Dispatch::Util'    => 0.11,

httpd.conf:

  PerlLoadModule Apache2::Dispatch
  PerlLoadModule Bar

  DispatchExtras Pre Post Error
  DispatchStat On
  DispatchISA "My::Utils"
  DispatchAUTOLOAD Off

  <Location /Foo>
    SetHandler perl-script
    PerlHandler Apache2::Dispatch

    DispatchPrefix Bar
    DispatchFilter Off
  </Location>

=head1 DESCRIPTION

Apache2::Dispatch translates $r->uri into a class and method and runs
it as a PerlHandler.  Basically, this allows you to call PerlHandlers
as you would Regsitry scripts without having to load your httpd.conf
with a slurry of <Location> tags.

=head1 EXAMPLE

  in httpd.conf

    PerlModule Apache2::Dispatch
    PerlModule Bar

    <Location /Foo>
      SetHandler perl-script
      PerlHandler Apache2::Dispatch

      DispatchPrefix Bar
    </Location>

  in browser:
    http://localhost/Foo/baz

  the results are the same as if your httpd.conf looked like:
    <Location /Foo>
      SetHandler perl-script
      PerlHandler Bar->dispatch_baz
    </Location>

but with the additional security of protecting the class name from
the browser and keeping the method name from being called directly.
Because any class under the Bar:: hierarchy can be called, one
<Location> directive is able to handle all the methods of Bar,
Bar::Baz, etc...

=head1 CONFIGURATION DIRECTIVES

  DispatchPrefix
    The base class to be substituted for the $r->location part of the
    uri.

  DispatchLocation
    Using Apache2::Dispatch from a <Directory> directive, either 
    directly or from a .htaccess file, will _require_ the use of
    DispatchLocation, which defines the location from which
    Apache2::Dispatch will start class->method() translation.
    For example:

      httpd.conf
        DocumentRoot /usr/local/apache/htdocs
        <Directory /usr/local/apache/htdocs/>
          ...
        <Directory>

     .htaccess (in /usr/local/apache/htdocs/Foo)
        SetHandler perl-script
        PerlHandler Apache2::Dispatch
        DispatchPrefix Baz
        DispatchLocation /Foo

    This allows a request to /Foo/Bar/biff to properly map to
    Baz::Bar->biff().  

    While intended specifically for <Directory> configurations, one
    could use DispatchLocation to further obscure uri translations
    within <Location> sections as well by changing the part of
    the uri that is substitued with your module.

  DispatchExtras
    An optional list of extra processing to enable per-request.  If
    the main handler is not a valid method call, the request is 
    declined prior to the execution of any of the extra methods.

      Pre   - eval()s Foo->pre_dispatch($r) prior to dispatching the
              uri.  The $@ of the eval is not checked in any way.

      Post  - eval()s Foo->post_dispatch($r) after dispatching the
              uri.  The $@ of the eval is not checked in any way.

      Error - If the main handler returns other than Apache2::Const::OK then 
              Foo->error_dispatch($r, $@) is called and return status
              of it is returned instead.  Unlike the pre and post
              processing routines above, error_dispatch is not wrapped
              in an eval, so if it dies, the Apache2::Dispatch dies,
              and Apache will process the error using ErrorDocument,
              custom_response(), etc.
              With error_dispatch() disabled, the return status of the
              the main handler is returned to the client.

  DispatchRequire
    An optional directive that enables require()ing of the module that
    is the result of the uri to class->method translation.  This allows
    your configuration to be a bit more dynamic, but also decreases
    security somewhat.  And don't forget that you really should be
    pre-loading frequently used modules in the parent process to reduce
    overhead - DispatchRequire is a directive of conveinence.

      On    - require() the module

      Off   - Do not require() the module (Default)

  DispatchStat
    An optional directive that enables reloading of the module that is
    the result of the uri to class->method translation, similar to
    Apache::Registry, Apache::Reload, or Apache::StatINC.

      On    - Test the called package for modification and reload on
              change

      Off   - Do not test or reload the package (Default)

      ISA   - Test the called package, and all other packages in the
              called package's @ISA, and reload on change

  DispatchAUTOLOAD
    An optional directive that enables unknown methods to use 
    AutoLoader.  It may be applied on a per-server or per-location
    basis and defaults to Off.  Please see the special section on 
    AUTOLOAD below.

      On    - Allow for methods to be defined in AUTOLOAD method

      Off   - Turn off search for AUTOLOAD method (Default)
    
  DispatchISA
    An optional list of parent classes you want your dispatched class
    to inherit from.

  DispatchFilter 
    If you have Apache::Filter 1.013 or above installed, you can take
    advantage of other Apache::Filter aware modules.  Please see the
    section on FILTERING below.  In keeping with Apache::Filter
    standards, PerlSetVar Filter has the same effect as DispatchFilter
    but with lower precedence.

      On    - make the output of your module Apache::Filter aware

      Off   - do not use Apache::Filter (Default)

=head1 SPECIAL CODING GUIDELINES

Migrating to Apache2::Dispatch is relatively painless - it requires
only a few minor code changes.  The good news is that once you adapt
code to work with Dispatch, it can be used as a conventional mod_perl
method handler, requiring only a few considerations.  Below are a few
things that require attention.

In the interests of security, all handler methods must be prefixed
with 'dispatch_', which is added to the uri behind the scenes.  Unlike
ordinary mod_perl handlers, for Apache2::Dispatch there is no default
method (with a tiny exception - see NOTES below).

Apache2::Dispatch uses object oriented calls behind the scenes.  This 
means that you either need to account for your handler to be called
as a method handler, such as

  sub dispatch_bar {
    my $self  = shift;  # your class
    my $r     = shift;
  }

or get the Apache request object directly via

  sub dispatch_bar {
    my $r     = Apache->request;
  }

If you want to use the handler unmodified outside of Apache2::Dispatch,
you must do three things:

  prototype your handler:

    sub dispatch_baz ($$) {
      my $self  = shift;
      my $r     = shift;
    }

  change your httpd.conf entry:

    <Location /Foo>
      SetHandler perl-script
      PerlHandler Bar->dispatch_baz
    </Location>

  pre-load your module:
    PerlModule Bar
      or
    PerlRequire startup.pl
    # where startup.pl contains
    # use Bar;

That's it - now the handler can be swapped in and out of Dispatch 
without further modification.  See the Eagle book on method handlers
for more details.

=head1 AUTOLOAD

Support for AUTOLOAD has been made optional, but requires special
care.  Please take the time to read the camel book on using AUTOLOAD
with can() and subroutine declarations (3rd ed pp326-329).

Basically, you declare the methods you want AUTOLOAD to capture by 
name at the top of your script.  This is necessary because can() 
will return true if your class (or any parent class) contains an
AUTOLOAD method, but $AUTOLOAD will only be populated for declared
method calls.  Hence, without a declaration you won't be able to
get at the name of the method you want to AUTOLOAD.

DispatchISA introduced some convenience, but some headaches as well - 
if you inherit from a class that uses AutoLoader then ALL method calls
are true.  And as just explained, AUTOLOAD() will not know what the
called method was.  This may represent a problem if you aren't aware
that, say, CGI.pm uses AutoLoader and spend a few hours trying to 
figure out why all of a sudden every URL under Dispatch is bombing.
You may want to check out NEXT.pm (available from CPAN) for use in 
your AUTOLOAD routines to help circumvent this partucular feature.

If you decide to use DispatchISA it is HIGHLY SUGGESTED that you do so
with DispatchAUTOLOAD Off (which is the default behavior).

=head1 NOTES

If you define a dispatch_index() method calls to /Foo will default to
it.  Unfortunately, this implicit translation only happens at the
highest level - calls to /Foo/Bar will translate to Foo->Bar() (that
is, unless Foo::Bar is your DispatchPrefix, in which case it will
work but /Foo/Bar/Baz will not, etc).  Explicit calls to /Foo/index
follow the normal dispatch rules.

If the uri can be dispatched but contains anything other than
[a-zA-Z0-9_/-] Apache2::Dispatch declines to handle the request.

Like everything in perl, the package names are case sensitive.

Warnings have been left on, so if you set an invalid class with
DispatchISA you will see a message like:
  Can't locate package Foo::Bar for @Bar::Baz::ISA at 
  .../Apache/Dispatch.pm line 277.

This is alpha software, and as such has not been tested on multiple
platforms or environments for security, stability or other concerns.
It requires PERL_DIRECTIVE_HANDLERS=1, PERL_LOG_API=1, PERL_HANDLER=1,
and maybe other hooks to function properly.

=head1 FEATURES/BUGS

If a module fails reload under DispatchStat, Apache2::Dispatch declines
the request.  This might change to SERVER_ERROR in the future...

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3), Apache::Filter(3), Apache::Reload(3),
Apache::StatINC(3)

=head1 MAINTAINER

Fred Moyer <phred@apache.org>

=head1 AUTHOR

Geoffrey Young <geoff@cpan.org>

=head1 COPYRIGHT

Copyright 2001-2006 Geoffrey Young - all rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
