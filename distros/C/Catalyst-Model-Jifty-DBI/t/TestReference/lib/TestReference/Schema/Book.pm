package TestReference::Schema::Book;

use strict;
use warnings;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
  column name   => type is 'text';
  column author => references TestReference::Schema::Author;
};

1;