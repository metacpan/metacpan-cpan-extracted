#!perl -T

use strict;

use Test::More qw/no_plan/;
use Test::Deep;

use Data::KeyDiff qw/diff/;

my (@new, @insert, @update, @delete, @update_rank);

sub _diff($$) {
    my $A = shift;
    my $B = shift;

    undef @new;
    undef @insert;
    undef @update;
    undef @delete;
    undef @update_rank;

    diff( $A, $B,
        key =>
            sub {
                return substr shift, 0, 1;
            },

        is_different =>
            sub {
                my $left = shift;
                my $right = shift;
                return substr($left, 1) ne substr($right, 1);
            },

        is_new =>
            sub {
                return shift !~ m/^\d/;
            },

        # "j" and "n" are new!
        new => sub {
            push @new, shift->value;
        },

        # "7q" was inserted (already had a key)
        insert => sub {
            push @insert, shift->value;
        },

        # "1f" and "3r" were updated
        update => sub {
            push @update, shift->value;
        },

        # "6f" was deleted
        delete => sub {
            push @delete, shift->value;
            # $element was "deleted" in @B
        },
        
        # "5e", "2b", and "4d" changed rank
        update_rank => sub {
            push @update_rank, shift->value;
        },
    );
}

{
    my @A = qw/1a 2b 3c 4d 5e 6f/;
    my @B = qw/5e 1f 2b 3r 4d 7q j n/;

    _diff \@A, \@B;

    cmp_bag(\@new, [qw/j n/]);
    cmp_bag(\@insert, [qw/7q/]);
    cmp_bag(\@update, [qw/1f 3r/]);
    cmp_bag(\@delete, [qw/6f/]);
    cmp_bag(\@update_rank, [qw/4d 2b 5e/]);
}

_diff [], [qw/a b c d e f/];
cmp_bag(\@new, [qw/a b c d e f/]),
cmp_bag($_, []) for (\@insert, \@update, \@delete, \@update_rank);

_diff [], [qw/1a 2b 3c 4d 5e 6f/];
cmp_bag(\@insert, [qw/1a 2b 3c 4d 5e 6f/]),
cmp_bag($_, []) for (\@new, \@update, \@delete, \@update_rank);

_diff [qw/1a 2b 3c 4d 5e 6f/], [];
cmp_bag(\@delete, [qw/1a 2b 3c 4d 5e 6f/]),
cmp_bag($_, []) for (\@new, \@update, \@insert, \@update_rank);

_diff [qw/1a 2b 3c 4d 5e 6f/], [qw/1g 2h 3i 4j 5k 6l/];
cmp_bag(\@update, [qw/1g 2h 3i 4j 5k 6l/]),
cmp_bag($_, []) for (\@new, \@delete, \@insert, \@update_rank);

_diff [qw/1a 2b 3c 4d 5e 6f/], [qw/2b 3c 4d 5e 6f 1a/];
cmp_bag(\@update_rank, [qw/2b 3c 4d 5e 6f 1a/]),
cmp_bag($_, []) for (\@new, \@delete, \@insert, \@update);
