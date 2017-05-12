#!/usr/bin/perl
{
    package Foo;
    use strict;
    use warnings;
    use lib qw(lib t ..);
    use Ambrosia::Event qw/on_run/;

    use Ambrosia::Meta;
    class
    {
        public     => [qw/Name Age/],
        protected  => [qw/State/],
    };

    sub getState
    {
        return $_[0]->State;
    }

    1;
}

{
    package FooSealed;
    use strict;
    use warnings;
    use lib qw(lib t ..);
    use Ambrosia::Event qw/on_run/;

    use Ambrosia::Meta;
    class sealed
    {
        public     => [qw/Name Age/],
        protected  => [qw/State/],
    };

    sub getState
    {
        return $_[0]->State;
    }

    1;
}

{
    package Vanilla;
    use strict;
    use warnings;
    use lib qw(lib t ..);
    use Ambrosia::Event qw/on_run/;

    sub new
    {
        my $proto = shift;
        my $class = ref $proto || $proto;
        my %self = @_;
        return bless \%self, $class;
    };

    sub getState
    {
        return $_[0]->{State};
    }

    1;
}


{
    package main;
    use warnings;
    use strict;
    use lib qw(lib t);
    use Dog;
    use Benchmark qw(:all);

    my $dog = new Dog(Name => 'John Smit', Age => 33, State => 'new', Foo=>123);
    my $foo = new Foo(Name => 'John Smit', Age => 33, State => 'new');
    my $fooSealed = new FooSealed(Name => 'John Smit', Age => 33, State => 'new');
    my $vanilla = new Vanilla(Name => 'John Smit', Age => 33, State => 'new');

my $NUM_ITER = 100_000;
cmpthese($NUM_ITER, {
    'foo_new'       => sub {my $foo =       new Foo(Name => 'John Smit', Age => 33, State => 'new');},
    'fooSealed_new' => sub {my $fooSealed = new FooSealed(Name => 'John Smit', Age => 33, State => 'new');},
    'vanilla_new'   => sub {my $vanilla =   new Vanilla(Name => 'John Smit', Age => 33, State => 'new');},
    'moose_new'   => sub {my $dog = new Dog(Name => 'John Smit', Age => 33, State => 'new');},
});

#exit;

$NUM_ITER = 1000_000;
cmpthese($NUM_ITER, {
    'foo_field'       => sub {my $age = $foo->Age;},
    'fooSealed_field' => sub {my $age = $fooSealed->Age;},
    'vanilla_field'   => sub {my $age = $vanilla->{Age};},
    'moose_new'   => sub {my $age = $dog->Age();},
});

cmpthese($NUM_ITER, {
    'foo_method'       => sub {my $state = $foo->getState;},
    'fooSealed_method' => sub {my $state = $fooSealed->getState;},
    'vanilla_method'   => sub {my $state = $vanilla->{State};},
});

}

