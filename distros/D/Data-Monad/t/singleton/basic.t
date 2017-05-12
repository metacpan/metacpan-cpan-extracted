use strict;
use warnings;
use Data::Monad::Singleton qw/singleton/;
use Data::Monad::Base::Sugar;
use Test::More;

subtest unit => sub {
    is +Data::Monad::Singleton->unit(singleton)->flatten, singleton;
    is singleton->map(sub {
        Data::Monad::Singleton->unit(@_);
    })->flatten, singleton;
};

subtest associative => sub {
    my $mm = Data::Monad::Singleton->unit(singleton);
    is $mm->flatten->flatten, singleton;
    is $mm->map(sub { $_[0]->flatten })->flatten, singleton;
};

subtest for => sub {
    is +Data::Monad::Base::Sugar::for {
        pick \my $x => sub { singleton };
        pick \my $y => sub { singleton };
        yield { $x, $y };
    }, singleton;
};

done_testing;
