BEGIN
{
	$| = 1;
	
	use Test::More qw(no_plan);

	#no_plan(); #plan tests => 3 + 3; 

	use_ok( 'Class::Maker', qw(class) );
	use_ok( 'Class::Maker::Exception', qw(:try) );
	use_ok( 'Data::Dumper' );
}

use strict; use warnings;

#######

{
package Test;
	
	Class::Maker::class
	{
		public =>
		{
			debug_verbose => [qw( debug_field )],	
			
			default => [qw( default_field )],
	
			array => [qw( array_field )],
	
			hash => [qw( hash_field )],
		},
	};

	sub _arginit
	{
		::ok( scalar @_, "_arginit for new $_[0] called" );
	}
	
	sub _preinit
	{
		my $this = shift;
		
			$this->debug_field( 123 );
			
			$this->default_field = 123;
	
			$this->array_field( [ 1, 2, 3] );
	
			$this->hash_field( { 1 => 'eins', 2 => 'zwei', 3 => 'drei' } );
	}	
}

can_ok( 
	'Test', 
	
	qw( debug_field default_field array_field hash_field ) 
);

my $obj;

ok( 
   $obj = Test->new, 
   
   'plain Test->new()' 
);

ok( 
   $obj = Test->new( 
		
		debug_field => 1, 
		
		default_field => 2,
		
		array_field => [ 2, 3, 4 ], 
		
		hash_field => { fuenf => 5 },
		), 
   
   'Test->new( with inits )' 
);

diag( Data::Dumper->Dump( [ $obj ] ) );

ok( 
   $obj->default_field == 2, 					
   
   '$obj->default_field == 2' 
);

ok( 
   $obj->default_field eq '2', 				
   
   q{$obj->default_field eq '2'} 
);

is_deeply( 
	[ $obj->array_field ], [ 2, 3, 4 ], 	
	
	'[ $obj->array_field ] is deeply [ 2, 3, 4 ]' 
);

ok( 
	$obj->hash_field->{fuenf} == 5, 			
	
	'$obj->hash_field->{fuenf} == 5' 
);

diag( 'Assignments' );

	$obj->default_field = 3;
	
ok(
	$obj->default_field == 3, 			
	
	'$obj->default_field = 3 (lvalue)'    
);

#is_deeply( [ $obj->hash_field ], [ { fuenf => 5 } ], '$obj->hash_field filled with { fuenf => 5 }' );

#ok( $obj->default_field eq '2', q{$obj->default_field eq '2'} );
