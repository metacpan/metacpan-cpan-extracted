#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::Git::Workflow::Command::Take' );
}

diag( "Testing App::Git::Workflow::Command::Take $App::Git::Workflow::Command::Take::VERSION, Perl $], $^X" );
done_testing();
