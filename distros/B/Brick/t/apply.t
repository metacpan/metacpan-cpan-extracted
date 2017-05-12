use Test::More 'no_plan';
use strict;

my $class = 'Brick';
use_ok( $class );

my $brick = $class->new();
isa_ok( $brick, $class );

use Brick::Profile;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
{
my @profile = ();
my %input   = ();

my $lint = $brick->profile_class->lint( \@profile );
is( $lint, 0, "Profile is formatted correctly" );

my $profile = $brick->profile_class->new( $brick, \@profile );
isa_ok( $profile, $brick->profile_class );

my $result = $brick->apply( $profile, \%input || {} );
isa_ok( $result, $class->result_class );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
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

my %input = (
	in_number => 5,
	ex_number => 0,
	);
	
my( $lint ) = $brick->profile_class->lint( \@profile );
is( keys %$lint, 0, "Profile is formatted correctly" );

use Data::Dumper;
print STDERR Data::Dumper->Dump( [$lint], [qw(lint)] ) if $ENV{DEBUG};


if( $ENV{DEBUG} )
	{
	my $profile = $brick->profile_class->new( $brick, \@profile );

	print STDERR "\n", "-" x 50, "\n";
	my $result = $brick->apply( $profile, \%input || {} );
	print STDERR "\n", "-" x 50, "\n";
	}
}
