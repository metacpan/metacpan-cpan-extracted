#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Algorithm::Retry::Constant;

# XXX test max_attempts for each strategy
subtest "attr: max_attempts" => sub {
    my $ar;

    $ar = Algorithm::Retry::Constant->new(
        delay_on_failure => 2,
        max_attempts => 0,
    );
    isnt($ar->failure(1), -1);
    isnt($ar->failure(2), -1);
    isnt($ar->failure(3), -1);

    $ar = Algorithm::Retry::Constant->new(
        delay_on_failure => 2,
        max_attempts => 1,
    );
    is($ar->failure(1), -1);

    $ar = Algorithm::Retry::Constant->new(
        delay_on_failure => 2,
        max_attempts => 2,
    );
    isnt($ar->failure(1), -1);
    is  ($ar->failure(1), -1);
    $ar->success(1);
    isnt($ar->failure(1), -1);
    is  ($ar->failure(1), -1);
};

# XXX test timestamp for each strategy
subtest "arg: timestamp" => sub {
    my $ar;

    $ar = Algorithm::Retry::Constant->new(
        delay_on_failure => 2,
        max_attempts => 0,
    );

    is($ar->failure(1), 2);
    # we have waited for a second, so the delay is just 2-1 = 1 sec
    is($ar->failure(2), 1);
    # we have waited for two seconds, so the delay is just 2-2 = 0 sec
    is($ar->failure(4), 0);
    # we have waited for three seconds, so the delay is just 0 sec
    is($ar->failure(7), 0);
    # we haven't waited, so the delay is still 2 secs
    is($ar->failure(7), 2);
};

# XXX test each strategy
subtest "attr: jitter_factor" => sub {
    my $ar = Algorithm::Retry::Constant->new(
        delay_on_failure => 2,
        delay_on_success => 3,
        jitter_factor => 0.1,
    );

    rand_between_ok(sub { $ar->failure(1) }, 2*(1-0.1), 2*(1+0.1));
    rand_between_ok(sub { $ar->success(1) }, 3*(1-0.1), 3*(1+0.1));
};

subtest "timestamp must not decrease" => sub {
    my $ar = Algorithm::Retry::Constant->new(
        delay_on_failure => 2,
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
