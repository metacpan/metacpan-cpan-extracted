#!/usr/bin/env perl

use warnings;
use strict;

use Authen::U2F;
use JSON;

use constant APPID   => 'https://example.com';
use constant VERSION => 'U2F_V2';

print "CHALLENGE:\n";

my $challenge = Authen::U2F->challenge;
print encode_json({
  challenge => $challenge,
  appId     => APPID,
  version   => VERSION,
}) . "\n";

exit;

print "\n";
print "ENTER RESPONSE:\n";
chomp (my $in = <STDIN>);

my $reg_response = decode_json($in);

my ($handle, $key) = Authen::U2F->registration_verify(
  challenge         => $challenge,
  app_id            => APPID,
  origin            => APPID,
  registration_data => $reg_response->{registrationData},
  client_data       => $reg_response->{clientData},
);

print "\n";
print "HANDLE: $handle\n";
print "KEY: $key\n";
