#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
#     `perl Algorithm::Pair::Best2.t'

#########################

use strict;
use IO::File;
use Test::More tests => 23;

BEGIN {
    use_ok('Algorithm::Pair::Best2')
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

##
## create Best2 object.
##

for (1 .. 1) {
    my $progress = 0;
    my $pair = new_ok('Algorithm::Pair::Best2' => [
            scoreSub => sub { # difference in rating.
                my ($item_0, $item_1) = @_;
                # print sprintf "comparing $item_0 with $item_1, returning %d\n", abs($item_0 - $item_1);
                return abs($item_0 - $item_1);
            },
            progress => sub {
                my ($item0, $item1) = @_;
                $progress++;    # notice that progress has been made
                # print "paired $item0 with $item1\n";
            },
        ],
    );

    # use List::Util qw (shuffle );
    my @pairs = (51, 31, 41, 21, 20, 20, 31, 21, 52, 42, 41, 51, 42, 52);
    my $num_items = @pairs;
    printf "pairs: %s\n", join ', ', @pairs;
    $pair->add(@pairs);
    @pairs = $pair->pick($num_items / 2);
    printf " =>    %s\n", join ', ', @pairs;
    is ($progress, @pairs / 2,      'progress was made');
    is (@pairs, $num_items,         'right number of items paired');

    my $idx = 0;
    foreach $idx (0 .. ($num_items / 2) - 1) {
        is ($pairs[2 * $idx], $pairs[2 * $idx + 1], "result $idx is good");
    }
}

my $progress = 0;
my $pair2 = new_ok('Algorithm::Pair::Best2' => [
        scoreSub => sub { # difference in rating.
            my ($item_0, $item_1) = @_;
            return (abs($item_0->{rating} - $item_1->{rating}));
        },
        progress => sub {
            my ($item0, $item1) = @_;
            $progress++;    # notice that progress has been made
            print "paired $item0->{id} with $item1->{id}\n";
        },
    ]
);

my $idx = 0;
foreach (3, 4, 2, 2.1, 2.7, 1.7, 6, 5.55) {
    $pair2->add( {
            id => "item $idx",
            rating => $_,
        },
    );
    $idx++;
}

$progress = 0;
my @pairs = $pair2->pick(2);
is( $@, '',                     'return from pick method');
is ($progress, 4,               'progress was made');
is (@pairs, 8,                  'right number of items paired');

$idx = 0;
foreach (0, 1, 2, 5, 3, 4, 6, 7) {
    is ($pairs[$idx]->{id}, "item $_", "result $idx is good");
    $idx++;
}
