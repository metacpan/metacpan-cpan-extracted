package Form::MultipleRole;

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm';

with 'Form::PersonRole';
with 'Form::AddressRole';


1;
