package CGI::Builder ;
$VERSION = 1.36 ;
use strict ;         

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use 5.006_001
; use Carp
; $Carp::Internal{+__PACKAGE__}++
; $Carp::Internal{__PACKAGE__.'::_'}++
; use IO::Util
; use Class::Util
; use warnings::register

; my @phase
; BEGIN
   { @phase  = qw | CB_INIT
                    GET_PAGE
                    PRE_PROCESS
                    SWITCH_HANDLER
                    PRE_PAGE
                    PAGE_HANDLER
                    FIXUP
                    RESPONSE
                    REDIR
                    CLEANUP
                  |
   ; no strict 'refs'
   ; foreach my $i (0..$#phase)
      { *{$phase[$i]} = sub(){$i}
      }
   }
 
; sub phase
   { $phase[$_[1]||$_[0]->PHASE]
   }

; sub capture
   { my ($s, $h, @args) =  @_
   ; IO::Util::capture{ $s->$h(@args) }
   }

; sub import
   { my ($cbb, $CB, @ext) = (scalar caller, @_)
   ; Class::Util::load for @ext
   ; no strict 'refs'
   ; foreach my $c (reverse @_)
      { push @{$cbb.'::ISA'}, $c unless $cbb->isa($c)
      }
   ; $cbb->isa('Apache::CGI::Builder') && $Apache::CGI::Builder::usage
     && carp $Apache::CGI::Builder::usage
   ; my $sub = sub
                { +{ map
                      { my $h = $_
                      ; my @op = grep
                                  { defined &{$_.'::OH_'.$h}
                                  }
                                  $h =~ /up$/   # ;-)
                                  ? reverse ($CB, @ext, $cbb)
                                  :         ($CB, @ext, $cbb)
                      ; @op ? ($h => \@op) : ()
                      }
                      qw| init pre_process pre_page fixup cleanup |
                   }
                }
   ; eval qq
      ! package $cbb
      ; use Class::groups
          { name    => 'overrun_handler_map'
          , default => \$sub
          }
      ; *import = sub{} unless defined &import
      !
   }

; my $exec = \&CGI::Builder::_::exec
   
; sub CGI::Builder::_::exec
   { my $s = shift
   ; my $h = shift
   ; Class::Util::gather { $s->$_(@_) } '&OH_'.$h
     , $s->overrun_handler_map($h)
   }

; use Class::constr
  ( { init      => \&CGI::Builder::_::init
    , no_strict => 1
    }
  )
        
; sub CGI::Builder::_::init
   { my $s = shift
   ; local $SIG{__DIE__} = sub{$s->die_handler(@_)}
   ; $s->$exec('init', @_)
   }
   
; use Class::groups  qw | overrun_handler_map
                          switch_handler_map
                          page_handler_map
                        |
; use Object::groups qw | param
                          header
                          page_error
                        |
; use Class::props
  ( { name       => 'no_page_content_status'
    , default    => '204 No Content'
    }
  )
  
; use Object::props
  ( { name       => 'PHASE'
    , default    => CB_INIT
    , allowed    => qr/^CGI::Builder/  # only settable from CBF
    }
  , { name       => 'cgi_page_param'
    , default    => 'p'
    }
  , { name       => 'cgi'
    , default    => sub{ shift()->cgi_new }
    }
  , { name       => 'page_name'
    , default    => 'index'
    }
  , { name       => 'requested_page'
    , allowed    => qw/^CGI::Builder::process$/
    }
  , { name       => 'page_path'
    , default    => './tm'
    , no_strict  => 1    # doesn't croak if ./tm is not a directory
    , validation => sub { -d or croak "'$_' is not a directory, died" }
    }
  , { name       => [ qw| page_content page_suffix | ]
    , default    => ''
    }
  , 'dont_send_header'
  )

; our $AUTOLOAD
; sub AUTOLOAD : lvalue              # param AUTOLOADING
   { (my $n = $AUTOLOAD) =~ s/.*://
   ; carp qq(Use of unprefixed autoloaded parameter "$n". )
        . qq(Autoloaded parameters should start with 'my_' or '_')
     if warnings::enabled && $n !~ /^(?:my)?_/
   ; @_ == 2
     ? ( $_[0]{param}{$n} = $_[1] )
     :   $_[0]{param}{$n}
   }
 
; sub DESTROY {}

; sub cgi_new
   { require CGI
   ; CGI->new
   }

; sub process
   { my ($s, $p) = @_
   ; local $SIG{__DIE__} = sub{$s->die_handler(@_)}
   ; $s->PHASE(GET_PAGE)
   ; if ( defined $p && length $p )
      { $s->requested_page($p)
      ; $s->page_name($p)
      }
     else
      { $s->requested_page( $s->get_page_name() )
      }
   ; if ($s->PHASE < PRE_PROCESS)
      { $s->PHASE(PRE_PROCESS)
      ; $s->$exec('pre_process')
      }
   ; if ($s->PHASE < SWITCH_HANDLER)
      { $s->switch_to( $s->page_name )
      }
   ; if ($s->PHASE < FIXUP)
      { $s->PHASE(FIXUP)
      ; $s->$exec('fixup')
      }
   ; if ($s->PHASE < RESPONSE)
      { $s->PHASE(RESPONSE)
      ; my $has_content = $s->page_content_check
      ; $s->header( -status => $s->no_page_content_status )
            unless $has_content || defined $s->header->{-status}
      ; $s->send_header() unless $s->dont_send_header
      ; $s->send_content() if $has_content
      }
   ; $s->PHASE(CLEANUP)
   ; $s->$exec('cleanup') # done however
   }

; sub switch_to
   { my ($s, $p) = splice @_, 0, 2
   ; $s->PHASE < PRE_PROCESS && croak 'Too early to call switch_to(), died'
   ; $s->PHASE > FIXUP       && croak 'Too late to call switch_to(), died'
   ; defined $p && length $p || croak 'No page_name name passed, died'
   ; $s->page_name($p)
   ; $s->PHASE(SWITCH_HANDLER)
   ; my $shm = $s->switch_handler_map
   ; my $SH  = $$shm{$p} || $s->can("SH_$p")
   ; $s->$SH(@_) if $SH
   ; if ($s->PHASE < PRE_PAGE)
      { $s->PHASE(PRE_PAGE)
      ; $s->$exec('pre_page')
      }
   ; if ($s->PHASE < PAGE_HANDLER)
      { $s->PHASE(PAGE_HANDLER)
      ; my $phm = $s->page_handler_map
      ; my $PH  =  $$phm{$p}        || $s->can("PH_$p")
                || ! $s->page_content_check
                && ($$phm{AUTOLOAD} || $s->can('PH_AUTOLOAD'))
      ; $s->$PH(@_) if $PH
      }
   }

; sub get_page_name
   { my $s = shift
   ; my $p = $s->cgi->param($s->cgi_page_param)
   ; $s->page_name($p) if defined($p) && length($p)
   }

; sub page_content_check
   { length $_[0]->page_content
   }
   
; sub send_header
   { print $_[0]->cgi->header( %{$_[0]->header} )
   }

; sub send_content
   { my $pc = $_[0]->page_content
   ; if ( ref $pc eq 'CODE' )
      { $_[0]->$pc
      }
     elsif ( ref $pc eq 'SCALAR' )
      { print $$pc
      }
     elsif ( not ref $pc )
      { print $pc
      }
   }

; sub redirect
   { my ($s, $url) = @_
   ; $s->PHASE < GET_PAGE        && croak 'Too early to call redirect(), died'
   ; $s->PHASE > RESPONSE        && croak 'Too late to call redirect(), died'
   ; defined $url && length $url || croak 'No URL passed, died'
   ; $s->PHASE(REDIR)
   ; $s->header(-url => $url)
   ; print $s->cgi->redirect( %{$s->header} )
   }

; sub die_handler
   { my ( $s, $msg ) = @_
   ; for ( my $i = 1
         ; my $sub = (caller($i))[3]
         ; $i++
         )
      { die $msg if $sub eq '(eval)' && (caller($i+1))[3]
      }
   ; die sprintf 'Fatal error in phase %s for page "%s": %s'
               , $s->phase
               , $s->page_name
               , $msg
   }
   
; 1

__END__

=pod

=head1 NAME

CGI::Builder - Framework to build simple or complex web-apps

=head1 VERSION 1.36

Included in CGI-Builder 1.36 distribution.

The latest versions changes are reported in the F<Changes> file in this distribution.

=head1 INSTALLATION

=over

=item Prerequisites

    Perl version >= 5.6.1
    OOTools      >= 2.1
    IO::Util     >= 1.46

=item CPAN

    perl -MCPAN -e 'install CGI::Builder'

You have also the possibility to use the Bundle to install all the extensions and prerequisites of the CBF in just one step. Please, notice that the Bundle will install A LOT of modules that you might not need, so use it specially if you want to extensively try the CBF.

    perl -MCPAN -e 'install Bundle::CGI::Builder::Complete'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

    # define your build
    use CGI::Builder
    qw| CGI::Builder::AnyExtension
        AnySuperClass
      |;

=head1 DESCRIPTION

This is the starting point of the documentation of the CGI Builder Framework (CBF). You should read this documentation before any other documentation in any other module that extends the CBF.

=head1 IMPORTANT INFO

The CBF is growing quickly, likewise its features, documentation and resources: if you use it and you have not subscribed the L<cgi-builder-announce> mailing list, you should remember to check at least monthly for new releases and ALWAYS read the F<Changes> file.

=head2 Mailing lists

The CBF has 3 mailing lists which may be very useful for developement:

=over

=item * cgi-builder-announce (IMPORTANT)

If you use the CBF, you should definitively subscribe this list, since it has a very low traffic (about 1-2 message per month) but informs you about new releases, improvements and fixes which B<you must not miss>.

L<http://lists.sourceforge.net/lists/listinfo/cgi-builder-announce>

=item * cgi-builder-users

This list is the CBF support mailing list, with a searchable archive full of examples and practical topics. You need to subscribe this list just if you need or give free support to/from other users. (see also L<"SUPPORT">)

L<http://lists.sourceforge.net/lists/listinfo/cgi-builder-users>

B<Note>: You could also search in the old CBF mailing list archive for previous posts (http://sourceforge.net/mailarchive/forum.php?forum=cgi-builder-users).

=item * cgi-builder-developers

This is the list reserved to the developers of the CBF and its Extensions: you must ask to be subscribed to this list, although you can browse the archive if you are interested in knowing what will come next in the CBF.

L<http://lists.sourceforge.net/lists/listinfo/cgi-builder-developers>

=back

=head2 Links

A simple and useful navigation system between the various CBF Extensions (and other modules used by the CBF) is available at this URL: L<http://perl.4pro.net>

=head2 Jobs

If you are interested in being hired as a developer for any commercial project, and if you have a good knowledge of the CBF, please send me a message with your CV including you usual hourly and monthly rate.

=head2 Applications

If you realize any interesting application by using the CBF and you want to share its link to increment your traffic, please send me a message. I am planning to publish a list of real world applications to show as successful CBF examples to the users. This will be a place where to show also information about your skills and other useful data about your work.

=head2 About CGI::Application and CGI::Application::Plus

B<Important Note>: If you are familiar with the API of these two modules, you will appreciate the L<CGI::Builder::CgiAppAPI|CGI::Builder::CgiAppAPI> which supplies an API compatible with those modules. It supplies also very useful hints which will suggest you what to change in your old code and what to read in the documentation in order to smoothly trasform your old cgiapp into a CGI::Builder application or simply learn this framework faster.

=head2 POD Conventions

=over

=item * CBF

the CGI::Builder framework

=item * CBA

the CGI::Builder application

=item * CBB

a CGI::Builder build (i.e. the application module that uses the CBF and eventually includes any extension)

=item * C::B

the CGI::Builder module

=item * C::B::foo

the CGI::Builder::foo extension (i.e. a module that will add some capability to the standard CBF)

=item * OH

means Overrun Handler

=item * PH

means Page Handler

=item * SH

means Switch Handler

=back

=head1 CGI Builder Framework (CBF)

B<Definition>: A "framework" in object-oriented systems, is a set of classes that embodies an abstract design for solutions to a number of related problems.

In simpler and more specific words, CBF is a set of modules providing the structure, the features and the solutions you need to easily write scalable, expandable, reusable and easy to maintain web applications (sometime called just 'CGI script' :-).

In even simpler words: if you invest a few hours in learning this documentation, you will save a lot of hours writing your future CGI scripts ;-).

=head2 Features

=over

=item Rapid Development

You inherit an efficient and flexible pre-built structure, a lot of useful, pre-configured and ready to use objects which will allow you to produce very compact, simple to write and maintain code.

=item * An easy tool for beginners and experts

The CBF handler approach make it easy the design of both simple and complex CGI applications with minimum programming effort. (see L<"Handlers">)

=item * Pre-structured process

The CBF implements a pre-structured and customizable CGI process, subdivided in phases to allow maximum process resolution and control. (see L<"Process Phases">)

=item * Memory Efficient

The whole CGI::Builder module is written in just 210 lines of code, very fast to load, very small footprint and very easy to maintain ;-). (see L<"Internal Structure">)

