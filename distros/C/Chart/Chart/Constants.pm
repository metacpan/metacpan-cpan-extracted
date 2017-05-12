## @file
# Constants used in Chart:\n
# PI
#
# written and maintained by
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10
#

## @class Chart::Constants
# @brief Constants class defines all necessary constants for Class Chart
#
# Defined are \n
# PI = 3.141...\n
# \n
# Usage:\n
# @code
# use Chart::Constants;
# my $pi = Chart::Constants::PI;
# @endcode
package Chart::Constants;
use strict;

# set up initial constant values
use constant PI => 4 * atan2( 1, 1 );

# be a good module
1;
