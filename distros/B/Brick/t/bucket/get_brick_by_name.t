#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

my $class = 'Brick';
use_ok( $class );

my $brick = $class->new;
isa_ok( $brick, $class );

my $bucket = $brick->bucket_class->new();
isa_ok( $bucket, $brick->bucket_class );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
ok( defined &Brick::Bucket::get_brick_by_name, "Method is defined" );

{
my $count = $bucket->get_brick_by_name( 'One' );
is( $count, 0, "No bricks in the bucket yet" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Add one brick
my $sub =  sub { __LINE__ };

$bucket->add_to_bucket(
	{
	name        => 'One',
	description => 'This is the first subroutine',
	code        => $sub,
	}
	);

{
my $count = $bucket->get_brick_by_name( 'One' );
is( $count, 1, "One brick in the bucket now" );
}

{
my( $code_ref ) = $bucket->get_brick_by_name( 'One' );
isa_ok( $code_ref, ref sub {} );
is( $code_ref, $sub, "Got back the same code ref" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Add another brick
my $sub2 =  sub { __LINE__ };

{
my $count = $bucket->get_brick_by_name( 'Two' );
is( $count, 0, "No bricks in the bucket yet" );
}

$bucket->add_to_bucket(
	{
	name        => 'Two',
	description => 'This is the second subroutine',
	code        => $sub2,
	}
	);

{
my $count = $bucket->get_brick_by_name( 'Two' );
is( $count, 1, "One brick in the bucket now" );
}

{
my( $code_ref ) = $bucket->get_brick_by_name( 'Two' );
isa_ok( $code_ref, ref sub {} );
is( $code_ref, $sub2, "Got back the same code ref" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Add another with the same name
my $sub3 =  sub { __LINE__ };

{
my $count = $bucket->get_brick_by_name( 'Two' );
is( $count, 1, "No bricks in the bucket yet" );
}

$bucket->add_to_bucket(
	{
	name        => 'Two',
	description => 'This is the third subroutine',
	code        => $sub3,
	}
	);

{
my $count = $bucket->get_brick_by_name( 'Two' );
is( $count, 2, "One brick in the bucket now" );
}

{
my @code_refs = $bucket->get_brick_by_name( 'Two' );
is( scalar @code_refs, 2, "Got two code refs" );
isa_ok( $code_refs[0], ref sub {} );
isa_ok( $code_refs[1], ref sub {} );
#is( $code_ref, $sub3, "Got back the same code ref" );
}
