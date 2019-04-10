#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Algorithm::Backoff::Constant;

# XXX test max_attempts for each strategy
subtest "attr: max_attempts" => sub {
    my $ar;

    $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        max_attempts => 0,
    );
    isnt($ar->failure(1), -1);
    isnt($ar->failure(2), -1);
    isnt($ar->failure(3), -1);

    $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        max_attempts => 1,
    );
    is($ar->failure(1), -1);

    $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        max_attempts => 2,
    );
    isnt($ar->failure(1), -1);
    is  ($ar->failure(1), -1);
    $ar->success(1);
    isnt($ar->failure(1), -1);
    is  ($ar->failure(1), -1);
};

# XXX test for each strategy
subtest "attr: consider_actual_delay" => sub {
    my $ar;

    $ar = Algorithm::Backoff::Constant->new(
        consider_actual_delay => 1,
        delay => 2,
        max_attempts => 0,
    );

    is($ar->failure(1), 2);

    # we didn't wait, so the delay is now 2+2 = 4
    is($ar->failure(1), 4);

    # we now waited for 5 seconds, so delay is now 2-1 = 1
    is($ar->failure(6), 1);

    # we now waited for 2 seconds, so delay is now 2-1 = 1
    is($ar->failure(8), 1);

    # we now waited for 3 seconds, so delay is now 2-2 = 0
    is($ar->failure(11), 0);
};

# XXX test each strategy
subtest "attr: jitter_factor" => sub {
    my $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
        delay_on_success => 3,
        jitter_factor => 0.1,
    );

    rand_between_ok(sub { $ar->failure(1) }, 2*(1-0.1), 2*(1+0.1));
    rand_between_ok(sub { $ar->success(1) }, 3*(1-0.1), 3*(1+0.1));
};

subtest "timestamp must not decrease" => sub {
    my $ar = Algorithm::Backoff::Constant->new(
        delay => 2,
    );

    $ar->success(2);
    dies_ok { $ar->success(1) };
};

DONE_TESTING:
done_testing;

# XXX temporary function
sub rand_between_ok(&$$) {
    my ($block, $min, $max, $name) = @_;
    my @res;
    my %res;
    for (1..10) {
        my $res = $block->();
        do {
            ok(0, "Result #$_ is not between $min and $max");
            last;
        } if $res < $min || $res > $max;
        push @res, $res;
        $res{ $res+0 }++;
    }
    note "Results: ", explain(\@res);
    keys(%res) > 1 or
        ok(0, "Results do not seem to be random, but constant $res[0]");
    ok(1, "Results are random between $min and $max");
}
