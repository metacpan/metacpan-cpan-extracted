package Form::PersonRole;

use Moo::Role;
use Data::MuForm::Meta;


has_field 'name';
has_field 'telephone';
has_field 'email';

1;
