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
    plan tests => 6;
}

my ($data);

$data = {
    foo => 'bar',
    baz => 'bazoo',
};
bless $data;
walk { wanted => sub {} }, $data;
ok ref $data, __PACKAGE__;

$data = [ 0, 1, 2, 3 ];
bless $data;
walk { wanted => sub {} }, $data;
ok ref $data, __PACKAGE__;

$data = {
    foo => 'bar',
    baz => 'bazoo',
};
walk { wanted => sub {} }, $data;
ok ref $data, 'HASH';
ok $data =~ /^HASH\(0x[0-9a-f]+\)$/;

$data = [ 0, 1, 2, 3];
walk { wanted => sub {} }, $data;
ok ref $data, 'ARRAY';
ok $data =~ /^ARRAY\(0x[0-9a-f]+\)$/;
