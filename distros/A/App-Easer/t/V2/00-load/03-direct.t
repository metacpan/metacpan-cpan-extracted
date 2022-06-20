#!/usr/bin/env perl
use v5.24;
use Test::More;

use App::Easer::V2 qw< run d appeaser_api >;

can_ok __PACKAGE__, 'run';
can_ok __PACKAGE__, 'd';
can_ok __PACKAGE__, 'appeaser_api';
is appeaser_api(), 'V2', 'App::Easer API version';
done_testing();
