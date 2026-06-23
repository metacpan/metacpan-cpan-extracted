package MyApp::SchemaCake::Result::Track;

use DBIO::Cake;

table 'track';

col trackid => integer, auto_inc;
col cdid    => integer;
col title   => text;

primary_key 'trackid';

unique 'title', 'cdid';

belongs_to cd => 'MyApp::SchemaCake::Result::Cd', 'cdid';

1;