=item * Homogeneous Accessors

The programmer has just to learn the features of a couple of accessors (property and property group) to be able to use dozens of different accessors with the same friendly and consistent interface. (see L<"PROPERTY ACCESSORS"> and L<"PROPERTY GROUP ACCESSORS">)

=item * OOTools pragmas

When using OOTools, adding lots of new custom properties accessors or accessors added by extensions will practically not increase neither the loading time nor the memory reqirements. (see "Function Templates" in the F<perlref> manpage)

=item * Smart defaults always overridable

The default of this framework are usually smart enough to do the right job for you even without any specific assignation, anyway you can always easily override everything with your own code. (see L<"Overriding"> and L<"ADVANCED FEATURES">)

=item * Powerful and flexible extension system

The CBF extension system allows L<"Inheritance, Overriding and Overrunning"> which greatly simplify the development and the use of any super class or extension.

=item * Growing Extensions List

Your application can take the advantage of a broad L<"Extensions List"> already covering most needed tasks (and hopefully growing with the contribution of many authors).

=item * Consistent interface and internal structure

The internal structure mirrors the public interface, so no mistakes about public or private methods and keys which often cause conflict in other frameworks. (see L<"Internal Structure">)

=item * Clear Conventions and Guide Lines

The CBF clearly states the conventions and the guide lines to use in your code or in extensions, making it very simple to avoid clashes and inconsistency even with future extensions. (see L<"HOW TO...">)

=back

=head2 Concept

In a (very simplified) web client-server transaction, when a client requests a static html page to the server, the server sends that page to the client; when the object of the request is a CGI script, that script is supposed to somehow create the 'page' to be sent to the client.

B<Note>: In the CBF metaphor, the page concept is not strictly related with the HTML file concept: 'page' is just the most used name of the entity that is the object of the request/response transaction, and so we use it as a simple synonym of requested/served entity.

The CBF metaphor is constructed around this simple concept: the web application using the CBF is interfaced with the client through 'pages'. A B<page> (page_name) is requested by the client and a B<page> (page_content) is sent to the client as the response; what happens in between is a totally customizable application B<process> that your application inherits from the CBF.

The application process is segmented into L<"Process Phases"> which will call specific L<"Handlers"> to allow your application to execute code at specific time during the process.

B<Note>: You will find this technique very familiar if you have some knowledge about mod_perl handlers.

As for most CGI frameworks, a complete CGI application is usually composed by 2 parts: B<The Instance Script> and B<CGI Builder Build (CBB)>.

=head2 Instance Script

The instance script is used as the CGI script that manage the client's request: it is usually a very short script that just creates a new instance of your application class, and executes the process() method. This is a complete typical instance script needed to use e.g. the 'My::WebApp' CBB:

    #!/usr/bin/perl -w
    use My::WebApp ;
    $webapp = My::WebApp->new() ;
    $webapp->process() ;

B<Note>: This script could be completely eliminated by the use of the C<Apache::CGI::Builder> extension (usable under mod_perl) which transparently executes the process.

=head2 CGI Builder Build (CBB)

This is the part of your application that implements the CBF features.

B<Note>: In this documentation we call the package that uses C::B (and that eventually includes any extension and super class) a "CGI Builder Build" or simply CBB for shortness.

The CBB is not intended to be used as a CGI script by itself, but as a class defining the methods, properties and handlers needed to integrates the CBF capability to generates the pages with your very specific needs.

Your application will inherit the CBF capability by simply using the base module CGI::Builder:

    package My::WebApp;
    use CGI::Builder;

It can inherit from more extensions or super classes including them in the 'use' statement:

    package My::WebApp;
    use CGI::Builder
    qw| CGI::Builder::SomeExtension
        My::SuperClass
        ...
      |;

B<WARNING>: B<Don't use the statement 'use base 'CGI::Builder;'>. You must just B<'use'> C::B because the CGI::Builder::import sub has to setup the overruning methods and will internally update @ISA on its own (see details in the L<"import"> advanced method).

A complete CBB module is usually as simple as this one:

    package My::WebApp ;     # your class name
               
    # CBB definition
    use CGI::Builder
    qw| CGI::Builder::SomeExtension
        My::SuperClass
        ...
      |;
      
    # optional instance initialization executed for each request
    sub OH_init
    { ... }
    
    # optional Pre Process Handler executed for each request
    sub OH_pre_process
    { ... }
    
    # Switch Handler executed only when page_name is 'foo'
    sub SH_foo
    { ... }
    
    # Page Handler executed only when page_name is 'foo'
    sub PH_foo
    { ... }
    
    # Page Handler executed only when page_name is 'bar'
    sub PH_bar
    { ... }
    
    # optional Fixup Handler executed for each request
    sub OH_fixup
    { ... }
    
    # optional Cleanup Handler executed for each request
    sub OH_cleanup
    { ... }
    
    1;

=head2 Internal Structure

The CBF uses B<properties> and B<property groups> accessors to store and retrieve B<all> the internal data into and from the object.

