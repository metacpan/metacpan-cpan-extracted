package MyApp::SchemaCandy::Result::Cd;

use DBIO::Candy;

table 'cd';

column cdid     => { data_type => 'integer', is_auto_increment => 1 };
column artistid => { data_type => 'integer' };
column title    => { data_type => 'text' };
column year     => { data_type => 'datetime', is_nullable => 1 };

primary_key 'cdid';

unique_constraint [qw(title artistid)];

belongs_to artist => 'MyApp::SchemaCandy::Result::Artist', 'artistid';
has_many   tracks => 'MyApp::SchemaCandy::Result::Track',  'cdid';

1;
