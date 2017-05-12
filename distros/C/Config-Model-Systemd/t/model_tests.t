# -*- cperl -*-
use warnings;
use strict;

use Config::Model::Tester 2.054;
use ExtUtils::testlib;

my $arg = shift || '';
my $test_only_app = shift || '';
my $do = shift ;

run_tests($arg, $test_only_app, $do) ;
