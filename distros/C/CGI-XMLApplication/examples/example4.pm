# this is the application class 

# this example shows how to skip the build in xml/xslt serialization

package example4;

use vars qw( @ISA @HANLDER );
use CGI::XMLApplication;
use XML::LibXML;

@ISA     = qw(CGI::XMLApplication);
sub registerEvents { qw( submit ); } # the handler list
sub selectStylesheet {
  return './' .  ex2_form.xsl;
}

sub event_init {
  my ( $self , $ctxt ) = @_;

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

sub event_default {
  my ( $self , $ctxt ) = @_;
  $ctxt->{-ROOT}->appendTextChild('message','Hey user from ' .
                                             $self->remote_host() .
                                            " pass your email!" );

  return 0;
}

sub event_submit {
  my ( $self , $ctxt ) = @_;

  # assume we have an file uploaded by the user and simply want to return
  # it back to the client
  my $file = $self->param("thefile");
  
  my $type = $self->uploadInfo($file)->{'Content-Type'};
  print $self->header( -type=>$type );
  while ( <$file> ) { print; }

  # in such a case we already handled the request so CGI::XMLApplication
  # should not try any serialization
  $self->skipSerialization(1);

  return 0;
}

1;
