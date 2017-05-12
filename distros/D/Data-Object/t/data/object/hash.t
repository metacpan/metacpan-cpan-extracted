use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';

ok Data::Object::Hash->does('Data::Object::Role::Collection');
ok Data::Object::Hash->does('Data::Object::Role::Comparison');
ok Data::Object::Hash->does('Data::Object::Role::Defined');
ok Data::Object::Hash->does('Data::Object::Role::Detract');
ok Data::Object::Hash->does('Data::Object::Role::Dumper');
ok Data::Object::Hash->does('Data::Object::Role::Item');
ok Data::Object::Hash->does('Data::Object::Role::List');
ok Data::Object::Hash->does('Data::Object::Role::Output');
ok Data::Object::Hash->does('Data::Object::Role::Throwable');
ok Data::Object::Hash->does('Data::Object::Role::Type');

can_ok 'Data::Object::Hash', 'clear';
can_ok 'Data::Object::Hash', 'count';
can_ok 'Data::Object::Hash', 'data';
can_ok 'Data::Object::Hash', 'defined';
can_ok 'Data::Object::Hash', 'delete';
can_ok 'Data::Object::Hash', 'detract';
can_ok 'Data::Object::Hash', 'dump';
can_ok 'Data::Object::Hash', 'each';
can_ok 'Data::Object::Hash', 'each_key';
can_ok 'Data::Object::Hash', 'each_n_values';
can_ok 'Data::Object::Hash', 'each_value';
can_ok 'Data::Object::Hash', 'empty';
can_ok 'Data::Object::Hash', 'eq';
can_ok 'Data::Object::Hash', 'exists';
can_ok 'Data::Object::Hash', 'filter_exclude';
can_ok 'Data::Object::Hash', 'filter_include';
can_ok 'Data::Object::Hash', 'fold';
can_ok 'Data::Object::Hash', 'ge';
can_ok 'Data::Object::Hash', 'get';
can_ok 'Data::Object::Hash', 'grep';
can_ok 'Data::Object::Hash', 'gt';
can_ok 'Data::Object::Hash', 'head';
can_ok 'Data::Object::Hash', 'invert';
can_ok 'Data::Object::Hash', 'iterator';
can_ok 'Data::Object::Hash', 'join';
can_ok 'Data::Object::Hash', 'keys';
can_ok 'Data::Object::Hash', 'le';
can_ok 'Data::Object::Hash', 'length';
can_ok 'Data::Object::Hash', 'list';
can_ok 'Data::Object::Hash', 'lookup';
can_ok 'Data::Object::Hash', 'lt';
can_ok 'Data::Object::Hash', 'map';
can_ok 'Data::Object::Hash', 'merge';
can_ok 'Data::Object::Hash', 'methods';
can_ok 'Data::Object::Hash', 'ne';
can_ok 'Data::Object::Hash', 'new';
can_ok 'Data::Object::Hash', 'pairs';
can_ok 'Data::Object::Hash', 'print';
can_ok 'Data::Object::Hash', 'reset';
can_ok 'Data::Object::Hash', 'reverse';
can_ok 'Data::Object::Hash', 'roles';
can_ok 'Data::Object::Hash', 'say';
can_ok 'Data::Object::Hash', 'set';
can_ok 'Data::Object::Hash', 'slice';
can_ok 'Data::Object::Hash', 'sort';
can_ok 'Data::Object::Hash', 'tail';
can_ok 'Data::Object::Hash', 'throw';
can_ok 'Data::Object::Hash', 'type';
can_ok 'Data::Object::Hash', 'unfold';
can_ok 'Data::Object::Hash', 'values';

subtest 'test instantiation' => sub {
    eval { Data::Object::Hash->new };
    like $@, qr/Type Instantiation Error/;

    eval { Data::Object::Hash->new(1) };
    like $@, qr/Type Instantiation Error/;

    my $h1 = Data::Object::Hash->new(1,2);
    is_deeply $h1, {1,2};

    my $h2 = Data::Object::Hash->new({1,2});
    is_deeply $h2, {1,2};

    my $h3 = Data::Object::Hash->new($h2);
    is_deeply $h3, {1,2};
};

ok 1 and done_testing;
