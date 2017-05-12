#!perl -T

use Test::More tests => 2;


BEGIN {
	use_ok( 'Bootylicious::Plugin::Gallery' );
}

diag( "Testing Bootylicious::Plugin::Gallery $Bootylicious::Plugin::Gallery::VERSION, Perl $], $^X" );

my $gallery = Bootylicious::Plugin::Gallery->new();
ok($gallery && ref($gallery) eq 'Bootylicious::Plugin::Gallery', 'ok use new')