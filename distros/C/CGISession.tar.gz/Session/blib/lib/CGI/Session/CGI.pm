use strict;

package CGI::Session::CGI;
use CGI;
use CGI::Carp;

use vars qw( @ISA );

@ISA = qw( CGI );

my %_params = ( -errors => __PACKAGE__.".errors",
		-messages => __PACKAGE__.".messages",
	        -session => __PACKAGE__.".session", );
   
sub errors { _param( shift, "-errors", @_ ); }
sub messages { _param( shift, "-messages", @_ ); }
sub session
  {
    my $self = shift;
    if ( @_ )
      {
	my $session = shift;
	#
	# If someone is unsetting the session then @_ will be
	# defined, but $session will not.  In this case we
	# skip setting the 'used_with_custom_cgi' flag.
	#
	$session->used_with_custom_cgi( 1 ) if defined $session ;
	_param( $self, "-session",  $session );
      }
    else
      {
	return _param( $self, "-session" );
      }
  }

sub _param
  {
    my $self = shift;
    if ( scalar @_ == 1 )
      {
	my $field = shift;
	my $slot = $_params{$field};
	croak "Programmer Error: $field is not a known parameter" unless defined $slot;
	return $self->{$slot};
      }
    else
      {
	while( my $field = shift )
	  {
	    my $slot = $_params{$field};
	    croak "Programmer Error: $field is not a known parameter" unless defined $slot;
	    $self->{$slot} = shift;
	  }
      }
  }

sub set { _param(shift,@_); }

sub add_error
  {
    my ( $self, $error ) = @_;
    push @{ $self->errors}, $error ;
  }

sub has_errors { return scalar @{shift->errors}; }

sub add_message
  {
    my ( $self, $message ) = @_;
    push @{$self->messages}, $message;
  }

sub has_messages { return scalar @{shift->messages}; }

sub new
  {
    my $type = shift;
    my $self = $type->SUPER::new;
    $self->errors([]);
    $self->messages([]);
    return $self;
  }

sub header
  {
    my $self = shift;
    my $header;
    if ( defined $self->session and $self->session )
      {
	$header = $self->SUPER::header( $self->session->header_args_with_cookie(@_) );
      }
    else
      {
	$header = $self->SUPER::header(@_);
      }
    carp $header;
    return $header;
  }

sub end_html
  {
    my $self = shift;
    if ( defined $self->session and $self->session )
      {
	$self->session(undef);
      }
    return $self->SUPER::end_html(@_);
  }

sub end_form
  {
    my $self = shift;
    my $out = "";

    # Inject hidden field with passkey if it exists.
    #
    if ( defined $self->session and $self->session )
      {
	my $session = $self->session;
	my $passkey = $session->passkey;
	my $passkey_name = $session->passkey_name;
	if ( defined $passkey and $passkey )
	  {
	    $out .= qq(<input type=hidden name="$passkey_name" value="$passkey">\n);
	  }
      }
    $out .= $self->SUPER::end_form(@_);
    return $out;
  }
       
sub errors_as_html
  {
    my $self = shift;
    return undef unless $self->has_errors;
    my $out .= qq(<ul>\n);
    foreach my $error ( @{$self->errors} )
      {
	$out .= qq(  <li><font color="#ff0000">$error</font></li>\n);
      }
    $out .= qq(</ul>\n);
    return $out;
  }
	       
sub messages_as_html
  {
    my $self = shift;
    return undef unless $self->has_messages;
    my $out .= qq(<ul>\n);
    foreach my $message ( @{$self->messages} )
      {
	$out .= qq(  <li>$message</li>\n);
      }
    $out .= qq(</ul>\n);
    return $out;
  }


1;

