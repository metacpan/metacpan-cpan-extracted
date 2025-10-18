use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT require_ok ) ], tests => 8;
use Test::API import => [ qw( public_ok ) ];
use Test::Fatal qw( dies_ok lives_ok );

my $class;

BEGIN {
  $class = 'Class::Enumeration';
  require_ok $class or BAIL_OUT "Cannot load class '$class'!"
}

public_ok $class, qw( name ordinal value_of values names to_string );

dies_ok { $class->values } 'Not implemented';

dies_ok { $class->_new( 0, '' ) } 'The name cannot be empty';

dies_ok { $class->_new( 0, 'Locked', [] ) } 'Wrong custom attributes data structure (Raises FATAL warning)';

for ( qw( name ordinal ) ) {
  dies_ok { $class->_new( 0, Locked => { $_ => undef } ) } "Overriding $_ attribute is forbidden"
}

lives_ok { $class->_new( 0, BIG => { ounces => 8 } ) } 'Provide valid custom attributes data structure'
