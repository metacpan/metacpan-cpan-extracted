#!perl

# Test GaiaPick format read

# Astro::Catalog test harness
use Test::More tests => 5;

# strict
use strict;

#load test
use File::Spec;
use Data::Dumper;

# load modules
require_ok("Astro::Catalog");

my $cat = new Astro::Catalog( Format => 'GaiaPick', Data => \*DATA );
isa_ok( $cat, "Astro::Catalog" );

my $star = $cat->popstar();
my $id = $star->id;
is($id,2,"Last ID");

is($star->ra, "00 44 35.50", "Gaia star RA");
is($star->dec,"+40 41 03.38",  "Gaia star dec");

__DATA__
# name 	 x 	 y 	 ra 	 dec 	 equinox 	 angle 	 peak 	 background 	 fwhm (X:Y)
# Sunday February 08 2004 - 16:43:59
/stardev/bin/kappa/iras.sdf 	 153.3 	 151.5 	 00:42:45.757 	 +41:16:44.96 	 J2000 	 160.7 	 2.7 	 1.4 	 7.8 : 6.1
# Sunday February 08 2004 - 16:44:20
/stardev/bin/kappa/iras.sdf 	 118.6 	 92.1 	 00:44:35.503 	 +40:41:03.38 	 J2000 	 167.6 	 2.1 	 0.2 	 7.2 : 5.7


