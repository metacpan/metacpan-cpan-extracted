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
    package Parent;
    use Class::Method::Modifiers;

    sub original { push @calls, 'Parent::original' }
    around original => sub {
        my $orig = shift;
        push @calls, 'around/before Parent::original';
        $orig->(@_);
        push @calls, 'around/after Parent::original';
    };
};

Parent->original;
is_deeply([splice @calls], [
    'around/before Parent::original',
    'Parent::original',
    'around/after Parent::original',
]);

do {
    package Parent;
    use Class::Method::Modifiers;

    around original => sub {
        my $orig = shift;
        push @calls, '2 around/before Parent::original';
        $orig->(@_);
        push @calls, '2 around/after Parent::original';
    };
};

Parent->original;
is_deeply([splice @calls], [
    '2 around/before Parent::original',
    'around/before Parent::original',
    'Parent::original',
    'around/after Parent::original',
    '2 around/after Parent::original',
]);

done_testing;
