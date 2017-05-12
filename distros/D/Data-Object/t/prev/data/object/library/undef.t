use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(deduce);
use Data::Object::Library qw(
    UndefObj
    UndefObject
    Object
);

ok_subtype Object, UndefObj;
ok_subtype Object, UndefObject;

my $data1 = undef;
my $data2 = deduce undef;

should_fail($data1, UndefObj);
should_pass($data2, UndefObj);

should_fail($data1, UndefObject);
should_pass($data2, UndefObject);

ok 1 and done_testing;
