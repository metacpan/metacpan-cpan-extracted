#!/usr/bin/perl

# Mark Palmer markpalmer@us.ibm.com

use Cisco::IPPhone;
use LWP;
use CGI;

$ua = LWP::UserAgent->new;
$mytext = new Cisco::IPPhone;
$error = new Cisco::IPPhone;
$query = new CGI;

my $host = "rainmaker.wunderground.com";
my $url = "/cgi-bin/findweather/getForecast";
$zip = $query->param('zip');
$completeurl = "http:\/\/$host\/$url?zip=$zip";

my $request = HTTP::Request->new(GET => $completeurl);
my $response = $ua->request($request);

if ($response->is_success) {
 # It was successful, so parse the form
 $lines = $response->content;
 $city = $1 if $lines =~ /<title>Weather Underground:(.*) Forecast?</;
if ($lines =~ /Temperature.*\n.*?(\d+).*\n.*Humidity.*\n.*?(\d+).*\n.*Dewpoint.*\n.*?(\d+).*\n.*Wind/) {
 $tempf = $1;
 $tempf .= " F";
 $humidity = $2;
 $humidity .= "%";
 $dewpoint = $3; 
 $dewpoint .= " F";
}
if ($lines =~ /Sunrise.*?(\d.+AM).*\n.*Sunset.*?(\d.+PM)/) {
  $sunrise = $1;
  $sunset = $2;
}
$mytext->Text( { Title => "Current Conditions", Prompt => "Select", 
          Text => "$city\nTemp: $tempf \nHumidity: $humidity\nDewpoint: $dewpoint\nSunrise/set: ${sunrise} ${sunset}" });
$mytext->AddSoftKeyItem( { Name => "Update", URL => "SoftKey:Update", 
                           Position => "1" });
$mytext->AddSoftKeyItem( { Name => "Exit", URL => "SoftKey:Exit", 
                           Position => "2" });
print $mytext->Content;
} else {
  $mytext->Text( { Title => "My Title", Prompt => "My Prompt", 
                           Text => "Unable to access $completeurl" });
  $mytext->AddSoftKeyItem( { Name => "Update", URL => "SoftKey:Update", 
                           Position => "1" });
  $mytext->AddSoftKeyItem( { Name => "Exit", URL => "SoftKey:Exit", 
                           Position => "2" });
  print $mytext->Content;
}

__END__
