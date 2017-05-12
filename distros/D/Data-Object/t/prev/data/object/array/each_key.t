use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'each_key';

use Scalar::Util 'refaddr';

subtest 'test the each_key method' => sub {
    my $array = Data::Object::Array->new(['a'..'g']);

    my $keys = [];
    my @argument = (sub{ my $index = shift; push @{$keys}, $index; });
    my $each_key = $array->each_key(@argument);

    is refaddr($array), refaddr($each_key);
    is_deeply $each_key, $array;
    is_deeply $keys, [qw(0 1 2 3 4 5 6)];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $each_key, 'Data::Object::Array';
};

ok 1 and done_testing;
