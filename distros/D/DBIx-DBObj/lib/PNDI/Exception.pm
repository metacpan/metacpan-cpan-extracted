package PNDI::Exception;

# Copyright (C) 2003 Matt Knopp <mhat@cpan.org>
# This library is free software released under the GNU Lesser General Public
# License, Version 2.1.  Please read the important licensing and disclaimer
# information included in the LICENSE file included with this distribution.

use strict;
use Error;
our @ISA = qw (Error::Simple);

package PNDI::NameCollisionException; 
use strict; 
use Error;
our @ISA = qw (PNDI::Exception);

package PNDI::NoSuchNameException; 
use strict; 
use Error;
our @ISA = qw (PNDI::Exception);

##
1;
