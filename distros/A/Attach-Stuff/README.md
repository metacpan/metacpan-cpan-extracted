You've got stuff, like a PCB board, that needs to be attached to other stuff, 
like a lasercut enclosure. How do you attach the stuff to the other stuff?  
This is a question we ask a lot when doing homebuilt Internet of Things 
projects.  Perl has the "Internet" half down pat. This module is an attempt to 
improve the "Things" part.

Lasercutters and other CNC machines often work with SVGs. Or more likely SVGs 
can be converted into something that are converted into G-code by whatever turd 
of a software package came with your CNC machine.  Whatever the case, you can 
probably start with an SVG and work your way from there.

Before you can get there, you need measurements of the board and the location 
of the screw holes.  If you're lucky, you can find full schematics for your 
board that will tell you the sizes exactly.  If not, you'll need to get out 
some callipers and possibly do some guesswork.

Protip: if you had to guess on some of the locations, etch a prototype into 
cardboard. Then you can lay the board over the cardboard and see if it matches 
up right.
