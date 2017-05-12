use strict;
use warnings;

use Test::More;
use Test::TypeTiny;

use Data::Object qw(deduce);
use Data::Object::Library qw(
    HashObj
    HashObject
    Object
);

ok_subtype Object, HashObj;
ok_subtype Object, HashObject;

my $data1 = {};
my $data2 = deduce {};

should_fail($data1, HashObj);
should_pass($data2, HashObj);

should_fail($data1, HashObject);
should_pass($data2, HashObject);

my $data3 = deduce { 0 => 1 };
my $data4 = deduce { 0 => bless {}, 'main' };

should_fail($data3, HashObject[Object]);
should_pass($data4, HashObject[Object]);

my $data5 = {  };
my $data6 = { 0 => bless {}, 'main' };
my $data7 = { 0 => { 1 => 2 } };

should_pass(HashObject->coerce($data5), HashObject);
should_pass((HashObject[Object])->coerce($data6), HashObject[Object]);
should_pass((HashObject[HashObject])->coerce($data7), HashObject[HashObject]);

ok 1 and done_testing;
