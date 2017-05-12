use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(deduce);
use Data::Object::Library qw(
    ScalarObj
    ScalarObject
    Object
);

ok_subtype Object, ScalarObj;
ok_subtype Object, ScalarObject;

my $data1 = \["12345"];
my $data2 = deduce \["12345"];

should_fail($data1, ScalarObj);
should_pass($data2, ScalarObj);

should_fail($data1, ScalarObject);
should_pass($data2, ScalarObject);

ok 1 and done_testing;
