#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use vars qw( $looping $moving_on );
use Test::More 'no_plan'; # tests => 20;

my $module = 'Acme::Pills';

require_ok( $module ) or exit;
my @oldinc = @INC;
$module->import();

isa_ok( $INC[0], 'CODE',
	'default import() should install something in @INC that' );
is( $INC[0], \&Acme::Pills::fine_products,
	'... a reference to fine_products()' );

{
	my $non_random = \&Acme::Pills::empty_box;
	my $breakage;
	local (*Acme::Pills::bad_product, *Acme::Pills::breaks, %INC);
	*Acme::Pills::bad_product = sub { $non_random };
	*Acme::Pills::breaks      = sub { $breakage-- };
	eval { require 'Some::Module'; 1 };
	is( $@, '',
		'loading a module should apparently succeed if empty box chosen' );
	ok( $INC{'Some/Module.pm'}, '... populating %INC appropriately' );
	ok( Some::Module::some_sub(), '... installing always successful subs' );

	local @INC  = ( 'lib', $INC[0] );
	$non_random = \&Acme::Pills::breaks_when_needed;
	$breakage = 5;
	eval { require 'BreakMe' };
	is( $@, '',
		'loading a module should succeed if breakable chosen' );
	ok( $moving_on, '... breaking infinite loops' );
	is( $looping, 5, '... looping while construct is true' );

	$breakage = 9;
	BreakMe::breakit();
	is( $moving_on, 2, '... potentially breaking for loops early' );
}

my $oos = Acme::Pills::out_of_stock( 'foobar', 'foo/bar.pm' );
like( <$oos>, qr/print.+foobar is out of stock/,
	'out_of_stock() should print an out of stock message' );
ok( ! $INC{'foo/bar.pm'}, '... not populating %INC for module' );

my @breaks = map { Acme::Pills::breaks() ? 1 : () } 1 .. 1000;
cmp_ok( @breaks, '>', 75,
	'breaks() should be true more than 7.5% of the time' );
cmp_ok( @breaks, '<', 125,
	'... and false less than 12.5% of the time' );

my @subs  = map { Acme::Pills::bad_product() } 1 .. 2000;
my @empty = grep { $_ == \&Acme::Pills::empty_box } @subs;
cmp_ok( @empty, '>', 150,
	'empty_box() should be called more than 7.5% of the time' );
cmp_ok( @empty, '<', 250,
	'... and less than 12.5% of the time' );

my @breaking = grep { $_ == \&Acme::Pills::breaks_when_needed } @subs;
cmp_ok( @breaking, '>', 150,
	'breaks_when_needed() should be called more than 7.5% of the time' );
cmp_ok( @breaking, '<', 250,
	'... and less than 12.5% of the time' );

my @nostock = grep { $_ == \&Acme::Pills::out_of_stock } @subs;
cmp_ok( @nostock, '>', 150,
	'out_of_stock() should be called more than 7.5% of the time' );
cmp_ok( @nostock, '<', 250,
	'... and less than 12.5% of the time' );
