#!/usr/bin/perl

use Cisco::IPPhone;

$mydirectory = new Cisco::IPPhone;

# Create Menu Object
$mydirectory->Directory( { Title => "My Title", 
                           Prompt => "My Prompt" });

# Add Directory Entries to Directory Object
$mydirectory->AddDirectoryEntry({ Name => "Entry 1", 
                                  Telephone => "555-1212" });
$mydirectory->AddDirectoryEntry({ Name => "Entry 2", 
                                  Telephone => "555-1234" });
# Add SoftKeyItems
$mydirectory->AddSoftKeyItem({ Name => "Dial", URL => "SoftKey:Dial", 
                               Position => "1" });
$mydirectory->AddSoftKeyItem({Name => "EditDial", URL => "SoftKey:EditDial", 
                         Position => "2" });
$mydirectory->AddSoftKeyItem({ Name => "Cancel", URL => "SoftKey:Cancel", 
                          Position => "3" });

# Print the Menu Object to the Phone
print $mydirectory->Content;

__END__