The accessors to the internal data object are provided by the OOTools pragmas, which are very efficient function templates that the CBF imports at compile time. "This technique saves on both compile time and memory use, and is less error-prone as well, since syntax checks happen at compile time." (quoted from "Function Templates" in the F<perlref> manpage).

With just 2 imported methods (property and property group) the CBF can handle dozens of different properties in just a few lines, with the same memory and the same friendly and consistent interface.

Another benefit that comes from the use of OOTools is that the internal hash structure always mirrors the public interface. This is very important specially for a module like C::B that is supposed to be used as a base class. In the C::B and its extensions there are no dirty statements like

    $self->{__SOME_INTERNAL_STUFF} = 'something'

that may introduce an undocumented and possibly conflicting key and/or bypass the accessors.

This practice allows to avoid the conflict between extensions and allows any subclass to override anything with the warranty to have it changed across the whole classes included in the CBB.

Besides, there are no mistakes about the internal structure of the object: when you write your super class or any special extension, you don't need to go through all the source to see if any key has already been used for internal purpose, because ALL the used key are documented, just because all have a consistent public accessor that uses the same identifier.

    # this accessor
    $s->some_property
    
    # will always refer to
    $$s{some_property}
    
    # and will never refer to any inconsistent
    $$s{__SOME_PROPERTY}

B<Note>: In order to make your code forward/backward compatible, you should always use the provided accessors.

=head2 Process Phases

The CBF makes available to your sub class a pre-structured and very flexible process that your application will use to do what it need to do and produce the requested 'pages' with minimum programming effort.

This process is composed by the following phases, internally handled by the CBF. Each phase provides one or more hooks to allow your application to execute code at specific phases of the process and to customize the process itself.

B<Important Note>: Remember that your CBB does not need to use each and all these hooks, in most cases it probably will use just a couple of them, so don't be afraid of the apparent complexity of the following table. It is just a simple time line with many hooks: you can attach your code to the hook in the right position in the time line.
    
  +-------------------+
  | Instance Creation |          Creation of the new object
  |-------------------|          usually done by the Instance Script
  | - new()           |          or by the Apache::CGI::Builder extension.
  +-------------------+
    |
    |   +---------------+
    +-->| CB_INIT phase |  Optional initializing hook e.g. used to set any
        |---------------|  property or to start a DB connection. Overrides
        | - OH_init()   |  defaults and values passed with new().
        +---------------+

  +-------------+
  | Process     |            Start of the process phases
  |-------------|            usually done by the Instance Script
  | - process() |            or by the Apache::CGI::Builder extension.
  +-------------+
    |
    |   +-------------------+
    |-->| GET_PAGE phase    |  This phase provides to get the requested
    |   |-------------------|  page_name. It is internally handled so no need
    |   | - get_page_name() |  to use its method unless you need overriding.
    |   +-------------------+
    |
    |   +--------------------+
    |-->| PRE_PROCESS phase  |  This optional hook will be called just after
    |   |--------------------|  the GET_PAGE Phase. Used to check access and
    |   | - OH_pre_process() |  authorizations and eventually switching to
    |   +--------------------+  another page.
    |
    |-------+
    |       |
    |   +======================+
        | SWITCH_HANDLER phase |  Per Page Handler. E.g. If defined, the
    P   |======================|  'SH_foo' will be executed when the 'foo'
    A   | - SH_foo             |  page will be requested; the 'SH_bar' when
    G   | - SH_bar             |  the 'bar' page... E.g. used to check the
    E   | - SH_baz             |  input, and eventually switching to another
        | - ......             |  page.
    S   +======================+
    W       |
    I   +-----------------+
    T   | PRE_PAGE phase  |  Overrun Handler called each time a Page
    C   |-----------------|  Handler is about to be executed. E.g. used
    H   | - OH_pre_page() |  to centrally handle errors.
    I   +-----------------+
    N       |
    G   +====================+
        | PAGE_HANDLER phase |   Per Page Handler. E.g. If defined, the
    C   |====================|   'PH_foo' will be executed when the 'foo'
    Y   | - PH_foo           |   page will be requested; the 'PH_bar' when
    C   | - PH_bar           |   the 'bar' page... If defined and if no other
    L   | - PH_baz           |   Page Handler has been found, the optional
    E   | - ......           |   'PH_AUTOLOAD' will be executed instead
        | - PH_AUTOLOAD      |   unless the page has some content already
    |   +====================+
    |       |
    |-------+
    |
    |   +--------------+
    |-->| FIXUP phase  |  This optional hook is called after the
    |   |--------------|  PAGE_HANDLER Phase. Used as last hook just
    |   | - OH_fixup() |  before the RESPONSE Phase.
    |   +--------------+
    |
    |   +------------------------+
    |-->| RESPONSE phase         |   This phase provides to generate the response.
    |   |------------------------|   It is internally handled so no need to
    |   | - page_content_check() |   use the methods in your applications unless
    |   | - send_header()        |   you really need severe overriding
    |   | - send_content()       |
    |   +------------------------+
    |
    |   +----------------+
    +-->| CLEANUP phase  |  This optional hook is called at the end of
        |----------------|  the process to allow cleanup. E.g used to
        | - OH_cleanup() |  disconnect from a DB, or for log operations.
        +----------------+

Your application can execute some optional code at each phase of the process. To do so it has just to define the handlers that will be automatically called during that phase of the process. (see L<"Handlers">)

If your CBB doesn't include any template integration extension, the only mandatory requirement for your application will be setting the L<"page_content"> property to some content (i.e. SCALAR, SCALAR ref or CODE ref) before the RESPONSE Phase; if your CBB includes some integration like L<CGI::Builder::Magic|CGI::Builder::Magic> even setting the C<page_content> property will become unnecessary.

=head2 Exceptions

All the fatal errors (even those originated by other used modules) are trapped and wrapped with the indication of the Phase name which was running and the page name defined at the moment of the error. (see L<"die_handler">)

B<Known Issue>: At the moment, if you don't use a 5.8.x perl version, a fatal error might trace also the CGI::Builder internal packages instead of just the line that generates it in your own code. Besides, under certain circumstances and for certain handlers, the error line number might refer to the original call in the Instance Script instead to the statement in the CBB; in this case, the phase name shown in the error message should however point you to the handler that generated the error.

=head3 No page content

Since the CBF 1.1, an empty page_content does not produce a fatal error. It just produce a "204 No Content" http status header or - if you are using the Apache::CGI::Builder integration - a "404 Not Found" http status header, if no other status has been set until the RESPONSE phase.

This means that if your application doesn't implement some system to handle unknown page_names on its own (i.e. page names that don't produce any page conent), the CBF will handle them automatically. (see also the L<"page_content_check"> advanced method)

=head1 The Extension System

=head2 Extensions and Super Classes

An B<extension> is a CPAN module that extends the capability of the CBF with some documented features which can extend the capability of any CBB. (see L<" Extensions List">)

A B<super class> is usually a 'private' module containing some application specific capability, used as the base class for one or more CBB.

Both - extensions and super classes - use and benefit from the same extension system capabilities; the differences between them are just scope differences, being aimed to generic/public use, or to specific/private use.

A CBB can include both extensions and super classes by just adding them to the build list:

    # define your application build
    use CGI::Builder
    qw| CGI::Builder::SomeExtension
        SomeSuperClass
      |;

=head2 Inheritance, Overriding and Overrunning

The CBF implements 3 main features in your CBB: the classical B<Inheritance> and B<Overriding>, plus a CBF exclusive B<Overrunning>.

=head3 Inheritance

The B<inheritance> allows your CBB to inherit the structure, methods, and properties of the CBF, so your methods can set and retrieve properties and call methods defined by C::B or any other extensions you may include in your build. Inheritance is provided by the simply 'use' of C::B, that will also update the @ISA array of your sub class with the base classes it inherits from.

=head3 Overriding

The B<overriding> allows a class to override methods or properties defined by some base class (i.e. C::B or any other extensions). Your sub class can override a method by just defining the same method in its package, or can override the default of a property, by just setting another value.

In the CBB next entry will override previous entries:

    package My::WebApp;
    
    # the effect on @ISA of this build definition
    use CGI::Builder
    qw| My::SuperClassA
        My::SuperClassB
        My::SuperClassC
      |;
    
    # is equal to this
    @My::WebApp::ISA = qw| My::SuperClassC
                           My::SuperClassB
                           My::SuperClassA
                           CGI::Builder
                         |;

Methods with the same identifier defined in class My::SuperClassC will override those of class My::SuperClassB which override those of My::SuperClassA, which override those in CGI::Builder itself.

=head3 Overrunning

The B<overrunning> allows multiple base classes to 'overrun' the same method, that is: runnig the 'foo' method of each base class that defines a 'foo' method (sort of multiple stacked execution). This is a very useful feature that adds more power and flexibility to the extension system, allowing extensions and super classes to have automatically executed some code at specific phases of the process. All the 'OH_*' handlers are Overrun Handlers so they ALWAYS will have their code executed at the proper phase time (i.e. they will not override each other).

