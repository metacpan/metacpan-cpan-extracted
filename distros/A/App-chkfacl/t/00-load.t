#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::chkfacl' );
}

diag( "Testing App::chkfacl $App::chkfacl::VERSION, Perl $], $^X" );
done_testing();
