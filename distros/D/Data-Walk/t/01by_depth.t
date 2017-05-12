# Data::Walk - Traverse Perl data structures.
# Copyright (C) 2005-2016 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

use strict;

use Test;
use Data::Walk;

BEGIN {
    plan tests => 13;
}

my ($data, $wanted);

my $data = [[[[[ 1 ], 11], 111], 1111], 11111];

my $wasref = 1;
my $last = 'undef';
$wanted = sub {
    my $isref = ref $_;
    ok ($wasref xor $isref);
    $last = $_;
    $wasref = $isref;
};
walkdepth $wanted, $data;

# The test data is constructed so that each node that is an
# array reference has a number of elements equal to its depth.
# Scalars are also equal to their depth.
$data = [
         [
              3, [ 4, 4, 4, ],
         ],
];

$wanted = sub {
    if (ref $_) {
        my $num = @$_;
        ok $Data::Walk::depth, $num;
    } else {
        $Data::Walk::depth, $_;
    }
};
walkdepth $wanted, $data;
