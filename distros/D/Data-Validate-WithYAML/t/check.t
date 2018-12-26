#!perl 

use strict;
use Test::More;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new( $FindBin::Bin . '/test.yml' );

is $validator->check( 'a_field', '1', { type => 'required' } ), 1;
is $validator->check( 'a_field', '', { type => 'required' } ), 0;
is $validator->check( 'a_field', undef, { type => 'required' } ), 0;

is $validator->check( 'another_field', '1', { type => 'optional' } ), 1;
is $validator->check( 'another_field', '', { type => 'optional' } ), 1;
is $validator->check( 'another_field', undef, { type => 'optional' } ), 1;

done_testing();
