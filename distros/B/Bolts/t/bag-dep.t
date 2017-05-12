#!/usr/bin/perl
use v5.10;
use strict;
use warnings;

use Test::More tests => 6;

{
    package Test::Bag;
    use Bolts;

    artifact up => 'w00t';

    bag down => contains {
        artifact use_up => (
            path => [ 'up' ],
        );

        artifact use_up_again => (
            builder => sub { [] },
            push => [ dep('up') ],
        );

        artifact use_up_and_down => (
            builder => sub { [] },
            push => [ dep(['down', 'use_up']) ],
        );

        artifact use_up_and_down_again => (
            builder => sub { [] },
            push => [ dep(['down', 'use_up_again']) ],
        );
    };

    __PACKAGE__->meta->finish_bag;
}

my $bag = Test::Bag->new;
isa_ok($bag, 'Test::Bag');

is($bag->acquire('up'), 'w00t');
is($bag->acquire('down', 'use_up'), 'w00t');
is_deeply($bag->acquire('down', 'use_up_again'), [ 'w00t' ]);
is_deeply($bag->acquire('down', 'use_up_and_down'), [ 'w00t' ]);
is_deeply($bag->acquire('down', 'use_up_and_down_again'), [ [ 'w00t' ] ]);
