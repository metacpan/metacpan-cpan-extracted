#!/usr/bin/perl
use strict;

use Test::More 'no_plan';
use Test::Output;

my $class = 'Brick';
use_ok( $class );

my $brick = $class->new();
isa_ok( $brick, $class );

$ENV{DEBUG} ||= 0;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
{
my @profile = ();

my $lint = $brick->profile_class->lint( \@profile );
is( $lint, 0, "Profile is formatted correctly" );

my $profile = $brick->profile_class->new( $brick, \@profile );
isa_ok( $profile, $brick->profile_class );

my $str = $profile->explain;
print STDERR "\n", "-" x 50, "\n", $str, "-" x 50,  "\n"  if $ENV{DEBUG};
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# SHOULD WORK
{
my @profile = (
	[ in_number => number_within_range => { 
		minimum   => 0, 
		maximum   => 10, 
		field     => 'in_number', 
		inclusive => 1 
		} 
	],
	[ ex_number => number_within_range => { 
		minimum   => 0, 
		maximum   => 10, 
		field     => 'ex_number', 
		inclusive => 0 
		} 
	],

	);

my $lint = $brick->profile_class->lint( \@profile );
is( $lint, 0, "Profile is formatted correctly" );

my $profile = $brick->profile_class->new( $brick, \@profile );
isa_ok( $profile, $brick->profile_class );


my $str = $profile->explain;
print STDERR "\n", "-" x 50, "\n", $str, "-" x 50,  "\n"  if $ENV{DEBUG};
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# SHOULD FAIL
{
my @profile = (
	[ in_number => number_within_range => { 
		minimum   => 0, 
		maximum   => 10, 
		field     => 'in_number', 
		inclusive => 1 
		} 
	],
	{},
	[ ex_number => number_within_range => { 
		minimum   => 0, 
		maximum   => 10, 
		field     => 'ex_number', 
		inclusive => 0 
		} 
	],

	);

my $lint = eval { $brick->profile_class->lint( \@profile ) };
is( $lint, 1, "Profile is formatted correctly" );

my $str;

stderr_like 
	{ $str = eval { 
		$brick->profile_class->new( $brick, \@profile ) } 
		}
	qr/did not validate/,
	"Bad profile carps";

is( $str, undef, "Profile is formatted correctly" );

print STDERR "\n", "-" x 50, "\n", $str, "-" x 50,  "\n"  if $ENV{DEBUG};
}
