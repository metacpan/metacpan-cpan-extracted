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
    package main;
    use Test::More tests => 6;
    use Test::Exception;
    use lib qw(lib t ..);
    use Carp;

    my $foo = new Foo(Name => 'John Smit', Age => 33, State => 'new');
    ok($foo->Name eq 'John Smit', 'check data in field Name');
    ok($foo->Age == 33, 'check data in field Age');
    ok($foo->getState eq 'new' , 'call method');

    my $fooSealed = new FooSealed(Name => 'John Smit', Age => 33, State => 'new');
    ok($fooSealed->Name eq 'John Smit', 'in sealed check data in field Name');
    ok($fooSealed->Age == 33, 'in sealed check data in field Age');
    ok($fooSealed->getState eq 'new' , 'in sealed call method');
}

