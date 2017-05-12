use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';

ok Data::Object::Array->does('Data::Object::Role::Collection');
ok Data::Object::Array->does('Data::Object::Role::Comparison');
ok Data::Object::Array->does('Data::Object::Role::Defined');
ok Data::Object::Array->does('Data::Object::Role::Detract');
ok Data::Object::Array->does('Data::Object::Role::Dumper');
ok Data::Object::Array->does('Data::Object::Role::Item');
ok Data::Object::Array->does('Data::Object::Role::List');
ok Data::Object::Array->does('Data::Object::Role::Output');
ok Data::Object::Array->does('Data::Object::Role::Throwable');
ok Data::Object::Array->does('Data::Object::Role::Type');

can_ok 'Data::Object::Array', 'all';
can_ok 'Data::Object::Array', 'any';
can_ok 'Data::Object::Array', 'clear';
can_ok 'Data::Object::Array', 'count';
can_ok 'Data::Object::Array', 'data';
can_ok 'Data::Object::Array', 'defined';
can_ok 'Data::Object::Array', 'delete';
can_ok 'Data::Object::Array', 'detract';
can_ok 'Data::Object::Array', 'dump';
can_ok 'Data::Object::Array', 'each';
can_ok 'Data::Object::Array', 'each_key';
can_ok 'Data::Object::Array', 'each_n_values';
can_ok 'Data::Object::Array', 'each_value';
can_ok 'Data::Object::Array', 'empty';
can_ok 'Data::Object::Array', 'eq';
can_ok 'Data::Object::Array', 'exists';
can_ok 'Data::Object::Array', 'first';
can_ok 'Data::Object::Array', 'ge';
can_ok 'Data::Object::Array', 'get';
can_ok 'Data::Object::Array', 'grep';
can_ok 'Data::Object::Array', 'gt';
can_ok 'Data::Object::Array', 'hash';
can_ok 'Data::Object::Array', 'hashify';
can_ok 'Data::Object::Array', 'head';
can_ok 'Data::Object::Array', 'invert';
can_ok 'Data::Object::Array', 'iterator';
can_ok 'Data::Object::Array', 'join';
can_ok 'Data::Object::Array', 'keyed';
can_ok 'Data::Object::Array', 'keys';
can_ok 'Data::Object::Array', 'last';
can_ok 'Data::Object::Array', 'le';
can_ok 'Data::Object::Array', 'length';
can_ok 'Data::Object::Array', 'list';
can_ok 'Data::Object::Array', 'lt';
can_ok 'Data::Object::Array', 'map';
can_ok 'Data::Object::Array', 'max';
can_ok 'Data::Object::Array', 'methods';
can_ok 'Data::Object::Array', 'min';
can_ok 'Data::Object::Array', 'ne';
can_ok 'Data::Object::Array', 'new';
can_ok 'Data::Object::Array', 'none';
can_ok 'Data::Object::Array', 'nsort';
can_ok 'Data::Object::Array', 'one';
can_ok 'Data::Object::Array', 'pairs';
can_ok 'Data::Object::Array', 'pairs_array';
can_ok 'Data::Object::Array', 'pairs_hash';
can_ok 'Data::Object::Array', 'part';
can_ok 'Data::Object::Array', 'pop';
can_ok 'Data::Object::Array', 'print';
can_ok 'Data::Object::Array', 'push';
can_ok 'Data::Object::Array', 'random';
can_ok 'Data::Object::Array', 'reverse';
can_ok 'Data::Object::Array', 'rnsort';
can_ok 'Data::Object::Array', 'roles';
can_ok 'Data::Object::Array', 'rotate';
can_ok 'Data::Object::Array', 'rsort';
can_ok 'Data::Object::Array', 'say';
can_ok 'Data::Object::Array', 'set';
can_ok 'Data::Object::Array', 'shift';
can_ok 'Data::Object::Array', 'size';
can_ok 'Data::Object::Array', 'slice';
can_ok 'Data::Object::Array', 'sort';
can_ok 'Data::Object::Array', 'sum';
can_ok 'Data::Object::Array', 'tail';
can_ok 'Data::Object::Array', 'throw';
can_ok 'Data::Object::Array', 'type';
can_ok 'Data::Object::Array', 'unique';
can_ok 'Data::Object::Array', 'unshift';
can_ok 'Data::Object::Array', 'values';

subtest 'test instantiation' => sub {
    eval { Data::Object::Array->new };
    like $@, qr/Type Instantiation Error/;

    eval { Data::Object::Array->new(1) };
    like $@, qr/Type Instantiation Error/;

    my $a1 = Data::Object::Array->new(1,2);
    is_deeply $a1, [1,2];

    my $a2 = Data::Object::Array->new([1,2]);
    is_deeply $a2, [1,2];

    my $a3 = Data::Object::Array->new($a2);
    is_deeply $a3, [1,2];
};

ok 1 and done_testing;
