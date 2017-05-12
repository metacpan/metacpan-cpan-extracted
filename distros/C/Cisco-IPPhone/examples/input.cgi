#!/usr/bin/perl

use Cisco::IPPhone;

$myinput = new Cisco::IPPhone;

# Create Menu Object
$myinput->Input( { Title => "My Title", 
                   Prompt => "My Prompt",
                   URL => "My URL" });

# Add Input Items to Input Object
$myinput->AddInputItem({ DisplayName => "Display Name1", 
                         QueryStringParam => "QueryString1",
                         DefaultValue => "Default1",
                         InputFlags => "A"} );
$myinput->AddInputItem({ DisplayName => "Display Name2", 
                         QueryStringParam => "QueryString2:",
                         DefaultValue => "Default2",
                         InputFlags => "A"} );

$myinput->AddSoftKeyItem ({ Name => "Submit",
                            URL => "SoftKey:Submit",
                            Position => "1" });
$myinput->AddSoftKeyItem ({ Name => "&lt&lt",
                            URL => "SoftKey:&lt&lt",
                            Position => "2" });
$myinput->AddSoftKeyItem ({ Name => "Cancel",
                            URL => "SoftKey:Cancel",
                            Position => "3" });

# Print the Input Object to the Phone
print $myinput->Content;

__END__
