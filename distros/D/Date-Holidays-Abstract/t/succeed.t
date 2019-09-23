#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib ("$Bin/../t", 't');

use Test::More;

use_ok('Example::Abstraction');

done_testing();
