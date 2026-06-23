package MyApp::SchemaCake::Result::Cd;

use DBIO::Cake;

table 'cd';

col cdid     => integer, auto_inc;
col artistid => integer;
col title    => text;
col year     => datetime, null;

primary_key 'cdid';

unique 'title', 'artistid';

belongs_to artist => 'MyApp::SchemaCake::Result::Artist', 'artistid';
has_many   tracks => 'MyApp::SchemaCake::Result::Track',  'cdid';

1;
