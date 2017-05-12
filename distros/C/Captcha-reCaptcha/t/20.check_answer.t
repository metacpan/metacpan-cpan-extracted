use strict;
use warnings;
use Test::More;
use HTTP::Response;
use Captcha::reCAPTCHA;
use Data::Dumper;


# Looks real. Isn't.
use constant PRIVKEY => '6LdAAAkAwAAAix_GF6AMQnw5UCG3JjWluQJMNGjY';

my @schedule;

BEGIN {

  # Looks real. Isn't.
  @schedule = (
    {
      name => 'Simple correct',
      args =>
       [ PRIVKEY, '192.168.0.1', '..challenge..', '..response..' ],
      response   => "true\n",
      check_args => {
        privatekey => PRIVKEY,
        remoteip   => '192.168.0.1',
        challenge  => '..challenge..',
        response   => '..response..'
      },
      check_url => 'http://www.google.com/recaptcha/api/verify',
      expect    => { is_valid => 1 },
    },
    {
      name => 'Simple incorrect',
      args =>
       [ PRIVKEY, '192.168.0.1', '..challenge..', '..response..' ],
      response   => "false\nincorrect-captcha-sol\n",
      check_args => {
        privatekey => PRIVKEY,
        remoteip   => '192.168.0.1',
        challenge  => '..challenge..',
        response   => '..response..'
      },
      check_url => 'http://www.google.com/recaptcha/api/verify',
      expect    => { is_valid => 0, error => 'incorrect-captcha-sol' },
    },
  );
  plan tests => 6 * @schedule;
}

package T::Captcha::reCAPTCHA;

our @ISA = qw(Captcha::reCAPTCHA);
use Captcha::reCAPTCHA;

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

package main;

for my $test ( @schedule ) {
  my $name = $test->{name};

  ok my $captcha = T::Captcha::reCAPTCHA->new(), "$name: Created OK";

  isa_ok $captcha, 'Captcha::reCAPTCHA';

  $captcha->set_response( $test->{response} );

  ok my $resp = $captcha->check_answer( @{ $test->{args} } ), "$name: got response";

  is $captcha->get_url,         $test->{check_url},  "$name: URL OK";

  is_deeply $captcha->get_args, $test->{check_args}, "$name: args OK";

  unless ( is_deeply $resp, $test->{expect}, "$name: result OK" ) {
    diag( Data::Dumper->Dump( [ $test->{expect} ], ['$expected'] ) );
    diag( Data::Dumper->Dump( [$resp], ['$got'] ) );
  }
}
