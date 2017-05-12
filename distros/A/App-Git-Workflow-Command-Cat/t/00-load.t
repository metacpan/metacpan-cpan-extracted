#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok('App::Git::Workflow::Command::Cat');
}

diag( "Testing App::Git::Workflow::Command::Cat $App::Git::Workflow::Command::Cat::VERSION, Perl $], $^X" );
done_testing();
