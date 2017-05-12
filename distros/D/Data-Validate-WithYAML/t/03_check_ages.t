#!perl 

use strict;
use Test::More tests => 97;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new( $FindBin::Bin . '/test.yml' );

my @ages = (5..17);
is($validator->check('age',$_),0) for(@ages); # too young
@ages = (18..67);
is($validator->check('age',$_),1) for(@ages); # that's ok
@ages = (68..100);
is($validator->check('age',$_),0) for(@ages); # too old
