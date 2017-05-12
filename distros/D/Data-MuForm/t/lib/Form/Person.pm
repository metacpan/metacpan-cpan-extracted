package Form::Person;

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm';

has_field 'name';
has_field 'telephone';
has_field 'email';

1;
