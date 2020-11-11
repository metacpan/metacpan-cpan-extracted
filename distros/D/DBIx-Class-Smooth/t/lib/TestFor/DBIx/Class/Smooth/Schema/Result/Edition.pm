use 5.20.0;
use strict;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::Result::Edition;

our $VERSION = '0.0001';

use TestFor::DBIx::Class::Smooth::Schema::Result;
use DBIx::Class::Smooth::Fields -all;

primary id => IntegerField(auto_increment => 1);
belongs Book => ForeignKey();
belongs Publisher => ForeignKey();
    col year => YearField();

1;
