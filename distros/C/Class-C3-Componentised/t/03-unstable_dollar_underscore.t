use strict;
use warnings;

use Class::C3::Componentised;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/lib";

my @mods = 'DestroyDollarUnderscore';

for (@mods) {
  Class::C3::Componentised->ensure_class_loaded($_);
}

is_deeply(\@mods, [ 'DestroyDollarUnderscore' ], '$_ untouched');

done_testing;
