#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Nopaste::Service::AnyPastebin' ) || print "Bail out!
";
}

diag( "Testing App::Nopaste::Service::AnyPastebin $App::Nopaste::Service::AnyPastebin::VERSION, Perl $], $^X" );
