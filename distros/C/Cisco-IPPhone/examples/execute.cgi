#!/usr/bin/perl
# Mark Palmer - markpalmer@us.ibm.com
# Must use authentication when POSTING an object to a Cisco IPPhone.
# User should be a user in the global directory associated with the phone
# Can use this script to send messages to IPPhones

use Cisco::IPPhone;
use LWP::UserAgent;
use URI;
$ua = LWP::UserAgent->new;
$myexecute = new Cisco::IPPhone;

$SERVER = "192.168.250.17";
$IPPHONE = "192.168.250.7";
$USER = 'myuser';
$PASSWORD = 'mypassword';
$POSTURL = "http://${IPPHONE}/CGI/Execute";

# URL that phone will fetch
$URL1 = "http://$SERVER/cgi-bin/nfl.cgi";

# Build Execute Object with up to 3 Execute Items
$myexecute->Execute;
$myexecute->AddExecuteItem( { ExecuteItem => "$URL1" });
my $xml = $myexecute->Content_Noheader;

# Translate non-alpha chars into hex
$xml = URI::Escape::uri_escape("$xml"); 

my $request = new HTTP::Request POST => "$POSTURL";
$request->authorization_basic($USER, $PASSWORD);
$request->content("XML=$xml"); # Phone requires parameter named XML
my $response = $ua->request($request); # Send the POST

if ($response->is_success) {
  $result = $response->content;
  if ($result =~ /CiscoIPPhoneError Number="(\d+)"/) {
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
  }
} else {
  print "Failure: Unable to POST XML object to phone $IPPHONE\n";
  print $response->status_line;
}

__END__

