#!/usr/bin/env perl

use 5.010;
use warnings;
use strict;

use Authen::U2F;
use JSON;

use constant APPID   => 'https://example.com';
use constant VERSION => 'U2F_V2';

say "CHALLENGE:";

my $challenge = Authen::U2F->challenge;
say encode_json({
  challenge => $challenge,
  appId     => APPID,
  version   => VERSION,
});

say "";
say "ENTER RESPONSE:";
chomp (my $in = <STDIN>);

my $reg_response = decode_json($in);

my ($handle, $key) = Authen::U2F->registration_verify(
  challenge         => $challenge,
  app_id            => APPID,
  origin            => APPID,
  registration_data => $reg_response->{registrationData},
  client_data       => $reg_response->{clientData},
);

say "";
say "HANDLE: $handle";
say "KEY: $key";
