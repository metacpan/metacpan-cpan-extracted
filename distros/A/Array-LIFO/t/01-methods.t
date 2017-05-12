#!/usr/bin/env perl

use Test::Spec; # automatically turns on strict and warnings

use Array::LIFO;

describe 'Array::LIFO' => sub {

    describe 'adds an element' => sub {
        my $ar;

        before each => sub {
            $ar = Array::LIFO->new( max_size => 5 );
            $ar->add(5);
        };

        it 'size is 1' => sub {
            is( $ar->size, 1 );
        };

        it 'average is 5' => sub {
            is( $ar->average, 5 );
        };

        it 'sum is 5' => sub {
            is( $ar->sum, 5 );
        };

        it 'peek is 5' => sub {
            is( $ar->peek, 5 );
        };
    };

    describe 'adds multiple elements' => sub {
        my ( $ar, $last );

        before each => sub {
            $ar = Array::LIFO->new( max_size => 5 );
            $ar->add(3);
            $ar->add(6);
            $last = $ar->add(9);
        };

        it 'size is 3' => sub {
            is( $ar->size, 3 );
        };

        it 'average is 6' => sub {
            is( $ar->average, 6 );
        };

        it 'sum is 18' => sub {
            is( $ar->sum, 18 );
        };

        it 'last one returned is 9' => sub {
            is( $last, 9 );
        };

        it 'peek is 9' => sub {
            is( $ar->peek, 9 );
        };
    };

    describe 'over max elements' => sub {
        my ( $ar, $last );

        before each => sub {
            $ar = Array::LIFO->new( max_size => 5 );
            $ar->add(4);
            $ar->add(7);
            $ar->add(10);
            $ar->add(13);
            $ar->add(16);
            $last = $ar->add(19); # Max reached. Can't add to stack
        };

        it 'size is 5' => sub {
            is( $ar->size, 5 );
        };

        it 'average is 10' => sub {
            is( $ar->average, 10 );
        };

        it 'sum is 50' => sub {
            is( $ar->sum, 50 );
        };

        it 'last one returned is 16' => sub {
            is( $last, 16 );
        };

        it 'peek is 16' => sub {
            is( $ar->peek, 16 );
        };
    };

    describe 'no max_size set' => sub {
        my $ar;

        before each => sub {
            $ar = Array::LIFO->new;
            $ar->add(3);
            $ar->add(6);
            $ar->add(9);
            $ar->add(12);
            $ar->add(15);
            $ar->add(18);
        };

        it 'size is 6' => sub {
            is( $ar->size, 6 );
        };

        it 'average is 12' => sub {
            is( $ar->average, 10.5 );
        };

        it 'sum is 63' => sub {
            is( $ar->sum, 63 );
        };

        it 'peek is 18' => sub {
            is( $ar->peek, 18 );
        };
    };
};

runtests unless caller;
