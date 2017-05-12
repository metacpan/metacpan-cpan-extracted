# $Id: get_all_postalcodes.t,v 1.1 2006-04-23 10:21:24 jonasbn Exp $

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 3;

#test 1
use_ok('Business::FO::Postalcode', qw(get_all_postalcodes));

#test 2
ok(my $postalcodes_ref = get_all_postalcodes(), 'Calling get_all_postalcodes');

#test 3
is(scalar(@{$postalcodes_ref}), 130, 'asserting number of postalcodes');
