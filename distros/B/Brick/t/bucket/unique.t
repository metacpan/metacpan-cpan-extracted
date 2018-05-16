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
# Add one brick, not declaring unique
# SHOULD WORK
{
my $sub  =  sub { __LINE__ };
my $name = 'One';

$bucket->add_to_bucket(
	{
	name        => $name,
	description => 'This is the first subroutine',
	code        => $sub,
	}
	);

{
my $count = $bucket->get_brick_by_name( $name );
is( $count, 1, "One brick in the bucket now" );
}

{
my( $code_ref ) = $bucket->get_brick_by_name( $name );
isa_ok( $code_ref, ref sub {} );
is( $code_ref, $sub, "Got back the same code ref" );
}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Add another brick, declaring unique
# SHOULD WORK
{
my $sub2 =  sub { __LINE__ };
my $name = 'Two';

{
my $count = $bucket->get_brick_by_name( $name );
is( $count, 0, "No bricks in the bucket yet" );
}

$bucket->add_to_bucket(
	{
	name        => $name,
	description => 'This is the second subroutine',
	code        => $sub2,
	unique      => 1,
	}
	);

{
my $count = $bucket->get_brick_by_name( $name );
is( $count, 1, "One brick in the bucket now" );
}

{
my( $code_ref ) = $bucket->get_brick_by_name( $name );
isa_ok( $code_ref, ref sub {} );
is( $code_ref, $sub2, "Got back the same code ref" );
}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Add a brick already named, but not declared unique
# SHOULD WORK
{
my $sub3 =  sub { __LINE__ };
my $name = 'One';

{
my $count = $bucket->get_brick_by_name( $name );
is( $count, 1, "One brick named [$name] already" );
}

$bucket->add_to_bucket(
	{
	name        => $name,
	description => 'This is the third subroutine',
	code        => $sub3,
	}
	);

{
my $count = $bucket->get_brick_by_name( $name );
is( $count, 2, "Two bricks name [$name] in the bucket now" );
}

{
my @code_refs = $bucket->get_brick_by_name( $name );
is( scalar @code_refs, 2, "Got two code refs" );
}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Add a brick already named and declared unique
# SHOULD FAIL
{
my $sub3 = sub { __LINE__ };
my $name = 'Two';

{
my $count = $bucket->get_brick_by_name( $name );
is( $count, 1, "No bricks in the bucket yet" );
}

eval {
	$bucket->add_to_bucket(
		{
		name        => $name,
		description => 'This is the third subroutine',
		code        => $sub3,
		}
		);
	};
ok( $@, "Adding already unique name croaks" );

{
my $count = $bucket->get_brick_by_name( $name );
is( $count, 1, "Still only one brick named [$name]" );
}

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Add a brick already named, declaring it unique
# SHOULD FAIL
{
my $sub3 = sub { __LINE__ };
my $name = 'One';

{
my $count = $bucket->get_brick_by_name( $name );
is( $count, 2, "Only one brick named [$name]" );
}

eval {
	$bucket->add_to_bucket(
		{
		name        => $name,
		description => 'This is the third subroutine',
		code        => $sub3,
		unique      => 1,
		}
		);
	};
ok( $@, "Adding already unique name croaks" );

{
my $count = $bucket->get_brick_by_name( $name );
is( $count, 2, "Still only one brick named [$name]" );
}

}
