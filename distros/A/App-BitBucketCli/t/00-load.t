#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::BitBucketCli' );
    use_ok( 'App::BitBucketCli::Branch' );
    use_ok( 'App::BitBucketCli::Core' );
    use_ok( 'App::BitBucketCli::Project' );
    use_ok( 'App::BitBucketCli::PullRequest' );
    use_ok( 'App::BitBucketCli::Repository' );
}

diag( "Testing App::BitBucketCli $App::BitBucketCli::VERSION, Perl $], $^X" );
done_testing();
