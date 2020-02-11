#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::Filter;
use Data::Sah::FilterCommon;
use Data::Sah::FilterJS;
use Nodejs::Util qw(get_nodejs_path);

ok 1;

done_testing;
