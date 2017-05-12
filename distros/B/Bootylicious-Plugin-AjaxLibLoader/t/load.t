#!perl -T

use Test::More tests => 2;


BEGIN {
	use_ok( 'Bootylicious::Plugin::AjaxLibLoader' );
}

diag( "Testing Bootylicious::Plugin::AjaxLibLoader $Bootylicious::Plugin::AjaxLibLoader::VERSION, Perl $], $^X" );

my $loader = Bootylicious::Plugin::AjaxLibLoader->new();
ok($loader && ref($loader) eq 'Bootylicious::Plugin::AjaxLibLoader', 'ok use new')