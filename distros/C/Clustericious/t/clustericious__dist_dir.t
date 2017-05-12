use strict;
use warnings;
use Clustericious;
use Test::More tests => 1;

my $dir = Clustericious->_dist_dir;

ok -d $dir, "share directory is $dir";
