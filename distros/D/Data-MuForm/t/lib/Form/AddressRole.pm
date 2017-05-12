package Form::AddressRole;

use Moo::Role;
use Data::MuForm::Meta;

has_field 'street';
has_field 'city';
has_field 'state';
has_field 'zip';

1;
