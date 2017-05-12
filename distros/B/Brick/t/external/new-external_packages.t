#!/usr/bin/perl

use Test::More 'no_plan';
use lib qw(t/lib);

my $class = 'Brick';

use_ok( $class );

my $brick = $class->new;
isa_ok( $brick, $class );

my $bucket_class = $brick->bucket_class;
ok( $bucket_class, "Bucket class is defined: $bucket_class" );

my $bucket = $brick->create_bucket;
isa_ok( $bucket, $bucket_class );

ok( defined &{ "${class}::_load_external_packages" }, 
	"_load_external_packages is there" );

ok( defined &{ "${class}::add_validator_packages" }, 
	"add_validator_packages is there" );
	

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
ok( ! defined &{ "${bucket_class}::_is_the_number_3" },
	"_is_the_number_3 is not in $bucket_class"
	);
ok( ! defined &{ "${bucket_class}::_is_the_letter_e" },
	"_is_the_letter_e is not in $bucket_class"
	);
	
ok( ! defined &{ "${bucket_class}::_is_odd" },
	"_is_the_number_3 is not in $bucket_class"
	);
ok( ! defined &{ "${bucket_class}::_is_even" },
	"_is_the_letter_e is not in $bucket_class"
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
$brick = $class->new( {
	external_packages => [ qw(Mock::FooValidator Mock::BarValidator) ],
	} );

ok( defined &{ "${bucket_class}::_is_the_number_3" },
	"_is_the_number_3 is in $bucket_class after add_validator_packages"
	);
isa_ok( $bucket->_is_the_number_3, ref sub {} );	


ok( defined &{ "${bucket_class}::_is_the_letter_e" },
	"_is_the_letter_e is in $bucket_class after add_validator_packages"
	);
isa_ok( $bucket->_is_the_letter_e, ref sub {} );	


ok( defined &{ "${bucket_class}::_is_odd" },
	"_is_odd is not in $bucket_class after add_validator_packages"
	);
isa_ok( $bucket->_is_odd, ref sub {} );	


ok( defined &{ "${bucket_class}::_is_even" },
	"_is_even is not in $bucket_class after add_validator_packages"
	);
isa_ok( $bucket->_is_even, ref sub {} );	
