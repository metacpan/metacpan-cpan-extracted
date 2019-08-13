use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @calls;

do {
    package Class;
    use Class::Method::Modifiers;

    sub original { push @calls, 'Class::original' }
    around original => sub { push @calls, 'around Class::original' };
};

Class->original;
is_deeply([splice @calls], [
    'around Class::original',
]);

do {
    package MyParent;
    use Class::Method::Modifiers;

    sub original { push @calls, 'MyParent::original' }
    around original => sub {
        my $orig = shift;
        push @calls, 'around/before MyParent::original';
        $orig->(@_);
        push @calls, 'around/after MyParent::original';
    };
};

MyParent->original;
is_deeply([splice @calls], [
    'around/before MyParent::original',
    'MyParent::original',
    'around/after MyParent::original',
]);

do {
    package MyParent;
    use Class::Method::Modifiers;

    around original => sub {
        my $orig = shift;
        push @calls, '2 around/before MyParent::original';
        $orig->(@_);
        push @calls, '2 around/after MyParent::original';
    };
};

MyParent->original;
is_deeply([splice @calls], [
    '2 around/before MyParent::original',
    'around/before MyParent::original',
    'MyParent::original',
    'around/after MyParent::original',
    '2 around/after MyParent::original',
]);

done_testing;
