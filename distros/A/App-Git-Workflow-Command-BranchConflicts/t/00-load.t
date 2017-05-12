#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::Git::Workflow::Command::BranchConflicts' );
}

diag( "Testing App::Git::Workflow::Command::BranchConflicts $App::Git::Workflow::Command::BranchConflicts::VERSION, Perl $], $^X" );
done_testing();
