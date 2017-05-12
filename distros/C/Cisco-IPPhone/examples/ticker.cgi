#!/usr/bin/perl

# Mark Palmer markpalmer@us.ibm.com

use Cisco::IPPhone;
use LWP;
use CGI;

$ua = LWP::UserAgent->new;
$mytext = new Cisco::IPPhone;
$error = new Cisco::IPPhone;
$query = new CGI;

my $host = 'finance.yahoo.com';
my $url = 'q?s';
$ticker = $query->param('ticker') || "CSCO";

$completeurl = "http:\/\/$host\/$url=${ticker}&d=d";

my $request = HTTP::Request->new(GET => $completeurl);
my $response = $ua->request($request);

if ($response->is_success) {
 # It was successful, so parse the form
 $lines = $response->content;

if ($lines =~ />Last Trade<br>(.+) .+?;\s+<b>(.+?)<\/b><\/font>.*Change<br>(.+?)<\/font>.*Prev Cls<br>(.+?)<\/font>.*Volume<br><i>(.+?)<\/i>/ ) {
   $date = $1;
   $last = $2;
   $change = $3;
   $close = $4;
   $volume = $5;
 }

$mytext->Text( { Title => "Stock Quote - Yahoo! Finance", Prompt => "Select", 
          Text => "Symbol: $ticker\nDate: $date\nLast: $last\nChange: $change\nClose: $close\nVolume: $volume\n" });
$mytext->AddSoftKeyItem( { Name => "Update", URL => "SoftKey:Update", 
                           Position => "1" });
$mytext->AddSoftKeyItem( { Name => "Exit", URL => "SoftKey:Exit", 
                           Position => "2" });
print $mytext->Content;
} else {
  $mytext->Text( { Title => "Stock Quote - Yahoo! Finance", Prompt => "Quote", 
                           Text => "Unable to access $completeurl" });
  $mytext->AddSoftKeyItem( { Name => "Update", URL => "SoftKey:Update", 
                           Position => "1" });
  $mytext->AddSoftKeyItem( { Name => "Exit", URL => "SoftKey:Exit", 
                           Position => "2" });
  print $mytext->Content;
}

__END__
