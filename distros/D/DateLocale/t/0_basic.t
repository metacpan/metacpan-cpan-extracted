#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN {
    use_ok('DateLocale');
    use_ok("Locale::Messages");
}

diag( "Testing DateLocale $DateLocale::VERSION, Perl $], $^X" );

my $package = 'gettext_xs';

is(Locale::Messages->select_package($package), $package, "Locale::$package not available here. Please install it and try again");

