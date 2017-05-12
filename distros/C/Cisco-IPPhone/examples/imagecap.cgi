#!/usr/bin/perl
# Mark Palmer - markpalmer@us.ibm.com
# Captures an IP Phone screenshot and saves it to a file (image.cip)

use Cisco::IPPhone;
use LWP;

$ua = LWP::UserAgent->new;
$mytext = new Cisco::IPPhone;

$IPPHONE = "192.168.1.100";
$USER = 'myusername';
$PASSWORD = 'mypassword';
$URL = "http://${IPPHONE}/CGI/Screenshot";
my $request = HTTP::Request->new(GET => $URL);
$request->authorization_basic($USER, $PASSWORD);
my $response = $ua->request($request);

if ($response->is_success) {
  $lines = $response->content;
} else {
  ## Handle Redirect and errors
  if ($response->is_redirect) {
     my $newrequest = HTTP::Request->new(GET => $response->header('Location'));
     $newrequest->authorization_basic($USER, $PASSWORD);
     my $newresponse = $ua->request($newrequest);
     $lines = $newresponse->content;
  } else {
     print $response->status_line;
  }
}

# Check results for errors
if ($lines =~ /CiscoIPPhoneError Number="(\d+)"/) {
     $errno = $1;
     if ($errno == 4) {
         print "Authentication error\n";
     } elsif ($errno == 3) {
         print "Internal file error\n"; 
     } elsif ($errno == 2) {
         print "Error framing CiscoIPPhoneResponse object\n"; 
     } elsif ($errno == 1) {
         print "Error parsing CiscoIPPhoneExecute object\n"; 
     } else {
         print "Unknown Error\n";
         print $result;
     }
     exit (1);
}

# Write Image Object to file
open (IMAGE, ">image.cip") || die "Unable to open image.cip";
print IMAGE $lines;
close IMAGE;

__END__
