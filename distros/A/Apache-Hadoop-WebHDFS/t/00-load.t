#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Apache::Hadoop::WebHDFS' ) || print "Bail out!\n";
}

diag( "Testing Apache::Hadoop::WebHDFS $Apache::Hadoop::WebHDFS::VERSION, Perl $], $^X" );
