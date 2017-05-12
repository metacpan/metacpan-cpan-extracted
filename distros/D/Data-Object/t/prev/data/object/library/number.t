use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(deduce);
use Data::Object::Library qw(
    NumObj
    NumObject
    NumberObj
    NumberObject
    Object
);

ok_subtype Object, NumObj;
ok_subtype Object, NumObject;
ok_subtype Object, NumberObj;
ok_subtype Object, NumberObject;

my $data1 = 10;
my $data2 = deduce 10;

should_fail($data1, NumObj);
should_pass($data2, NumObj);

should_fail($data1, NumberObj);
should_pass($data2, NumberObj);

should_fail($data1, NumObject);
should_pass($data2, NumObject);

should_fail($data1, NumberObject);
should_pass($data2, NumberObject);

ok 1 and done_testing;
