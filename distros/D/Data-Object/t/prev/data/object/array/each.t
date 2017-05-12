use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'each';

use Scalar::Util 'refaddr';

subtest 'test the each method - natural' => sub {
    my $array = Data::Object::Array->new(['a'..'g']);
    my $keys  = Data::Object::Array->new([]);

    my $indices = [];
    my $values  = [];

    my $each = $array->each(sub{
        push @{$indices}, shift; # 0
        push @{$values},  shift; # a
    });

    is refaddr($array), refaddr($each);
    is_deeply $indices, [qw(0 1 2 3 4 5 6)];
    is_deeply $values, [qw(a b c d e f g)];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $each, 'Data::Object::Array';
};

subtest 'test the each method - codified' => sub {
    my $array = Data::Object::Array->new(['a'..'g']);
    my $keys  = Data::Object::Array->new([]);

    my $indices = Data::Object::Array->new([]);
    my $values  = Data::Object::Array->new([]);

    my $each = $array->each('$c->push($a); $d->push($b)', $indices, $values);

    is refaddr($array), refaddr($each);
    is_deeply $indices, [qw(0 1 2 3 4 5 6)];
    is_deeply $values, [qw(a b c d e f g)];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $each, 'Data::Object::Array';
};

ok 1 and done_testing;
