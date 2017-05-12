use strict;
use warnings;
use Test::More;
use Data::Dumper;

use_ok(' Data::MuForm::Field' );

my $field = Data::MuForm::Field->new( name => 'Foo' );

ok($field, 'field built');


{
    package Test::Form::Field::Text;
    use Moo;
    extends 'Data::MuForm::Field';

    has 'cols' => ( is => 'rw' );
    has 'rows' => ( is => 'rw' );
}

$field = Test::Form::Field::Text->new( name => 'Bar' );
ok( $field, 'extended field built' );

done_testing;
