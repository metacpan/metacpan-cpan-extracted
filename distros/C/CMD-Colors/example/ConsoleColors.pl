#!/usr/bin/perl 

use strict;
use CMD::Colors;

## Example Usage
Cprint('hello, This is RED text', 'red');            
Cprint("\nhello, This is RED text with WHITE background", 'red', 'white');            
Cprint("\nhello, This is RED (Bold) text", 'red', undef, 'bold');  
Cprint("\n");
exit;

## Demo ##
foreach my $color (keys %{$COLOR_CODES{'foreground'}}) {                                                                 
    Cprint("This is $color text", $color);                                                                                  
    print "\n";                                                                                                             
    foreach my $bgcolor(keys %{$COLOR_CODES{'background'}}) {                                                               
        Cprint("This is $color text with $bgcolor background", $color, $bgcolor);               
	print "\n";                                                                             
    }                     
}
