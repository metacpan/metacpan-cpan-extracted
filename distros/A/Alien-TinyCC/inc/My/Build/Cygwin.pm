########################################################################
                    package My::Build::Cygwin;
########################################################################

use strict;
use warnings;
use parent 'My::Build::Linux';

sub extra_config_args { '--enable-cygwin' }

1;
