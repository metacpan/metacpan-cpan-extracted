#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::Git::Workflow::Extra' );
}

diag( "Testing module $App::Git::Workflow::Extra::VERSION, Perl $], $^X" );
done_testing();
