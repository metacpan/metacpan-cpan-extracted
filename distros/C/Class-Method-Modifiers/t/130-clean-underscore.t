use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @calls;

do {
    package MyParent;

    sub original {
        $_ = "danger";
        push @calls, 'MyParent::original';
    }
};

do {
    package Child::Before;
    use Class::Method::Modifiers;
    BEGIN { our @ISA = 'MyParent' }

    before original => sub {
        $_ = "danger";
        push @calls, 'Child::Before::original';
    };
};

Child::Before->original;
is_deeply([splice @calls], [
    'Child::Before::original',
    'MyParent::original',
]);

Child::Before->original;
is_deeply([splice @calls], [
    'Child::Before::original',
    'MyParent::original',
]);

do {
    package Child::After;
    use Class::Method::Modifiers;
    BEGIN { our @ISA = 'MyParent' }

    after original => sub {
        $_ = "danger";
        push @calls, 'Child::After::original';
    };
};

Child::After->original;
is_deeply([splice @calls], [
    'MyParent::original',
    'Child::After::original',
]);

Child::After->original;
is_deeply([splice @calls], [
    'MyParent::original',
    'Child::After::original',
]);

do {
    package Child::Around;
    use Class::Method::Modifiers;
    BEGIN { our @ISA = 'MyParent' }

    around original => sub {
        my $orig = shift;
        $_ = "danger";
        push @calls, 'Child::Around::original(before)';
        $orig->(@_);
        $_ = "danger";
        push @calls, 'Child::Around::original(after)';
    };
};

Child::Around->original;
is_deeply([splice @calls], [
    'Child::Around::original(before)',
    'MyParent::original',
    'Child::Around::original(after)',
]);

Child::Around->original;
is_deeply([splice @calls], [
    'Child::Around::original(before)',
    'MyParent::original',
    'Child::Around::original(after)',
]);

done_testing;
