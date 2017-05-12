# WARNING:
# Do not use for production purposes; intended for debugging/testing only.
# These may change or be removed at any time.
#
package App::TestOnTap::_dbgvars;

use strict;
use warnings;

# if true, avoids processing any DEPENDENCY sections in the config
#
our $IGNORE_DEPENDENCIES = 0;

# default config file name
#
our $CONFIG_FILE_NAME = 'config.testontap';

# if set, attempt to read config from it
#
our $FORCED_CONFIG_FILE; 

# if true, ignores the config file
#
our $IGNORE_CONFIG_FILE = 0;

1;
