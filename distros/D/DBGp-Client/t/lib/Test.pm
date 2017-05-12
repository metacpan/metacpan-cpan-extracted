package t::lib::Test;

use strict;
use warnings;
use parent 'Test::Builder::Module';

use IPC::Open3 ();
use Test::More;
use Test::DBGp;

our @EXPORT = (
    @Test::More::EXPORT,
    @Test::DBGp::EXPORT,
    qw(
        dbgp_response_cmp
        dbgp_listen
        dbgp_run_fake
    )
);

sub import {
    unshift @INC, 't/lib';

    strict->import;
    warnings->import;

    goto &Test::Builder::Module::import;
}

my ($PID, $CHILD_IN, $CHILD_OUT, $CHILD_ERR);

sub dbgp_run_fake {
    my $port = dbgp_listening_port();
    my $path = dbgp_listening_path();
    $PID = IPC::Open3::open3(
        $CHILD_IN, $CHILD_OUT, $CHILD_ERR,
        $^X, 't/scripts/fake.pl', $port, $path,
    );
}


sub _cleanup {
    return unless $PID;
    kill 9, $PID;
}

END { _cleanup() }

1;
