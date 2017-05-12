use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(deduce);
use Data::Object::Library qw(
    StrObj
    StrObject
    StringObj
    StringObject
    Object
);

ok_subtype Object, StrObj;
ok_subtype Object, StrObject;
ok_subtype Object, StringObj;
ok_subtype Object, StringObject;

my $data1 = "abcdefg";
my $data2 = deduce "abcdefg";

should_fail($data1, StrObj);
should_pass($data2, StrObj);

should_fail($data1, StringObj);
should_pass($data2, StringObj);

should_fail($data1, StrObject);
should_pass($data2, StrObject);

should_fail($data1, StringObject);
should_pass($data2, StringObject);

ok 1 and done_testing;
