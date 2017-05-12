package Apache::Dispatch;

#---------------------------------------------------------------------
#
# usage: PerlHandler Apache::Dispatch
#
#---------------------------------------------------------------------

use strict;
use warnings;

use mod_perl 1.2401;
use Apache::Constants qw(OK DECLINED SERVER_ERROR);
use Apache::Log			   ();
use Apache::Dispatch::Util ();

our $VERSION = 0.15;

BEGIN {
    push @Apache::Dispatch::ISA, qw(Apache::Dispatch::Util);

    {

        #---------------------------------------------------------------------
        # there is a problem with using command_table methods with inheritance
        # so here we map the command table directive names to the methods in
		# Apache::Dispatch::Util using the symbol table.  this allows us to
		# share the code between Apache::Dispatch and Apache2::Dispatch
        #---------------------------------------------------------------------

        my @dir_names =
          map { $_->{name} } @{Apache::Dispatch::Util->directives};
        no strict 'refs';
        foreach my $directive (@dir_names) {
            *{"Apache::Dispatch::$directive"} =
              \&{"Apache::Dispatch::Util::$directive"};
        }

    }
}

$Apache::Dispatch::PUREPERL = 0;    # set during perl Makefile.PL

if ($Apache::Dispatch::PUREPERL == 0) {
    require Apache::ModuleConfig;
    require DynaLoader;
    push @Apache::Dispatch::ISA, qw(DynaLoader);
    __PACKAGE__->bootstrap($VERSION);
}

sub handler {

    #---------------------------------------------------------------------
    # initialize request object and variables
    #---------------------------------------------------------------------

    my $r = shift;

    my $dcfg;
    if ($Apache::Dispatch::PUREPERL == 0) {
        $dcfg = Apache::ModuleConfig->get($r, __PACKAGE__);
    }
    else {
        $dcfg = get_pureperl_config($r);
    }

    my $filter = $dcfg->{_filter}
      || $r->dir_config('Filter')
      || 0;

    my $debug        = $dcfg->{_debug};
    my $autoload     = $dcfg->{_autoload};
    my $stat         = $dcfg->{_stat};
    my $prefix       = $dcfg->{_prefix};
    my $uppercase    = $dcfg->{_uppercase} || 'Off';
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

    $log->debug("Using Apache::Dispatch") if $debug;

    # redefine $r as necessary for Apache::Filter 1.013 and above
    if ($filter) {
        $log->debug("\tregistering handler with Apache::Filter") if $debug > 1;

        # in case we used DispatchFilter directive instead, make sure
        # that other filters in the chain recognize us...
        $r->dir_config->set(Filter => 'On');
		
		require Apache::Filter;
		$r   = $r->filter_register;
        $log = $r->server->log;
    }

    $log->debug("\tchecking $uri for possible dispatch...") if $debug > 1;

    # if the uri contains any characters we don't like, bounce...
    # is this necessary?
    if (__PACKAGE__->bogus_uri($uri)) {
        if ($debug) {
            $log->error("\t$uri has bogus characters...");
            $log->debug("Exiting Apache::Dispatch") if $debug;
        }
        return DECLINED;
    }

    if ($debug > 1) {
        $log->debug(
                   "\tapplying the following dispatch rules:",
                   "\n\t\tDispatchPrefix: ",
                   $prefix,
                   "\n\t\tDispatchUpperCase: ",
                   $uppercase,
                   "\n\t\tDispatchStat: ",
                   $stat,
                   "\n\t\tDispatchFilter: ",
                   $filter,
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
                  );
    }

    #---------------------------------------------------------------------
    # create the new object
    #---------------------------------------------------------------------

    my ($class, $method) =
      __PACKAGE__->_translate_uri($r, $prefix, $new_location, $log, $debug);

    unless ($class && $method) {
        $log->error("\tclass and method could not be discovered");
        $log->debug("Exiting Apache::Dispatch") if $debug;;
        return DECLINED;
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
            $log->debug("Exiting Apache::Dispatch") if $debug;
            return DECLINED;
        }
    }

    #---------------------------------------------------------------------
    # require the module if DispatchRequire On
    #---------------------------------------------------------------------

    if ($require) {
        $log->debug("\tattempting to require $class...") if $debug > 1;

        eval "require $class";

        if ($@) {
            $log->error("\tcould not require $class: $@");
            $log->debug("Exiting Apache::Dispatch") if $debug;
            return DECLINED;
        }
        else {
            $log->debug("\t$class required successfully") if $debug > 1;
        }
    }

    #---------------------------------------------------------------------
    # reload the module if DispatchStat On or ISA
    #---------------------------------------------------------------------

    if ($stat eq "ON") {
        $rc = __PACKGE__->_stat($class, $log, $debug);

        unless ($rc) {
            $log->error("\tDispatchStat did not return successfully!");
            $log->debug("Exiting Apache::Dispatch") if $debug;
            return DECLINED;
        }
    }
    elsif ($stat eq "ISA") {
        $rc = __PACKAGE__->_recurse_stat($class, $log, $debug);

        unless ($rc) {
            $log->error("\tDispatchStat did not return successfully!");
            $log->debug("Exiting Apache::Dispatch") if $debug;
            return DECLINED;
        }
    }

    #---------------------------------------------------------------------
    # see if the handler is a valid method
    # if not, decline the request
    #---------------------------------------------------------------------

    my $handler =
      __PACKAGE__->_check_dispatch($object, $method, $autoload, $log, $debug);

    if ($handler) {
        $log->debug("\t$uri was translated into $class->$method") if $debug;
    }
    else {
        $log->error("\t$uri did not result in a valid method");
        $log->debug("Exiting Apache::Dispatch") if $debug;
        return DECLINED;
    }

    #---------------------------------------------------------------------
    # since the uri is dispatchable, check each of the extras
    #---------------------------------------------------------------------
    foreach my $extra (@extras) {
        if ($extra eq "PRE") {
            $prehandler =
              __PACKAGE__->_check_dispatch($object, "pre_dispatch", $autoload,
                                           $log, $debug);
        }
        elsif ($extra eq "POST") {
            $posthandler =
              __PACKAGE__->_check_dispatch($object, "post_dispatch", $autoload,
                                           $log, $debug);
        }
        elsif ($extra eq "ERROR") {
            $errorhandler =
              __PACKAGE__->_check_dispatch($object, "error_dispatch", $autoload,
                                           $log, $debug);
        }
    }

    #---------------------------------------------------------------------
    # run each of the enabled methods, ignoring pre and post errors
    #---------------------------------------------------------------------

    eval { $object->$prehandler($r) } if $prehandler;

    eval { $rc = $object->$handler($r) };

    if ($errorhandler && ($@ || $rc != OK)) {

        # if the error handler dies we want to catch it, so don't eval
        $rc = $object->$errorhandler($r, $@, $rc);
    }
    elsif ($@) {
        $log->error("$class->$method died: $@");
        $rc = SERVER_ERROR;
    }

    eval { $object->$posthandler($r) } if $posthandler;

    #---------------------------------------------------------------------
    # wrap up...
    #---------------------------------------------------------------------

    $log->debug("\tApache::Dispatch is returning $rc") if $debug;
    $log->debug("Exiting Apache::Dispatch") if $debug;
    return $rc;
}

