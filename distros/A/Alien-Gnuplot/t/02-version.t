#===============================================================================
#
#         FILE: 02-version.t
#
#  DESCRIPTION: Test of VERSION() sub
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
#
#===============================================================================

use strict;
use warnings;

use Alien::Gnuplot;
use Test::More tests => 2;
use Test::Exception;

lives_ok  { Alien::Gnuplot->VERSION (0.1) } 'Installed version > 0,1';
throws_ok { Alien::Gnuplot->VERSION (99)  } qr/You should upgrade gnuplot/,
	'Installed version < 99';
