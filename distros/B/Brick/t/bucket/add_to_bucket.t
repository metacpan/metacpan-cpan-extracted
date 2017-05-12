use Test::More 'no_plan';
use Test::Data qw(Scalar);

use strict;

use Brick::Bucket;
use Brick::Numbers;

my $class = 'Brick::Bucket';

use_ok( $class );

my $bucket = $class->new;
isa_ok( $bucket, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# good entry
{
my $code_ref = sub { 5 };

my $sub = $bucket->add_to_bucket(
	{
	code        => $code_ref,
	name        => 'Fiver',
	description => 'Returns 5',
	}
	);
isa_ok( $sub, ref sub {} );	
	
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# bad entry
while (0 ){
my $entry = $bucket->add_to_bucket(
	{
	code        => '',
	name        => 'Fiver',
	description => 'Returns 5',
	}
	);
undef_ok( $entry, "Passing something other than a code ref returns undef" );	
	
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
can_ok( $class, 'number_within_range' );
can_ok( $class, '__compose_satisfy_all' );

$bucket->add_to_bucket( { code =>
	$bucket->number_within_range( { qw( field in_number minimum 5 maximum 10 inclusive 1 ) } )
	} );
	
use Data::Dumper;
#print STDERR Data::Dumper->Dump( [ $bucket ], [qw(bucket)] );

__END__
my $level = 0;
foreach my $tuple ( map { [ $bucket->{$_}{code}, $bucket->{$_}{name} ] } keys %{ $bucket } )
	{		
	#print "Sub is $sub\n";
	
	my @uses = ( [ $level, $tuple->[0] ] );
	
	#print Data::Dumper->Dump( [ \@uses ], [qw(uses)] );

	while( my $pair = shift @uses )
		{
		my $entry = $bucket->get_from_bucket( $pair->[1] );
		
		print STDERR "\t" x $pair->[0], $entry->get_name, "\n";
		
		unshift @uses, map { [ $pair->[0] + 1, $_ ] } @{ $entry->get_comprises( $pair->[1] ) };
		#print Data::Dumper->Dump( [ \@uses ], [qw(uses)] );
		}

	print "\n";
	}