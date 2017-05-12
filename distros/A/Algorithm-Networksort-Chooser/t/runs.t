use strict;

use Test::More tests => 1;

use Config;
my $perlpath = $Config{perlpath};

my $network = eval `$perlpath -I lib bin/algorithm-networksort-chooser 9 --raw`;
is(0+@$network, 25, "Found Floyd's best known network for size 9");
