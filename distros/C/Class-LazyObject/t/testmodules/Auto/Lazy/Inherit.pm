package Auto::Lazy::Inherit;
#Inherit from Auto::Lazy

use strict;
use warnings;
use Auto::Lazy;

use vars '@ISA';
@ISA = qw(Auto::Lazy);

1;