#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::JenkinsCli' );
}

diag( "Testing App::JenkinsCli $App::JenkinsCli::VERSION, Perl $], $^X" );
done_testing();
