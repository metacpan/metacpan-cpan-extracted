package CMD::Colors;

=head1 NAME

CMD::Colors - Generate Colorfull text on commandline

=head1 SYNOPSIS

    use CMD::Colors;

    ##### Example Usage ##### 
    
    ## Prints text with 'RED' color & default background
    Cprint('hello, This is RED text', 'red');                   

    ## Prints text with 'RED' color & 'white' background 
    Cprint('hello, This is RED text', 'red', 'white');    

    ## Prints text with 'RED' color & 'default' background & BOLD text
    Cprint('hello, This is RED text', 'red', 'default', 'bold'); 

    ## Prints text with 'RED' color & 'default' background & 'half_bright' text
    Cprint('hello, This is RED text', 'red', undef, 'half_bright');


    ##### Show all available 'foreground' & 'background' colors - DEMO #####
    foreach my $color (keys %{$COLOR_CODES{'foreground'}}) {
     Cprint("This is $color text", $color);
     print "\n";
     foreach my $bgcolor(keys %{$COLOR_CODES{'background'}}) {
        Cprint("This is $color text with $bgcolor background", $color, $bgcolor);
        print "\n";
      }
     }


=head1 DESCRIPTION

This module provides functions for generating colorfull text on commandline with perl
programs.  It can be used to make PERL "CMD" programs more interesting.

*Cprint() function be used for all "print" calls.

Syntax -
Cprint("TEXT TO BE Printed", "ForegroundCOLORName", "BackgroundColorName", "TEXT Property");


Supported Colors ::
Foreground   - black, red, green, brown, blue, magenta, cyan, white
Background   - black, red, green, brown, blue, magenta, cyan, white


Supported Properties ::
        'bold'                 ## Set bold                                                                       
        'half_bright'          ## Set  half-bright (simulated with color on a color display)                     
        'underscore'           ## Set underscore (simulated with color on a color  display)                      
                               ## (the  colors  used  to  simulate dim or underline are set                      
        'blink'                ## Set blink                                                                      
        'reverse_video'        ## Set reverse video                                                              
        'reset_mapping'        ## Reset selected mapping, display control flag, and  toggle                      
                               ## meta flag (ECMA-48 says "primary font").                                       
        'null_mapping'         ## Select null mapping, set display control flag, reset                           
                               ## toggle meta flag (ECMA-48 says "first alternate font").                        
        'null-mapping '        ## Select null mapping, set display control flag, set toggle                      
                               ## meta  flag  (ECMA-48  says "second alternate font").  The                      
                               ## toggle meta flag causes the high bit of a byte to be                           
                               ## toggled before the mapping table translation is done.                          
        'nd_intensity'         ## Set normal intensity (ECMA-48 says "doubly underlined")                        
        'n_intensity'          ## Set normal intensity                                                           
        'underline_off'        ## Set underline off                                                              
        'blink_off'            ## Set blink off                                                                  
        'reverse_video_off'    ## Set reverse video off                                                          
        'default'              ## Set default        


** If color/property specified is not supported, default color/property would be used for printing text **

Techinal Details:: 
This module uses "Linux" console escape and control sequences for generating colorfull text 
with background colors, It utilizes the "ECMA-48 SGR" sequenceof the SHELL to generate colored text.


=head1 AUTHOR
       Utsav Handa <handautsav@hotmail.com>
         
         
=head1 COPYRIGHT
       (c) 2009 Utsav Handa. 

        
       All rights reserved.  This program is free software; you can redistribute it 
       and/or modify it under the same terms as Perl itself.

           
          
=cut


use strict;
use Exporter;

our $VERSION   = '0.1';
our @ISA       = qw/ Exporter /;
our @EXPORT    = qw(Cprint %COLOR_CODES);



#########################
#### Color Code Hash ####
#########################
our %COLOR_CODES = (
    'foreground' => {
	'black'                => 30,     ## Set black foreground
	'red'                  => 31,     ## Set red foreground
	'green'                => 32,     ## Set green foreground
	'brown'                => 33,     ## Set brown foreground
	'blue'                 => 34,     ## Set blue foreground
	'magenta'              => 35,     ## Set magenta foreground
	'cyan'                 => 36,     ## Set cyan foreground
	'white'                => 37,     ## Set white foreground
	'default'              => 49,     ## Set default background color
    },
    'background' => {
	'black'                => 40,     ## Set black background
	'red'                  => 41,     ## Set red background
	'green'                => 42,     ## Set green background
	'brown'                => 43,     ## Set brown background
	'blue'                 => 44,     ## Set blue background
	'magenta'              => 45,     ## Set magenta background
	'cyan'                 => 46,     ## Set cyan background
	'white'                => 47,     ## Set white background
	'default'              => 49,     ## Set default background color
    },
    'other'      => {
	'bold'                 => ';1',    ## Set bold
	'half_bright'          => ';2',    ## Set  half-bright (simulated with color on a color display)
	'underscore'           => ';4',    ## Set underscore (simulated with color on a color  display)
	                                   ## (the  colors  used  to  simulate dim or underline are set
	'blink'                => ';5',    ## Set blink
	'reverse_video'        => ';7',    ## Set reverse video
	'reset_mapping'        => ';10',   ## Reset selected mapping, display control flag, and  toggle
	                                   ## meta flag (ECMA-48 says "primary font").
	'null_mapping'         => ';11',   ## Select null mapping, set display control flag, reset 
                                           ## toggle meta flag (ECMA-48 says "first alternate font").
	'null-mapping '        => ';12',   ## Select null mapping, set display control flag, set toggle
	                                   ## meta  flag  (ECMA-48  says "second alternate font").  The
	                                   ## toggle meta flag causes the high bit of a byte to be 
	                                   ## toggled before the mapping table translation is done.
	'nd_intensity'         => ';21',   ## Set normal intensity (ECMA-48 says "doubly underlined")
	'n_intensity'          => ';22',   ## Set normal intensity
	'underline_off'        => ';24',   ## Set underline off
	'blink_off'            => ';25',   ## Set blink off
	'reverse_video_off'    => ';27',   ## Set reverse video off	     
	'default'              => '',      ## Set default
    }

    );


sub Cprint {
    ## This sub-routine actually makes call to 'print' statemtn with ESC characters
    ## and prepares statemtn for printing specified text
    my ($text, $foreground_color, $background_color, $other_color, $garb) = @_;

    ## Default Variable(s)
    $foreground_color = 'default' if (!$foreground_color);
    $background_color = 'default' if (!$background_color);
    $other_color      = ( $other_color ? getCodeForColor($other_color, 'other') : '' );

    ## Building string to print
    my $string  = "\033[";
    $string    .= getCodeForColor($foreground_color, 'foreground').';'.getCodeForColor($background_color, 'background');
    $string    .= $other_color."m".$text."\033[0m";

    return print $string;
}


sub getCodeForColor {
    ## This sub-routine returns actualt ESC Code for property and color specified
    my ($color, $type, $garb) = @_;

    ## Default Type
    $type  = 'foreground' if (!$type);

    ## Sanitize Arguments
    $color = lc $color;
    $type  = lc $type;


    return ( $COLOR_CODES{$type}{$color} ? $COLOR_CODES{$type}{$color} : $COLOR_CODES{$type}{'default'} );
}





