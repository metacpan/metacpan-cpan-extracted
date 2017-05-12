#!/usr/bin/perl
#
# Copyright (c) 2011 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#

use strict;
use warnings;

use Test::More;

use Cairo;

unless (Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 10, 0)) {
	plan skip_all => 'need cairo 1.10';
}

plan tests => 19;

my $region = Cairo::Region->create;
isa_ok ($region, 'Cairo::Region');

$region = Cairo::Region->create ({x=>10, y=>10, width=>5, height=>5});
isa_ok ($region, 'Cairo::Region');

$region = Cairo::Region->create ({x=>10, y=>10, width=>5, height=>5},
                                 {x=>0, y=>0, width=>5, height=>5});
isa_ok ($region, 'Cairo::Region');

is ($region->status, 'success');
is_deeply ($region->get_extents, {x=>0, y=>0, width=>15, height=>15});
is ($region->num_rectangles, 2);
is_deeply ($region->get_rectangle (1), {x=>10, y=>10, width=>5, height=>5});
ok (!$region->is_empty);
ok ($region->contains_point (12, 13));
is ($region->contains_rectangle ({x=>7, y=>7, width=>5, height=>5}), 'part');
ok ($region->equal ($region));
$region->translate (0, 0);

my $other = {x=>0, y=>0, width=>15, height=>15};
foreach my $method (qw/intersect subtract union xor/) {
  is ($region->$method ($region), 'success', $method);
  my $rect_method = $method . '_rectangle';
  is ($region->$rect_method ($other), 'success', $rect_method);
}
