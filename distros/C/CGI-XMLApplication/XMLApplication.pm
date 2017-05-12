package CGI::XMLApplication;

# ################################################################
#
# (c) 2001 Christian Glahn <phish@CPAN.org>
#
# This code is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# ################################################################

##
# CGI::XMLApplication - Application Module for CGI scripts

# ################################################################
# module loading and global variable initializing
# ################################################################
use strict;

use CGI;
use Carp;
#use Data::Dumper;

# ################################################################
# inheritance
# ################################################################
@CGI::XMLApplication::ISA = qw( CGI );

# ################################################################

$CGI::XMLApplication::VERSION = "1.1.5";

# ################################################################
# general configuration
# ################################################################

# some hardcoded error messages, the application has always, e.g.
# to tell that a stylesheet is missing
@CGI::XMLApplication::panic = (
          'No Stylesheet specified! ',
          'Stylesheet is not available! ',
          'Event not implemented',
          'Application Error',
         );

# The Debug Level for verbose error messages
$CGI::XMLApplication::DEBUG = 0;

# ################################################################
# methods
# ################################################################
sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    bless $self, $class;

    $self->{XML_CGIAPP_HANDLER_}    = [$self->registerEvents()];
    $self->{XML_CGIAPP_STYLESHEET_} = [];
    $self->{XML_CGIAPP_STYLESDIR_}  = '';

    return $self;
}

# ################################################################
# straight forward coded methods

# application related ############################################
# both functions are only for backward compatibilty with older scripts
sub debug_msg {
    my $level = shift;
    if ( $level <= $CGI::XMLApplication::DEBUG && scalar @_ ) {
        my ($module, undef, $line) = caller(1);
        warn "[$module; line: $line] ", join(' ', @_) , "\n";
    }
}

##
# dummy functions
#
# each function is required to be overwritten by any class inheritated
sub registerEvents   { return (); }

# all following function will recieve the context, too
sub getDOM           { return undef; }
sub requestDOM       { return undef; }  # old style use getDOM!

sub getStylesheetString { return ""; }     # return a XSL String
sub getStylesheet       { return ""; }     # returns either name of a stylesheetfile or the xsl DOM
sub selectStylesheet    { return ""; }     # old style getStylesheet

sub getXSLParameter  { return (); }  # should return a plain hash of parameters passed to xsl
sub setHttpHeader    { return (); }  # should return a hash of header

sub skipSerialization{
    my $self = shift;
    $self->{CGI_XMLAPP_SKIP_TRANSFORM} = shift if scalar @_;
    return $self->{CGI_XMLAPP_SKIP_TRANSFORM};
}

# returns boolean
sub passthru {
    my $self = shift;
    if ( scalar @_ ) {
        $self->{CGI_XMLAPP_PASSXML} = shift;
        $self->delete( 'passthru' ); # delete any passthru parameter
    }
    elsif ( defined $self->param( "passthru" ) ) {
        $self->{CGI_XMLAPP_PASSXML} = 1    ;
        $self->delete( 'passthru' );
    }
    return $self->{CGI_XMLAPP_PASSXML};
}

sub redirectToURI {
    my $self = shift;
    $self->{CGI_XMLAPP_REDIRECT} = shift if scalar @_;
    return $self->{CGI_XMLAPP_REDIRECT};
}

# ################################################################
# content related functions

# stylesheet directory information ###############################
sub setStylesheetDir  { $_[0]->{XML_CGIAPP_STYLESDIR_} = $_[1];}
sub setStylesheetPath { $_[0]->{XML_CGIAPP_STYLESDIR_} = $_[1];}
sub getStylesheetDir  { $_[0]->{XML_CGIAPP_STYLESDIR_}; }
sub getStylesheetPath { $_[0]->{XML_CGIAPP_STYLESDIR_}; }

# event control ###################################################

sub addEvent          { my $s=shift; push @{$s->{XML_CGIAPP_HANDLER_}}, @_;}

sub getEventList      { @{ $_[0]->{XML_CGIAPP_HANDLER_} }; }
sub testEvent         { return $_[0]->checkPush( $_[0]->getEventList() ); }

sub deleteEvent       {
    my $self = shift;
    if ( scalar @_ ){ # delete explicit events
        foreach ( @_ ) {
            debug_msg( 8, "[XML::CGIApplication] delete event $_" );
            $self->delete( $_ );
            $self->delete( $_.'.x' );
            $self->delete( $_.'.y' );
        }
    }
    else { # delete all
        foreach ( @{ $self->{XML_CGIAPP_HANDLER_} } ){
            debug_msg( 8, "delete event $_" );
            $self->delete( $_ );
            $self->delete( $_.'.x' );
            $self->delete( $_.'.y' );
        }
    }
}

