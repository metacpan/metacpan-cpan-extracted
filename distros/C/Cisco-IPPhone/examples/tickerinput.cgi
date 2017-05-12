#!/usr/bin/perl

use Cisco::IPPhone;

$myinput = new Cisco::IPPhone;
$myinputitem = new Cisco::IPPhone;

# Create Menu Object
$myinput->Input( { Title => "Stock Quote - Yahoo! Finance", 
                   Prompt => "Enter Stock Ticker",
                   URL => "http://$ENV{'SERVER_ADDR'}/cgi-bin/ticker.cgi" });

# Add Input Items to Input Object
$myinput->AddInputItem({ DisplayName => "Enter Ticker", 
                         QueryStringParam => "ticker",
                         DefaultValue => "",
                         InputFlags => "A"} );

# Print the Input Object to the Phone
print $myinput->Content;

__END__
