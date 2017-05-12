#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
#use Carp; $SIG{__WARN__} = $SIG{__DIE__} = \&Carp::confess;

BEGIN
{ 
   use Test::More tests => 23;
   use_ok('CAM::SOAPClient');
}

package FakeSOAP;

my $SOM;
sub call
{
   # Return a SOAP::SOM object
   return $SOM ||= SOAP::Deserializer->deserialize(<<'EOF');
<Envelope xmlns:ss="http://xml.apache.org/xml-soap"
          xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
          xmlns:enc="http://schemas.xmlsoap.org/soap/encoding/"
          xmlns:xsd="http://www.w3.org/1999/XMLSchema">
  <Body>
    <methodResponse>
      <userID xsi:type="xsd:string">12</userID>
      <data enc:arrayType="ss:SOAPStruct[]" xsi:type="enc:Array">
        <item xsi:type="ss:SOAPStruct"><id xsi:type="xsd:int">4</id></item>
        <item xsi:type="ss:SOAPStruct"><id xsi:type="xsd:int">6</id></item>
        <item xsi:type="ss:SOAPStruct"><id xsi:type="xsd:int">7</id></item>
        <item xsi:type="ss:SOAPStruct"><id xsi:type="xsd:int">10</id></item>
        <item xsi:type="ss:SOAPStruct"><id xsi:type="xsd:int">20</id></item>
      </data>
    </methodResponse>
  </Body>
</Envelope>
EOF
}
sub ns  # for SOAP::Lite v0.66 and later
{
   return shift;
}
sub uri # for SOAP::Lite v0.60 and ealier
{
   return shift;
}
sub proxy
{
   return shift;
}

package main;

my $obj = CAM::SOAPClient->new('http://www.foo.com/No/Such/Class/', 'foo');
ok($obj, 'Constructor');

# HACK! ruin the SOAP object for the sake of the test
$obj->{soap} = bless {}, 'FakeSOAP';

my $all = {data => [{id=>4},{id=>6},{id=>7},{id=>10},{id=>20}], userID => 12};
my @tests = (
   { request => undef,                       scalar => $all,          array => [$all]        },
   { request => 'data/item/id',              scalar => 4,             array => [4]           },
   { request => ['data/item/id'],            scalar => 4,             array => [4]           },
   { request => '@data/item/id',             scalar => 4,             array => [4,6,7,10,20] },
   { request => ['@data/item/id'],           scalar => 4,             array => [4,6,7,10,20] },
   { request => ['data/item/id','userID'],   scalar => 4,             array => [4,12]        },
   { request => ['@data/item/id','userID'],  scalar => [4,6,7,10,20], array => [[4,6,7,10,20],12] },
   { request => ['userID', '@data/item/id'], scalar => 12,            array => [12,[4,6,7,10,20]] },
);
for my $test (@tests)
{
   my $paths = $test->{request};
   my $spaths = Data::Dumper->new([$paths])->Terse(1)->Indent(0)->Dump();
   my $response = $obj->call('null', $paths);
   is_deeply($response, $test->{scalar}, "call scalar $spaths");
   $response = [$obj->call('null', $paths)];
   is_deeply($response, $test->{array},  "call array  $spaths");

   #print Dumper($obj->getLastSOM());
}

$obj = CAM::SOAPClient->new(wsdl => 'file:t/test.wsdl');
is($obj->{proxies}->{test}, 'http://www.foo.com/test.cgi', 'WSDL test - endpoint');
is($obj->{uris}->{test}, 'http://foo.com/test', 'WSDL test - uri');

is(CAM::SOAPClient->new(), undef, 'no uri specified');
isnt(CAM::SOAPClient->new('http://localhost'), undef, 'no proxy specified');
is_deeply({CAM::SOAPClient->new('http://localhost', undef, 'user', 'pass')->loginParams()}, {username => 'user', password => 'pass'}, 'username and password');
