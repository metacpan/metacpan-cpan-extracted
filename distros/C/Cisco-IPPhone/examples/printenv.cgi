#!/usr/bin/perl
 
# Mark Palmer markpalmer@us.ibm.com

use Cisco::IPPhone;

$mytext = new Cisco::IPPhone;

my $text = '';
my $temp = '';

foreach $var (sort(keys(%ENV))) {
    $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    $temp = "${var}=\"${val}\"\n";
    $text .= substr($temp,0,50);
    $text .= "\n";
}

$text =~ s/</&lt;/g;
$text =~ s/>/&gt;/g;

$mytext->Text ({ Title => "IPPhone Environment Variables",
                  Prompt => "",
                  Text => "$text" });

$mytext->AddSoftKeyItem( { Name => "Update", URL => "SoftKey:Update", 
                           Position => "1" });
$mytext->AddSoftKeyItem( { Name => "Exit", URL => "SoftKey:Exit", 
                           Position => "2" });

print $mytext->Content;

