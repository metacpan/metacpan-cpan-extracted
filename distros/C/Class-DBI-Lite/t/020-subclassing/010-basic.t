#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use lib qw( lib t/lib );

use Test::More 'no_plan';

use_ok('My::Province');
ok( my $provinces = My::Province->retrieve_all );



