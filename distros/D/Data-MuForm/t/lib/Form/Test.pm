package Form::Test;

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm';

has '+name' => ( default => 'TestForm');

has_field 'reqname' => ( type => 'Text', required => 1 );
has_field 'optname' => ( type => 'Text' );
has_field 'fruit' => ( type => 'Select' );


sub options_fruit {
    return (
        1   => 'apples',
        2   => 'oranges',
        3   => 'kiwi',
    );
}

1;

