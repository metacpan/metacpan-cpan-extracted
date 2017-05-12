# $Id$

use strict;
use Data::YUID;
use Data::YUID::Generator;
use Test::More 'no_plan';
use Time::HiRes;

## basic test
{
    my $gen = Data::YUID::Generator->new;
    isa_ok($gen, 'Data::YUID::Generator');
    my $id1 = $gen->get_id;
    ok($id1);
    my $id2 = $gen->get_id;
    isnt($id1, $id2);
}

## test component of the id
{
    my $gen = Data::YUID::Generator->new;
    my $id1 = $gen->get_id;
    my $id2 = $gen->get_id;

    is (Data::YUID->host($id1), Data::YUID->host($id2)), "same host";
    my $serial1 = Data::YUID->serial($id1);
    my $serial2 = Data::YUID->serial($id2);
    my $ts1 = Data::YUID->timestamp($id1);
    my $ts2 = Data::YUID->timestamp($id2);

    if ($ts1 == $ts2) {
        is $serial1, 0, "First serial";
        is $serial2, $serial1 + 1, "next one";
    }
    else {
        is $serial1, 0, "First serial";
        is $serial2, 0, "First serial of different ts";
    }
}

## Now exhaust serial
{
    my $gen = Data::YUID::Generator->new;
    my $prev_ts;
    my $tries = 5;
    AGAIN:
    $tries--;
    for (0..Data::YUID::Generator->SERIAL_MAX) {
        my $id = $gen->get_id;
        my $serial = Data::YUID->serial($id);
        $prev_ts = Data::YUID->timestamp($id) unless $prev_ts;
        if ($_ && $serial != $_) {
            my $ts = Data::YUID->timestamp($id);
            is $ts, $prev_ts, "switched over second boundary";
            is $serial, 0, "so serial is 0 again";
            $prev_ts = undef;
            if ($tries == 0) {
                fail "cpu too slow to go over serial in less than a second";
                last;
            }
            diag "let's do it again";
            goto AGAIN;
        }
    }
    my $id = $gen->get_id;
    if (! $id) {
        is $id, undef, "serial exhausted $prev_ts";
        sleep_to_next_sec();
    }
    else {
        my $ts = Data::YUID->timestamp($id);
        is $ts, $prev_ts + 1, "switched over sec boundary after loop";
    }
    $id = $gen->get_id;
    my $ts = Data::YUID->timestamp($id);
    isnt $id, undef, "can generate ids again $ts";
}

## check that timestamp is increment at every second
{
    my $gen = Data::YUID::Generator->new;
    my $id = $gen->get_id;
    my $ts = Data::YUID->timestamp($id);
    sleep_to_next_sec();
    my $id2 = $gen->get_id;
    my $ts2 = Data::YUID->timestamp($id2);
    is $ts2, $ts + 1, "this is next sec $ts vs $ts2";
}

sub sleep_to_next_sec {
    (undef, my $us) = Time::HiRes::gettimeofday;
    my $diff = 1_000_000 - $us + 1;
    diag "sleeping until next sec ($diff µs)";
    Time::HiRes::usleep($diff);
}
#done_testing();
