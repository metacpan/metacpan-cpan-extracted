#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

use lib grep { -d } qw(../lib ./lib ./t/lib);
use Array::Sticky;
use Test::Easy qw(deep_ok);

my @sticky;
tie @sticky, 'Array::Sticky', head => ['head'], body => ['body'], tail => ['tail'];
@sticky = ();
deep_ok( \@sticky, [qw(head tail)] );
