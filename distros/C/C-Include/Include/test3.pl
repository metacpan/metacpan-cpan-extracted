use C::Include qw/test.h -cache/;
use hiew;
use vars qw/$node $data/;
use strict;

print "Example of usage unpack/pack\n";

$node = INC->make_struct('Node');   # Make struct instance
$node->unpack( $data );             # Unpack buffer to struct
$data=$node->pack();                # Pack struct to buffer
hiew( $data );                      # Print buffer to STDOUT


BEGIN{$data=unpack 'u',<<'END';}
M`@"Y$U`````````````````````1````````````````````````````````
M``````````````````!!;&)E<G0@36EC:&%U97(`````````````````````
END
