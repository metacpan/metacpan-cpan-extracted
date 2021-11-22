# -*- cperl -*-
use warnings;
use strict;
use English;
use Test::More;

use Config::Model::Tester 4.007;
use ExtUtils::testlib;

if ($OSNAME eq 'solaris' ) {
    plan skip_all => "Test irrelevant on $OSNAME";
    exit;
}

run_tests() ;
