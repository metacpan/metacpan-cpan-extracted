use strict;
use warnings;
use Test::More;
use Data::Compare::Module;

use lib 't/lib';

use ModA;
use ModB;
use ModC;

is_deeply [Data::Compare::Module::compare("ModA", "ModB")], [[ ], [ ]];

is_deeply [Data::Compare::Module::compare("ModA", "ModC")], [[qw(bar)], [qw(bbr)]];

done_testing;
