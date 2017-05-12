#!/usr/bin/env perl

use 5.010;
use warnings;
use strict;

use Authen::U2F;
use JSON;

use constant APPID   => 'https://example.com';
use constant VERSION => 'U2F_V2';

my ($handle, $key) = @ARGV;
unless ($handle && $key) {
  die "usage: $0 <handle> <key>\n";
}

say "CHALLENGE:";

my $challenge = Authen::U2F->challenge;
say encode_json({
  challenge => $challenge,
  keyHandle => $handle,
  appId     => APPID,
  version   => VERSION,
});

say "";
say "ENTER RESPONSE:";
chomp (my $in = <STDIN>);

my $sign_response = decode_json($in);

Authen::U2F->signature_verify(
  challenge      => $challenge,
  app_id         => APPID,
  origin         => APPID,
  key_handle     => $sign_response->{keyHandle},
  key            => $key,
  signature_data => $sign_response->{signatureData},
  client_data    => $sign_response->{clientData},
);

say "";
say "SUCCESS";
