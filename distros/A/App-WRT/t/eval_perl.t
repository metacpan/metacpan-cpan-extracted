#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use Test::Simple tests => 1; # last test to print
use App::WRT;

my $w = App::WRT->new;

# 'configuration';
my $perlcode = $w->eval_perl("IS <perl>return 'TRUE';</perl>");
ok ($perlcode eq 'IS TRUE', 'eval_perl in line_parse');

1;
