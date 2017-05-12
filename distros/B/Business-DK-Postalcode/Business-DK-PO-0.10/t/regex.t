# $Id: regex.t,v 1.1 2006-04-23 10:21:24 jonasbn Exp $

use strict;
use Test::More qw(no_plan);

#test 1
BEGIN { use_ok('Business::DK::Postalcode', qw(get_all_postalcodes create_regex)); }

my $postalcodes = get_all_postalcodes();
my $regex = create_regex($postalcodes);

#test 2 .. 
foreach my $postalcode (@{$postalcodes}) {
	ok($postalcode =~ m/$$regex/cg, "$postalcode tested");
}