sub sendEvent         {
    debug_msg( 10, "send event " . $_[1] );
    $_[0]->deleteEvent();
    $_[0]->param( -name=>$_[1] , -value=>1 );
}

# error handling #################################################
# for internal use only ...
sub setPanicMsg       { $_[0]->{XML_CGIAPP_PANIC_} = $_[1] }
sub getPanicMsg       { $_[0]->{XML_CGIAPP_PANIC_} }

# ################################################################
# predefined events

# default event handler prototypes
sub event_init    {}
sub event_exit    {}
sub event_default { return 0 }

# ################################################################
# CGI specific helper functions

# this is required by the eventhandling
sub checkPush {
    my $self = shift;
    my ( $pushed ) = grep {
        defined $self->param( $_ ) ||  defined $self->param( $_.'.x')
    } @_;
    $pushed =~ s/\.x$//i if defined $pushed;
    return $pushed;
}

# helper functions which were missing in CGI.pm
sub checkFields{
    my $self = shift;
    my @missing = grep {
        not length $self->param( $_ ) || $self->param( $_ ) =~ /^\s*$/
    } @_;
    return wantarray ? @missing : ( scalar(@missing) > 0 ? undef : 1 );
}

sub getParamHash {
    my $self = shift;
    my $ptrHash = $self->Vars;
    my $ptrRV   = {};

    foreach my $k ( keys( %{$ptrHash} ) ){
        next unless exists $ptrHash->{$_} && $ptrHash->{$_} !~ /^[\s\0]*$/;
        $ptrRV->{$k} = $ptrHash->{$k};
    }

    return wantarray ? %{$ptrRV} : $ptrRV;
}

# ################################################################
# application related methods
# ################################################################
# algorithm should be
# event registration
# app init
# event handling
# app exit
# serialization and output
# error handling
sub run {
    my $self = shift;
    my $sid = -1;
    my $ctxt = (!@_ or scalar(@_) > 1) ? {@_} : shift; # nothing, hash or context object

    $self->event_init($ctxt);

    if ( my $n = $self->testEvent($ctxt) ) {
        if ( my $func = $self->can('event_'.$n) ) {
            $sid = $self->$func($ctxt);
        }
        else {
            $sid = -3;
        }
    }

    if ( $sid == -1 ){
        $sid = $self->event_default($ctxt);
    }

    $self->event_exit($ctxt);

    # if we allready panic, don't try to render
    if ( $sid >= 0 ) {
        # check if we wanna redirect
        if ( my $uri = $self->redirectToURI() ) {
            my %h = $self->setHttpHeader( $ctxt );
            $h{-uri} = $uri;
            print $self->SUPER::redirect( %h ) . "\n\n";
        }
        elsif ( not $self->skipSerialization() ) {
            # sometimes it is nessecary to skip the serialization
            # eg. due passing binary data.
            $sid = $self->serialization( $ctxt );
        }
    }

    $self->panic( $sid, $ctxt );
}

