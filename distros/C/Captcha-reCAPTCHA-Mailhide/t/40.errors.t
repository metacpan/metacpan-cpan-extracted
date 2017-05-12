use strict;
use warnings;
use Test::More;
use Captcha::reCAPTCHA::Mailhide;

use constant MH_PUBKEY  => 'UcV0oq5XNVM01AyYmMNRqvRA==';
use constant MH_PRIVKEY => 'E542D5DB870FF2D2B9D01070FF04F0C8';

my @schedule;

BEGIN {
  @schedule = (
    {
      name  => 'mailhide_html: No args',
      class => 'Captcha::reCAPTCHA::Mailhide',
      try   => sub {
        my $c = shift;
        $c->mailhide_html();
      },
      expect => qr/you have to sign up for a public and private key/
    },
    {
      name  => 'mailhide_html: One arg',
      class => 'Captcha::reCAPTCHA::Mailhide',
      try   => sub {
        my $c = shift;
        $c->mailhide_html( MH_PUBKEY );
      },
      expect => qr/you have to sign up for a public and private key/
    },
    {
      name  => 'mailhide_html: No email',
      class => 'Captcha::reCAPTCHA::Mailhide',
      try   => sub {
        my $c = shift;
        $c->mailhide_html( MH_PUBKEY, MH_PRIVKEY );
      },
      expect => qr/You must supply an email address/
    },
  );

  plan tests => 3 * @schedule + 1;
}

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
    ok !$@, "$name: no error OK";
  }
}

eval { Captcha::reCAPTCHA::Mailhide->new( 'An argument' ) };
like $@, qr{no\s+parameters}, 'new';
