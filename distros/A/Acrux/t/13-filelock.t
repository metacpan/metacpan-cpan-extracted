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

my $file = "test13.lock";

subtest "Base call" => sub {
    my $l = Acrux::FileLock->new(file => $file, debug => 0);
    is $l->pid, $$, "$$ current process by default";

    # Lock
    ok !$l->lock->error, "$$ lock file" or diag $l->error;

    # Get owner uid
    my $owner_uid = $l->owner // 0;
    ok $owner_uid, "$$ owner uid" and note "owner uid = $owner_uid";

    # Check
    ok $l->check, "$$ is locked";

    # Unlock
    ok $l->unlock, "$$ unlock file";
    #note explain $l;

    # Check
    ok !$l->check, "$$ is NOT locked";
};

subtest "Auto call" => sub {
    my $l = Acrux::FileLock->new(file => $file, auto => 1, debug => 0);

    # Check
    ok $l->check, "$$ is locked";

    # Lock again
    ok !$l->lock->error, "$$ lock file again" or diag $l->error;
};

subtest "Fork mode" => sub {

    # Parent process
    if (my $child = fork) {
        sleep 1;
        my $l = Acrux::FileLock->new(file => $file, auto => 1);
        note sprintf "Parent PID: %s; Parent Owner PID: %s", $l->pid, $l->own;

        # Check
        ok $l->check, "$$ is locked";

        waitpid $child, 0;
        return;
    }

    # Child process
    else {
        my $l = Acrux::FileLock->new(file => $file, auto => 1);
        unless ($l->check) {
           note sprintf "Start child process (Child PID: %s; Child Owner PID: %s)", $l->pid, $l->owner;
           sleep 3;
           note sprintf "Finish child process (Child PID: %s; Child Owner PID: %s)", $l->pid, $l->owner;
        }
        exit;
    }

};

done_testing;

1;

__END__

prove -lv t/13-filelock.t
