package t::Util;
use strict;
use warnings;
use base qw/Exporter/;
use Test::More;
use Test::Requires qw/Test::TCP File::Which/;

our @EXPORT = qw/test_kt/;

sub test_kt {
    my $cb = shift;
    my $server_cb = shift;

    my $ktserver = scalar(which 'ktserver');
    plan skip_all => 'This test requires "ktserver"' unless $ktserver;

    test_tcp(
        client => $cb,
        port => Test::TCP::empty_port(10000), # kt cannot use 50000+ number as a port number
        server => $server_cb ? sub { $server_cb->(shift, $ktserver) } : sub {
            my $port = shift;
            exec $ktserver, '-port', $port;
            die "cannot exec ktserver";
        },
    );
}

1;
