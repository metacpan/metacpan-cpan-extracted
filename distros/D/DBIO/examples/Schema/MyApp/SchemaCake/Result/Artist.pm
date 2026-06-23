package MyApp::SchemaCake::Result::Artist;

use DBIO::Cake;

table 'artist';

col artistid => integer, auto_inc;
col name     => text;

primary_key 'artistid';

unique 'name';

has_many cds => 'MyApp::SchemaCake::Result::Cd', 'artistid';

1;
