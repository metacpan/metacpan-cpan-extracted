use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(deduce);
use Data::Object::Library qw(
    FloatObj
    FloatObject
    Object
);

ok_subtype Object, FloatObj;
ok_subtype Object, FloatObject;

my $data1 = 99.99;
my $data2 = deduce 99.99;

should_fail($data1, FloatObj);
should_pass($data2, FloatObj);

should_fail($data1, FloatObject);
should_pass($data2, FloatObject);

ok 1 and done_testing;
