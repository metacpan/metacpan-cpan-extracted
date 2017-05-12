#!/usr/bin/env perl
#
# $Revision: 1.1 $
# $Source: /home/cvs/CGI-PathParam/t/02pod.t,v $
# $Date: 2006/05/30 22:29:29 $
#
use strict;
use warnings;
our $VERSION = '0.01';

use blib;
use English qw(-no_match_vars);
use Test::More;

if ( $ENV{TEST_POD} || $ENV{TEST_ALL} ) {
    eval {
        require Test::Pod;
        Test::Pod->import;
    };
    if ($EVAL_ERROR) {
        plan skip_all => 'Test::Pod required to enable this test';
    }
}
else {
    plan skip_all => 'set TEST_POD to enable this test';
}

all_pod_files_ok();
