use utf8;
use strict;
use warnings;

package Check::XlogCleanup;
use Coro::AnyEvent;
use File::Spec::Functions 'catfile';
use AnyEvent::Socket;
use AnyEvent;
use Encode 'decode_utf8';
use Coro;

sub start {
    my (undef, $tarantool, $primary_pid) = @_;

    Coro::schedule unless $primary_pid == $$;
    my $csocket;
    my $watcher;
    my $c = tcp_connect '127.0.0.1', $tarantool->admin_port, sub {
        my ($fh) = @_;
        $csocket = $fh;
        $watcher = AE::io $fh, 0, sub {
            my $data;
            undef $watcher unless defined sysread $fh, $data, 1024;
        };
    };
    while(1) {
        Coro::AnyEvent::sleep 20;
        next unless $tarantool;
        df 'Cleanup *.xlog files in: %s', $tarantool->temp_dir;


        my @xlogs = sort glob catfile $tarantool->temp_dir, '*.xlog';
        while(@xlogs > cfg 'check.xlogcleanup.keep_xlogs') {
            my $name = shift @xlogs;
            df 'unlink %s', $name;
            unlink $name;
        }
        my @snaps = sort glob catfile $tarantool->temp_dir, '*.snapshot';
        while(@snaps > cfg 'check.xlogcleanup.keep_snapshots') {
            my $name = shift @snaps;
            df 'unlink %s', $name;
            unlink $name;
        }

        if ($csocket) {
            df 'create new snapshot';
            die decode_utf8 $! unless defined
                syswrite $csocket, "save snapshot\n";
        }


    }
};

1;
