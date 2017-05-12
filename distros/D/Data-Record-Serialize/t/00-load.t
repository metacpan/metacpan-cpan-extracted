#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Data::Record::Serialize');
}

diag( "Testing Data::Record::Serialize $Data::Record::Serialize::VERSION, Perl $], $^X" );
