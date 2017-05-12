#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use lib 'lib';

use Checkster 'check';

use Data::Dumper;

say check->true(1, ' ');

say check->not->true(1);

say check->all->true(1, 1, 1, '');

