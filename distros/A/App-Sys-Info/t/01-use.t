#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );

use App::Sys::Info;

App::Sys::Info->run;

ok(1, 'Module loaded ok');