sub serialization {
    # i require both modules here, so one can implement his own
    # serialization
    require XML::LibXML;
    require XML::LibXSLT;

    my $self = shift;
    my $ctxt = shift;
    my $id;

    my %header = $self->setHttpHeader( $ctxt );

    my $xml_doc = $self->getDOM( $ctxt );
    if ( not defined $xml_doc ) {
        debug_msg( 10, "use old style interface");
        $xml_doc = $self->requestDOM( $ctxt );
    }
    # if still no document is available
    if ( not defined $xml_doc ) {
        debug_msg( 10, "no DOM defined; use empty DOM" );
        $xml_doc = XML::LibXML::Document->new;
        # the following line is to keep xpath.c quiet!
        $xml_doc->setDocumentElement( $xml_doc->createElement( "dummy" ) );
    }

    if( defined $self->passthru() && $self->passthru() == 1 ) {
        # this is a useful feature for DOM debugging
        debug_msg( 10, "attempt to pass the DOM to the client" );
        $header{-type} = 'text/xml';
        print $self->header( %header  );
        print $xml_doc->toString();
        return 0;
    }

    my $stylesheet = $self->getStylesheet( $ctxt );

    my ( $xsl_dom, $style, $res );
    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();

    if ( ref( $stylesheet ) ) {
        debug_msg( 5, "stylesheet is reference"  );
        $xsl_dom = $stylesheet;
    }
    elsif ( -f $stylesheet && -r $stylesheet ) {
        debug_msg( 5, "filename is $stylesheet" );
        eval {
            $xsl_dom  = $parser->parse_file( $stylesheet );
        };
        if ( $@ ) {
            debug_msg( 3, "Corrupted Stylesheet:\n broken XML\n". $@ );
            $self->setPanicMsg( "Corrupted document:\n broken XML\n". $@ );
            return -2;
        }
    }
    else {
        # first test the new style interface
        my $xslstring = $self->getStylesheetString( $ctxt );
        if ( length $xslstring ) {
            debug_msg( 5, "stylesheet is xml string"  );
            eval { $xsl_dom = $parser->parse_string( $xslstring ); };
            if ( $@ || not defined $xsl_dom ) {
                # the parse failed !!!
                debug_msg( 3, "Corrupted Stylesheet String:\n". $@ ."\n" );
                $self->setPanicMsg( "Corrupted Stylesheet String:\n". $@ );
                return -2;
            }
        }
        else {
            # now test old style interface
            # will be removed with the next major release

            debug_msg( 5, "old style interface to select the stylesheet"  );
            $stylesheet = $self->selectStylesheet( $ctxt );
            if ( ref( $stylesheet ) ) {
                debug_msg( 5, "stylesheet is reference"  );
                $xsl_dom = $stylesheet;
            }
            elsif ( -f $stylesheet && -r $stylesheet ) {
                debug_msg( 5, "filename is $stylesheet" );
                eval {
                    $xsl_dom  = $parser->parse_file( $stylesheet );
                };
                if ( $@ ) {
                    debug_msg( 3, "Corrupted Stylesheet:\n broken XML\n". $@ );
                    $self->setPanicMsg( "Corrupted document:\n broken XML\n". $@ );
                    return -2;
                }
            }
            else {
                debug_msg( 2 , "panic stylesheet file $stylesheet does not exist" );
                $self->setPanicMsg( "$stylesheet" );
                return length $stylesheet ? -2 : -1 ;
            }
        }
    }

    eval {
        $style = $xslt->parse_stylesheet( $xsl_dom );
        # $style = $xslt->parse_stylesheet_file( $file );
    };
    if( $@ ) {
        debug_msg( 3, "Corrupted Stylesheet:\n". $@ ."\n" );
        $self->setPanicMsg( "Corrupted Stylesheet:\n". $@ );
        return -2;
    }

    my %xslparam = $self->getXSLParameter( $ctxt );
    eval {
        # first do special xpath encoding of the parameter
        if ( %xslparam && scalar( keys %xslparam ) > 0 ) {
            my @list;
            foreach my $key ( keys %xslparam ) {
                # check for multivalued parameters stored in a \0 separated string by CGI.pm :-/
                if ( $xslparam{$key} =~ /\0/ ) {
                    push @list, $key, (split("\0",$xslparam{$key}))[-1];
                }
                else {
                        push @list, $key, $xslparam{$key};
                }
            }
            $res = $style->transform( $xml_doc,
                                      XML::LibXSLT::xpath_to_string(@list)
                                    );
        }
        else {
            $res = $style->transform( $xml_doc );
        }
    };
    if( $@ ) {
        debug_msg( 3, "Broken Transformation:\n". $@ ."\n" );
        $self->setPanicMsg( "Broken Transformation:\n". $@ );
        return -2;
    }

    # override content-type with the correct content-type
    # of the style (is this ok?)
    $header{-type}    = $style->media_type;
    $header{-charset} = $style->output_encoding;

    debug_msg( 10, "serialization do output" );
    # we want nice xhtml and since the output_string does not the
    # right job
    my $out_string= undef;

    debug_msg( 9, "serialization get output string" );
    eval {
        $out_string =  $style->output_string( $res );
    };
    debug_msg( 10, "serialization rendered output" );
    if ( $@ ) {
        debug_msg( 3, "Corrupted Output:\n", $@ , "\n" );
        $self->setPanicMsg( "Corrupted Output:\n". $@ );
        return -2;
    }
    else {
        # do the output
        print $self->header( %header );
        print $out_string;
        debug_msg( 10, "output printed" );
    }

    return 0;
}

