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
use Test::More;

use App::DistSync::LockFile;

# Base call
{
    my $lf = App::DistSync::LockFile->new(file => "test.lock", debug => 0);
    is $lf->pid, $$, "$$ current process by default";

    # Lock
    ok !$lf->lock->error, "$$ lock file" or diag $lf->error;

    # Check
    ok $lf->check, "$$ is locked";

    # Unlock
    ok $lf->unlock, "$$ unlock file";
    #note explain $lf;

    # Check
    ok !$lf->check, "$$ is NOT locked";
}

# Auto call
{
    my $lf = App::DistSync::LockFile->new(file => "test.lock", auto => 1, debug => 0);

    # Check
    ok $lf->check, "$$ is locked";

    # Lock again
    ok !$lf->lock->error, "$$ lock file again" or diag $lf->error;
}

done_testing;

1;

__END__

prove -lv t/02-lock.t
