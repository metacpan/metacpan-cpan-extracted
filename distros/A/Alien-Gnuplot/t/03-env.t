#===============================================================================
#
#         FILE: 03-env.t
#
#  DESCRIPTION: Environment variable
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
#
#===============================================================================

use strict;
use warnings;

use Alien::Gnuplot;
use Test::More tests => 1;
use Test::Exception;

# Set the path to something non-existent
$ENV{GNUPLOT_BINARY} = '/this/is/not/a/real/path';
throws_ok { Alien::Gnuplot->load_gnuplot } qr/no executable gnuplot found!/,
	'Duff path fatality';
