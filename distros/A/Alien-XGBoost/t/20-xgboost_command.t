#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test2::V0;
use Test::Alien;
use Alien::XGBoost;

alien_ok 'Alien::XGBoost';
run_ok('xgboost')->exit_is(0);

done_testing;

