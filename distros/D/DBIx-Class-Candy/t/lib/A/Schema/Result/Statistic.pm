package A::Schema::Result::Statistic;

use DBIx::Class::Candy -base => 'A::Schema::Result';

table 'statistics';

primary_column song_id => { data_type => 'int' };
primary_column playtime => { data_type => 'int' };

belongs_to song => 'A::Schema::Result::Song', 'song_id';

1;

