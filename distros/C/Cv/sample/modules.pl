#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use Data::Dumper;

# print scalar Cv->getBuildInformation;
local $Data::Dumper::Terse = 1;
local $Data::Dumper::Indent = 1;
print Dumper({ Cv->getBuildInformation});
print "has $_->[0]? $_->[1]\n"
    for map [ $_, Cv->hasModule($_)? 'yes' : 'no' ], qw(core qt);

