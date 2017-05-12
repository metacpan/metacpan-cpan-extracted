package t::lib::Test;

use strict;
use warnings;
use parent 'Test::Builder::Module';

use IPC::Open3 ();
use Test::More;
use Test::DBGp qw(
    dbgp_parsed_response_cmp
);
use DBGp::Client::AnyEvent::Listener;

our @EXPORT = (
    @Test::More::EXPORT,
    @Test::DBGp::EXPORT,
    qw(
        dbgp_parsed_response_cmp
        dbgp_anyevent_listen
        dbgp_run_fake
    )
);

sub import {
    unshift @INC, 't/lib';

    strict->import;
    warnings->import;

    goto &Test::Builder::Module::import;
}

my ($LISTEN, $PORT, $PATH);

sub dbgp_anyevent_listen {
    if ($^O eq 'MSWin32') {
        dbgp_anyevent_listen_tcp(@_);
    } else {
        dbgp_anyevent_listen_unix(@_);
    }
}

sub dbgp_anyevent_listen_tcp {
    return if $LISTEN;

    for my $port (!$PORT ? (17000 .. 19000) : ($PORT)) {
        eval {
            my $listener = DBGp::Client::AnyEvent::Listener->new(
                port            => $port,
                on_connection   => $_[0],
            );
            $listener->listen;
            $LISTEN = $listener;
        };
        next unless $LISTEN;

        $PORT = $port;
        $PATH = undef;
        last;
    }

    die "Unable to open a listening socket in the 17000 - 19000 port range"
        unless $LISTEN;
}

sub dbgp_anyevent_listen_unix {
    return if $LISTEN;

    my $path = $PATH;
    if (!$path) {
        $path = File::Spec::Functions::rel2abs('dbgp.sock', Cwd::getcwd());

        if (length($path) >= 90) { # arbitrary, should be low enough
            my $tempdir = File::Temp::tempdir(CLEANUP => 1);
            $path = File::Spec::Functions::rel2abs('dbgp.sock', $tempdir);
        }
    }
    unlink $path if -S $path;
    return if -e $path;

    my $listener = DBGp::Client::AnyEvent::Listener->new(
        path            => $path,
        on_connection   => $_[0],
    );
    $listener->listen;
    $LISTEN = $listener;
    $PORT = undef;
    $PATH = $path;

    die "Unable to open a listening socket on '$path'"
        unless $LISTEN;
}

my ($PID, $CHILD_IN, $CHILD_OUT, $CHILD_ERR);

sub dbgp_run_fake {
    $PID = IPC::Open3::open3(
        $CHILD_IN, $CHILD_OUT, $CHILD_ERR,
        $^X, 't/scripts/fake.pl', $PORT, $PATH,
    );
}

sub _cleanup {
    return unless $PID;
    kill 9, $PID;
}

END { _cleanup() }

1;
