package TestReference::Schema::Author;

use strict;
use warnings;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
  column name => type is 'text';
  column books =>
    references TestReference::Schema::BookCollection by 'author';
};

1;
