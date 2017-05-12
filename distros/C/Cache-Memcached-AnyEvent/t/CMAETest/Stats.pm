package t::CMAETest::Stats;
use strict;
use t::Util;

sub should_run { 1 }
sub run {
    my ( $pkg, $protocol, $selector) = @_;

    SKIP: {
        my $memd = test_client( protocol_class => $protocol, selector_class => $selector );
        my @servers = @{ $memd->servers };
        if ($protocol eq 'Binary') {
            skip "stats() for Binary protocol unimplemented", scalar @servers;
        }
        my $cv = AE::cv;
        $cv->begin;
        $memd->stats( sub {
            my $stats = shift;

            foreach my $server ( @servers ) {
                is( ref $stats->{$server}, 'HASH', "Stats for $server exists" );
            }
            $cv->end;
        } );
        $cv->recv;
        $memd->disconnect;
    }
    done_testing;
}

1;
