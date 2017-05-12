use Test::More 'no_plan';

my $class = 'Brick';
use_ok( $class );

my $brick = $class->new();
isa_ok( $brick, $class );

$ENV{DEBUG} ||= 0;

use_ok( 'Brick::General' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
my @profile = (
	[ 'defined' => defined_fields => { 
		fields  => [ qw(in_number ex_number not_a_number blank_field) ], 
		} 
	],
	[ true => true_fields => { 
		fields  => [ qw(in_number not_a_number) ], 
		} 
	],
	[ false => false_fields => { 
		fields  => [ qw(ex_number blank_field undef_field) ], 
		} 
	],
	[ blank => blank_fields => { 
		fields  => [ qw(blank_field undef_field) ], 
		} 
	],
	[ some_not_blank => blank_fields => { 
		fields  => [ qw(in_number blank_field true_field undef_field) ], 
		} 
	],
	[ bad_row => true_fields => { 
		fields  => [ qw(ex_number blank_field in_number) ], 
		} 
	],

	);

my %input = (
	in_number    => 11,
	ex_number    =>  0,
	not_a_number => 'NaN',
	blank_field  => '',
	undef_field  => undef,
	);
	
my( $lint ) = $brick->lint( \@profile );
is( keys %$lint, 0, "Profile is formatted correctly\n" );
#print STDERR Data::Dumper->Dump( [$lint], [qw(lint)] );
use Data::Dumper;

if( $ENV{DEBUG} )
	{
	print STDERR $brick->explain( \@profile );
	}
	
my $result = $brick->apply( \@profile, \%input );

isa_ok( $result, ref [], "apply() returns an array reference" );

is( scalar @$result, scalar @profile, 
	"Results have the same number of elements as the profile" );


print STDERR Data::Dumper->Dump( [$result], [qw(result)] ) if $ENV{DEBUG};
use Data::Dumper;

print STDERR "\n"  if $ENV{DEBUG};

foreach my $index ( 0 .. $#$result )
	{
	my $entry = $result->[$index];
	
	print STDERR "----- $entry->[0] ----------------------------\n" if $ENV{DEBUG};
	
	do { print STDERR "\tpassed\n\n" if $ENV{DEBUG}; next } if $entry->[2];
	
	my @data = ( $entry->[3] );
	my @errors = ();
	my $iterations = 0;
	while( my $error = shift @data )
		{
		last if $iterations++ > 20; # debugging guard against infinity
#		print STDERR "Iteration $iterations\n";
		if( $error->{handler} =~ m/^__/ )
			{
			push @data, @{ $error->{errors} };
			next;
			}
		
		push @errors, $error;
		}
		
	print STDERR Data::Dumper->Dump( [\@errors], [qw(errors)] ) if $ENV{DEBUG};

	#print STDERR "$entry->[0] checked by $entry->[1] which returned:\n\t$message\n";
	
	next unless ref $entry->[3] and @{ $entry->[3]{errors} } > 0;
	
	foreach my $error ( @errors )
		{
		print STDERR "$error->{handler}: $error->{message}\n" if $ENV{DEBUG};
		}
	
	print STDERR "\n" if $ENV{DEBUG};
	}


foreach my $row ( splice @$result, 0, 4 )
	{
	is( $row->[2], 1, "$row->[0] passes" );
	}

foreach my $row ( @$result )
	{
	is( $row->[2], 0, "$row->[0] fails (as expected)" );
	}
