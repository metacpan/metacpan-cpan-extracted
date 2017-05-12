#!/usr/bin/perl

use Cisco::IPPhone;

$mytext = new Cisco::IPPhone;

$mytext->Text({ Title => "My Title",  
                 Prompt => "My Prompt", 
                 Text => "My Text" });
print $mytext->Content;

__END__
