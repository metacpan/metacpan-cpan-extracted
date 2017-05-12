#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Amazon::S3::FastUploader' ) || print "Bail out!\n";
}

diag( "Testing Amazon::S3::FastUploader $Amazon::S3::FastUploader::VERSION, Perl $], $^X" );
