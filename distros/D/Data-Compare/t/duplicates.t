#!/usr/bin/perl -w

use strict;
use warnings;
# use diagnostics;

use Test::More tests => 2;

use Data::Compare;

my $z = 0;
ok(Compare([\$z, \$z], [\$z, \$z]), 'Can compare duplicated array data');
ok(Compare(
    { a => \$z, b => \$z },
    { a => \$z, b => \$z }
), 'Can compare duplicated hash data');
