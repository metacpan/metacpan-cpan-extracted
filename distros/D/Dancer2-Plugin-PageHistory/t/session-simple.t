use strict;
use warnings;

use Test::Fatal;
use Test::More;
use lib 't/lib';

use Tests;

Tests::run_tests( { session => 'Simple' } );

done_testing;
