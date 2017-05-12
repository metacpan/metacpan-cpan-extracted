#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok('App::Git::Workflow::Command::SinceRelease');
}

diag( "Testing App::Git::Workflow::Command::SinceRelease $App::Git::Workflow::Command::SinceRelease::VERSION, Perl $], $^X" );
done_testing();
