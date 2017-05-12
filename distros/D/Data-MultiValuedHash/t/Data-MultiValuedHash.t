# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/Data-MultiValuedHash.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..221\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::MultiValuedHash 1.081;
$loaded = 1;
print "ok 1\n";
use strict;
use warnings;

# Set this to 1 to see complete result text for each test
my $verbose = shift( @ARGV ) ? 1 : 0;  # set from command line

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

######################################################################
# Here are some utility methods:

my $test_num = 1;  # same as the first test, above

sub result {
	$test_num++;
	my ($worked, $detail) = @_;
	$verbose or 
		$detail = substr( $detail, 0, 50 ).
		(length( $detail ) > 47 ? "..." : "");	
	print "@{[$worked ? '' : 'not ']}ok $test_num $detail\n";
}

sub message {
	my ($detail) = @_;
	print "-- $detail\n";
}

sub vis {
	my ($str) = @_;
	$str =~ s/\n/\\n/g;  # make newlines visible
	$str =~ s/\t/\\t/g;  # make tabs visible
	return( $str );
}

sub serialize {
	my ($input,$is_key) = @_;
	return( join( '', 
		ref($input) eq 'HASH' ? 
			( '{ ', ( map { 
				( serialize( $_, 1 ), serialize( $input->{$_} ) ) 
			} sort keys %{$input} ), '}, ' ) 
		: ref($input) eq 'ARRAY' ? 
			( '[ ', ( map { 
				( serialize( $_ ) ) 
			} @{$input} ), '], ' ) 
		: defined($input) ?
			"'$input'".($is_key ? ' => ' : ', ')
		: "undef".($is_key ? ' => ' : ', ')
	) );
}

######################################################################

message( "START TESTING Data::MultiValuedHash" );

######################################################################
# testing new(), initialize(), and clone()

