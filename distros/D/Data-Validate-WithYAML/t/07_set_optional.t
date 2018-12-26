#!perl 

use strict;
use Test::More tests => 3;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new( $FindBin::Bin . '/test.yml' );

my $age_required = $validator->check( 'age', undef );
is( $age_required, 0 );

$validator->set_optional( 'age' );

my $age_optional = $validator->check( 'age', undef );
is( $age_optional, 1 );

$validator->set_optional( 'age_virtual' );
$validator->set_optional( 'virtually_created' );

