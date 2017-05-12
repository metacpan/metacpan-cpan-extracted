use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(deduce);
use Data::Object::Library qw(
    RegexpObj
    RegexpObject
    Object
);

ok_subtype Object, RegexpObj;
ok_subtype Object, RegexpObject;

my $data1 = qr//;
my $data2 = deduce qr//;

should_fail($data1, RegexpObj);
should_pass($data2, RegexpObj);

should_fail($data1, RegexpObject);
should_pass($data2, RegexpObject);

ok 1 and done_testing;
