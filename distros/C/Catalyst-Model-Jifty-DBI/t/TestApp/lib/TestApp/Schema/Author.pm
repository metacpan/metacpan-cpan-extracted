package TestApp::Schema::Author;

use strict;
use warnings;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
  column name    => type is 'text';
  column pauseid => type is 'text';
};

1;
