use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(deduce);
use Data::Object::Library qw(
    IntObj
    IntObject
    IntegerObj
    IntegerObject
    Object
);

ok_subtype Object, IntObj;
ok_subtype Object, IntObject;
ok_subtype Object, IntegerObj;
ok_subtype Object, IntegerObject;

my $data1 = -10;
my $data2 = deduce -10;

should_fail($data1, IntObj);
should_pass($data2, IntObj);

should_fail($data1, IntegerObj);
should_pass($data2, IntegerObj);

should_fail($data1, IntObject);
should_pass($data2, IntObject);

should_fail($data1, IntegerObject);
should_pass($data2, IntegerObject);

ok 1 and done_testing;
