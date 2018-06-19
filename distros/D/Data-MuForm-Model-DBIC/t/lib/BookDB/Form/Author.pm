package BookDB::Form::Author;

use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm::Model::DBIC';

has '+model_class' => ( default => 'Author' );

has_field 'last_name' => ( type => 'Text', required => 1 );
has_field 'first_name' => ( type => 'Text', required => 1 );
has_field 'country' => ( type => 'Text' );
has_field 'birthdate' => ( type => 'Date' );
has_field 'books' => ( type => 'Repeatable' );
has_field 'books.contains' => ( type => '+BookDB::Form::Field::Book' );

1;
