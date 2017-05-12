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
    plan tests => 52;
}

my ($data, $item, $count, $wanted, @hashdata);

$data = "foobar";
$item;
$count = 0;
$wanted = sub {
    ++$count;
    $item = $_;
};
walk $wanted, $data;
ok $count, 1;
ok $item, $data;

$data = [ (0 .. 4) ];
$count = 0;
$wanted = sub {
    ok($Data::Walk::type, 'ARRAY') unless ref $_;
    ++$count;
};
walk $wanted, $data;
ok $count, 1 + @{$data};

@hashdata = qw (a b c d e);
$data = { map { $_ => $_ } @hashdata };
$count = 0;
$wanted = sub {
    ok($Data::Walk::type, 'HASH')unless ref $_;
    ++$count;
};
walk $wanted, $data;
ok $count, 1 + 2 * @hashdata;

@hashdata = qw (a b c d e);
$data = { map { $_ => $_ } @hashdata };
my @list = (0 .. 4);
$data->{list} = [ @list ];
$count = 0;
$wanted = sub {
    ++$count;
};
walk $wanted, $data;
ok $count, 1 + 2 * @hashdata + 2 + @list;

$data = [ (0 .. 4) ];
bless $data;
$count = 0;
$wanted = sub {
    $DB::single = 1;
    ok($Data::Walk::type, 'ARRAY') unless ref $_;
    ++$count;
};
walk $wanted, $data;
ok $count, 1 + @{$data};

@hashdata = qw (a b c d e);
$data = { map { $_ => $_ } @hashdata };
bless $data;

$count = 0;
$wanted = sub {
    ok($Data::Walk::type, 'HASH') unless ref $_;
    ++$count;
};
walk $wanted, $data;
ok $count, 1 + 2 * @hashdata;

@hashdata = qw (a b c d e);
$data = { map { $_ => $_ } @hashdata };
@list = (0 .. 4);
$data->{list} = [ @list ];
bless $data;
bless $data->{list};

$count = 0;
$wanted = sub {
    ++$count;
};
walk $wanted, $data;
ok $count, 1 + 2 * @hashdata + 2 + @list;

$data = [[[[[ 1 ], 11], 111], 1111], 11111];
my $wasref = 1;
my $last = '';
$wanted = sub {
    my $isref = ref $_;

    ok ($wasref || (!$wasref && !$isref));

    $last = $_;
    $wasref = $isref;
};
walk $wanted, $data;
ok !$wasref;

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
walk $wanted, $data;
