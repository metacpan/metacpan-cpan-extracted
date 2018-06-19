package BookDB::Form::AuthorOld;

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm::Model::DBIC';

has '+model_class' => ( default => 'AuthorOld' );

has_field 'last_name' => ( type => 'Text', required => 1 );
has_field 'first_name' => ( type => 'Text', required => 1 );
has_field 'country' => ( type => 'Text' );
has_field 'birthdate' => ( type => 'DateTime' );
has_field 'foo';
has_field 'bar';

1;
