use 5.20.0;
use strict;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::Result::Book;

our $VERSION = '0.0001';

use TestFor::DBIx::Class::Smooth::Schema::Result;
use DBIx::Class::Smooth::Fields -all;

primary id => IntegerField(auto_increment => 1);
    col title => VarcharField(size => 150, indexed => 1);
    col published_date => DateField();

1;
