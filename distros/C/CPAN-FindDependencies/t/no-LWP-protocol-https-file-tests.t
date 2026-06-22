use strict;
use warnings;

use Test::More;
BEGIN { plan skip_all => "set AUTHOR_TESTING to run these" unless($ENV{AUTHOR_TESTING}) }

use Devel::Hide qw(LWP::Protocol::https);

require './t/configure.t';
