use strict;
use warnings;

use Alien::GSL;

use Test::More;

my $type = Alien::GSL->install_type;
note "Install was type <$type>";

ok $type, 'install type sanity/load check';

done_testing;

