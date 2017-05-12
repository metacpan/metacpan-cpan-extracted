package TestCandy::Schema::Result::Tree;
use TestCandy::Schema::Candy;

since '0.003';
renamed_from 'Foo';

primary_column trees_id => {
    data_type         => 'integer',
    is_auto_increment => 1,
    renamed_from      => 'foos_id',
};

column age => { data_type => "integer", is_nullable => 1 };

column width =>
  { data_type => "integer", is_nullable => 0, default_value => 1 };

column bars_id =>
  { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 };

belongs_to bar => 'TestCandy::Schema::Result::Bar', 'bars_id';

1;
