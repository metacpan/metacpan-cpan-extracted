use Test2::V1
  -pragmas,
  -target => { CLASS => 'Class::Enumeration' },
  qw( dies lives ok plan );
use Test::API import => [ qw( public_ok ) ];

plan 7;

public_ok CLASS, qw( name ordinal value_of values names to_string );

ok defined( dies { CLASS->values } ), 'Not implemented';

ok defined( dies { CLASS->_new( 0, '' ) } ), 'The name cannot be empty';

ok defined( dies { CLASS->_new( 0, 'Locked', [] ) } ), 'Wrong custom attributes data structure (Raises FATAL warning)';

for ( qw( name ordinal ) ) {
  ok defined( dies { CLASS->_new( 0, Locked => { $_ => undef } ) } ), "Overriding $_ attribute is forbidden"
}

ok lives { CLASS->_new( 0, BIG => { ounces => 8 } ) }, 'Provide valid custom attributes data structure'
