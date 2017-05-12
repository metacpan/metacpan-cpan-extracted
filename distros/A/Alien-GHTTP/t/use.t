use strict;
use warnings;

use Alien::GHTTP;

use Test::More;

my $type = Alien::GHTTP->install_type;
note "Install was type <$type>";

ok $type, 'install type sanity/load check';

done_testing;
