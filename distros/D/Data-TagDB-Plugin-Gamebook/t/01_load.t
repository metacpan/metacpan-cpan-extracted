#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 2;

use_ok('Data::TagDB::Plugin::Gamebook');
use_ok('Data::TagDB::Plugin::Gamebook::Exit');

exit 0;