#*********************************************************************
# the below methods are not part of the external API
#*********************************************************************

#---------------------------------------------------------------------
# Pure Perl configuration methods
#---------------------------------------------------------------------

sub get_pureperl_config {
    my $r   = shift;
    my $cfg = {};
    no strict 'refs';
    foreach my $key (
        qw(DispatchPrefix DispatchExtras DispatchStat DispatchAUTOLOAD DispatchDebug DispatchISA DispatchLocation DispatchRequire DispatchFilter DispatchUpperCase)
      )
    {
        my $arg = $r->dir_config($key);
        next unless $arg;
        &$key($cfg, undef, $arg);
    }
    return $cfg;
}

1;

__END__

=head1 NAME

Apache::Dispatch - call PerlHandlers with the ease of Registry scripts

=head1 SYNOPSIS

Makefile.PL:

    # require util since it can be used outside an apache process
    PREREQ_PM    => {
        'Apache::Dispatch::Util'    => 0.11,
    }

httpd.conf:

  PerlModule Apache::Dispatch
  PerlModule Bar

  DispatchExtras Pre Post Error
  DispatchStat On
  DispatchISA "My::Utils"
  DispatchAUTOLOAD Off

  <Location /Foo>
    SetHandler perl-script
    PerlHandler Apache::Dispatch

    DispatchPrefix Bar
    DispatchFilter Off
  </Location>

=head1 DESCRIPTION

Apache::Dispatch translates $r->uri into a class and method and runs
it as a PerlHandler.  Basically, this allows you to call PerlHandlers
as you would Regsitry scripts without having to load your httpd.conf
with a slurry of <Location> tags.

=head1 EXAMPLE

  in httpd.conf

    PerlModule Apache::Dispatch
    PerlModule Bar

    <Location /Foo>
      SetHandler perl-script
      PerlHandler Apache::Dispatch

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
    Using Apache::Dispatch from a <Directory> directive, either 
    directly or from a .htaccess file, will _require_ the use of
    DispatchLocation, which defines the location from which
    Apache::Dispatch will start class->method() translation.
    For example:

      httpd.conf
        DocumentRoot /usr/local/apache/htdocs
        <Directory /usr/local/apache/htdocs/>
          ...
        <Directory>

     .htaccess (in /usr/local/apache/htdocs/Foo)
        SetHandler perl-script
        PerlHandler Apache::Dispatch
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

      Error - If the main handler returns other than OK then 
              Foo->error_dispatch($r, $@) is called and return status
              of it is returned instead.  Unlike the pre and post
              processing routines above, error_dispatch is not wrapped
              in an eval, so if it dies, the Apache::Dispatch dies,
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

  DispatchDebug
    Set DispatchDebug to 1 or 2 to control the verbosity of
    debug statements.
  
=head1 SPECIAL CODING GUIDELINES

Migrating to Apache::Dispatch is relatively painless - it requires
only a few minor code changes.  The good news is that once you adapt
code to work with Dispatch, it can be used as a conventional mod_perl
method handler, requiring only a few considerations.  Below are a few
things that require attention.

In the interests of security, all handler methods must be prefixed
with 'dispatch_', which is added to the uri behind the scenes.  Unlike
ordinary mod_perl handlers, for Apache::Dispatch there is no default
method (with a tiny exception - see NOTES below).

Apache::Dispatch uses object oriented calls behind the scenes.  This 
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

If you want to use the handler unmodified outside of Apache::Dispatch,
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

=head1 FILTERING

Apache::Dispatch provides for output filtering using Apache::Filter
1.013 and above.

  <Location /Foo>
    SetHandler perl-script
    PerlHandler Apache::Dispatch Apache::Compress

    DispatchPrefix Bar
    DispatchFilter On
  </Location>

Your handler need do nothing special to make its output the start of
the chain - Apache::Dispatch registers itself with Apache::Filter and
hides the task from your handler.  Thus, any dispatched handler is
automatically Apache::Filter ready without the need for additional
code.

The only caveat is that you must use the request object that is passed
to the handler and not get it directly using Apache->request.

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
[a-zA-Z0-9_/-] Apache::Dispatch declines to handle the request.

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

If a module fails reload under DispatchStat, Apache::Dispatch declines
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
