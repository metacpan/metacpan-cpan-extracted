#!/usr/bin/env perl -w

use lib::abs 'lib','../lib';#, '../../AE-Cnn/lib';
use Test::AE::MC;
use common::sense;

do + lib::abs::path('.').'/check.pl'; $@ and die;
exit;
require Test::NoWarnings;
