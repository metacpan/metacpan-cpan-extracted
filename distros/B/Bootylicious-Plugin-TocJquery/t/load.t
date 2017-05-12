#!perl -T

use Test::More tests => 2;


BEGIN {
	use_ok( 'Bootylicious::Plugin::TocJquery' );
}

diag( "Testing Bootylicious::Plugin::TocJquery $Bootylicious::Plugin::TocJquery::VERSION, Perl $], $^X" );

my $toc = Bootylicious::Plugin::TocJquery->new();
ok($toc && ref($toc) eq 'Bootylicious::Plugin::TocJquery', 'ok use new')