sub panic {
    my ( $self, $pid ) = @_;
    return unless $pid < 0;
    $pid++;
    $pid*=-1;

    my $str = "Application Panic: ";
    $str = "PANIC $pid :" .  $CGI::XMLApplication::panic[$pid] ;
    # this is nice for debugging from logfiles...
    $str  = $self->b( $str ) . "<br />\n";
    $str .= $self->pre( $self->getPanicMsg() );
    $str .= "Please Contact the Systemadminstrator<br />\n";

    debug_msg( 1, "$str" );

    if ( $CGI::XMLApplication::Quiet == 1 ) {
        $str = "Application Panic";
    }
    if ( $CGI::XMLApplication::Quiet == 2 ) {
        $str = "";
    }

    my $status = $pid < 3 ? 404 : 500; # default is the application error ...
    print $self->header( -status => $status ) , $str ,"\n";

}

1;
# ################################################################
__END__

=head1 NAME

CGI::XMLApplication -- Object Oriented Interface for CGI Script Applications

=head1 SYNOPSIS

  use CGI::XMLApplication;

  $script = new CGI::XMLApplication;
  $script->setStylesheetPath( "the/path/to/the/stylesheets" );

  # either this for simple scripts
  $script->run();
  # or if you need more control ...
  $script->run(%context_hash); # or a context object

=head1 DESCRIPTION

CGI::XMLApplication is a CGI application class, that intends to enable
perl artists to implement CGIs that make use of XML/XSLT
functionality, without taking too much care about specialized
errorchecking or even care too much about XML itself. It provides the
power of the L<XML::LibXML>/ L<XML::LibXSLT> module package for
content deliverment.

As well CGI::XMLApplication is designed to support project management
on code level. The class allows splitting web applications into several
simple parts. Through this most of the code stays simple and easy to
maintain. Throughout the whole runtime of a script
CGI::XMLApplication tries to keep the application stable. As well a
programmer has not to bother about some of XML::LibXML/ XML::LibXSLT
transformation pitfalls.

The class module extends the CGI class. While all functionality of the
original CGI package is still available, it should be not such a big
problem, to port existing scripts to CGI::XMLApplication, although
most functions used here are the access function for client data
such as I<param()>.

CGI::XMLApplication, intended to be an application class should make
writing of XML enabled CGI scripts more easy. Especially because of
the use of object orientated concepts, this class enables much more
transparent implemententations with complex functionality compared to
what is possible with standard CGI-scripts.

The main difference with common perl CGI implementation is the fact,
that the client-output is not done from perl functions, but generated
by an internally build XML DOM that gets processed with an XSLT
stylesheet. This fact helps to remove a lot of the HTML related
functions from the core code, so a script may be much easier to read,
since only application relevant code is visible, while layout related
information is left out (commonly in an XSLT file).

This helps to write and test a complete application faster and less
layout related. The design can be appended and customized later
without effecting the application code anymore.

Since the class uses the OO paradigma, it does not force anybody to
implement a real life application with the complete overhead of more
or less redundant code. Since most CGI-scripts are waiting for
B<events>, which is usually the code abstraction of a click of a
submit button or an image, CGI::XMLApplication implements a simple
event system, that keeps event related code separated from other events.

Therefore, a final application class is not meant to have a constructor
anymore. All functionality should be encapsulated into implicit or
explicit event handlers. Because of a lack in Perl's OO implementation
the call of a superclass constructor before the current constructor
call is not default behavior in Perl. For that reason I decided to
have special B<events> to enable the application to initialize
correctly, excluding the danger of leaving important variables
undefined. Also this forces the programmer to implement
scripts more problem orientated, rather than class or content focused.

Another design aspect for CGI::XMLApplication is the strict
differentiation between CODE and PRESENTATION. IMHO this, in fact
being one of the major problems in traditional CGI programming. To
implement this, the XML::LibXML and XML::LibXSLT modules are used by
default but may be replaced easily by any other XML/XSLT capable
modules. Each CGI Script should generate an XML-DOM, that can be
processed with a given stylesheet.

B<Pay attention: In this Document XML-DOM means the DOM of XML::LibXML
and not XML::DOM!>

=head2 Programflow of a CGI::XMLApplication

