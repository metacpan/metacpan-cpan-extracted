{
    package BookDB::Field::BookOwnerAlt;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm::Model::DBIC';

    with 'BookDB::Form::Role::BookOwner';
}

{
    package BookDB::Form::BookWithOwnerAlt;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm::Model::DBIC';

    has '+model_class' => ( default => 'Author' );

    has_field 'title' => ( type => 'Text', required => 1 );
    has_field 'publisher' => ( type => 'Text', required => 1 );
    has_field 'owner' => ( type => '+BookDB::Field::BookOwner' );
}

1;
