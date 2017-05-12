#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

my $class = 'Brick';
use_ok( $class );

my $brick = $class->new();
isa_ok( $brick, $class );

my $bucket_class = $class->bucket_class;
ok( defined &{"${bucket_class}::number_within_range"}, "Method is defined" );

my $bucket = $class->bucket_class->new;
isa_ok( $bucket, $bucket_class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Use both minimum and maximum
# SHOULD WORK

my $constraint = $bucket->number_within_range(
	{
	maximum => 10,
	minimum => 0,
	}
	);
isa_ok( $constraint, ref sub {} );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Use only minimum
# SHOULD FAIL

eval {
	my $constraint = $bucket->number_within_range(
		{
		minimum => 0,
		}
		);
	};
ok( $@, "Leaving off maximum fails" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Use only maximum
# SHOULD FAIL

eval {
	my $constraint = $bucket->number_within_range(
		{
		maximum => 0,
		}
		);
	};
ok( $@, "Leaving off minimum fails" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Use neither minimum nor maximum
# SHOULD FAIL

eval {
	my $constraint = $bucket->number_within_range(
		{
		}
		);
	};
ok( $@, "Leaving off both maximum and minimum fails" );


