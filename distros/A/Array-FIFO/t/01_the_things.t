
use Test::Spec; # automatically turns on strict and warnings
use FindBin;
use lib "$FindBin::Bin/../lib";

use Array::FIFO;

describe "Array::FIFO" => sub {

    describe "adds an element" => sub {
        my $ar;

        before each => sub {
            $ar = Array::FIFO->new( limit => 5 );
            $ar->add( 5 );
        };

        it "size is 1" => sub {
            is( $ar->size, 1 );
        };

        it "average is 5" => sub {
            is( $ar->average, 5 );
        };

        it "sum is 5" => sub {
            is( $ar->sum, 5 );
        };

    };

    describe "adds multiple elements" => sub {
        my $ar;

        before each => sub {
            $ar = Array::FIFO->new( limit => 5 );
            $ar->add( 3 );
            $ar->add( 6 );
            $ar->add( 9 );
        };

        it "size is 3" => sub {
            is( $ar->size, 3 );
        };

        it "average is 6" => sub {
            is( $ar->average, 6 );
        };

        it "sum is 18" => sub {
            is( $ar->sum, 18 );
        };

    };

    describe "over max elements" => sub {
        my ($ar, $last);

        before each => sub {
            $ar = Array::FIFO->new( limit => 5 );
            $ar->add( 4 );
            $ar->add( 7 );
            $ar->add( 10 );
            $ar->add( 13 );
            $ar->add( 16 );
            $last = $ar->add( 19 );
        };

        it "size is 5" => sub {
            is( $ar->size, 5 );
        };

        it "average is 13" => sub {
            is( $ar->average, 13 );
        };

        it "sum is 60" => sub {
            is( $ar->sum, 65 );
        };

        it "lost one returned is 4" => sub {
            is( $last, 4 );
        };

        it "average resets as new entries are added" => sub {
            is( $ar->average, 13 );
            $ar->add( 22 );
            is( $ar->average, 16 );
        };

    };

    describe "no limit set" => sub {
        my $ar;

        before each => sub {
            $ar = Array::FIFO->new;
            $ar->add( 3 );
            $ar->add( 6 );
            $ar->add( 9 );
            $ar->add( 12 );
            $ar->add( 15 );
            $ar->add( 18 );
        };

        it "size is 6" => sub {
            is( $ar->size, 6 );
        };

        it "average is 12" => sub {
            is( $ar->average, 10.5 );
        };

        it "sum is 63" => sub {
            is( $ar->sum, 63 );
        };

    };

    describe "test with negative values" => sub {
        my $ar;

        before each => sub {
            $ar = Array::FIFO->new( limit => 5 );
            $ar->add( -3 );
            $ar->add( -8 );
            $ar->add( 2 );
            $ar->add( -1 );
        };

        it "size is 4" => sub {
            is( $ar->size, 4 );
        };

        it "average is -2.5" => sub {
            is( $ar->average, -2.5 );
        };

        it "sum is -10" => sub {
            is( $ar->sum, -10 );
        };

    };

};

runtests unless caller;

