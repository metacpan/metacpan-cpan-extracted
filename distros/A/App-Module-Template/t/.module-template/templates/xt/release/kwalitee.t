#!perl

use strict;
use warnings;

use Test::More;
use Test::Kwalitee qw/kwalitee_ok/;

kwalitee_ok();

done_testing();