This tecnique is particularly useful to use super classes as plug-ins in multiple CBBs. Simple methods could be skipped (not executed) if the base class that use the super class would define that same method, while Overrun Handlers are always executed (unless your CBB explicitly use the overrun_handler_map() class accessor to skip them). (see L<"overrun_handler_map">)

B<Important Note>: A DB super class, could define an OH_init() and an OH_cleanup() that would be called at the correct time to connect and disconnect to/from a DB. Another super class could use the same handlers (defined in its own package) to do something competely different, and (with automatic overrunnig) your CBBs would have just to include them in the build definition, and each handler of each super class will be called at the correct time, so everything would work as expected.

=head2 Extensions List

=over

=item * CGI::Builder

Framework to build simple or complex web-apps

=over

=item * L<CGI::Builder::Conf|CGI::Builder::Conf>

Add user editable configuration files to your WebApp

=item * L<CGI::Builder::Test|CGI::Builder::Test>

Adds some testing methods to your build

=item * L<CGI::Builder::Const|CGI::Builder::Const>

Deprecated

=back

=item * L<Apache::CGI::Builder|Apache::CGI::Builder>

CGI::Builder and Apache/mod_perl (1 and 2) integration

=item * L<Apache2::CGI::Builder|Apache2::CGI::Builder>

CGI::Builder and Apache/mod_perl2 (new namespace) integration

=item * L<CGI::Builder::LogDispatch|CGI::Builder::LogDispatch>

Integrated logging system for CGI::Builder (Vincent Veselosky)

=item * L<CGI::Builder::Auth|CGI::Builder::Auth>

Adds user authentication and authorization to the CBF (Vincent Veselosky)

=item * L<CGI::Builder::Magic|CGI::Builder::Magic>

CGI::Builder and Template::Magic integration

=item * L<CGI::Builder::DFVCheck|CGI::Builder::DFVCheck>

CGI::Builder and Data::FormValidator integration

=item * L<CGI::Builder::Session|CGI::Builder::Session>

CGI::Builder and CGI::Session integration

=item * L<CGI::Builder::SessionManager|CGI::Builder::SessionManager>

CGI::Builder and Apache::SessionManager integration (Enrico Sorcinelli)

=item * L<CGI::Builder::CgiAppAPI|CGI::Builder::CgiAppAPI>

Use CGI::Application API with CGI::Builder

=item * L<CGI::Builder::HTMLtmpl|CGI::Builder::HTMLtmpl>

CGI::Builder and HTML::Template integration

=item * L<CGI::Builder::TT2|CGI::Builder::TT2>

CGI::Builder and Template::Toolkit integration (Stefano Rodighiero)

=back

=head1 METHODS

=head2 new ( [ properties ] )

The new() method construct a new instance of your application. It accepts and sets any known object property, storing any unknow property as a new param.

Use this feature to set the default of the properties of the new object before any other method calls.

For example you could install just one CBB on your server but use it in different domains, and you want to give the possibility to the webmasters that use it to pass different parameters to your CBB.

This feature just adds a flexible possibility to configure your application from the cgi script that uses it instead from the usual CBB C<OH_init>:

    # not always useful here, but possible
    $webapp = WebApp->new( page_name        => 'mySpecialPage',
                           cgi_page_param   => 'pp',
                           page_handler_map => { start => \&myPH } ,
                           myParam          => 'myDATA',# sets param
                           ... more here...
                         );

B<Note>: This feature is fully utilized by L<Apache::CGI::Builder|Apache::CGI::Builder>, which internally initialize the object with some defaults.

=head2 process ( [ page_name ] )

The process method starts the pre-structured CBF process (see L<"Process Phases">).

You usually will use this in the Instance Script without any argument. If you need to temporarly force the application to send a particular page, you can add it as an argument (e.g. useful when testing a particular Page Handler):

    $webapp->process('mySpecialPage');

=head2 switch_to ( page_name [, arguments] )

This method will switch the process to a page_name, e.g. useful when validating some condition in any handler. This cause a sort of internal redirect: use the L<redirect( url )> method to make the client do a new request.

    sub PH_myPage
    {
      my $s = shift;
      some_condition
        || return $s->switch_to('myOtherPage', @optional_arg)
      ...
    }

The I<arguments> passed to this method are optional and not needed by the CBF itself; they are just passed to your other handlers, just in case you need to keep track of something, or whatever you need to do.

This is an example, to show a possible use of the I<arguments>:
 
  sub SH_any_handler {
      my $s = shift;
      if (any_condition) {
          return switch_to("other_page", $my_argument)
      }
  }
  
  sub SH_other_page {
      my ($s, $my_argument) = @_ ;
      if ( $my_argument eq "something" ){
          do_something
      } else {
          do_something_else
      }
  }
  
  sub PH_other_page {
      my ($s, $my_argument) = @_  ;
      $s->page_content = $my_argument
                         ? "You requested "any_page""
                         : "You requested "other_page""
  }

B<Note>: You can use this method from the PRE_PROCESS phase until the FIXUP phase.

=head2 redirect( url )

This method will redirect the client to the I<url>, bypassing all the remaining phases until the CLEANUP phase that will be executed as usual after the client has been redirect to the I<url>. You can use this method from the GET_PAGE phase until the RESPONSE phase.

   return $s->redirect('http://domain.com/some/url');

B<Note>: This method will add the url to the header, and will use the CGI::redirect() method to redirect the client, passing it also the whole header hash you set so far (see also L<header() method|header( [ header ] )>).

=head2 cgi_new ( [arguments] )

This method is internally used by the C<cgi> property in order to create a new CGI object. You can also use this method if you need to create a CGI object with your own param (e.g. useful to fill a form with HTML::FillInForm).

Override it if you want to use any CGI object different than the canonical CGI.pm (e.g. CGI::Simple).

This method should return an object which implements at least: C<param>, C<header>, C<redirect> and C<cookie>, which are methods the CBF and its Extension use.

=head1 PROPERTY ACCESSORS

A CBF B<property> is a lvalue accessor to an object value. 'lvalue' means that you can create a reference to it, assign to it and apply a regex to it (see also L<KNOWN ISSUE>). Besides, a property can have a default value, some validation entry rules, etc. and you can use them as an argument to the new() method as well.

    # 'page_content' is a property accessor
    $webapp = WebApp->new(page_content => 'dummy default') ;
    
    $pc = \ $s->page_content ;
    $s->page_content  = 'some content ' ;
    $s->page_content .= 'some more content' ;
    $s->page_content =~ s/some/SOME/ ;
    
    # old debugger-safe way still works
    $s->page_content('some content')
    
    $pageContent = $s->page_content

There are several CBF standard properties and each extensions can add some other specific property to the set of the CBF. You can see a description for each property used by an extension in its own POD.

B<Note>: The properties in this section are ordered by importance/frequency of use, listing first the most frequently used and needed, and last the properties that you might probably ignore for the rest of your life :-).

=head2 cgi

This property allows you to access and set the cgi object. The default for this property is a CGI.pm object, but you can override this default if you redefine the C<cgi_new()> method.

If you use the default you have just to use the C<cgi> property which will return the current CGI object without the need to create it by yourself.

   # in any handler
   $my_query_param = $s->cgi->param('any_query_parameter')

If, for any reason, you want to use your own cgi object, you can pass this property to the new() method, or you can also directly set it at some point in the process.
                
    $cbb = WebAppClass
             ->new( cgi => CGI->new({myOwnQuery => 'something'}) )
    
    $s->cgi = CGI->new({myOwnQuery => 'something'}) ;

=head2 page_name

This property allows you to access and set the page name. The default for this property is 'index'. This means that the 'index' page will be requested if no other page has been explicitly requested.

Set the C<page_name> to redefine the default page_name. This default will be used whenever the value of the CGI form parameter specified by the C<cgi_page_param> property is not defined.

    $current_page_name = $s->page_name
    
    # override default page name in OH_init
    $s->page_name = 'myStart' ;

=head2 requested_page

This property holds the original requested page name. Read only.

=head2 page_content

This property allows you to access and set the content of the page (or a reference to it) to send to the client. The default for this property is the empty string '' so be aware that it is always defined even if you don't set it.

During the process the C<page_content> property will be set to some page content, to a reference to it or to a CODE reference that will print the output on its own. In this case the refereced code will be called after the printing of the header.

    sub PH_myPage
    {
      ...do_something_useful...
      $s->page_content  = 'something'
      $s->page_content .= 'something more'
    }
    
    sub PH_myOtherPage
    {
      ...do_something_useful...
      $s->page_content  = \&print_the_content
    }

The main advantage to set this property to a CODE reference is that you avoid to charge the memory with the whole (and sometime huge) output and print it while it is produced.

This feature is fully utilized in L<CGI::Builder::Magic|CGI::Builder::Magic>, but you can also use it with your own subroutines.

=head2 cgi_page_param

This property allows you to access and set the name of the query parameter used to retrieve the page_name. The default for this property is 'p'.

=head2 page_path

This property allows you to access and set the path of the page (e.g used to address a template or a web directory). The default for this property is './tm' (relative to the Instance Script), but your code or other extensions may set it otherwise.

