#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use lib qw( lib t/lib );
use Data::Dumper;

use_ok('My::State');
use My::Fixtures 'states';

is( My::State->count_search(state_abbr => 'AL') => 1 );



