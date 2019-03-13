use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object::Export qw(data_any);
use Data::Object::Config::Library qw(
  AnyObj
  AnyObject
  Object
);

ok_subtype Object, AnyObj;
ok_subtype Object, AnyObject;

my $data1 = undef;
my $data2 = data_any undef;

should_fail($data1, AnyObj);
should_pass($data2, AnyObj);

should_fail($data1, AnyObject);
should_pass($data2, AnyObject);

ok 1 and done_testing;
