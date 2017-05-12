#!/usr/bin/env perl

use warnings;
use strict;
use Test::More tests => 16;


# 431234 gets
# block_range 431234
# block_exact 4
# block_exact 43
# block_exact 431
# block_exact 4312
# block_exact 43123
# block_exact 431234
#
# 4312 fails because of block_exact 4312
#
# 4312345 fails because of block_range 431234
#
# 431235 ok because neither block_exact 431235 nor block_range 4, block_range
# 43, ..., or block_range 431235
#
# block_range new number fails if there is an block_exact lock for itself or
# an block_range lock for any leading substring of itself.


# returns 1 on success, undef on failure

sub get_locks_for_number {
    my $number = shift;

    print "#\n";
    print "# getting meta lock\n";
    print "# trying to get locks for [$number]\n";
    our %locks;

    if ($locks{block_exact}{$number}) {    # EXC
        print "# exact number [$number] is blocked, aborting\n";
        print "# releasing meta lock\n";
        return;
    }

    local $_ = $number;
    my @substr;
    while (length()) {
        push @substr => $_;
        chop;
    }

    for my $substr (@substr) {
        if ($locks{block_range}{$substr}) {    # EXC
            print "# range [$substr] is blocked, aborting\n";
            print "# releasing meta lock\n";
            return;
        }
    }

    $locks{block_range}{$number}++;
    $locks{block_exact}{$_}++ for @substr;   # convert to SHARED

    print "# releasing meta lock\n";

    return 1;   # indicate ok
}


sub release_locks_for_number {
    my $number = shift;
    print "#\n";
    print "# releasing locks for [$number]\n";
    our %locks;

    $locks{block_range}{$number}--;
    delete $locks{block_range}{$number} unless $locks{block_range}{$number};

    local $_ = $number;
    my @substr;
    while (length()) {
        push @substr => $_;
        chop;
    }

    for (@substr) {
        $locks{block_exact}{$_}--;
        delete $locks{block_exact}{$_} unless $locks{block_exact}{$_};
    }
}


sub reset_locks {
    our %locks = ();
    print "# resetting locks\n";
}


sub dump_locks {
    our %locks;
    use Data::Dumper;
    print Dumper \%locks;
}


sub test_ok_locks {
    my $number = shift;
    ok(get_locks_for_number($number), "OK get_locks_for_number($number)");
    dump_locks;
}


sub test_not_ok_locks {
    my $number = shift;
    ok(!get_locks_for_number($number), "NOT OK get_locks_for_number($number)");
    dump_locks;
}


sub test_locks_are_empty {
    our %locks;
    is_deeply(($locks{block_exact} || {}), {}, 'no exact numbers are blocked');
    is_deeply(($locks{block_range} || {}), {}, 'no numbers ranges are blocked');
}


reset_locks();
test_ok_locks(431234);
test_not_ok_locks(431234);
test_not_ok_locks(4312);
test_not_ok_locks(4312345);
test_ok_locks(431235);
release_locks_for_number(431234);
release_locks_for_number(431235);
test_locks_are_empty;

test_ok_locks(4312);
test_not_ok_locks(4312345);
test_not_ok_locks(431235);
release_locks_for_number(4312);
test_locks_are_empty;

test_ok_locks(4312345);
test_ok_locks(431235);
release_locks_for_number(4312345);
release_locks_for_number(431235);
test_locks_are_empty;
