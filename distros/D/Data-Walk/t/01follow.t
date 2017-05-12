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
    plan tests => 11;
}

my ($data, $wanted, $count, $preprocess);

$data = { foo => 'bar' };
$data->{baz} = $data;

$count = 0;
$wanted = sub {
    ++$count;
    ok ($count <= 5);
};
walk { wanted => $wanted }, $data;

ok $count, 5;

$preprocess = sub {
    my @args = @_;
	
    return () if $count > 10;

    return @args;
};

$wanted = sub {
   ++$count;
};
walk { wanted => $wanted, 
       follow => 1, 
       preprocess => $preprocess,
     }, $data;
ok $count > 5;

$data = {};
bless $data, 'Data::Walk::Fake';

$wanted = sub {
    ok $Data::Walk::address, int $_;
};
walk { wanted => $wanted }, $data;

my $scalar = 'foobar';
$data = [ \$scalar, \$scalar, \$scalar ];
$count = 0;
$wanted = sub {
    unless ('ARRAY' eq ref $_) {
        ok $Data::Walk::seen, $count++;
    }
};
walk { wanted => $wanted }, $data;
$count, scalar @{$data};
