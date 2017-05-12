#!perl

use strict;
use warnings;
use Test::More;
use Browser::Open;

pass("Compiled Browser::Open $INC{'Browser/Open.pm'}, version $Browser::Open::VERSION");

done_testing();
