#!perl

use strict;
use warnings;

use App::WUPHF;
use Test::More;

isa_ok(App::WUPHF->new, 'App::WUPHF');

done_testing();
