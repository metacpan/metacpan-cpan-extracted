use strict;
use warnings;
use lib 't';
use MyTest;
use Test::More;
use Test::Catch;

plan skip_all => 'available for linux only' unless $^O eq 'linux';

catch_run('[exception]');

done_testing;
