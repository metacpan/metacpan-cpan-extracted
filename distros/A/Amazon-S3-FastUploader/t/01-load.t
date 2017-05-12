#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Amazon::S3::FastUploader::File' ) || print "Bail out!\n";
}

diag( "Testing Amazon::S3::FastUploader::File $Amazon::S3::FastUploader::File::VERSION, Perl $], $^X" );
