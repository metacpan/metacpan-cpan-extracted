#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

my $class = 'Brick';

use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my %labels = (
	1 => 'One',
	2 => 'Two',
	3 => 'Three',
	red_dog => 'Red Dog',
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $brick = $class->new;
isa_ok( $brick, $class );

my $bucket = $brick->bucket_class->new;
isa_ok( $bucket, $brick->bucket_class );

can_ok( $bucket, 'use_field_labels' );
can_ok( $bucket, 'get_field_label'  );
can_ok( $bucket, 'set_field_label'  );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# get_field_label
$bucket->use_field_labels( \%labels );

# keys  in %labels should return their values
foreach my $key ( keys %labels )
	{
	is( $bucket->get_field_label( $key ), $labels{$key},
		"Right value for key [$key]" );
	}

# keys not in %labels should return undef
{
no warnings 'uninitialized';

foreach my $key ( '', undef, 0, 'blue_dog' )
	{
	ok( ! defined $bucket->get_field_label( $key ),
		"Undefined value for non-existent key [$key]" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# set_field_label

# keys  in %labels should return their values
foreach my $key ( keys %labels )
	{
	my $value = $labels{$key};

	is( $bucket->set_field_label( $value, $key ), $key,
		"Right value for key [$key]" );
	is( $bucket->get_field_label( $value ), $key,
		"Right value for key [$key]" );
	}
