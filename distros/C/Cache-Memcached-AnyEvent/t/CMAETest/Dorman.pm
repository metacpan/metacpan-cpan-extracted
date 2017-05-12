package t::CMAETest::Dorman;
use strict;
use t::Util;

sub should_run { 1 }
sub run {
    my ($pkg, $protocol, $selector) = @_;

    { # populate
        my $cv = AE::cv;
        my $mc = test_client(
            protocol_class => $protocol,
            selector_class => $selector,
            namespace => 'mytest.') or die;
        $cv->begin;
        $mc->flush_all( sub {
            $mc->set (foo => bar => sub {
                my $rc = shift;
                is $rc, 1, 'Success setting key';
                $cv->end;
            });
        } );
        $cv->recv;
        $mc->disconnect;
    }

    { # run once with regular server list
        my $cv = AE::cv;
        my $mc = test_client(
            protocol_class => $protocol,
            selector_class => $selector,
            namespace => 'mytest.') or die;
        $cv->begin;
        $mc->get (foo => sub {
            my $value = shift;
            is $value, 'bar', 'Success getting key';
            $cv->end;
        });
        $cv->recv;
        $mc->disconnect;
    }

    { # run another time, but this time shuffle round the server
      # list before creating a client
        my @servers = reverse split /\s*,\s*/, $ENV{PERL_ANYEVENT_MEMCACHED_SERVERS};
        
        local $ENV{PERL_ANYEVENT_MEMCACHED_SERVERS} = join(',', @servers);
        my $cv = AE::cv;
        my $mc = test_client(
            protocol_class => $protocol,
            selector_class => $selector,
            namespace => 'mytest.') or die;
        $cv->begin;
        $mc->get (foo => sub {
            my $value = shift;
            is $value, 'bar', 'Success getting key';
            $cv->end;
        });
        $cv->recv;
        $mc->disconnect;
    }
    done_testing;
}

1;