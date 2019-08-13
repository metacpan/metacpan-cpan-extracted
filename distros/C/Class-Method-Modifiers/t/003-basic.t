use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @calls;

do {
    package MyParent;
    use Class::Method::Modifiers;

    sub original { push @calls, 'MyParent::original' }
    before original => sub { push @calls, 'before MyParent::original' };
    after  original => sub { push @calls, 'after MyParent::original' };
};

MyParent->original;
is_deeply([splice @calls], [
    'before MyParent::original',
    'MyParent::original',
    'after MyParent::original',
]);

do {
    package MyParent;
    use Class::Method::Modifiers;

    before original => sub { push @calls, 'before before MyParent::original' };
    after  original => sub { push @calls, 'after after MyParent::original' };
};

MyParent->original;
is_deeply([splice @calls], [
    'before before MyParent::original',
    'before MyParent::original',
    'MyParent::original',
    'after MyParent::original',
    'after after MyParent::original',
]);

do {
    package Child;
    BEGIN { our @ISA = 'MyParent' }
};

MyParent->original;
is_deeply([splice @calls], [
    'before before MyParent::original',
    'before MyParent::original',
    'MyParent::original',
    'after MyParent::original',
    'after after MyParent::original',
]);

Child->original;
is_deeply([splice @calls], [
    'before before MyParent::original',
    'before MyParent::original',
    'MyParent::original',
    'after MyParent::original',
    'after after MyParent::original',
]);

do {
    package Child;
    use Class::Method::Modifiers;

    before original => sub { push @calls, 'before Child::original' };
    after  original => sub { push @calls, 'after Child::original' };
};

MyParent->original;
is_deeply([splice @calls], [
    'before before MyParent::original',
    'before MyParent::original',
    'MyParent::original',
    'after MyParent::original',
    'after after MyParent::original',
]);

Child->original;
is_deeply([splice @calls], [
    'before Child::original',
    'before before MyParent::original',
    'before MyParent::original',
    'MyParent::original',
    'after MyParent::original',
    'after after MyParent::original',
    'after Child::original',
]);

done_testing;
