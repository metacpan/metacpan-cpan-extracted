use 5.20.0;
use strict;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::Result::Publisher;

our $VERSION = '0.0001';

use TestFor::DBIx::Class::Smooth::Schema::Result;
use DBIx::Class::Smooth::Fields -all;

primary id => IntegerField(auto_increment => 1);
    col name => VarcharField();
    col main_office_location => NonNumericField(data_type => 'point', nullable => 1);

1;
