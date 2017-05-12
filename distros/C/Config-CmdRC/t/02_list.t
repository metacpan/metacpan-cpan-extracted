use strict;
use warnings;
use Test::More;

use Config::CmdRC (
    dir  => ['share/dir1', 'share/dir2'],
    file => ['.akirc', '.yuirc'],
);

is RC->{yui}, 2;
is RC->{haruko}, 1;
is RC->{hiroshi}, 1;
is RC->{aki}, 1;

done_testing;
