package TestApp::Schema::Book;

use strict;
use warnings;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
  column name => type is 'text';
  column isbn => type is 'text';
};

1;
