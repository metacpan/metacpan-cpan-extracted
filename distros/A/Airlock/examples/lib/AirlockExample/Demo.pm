package AirlockExample::Demo;

# What both example apps share: the Airlock itself and the approval page as
# plain data plus a tiny HTML renderer. In a real application the Airlock is
# built from your configuration and the page is one of your own templates.

use Moo;
use Airlock;
use Airlock::Factor::Callback;
use namespace::autoclean;

has base_url => ( is => 'ro', default => 'http://localhost:5000' );

has airlock => ( is => 'lazy' );

sub _build_airlock {
  my ( $self ) = @_;
  return Airlock->new(
    clients          => { 'demo-cli' => { name => 'Demo CLI', scopes => [qw( read admin )] } },
    verification_uri => $self->base_url.'/approve',
    # asking for the scope "admin" needs the PIN on top of being logged in
    policy  => { step_up => { admin => ['pin'] } },
    factors => [
      Airlock::Factor::Callback->new( name => 'pin', amr => 'pin', verify => sub { $_[1] eq '4711' } )
    ]
  );
}

# YOUR LOGIN GOES HERE. The demo has exactly one person and she is always
# logged in. A real application returns its session's user, or nothing, and
# sends anyone who is not logged in to its login page first.
sub subject { { id => 'demo-user' } }

sub escape {
  my ( $self, $text ) = @_;
  $text //= '';
  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  $text =~ s/"/&quot;/g;
  return $text;
}

# Everything the approval page does, as status and HTML, so that the Plack and
# the Mojolicious example differ only in how they read a request.
sub page {
  my ( $self, %param ) = @_;
  my $airlock = $self->airlock;
  my $subject = $self->subject;
  my $code    = $param{user_code} // '';
  return ( 200, $self->_form('') ) unless length $code;

  # Opening a link must never approve or deny anything: the action only counts
  # when it arrives in the body of a POST.
  my $action = ( $param{method} // '' ) eq 'POST' ? $param{action} // '' : '';

  if ( $action eq 'deny' ) {
    my $denied = $airlock->deny( $code, subject => $subject );
    return $denied->ok ? ( 200, '<p>Denied. You can close this window.</p>' ) : ( 404, $self->_form('That code is unknown or has expired.') );
  }

  my $view = $airlock->inspect( $code, subject => $subject )
    or return ( 404, $self->_form('That code is unknown or has expired.') );
  my $needs = $airlock->requirements( $view, $subject );
  return ( 200, $self->_confirm( $view, $needs, '' ) ) unless $action eq 'approve';

  my $result = $airlock->approve( $code, subject => $subject, proofs => { pin => $param{pin} } );
  return ( 200, '<p>Approved. You can close this window.</p>' ) if $result->ok;
  return ( 403, '<p>Too many wrong attempts. Start again on the device.</p>' ) if $result->status eq 'too_many_failures';
  return ( 404, $self->_form('That code is unknown or has expired.') ) if $result->status eq 'unknown_code';
  return ( $result->status eq 'factor_required' ? 200 : 403,
    $self->_confirm( $view, $needs, $result->status eq 'factor_failed' ? 'Wrong PIN.' : '' ) );
}

sub _form {
  my ( $self, $message ) = @_;
  return '<p>'.$self->escape($message).'</p>'
    .'<form method="get" action="/approve"><label>Code <input name="user_code" autofocus></label>'
    .'<button>Continue</button></form>';
}

sub _confirm {
  my ( $self, $view, $needs, $message ) = @_;
  my $pin = grep( { $_ eq 'pin' } @$needs ) ? '<label>PIN <input name="pin" inputmode="numeric" autocomplete="off"></label>' : '';
  # YOUR CSRF TOKEN GOES INTO THIS FORM. Approving is a state change made with
  # the person's session; check the token before calling approve or deny.
  return '<p>'.$self->escape($message).'</p>'
    .'<p><b>'.$self->escape( $view->{client_name} ).'</b> wants access: '
    .$self->escape( join ', ', @{ $view->{scopes} } ).'</p>'
    .'<p>Asked '.$view->{age}.' seconds ago from '.$self->escape( $view->{origin}{ip} )
    .' ('.$self->escape( $view->{origin}{ua} ).')</p>'
    .'<form method="post" action="/approve">'
    .'<input type="hidden" name="user_code" value="'.$self->escape( $view->{user_code} ).'">'
    .$pin
    .'<button name="action" value="approve">Approve</button>'
    .'<button name="action" value="deny">Deny</button></form>';
}

1;
