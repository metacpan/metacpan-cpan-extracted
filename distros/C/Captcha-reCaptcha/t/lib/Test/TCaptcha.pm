package Test::TCaptcha;

@ISA = qw(Captcha::reCAPTCHA);
use Captcha::reCAPTCHA;
use HTTP::Response;

sub set_response {
  my $self     = shift;
  my $response = shift;
  $self->{t_response} = $response;
}

sub _post_request {
  my $self = shift;
  my $url  = shift;
  my $args = shift;

  # Just keep the args
  $self->{t_url}  = $url;
  $self->{t_args} = $args;

  my $r = HTTP::Response->new( 200, 'OK');
  $r->header('Content-type' => 'text/plain');
  $r->content( $self->{t_response} );

  return $r;
}

sub get_url  { shift->{t_url} }
sub get_args { shift->{t_args} }
