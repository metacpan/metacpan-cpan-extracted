use Test::More 'no_plan';

my $class = 'Brick';
use_ok( $class );

my $brick = $class->new();
isa_ok( $brick, $class );

$ENV{DEBUG} ||= 0;


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
	[ not_a_number => number_within_range => { 
		minimum   => 0, 
		maximum   => 10, 
		field     => 'not_a_number', 
		inclusive => 0 
		} 
	],

	);


my %input = (
	in_number => 11,
	ex_number =>  0,
	not_a_number => 'NaN',
	);
	
my( $lint ) = $brick->profile_class->lint( \@profile );
is( keys %$lint, 0, "Profile is formatted correctly\n" );

my $profile = $brick->profile_class->new( $brick, \@profile );
isa_ok( $profile, $brick->profile_class );

my $result = $brick->apply( $profile, \%input );

isa_ok( $result, ref [], "apply() returns an array reference" );

is( scalar @$result, scalar @profile, 
	"Results have the same number of elements as the profile" );


if( $ENV{DEBUG } )
	{
	print STDERR Data::Dumper->Dump( [$result], [qw(result)] );
	use Data::Dumper;
	
	foreach my $index ( 0 .. $#$result )
		{
		my $entry = $result->[$index];
		
		my $message = $entry->[2] ? 'passed' :
			ref $entry->[3] ? $entry->[3]->{message} : $entry->[3];
			
		print STDERR "$entry->[0] checked by $entry->[1] which returned:\n\t$message\n";
		}
	}

}
