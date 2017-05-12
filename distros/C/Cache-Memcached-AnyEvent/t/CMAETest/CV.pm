package t::CMAETest::CV;
use strict;
use t::Util;

sub should_run { 1 }

sub run {
    my ($pkg, $protocol, $selector) = @_;
    my $memd = test_client(protocol_class => $protocol, selector_class => $selector);

    my $key = random_key();
    my @keys = map { "commands-$_" } (1..4);

    my $cv_called = 0;
    my $cv = AE::cv { 
        ok(1, "delete 'returns' ok");
        $cv_called++;
    };
    $memd->delete($key, $cv);
    $cv->recv;

    ok $cv_called, "cv called";

    $cv_called = 0;
    $cv = AE::cv {
        ok($_[0]->recv, "set ok");
        $cv_called++;
    };
    $memd->set($key, "foo", $cv);
    $cv->recv;
    ok $cv_called, "cv called";

    $cv_called = 0;
    $cv = AE::cv {
        is($_[0]->recv, "foo", "get ok");
        $cv_called++;
    };
    $memd->get($key, $cv);
    $cv->recv;
    ok $cv_called, "cv called";

    $memd->disconnect();
    done_testing();
}

1;