#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok 'App::CPANCoverBadge';
can_ok 'App::CPANCoverBadge', 'badge', 'new';

done_testing();

