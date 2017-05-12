package Simple::Lazy::Inherit;
#Inherit from Simple::Lazy

use strict;
use warnings;
use Simple::Lazy;

use vars '@ISA';
@ISA = qw(Simple::Lazy);

1;