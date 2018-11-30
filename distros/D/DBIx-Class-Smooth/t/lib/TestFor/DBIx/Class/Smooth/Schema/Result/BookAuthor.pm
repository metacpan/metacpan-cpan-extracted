use 5.20.0;
use strict;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::Result::BookAuthor;

our $VERSION = '0.0001';

use TestFor::DBIx::Class::Smooth::Schema::Result;

join_table 'Book', 'Author';

1;
