#!/perl -I..

use strict;
use lib 't';
use Test::More tests => 2;

use cvExp;

eval <<'EXPORT';
use cvExp;
my $meower = $cat;
EXPORT
like $@, qr/^Global symbol "\$cat\" requires explicit package name at/  => 'No default export';


eval <<'EXPORT_ALL';
use cvExpall;
my $meower  = $cat;
my $woofer  = $dogs[0];
my $growler = (keys %hamsters)[0];
EXPORT_ALL
is $@, ''   => 'All symbols exported';
