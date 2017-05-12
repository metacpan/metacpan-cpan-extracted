package A::Schema::Result::Artist;

use A::Schema::Candy;

table 'artists';

primary_column id => {
   data_type => 'int',
   is_auto_increment => 1,
};

has_column name => (
   data_type => 'varchar',
   size => 25,
   is_nullable => 1,
);

has_many albums => 'A::Schema::Result::Album', 'artist_id';

1;

