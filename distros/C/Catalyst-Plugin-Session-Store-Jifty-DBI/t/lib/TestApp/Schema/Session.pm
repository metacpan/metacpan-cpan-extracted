package TestApp::Schema::Session;

use strict;
use warnings;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
  column session_id
    => type is 'text', is mandatory, is indexed, is distinct;
  column session_data => type is 'text';
  column expires => type is 'integer';
};

1;
