package MyApp::SchemaCandy::Result::Track;

use DBIO::Candy;

table 'track';

column trackid => { data_type => 'integer', is_auto_increment => 1 };
column cdid    => { data_type => 'integer' };
column title   => { data_type => 'text' };

primary_key 'trackid';

unique_constraint [qw(title cdid)];

belongs_to cd => 'MyApp::SchemaCandy::Result::Cd', 'cdid';

1;
