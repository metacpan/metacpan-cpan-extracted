#!/usr/bin/env perl

use strict;
use warnings;

use Test::Aggregate::Nested;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

Test::Aggregate::Nested->new({
  dirs => 'agg-t/user',
})->run;
