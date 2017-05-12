#!/usr/bin/perl

use Cisco::IPPhone;

$myinput = new Cisco::IPPhone;
$myinputitem = new Cisco::IPPhone;

$SERVER = $ENV{'SERVER_ADDR'};

# Create Menu Object
$myinput->Input( { Title => "Weather Program", 
                   Prompt => "Enter Zip Code",
                   URL => "http://$SERVER/cgi-bin/weather.cgi" });

# Add Input Items to Input Object
$myinput->AddInputItem({ DisplayName => "Enter Zip", 
                         QueryStringParam => "zip",
                         DefaultValue => "",
                         InputFlags => "N"} );

# Print the Input Object to the Phone
print $myinput->Content;

__END__
