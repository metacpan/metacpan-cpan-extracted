#!/usr/bin/perl

use Cisco::IPPhone;

$mygraphicmenu = new Cisco::IPPhone;

$data = "FFFFFFFFFFFFFFFFFFFF";

# Create Menu Object
$mygraphicmenu->GraphicMenu( { Title => "My Image", 
                   Prompt => "View the image",
                   LocationX => "-1", LocationY => "-1", 
                   Width => "10",
                   Height => "10", 
                   Depth => "2", 
                   Data => "$data" });

$mygraphicmenu->AddMenuItem({ Name => "Image IBM Logo", 
         URL => "http://192.168.25.1/cgi-bin/idle.cgi" });
$mygraphicmenu->AddSoftKeyItem( { Name => "Update", URL => "SoftKey:Update", 
                           Position => "1" });
$mygraphicmenu->AddSoftKeyItem( { Name => "Select", URL => "SoftKey:Select", 
                           Position => "2" });
$mygraphicmenu->AddSoftKeyItem( { Name => "Exit", URL => "SoftKey:Exit", 
                           Position => "3" });

print $mygraphicmenu->Content;
