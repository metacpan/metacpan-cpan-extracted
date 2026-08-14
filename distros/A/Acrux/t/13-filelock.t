#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use strict;
use Test::More;

use Acrux::FileLock;

use constant DEBUG => !!($ENV{ACRUX_FILELOCK_DEBUG} || 0);
use constant FLOCK => !!($ENV{ACRUX_FILELOCK_FLOCK} || 0);

my $file = "test13.lock";
note "Current PID=$$";

subtest "Base call" => sub {
    my $l = Acrux::FileLock->new(file => $file, debug => DEBUG, flock => FLOCK);
    is $l->pid, $$, "$$ current process by default";

    # Lock
    ok !$l->lock->error, "$$ lock file" or diag $l->error;

    # Check
    ok $l->check, "$$ is locked";

    # Get owner uid
    if (my $owner_uid = $l->uid) {
        is $owner_uid, $>, "$$ owner uid" and note "owner uid = $owner_uid";
    }

    # Unlock
    ok $l->unlock, "$$ unlock file";
    #note explain $l;

    # Check
    ok !$l->check, "$$ now is NOT locked";
};

subtest "Auto call" => sub {
    my $l = Acrux::FileLock->new(file => $file, auto => 1, debug => DEBUG, flock => FLOCK);

    # Check
    ok $l->check, "$$ is locked";

    # Lock again
    ok !$l->lock->error, "$$ lock file again" or diag $l->error;
};

subtest "Fork mode" => sub {

    # Parent process
    if (my $child = fork) {
        sleep 1;
        my $l = Acrux::FileLock->new(file => $file, auto => 1, flock => FLOCK);
        note sprintf "Parent PID: %s; Parent Owner PID: %s", $l->pid, $l->own;

        # Check
        ok $l->check, "$$ is locked";

        waitpid $child, 0;
        return;
    }

    # Child process
    else {
        my $l = Acrux::FileLock->new(file => $file, auto => 1, flock => FLOCK);
        unless ($l->check) {
           note sprintf "Start child process (Child PID: %s; Child Owner PID: %s)", $l->pid, $l->uid;
           sleep 3;
           note sprintf "Finish child process (Child PID: %s; Child Owner PID: %s)", $l->pid, $l->uid;
        }
        exit;
    }

};


done_testing;

1;

__END__

ACRUX_FILELOCK_DEBUG=1 ACRUX_FILELOCK_FLOCK=1 prove -lv t/13-filelock.t
