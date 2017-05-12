#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Audio::Metadata::Flac' ) || print "Bail out!
";
}

diag( "Testing Audio::Metadata::Flac $Audio::Metadata::Flac::VERSION, Perl $], $^X" );
