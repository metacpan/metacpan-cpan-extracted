use Test::More 'no_plan';

my $class = 'Brick';
use_ok( $class );

my $brick = $class->new();
isa_ok( $brick, $class );

$ENV{DEBUG} ||= 0;

use_ok( 'Brick::Dates' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
{
my @profile = (
	[ now => _date_is_after => { 
		start_date_field  => 'last_year', 
		input_date_field  => 'today',
		} 
	],
	[ next_year => _date_is_after => { 
		start_date        => 20070501, 
		input_date_field  => 'unix_birthdate',
		} 
	],
	[ between_fails => date_within_range => { 
		start_date        => 20070501, 
		end_date_field    => 'end_of_time',
		input_date_field  => 'unix_birthdate',
		} 
	],
	[ between_passes => date_within_range => { 
		start_date        => 19631122, 
		end_date_field    => 'end_of_time',
		input_date_field  => 'unix_birthdate',
		} 
	],
	);


my %input = (
	last_year      => 20060613,
	next_year      => 20071106,
	unix_birthdate => 19700101,
	invalid_day    => 20070229,
	invalid_month  => 20074229,
	no_digits      => 'QBERT',
	today          => 20070129,
	end_of_time    => 20380714,
	);
	
my( $lint ) = $brick->profile_class->lint( \@profile );
is( keys %$lint, 0, "Profile is formatted correctly\n" );
#	print STDERR Data::Dumper->Dump( [$lint], [qw(lint)] ) if $ENV{DEBUG};
#	use Data::Dumper;

my $profile = $brick->profile_class->new( $brick, \@profile );
isa_ok( $profile, $brick->profile_class );

if( $ENV{DEBUG} )
	{
	print STDERR $profile->explain;
	}
	
my $result = $brick->apply( $profile, \%input );

isa_ok( $result, ref [], "apply() returns an array reference" );

is( scalar @$result, scalar @profile, 
	"Results have the same number of elements as the profile" );


if( $ENV{DEBUG } )
	{
	#print STDERR Data::Dumper->Dump( [$result], [qw(result)] );
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