=head2 page_suffix

This property allows you to access and set the suffix string used by some template extension to compose the page file path. The default for this property is the empty string '' so be aware that it is always defined even if you don't set it, anyway your code or other extensions may set it otherwise.

=head1 PROPERTY GROUP ACCESSORS

A property group accessor is simply an accessor which can handle multiple data (or properties) of a same group. With all the property group accessors you can set, add, retrieve, delete, check for existance with only one method. You can use them as an argument to the new() method as well.  See the param() method to learn the feature of the group accessors (remember that all the property group accessors use the same interface).

=head2 param ( [ key | hash ] )

This accessor handles the parameters of your application

    # pass a parameter to the new object
    $webapp = WebApp->new(param => {myParam => 'myD'})
    
    # sets or adds several params
    $s->param(myParam1=>'myDATA1',
              myParam2=>'myDATA2') ;
    
    # sets or adds several params
    $s->param(\%other_param) ;
    
    # retrieve a value
    $myParam1 =  $s->param('myParam1')

    # retrieve a slice of values (requires OOTools >= 1.77)
    @slice =  $s->param(['myParam1', 'myParam3'])
    
    # retrieve the reference to the param hash
    $param_ref = $s->param ;
    while ( my ($p, $v) = each %$param_ref )
    { do_something_useful }
    
    # retrieve the keys of the param hash (new OOTools recommendation)
    @param_keys = keys %{$s->param} ;
    
    # copying he whole hash (requires OOTools >= 1.8)
    %param = $s->param
    
    # check if exists any param
    exists $s->param->{myParam} ;
    
    # delete any param
    delete $s->param->{myParam} ;

A special feature only for the param() accessor, is the automatic loading and retrieving using the parameter key as it was a defined property or method. This feature uses the L<"AUTOLOAD"> method:

    # with the automatic AUTOLOAD of param, these statements
    $webapp = WebApp->new(param => {myParam => 'myD'}) ;
    $s->param( myParam=>'myD') ;
    $p = $s->param('myParam') ;
    
    # can be written simply as
    $webapp = WebApp->new(myParam => 'myD') ;
    $s->myParam = 'myD';
    $p = $s->myParam ;

B<Important Note>: If you use the AUTOLOAD feature, and if you want to write code that will not break, you should always follow the CBF convention and name your param with the 'my_' or '_' prefixes. If you don't do that, it might happen that in the future, your 'special_data' parameter loaded with AUTOLOAD (C<< $s->special_data >>) will call instead a special_data() method implemented by any new release of any extension :-). The 'my_special_data' or '_special_data' are safer choices.

=head2 header( [ header ] )

This accessor works for header exactly like param() works for param. You can use it to change the header that your application will use in the RESPONSE phase.

B<Note>: The keys/values pairs you are setting as the headers will be internally passed to the C<CGI::header()> method at the correct time, so you should always use the leading '-' character as you do for C<CGI::header> (please, refer also to the documentation of the header() method in CGI.pm, or other module if you have overridden the C<cgi_new()> method in order to return a different CGI object).

=head2 page_error

You can use this property group accessor to store and retrieve page errors.  You can add key value pairs each time you find an error, and retrieve the whole hash later, e.g. to show a feedback of the errors:

    $s->page_error(email_field => 'Not a valid address')
       unless email_condition ;
    $s->page_error(other_field => 'Bad parameter')
       unless otherfield_condition ;
    
    ...
    exists $s->page_error->{email_field} ;

B<Note>: It is automatically set by L<CGI::Builder::DFVCheck|CGI::Builder::DFVCheck>.

=head1 HANDLERS

The CBF provides several optional handlers that will be called at specific phases during the process: your CBB has just to define the specific handler of the specific phase. E.g. if your application needs to check the authorization for a user at the start of the process, it should define a C<OH_pre_process> method and put the needed code in that handler.

All the handlers are optional; this means that your CBB should define just the handlers that it need.

B<Note>: Here they are ordered by category and not by execution time, see L<"Process Phases"> to have them ordered by execution time.

=head2 Overrun Handlers

The handlers in this category - if defined in your CBB - are executed at each request at the specific Phase time and for each base class that defines them. (see L<"Overrunning">)

=head3 OH_init

This handler is executed in the CB_INIT Phase (i.e. just after the creation of the new object) and it is internally called by the new() method. You can use it to initialize some properties or param of your application, or to connect with a DB.

B<Note>: The OH_init() handlers defined in different classes are executed with the same order as the CBB inclusion order.

=head3 OH_pre_process

This handler is executed in the PRE_PROCESS Phase (i.e. at the very start of the process). You can use it to control AAA (Authentication and Authorization, and Access) and eventually switch_to() another page on failure.

B<Note>: The OH_pre_process() handlers defined in different classes are executed with the same order as the CBB inclusion order.

=head3 OH_pre_page

This handler is executed in the PAGE_PROCESS Phase (i.e. after the SWITCH_HANDLER Phase, and just before the PAGE_HANDLER Phase) at each switching cycle. This is the only Overrun Handler that may be executed multiple times in the same process (i.e. each time the switch_to() method is internally or explicitly called and no Switch Handler has been set). You can use it e.g. to centrally handle page errors with a single handler.

B<Note>: The OH_pre_page() handlers defined in different classes are executed with the same order as the CBB inclusion order.

=head3 OH_fixup

This handler is executed in the FIXUP Phase (i.e. after the PAGE_HANDLER Phase, and just before the RESPONSE Phase). It gives the last chance to do things before the response is generated (e.g. modify the header or the page_content just before they are sent to the client).

B<Note>: The OH_fixup() handlers defined in different classes are executed with a reversed CBB inclusion order.

=head3 OH_cleanup

This handler is executed in the CLEANUP Phase (i.e. after the RESPONSE Phase). At this Phase, the page has already been sent to the client, and you can use it to cleanup e.g. closing some opened DB connection or logging execution.

B<Note>: The OH_cleanup() handlers defined in different classes are executed with a reversed CBB inclusion order.

=head2 Per Page Handlers

These are the handlers called on a per page basis, i.e. each per Page Handler is called ONLY for a certain requested page.

=head3 SH_* (Switch Handlers)

This handlers are prefixed by 'SH_' (i.e. Switch Handler). (e.g. If defined, the 'SH_foo' will be executed when the 'foo' page will be requested).

You can use this handlers to check some condition just before the PRE_PAGE Phase so giving you the possibility to switch to another page before the execution of that phase.

=head3 PH_* (Page Handlers)

This handlers are prefixed by 'PH_' (i.e. Page Handler). (e.g. If defined, the 'PH_foo' will be executed when the 'foo' page will be requested).

