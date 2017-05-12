# $Id$

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 3;

#test 1
BEGIN { use_ok('Business::GL::Postalcode', qw(get_all_data)); }

my $postalcodes_ref;

#test 2
ok($postalcodes_ref = get_all_data(), 'Calling get_all_data');

#test 3
is(scalar(@{$postalcodes_ref}), 33);
