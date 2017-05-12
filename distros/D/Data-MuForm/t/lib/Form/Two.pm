package Form::Two;

use Moo;
use Data::MuForm::Meta;
extends 'Form::Test';

has '+name' => ( default => 'FormTwo' );
has_field 'new_field' => ( required => 1 );
has_field 'optname' => ( custom => 'Txxt' );
has_field '+reqname' => ( custom => 'Abc' );

1;
