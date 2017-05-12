#!perl
# 
# Part of Comedi::Lib
#
# Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
#
use Test::More tests => 2;
use warnings;
use strict;

use Comedi::Lib;

my $cref = Comedi::Lib->new(device => '/dev/comedi0', open_flag => 0);
ok(defined $cref, 'Comedi::Lib->new() success');
isa_ok($cref, 'Comedi::Lib');
