package TestApp::DB::Object;

use base 'Rose::DB::Object';

use TestApp::DB;

sub init_db { TestApp::DB->new }

1;
