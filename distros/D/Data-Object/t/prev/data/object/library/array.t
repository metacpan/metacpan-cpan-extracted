use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(deduce);
use Data::Object::Library qw(
    ArrayObj
    ArrayObject
    Object
);

ok_subtype Object, ArrayObj;
ok_subtype Object, ArrayObject;

my $data1 = [];
my $data2 = deduce [];

should_fail($data1, ArrayObj);
should_pass($data2, ArrayObj);

should_fail($data1, ArrayObject);
should_pass($data2, ArrayObject);

my $data3 = deduce [undef];
my $data4 = deduce [bless {}, 'main'];

should_fail($data3, ArrayObj[Object]);
should_pass($data4, ArrayObj[Object]);

my $data5 = [ ];
my $data6 = [ bless {}, 'main' ];
my $data7 = [ [  ] ];

should_pass(ArrayObject->coerce($data5), ArrayObject);
should_pass((ArrayObject[Object])->coerce($data6), ArrayObject[Object]);
should_pass((ArrayObject[ArrayObject])->coerce($data7), ArrayObject[ArrayObject]);

ok 1 and done_testing;
