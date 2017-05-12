#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Test::Deep;

use Data::Validator;
use Data::Validator::MultiManager;

my $manager = Data::Validator::MultiManager->new;
$manager->add(
    id => {
        id => { isa => 'Int' },
    },
    name => {
        name    => { isa => 'Str' },
        compony => { isa => 'Str' },
    },
);

subtest 'diff ( id:1 vs name:3 )' => sub {
    my $result = $manager->validate({ id => 'invalid' });

    cmp_deeply $result->errors('id'), bag(
        superhashof( { name => 'id', type => 'InvalidValue' } ),
    );
    cmp_deeply $result->errors('name'), bag(
        superhashof( { name => 'id', type => 'UnknownParameter' } ),
        superhashof( { name => 'name', type => 'MissingParameter' } ),
        superhashof( { name => 'compony', type => 'MissingParameter' } ),
    );
    cmp_deeply $result->errors, bag(
        superhashof( { name => 'id', type => 'InvalidValue' } ),
    );
    is $result->invalid, 'id';
};

subtest 'diff ( id:2 vs name:2 ) using order by' => sub {
    my $result = $manager->validate({ name => ['invalid'] });

    cmp_deeply $result->errors('id'), bag(
        superhashof( { name => 'id', type => 'MissingParameter' } ),
        superhashof( { name => 'name', type => 'UnknownParameter' } ),
    );
    cmp_deeply $result->errors('name'), bag(
        superhashof( { name => 'name', type => 'InvalidValue' } ),
        superhashof( { name => 'compony', type => 'MissingParameter' } ),
    );
    cmp_deeply $result->errors, bag(
        superhashof( { name => 'id',   type => 'MissingParameter' } ),
        superhashof( { name => 'name', type => 'UnknownParameter' } ),
    );
    is $result->invalid, 'id';
};

subtest 'diff ( id:3 vs name:2 )' => sub {
    my $result = $manager->validate({ name => ['invalid'], compony => ['invalid'] });

    cmp_deeply $result->errors('id'), bag(
        superhashof( { name => 'id', type => 'MissingParameter' } ),
        superhashof( { name => 'name', type => 'UnknownParameter' } ),
        superhashof( { name => 'compony', type => 'UnknownParameter' } ),
    );
    cmp_deeply $result->errors('name'), bag(
        superhashof( { name => 'name', type => 'InvalidValue' } ),
        superhashof( { name => 'compony', type => 'InvalidValue' } ),
    );
    cmp_deeply $result->errors, bag(
        superhashof( { name => 'name',    type => 'InvalidValue' } ),
        superhashof( { name => 'compony', type => 'InvalidValue' } ),
    );
    is $result->invalid, 'name';
};

subtest 'diff ( id:1 vs name:2 )' => sub {
    my $result = $manager->validate({});

    cmp_deeply $result->errors('id'), bag(
        superhashof( { name => 'id', type => 'MissingParameter' } ),
    );
    cmp_deeply $result->errors('name'), bag(
        superhashof( { name => 'name', type => 'MissingParameter' } ),
        superhashof( { name => 'compony', type => 'MissingParameter' } ),
    );
    cmp_deeply $result->errors, bag(
        superhashof( { name => 'id', type => 'MissingParameter' } )
    );
    is $result->invalid, 'id';
};
done_testing;
__END__


