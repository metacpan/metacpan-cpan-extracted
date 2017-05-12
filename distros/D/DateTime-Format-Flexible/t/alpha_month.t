#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 3;

use t::lib::helper;

t::lib::helper::run_tests(
    '12-Oct-2010 => 2010-10-12T00:00:00' ,
    '12-Nov-2010 => 2010-11-12T00:00:00' ,
    '12-Dec-2010 => 2010-12-12T00:00:00' ,
);
