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
	[ last_year => _is_valid_date => {
		field  => 'last_year',
		}
	],
	[ next_year => _is_valid_date => {
		field  => 'next_year',
		}
	],
	[ unix_birthdate => _is_valid_date => {
		field  => 'unix_birthdate',
		}
	],
	[ invalid_day => _is_valid_date => {
		field  => 'invalid_day',
		}
	],
	[ invalid_month => _is_valid_date => {
		field  => 'invalid_month',
		}
	],
	[ invalid_format => _is_valid_date => {
		field  => 'no_digits',
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
	);

my( $lint ) = $brick->profile_class->lint( \@profile );
is( keys %$lint, 0, "Profile is formatted correctly\n" );
	print STDERR Data::Dumper->Dump( [$lint], [qw(lint)] ) if $ENV{DEBUG};
	use Data::Dumper;

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
