#!/usr/bin/perl -w

use strict;
use warnings;

BEGIN
{ 
   use Test::More tests => 14;
   use_ok('CAM::SOAPClient');
}

my $PORT = 9674;

SKIP:
{
   require IO::Socket;
   my $s = IO::Socket::INET->new(PeerAddr => "localhost:$PORT",
                                 Timeout  => 10);
   if (!$s)
   {
      skip(
         "The test server is not running.  Run via:  './t/soap.pl $PORT &'\n" .
         "(the server runs for about ten minutes before turning itself off)\n" .
         "(Also note that the server require CAM::SOAPApp to be installed...)\n",
         
         # Hack: get the number of tests we expect, skip all but one
         # This hack relies on the soliton nature of Test::Builder
         Test::Builder->new()->expected_tests() -
         Test::Builder->new()->current_test()
      );
   }

   close $s;

   my $uri   = 'http://localhost/Example';
   my $proxy = "http://localhost:$PORT/soaptest/soap.pl";
   my $ssn = '111-11-1111';
   
   is_deeply([getPhoneNumber_SOAPLite($ssn, $uri, $proxy)], ['212-555-1212'], 'SOAP::Lite');
   is_deeply([getPhoneNumber_CAM_SOAP($ssn, $uri, $proxy)], ['212-555-1212'], 'CAM::SOAPClient');

   my $c;
   my @result;

   $c = CAM::SOAPClient->new($uri, $proxy);
   @result = $c->call('fail');
   ok($c->hadFault(), 'fault');
   is_deeply(\@result, [], 'fault');
   isnt($c->getLastFaultCode(), '(none)', 'fault, faultcode');
   isnt($c->getLastFaultString(), '(none)', 'fault, faultstring');
   my $fault = $c->getLastFault();
   isnt($fault, undef, 'getLastFault');
   isnt($fault->faultcode, undef, 'getLastFault');
   isnt($fault->faultstring, undef, 'getLastFault');

   $c = CAM::SOAPClient->new($uri, $proxy);
   @result = $c->call('abort');
   ok($c->hadFault(), 'server failure');
   is_deeply(\@result, [], 'server failure');
   is($c->getLastFaultCode(), 'Client', 'server failure, faultcode');
   isnt($c->getLastFaultString(), '(none)', 'server failure, faultstring');
}


sub getPhoneNumber_CAM_SOAP
{
   my ($ssn, $uri, $proxy) = @_;
   my $c = CAM::SOAPClient->new(timeout => 15, $uri, $proxy);
   my @result = $c->call('getEmployeeData', 'phone', ssn => $ssn);
   die 'Fault' if ($c->hadFault());
   return @result;
}

sub getPhoneNumber_SOAPLite
{
   my ($ssn, $uri, $proxy) = @_;
   # The SOAP::Lite API changed in v0.65-beta7
   my $soap = SOAP::Lite->can('ns') ? SOAP::Lite->ns($uri) : SOAP::Lite->uri($uri);
   my $som = $soap 
       -> proxy($proxy)
       -> call('getEmployeeData', SOAP::Data->name(ssn => $ssn));
   if (ref $som)
   {
      return $som->valueof('/Envelope/Body/[1]/phone');
   }
   else
   {
      return;
   }
}