You can use this handlers to do something specific for different pages, such as e.g. executing some specific code just for that specific request (or creating the specific page content when your handler don't use any automagic template integration)

=head3 PH_AUTOLOAD

This is a special Page Handler which will be called IF defined and IF there are no other defined page handler for the specific requested page and UNLESS the page_content_check() return true (i.e. there is no page content so far).

The main purpose of this handler is giving you one more option to generate the page_content if no other handler has generated it so far, so you can use it e.g. as the last chance to redirect the client or switch_to your special 'Not found' page during the PAGE_HANDLER phase.

You can also use the C<page_handler_map> advanced accessor to map the AUTOLOAD handler to any method you prefer.

B<Note>: The execution of this handler is skipped by the presence of:

=over

=item *

any specific PH handler defined for the current page

=item *

any page_content already defined

=item *

a found template, which is supposed to generate the page content if you use any template integration Extension

=back

If you need a wider solution you should use an C<OH_pre_page> or an C<OH_fixup> handler instead, which get always called without any restriction.

=head1 ADVANCED FEATURES

In this section you can find all the most advanced or less used features that document all the details of the CBF. In most cases you don't need to use them, anyway, knowing them will not hurt.

=head2 CONSTANTS

These constant are used to set and check the Process Phase. They return just a progressive integer:

  CB_INIT         0
  GET_PAGE        1
  PRE_PROCESS     2
  SWITCH_HANDLER  3
  PRE_PAGE        4
  PAGE_HANDLER    5
  FIXUP           6
  RESPONSE        7
  REDIR           8
  CLEANUP         9

=head2 Global Variables Persistence

If you are using mod_perl, you should know the "Global Variables Persistence" issue: this is something that you must consider when your CBB is running under mod_perl, even when your CBB doesn't use Apache::CGI::Builder.

More explicitly you should know that the CBF and its extensions may use Global Variables to store certain data which are B<class scoped> (i.e. used for all the processes of your CBB class), thus caching the data and saving some processing.

The Global Variables that the CBF uses are always accessed by an OOTool accessor, they are just B<Class Accessors> instead of B<Object Accessors>: the behaviour of a Class accessors (property or group) is the same, but the underlaying accessed variable is a Global Variable, and so it will behave under mod_perl. (See OOTools documentation if you want more details about the differences).

Examples of Class Accessors are the L<"Class Property Group Accessors"> of this module, or the C<tm>, C<tm_new_args> and C<tm_lookups_package> accessors of the CGI::Builder::Magic extension (which creates the Template::Magic object just once -the first time it is accessed- and uses the same object for all the successive requests that involve template processing).

B<Note>: You should clearly distinguish the B<class accessors> among the others because this particular feature is usually written in B<bold> at the start of the accessor doc.

=head2 Advanced Methods

=head3 capture( CODE )

This method executes the I<CODE> (which can be a method name or a CODE ref) and returns a ref to the captured output, so allowing you to eventually test your sub classes, or doing something with the output (e.g. in a OH_fixup() when the page content is a CODE reference).

  $captured_output = $webapp->capture('process');
  if ( $$captured_output =~ /something to test/ ){
      print 'ÍT WORKS!'
  }

  sub OH_fixup {
      my $s = shift ;
      if (ref $s->page_content eq 'CODE')  {
          # executes the referenced CODE and capture the output
          $s->page_content = $s->capture($s->page_content)
      }
      # do something with $s->page_content as usual
  }

=head3 phase( [phase_number] )

This method returs the current phase name or the name of the passed I<phase_number> argument.

=head2 Internal Methods

B<You don't need to directly use any of these methods because they are used internally> but you might need to override them in very special cases, so they are documented here.

=head3 get_page_name

Used internally to set the C<page_name> to the value of the C<cgi_page_param> query parameter at the very start of the process. (e.g. this query parameter ?p=myPage will set the C<page_name> to 'myPage')

If you don't want to pass the page parameter as a query parameter, or if you have any other custom need you can override this method which should set the C<page_name> as you need.

=head3 send_header

Used internally to send the C<header> to the client.

This accessor is backed by the C<header()> CGI function, so IF (and only if) you implement a different query object not based on CGI.pm, AND the object you use 'can' not "header", THEN you cannot use this method, so you need to override it.

=head3 send_content

Used internally to send the C<page_content> to the client.

=head3 AUTOLOAD

This method (not to be confused with the 'PH_AUTOLOAD' Page Handler) implements an handy param accessor. You can store or retrieve some param as it was an object property:

    # instead of do this
    $s->param(my_Param => 'some init value')
    
    # you can do this directly
    $s->my_Param = 'some init value' ;
    
    # same thing with the new() method
    $webapp = WebApp->new(my_Param => 'some init value')
    
    # or with the explicit assignation
    $webapp = WebApp->new(param => {my_Param      => 'some init value',
                                    my_OtherParam => 'some data'      } )
    # and to retrieve it
    $p = $s->my_Param

B<Note>: If you don't like this feature, just override the AUTOLOAD method. If your application implements its own AUTOLOAD sub and you want to keep this possibility just fall back on the SUPER method when needed.

B<Important Note>: If you use this feature, and if you want to write code that does not break, you should always follow the CBF convention and name your param with the 'my_' or '_' prefixes. If you don't do that, it might happen that in the future your 'special_data' parameter loaded with AUTOLOAD (C<< $s->special_data >>) will call instead a special_data() method implemented by any new release of any Extension :-). The 'my_special_data' or '_special_data' are safer choices.

=head3 page_content_check

This method is called at the very start of the RESPONSE phase. It checks if the page_content contains some content to be sent. A true returned value will send the C<page_content>, while a false returned value will prevent the sending of the C<page_content>, and will set the C<-status> header to the value of the C<no_page_content_status> property if no status header has ben set yet.

The page_content_check() method is overridden by other extensions such as CGI::Builder::Magic, that checks also if the template file exists before using its template print method.

This method is used also to handle the AUTOLOAD page handler, which will not be called unless there is no C<page_content> so far.

=head3 die_handler

Used internally to implement a localized $SIG{__DIE__}. This method adds useful informations to the error messages (even to those generated by other used modules). It adds the page name and the phase at the moment of the error plus a Data::Dumper::Dumper() of the object itself if the CGI::Builder::Test is included in the build.

If you need to implement your own $SIG{__DIE__} you should override this handler in your own CBB.

=head3 import

The C::B module use the import() method to setup inheritance and overrunning of your CBB, and undefines the import() method in your CBB (to avoid inheritance and overrunning propagation). If for any very exotic reason you need to define an import method in your own CBB, you should define it BEFORE the definition of the build, or it will not work.

=head2 Advanced Property Accessors

=head3 dont_send_header

Set to a true value, this property will prevent the sending of the header. Undefined by default.

=head3 no_page_content_status

This B<Class property> is used to supply the default C<-status> header that the CBF send in the RESPONSE phase when the C<page_content> is empty, but ONLY if the status header is not defined yet. The default of this property is '204 No Content', but other extensions (such as Apache::CGI::Builder) could set it otherwise.

=head3 PHASE

Internal read only property used to control the process and the exceptions. B<Don't override it unless you know exactly what you are doing!>.

=head2 Class Property Group Accessors

The accessors in this section are B<Class Accessors>, which are accessors to package variables (i.e. not instance variables) which are B<class scoped>. Usually you sould use them at the start of the CBB code (and out of any handler or method).

=head3 page_handler_map( [ page => page_handler ] )

With this B<Class Accessor> you can map some page name to a specific Page Handler:

    __PACKAGE__->page_handler_map
                 ( thisPage => \&special_Phandler,
                   thatPage => 'other_special_Phandler'
                 );

=head3 switch_handler_map( [ page => switch_handler ] )

With this B<Class Accessor> you can map some page name to a specific Switch Handler:

    __PACKAGE__->switch_handler_map
                 ( thisPage => \&special_Shandler,
                   thatPage => 'other_special_Shandler'
                 );

=head3 overrun_handler_map

The purpose of this B<Class Accessor> is giving you the possibility to override the automatic overrunning of CBF if you want to change the order (or skip) any Overrun Handler defined by some extension or super class.

Consider this CBB:

    package My::WebApp;
    use CGI::Builder
    qw| My::SuperClassA # defines its own OH_init() and OH_cleanup()
        My::SuperClassB # defines its own OH_init() and OH_cleanup()
        My::SuperClassC # defines its own OH_init() and OH_cleanup()
      |;
    
    sub OH_init
    { ... }
    
    sub OH_cleanup
    { ... }

In the CB_INIT Phase the following handlers will be automatically executed with this order:

    1 My::SuperClassA::OH_init
    2 |  My::SuperClassB::OH_init
    3 |  |  My::SuperClassC::OH_init
    4 |  |  |  My::WebApp::OH_init
      |  |  |  |
    5 |  |  |  My::WebApp::OH_cleanup
    6 |  |  My::SuperClassC::OH_cleanup
    7 |  My::SuperClassB::OH_cleanup
    8 My::SuperClassA::OH_cleanup

As you can see the OH_init() handlers are executed with the same order of the CBB inclusion order, while the OH_cleanup() execution order is reversed. This way it is created a sort of nested execution so that the class that first inits is the last that ends/destroys. See each handler description to know the execution order.

If you want to change the execution order of the Overrun Handlers, you can use this class accessor to change that order:

        __PACKAGE__->overrun_handler_map
                     ( init => [ 'My::SuperClassC',
                                 'My::SuperClassB',
                                 'My::WebApp',
                                 'My::SuperClassA'] );

After that change the execution order of the handlers will be:

    My::SuperClassC::OH_init
    My::SuperClassB::OH_init
    My::WebApp::OH_init
    My::SuperClassA::OH_init


Remember also that you can change the order of all the Overrun Handlers in a single step:

      __PACKAGE__->overrun_handler_map
                   ( init  => [ 'My::SuperClassC',
                                'My::SuperClassB',
                                'My::SuperClassA'],
                     fixup => [ 'My::SuperClassB',
                                'My::SuperClassA']);

B<Important Note>: The keys of this accessor are the handler identifier WITHOUT the 'OH_' overrun handler constant prefix.

=head1 EXAMPLES

All the examples in this section will use the following Instance Script that use a WebApp.pm CBB (differently organized in each example). In this example the script is supposed to be available at the url: http://domain.com/IScript.cgi

    #!/usr/bin/perl -w
    use My::WebApp ;
    $webapp = My::WebApp->new() ;
    $webapp->process() ;

=head2 Hello world!

This is the classical example of a minimal output, that will produce a page content with just the "Hello world!" string in it (not a valid HTML page, but it's ok for our purpose). Obviously, without the CBF you could write the same script with less effort, but the usefulness of CBF comes up when the application become more complex:

  package My::WebApp;    # your class name
  use CGI::Builder;      # defines a build with no other extension
  
  sub PH_AUTOLOAD {      # called for all requested pages (no other PH_*)
      my $s = shift;
      $s->page_content = "Hello world!"   # defines the page content
  }
  
  1;

As you see in the CBB, it defines just the PH_AUTOLOAD, the special Page Handler that is automatically called when no other Page Handlers are found for the requested page (see L<"PH_AUTOLOAD">).

All we have to do in that handler is set the 'page_content' property to the content we want to send to the client, and the CBF will manage automatically all the process.

=head2 Hello world! Variant 1

Suppose that we want to send the "hello world!" content just for the specific "Hello" page, while for each other page eventually requested, we want to redirect the client to another url:

  package My::WebApp;    # your class name
  use CGI::Builder;      # defines a build with no other extension
  
  
  sub PH_Hello {         # called ONLY for page_name 'Hello'
      my $s = shift;
      $s->page_content = "Hello world!"   # defines the page content
  }
  
  # first alternative
  # check the requested page in PRE_PROCESS Phase
  # redirect if page_name is not "Hello"
  
  sub OH_pre_process {
      my $s = shift;
      if ($s->page_name ne 'Hello') {
          return $s->redirect('http://my/not/found/page/url')
      }
  }
  
  # second alternative
  # check the defined page content in FIXUP Phase
  # redirect if page_content has not been set yet (by any handler)
  
  sub OH_fixup {
      my $s = shift;
      return $s->redirect('http://my/not/found/page/url')
        unless $s->page_content_check;
  }
  
  # third alternative
  sub PH_AUTOLOAD {
     my $s = shift;
     $s->redirect('http://my/not/found/page/url');
  }
  
  1;

As you see, we have changed the PH_AUTOLOAD with the PH_Hello that will be called only when the page_name is 'Hello', then, we have a few alternatives to choose for the redirection.

The first alternative is very specific, and checks exactly for the 'Hello' C<page_name>, so if we will add another Page Handler in the future, we have to modify accordingly the condition to avoid redirection.

The second alternative is more flexible because it checks for the content of the page in the FIXUP Phase, after the PAGE_HANDLER Phase has been tried, redirecting only if no Page Handlers has set the page_content so far, so if we will add a new Page Handler in the future it will work without any changes.

The third alternative is simpler since it uses the way the PH_AUTOLOAD get called, and just redirect without checking any condition (the conditions are internally checked BEFORE calling the PH_AUTOLOAD).

B<Note>: To request the page "Hello" the client should point to http://domain.com/IScript.cgi?p=Hello. Any other requested page as (e.g. ?p=myTry) will cause a redirection to http://my/not/found/page/url.

=head2 Hello world! Variant 2

To add another page we just add another Page Handler:

  package My::WebApp;    # your class name
  use CGI::Builder;      # defines a build with no other extension
  
  
  sub PH_Hello {         # called ONLY for page_name 'Hello'
      my $s = shift;
      $s->page_content = "Hello world!"   # defines the page content
  }
  
  sub PH_NiceHello {    # called ONLY for page_name 'NiceHello'
      my $s = shift;
      $s->page_content = "This is a nice HeLlO WoRlD! :-)"
  }
  
  sub PH_AUTOLOAD {
      my $s = shift;
      return $s->redirect('http://my/not/found/page/url')
  }
  
  1;

B<Note>: To request the page "NiceHello" the client should point to http://domain.com/IScript.cgi?p=NiceHello.

=head2 Hello world! Variant 3

If instead of a client redirection we want to send a specific page internally generated, we could add a new Page Handler for that page, and/or change a little the OH_fixup:

  package My::WebApp;    # your class name
  use CGI::Builder;      # defines a build with no other extension
  
  
  sub PH_Hello {         # called ONLY for page_name 'Hello'
      my $s = shift;
      $s->page_content = "Hello world!"   # defines the page content
  }
  
  sub PH_NiceHello {    # called ONLY for page_name 'NiceHello'
      my $s = shift;
      $s->page_content = "This is a nice HeLlO WoRlD! :-)"
  }
  
  # first alternative
  
  sub PH_no_page {     # internally called by the OH_fixup
      my $s = shift;
      $s->page_content = "The page you requested is not available!"
  }
  
  sub PH_AUTOLOAD {
      my $s = shift;
      $s->switch_to('no_page')  # switches to the no_page Page Handler
  }
  
  # second alternative
  # you can eliminate the PH_no_Page Handler
  # and set the page_content directly from the PH_AUTOLOAD
  
  sub PH_AUTOLOAD {
      my $s = shift;
      $s->page_content = "The page you have requested is not available!"
  }
  
  
  1;

B<Note>: Any requested page that does not produce any page_content as e.g. ?p=myTry, will print "The page you requested is not available!".

=head2 Check the input

Imagine a simple application that addresses 2 pages: a 'ShowForm' page that contains a form with just a field, and a 'Submitted' page that will show just a message confirming the submission. The form action of the ShowForm page is set to 'IScript.cgi?p=Submitted'.

B<Note>: We don't handle the error for this simple example, we just want to check whether the 'email' field is not empty, so showing the Submitted page, or re-send the ShowForm page in case the 'email' field is empty.

  package My::WebApp;
  use CGI::Builder;
  
  # this is the Page Handler that produce the form
  sub PH_ShowForm {
     my $s = shift;
     ... generates the form
     $s->page_content = $generated_page_with_form;
  }
  
  # add a Switch Handler for the Submitted page
  # that checks the 'email' query param and switches on failure
  sub SH_Submitted {
     my $s = shift;
     $s->cgi->param('email') or switch_to('ShowForm');
  }
  
  # this is the Page Handler that confirms the submission
  sub PH_Submitted {
     my $s = shift ;
     $s->page_content = 'Thank you for filling the form';
  }

The 'SH_Submitted' handler will be automatically called when the C<page_name> is 'Submitted' and just before calling the 'PH_Submitted' handler, so giving you the possibility to check some condition (i.e. the not empty 'email' field). The process will switch to the 'ShowForm' page on failure (so executing the PH_ShowForm'), or will execute the PH_Submitted on success.

You could do the same by avoiding the use of the 'SH_Submitted' handler, by moving the switch condition inside the Page Handler itself. In this example it might appear that the elimination of the SH_Submitted method could produce a more clear code, but in real world jobs I find this is less clear, specially because sometimes a handler may contain a lot of conditions and mixing checking with page production is more confusing, anyway... in your applications this is up to you :-).

  package My::WebApp;
  use CGI::Builder;
  
  # this is the Page Handler that produce the form
  sub PH_ShowForm {
     my $s = shift;
     ... generates the form
     $s->page_content = $generated_page_with_form;
  }
 
  # this is the Page Handler that confirms the submission
  sub PH_Submitted {
     my $s = shift ;
     $s->cgi->param('email') or return switch_to('ShowForm') ;
     $s->page_content = 'Thank you for filling the form';
  }

In this case, notice the C<return switch_to()> to return from the handler on switching.

B<Note>: You should consider to use the L<CGI::Builder::DFVCheck|CGI::Builder::DFVCheck> extension that integrates C::B and the C<Data::FormValidator> module.

=head2 More examples

You can find more examples in the mailing list archive and in the F<CBF_examples> dir included in this distribution.

B<Note>: While you are experimenting with the CBF, you are probably creating examples that could be useful to other users. Please submit them to the mailing list, and I will add them to the next CBF release, giving you the credit of your code. Thank you in advance for your collaboration.

=head1 HOW TO...

=head2 Design your application

As general guide, you should keep in mind the L<"Process Phases">: almost all your code should go into some handlers, so decide when (in what Phase) you want it to be executed and define the specific handler you need. Also consider these points as a more detailed guide:

=over

=item *

Define your build including the extension you need (see L<"Extensions Lists">).

=over

=item *

If your application will run under mod_perl, consider to use L<Apache::CGI::Builder|Apache::CGI::Builder> that offers several advantages

=item *

Consider to use some integration with a template system that could speed up your work and make your application simpler to maintain.

=back

=item *

Unless you override the new_cgi() method with one which does not use CGI.pm, include the 'use CGI' statement in your CBB to save some loading time. (The new_cgi() method requires the CGI.pm only at run-time)

=item *

Set all the defaults of the properties and all the statements common to all pages in the C<OH_init()> method that is executed even before the start of the process(), just after the creation of the new object

=item *

Use the param() accessor to store and retrieve the param needed by your application. You can also use the shortcut provided by the L<"AUTOLOAD"> method (not to be confused with the L<"PH_AUTOLOAD"> page handler):

   # just assign to a new param
   $s->myNewParam = 'something' ;
   
   # without the need of doing this
   $s->param(myNewParam => ' something') ;

=item *

If your application needs to check some general AAA (Authentication and Authorization, and Access) condition define a C<OH_pre_process()> that will C<switch_to()> a login or similar page on failure

=item *

If your application needs to check some condition specific to a 'foo' page, define a specific 'SH_foo()' Switch Handler that will C<switch_to()> another page on failure.

=item *

If you don't use any template integration, define a Page Handler for each page and set the C<page_content> property inside it.

=item *

If you use a template integration like L<CGI::Builder::Magic|CGI::Builder::Magic> usually you don't need to set the C<page_content> property because it will be magically filled for you, so define just the Page Handlers that have something special to do (e.g. update some data in a DB)

=item *

Use the C<OH_fixup()> as the last hook before the RESPONSE phase (when the page will be sent to the client). The C<page_content> property should already contain the content of the page and you can have the last chance to transform it or to change the header in some way.

=item *

Use the C<cleanup_handler()> as the last hook of the process, to do cleanup after the page has been sent (e.g. close DB connection, log, etc.)

=item *

If your site structure become more complex and you need to split your CBB into several different modules, consider to create super classes and use the overrun handlers. (see L<"Write a Super Class">)

=back


=head2 Write code that will not break

Since this framework is implemented by inheritance of possibly many extensions, conflicting keys, methods and properties could become a real problem unless you follow some simple conventions. If you want to write forward/backward compatible CBF code please, consider this:

=over

=item *

Prefix the methods and the param keys of your own CBB with a simple 'my' or '_'. No other extension will never use a property or method with these prefixes, so your code will not break even by adding new future extensions.

=item *

Don't interact with the internal hash structure with any dirty statement aimed to B<add> some data to the object. Use the C<param> accessor to hold the param of your application. (Note: you have just to set some property and it will be added as a new param even without using the param accessor explicitly. See L<"AUTOLOAD"> method)

=item *

Don't interact with the internal hash structure with any dirty statement aimed to B<use> some data of the object. Override the accessors or methods anywere you need some very severe customization.

=back

=head2 Avoid common mistakes

=over

=item *

Ask for support and advice. Your work will progress faster and smoother.

=item *

Don't directly print neither the header nor the content to STDOUT: it probably would just cause a server error! The CBF is organized to send the header on its own during the RESPONSE phase, and use the C<page_content> value to send the page to the client. Instead of print, just assign to C<header()> and to C<page_content>.

=item *

Don't change CBF defaults unless you have a good reason to do so. Defaults keep consistent your application with conventions and guide lines, if you change them without a good reason, you just waste your time.

=item *

Don't override any internal method without a good reason, specially if you can use another way to do what you need. The internal methods will evolve with the framework, so if your application rely on any overridden method, it will loose the possibility to benefit of the future improvements of that method.

=item *

Don't set C<page_name>, C<page_path> and C<page_suffix> unless you need to change the default in CBF_INIT Phase. Use switch_to to switch to another page.

=back

=head2 Write a Super Class

=over

=item *

Don't inherit neither from C::B base class nor from other extensions: all the inheritance business is done in the definition of the CBB

=item *

Avoid dirty and undocumented statements (i.e. don't write statements like $s->{__SOMETHING} = 'something else') because this might clash with some other extension. Use the param() accessor to store the param of your super class.

=item *

Use the OH_init() method when you need to init properties

=item *

Use Overrun Handlers when your super classes MUST run some code at specific Phase time. Simple methods could be skipped (not executed) if the base class that use your super class defines that same method! (Remember that all the defined Overrun Handlers are executed for all the base classes. see L<"Overrunning">)

=item *

Organize methods calls without passing arguments unless the argument goes out of scope imediately. Define a property that will 'stay' in the object without the need to be passed as an argument. This produces cleaner code.

=back


=head2 Write an Extension

Writing an extension is usually simpler than what you might expect. Since extensions are included in the CBB as base classes, an extension could contain just a simple method of just a few line of code so you don't need to be a guru in order to contribute. The only real requirement is following this simple guide lines:

=over

=item *

Ask in the mailing list if nobody else is writing the same extension you are planning to write. ;-)

=item *

Don't inherit neither from C::B base class nor from other extensions: all the inheritance business is done in the CBB definition. If your extension uses any other extension, just specify to include it in the CBB definition and eventually check if the module is loaded by checking $s->isa('anyExtension').

=item *

Don't group several independent modules in the same distribution: allow the user to install just what he needs

=item *

Avoid dirty and undocumented statements (i.e. don't write statements like $s->{__SOMETHING} = 'something else') because this might clash with some other extension. Always use the same identifier for both the internal hash key and the public accessor.

=item *

Avoid defining private and undocumented methods in your package. Your module will be used as a base class along with other modules, so conflicting identifiers are not only possible, but probable. Instead of using the classical initial underscore like in '_private_method' that is reserved for CBB parameters and methods, declare your method in e.g. Your::Package::_, then use it without importing in your module.
    
    # don't do this in your extension package
    sub _private_method { ... }
    
    # do this instead
    # ( it is overridable but 'private_method' will never clash )
    sub Your::Package::_::private_method { ... }
    
    # if you want an alias to save typing
    my $private_method = \&Your::Package::_::private_method ;
    ...
    # use it as usual
    $s->$private_method() ;

=item *

Never name an extension method starting with the 'my' or '_' string, which are prefixes reserved to the CBB code.

=item *

Don't import from other modules. You can use any function or method without the need of importing:
   
    require Foo::Bar ;
    $res = Foo::Bar::special_function(@args) ;

=item *

Don't use the param() accessor to store properties of your extension (this is reserved to the CBB); create a new property instead.

=item *

Always write accessors for your properties and try to use OOTools when possible. The accessors allow easy overriding, and OOTools pragmas are already loaded with C::B and provide efficient and simply to use accessors.

=item *

Use the OOTools default option when you need to init your new property implemented with OOTools pragmas; use the OH_init() method when you need to init other properties

=item *

Use Overrun Handlers when your extension MUST run some code at specific Phase time. Simple methods could be skipped (not executed) if the base class that use your extension defines that same method! (Remember that all the defined Overrun Handlers are executed for all the base classes. see L<"Overrunning">)

=item *

Organize methods calls without passing arguments unless the argument goes out of scope imediately. Define a property that will 'stay' in the object instead of passing it as an argument.

=item *

Ignore the returned value of a method. When needed, a method should set a property that will 'stay' in the object instead of returning its value. This allows cleaner and more flexible code.

=item *

Pick a meaningful prefix and use it for naming the methods and properties of your extension. (e.g. 'dfv_' is the prefix used by C::B::DFVCheck that stands for 'Data::FormValidator', 'tm_' stands for 'Template;:Magic' and so on).

=item *

If you use internal created objects, always provide a C<foo> property, a C<foo_new_args()> property group accessor and eventually a C<foo_new()> method to allow overriding. With OOTools it is very simple:

    # this creates a property group accessor for foo_new_args
    # already containing some default arguments which can be overridden
    use Object::groups
        ( { name       => 'foo_new_args',
            # default can be an HASH ref
            # or a sub returning an HASH ref
            default    => { arg1 => 'some value',
                            arg2 => 'some other value'
                          }
          }
        ) ;
    
    # this will create a foo property that will
    # call the foo_new to initialize the object,
    # just before using the object and only if the object
    # has not been created yet
    use Object::props
        ( { name       => 'foo',
            default    => sub{ shift()->foo_new(@_) }
          }
        ) ;
        
    # this creates the object and allows to override the method
    sub foo_new {
        my $s = shift;
        return Foo->new( $s->foo_new_args )
    }

=item *

Check if the CBB is including Apache/mod_perl integration by checking C<< $s->isa('Apache::CGI::Builder') >>; checking C<$ENV{MOD_PERL}> or C<$mod_perl::VERSION> would tell you just that mod_perl is running.

=item *

If you use Carp consider to add this line to your extension:

    $Carp::Internal{+__PACKAGE__}++ ;

No exception will blame your module and your user will have always a meaningful feedback indicating a line of his CBB.

=back

=head1 KNOWN ISSUE

Due to the perl bug #17663 I<(Perl 5 Debugger doesn't handle properly lvalue sub assignment)>, you must know that under the B<-d> switch the lvalue sub assignment will not work, so your program will not run as you expect.

Since version 1.33 the CBF and its extensions B<don't internally use any lvalue sub assignment> although they are fully supported if you decide to use them in your code.

In order to avoid the perl-bug you have 3 alternatives:

=over

=item 1

patch perl itself as suggested in this post: http://www.talkaboutprogramming.com/group/comp.lang.perl.moderated/messages/13142.html (See also the cgi-builder-users mailinglist about that topic)

=item 2

use the lvalue sub assignment (e.g. C<< $s->any_property = 'something' >>) only if you will never need B<-d>

=item 3

if you plan to use B<-d>, use only standard assignments (e.g. C<< $s->any_property('something') >>)

=back

Maybe a next version of perl will fix the bug, or maybe lvalue subs will be banned forever, meanwhile be careful with lvalue sub assignment.

=head1 SUPPORT

You can obtain free support, by using the L<cgi-builder-users> mailing list. Before posting, please:

=over

=item 1

carefully read the whole documentation of the modules you are using

=item 2

check and run the CBF examples and/or your own sample code

=item 3

search the forum archive for any clue about your problem at: http://sourceforge.net/mailarchive/forum.php?forum=cgi-builder-users

=item 4

try to explain your post with a minimum but working and self-contained example (i.e. it should ONLY reproduce the problem whithout any other superfluous code; it should WORK by doing a simple copy, paste and run; it should NOT NEED any other non postable external package, DB connection, ...)

=back


=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=head1 CREDITS

Thanks to these people which - in very different ways - have been somehow helpful with their feedback, suggestions or criticism:

=over

=item * Massimiliano Ciancio

=item * Iain Fairbaim

=item * Maurice Height

=item * Cees Hek

=item * Philipp Knobel

=item * Carlos Molina Garcia

=item * Stefano Rodighiero

=item * Reto Schuettel

=item * Mike South

=item * Mark Stosberg

=item * Vincent Veselosky

=back

=cut
