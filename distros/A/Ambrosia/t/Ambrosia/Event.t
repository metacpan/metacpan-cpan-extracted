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
        public  => [qw/foo/],
    };

    sub run
    {
        my $self = shift;
        $self->publicEvent(on_run => $self->foo);
    }

    sub abort
    {
        Ambrosia::Event::fireEvent('', on_abort => 321);
    }

    1;
}

{
    package main;
    use Test::More tests => 5;
    use Test::Exception;
    use lib qw(lib t ..);
    use Carp;

    use Data::Dumper;

    BEGIN {
        use_ok( 'Ambrosia::Event' ); #test #1
    }

    my $foo = new Foo(foo=>123);
    $foo->on_run(sub {$foo->foo=1; return 1;});
    $foo->run();
    ok($foo->foo == 1, 'fire event'); #test #2

    $foo->on_run(sub {$foo->foo+=1; return 1;});
    $foo->run();
    ok($foo->foo == 2, 'fire event with ignore previos'); #test #3

    $foo->on_run(sub {$foo->foo=3; return 0;});
    $foo->run();
    ok($foo->foo == 4, 'fire event throw chain previos'); #test #4

    my $abort = 0;
    Ambrosia::Event::attachHandler('','on_abort', sub {$abort=123});
    $foo->abort();
    ok($abort == 123, 'global event');
}