{
	message( "testing new(), initialize(), and clone()" );

	my ($did, $should);

	# make empty, case-sensitive (norm)

	my $mvh1 = Data::MultiValuedHash->new();  
	result( UNIVERSAL::isa( $mvh1, "Data::MultiValuedHash" ), 
		"mvh1 = new() ret MVH obj" );

	$did = $mvh1->ignores_case();
	result( $did == 0, "on init mvh1->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh1->fetch_all() ) );
	$should = "{ }, ";
	result( $did eq $should, "on init mvh1->fetch_all() returns '$did'" );

	# make empty, case-insensitive

	my $mvh2 = Data::MultiValuedHash->new( 1 );  
	result( UNIVERSAL::isa( $mvh2, "Data::MultiValuedHash" ), 
		"mvh2 = new( 1 ) ret MVH obj" );

	$did = $mvh2->ignores_case();
	result( $did == 1, "on init mvh2->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh2->fetch_all() ) );
	$should = "{ }, ";
	result( $did eq $should, "on init mvh2->fetch_all() returns '$did'" );

	# make new with initial values, case-sensitive keys

	my $mvh3 = Data::MultiValuedHash->new( 0, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} );  
	result( UNIVERSAL::isa( $mvh3, "Data::MultiValuedHash" ), 
		"mvh3 = new( 0, {...} ) ret MVH obj" );

	$did = $mvh3->ignores_case();
	result( $did == 0, "on init mvh3->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh3->fetch_all() ) );
	$should = "{ 'Name' => [ 'John', ], 'Siblings' => [ 'Laura', 'Andrew', ".
		"'Julia', ], 'age' => [ '17', ], 'color' => [ 'green', ], 'pets' => ".
		"[ 'Cat', 'Bird', ], }, ";
	result( $did eq $should, "on init mvh3->fetch_all() returns '$did'" );

	# make new with initial values, case-insensitive keys

	my $mvh4 = Data::MultiValuedHash->new( 1, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} );  
	result( UNIVERSAL::isa( $mvh4, "Data::MultiValuedHash" ), 
		"mvh4 = new( 1, {...} ) ret MVH obj" );

	$did = $mvh4->ignores_case();
	result( $did == 1, "on init mvh4->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh4->fetch_all() ) );
	$should = "{ 'age' => [ '17', ], 'color' => [ 'green', ], ".
		"'name' => [ 'John', ], 'pets' => [ 'Cat', 'Bird', ], ".
		"'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "on init mvh4->fetch_all() returns '$did'" );

	# make new with initial values from mvh3, case-sensitive keys

	my $mvh5 = Data::MultiValuedHash->new( 0, $mvh3 );  
	result( UNIVERSAL::isa( $mvh5, "Data::MultiValuedHash" ), 
		"mvh5 = new( 0, mvh3 ) ret MVH obj" );

	$did = $mvh5->ignores_case();
	result( $did == 0, "on init mvh5->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh5->fetch_all() ) );
	$should = "{ 'Name' => [ 'John', ], 'Siblings' => [ 'Laura', 'Andrew', ".
		"'Julia', ], 'age' => [ '17', ], 'color' => [ 'green', ], 'pets' => ".
		"[ 'Cat', 'Bird', ], }, ";
	result( $did eq $should, "on init mvh5->fetch_all() returns '$did'" );

	# make new with initial values from mvh3, case-insensitive keys

	my $mvh6 = Data::MultiValuedHash->new( 1, $mvh3 );  
	result( UNIVERSAL::isa( $mvh4, "Data::MultiValuedHash" ), 
		"mvh6 = new( 1, mvh3 ) ret MVH obj" );

	$did = $mvh6->ignores_case();
	result( $did == 1, "on init mvh6->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh6->fetch_all() ) );
	$should = "{ 'age' => [ '17', ], 'color' => [ 'green', ], ".
		"'name' => [ 'John', ], 'pets' => [ 'Cat', 'Bird', ], ".
		"'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "on init mvh6->fetch_all() returns '$did'" );
	
	# make new as a clone of mvh1 - no values, case-sensitive
	
	my $mvh7 = $mvh1->clone();
	result( UNIVERSAL::isa( $mvh7, "Data::MultiValuedHash" ), 
		"mvh7 = mvh1->clone() ret MVH obj" );

	$did = $mvh7->ignores_case();
	result( $did == 0, "on clone mvh7->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh7->fetch_all() ) );
	$should = "{ }, ";
	result( $did eq $should, "on clone mvh7->fetch_all() returns '$did'" );
	
	# make new as a clone of mvh4 - some values, case-insensitive
	
	my $mvh8 = $mvh4->clone();
	result( UNIVERSAL::isa( $mvh8, "Data::MultiValuedHash" ), 
		"mvh8 = mvh4->clone() ret MVH obj" );

	$did = $mvh8->ignores_case();
	result( $did == 1, "on clone mvh8->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh8->fetch_all() ) );
	$should = "{ 'age' => [ '17', ], 'color' => [ 'green', ], ".
		"'name' => [ 'John', ], 'pets' => [ 'Cat', 'Bird', ], ".
		"'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "on clone mvh8->fetch_all() returns '$did'" );
}

######################################################################
# test ignores_case()

{
	message( "testing ignores_case()" );

	my ($mvh, $did, $should);
	
	# convert from false to false

	$mvh = Data::MultiValuedHash->new( 0, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} ); 
	$mvh->ignores_case( 0 );
	
	$did = $mvh->ignores_case();
	result( $did == 0, "ign-case from 0 to 0; ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all() ) );
	$should = "{ 'Name' => [ 'John', ], 'Siblings' => [ 'Laura', 'Andrew', ".
		"'Julia', ], 'age' => [ '17', ], 'color' => [ 'green', ], 'pets' => ".
		"[ 'Cat', 'Bird', ], }, ";
	result( $did eq $should, "ign-case from 0 to 0; fetch_all() returns '$did'" );
	
	# convert from false to true

	$mvh = Data::MultiValuedHash->new( 0, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} ); 
	$mvh->ignores_case( 1 );
	
	$did = $mvh->ignores_case();
	result( $did == 1, "ign-case from 0 to 1; ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all() ) );
	$should = "{ 'age' => [ '17', ], 'color' => [ 'green', ], ".
		"'name' => [ 'John', ], 'pets' => [ 'Cat', 'Bird', ], ".
		"'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "ign-case from 0 to 1; fetch_all() returns '$did'" );
	
	# convert from true to false

	$mvh = Data::MultiValuedHash->new( 1, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} ); 
	$mvh->ignores_case( 0 );
	
	$did = $mvh->ignores_case();
	result( $did == 0, "ign-case from 1 to 0; ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all() ) );
	$should = "{ 'age' => [ '17', ], 'color' => [ 'green', ], ".
		"'name' => [ 'John', ], 'pets' => [ 'Cat', 'Bird', ], ".
		"'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "ign-case from 1 to 0; fetch_all() returns '$did'" );
	
	# convert from true to true

	$mvh = Data::MultiValuedHash->new( 1, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} ); 
	$mvh->ignores_case( 1 );
	
	$did = $mvh->ignores_case();
	result( $did == 1, "ign-case from 1 to 1; ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all() ) );
	$should = "{ 'age' => [ '17', ], 'color' => [ 'green', ], ".
		"'name' => [ 'John', ], 'pets' => [ 'Cat', 'Bird', ], ".
		"'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "ign-case from 1 to 1; fetch_all() returns '$did'" );
}

######################################################################
# test read-only methods on case-sensitive MVH

{
	message( "testing read-only methods on case-sensitive MVH" );

	my ($mvh, $did, $should);
	
	# first initialize data we will be reading from
	
	$mvh = Data::MultiValuedHash->new( 0, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} ); 

	# now we do keys(), values(), and the like

	$did = serialize( [ sort $mvh->keys() ] );
	$should = "[ 'Name', 'Siblings', 'age', 'color', 'pets', ], ";
	result( $did eq $should, "sort keys() returns '$did'" );

	$did = serialize( scalar( $mvh->keys_count() ) );
	$should = "'5', ";
	result( $did eq $should, "keys_count() returns '$did'" );

	$did = serialize( [ sort $mvh->values() ] );
	$should = "[ '17', 'Andrew', 'Bird', 'Cat', 'John', 'Julia', 'Laura', 'green', ], ";
	result( $did eq $should, "sort values() returns '$did'" );

	$did = serialize( scalar( $mvh->values_count() ) );
	$should = "'8', ";
	result( $did eq $should, "values_count() returns '$did'" );

	# now we do exists()

	$did = serialize( scalar( $mvh->exists() ) );
	$should = "'', ";
	result( $did eq $should, "exists() returns '$did'" );

	$did = serialize( scalar( $mvh->exists( 'name' ) ) );
	$should = "'', ";
	result( $did eq $should, "exists( 'name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->exists( 'Name' ) ) );
	$should = "'1', ";
	result( $did eq $should, "exists( 'Name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->exists( 'color' ) ) );
	$should = "'1', ";
	result( $did eq $should, "exists( 'color' ) returns '$did'" );

	$did = serialize( scalar( $mvh->exists( 'Color' ) ) );
	$should = "'', ";
	result( $did eq $should, "exists( 'Color' ) returns '$did'" );

	# now we do count()

	$did = serialize( scalar( $mvh->count() ) );
	$should = "undef, ";
	result( $did eq $should, "count() returns '$did'" );

	$did = serialize( scalar( $mvh->count( 'name' ) ) );
	$should = "undef, ";
	result( $did eq $should, "count( 'name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->count( 'age' ) ) );
	$should = "'1', ";
	result( $did eq $should, "count( 'age' ) returns '$did'" );

	$did = serialize( scalar( $mvh->count( 'pets' ) ) );
	$should = "'2', ";
	result( $did eq $should, "count( 'pets' ) returns '$did'" );

	# now we do fetch_value()

	$did = serialize( scalar( $mvh->fetch_value() ) );
	$should = "undef, ";
	result( $did eq $should, "fetch_value() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'name' ) ) );
	$should = "undef, ";
	result( $did eq $should, "fetch_value( 'name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'age' ) ) );
	$should = "'17', ";
	result( $did eq $should, "fetch_value( 'age' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'Siblings' ) ) );
	$should = "'Laura', ";
	result( $did eq $should, "fetch_value( 'Siblings' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'age', 0 ) ) );
	$should = "'17', ";
	result( $did eq $should, "fetch_value( 'age', 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'Siblings', 0 ) ) );
	$should = "'Laura', ";
	result( $did eq $should, "fetch_value( 'Siblings', 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'age', 1 ) ) );
	$should = "undef, ";
	result( $did eq $should, "fetch_value( 'age', 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'Siblings', 1 ) ) );
	$should = "'Andrew', ";
	result( $did eq $should, "fetch_value( 'Siblings', 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'age', -1 ) ) );
	$should = "'17', ";
	result( $did eq $should, "fetch_value( 'age', -1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'Siblings', -1 ) ) );
	$should = "'Julia', ";
	result( $did eq $should, "fetch_value( 'Siblings', -1 ) returns '$did'" );

	# now we do fetch()

	$did = serialize( scalar( $mvh->fetch() ) );
	$should = "undef, ";
	result( $did eq $should, "fetch() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'name' ) ) );
	$should = "undef, ";
	result( $did eq $should, "fetch( 'name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'age' ) ) );
	$should = "[ '17', ], ";
	result( $did eq $should, "fetch( 'age' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Siblings' ) ) );
	$should = "[ 'Laura', 'Andrew', 'Julia', ], ";
	result( $did eq $should, "fetch( 'Siblings' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'age', 0 ) ) );
	$should = "[ '17', ], ";
	result( $did eq $should, "fetch( 'age', 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Siblings', 0 ) ) );
	$should = "[ 'Laura', ], ";
	result( $did eq $should, "fetch( 'Siblings', 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'age', 1 ) ) );
	$should = "[ undef, ], ";
	result( $did eq $should, "fetch( 'age', 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Siblings', 1 ) ) );
	$should = "[ 'Andrew', ], ";
	result( $did eq $should, "fetch( 'Siblings', 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'age', -1 ) ) );
	$should = "[ '17', ], ";
	result( $did eq $should, "fetch( 'age', -1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Siblings', -1 ) ) );
	$should = "[ 'Julia', ], ";
	result( $did eq $should, "fetch( 'Siblings', -1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'age', [0..1] ) ) );
	$should = "[ '17', undef, ], ";
	result( $did eq $should, "fetch( 'age', [0..1] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Siblings', [0..1] ) ) );
	$should = "[ 'Laura', 'Andrew', ], ";
	result( $did eq $should, "fetch( 'Siblings', [0..1] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Siblings', [1..4] ) ) );
	$should = "[ 'Andrew', 'Julia', undef, undef, ], ";
	result( $did eq $should, "fetch( 'Siblings', [1..4] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Siblings', [-1,1] ) ) );
	$should = "[ 'Julia', 'Andrew', ], ";
	result( $did eq $should, "fetch( 'Siblings', [-1,1] ) returns '$did'" );
	
	# now we do fetch_hash()

	$did = serialize( scalar( $mvh->fetch_hash() ) );
	$should = "{ 'Name' => 'John', 'Siblings' => 'Laura', 'age' => '17', 'color' => 'green', 'pets' => 'Cat', }, ";
	result( $did eq $should, "fetch_hash() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_hash( 0 ) ) );
	$should = "{ 'Name' => 'John', 'Siblings' => 'Laura', 'age' => '17', 'color' => 'green', 'pets' => 'Cat', }, ";
	result( $did eq $should, "fetch_hash( 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_hash( 1 ) ) );
	$should = "{ 'Name' => undef, 'Siblings' => 'Andrew', 'age' => undef, 'color' => undef, 'pets' => 'Bird', }, ";
	result( $did eq $should, "fetch_hash( 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_hash( 2 ) ) );
	$should = "{ 'Name' => undef, 'Siblings' => 'Julia', 'age' => undef, 'color' => undef, 'pets' => undef, }, ";
	result( $did eq $should, "fetch_hash( 2 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_hash( 3 ) ) );
	$should = "{ 'Name' => undef, 'Siblings' => undef, 'age' => undef, 'color' => undef, 'pets' => undef, }, ";
	result( $did eq $should, "fetch_hash( 3 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_hash( -1 ) ) );
	$should = "{ 'Name' => 'John', 'Siblings' => 'Julia', 'age' => '17', 'color' => 'green', 'pets' => 'Bird', }, ";
	result( $did eq $should, "fetch_hash( -1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_hash( undef, ['age','pets'] ) ) );
	$should = "{ 'age' => '17', 'pets' => 'Cat', }, ";
	result( $did eq $should, "fetch_hash( undef, ['age','pets'] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_hash( 1, ['age','Siblings'] ) ) );
	$should = "{ 'Siblings' => 'Andrew', 'age' => undef, }, ";
	result( $did eq $should, "fetch_hash( 1, ['age','Siblings'] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_hash( undef, ['age','pets'], 1 ) ) );
	$should = "{ 'Name' => 'John', 'Siblings' => 'Laura', 'color' => 'green', }, ";
	result( $did eq $should, "fetch_hash( undef, ['age','pets'], 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_hash( 1, ['age','Siblings'], 1 ) ) );
	$should = "{ 'Name' => undef, 'color' => undef, 'pets' => 'Bird', }, ";
	result( $did eq $should, "fetch_hash( 1, ['age','Siblings'], 1 ) returns '$did'" );

	# now we do fetch_first()

	$did = serialize( scalar( $mvh->fetch_first() ) );
	$should = "{ 'Name' => 'John', 'Siblings' => 'Laura', 'age' => '17', 'color' => 'green', 'pets' => 'Cat', }, ";
	result( $did eq $should, "fetch_first() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_first( ['age','Siblings'] ) ) );
	$should = "{ 'Siblings' => 'Laura', 'age' => '17', }, ";
	result( $did eq $should, "fetch_first( ['age','Siblings'] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_first( ['age','Siblings'], 1 ) ) );
	$should = "{ 'Name' => 'John', 'color' => 'green', 'pets' => 'Cat', }, ";
	result( $did eq $should, "fetch_first( ['age','Siblings'], 1 ) returns '$did'" );

	# now we do fetch_last()

	$did = serialize( scalar( $mvh->fetch_last() ) );
	$should = "{ 'Name' => 'John', 'Siblings' => 'Julia', 'age' => '17', 'color' => 'green', 'pets' => 'Bird', }, ";
	result( $did eq $should, "fetch_last() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_last( ['age','Siblings'] ) ) );
	$should = "{ 'Siblings' => 'Julia', 'age' => '17', }, ";
	result( $did eq $should, "fetch_last( ['age','Siblings'] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_last( ['age','Siblings'], 1 ) ) );
	$should = "{ 'Name' => 'John', 'color' => 'green', 'pets' => 'Bird', }, ";
	result( $did eq $should, "fetch_last( ['age','Siblings'], 1 ) returns '$did'" );
	
	# now we do fetch_all()
	
	$did = serialize( scalar( $mvh->fetch_all() ) );
	$should = "{ 'Name' => [ 'John', ], 'Siblings' => [ 'Laura', 'Andrew', 'Julia', ], 'age' => [ '17', ], 'color' => [ 'green', ], 'pets' => [ 'Cat', 'Bird', ], }, ";
	result( $did eq $should, "fetch_all() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( undef, undef, 0 ) ) );
	$should = "{ 'Name' => [ 'John', ], 'Siblings' => [ 'Laura', ], 'age' => [ '17', ], 'color' => [ 'green', ], 'pets' => [ 'Cat', ], }, ";
	result( $did eq $should, "fetch_all( undef, undef, 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( undef, undef, 1 ) ) );
	$should = "{ 'Name' => [ undef, ], 'Siblings' => [ 'Andrew', ], 'age' => [ undef, ], 'color' => [ undef, ], 'pets' => [ 'Bird', ], }, ";
	result( $did eq $should, "fetch_all( undef, undef, 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( undef, undef, 2 ) ) );
	$should = "{ 'Name' => [ undef, ], 'Siblings' => [ 'Julia', ], 'age' => [ undef, ], 'color' => [ undef, ], 'pets' => [ undef, ], }, ";
	result( $did eq $should, "fetch_all( undef, undef, 2 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( undef, undef, 3 ) ) );
	$should = "{ 'Name' => [ undef, ], 'Siblings' => [ undef, ], 'age' => [ undef, ], 'color' => [ undef, ], 'pets' => [ undef, ], }, ";
	result( $did eq $should, "fetch_all( undef, undef, 3 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( undef, undef, -1 ) ) );
	$should = "{ 'Name' => [ 'John', ], 'Siblings' => [ 'Julia', ], 'age' => [ '17', ], 'color' => [ 'green', ], 'pets' => [ 'Bird', ], }, ";
	result( $did eq $should, "fetch_all( undef, undef, -1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['age','pets'], undef, 0 ) ) );
	$should = "{ 'age' => [ '17', ], 'pets' => [ 'Cat', ], }, ";
	result( $did eq $should, "fetch_all( ['age','pets'], undef, 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['age','Siblings'], undef, 1 ) ) );
	$should = "{ 'Siblings' => [ 'Andrew', ], 'age' => [ undef, ], }, ";
	result( $did eq $should, "fetch_all( ['age','Siblings'], undef, 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['age','pets'], 1, 0 ) ) );
	$should = "{ 'Name' => [ 'John', ], 'Siblings' => [ 'Laura', ], 'color' => [ 'green', ], }, ";
	result( $did eq $should, "fetch_all( ['age','pets'], 1, 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['age','Siblings'], 1, 1 ) ) );
	$should = "{ 'Name' => [ undef, ], 'color' => [ undef, ], 'pets' => [ 'Bird', ], }, ";
	result( $did eq $should, "fetch_all( ['age','Siblings'], 1, 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'name' ) ) );
	$should = "{ }, ";
	result( $did eq $should, "fetch_all( 'name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'age' ) ) );
	$should = "{ 'age' => [ '17', ], }, ";
	result( $did eq $should, "fetch_all( 'age' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'Siblings' ) ) );
	$should = "{ 'Siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "fetch_all( 'Siblings' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'age', undef, 0 ) ) );
	$should = "{ 'age' => [ '17', ], }, ";
	result( $did eq $should, "fetch_all( 'age', undef, 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'Siblings', undef, 0 ) ) );
	$should = "{ 'Siblings' => [ 'Laura', ], }, ";
	result( $did eq $should, "fetch_all( 'Siblings', undef, 0 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'age', undef, 1 ) ) );
	$should = "{ 'age' => [ undef, ], }, ";
	result( $did eq $should, "fetch_all( 'age', undef, 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'Siblings', undef, 1 ) ) );
	$should = "{ 'Siblings' => [ 'Andrew', ], }, ";
	result( $did eq $should, "fetch_all( 'Siblings', undef, 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'age', undef, -1 ) ) );
	$should = "{ 'age' => [ '17', ], }, ";
	result( $did eq $should, "fetch_all( 'age', undef, -1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'Siblings', undef, -1 ) ) );
	$should = "{ 'Siblings' => [ 'Julia', ], }, ";
	result( $did eq $should, "fetch_all( 'Siblings', undef, -1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'age', undef, [0..1] ) ) );
	$should = "{ 'age' => [ '17', undef, ], }, ";
	result( $did eq $should, "fetch_all( 'age', undef, [0..1] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'Siblings', undef, [0..1] ) ) );
	$should = "{ 'Siblings' => [ 'Laura', 'Andrew', ], }, ";
	result( $did eq $should, "fetch_all( 'Siblings', undef, [0..1] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'Siblings', undef, [1..4] ) ) );
	$should = "{ 'Siblings' => [ 'Andrew', 'Julia', undef, undef, ], }, ";
	result( $did eq $should, "fetch_all( 'Siblings', undef, [1..4] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( 'Siblings', undef, [-1,1] ) ) );
	$should = "{ 'Siblings' => [ 'Julia', 'Andrew', ], }, ";
	result( $did eq $should, "fetch_all( 'Siblings', undef, [-1,1] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['Siblings','pets'], undef, [-1,1] ) ) );
	$should = "{ 'Siblings' => [ 'Julia', 'Andrew', ], 'pets' => [ 'Bird', 'Bird', ], }, ";
	result( $did eq $should, "fetch_all( ['Siblings','pets'], undef, [-1,1] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['Name','Siblings','pets'], 1, [-1,1] ) ) );
	$should = "{ 'age' => [ '17', undef, ], 'color' => [ 'green', undef, ], }, ";
	result( $did eq $should, "fetch_all( ['Name','Siblings','pets'], 1, [-1,1] ) returns '$did'" );
	
	

}

######################################################################
# test read-only methods on case-insensitive MVH

{
	message( "testing read-only methods on case-insensitive MVH" );

	my ($mvh, $did, $should);
	
	# first initialize data we will be reading from
	
	$mvh = Data::MultiValuedHash->new( 1, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} ); 

	# now we do keys(), values(), and the like

	$did = serialize( [ sort $mvh->keys() ] );
	$should = "[ 'age', 'color', 'name', 'pets', 'siblings', ], ";
	result( $did eq $should, "sort keys() returns '$did'" );

	$did = serialize( scalar( $mvh->keys_count() ) );
	$should = "'5', ";
	result( $did eq $should, "keys_count() returns '$did'" );

	$did = serialize( [ sort $mvh->values() ] );
	$should = "[ '17', 'Andrew', 'Bird', 'Cat', 'John', 'Julia', 'Laura', 'green', ], ";
	result( $did eq $should, "sort values() returns '$did'" );

	$did = serialize( scalar( $mvh->values_count() ) );
	$should = "'8', ";
	result( $did eq $should, "values_count() returns '$did'" );

	# now we do exists()

	$did = serialize( scalar( $mvh->exists( 'name' ) ) );
	$should = "'1', ";
	result( $did eq $should, "exists( 'name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->exists( 'Name' ) ) );
	$should = "'1', ";
	result( $did eq $should, "exists( 'Name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->exists( 'color' ) ) );
	$should = "'1', ";
	result( $did eq $should, "exists( 'color' ) returns '$did'" );

	$did = serialize( scalar( $mvh->exists( 'Color' ) ) );
	$should = "'1', ";
	result( $did eq $should, "exists( 'Color' ) returns '$did'" );

	# now we do fetch_value()

	$did = serialize( scalar( $mvh->fetch_value( 'name' ) ) );
	$should = "'John', ";
	result( $did eq $should, "fetch_value( 'name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'age' ) ) );
	$should = "'17', ";
	result( $did eq $should, "fetch_value( 'age' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'Siblings' ) ) );
	$should = "'Laura', ";
	result( $did eq $should, "fetch_value( 'Siblings' ) returns '$did'" );

	# now we do fetch()

	$did = serialize( scalar( $mvh->fetch( 'name' ) ) );
	$should = "[ 'John', ], ";
	result( $did eq $should, "fetch( 'name' ) returns '$did'" );

	# now we do fetch_hash()

	$did = serialize( scalar( $mvh->fetch_hash() ) );
	$should = "{ 'age' => '17', 'color' => 'green', 'name' => 'John', 'pets' => 'Cat', 'siblings' => 'Laura', }, ";
	result( $did eq $should, "fetch_hash() returns '$did'" );

	# now we do fetch_first()

	$did = serialize( scalar( $mvh->fetch_first( ['age','Siblings'] ) ) );
	$should = "{ 'age' => '17', 'siblings' => 'Laura', }, ";
	result( $did eq $should, "fetch_first( ['age','Siblings'] ) returns '$did'" );

	# now we do fetch_last()

	$did = serialize( scalar( $mvh->fetch_last( ['age','Siblings'], 1 ) ) );
	$should = "{ 'color' => 'green', 'name' => 'John', 'pets' => 'Bird', }, ";
	result( $did eq $should, "fetch_last( ['age','Siblings'], 1 ) returns '$did'" );
	
	# now we do fetch_all()
	
	$did = serialize( scalar( $mvh->fetch_all() ) );
	$should = "{ 'age' => [ '17', ], 'color' => [ 'green', ], 'name' => [ 'John', ], 'pets' => [ 'Cat', 'Bird', ], 'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "fetch_all() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['Siblings','pets'], undef, [-1,1] ) ) );
	$should = "{ 'pets' => [ 'Bird', 'Bird', ], 'siblings' => [ 'Julia', 'Andrew', ], }, ";
	result( $did eq $should, "fetch_all( ['Siblings','pets'], undef, [-1,1] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['Name','Siblings','pets'], 1, [-1,1] ) ) );
	$should = "{ 'age' => [ '17', undef, ], 'color' => [ 'green', undef, ], }, ";
	result( $did eq $should, "fetch_all( ['Name','Siblings','pets'], 1, [-1,1] ) returns '$did'" );
}
	
######################################################################
# test fetch_mvh()

{
	message( "testing fetch_mvh()" );

	my ($mvh1, $mvh2, $mvh3, $did, $should);
	
	$mvh1 = Data::MultiValuedHash->new( 1, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} ); 

	# first, emulate clone()

	$mvh2 = $mvh1->fetch_mvh();
	result( UNIVERSAL::isa( $mvh2, "Data::MultiValuedHash" ), 
		"mvh2 = mvh1->fetch_mvh() ret MVH obj" );

	$did = $mvh2->ignores_case();
	result( $did == 1, "on fetch_mvh mvh2->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh2->fetch_all() ) );
	$should = "{ 'age' => [ '17', ], 'color' => [ 'green', ], ".
		"'name' => [ 'John', ], 'pets' => [ 'Cat', 'Bird', ], ".
		"'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "on fetch_mvh mvh2->fetch_all() returns '$did'" );

	# then try a subset

	$mvh3 = $mvh1->fetch_mvh( ['name','siblings'] );
	result( UNIVERSAL::isa( $mvh3, "Data::MultiValuedHash" ), 
		"mvh3 = mvh1->fetch_mvh( ['name','siblings'] ) ret MVH obj" );

	$did = $mvh3->ignores_case();
	result( $did == 1, "on fetch_mvh mvh3->ignores_case() returns '$did'" );

	$did = serialize( scalar( $mvh3->fetch_all() ) );
	$should = "{ 'name' => [ 'John', ], 'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ";
	result( $did eq $should, "on fetch_mvh mvh3->fetch_all() returns '$did'" );
}
	
######################################################################
# test altering methods like store()

{
	message( "testing altering methods like store()" );

	my ($mvh, $did, $should);
	
	# first initialize data we will be reading from
	
	$mvh = Data::MultiValuedHash->new( 0, {
		Name => 'John',
		age => 17,
		color => 'green',
		Siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} ); 

	# now we do store_value()

	$did = $mvh->store_value( 'pets', 'turtle' );
	result( $did == 2, "store_value( 'pets', 'turtle' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'pets' ) ) );
	$should = "'turtle', ";
	result( $did eq $should, "fetch_value( 'pets' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'pets' ) ) );
	$should = "[ 'turtle', 'Bird', ], ";
	result( $did eq $should, "fetch( 'pets' ) returns '$did'" );

	$did = $mvh->store_value( 'pets', 'rabbit', 1 );
	result( $did == 2, "store_value( 'pets', 'rabbit', 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_value( 'pets', 1 ) ) );
	$should = "'rabbit', ";
	result( $did eq $should, "fetch_value( 'pets', 1 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'pets' ) ) );
	$should = "[ 'turtle', 'rabbit', ], ";
	result( $did eq $should, "fetch( 'pets' ) returns '$did'" );

	# now we do store()

	$did = $mvh->store( 'age', 18 );
	result( $did == 1, "store( 'age', 18 ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'age' ) ) );
	$should = "[ '18', ], ";
	result( $did eq $should, "fetch( 'age' ) returns '$did'" );

	$did = $mvh->store( 'Name', [] );
	result( $did == 0, "store( 'Name', [] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Name' ) ) );
	$should = "[ ], ";
	result( $did eq $should, "fetch( 'Name' ) returns '$did'" );

	$did = $mvh->store( 'Name', [ 'John', 'Reese' ] );
	result( $did == 2, "store( 'Name', [ 'John', 'Reese', ] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Name' ) ) );
	$should = "[ 'John', 'Reese', ], ";
	result( $did eq $should, "fetch( 'Name' ) returns '$did'" );

	$did = $mvh->store( 'Name', 'John', 'Glenn' );
	result( $did == 2, "store( 'Name', 'John', 'Glenn' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Name' ) ) );
	$should = "[ 'John', 'Glenn', ], ";
	result( $did eq $should, "fetch( 'Name' ) returns '$did'" );
	
	# now we do store_all()

	$did = $mvh->store_all( {
		songs => ['here','we','go'],
		pets => 'Lobster',
	} );
	result( $did == 2, "store_all( {songs => ['here','we','go'],".
		"pets => 'Lobster',} ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['songs','pets'] ) ) );
	$should = "{ 'pets' => [ 'Lobster', ], 'songs' => [ 'here', 'we', 'go', ], }, ";
	result( $did eq $should, "fetch_all( ['songs','pets'] ) returns '$did'" );

	$did = $mvh->store_all(
		songs => ['this','that','and the other'],
		pets => 'Fish',
	);
	result( $did == 2, "store_all( songs => ['this','that','and the other'],".
		"pets => 'Fish', ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( ['songs','pets'] ) ) );
	$should = "{ 'pets' => [ 'Fish', ], 'songs' => [ 'this', 'that', 'and the other', ], }, ";
	result( $did eq $should, "fetch_all( ['songs','pets'] ) returns '$did'" );

	$did = $mvh->store_all();
	result( $did == 0, "store_all() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all( [] ) ) );
	$should = "{ }, ";
	result( $did eq $should, "fetch_all( [] ) returns '$did'" );

	# now we do push()

	$did = $mvh->push();
	result( $did == 0, "push() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch() ) );
	$should = "[ ], ";
	result( $did eq $should, "fetch() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( undef ) ) );
	$should = "[ ], ";
	result( $did eq $should, "fetch( undef ) returns '$did'" );

	$did = $mvh->push( 'Siblings' );
	result( $did == 3, "push( 'Siblings' ) returns '$did'" );

	$did = $mvh->push( 'Siblings', [] );
	result( $did == 3, "push( 'Siblings', [] ) returns '$did'" );

	$did = $mvh->push( 'Siblings', 'Tandy' );
	result( $did == 4, "push( 'Siblings', 'Tandy' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Siblings' ) ) );
	$should = "[ 'Laura', 'Andrew', 'Julia', 'Tandy', ], ";
	result( $did eq $should, "fetch( 'Siblings' ) returns '$did'" );

	$did = $mvh->push( 'Siblings', ['Adam','Jessie'] );
	result( $did == 6, "push( 'Siblings', ['Adam','Jessie'] ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'Siblings' ) ) );
	$should = "[ 'Laura', 'Andrew', 'Julia', 'Tandy', 'Adam', 'Jessie', ], ";
	result( $did eq $should, "fetch( 'Siblings' ) returns '$did'" );
	
	# now we do unshift()

	$did = $mvh->unshift( 'pets', 'Dog', 'Hamster' );
	result( $did == 3, "unshift( 'pets', 'Dog', 'Hamster' ) returns '$did'" );

	$did = serialize( scalar( $mvh->fetch( 'pets' ) ) );
	$should = "[ 'Dog', 'Hamster', 'Fish', ], ";
	result( $did eq $should, "fetch( 'pets' ) returns '$did'" );
	
	# now we do pop()

	$did = serialize( scalar( $mvh->pop( 'pets' ) ) );
	$should = "'Fish', ";
	result( $did eq $should, "pop( 'pets' ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'pets' ) ) );
	$should = "[ 'Dog', 'Hamster', ], ";
	result( $did eq $should, "fetch( 'pets' ) returns '$did'" );

	$did = serialize( scalar( $mvh->pop( 'Pets' ) ) );
	$should = "undef, ";
	result( $did eq $should, "pop( 'Pets' ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'Pets' ) ) );
	$should = "undef, ";
	result( $did eq $should, "fetch( 'Pets' ) returns '$did'" );
	
	# now we do shift()

	$did = serialize( scalar( $mvh->shift( 'color' ) ) );
	$should = "'green', ";
	result( $did eq $should, "shift( 'color' ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'color' ) ) );
	$should = "[ ], ";
	result( $did eq $should, "fetch( 'color' ) returns '$did'" );

	$did = serialize( scalar( $mvh->shift( 'color' ) ) );
	$should = "undef, ";
	result( $did eq $should, "shift( 'color' ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'color' ) ) );
	$should = "[ ], ";
	result( $did eq $should, "fetch( 'color' ) returns '$did'" );
	
	# now we do splice()

	$did = serialize( scalar( $mvh->splice( 'Siblings', 0, 1 ) ) );
	$should = "[ 'Laura', ], ";
	result( $did eq $should, "splice( 'Siblings', 0, 1 ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'Siblings' ) ) );
	$should = "[ 'Andrew', 'Julia', 'Tandy', 'Adam', 'Jessie', ], ";
	result( $did eq $should, "fetch( 'Siblings' ) returns '$did'" );

	$did = serialize( scalar( $mvh->splice( 'Siblings', 3, 1, 'Evette' ) ) );
	$should = "[ 'Adam', ], ";
	result( $did eq $should, "splice( 'Siblings', 3, 1, 'Evette' ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'Siblings' ) ) );
	$should = "[ 'Andrew', 'Julia', 'Tandy', 'Evette', 'Jessie', ], ";
	result( $did eq $should, "fetch( 'Siblings' ) returns '$did'" );

	$did = serialize( scalar( $mvh->splice( 'Siblings', 3, 0, ['James'] ) ) );
	$should = "[ ], ";
	result( $did eq $should, "splice( 'Siblings', 3, 0, ['James'] ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'Siblings' ) ) );
	$should = "[ 'Andrew', 'Julia', 'Tandy', 'James', 'Evette', 'Jessie', ], ";
	result( $did eq $should, "fetch( 'Siblings' ) returns '$did'" );

	$did = serialize( scalar( $mvh->splice( 'Siblings', -1 ) ) );
	$should = "[ 'Jessie', ], ";
	result( $did eq $should, "splice( 'Siblings', -1 ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'Siblings' ) ) );
	$should = "[ 'Andrew', 'Julia', 'Tandy', 'James', 'Evette', ], ";
	result( $did eq $should, "fetch( 'Siblings' ) returns '$did'" );

	$did = serialize( scalar( $mvh->splice( 'Siblings', 3 ) ) );
	$should = "[ 'James', 'Evette', ], ";
	result( $did eq $should, "splice( 'Siblings', 3 ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'Siblings' ) ) );
	$should = "[ 'Andrew', 'Julia', 'Tandy', ], ";
	result( $did eq $should, "fetch( 'Siblings' ) returns '$did'" );

	$did = serialize( scalar( $mvh->splice( 'Siblings' ) ) );
	$should = "[ 'Andrew', 'Julia', 'Tandy', ], ";
	result( $did eq $should, "splice( 'Siblings' ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'Siblings' ) ) );
	$should = "[ ], ";
	result( $did eq $should, "fetch( 'Siblings' ) returns '$did'" );

	# now we do delete()

	$did = serialize( scalar( $mvh->delete( 'Name' ) ) );
	$should = "[ 'John', 'Glenn', ], ";
	result( $did eq $should, "delete( 'Name' ) returns '$did'" );
	
	$did = serialize( scalar( $mvh->fetch( 'Name' ) ) );
	$should = "undef, ";
	result( $did eq $should, "fetch( 'Name' ) returns '$did'" );

	$did = serialize( scalar( $mvh->delete( 'Name' ) ) );
	$should = "undef, ";
	result( $did eq $should, "delete( 'Name' ) returns '$did'" );

	# now we do delete_all()

	$did = serialize( scalar( $mvh->delete_all() ) );
	$should = "{ '' => [ ], 'Siblings' => [ ], 'age' => [ '18', ], 'color' => [ ], 'pets' => [ 'Dog', 'Hamster', ], 'songs' => [ 'this', 'that', 'and the other', ], }, ";
	result( $did eq $should, "delete_all() returns '$did'" );

	$did = serialize( scalar( $mvh->fetch_all() ) );
	$should = "{ }, ";
	result( $did eq $should, "fetch_all() returns '$did'" );

	$did = serialize( scalar( $mvh->delete_all() ) );
	$should = "{ }, ";
	result( $did eq $should, "delete_all() returns '$did'" );
}

######################################################################
# testing batch_new()

{
	message( "testing batch_new()" );

	my ($mvh, $did, $should);

	my @sources = (
		'',
		[],
		{},
		{ name => 'Don Smith' },
		Data::MultiValuedHash->new( 1, {
			Name => 'John',
			age => 17,
			color => 'green',
			Siblings => ['Laura', 'Andrew', 'Julia'],
			pets => ['Cat', 'Bird'],
		} ),
		{
			visible_title => "What's your name?",
			type => 'textfield',
			name => 'name',
		}, {
			visible_title => "What's the combination?",
			type => 'checkbox_group',
			name => 'words',
			'values' => ['eenie', 'meenie', 'minie', 'moe'],
			default => ['eenie', 'minie'],
		}, {
			visible_title => "What's your favorite colour?",
			type => 'popup_menu',
			name => 'color',
			'values' => ['red', 'green', 'blue', 'chartreuse'],
		}, {
			type => 'submit', 
		},	
	);
	result( @sources == 9, "there are @{[scalar(@sources)]} source records" );

	my @mvh_list = Data::MultiValuedHash->batch_new( 0, \@sources );
	result( @mvh_list == 9, "there are @{[scalar(@mvh_list)]} new objects" );
	
	my @expected = (
		"{ }, ",
		"{ }, ",
		"{ }, ",
		"{ 'name' => [ 'Don Smith', ], }, ",
		"{ 'age' => [ '17', ], 'color' => [ 'green', ], 'name' => [ 'John', ], 'pets' => [ 'Cat', 'Bird', ], 'siblings' => [ 'Laura', 'Andrew', 'Julia', ], }, ",
		"{ 'name' => [ 'name', ], 'type' => [ 'textfield', ], 'visible_title' => [ 'What's your name?', ], }, ",
		"{ 'default' => [ 'eenie', 'minie', ], 'name' => [ 'words', ], 'type' => [ 'checkbox_group', ], 'values' => [ 'eenie', 'meenie', 'minie', 'moe', ], 'visible_title' => [ 'What's the combination?', ], }, ",
		"{ 'name' => [ 'color', ], 'type' => [ 'popup_menu', ], 'values' => [ 'red', 'green', 'blue', 'chartreuse', ], 'visible_title' => [ 'What's your favorite colour?', ], }, ",
		"{ 'type' => [ 'submit', ], }, ",
	);

	foreach my $i (0..$#mvh_list) {
		$mvh = $mvh_list[$i];
		
		$did = UNIVERSAL::isa( $mvh, "Data::MultiValuedHash" );
		result( $did, "new object $i is an MVH object" );

		if( $did ) {
			$did = $mvh->ignores_case();
			result( $did == 0, "mvh$i->ignores_case() returns '$did'" );

			$did = serialize( scalar( $mvh->fetch_all() ) );
			$should = $expected[$i];
			result( $did eq $should, "mvh$i->fetch_all() returns '$did'" );
		}
	}
}

######################################################################

message( "DONE TESTING Data::MultiValuedHash" );

######################################################################

1;
