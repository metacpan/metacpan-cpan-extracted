#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::BackupTumblr' ) || print "Bail out!
";
}

diag( "Testing App::BackupTumblr $App::BackupTumblr::VERSION, Perl $], $^X" );
