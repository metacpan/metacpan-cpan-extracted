use C::Include qw/test.h -cache/;
use hiew;
use vars qw/$node $buffer/;
use strict;

# Make struct instance
$node = INC->make_struct('Node');

# Fill struct fields
$$node{name} = 'Albert Michauer';
$$node{addr}{zone} = 2;
$$node{addr}{net}  = 5049;
$$node{addr}{node} = 80;
$$node{flags}{passive}   = 1;
$$node{flags}{umlautnet} = 1;

# Pack struct to buffer
$buffer = $node->pack();

# Print buffer to STDOUT
hiew( $buffer );
