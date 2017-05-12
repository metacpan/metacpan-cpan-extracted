use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(data_universal);
use Data::Object::Library qw(
    UniversalObj
    UniversalObject
    Object
);

ok_subtype Object, UniversalObj;
ok_subtype Object, UniversalObject;

my $data1 = undef;
my $data2 = data_universal undef;

should_fail($data1, UniversalObj);
should_pass($data2, UniversalObj);

should_fail($data1, UniversalObject);
should_pass($data2, UniversalObject);

ok 1 and done_testing;
