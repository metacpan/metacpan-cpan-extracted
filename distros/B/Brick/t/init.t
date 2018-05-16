#!/usr/bin/perl
use strict;

use Test::More 'no_plan';
use Test::Output;

my $class = 'Brick';

use_ok( $class );

can_ok( $class, 'init' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SHOULD WORK
{
my $brick = bless {}, 'Brick';

ok( ! exists $brick->{external_packages} );
ok( ! exists $brick->{buckets} );
$brick->init( {} );
ok( exists $brick->{buckets} );
ok( exists $brick->{external_packages} );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SHOULD WORK
{
my $brick = bless {}, 'Brick';

ok( ! exists $brick->{external_packages} );
ok( ! exists $brick->{buckets} );
$brick->init( { external_packages => [ 'Mock::FooValidator' ] } );
ok( exists $brick->{buckets} );
ok( exists $brick->{external_packages} );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SHOULD FAIL (not an array reference)
{
my $brick = bless {}, 'Brick';

ok( ! exists $brick->{external_packages} );
ok( ! exists $brick->{buckets} );
stderr_like
	{ $brick->init( { external_packages => 'Mock::FooValidator' } ) }
	qr/must be an anonymous array/,
	"String value for external_packages carps"
	;
ok( exists $brick->{buckets} );
ok( exists $brick->{external_packages} );
isa_ok( $brick->{external_packages}, ref [] );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SHOULD FAIL (not a defined value)
{
my $brick = bless {}, 'Brick';

ok( ! exists $brick->{external_packages} );
ok( ! exists $brick->{buckets} );
$brick->init( { external_packages => undef } );
ok( exists $brick->{buckets} );
ok( exists $brick->{external_packages} );
isa_ok( $brick->{external_packages}, ref [] );
}
