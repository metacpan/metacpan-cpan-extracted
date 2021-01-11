#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

for my $mod ( qw( Mojo::Promise  Mojo::IOLoop ) ) {
    eval "require $mod" or plan skip_all => "No $mod: $@";
}

use Data::Dumper;
$Data::Dumper::Useqq = 1;

use_ok('DNS::Unbound::Mojo');

my $name = 'example.com';

is(
    DNS::Unbound::Mojo->can('resolve_p'),
    DNS::Unbound::Mojo->can('resolve_async'),
    'resolve_p() alias',
);

SKIP: {
    eval { my $p = Mojo::Promise->new( sub { } ); 1 } or do {
        my $err = $@;
        require Mojolicious;
        skip "This Mojo::Promise ($Mojolicious::VERSION) isn’t ES6-compatible: $err", 1;
    };

    DNS::Unbound::Mojo->new()->resolve_p($name, 'NS')->then(
        sub {
            my ($result) = @_;

            isa_ok( $result, 'DNS::Unbound::Result', 'promise resolution' );

            diag explain [ passed => $result ];
        },
        sub {
            my $why = shift;
            fail $why;
        },
    )->wait();
}

done_testing();
