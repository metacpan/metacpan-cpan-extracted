
use Test::Spec; # automatically turns on strict and warnings
use FindBin;
use lib "$FindBin::Bin/../lib";

use Array::Queue::Priority;

describe "Array::Queue::Priority" => sub {

    describe "adds an element" => sub {
        my $ar;

        before each => sub {
            $ar = Array::Queue::Priority->new;
            $ar->add( 5 );
        };

        it "size is 1" => sub {
            is( $ar->size, 1 );
        };

        it "first elem is 5" => sub {
            is( $ar->first, 5 );
        };

    };

    describe "adds multiple elements" => sub {
        my $ar;

        before each => sub {
            $ar = Array::Queue::Priority->new;
            $ar->add( 9 );
            $ar->add( 6 );
            $ar->add( 3 );
            $ar->add( 10 );
            $ar->add( 7 );
        };

        it "size is 5" => sub {
            is( $ar->size, 5 );
        };

        it "first is 3" => sub {
            is( $ar->first, 3 );
        };

        it "second is 6" => sub {
            $ar->remove;
            is( $ar->first, 6 );
        };

        it "third is 7" => sub {
            $ar->remove;
            $ar->remove;
            is( $ar->first, 7 );
        };

        it "fourth is 9" => sub {
            $ar->remove;
            $ar->remove;
            $ar->remove;
            is( $ar->first, 9 );
        };

        it "fifth is 10" => sub {
            $ar->remove;
            $ar->remove;
            $ar->remove;
            $ar->remove;
            is( $ar->first, 10 );
        };

    };

    describe "adds multiple hashref" => sub {
        my $ar;

        before each => sub {
            $ar = Array::Queue::Priority->new(
                sort_cb => sub {
                    $_[0]->{num} <=> $_[1]->{num}
                });
            $ar->add({ num => 9 });
            $ar->add({ num => 6 });
            $ar->add({ num => 3 });
            $ar->add({ num => 1 });
            $ar->add({ num => 10 });
            $ar->add({ num => 7 });
        };

        it "size is 6" => sub {
            is( $ar->size, 6 );
        };

        it "first is 1" => sub {
            is( $ar->first->{num}, 1 );
        };

        it "second is 3" => sub {
            $ar->remove;
            is( $ar->first->{num}, 3 );
        };

        it "third is 6" => sub {
            $ar->remove;
            $ar->remove;
            is( $ar->first->{num}, 6 );
        };

        it "fourth is 7" => sub {
            $ar->remove;
            $ar->remove;
            $ar->remove;
            is( $ar->first->{num}, 7 );
        };

        it "fifth is 9" => sub {
            $ar->remove;
            $ar->remove;
            $ar->remove;
            $ar->remove;
            is( $ar->first->{num}, 9 );
        };


        it "sixth is 10" => sub {
            $ar->remove;
            $ar->remove;
            $ar->remove;
            $ar->remove;
            $ar->remove;
            is( $ar->first->{num}, 10 );
        };

    };


    describe "adds multiple non-dumeric" => sub {
        my $ar;

        before each => sub {
            $ar = Array::Queue::Priority->new(
                sort_cb => sub {
                    $_[0]->{l_name} cmp $_[1]->{l_name}
                });
            $ar->add({ l_name => 'Hess' });
            $ar->add({ l_name => 'Wilco' });
            $ar->add({ l_name => 'Burke' });
            $ar->add({ l_name => 'Robinson' });
            $ar->add({ l_name => 'Wall' });
            $ar->add({ l_name => 'Bates' });
        };

        it "size is 6" => sub {
            is( $ar->size, 6 );
        };

        it "first is Bates" => sub {
            is( $ar->first->{l_name}, 'Bates' );
        };

        it "second is Burke" => sub {
            $ar->remove;
            is( $ar->first->{l_name}, 'Burke' );
        };

        it "third is Hess" => sub {
            $ar->remove;
            $ar->remove;
            is( $ar->first->{l_name}, 'Hess' );
        };

        it "fourth is Robinson" => sub {
            $ar->remove;
            $ar->remove;
            $ar->remove;
            is( $ar->first->{l_name}, 'Robinson' );
        };

        it "fifth is Wall" => sub {
            $ar->remove;
            $ar->remove;
            $ar->remove;
            $ar->remove;
            is( $ar->first->{l_name}, 'Wall' );
        };


        it "sixth is Wilco" => sub {
            $ar->remove;
            $ar->remove;
            $ar->remove;
            $ar->remove;
            $ar->remove;
            is( $ar->first->{l_name}, 'Wilco' );
        };

    };


};

runtests unless caller;

