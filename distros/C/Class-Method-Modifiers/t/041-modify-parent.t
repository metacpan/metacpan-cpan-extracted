use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @calls;

do {
    package MyParent;
    sub foo { push @calls, 'MyParent::foo' }

    package Child;
    use Class::Method::Modifiers;
    our @ISA = 'MyParent';

    around foo => sub {
        push @calls, 'before Child::foo';
        shift->(@_);
        push @calls, 'after Child::foo';
    };
};

Child->foo;
is_deeply([splice @calls], [
    'before Child::foo',
    'MyParent::foo',
    'after Child::foo',
]);

do {
    package MyParent;
    use Class::Method::Modifiers;
    around foo => sub {
        push @calls, 'before MyParent::foo';
        shift->(@_);
        push @calls, 'after MyParent::foo';
    };
};

Child->foo;

TODO: {
    local $TODO = "pending discussion with stevan";
    is_deeply([splice @calls], [
        'before Child::foo',
        'before MyParent::foo',
        'MyParent::foo',
        'after MyParent::foo',
        'after Child::foo',
    ]);
}

done_testing;
