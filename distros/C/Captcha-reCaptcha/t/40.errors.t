use strict;
use warnings;
use Test::More;
use Captcha::reCAPTCHA;

use constant PUBKEY  => '6LdAAAkAwAAAFJj6ACG3Wlix_GuQJMNGjMQnw5UY';
use constant PRIVKEY => '6LdAAAkAwAAAix_GF6AMQnw5UCG3JjWluQJMNGjY';

my @schedule;

BEGIN {
  @schedule = (
    {
      name  => 'new: Bad args',
      class => 'T::Captcha::reCAPTCHA',
      try   => sub {
        my $c = Captcha::reCAPTCHA->new( PUBKEY );
      },
      expect => qr/reference to a hash/
    },
    {
      name  => 'get_html: No args',
      class => 'T::Captcha::reCAPTCHA',
      try   => sub {
        my $c = shift;
        $c->get_html();
      },
      expect => qr/To use reCAPTCHA you must get an API key from/
    },
    {
      name  => 'get_html: No key',
      class => 'T::Captcha::reCAPTCHA',
      try   => sub {
        my $c = shift;
        $c->get_html( '' );
      },
      expect => qr/To use reCAPTCHA you must get an API key from/
    },
    {
      name  => 'check_answer: No args',
      class => 'T::Captcha::reCAPTCHA',
      try   => sub {
        my $c = shift;
        $c->check_answer();
      },
      expect => qr/To use reCAPTCHA you must get an API key from/
    },
    {
      name  => 'check_answer: no response',
      class => 'T::Captcha::reCAPTCHA',
      try   => sub {
        my $c = shift;
        $c->check_answer( PRIVKEY, '' );
      },
      expect => qr/you must pass the remote ip/
    },
  );

  plan tests => 3 * @schedule;
}

package T::Captcha::reCAPTCHA;

our @ISA = qw(Captcha::reCAPTCHA);
use Captcha::reCAPTCHA;

sub _post_request {
  my $self = shift;
  my $url  = shift;
  my $args = shift;

  # Just keep the args
  $self->{t_url}  = $url;
  $self->{t_args} = $args;

  return HTTP::Response->new( 200, 'OK',
    [ 'Content-type:' => 'text/plain' ], "true\n" );
}

sub get_url  { shift->{t_url} }
sub get_args { shift->{t_args} }

package main;

for my $test ( @schedule ) {
  my $name  = $test->{name};
  my $class = $test->{class};
  ok my $captcha = $class->new, "$name: create OK";
  isa_ok $captcha, $class;
  eval { $test->{try}->( $captcha ); };
  if ( my $expect = $test->{expect} ) {
    like $@, $expect, "$name: error OK";
  }
  else {
    note "error is " . $@;
    ok !$@, "$name: no error OK";
  }
}
