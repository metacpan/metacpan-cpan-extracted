#!/usr/bin/perl

use Cisco::IPPhone;

$myiconmenu = new Cisco::IPPhone;

$data = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

# Create Icon Menu
$myiconmenu->IconMenu( { Title => "Icon Menu", 
                   Prompt => "Select an icon" });

$myiconmenu->AddMenuItem({  IconIndex => "1", 
                            Name => "Menu Item 1", 
     URL => "http://192.168.250.31/cgi-bin/text.cgi" });
$myiconmenu->AddMenuItem({  IconIndex => "1", 
                            Name => "Menu Item 2", 
     URL => "http://192.168.250.31/cgi-bin/text.cgi" });
$myiconmenu->AddMenuItem({  IconIndex => "1", 
                            Name => "Menu Item 3", 
     URL => "http://192.168.250.31/cgi-bin/text.cgi" });

# Index is the numeric index of the icon to be displayed
# Up to 10 instances of iconitem can be displayed
$myiconmenu->AddIconItem ({ Index => "1", 
                            Width => "10",
                            Height => "10", 
                            Depth => "2", 
                            Data => "$data" });

print $myiconmenu->Content;
