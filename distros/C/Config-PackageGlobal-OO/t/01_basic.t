#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

{
	package Module::Crappy;

	our ( $scalar_conf, @array_conf ) = ( "foo", 1, 2, 3 );

	my $conf = "moose";
	sub sub_conf {
		$conf = shift if @_;
		$conf;
	}

	my $thing = "thing";
	sub get_thing { $thing }
	sub set_thing { $thing = shift }

	sub some_action {
		return [
			$scalar_conf,
			$conf,
			$thing,
			[ @array_conf ],
		];
	}
}

my $m; use ok $m = "Config::PackageGlobal::OO";

my $defaults = [ "foo", "moose", "thing", [ 1, 2, 3 ] ];

is_deeply( Module::Crappy::some_action(), $defaults , "current values" );

can_ok($m, "new");
isa_ok(my $o = $m->new("Module::Crappy", "some_action"), $m);

is( $o->scalar_conf, "foo", "scalar accessor" );
is_deeply( [ $o->array_conf ], [ 1, 2, 3 ], "array accessor" );
is( $o->sub_conf, "moose", "sub accessor" );
is( $o->thing, "thing", "sub accessor get/set style" );

$o->scalar_conf( "new-val" );
is( $o->scalar_conf, "new-val", "scalar accessor also sets" );

is_deeply( [ $o->array_conf(qw/a b c/) ], [qw/a b c/], "array accessor also sets" );

$o->sub_conf("elk");
is( $o->sub_conf, "elk", "sub accessor also sets" );

$o->thing("thong");
is( $o->thing, "thong", "scalar accessor also sets with set/get style" );


is_deeply( Module::Crappy::some_action(), $defaults , "original values not changed" );

is_deeply( $o->some_action(), [ "new-val", "elk", "thong", [qw/a b c/] ], "values temporarily changed" );

is_deeply( Module::Crappy::some_action(), $defaults , "original values not changed" );

dies_ok {
	$m->new("Module::Crappy", "does_not_exist");
} "can't use non existent function as action method";

dies_ok {
	$o->this_does_not_exist();
} "can't use nonexistent field as config method";
