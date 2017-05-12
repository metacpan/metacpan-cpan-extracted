# this is the application class
#
# this example shows how to make use of the context
# and how passing your personalized xml dom around.
#
# actually this is allready a full featured example, although it does
# nothing useful :>
#
# while programming with this package you should avoid printing to the
# clientside, because this is the job of the serialization function.
# for q'n'd scripter this will be the biggest change of
# paradigma. from the viewpoint of XML/ XSLT this follows exactly the
# paradigma of separating function, content and presentation.
#
# once you get used not using the print function from inside a script,
# you will realize the resulting code will be much easier to maintain.

package example2;

use vars qw( @ISA @HANLDER );
use CGI::XMLApplication;
use XML::LibXML;

@ISA     = qw(CGI::XMLApplication);

# if you implement internal error events ashure, you place them at the
# very end of the eventlist, so if someone places a parameter with the
# same name into a form, the script can still find the correct event
# (which is usually the submit button a client pushed).
#
# what are internal events good for? i found it's comfortable to have
# special events, for special problems. this could be that a database
# server is not reachable or a client session has expiered. These are
# no real events, clients cause by clicking around, but in my logic,
# this should be handled in special events. So i delete all existing
# events (done implicit by sendEvent) and send the error event by
# myself.

sub registerEvents { qw( submit _internal_error_ ); } # the handler list

# the requestDOM function is called by the serialize function.  it has
# to return a XML::LibXML::Document object. If no DOM is
# returned,sreialize will create an empty DOM, so stylesheets can be
# processed, even if the script does not create a DOM structure
#
# pay attention that you can use any name to store your own DOM
# in the context hash.

sub requestDOM     { my ( undef, $ctxt ) = @_; return $ctxt->{-XML}; }

# one can implement any complexity of stylesheet selection wanted, but
# i recommend to keep this function as simple as possible.
sub selectStylesheet {
  my ( $self, $ctxt ) = @_;
  return $self->getStylesheetPath() . qw( ex2_form.xsl ex2_finish.xsl )[ $ctxt->{-stylesheet} ];
}


# the following subroutine will make CGI::XMLApplication to pass the returned 
# hash to the stylesheetprocessor
sub getXSLTParameter {
  my ( $self, $ctxt ) = @_;
  return ( test=>$ctxt->{-test}||-1 );
}

# the init event should do all required initializing, that is common
# to all events implemeted, as well system problems should be catched
# here as well
sub event_init {
  my ( $self , $ctxt ) = @_;

  # initialize the context
  my $dom = XML::LibXML::Document->new();
  my $root= $dom->createElement( 'yourfavouritetagname' );
  $dom->setDocumentElement( $root );

  $ctxt->{-XML} = $dom;
  $ctxt->{-ROOT}= $root;
  $ctxt->{-stylesheet} = 0; # on default we'll display the form

  # do some testing
  # in more complex scripts such tests would be confusing here ...
  # the use of error handling inside event_init is more for general
  # problems.
  if ( $self->param('email')=~/\@.*\@/ || $self->param('email')!~/\@..+/ ) {
    $self->sendEvent('_internal_error_' );
  }
}

# exit is called before serialization
sub event_exit {
  my ( $self , $ctxt ) = @_;
  # we do some caching here, but you can do whatever you like
  # (e.g. release lockfiles)
  if ( exists $ctxt->{-XML} && not exists $ctxt->{-ERROR} ){
    open CACHEFILE , "> ex2_cache.xml";
    print CACHEFILE $ctxt->{-XML}->toString();
    close CACHEFILE;
  }
}

sub event_default {
  my ( $self , $ctxt ) = @_;
  $ctxt->{-ROOT}->appendTextChild('message','Hey user from ' .
                                             $self->remote_host() .
                                            " pass your email!" );

  # PAY ATTENTION HERE!
  # the return value has to be greater or equal 0. If a value
  # less than 0 is returned CGI::XMLApplication asumes an so called
  # panic. This will have the effect, that no XSLT redering is tried 
  # and a special error message is returned (see setPanicMsg)
  # CGI::XMLApplication knows 4 types of panics:
  # -1 "no stylesheet set" (internal error)   (no filename given)
  # -2 "no stylesheet found" (internal error) (like file not found)
  # -3 "no event function for registred event" (internal error) (...)
  # -4 "application error"    (this one is for you) ;)
  # 
  # if it is a valid value, the value itself has no meaning anymore...
  return 0;
}

# as one can see easily, the event functions has to have the same name
# as the event has. the prefix 'event_' is a requirement.
#
# i think, i'll introduce real callbacks quite soon, so one can choose
# any function name prefered and has only to register it to the related
# event.

sub event__internal_error_ {
  my ( $self , $ctxt ) = @_;
  $ctxt->{-ROOT}->appendTextChild('message',
                                  'this email seems not to be valid');
  $ctxt->{-ROOT}->appendTextChild( 'email', "".$self->param( 'email' ) );
  $ctxt->{-ERROR} = 1;
  return 0;
}

sub event_submit {
  my ( $self , $ctxt ) = @_;
  $ctxt->{-ROOT}->appendTextChild('message',
                                  "ALL YOUR BASE DOES BELONG TO US!"); # ;)
  $ctxt->{-stylesheet} = 1; # submit was ok, so display the thank you message
  return 0;
}

1;
