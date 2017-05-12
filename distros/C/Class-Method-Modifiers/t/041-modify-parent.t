use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @calls;

do {
    package Parent;
    sub foo { push @calls, 'Parent::foo' }

    package Child;
    use Class::Method::Modifiers;
    our @ISA = 'Parent';

    around foo => sub {
        push @calls, 'before Child::foo';
        shift->(@_);
        push @calls, 'after Child::foo';
    };
};

Child->foo;
is_deeply([splice @calls], [
    'before Child::foo',
    'Parent::foo',
    'after Child::foo',
]);

do {
    package Parent;
    use Class::Method::Modifiers;
    around foo => sub {
        push @calls, 'before Parent::foo';
        shift->(@_);
        push @calls, 'after Parent::foo';
    };
};

Child->foo;

TODO: {
    local $TODO = "pending discussion with stevan";
    is_deeply([splice @calls], [
        'before Child::foo',
        'before Parent::foo',
        'Parent::foo',
        'after Parent::foo',
        'after Child::foo',
    ]);
}

done_testing;
