#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 3;

BEGIN { use_ok 'App::soapcli' };

my $app = App::soapcli->new( dump_xml_request => 1, extra_argv => [
    'examples/mt-sms-service-ws-example-wappush.json', 'examples/mt-sms-service-ws.wsdl'
] );
is ref $app, 'App::soapcli', '$app isa App::soapcli';

my $buf;
{
    open my $fh, '>', \$buf or die $!;
    local *STDOUT = *$fh;
    $app->run;
}
is $buf, << 'END', 'XML request';
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Header>
    <mt:Security xmlns:mt="http://ws.orange.pl/mt-sms-service-ws">
      <mt:username>LOGIN</mt:username>
      <mt:password>PASS</mt:password>
    </mt:Security>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
    <mt:SubmitBinaryMessage xmlns:mes="http://ws.orange.pl/mt-sms-service-ws/message" xmlns:mt="http://ws.orange.pl/mt-sms-service-ws">
      <mt:sms>
        <mes:content>6E070605040B8423F0000601AE03056A0045C60E036D6574616370616E008803706F642F646973747269627574696F6E2F4170702D736F6170636C692F7363726970742F736F6170636C692E706C000AC3072015050220253310C307201505052025330103736F6170636C69000101</mes:content>
        <mes:expiryDate>2014-01-01T12:00:00</mes:expiryDate>
        <mes:recipient>507998000</mes:recipient>
        <mes:originator>12345</mes:originator>
      </mt:sms>
    </mt:SubmitBinaryMessage>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
END
