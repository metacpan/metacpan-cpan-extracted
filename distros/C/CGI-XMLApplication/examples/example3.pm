# this is the application class # This example shows how to pass a
# configuration to CGI::XMLApplication.  In fact the data passed to
# CGI::XMLApplication can be of any type you like. The data is simply
# inserted to the context (see CGI::XMLApplication for
# details). Basicly this module has the same function as example2, so
# I asume you have through that module already.

package example3;

use vars qw( @ISA @HANLDER );
use CGI::XMLApplication;
use XML::LibXML;

@ISA     = qw(CGI::XMLApplication);
sub registerEvents { qw( submit _internal_error_ ); } # the handler list
sub requestDOM     { my ( undef, $ctxt ) = @_; return $ctxt->{-XML}; }
sub selectStylesheet {
  my ( undef, $ctxt ) = @_;
  return './' . qw( ex2_form.xsl ex2_finish.xsl )[ $ctxt->{-stylesheet} ];
}

sub event_init {
  my ( $self , $ctxt ) = @_;

  # lets see if our configuration is here :)
  if ( exists $ctxt->{-DUMMY} ){
    # not very useful, huh? =)
    # the thing here is, that the data passed to run() in the script,
    # is available in ALL events. this may be useful, if one has to
    # load script configurations on runtime
    warn "example3 found the dummy!\n";
  }
  # initialize the internal context
  my $dom = XML::LibXML::Document->new();
  my $root= $dom->createElement( 'yourfavouritetagname' );
  $dom->setDocumentElement( $root );

  $ctxt->{-XML} = $dom;
  $ctxt->{-ROOT}= $root;
  $ctxt->{-stylesheet} = 0; # on default we'll display the form

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

  return 0;
}

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
