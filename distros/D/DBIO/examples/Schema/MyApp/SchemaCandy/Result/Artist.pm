package MyApp::SchemaCandy::Result::Artist;

use DBIO::Candy;

table 'artist';

column artistid => { data_type => 'integer', is_auto_increment => 1 };
column name     => { data_type => 'text' };

primary_key 'artistid';

unique_constraint [qw(name)];

has_many cds => 'MyApp::SchemaCandy::Result::Cd', 'artistid';

1;
