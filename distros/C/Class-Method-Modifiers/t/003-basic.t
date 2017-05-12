use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @calls;

do {
    package Parent;
    use Class::Method::Modifiers;

    sub original { push @calls, 'Parent::original' }
    before original => sub { push @calls, 'before Parent::original' };
    after  original => sub { push @calls, 'after Parent::original' };
};

Parent->original;
is_deeply([splice @calls], [
    'before Parent::original',
    'Parent::original',
    'after Parent::original',
]);

do {
    package Parent;
    use Class::Method::Modifiers;

    before original => sub { push @calls, 'before before Parent::original' };
    after  original => sub { push @calls, 'after after Parent::original' };
};

Parent->original;
is_deeply([splice @calls], [
    'before before Parent::original',
    'before Parent::original',
    'Parent::original',
    'after Parent::original',
    'after after Parent::original',
]);

do {
    package Child;
    BEGIN { our @ISA = 'Parent' }
};

Parent->original;
is_deeply([splice @calls], [
    'before before Parent::original',
    'before Parent::original',
    'Parent::original',
    'after Parent::original',
    'after after Parent::original',
]);

Child->original;
is_deeply([splice @calls], [
    'before before Parent::original',
    'before Parent::original',
    'Parent::original',
    'after Parent::original',
    'after after Parent::original',
]);

do {
    package Child;
    use Class::Method::Modifiers;

    before original => sub { push @calls, 'before Child::original' };
    after  original => sub { push @calls, 'after Child::original' };
};

Parent->original;
is_deeply([splice @calls], [
    'before before Parent::original',
    'before Parent::original',
    'Parent::original',
    'after Parent::original',
    'after after Parent::original',
]);

Child->original;
is_deeply([splice @calls], [
    'before Child::original',
    'before before Parent::original',
    'before Parent::original',
    'Parent::original',
    'after Parent::original',
    'after after Parent::original',
    'after Child::original',
]);

done_testing;
