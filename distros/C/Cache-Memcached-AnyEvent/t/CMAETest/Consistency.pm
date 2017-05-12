package t::CMAETest::Consistency;
use strict;
use AnyEvent;
use Test::More;
use t::Util;
use constant HAVE_CACHE_MEMCACHED => eval {
    require Cache::Memcached;
};

sub should_run {
    return HAVE_CACHE_MEMCACHED;
}

sub run {
    my ($self, $protocol, $selector) = @_;

    SKIP: {
        if ($selector eq 'Ketama') {
warn "Skip because of Ketama";
            skip("Can't test with Ketama", 26);
        }
        my $memd_anyevent = test_client(protocol_class => $protocol, selector_class => $selector);
        my $memd = Cache::Memcached->new({
            servers => [ test_servers() ],
            namespace => $memd_anyevent->{namespace},
        });

        my $key  = random_key();
        my @keys = map { "$key.$_" } ('a'..'z');
        $memd->flush_all;
        foreach my $key (@keys) {
            $memd->set($key, $key);
        }

        my $cv = AE::cv;
        $memd_anyevent->get_multi(\@keys, sub {
            my $values = shift;
            foreach my $key (@keys) {
                is $values->{$key}, $key, "get_multi returned $key";
            }
            $cv->send();
        });

        $cv->recv;
        $memd_anyevent->disconnect;
        $memd->disconnect_all;
    }
    done_testing;
}

1;
