package Local::PkgSkip;

use strict;
use warnings;

# A file with a package statement is analyzed directly (not wrapped). This one
# opts out at compile time: "plan skip_all" calls exit() while Test::Vars
# requires the file, so its forked child dies before writing its pipe and the
# parent would die thawing an empty Storable string. perlvars must skip it
# cleanly. (It lives under lib/ with a matching package name so Test::Vars can
# actually load it -- otherwise the require is skipped before the exit fires.)
use Test::More;

BEGIN { plan skip_all => 'this file opts out at compile time' }

sub run {
    my $never_reached = 1;
    return;
}

1;
