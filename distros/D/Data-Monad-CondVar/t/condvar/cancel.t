use strict;
use warnings;
use Data::Monad::CondVar;
use Test::More;

sub _after_dot_4(&) {
    my $code = shift;
    return cv_unit->sleep(.04)->flat_map(sub {
        cv_unit->sleep(.04)->map($code);
    });
}

subtest 'flat_map_and_sleep' => sub {
    {
        my $shouldnt_reach;
        my $cv = _after_dot_4 { $shouldnt_reach++ };

        # cancel when it sleeps to the first time
        cv_unit->sleep(.02)->map(sub {
            $cv->cancel;
        })->sleep(.08)->recv;

        ok ! $cv->ready;
        ok ! $shouldnt_reach;
    };

    {
        my $shouldnt_reach;
        my $cv = _after_dot_4 { $shouldnt_reach++ };

        # cancel when it sleeps to the second time
        cv_unit->sleep(.06)->map(sub {
            $cv->cancel;
        })->sleep(.04)->recv;

        ok ! $cv->ready;
        ok ! $shouldnt_reach;
    };

    {
        my $shouldnt_reach;
        my $cv = _after_dot_4 { $shouldnt_reach++; "OK" };

        # cancel after it was finished
        cv_unit->sleep(.1)->map(sub {
            $cv->cancel;
        })->recv;

        is $cv->recv, "OK";
        ok $shouldnt_reach;
    }
};

subtest 'flat_map_restriction' => sub {
    my $should_be_canceled;
    my $shouldnt_be_canceled;
    my $outer_cv = _after_dot_4 { $shouldnt_be_canceled++ };
    _after_dot_4 { $should_be_canceled++ }
        ->flat_map(sub { $outer_cv })
        ->cancel;
    cv_unit->sleep(.18)->recv;

    ok ! $should_be_canceled;
    ok $shouldnt_be_canceled, "flat_map() can't cancel outer cv.";

};

subtest 'call_cc' => sub {
    my $should_be_canceled;
    my $cv = call_cc {
        my $cont = shift;
        cv_unit->sleep(.04)->flat_map(sub {
            $should_be_canceled++;
            $cont->('OK');
        })->map(sub { $should_be_canceled++ });
    };

    cv_unit->sleep(.02)->map(sub { $cv->cancel })
           ->sleep(.04)->recv;
    ok ! $cv->ready;
    ok ! $should_be_canceled;
};

subtest 'or_right' => sub {
    my $done;
    my $cv = cv_unit->sleep(.04)->map(sub { $done++ })->or(
        cv_unit->sleep(.04)->map(sub { $done++ })
    );
    cv_unit->sleep(.02)->map(sub { $cv->cancel })->sleep(.04)->recv;

    ok ! $cv->ready;
    ok ! $done;
};

subtest 'or_left' => sub {
    my $done;
    my $cv = cv_zero("ERROR")->or(
        cv_unit->sleep(.04)->map(sub { $done++ })
    );

    cv_unit->sleep(.02)->map(sub { $cv->cancel })->sleep(.04)->recv;

    ok ! $cv->ready;
    ok ! $done;
};

subtest 'catch' => sub {
    {
        my $done;
        my $cv = cv_fail->catch(sub {
            cv_unit->sleep(.04)->map(sub { $done++ });
        });

        cv_unit->sleep(.02)->map(sub { $cv->cancel })->sleep(.04)->recv;

        ok ! $cv->ready;
        ok ! $done;
    }

    {
        my $done;
        my $cv = cv_unit->sleep(.04)->flat_map(sub { cv_fail })->catch(sub {
            $done++;
        });

        cv_unit->sleep(.02)->map(sub { $cv->cancel })->sleep(.04)->recv;

        ok ! $cv->ready;
        ok ! $done;
    }
};

subtest 'timeout' => sub {
    my $done;
    my $cv = cv_unit->sleep(.06)->map(sub { $done++ })->timeout(.04);

    cv_unit->sleep(.02)->map(sub { $cv->cancel })->sleep(.06)->recv;

    ok ! $cv->ready;
    ok ! $done;
};

subtest 'any' => sub {
    my $done;
    my $cv = AnyEvent::CondVar->any(
        cv_unit("NG")->sleep(.06)->map(sub { $done++ }),
        cv_unit("OK")->sleep(.04)->map(sub { $done++ }),
        cv_unit("NG")->sleep(.08)->map(sub { $done++ }),
    );

    cv_unit->sleep(.02)->map(sub { $cv->cancel })->sleep(.08)->recv;

    ok ! $cv->ready;
    ok ! $done;
};

subtest 'all' => sub {
    my $done;
    my $cv = AnyEvent::CondVar->all(
        cv_unit("NG")->sleep(.06)->map(sub { $done++ }),
        cv_unit("OK")->sleep(.04)->map(sub { $done++ }),
        cv_unit("NG")->sleep(.08)->map(sub { $done++ }),
    );

    cv_unit->sleep(.02)->map(sub { $cv->cancel })->sleep(.08)->recv;

    ok ! $cv->ready;
    ok ! $done;
};

done_testing;
