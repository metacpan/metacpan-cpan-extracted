#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 3;

use_ok('Data::URIID');
use_ok('Data::URIID::Colour');
use_ok('Data::URIID::Barcode');

exit 0;
