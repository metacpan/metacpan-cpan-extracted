########################################################################
                    package My::Build::Solaris;
########################################################################

use strict;
use warnings;
use parent 'My::Build::Linux';

# use gmake on Solaris, otherwise everything goes through (for now)
sub make_command { 'gmake' }

1;
