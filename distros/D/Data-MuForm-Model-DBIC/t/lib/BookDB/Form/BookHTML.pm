package BookDB::Form::BookHTML;
use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm::Model::DBIC';


has '+model_class' => ( default => 'Book' );
has '+name' => ( default => 'book' );
has '+field_prefix' => ( default => 1 );

sub field_list {
     [
         title     => {
            type => 'Text',
            required => 1,
         },
         author    => 'Text',
         pages     => 'Integer',
         year      => 'Integer',
     ]
}

1;
