use strict;
use warnings;
use Test::More 0.98;
plan skip_all => 'Test irrelevant on Other than MSWin32' if($^O ne 'MSWin32');

fail sprintf("%s OS is not supported.",$^O);

done_testing;
