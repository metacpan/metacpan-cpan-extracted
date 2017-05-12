package Form::Address;

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm';

has_field 'street';
has_field 'city';
has_field 'state';
has_field 'zip';

1;
