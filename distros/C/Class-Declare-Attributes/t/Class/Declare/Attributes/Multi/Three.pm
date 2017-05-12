#!/usr/bin/perl -Tw

# $Id: Three.pm 1515 2010-08-22 14:41:53Z ian $
# Helper class for multiple inheritance test
#    - unlike Class::Declare, Class::Declare::Attributes doesn't support
#      on-the-fly generation of modules (Attributes::Handlers is unable to
#      return a meaningful glob for a method generated through a string
#      eval()), so we must explicitly generate modules for testing, rather
#      than have the test script generate them for us.
package Class::Declare::Attributes::Multi::Three;

use strict;
use warnings;

use base qw( Class::Declare::Attributes );

# define a public method
sub c : public { 3 };

################################################################################
1;	# end of module
__END__
