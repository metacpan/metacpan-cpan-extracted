#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'App::BitBucketCli' );
    use_ok( 'App::BitBucketCli::Branch' );
    use_ok( 'App::BitBucketCli::Base' );
    use_ok( 'App::BitBucketCli::Core' );
    use_ok( 'App::BitBucketCli::Link' );
    use_ok( 'App::BitBucketCli::Links' );
    use_ok( 'App::BitBucketCli::Project' );
    use_ok( 'App::BitBucketCli::PullRequest' );
    use_ok( 'App::BitBucketCli::Repository' );
    use_ok( 'App::BitBucketCli::Command::PullRequests' );
    use_ok( 'App::BitBucketCli::Command::Repositories' );
    use_ok( 'App::BitBucketCli::Command::Repository' );
    use_ok( 'App::BitBucketCli::Command::Projects' );
    use_ok( 'App::BitBucketCli::Command::Branches' );
}

diag( "Testing App::BitBucketCli $App::BitBucketCli::VERSION, Perl $], $^X" );
done_testing();
