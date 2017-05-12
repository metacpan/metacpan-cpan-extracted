package t::CMAETest::ConnectFail;
use strict;
use Test::More;
use t::Util;

sub should_run { 1 }
sub run {
    my ($pkg, $protocol, $selector) = @_;
    my $memd = test_client(protocol_class => $protocol, selector_class => $selector);

    my $bogus_server = 'you.should.not.be.able.to.connect.to.me:11211';
    $memd->add_server( $bogus_server );

    my $key_base = random_key();
    my $value = join('.', time(), $$, {}, rand());

    my $cv = AE::cv;

    my $warn_called = 0;
    local $SIG{__WARN__} = sub {
#        like( $_[0], qr/^failed to connect to $bogus_server/);
        if ( $_[0] =~ /^failed to connect to $bogus_server/ ) {
            $warn_called++;
        } else {
            warn @_;
        }
    };

    foreach my $i (1..50) {
        my $key = $key_base . $i;
        $cv->begin;
        $memd->set($key, $value, sub {
            if (ok($_[0], "set $key works")) {
                $memd->get($key, sub {
                    is ($_[0], $value, "values match for $key");
                    $cv->end;
                });
            }
        });
    }

    $cv->recv;

    ok $warn_called, "warn properly called";

    $memd->disconnect;
    done_testing;
}

1;
