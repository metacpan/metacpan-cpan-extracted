#!/usr/bin/perl

use Cisco::IPPhone;
use LWP;

$ua = LWP::UserAgent->new;
$mytext = new Cisco::IPPhone;

my $host = "www.nfl.com";
my $url = "scores";
$completeurl = "http:\/\/$host\/$url";

my $request = HTTP::Request->new(GET => $completeurl);
my $response = $ua->request($request);

if ($response->is_success) {
 # It was successful, so parse the form

 $results = $response->content;

 @lines = split ('\n', $results);
$counter = 0;
$team = '';
$score = -1;
foreach $line (@lines) {
  $team = $1 if ($line =~ /\/teams\/news\/(\S+)"/);
  $score = $1 if ($line =~ /finalscore">(\d+)</);
  if ($line =~ /"columnrow".*>(.*)<\/t.>/) {
    $timeleft = $1;
    $timeleft =~ s/&nbsp//g;
  }
  if ($score >= 0) {
    $counter++;
    $text .= "$team : $score ";
    if ($counter % 2 == 0) {
      $text .= "$timeleft\n";
      $timeleft = '';
    }
    $team = '';
    $score = -1;
  }
}

$mytext->Text( { Title => "NFL Scores from nfl.com", Prompt => "Go Packers", 
          Text => "$text" });
print $mytext->Content({Refresh => "60"});

} else {
  $mytext->Text( { Title => "NFL Scores from nfl.com", Prompt => "Go Packers", 
                           Text => "Unable to access $completeurl" });
  print $mytext->Content;
}

__END__