The following Flowchart illustratrates how CGI::XMLApplication behaves
during runtime. Also chart shows where specialized application code gets
control during script runtime.

  ------- CGI Script ------->|<--------- CGI::XMLApplication --------
   .---------------------.    .--------------------.
   | app-class creation  |--- | event registration |
   `---------------------'    | registerEvents()   |
                              `--------------------'
   .------------------------.            |
   | context initialization |------------'
   |     ( optional )       |
   `------------------------'
              |
   .-----------------------.  .------------------------.
   | run() function called |--| application initialize |
   `-----------------------'  |      event_init()      |
                              `------------------------'
                                          |
                                 .--------'`------------.
                                / event parameter found? \_
                                \       testEvent()      / \
                                 `--------.,------------'   |
                                          |                 |
                                      yes |              no |
                                          |                 |
                               .------------.  .------------------.
                               | call event |  | call             |
                               |  event_*() |  |  event_default() |
                               `------------'  `------------------'
                                          |                |
                               .---------------------.     |
                               | application cleanup |-----'
                               |     event_exit()    |
                               `---------------------'
                                          |
                                .---------'`------------.
                              _/ avoid XML serialization \
                             / \   skip_serialization()  /
                            |   `---------.,------------'
                            |             |
                        yes |          no |
                            |             |
                            |  .--------------------------.
                            |  | XML generation, XSLT     |
                            |  | serialization and output |
                            |  |     serialization()      |
                            |  `--------------------------'
    .---------------.       |             |
    |      END      |-------+-------------'
    `---------------'

=head2 What are Events and how to catch them

Most CGI Scripts handle the result of HTML-Forms or similar requests
from clients. Analouge to GUI Programming, CGI::XMLApplication calls
this an B<event>. Spoken in CGI/HTML-Form words, a CGI-Script handles
the various situations a clients causes by pushing a submit button or
follows a special link. Because of this common events are thrown by
arguments found in the CGI's query string.

An event of CGI::XMLApplication has the same B<name> as the input
field, that should cause the event. The following example should
illustrate this a little better:

    <!-- SOME HTML CODE -->
    <input type="submit" name="dummy" value="whatever" />
    <!-- SOME MORE HTML :) -->

If a user clicks the submitbutton and you have registered the event
name B<dummy> for your script, CGI::XMLApplication will try to call the
function B<event_dummy()>. The script module to handle the dummy event
would look something like the following code:

 # Application Module
 package myApp;

 use CGI::XMLApplication;
 @ISA = qw(CGI::XMLApplication);

 sub registerEvents { qw( dummy ); } # list of event names

 # ...

 sub event_dummy {
     my ( $self, $context ) = @_;

     # your event code goes here

     return 0;
 }

During the lifecircle of a CGI script, often the implementation starts
with ordinary submit buttons, which get often changed to so called
input images, to fit into the UI of the Website. One does not need to
change the code to make the scripts fit to these changes;
CGI::XMLApplication already did it. The code has not to be changed if
the presentation of the form changes. Therefore there is no need to
declare separate events for input images. E.g. an event called evname
makes CGI::XMLApplication tests if evname B<or> evname.x exist in the
querystring.

So a perl artist can implement and test his code without caring if the
design crew have done their job, too ;-)

In many cases an web application is also confronted with events that
can not be represented in with querystring arguments. For these cases
CGI::XMLApplication offers the possibility to send B<special events>
from the B<event_init()> function for example in case of application
errors. This is done with the B<sendEvent()> Function. This will set a
new parameter to the CGI's querystring after removing all other
events. B<One can only send events that are already registred!>.

Although a sendEvent function exists, CGI::XMLApplication doesn't
implement an event queqe. For GUI programmers this seems like a
unnessecary restriction. In terms of CGI it makes more sense to think
of a script as a program, that is only able to scan its event queqe
only once during runtime and stopped before the next event can be
thrown. The only chance to stop the script from handling a certain
event is to send a new event or delete this (or even all) events from
inside the event_init() function. This function is always called at
first from the run method. If another event uses the sendEvent
function, the call will have no effect.

=over 4

=item method registerEvents

This method is called by the class constructor - namely
CGI::XMLApplication's B<new()> function . Each application should
register the events it likes to handle with this function. It should
return an array of eventnames such as eg. 'remove' or 'store'. This
list is used to find which event a user caused on the client side.

=item method run

Being the main routine this should be the only method called by the
script apart from the constructor. All events are handled inside the
method B<run()>.  Since this method is extremly simple and transparent
to any kind of display type, there should be no need to override this
function. One can pass a context hash or context object, to pass external
or prefetched information to the application. This context will be
available and accessible in all events and most extra functions.

This function does all event and serialization related work. As well
there is some validation done as well, so catched events, that are not
implemented, will not cause any harm.

=back

=head2 The Event System

A CGI::XMLApplication is split into two main parts: 1) The executable
script called by the webserver and 2) the application module which has
to be loaded, initialized and called by the script.

Commonly applications that make use of CGI::XMLApplication, will not
bother about the B<run> function too much. All functionality is kept
inside B<event>- and (pseudo-)B<callback functions>. This forces one
to implement much more strict code than common perl would allow. What
first looks like a drawback, finally makes the code much easier to
understand, maintain and finally to extend.

CGI::XMLApplication knows two types of event handlers: implicit
events, common to all applications and explicit events, reflecting the
application logic. The class assumes that implicit events are
implemented in any case. Those events have reserved names and need not
be specified through B<registerEvents>. Since the class cannot know
something about the application logic by itself, names of events have
to be explicitly passed to be handled by the application. As well all
event functions have to be implemented as member methods of the
application class right now. Because of perls OO interface a class has
to be written inside its own module.

An event may return a integer value. If the event succeeds (no fatal
errors, e.g. database errors) the explicit or common event function
should return a value greater or eqal than 0. If the value is less
than 0, CGI::XMLApplication assumes an application panic, and will not
try to generate a DOM or render it with a stylesheet.

There are 4 defined panic levels:

=over 4

=item -1

Stylesheet missing

=item -2

Stylesheet not available

=item -3

Event not implemented

=item -4

Application panic

=back

Apart from B<Application Panic> the panic levels are set
internally. An Application Panic should be set if the application
catches an error, that does not allow any XML/XSLT processing. This
can be for example, that a required perl module is not installed on
the system.

To make it clear: If CGI::XMLApplication throws a panic, the
application is broken, not completely implemented or stylesheets are
missing or broken. Application panics are meant for debugging purposes
and to avoid I<Internal Server Errors>. They are B<not> meant as a
replacement of a propper error handling!

But how does CGI::XMLApplication know about the correct event handler?

One needs to register the names of the events the application handles.
This is done by implmenting a registerEvents() function that simply
returns an B<array> of event names. Through this function one prepares
the CGI::XMLApplication to catch the listed names as events from the
query string the client browser sends back to the
script. CGI::XMLApplication tries to call a event handler if a name of
a registred event is found. The coresponding function-name of an event
has to have the following format:

 event_<eventname>

E.g. event_init handles the init event described below.

Each event has a single Parameter, the context. This can be an unblessed
hash reference or an object, where the user can store whatever needed.
This context is useful to pass scriptwide data between callbacks and
event functions around. The callback is even available and useable if
the script does not initialize the application context as earlier shown
in the program flow chart.

If such a function is not implemented in the application module,
CGI::XMLApplication sets the I<Event not implemented> panic state.

All events have to return an integer that tells about their execution
state as already described.

By default CGI::XMLApplication does not test for other events if it
already found one. The most significant event is the first name of an
event found in the query string - all other names are simply ignored.
One may change this behaviour by overriding the B<testEvent()>
function.

But still it is a good idea to choose the event names carefully and do
not mix them with ordinary datafield names.

=over 4

=item function testEvent

If it is nesseccary to check which event is relevant for the current
script one can use this function to find out in event_init(). If this
function returns I<undef>, the default event is active, otherwise it
returns the eventname as defined by B<registerEvents>.

In case one needs a special algorithm for event selection one can
override this function. If done so, one can make use of the
application context inside this function since it is passed to
B<testEvent()> by the B<run()> function.

=item method sendEvent SCALAR

Sometimes it could be necessary to send an event by your own (the
script's) initiative. A possible example could be if you don't have
client input but path_info data, which determinates how the script
should behave or session information is missing, so the client should
not even get the default output.

This can only be done during the event_init() method call. Some coders
would prefer the constructor, which is not a very good idea in this
case: While the constructor is running, the application is not
completely initialized. This can be only ashured in the event_init
function. Therefore all application specific errorhandling and
initializing should be done there.

B<sendEvent> only can be called from event_init, because any
CGI::XMLApplication will handle just one event, plus the B<init> and
the B<exit event>. If B<sendEvent> is called from another event than
B<event_init()> it will take not effect.

It is possible through sendEvent() to keep the script logic clean.

Example:

  package myApp;
  use CGI::XMLApplication;
  @ISA = qw(CGI::XMLApplication);

  sub registerEvents { qw( missing ... ) ; }

  # event_init is an implicit event
  sub event_init {
     my ( $self, $context ) = @_;
     if ( not ( defined $self->param( $paraname ) && length $self->param( $paramname ) ) ){
        # the parameter is not correctly filled
        $self->sendEvent( 'missing' );
     }
     else {

    ... some more initialization ...

     }
     return 0;
  }

  ... more code ...

  # event_missing is an explicit event.
  sub event_missing {
     my ( $self , $context ) = @_;

     ... your error handling code goes ...

     return -4 if $panic;  # just for illustration
     return 0;
  }

=back

=head2 Implicit Events

CGI::XMLApplication knows three implicit events which are more or less
independent to client responses: They are 'init', 'exit', and
'default'. These events already exist for any
CGI::XMLApplication. They need not to be implemented separately if they
make no sense for the application.

=over 4

=item event_init

The init event is set before the CGI::XMLApplication tries to evaluate
any of script parameters. Therefore the event_init method should be
used to initialize the application.

=item event_exit

The event_exit method is called after all other events have been
processed, but just before the rendering is done. This should be used,
if you need to do something independend from all events before the
data is send to the user.

=item event_default

This event is called as a fallback mechanism if CGI::XMLApplication
did not receive a stylesheet id by another event handler, for example
if no event is matched.

=back


=head2 the XML Serialization

The presentation is probably the main part of a CGI script. By using
XML and XSLT this can be done in a standartised manner. From the
application view all this can be isolated in a separate subsystem as
well. In CGI::XMLApplication this subsystem is implemented inside the
B<serialize()> function.

For XML phobic perl programmers it should be cleared, that
CGI::XMLApplication makes real use of XML/XSLT functionalty only
inside this function. For all code explained above it is not required
to make use of XML at all.

The XML serialization subsystem of CGI::XMLApplication tries to hide
most of non application specific code from the application programmer.

This method renders the data stored in the DOM with the stylesheet
returned by the event handler. You should override this function if
you like to use a different way of displaying your data.

If the serialization should be skipped, CGI::XMLApplication will not
print any headers. In such case the application is on its own to pass
all the output.

The algorithm used by serialization is simple:

=over 4

=item * request the appplication DOM through B<getDOM()>

=item * test for XML passthru

=item * get the stylesheet the application preferes through B<selectStylesheet()>

=item * parse the stylesheet

=item * transform the DOM with the stylesheet

=item * set Content-Type and headers

=item * return the content to the client

=back

If errors occour on a certain stage of serialization, the application
is stopped and the generated error messages are returned.

CGI::XMLApplication provides four pseudo-callbacks, that are used to
get the application specific information during serialization. In
order of being called by CGI::XMLApplication::serialization() they
are:

=over 4

=item * getDOM

=item * setHttpHeader

=item * getStylesheet

=item * getXSLTParameter

=back

In fact only getStylesheet has to be implemented. In most cases it
will be a good idea to provide the getDOM function as well. The other
functions provider a interface to make the CGI output more
generic. For example one can set cookies or pass XSL parameters to
XML::LibXSLT's xsl processor.

These methods are used by the serialization function, to create the
content related datastructure. Like event functions these functions
have to be implemented as class member, and like event funcitons the
functions will have the context passed as the single parameter.

=over 4

=item getDOM()

getDOM() should return the application data as
XML-DOM. CGI::XMLApplication is quite lax if this function does not
return anything - its simply assumed that an empty DOM should be
rendered. In this case a dummy root element is created to avoid error
messages from XML::LibXSLT.

=item setHttpHeader()

B<setHttpHeader> should return a hash of headers (but not the
Content-Type). This can be used to set the I<nocache> pragma, to set
or remove cookies. The keys of the hash must be the same as the named
parameters of CGI.pm's header method. One does not need to care about
the output of these headers, this is done by CGI::XMLApplication
automatically.

The content type of the returned data is usually not required to be
set this way, since the XSLT processor knows about the content type,
too.

=item getStylesheet()

If the B<getStylesheet> is implemented the CGI::XMLApplication will
assume the returned value either as a filename of a stylesheet or as a
XML DOM representation of the same. If Stylesheets are stored in a
folder accessible for the the web-server, a common path for the
stylesheets should be set and  B<CGI::XMLApplication> will initiate
the parsing job.

In cases the stylesheet is already present as a string (e.g. as a
result of a database query) one may pass this string directly to
B<CGI::XMLApplication>.

I<selectStylesheet> is an alias for I<getStylesheet> left for
compatibility reasons.

If none of these stylesheet selectors succeeds the I<Stylesheet
missing> panic code is thrown. If the parsing of the stylesheet XML
fails I<Stylesheet not available> is thrown. The latter case will also
provide details where the stylesheet selection failed.

B<selectStylesheet()> has to return a valid path/filename for the
stylesheet requested.

=item getXSLTParameter()

This function helps passing parameters to XML::LibXSLT's xsl
processor. The function needs only to return a hash and does not need
to encode the parameters.

The function is the last callback called before the XSLT processing is
started.

=back

=head2 Flow Control

Besides the sendEvent() function, CGI::XMLApplication provides
two additional functions for controlling the flow of the application.

These two functions are related to the XML serialization and have not
affect to the event handling.


=over 4

=item passthru()

Originally for debugging purposes CGI::XMLApplication supports the
B<passthru> argument in the CGI query string. It can be used to
directly pass the stringified XML-DOM to the client.

Since there are cases one needs to decide from within the application
if an untransformed XML Document has to be returned, this function was
introduced.

If is called without parameters B<passthru()> returns the current
passthru state of the application. E.g. this is done inside
B<serialization()>. Where TRUE (1) means the XML DOM should be passed
directly to the client and FALSE (0) marks that the DOM must get
XSL transformed first.

Optional the function takes a single parameter, which shows if the
function should be used in set rather than get mode. The parameter is
interpreted as just described.

If an application sets passthru by itself, any external 'passthru'
parameter will be lost. This is useful if the application requires
access to the plain (untransformed) XML Data.


=item skipSerialization()

To avoid the call of B<serialization()> one should set B<skipSerialization>.

   event_default {
      my $self = shift;
      # avoid serialization call
      $self->skipSerialization( 1 ); # use 0 to unset

      # now you can directly print to the client, but don't forget the
      # headers.

      return 0;
   }

=back

=head2 Helperfunctions for internal use

=over 4

=item function checkPush LIST

This function searches the query string for a parameter with the
passed name. The implementation is "imagesave" meaning there is no
change in the code needed, if you switch from input.type=submit to
input.type=image or vv. The algorithm tests whether a full name is
found in the querystring, if not it tries tests for the name expanded
by a '.x'. In context of events this function interprets each item
part in the query string list as an event. Because of that, the
algorithm returns only the first item matched.

If you use the event interface with this function, then the
HTML-forms should pass unique events to the script in order to
avoid confusing behaviour.

This function is used by testEvent() so if it is required to change
the way CGI::XMLApplication selects events, override that function.

=item method panic SCALAR

This a simple error message handler. By default this function will
print some information to the client where the application
failed. During development, this is a useful feature, while on a production
system this may pass vulnerable information about the system to the
clients. To change the default behaviour, I<$CGI::XMLApplication::Quiet>
should get set to 1. This will still show an error page but without
displaying error messages. Alternatively, the panic method can be overloaded.

The current implementation send the 404 status to the client if any
low level errors occour ( e.g. panic levels > -4 aka Application
Panic).  Commonly this really shows a "Not Found" on the application
Level. Application Panics will set the 500 error state. This makes
this implementation work perfect with a mod_perl installation.

In case L<mod_perl> is used to handle the script one likes to set
I<CGI::XMLApplication::Quiet> to 2 which will cause
CGI::XMLApplication just to return the error state while L<mod_perl>
does the rest.

=item method setPanicMsg $SCALAR

This useful method, helps to pass more specific error messages to the
user. Currently this method is not very sophisticated: if
the method is called twice, only the last string will be displayed.

=item function getPanicMsg

This method returns the panic message set by setPanicMsg().

=back

=head2 CGI Extras

The following functions are some neat features missing in
CGI.pm

=over 4

=item function checkFields LIST

This is an easy way to test whether all required fields are filled out
correctly. Called in array context the function returns the list of
missing parameter. (Different to param() which returns all parameter names).
In scalar context the function returns a boolean value.

=item function getParamHash LIST

This function is a bit better for general data processing as
the standard CGI::Vars function. While Vars sets a keys for each
parameter found in the query string, getFieldsAsHash returns only the
requested fields (as long they aren't NULL). This is useful in scripts
where the script itself handles different kind of data within the
same event.

Since the function relies on Vars the returned data has the same
structure Vars returns.

=back

=head2 some extra functions for stylesheet handling

The getStylesheet() function should return either a filename or a
stringnyfied XSL-DOM. For the first case it can be a restriction to
return the fully qualified path. The following functions help managing
the stylesheetpath, system-wide.

=over 4

=item method setStylesheetDir DIRNAME

alias for B<setStylesheetPath>

=item method setStylesheetPath DIRNAME

This method is for telling the application where the stylesheets can
be found. If you keep your stylesheets in the same directory as your
script you might leave this untouched. However, it is suggested to store
stylesheet files in a directory that is out of reach for client access.

=item function getStylesheetPath

This function is only relevant if you write your own
B<serialization()> method. It returns the current path to the
application stylesheets.

=back

=head1 SEE ALSO

CGI, perlobj, perlmod, XML::LibXML, XML::LibXSLT

=head1 AUTHOR

Christian Glahn, phish@cpan.org

=head1 VERSION

1.1.5
