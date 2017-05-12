#!/usr/bin/env perl
use strict;
use Test::More;

use Bread::Board;

my $seen;

{
    package Bot;
    use Moose;

    has plugin => (
        isa      => 'Plugin',
        is       => 'ro',
        required => 1
    );
}

{
    package Plugin;
    use Moose;

    has bot => (
        isa      => 'Bot',
        is       => 'ro',
        weak_ref => 1,
        required => 1
    );
}

my $c = container 'Config' => as {
    service plugin => (
        class        => 'Plugin',
        lifecycle    => 'Session',
        dependencies => ['bot'],
    );

    service bot => (
        class        => 'Bot',
        block        => sub {
            my ($s) = @_;
            $seen++;
            Bot->new(plugin => $s->param('plugin'));
        },
        lifecycle    => 'Session',
        dependencies => ['plugin'],
    );
};

ok($c->resolve(service => 'bot'));
is($seen, 1, 'seen only once');

ok($c->flush_session_instances);

ok($c->resolve(service => 'bot'));
is($seen, 2, 'seen twice');

done_testing;
