#!perl 

use strict;
use Test::More tests => 3;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new( $FindBin::Bin . '/test.yml' );

my $plz_optional = $validator->check( 'plz', undef );
is( $plz_optional, 1 );

$validator->set_required( 'plz' );

my $plz_required = $validator->check( 'plz', undef );
is( $plz_required, 0 );
