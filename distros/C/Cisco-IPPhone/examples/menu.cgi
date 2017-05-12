#!/usr/bin/perl

use Cisco::IPPhone;

$mymenu = new Cisco::IPPhone;

# Create Menu Object
$mymenu->Menu( { Title => "My Title", Prompt => "My Prompt", Text => "My Text" });

# Add Menu Item to Menu Object
$mymenu->AddMenuItem({ Name => "Item 1", URL => "http://www.mydomain1.com" });

# Add another menu item to Menu Object
$mymenu->AddMenuItem({ Name => "Item 2", URL => "http://www.mydomain2.com" });

# Add SoftKeyItems to Menu Object
$mymenu->AddSoftKeyItem({ Name => "Select", URL => "SoftKey:Select", 
                          Position => "1" });
$mymenu->AddSoftKeyItem({ Name => "Exit", URL => "SoftKey:Exit", 
                          Position => "2" });

# Print the Menu Object to the Phone
print $mymenu->Content;

__END__
