#!/usr/bin/perl
use warnings;
use strict;
use lib qw(lib t);
use Benchmark;

{
    package Foo;
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

    1;
}

my $foo = new Foo(foo=>123);
$foo->on_run(sub {$foo->foo=1; return 1;});
$foo->on_run(sub {$foo->foo+=1; return 0;});
$foo->on_run(sub {$foo->foo=3; return 0;});

my $NUM_ITER = 1000_000;

timethese($NUM_ITER, {
    'run' => sub { $foo->run() },
});
