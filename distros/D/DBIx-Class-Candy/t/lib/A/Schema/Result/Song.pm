package A::Schema::Result::Song;

use DBIx::Class::Candy -base => 'A::Schema::Result';

table 'songs';

column id => {
   data_type => 'int',
   is_auto_increment => 1,
};

column name => {
   data_type => 'varchar',
   size => 25,
   is_nullable => 1,
};

column album_id => {
   data_type => 'int',
   is_nullable => 0,
};

primary_key 'id';

belongs_to album => 'A::Schema::Result::Album', 'album_id';

1;

