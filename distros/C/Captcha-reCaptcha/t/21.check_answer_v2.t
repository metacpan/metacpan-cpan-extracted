use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Test::TCaptcha;
use Data::Dumper;

# Looks real
use constant PRIVKEY => '6LdAAAkAwAAAix_GF6AMQnw5UCG3JjWluQJMNGjY';

note "Create object";
ok my $captcha = Test::TCaptcha->new(), "Captcha::reCAPTCHA: Created OK";

note "croaks on no response";
eval { $captcha->check_answer_v2() };
ok $@ =~ /To use reCAPTCHA you must get an API key from/, "Breaks on no arguments";

eval { $captcha->check_answer_v2( PRIVKEY ) };
ok $@ =~ /To check answer, the user response token must be provided/, "Breaks on no response arg";

$captcha->set_response("\"success\": false");
my $result = eval { $captcha->check_answer_v2( PRIVKEY, 'fakeresponse' ) };
ok $result->{is_valid} eq '0', "Google Say's the response is invalid";


my @schedule;

BEGIN {

  # Looks real. Isn't.
  @schedule = (
    {
      name => 'Simple correct',
      args =>
       [ PRIVKEY, 'abcdefghijklmnopqrstuv', '192.168.0.1' ],
      response   => '"success": true,',
      check_args => {
        privatekey => PRIVKEY,
        remoteip   => '192.168.0.1',
        response   => '..response..'
      },
      check_url => 'https://www.google.com/recaptcha/api/siteverify',
      expect    => { is_valid => 1 },
    },
    {
      name => 'Simple incorrect',
      args =>
       [ PRIVKEY, 'response', '192.168.0.1' ],
      response   => "incorrect-captcha-sol",
      check_args => {
        privatekey => PRIVKEY,
        remoteip   => '192.168.0.1',
        response   => '..response..'
      },
      check_url => 'https://www.google.com/recaptcha/api/siteverify',
      expect    => { is_valid => 0, error => 'incorrect-captcha-sol' },
    },
  );
  plan tests => 6 * @schedule;
}


for my $test ( @schedule ) {
  my $name = $test->{name};

  ok my $captcha = Test::TCaptcha->new(), "$name: Created OK";

  isa_ok $captcha, 'Captcha::reCAPTCHA';

  $captcha->set_response( $test->{response} );

  ok my $resp = $captcha->check_answer_v2( @{ $test->{args} } ), "$name: got response";

  unless ( is_deeply $resp, $test->{expect}, "$name: result OK" ) {
    diag( Data::Dumper->Dump( [ $test->{expect} ], ['$expected'] ) );
    diag( Data::Dumper->Dump( [$resp], ['$got'] ) );
  }
}


done_testing();
