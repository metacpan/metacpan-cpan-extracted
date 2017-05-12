#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $pkg = 'Dancer::Session::Catmandu';

require_ok $pkg;

isa_ok $pkg, 'Dancer::Session::Abstract';

done_testing 2;
