#!/usr/bin/perl
#
# Test that creating a PAG isolates token changes from the caller
#
# Written by Russ Allbery <rra@cpan.org>
# Copyright 2013
#     The Board of Trustees of the Leland Stanford Junior University
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

use 5.010;
use autodie;
use strict;
use warnings;

use lib 't/lib';

use Test::RRA qw(use_prereq);
BEGIN { use_prereq('IPC::System::Simple', qw(capturex systemx)) }

# Establish the plan now that we know we're continuing.
use Test::More tests => 3;

# Load the module.
BEGIN { use_ok('AFS::PAG', qw(hasafs setpag unlog)) }

# Determines if the user has valid tokens by running tokens.
#
# Returns: True if the user has valid tokens, false if not or if tokens fails
sub has_tokens {
    my $tokens = eval { capturex('tokens') };
    if (!$@ && $tokens =~ m{ [ ] tokens [ ] for [ ] }xmsi) {
        return 1;
    } else {
        return;
    }
}

# We need AFS support and existing tokens to run this test.
SKIP: {
    if (!hasafs() || !has_tokens()) {
        skip 'AFS tokens not available', 2;
    }

    # Fork off a child that creates a new PAG and then runs unlog.  This
    # should not affect the tokens in our parent process.
    my $pid = fork;
    if ($pid == 0) {
        setpag();
        unlog();
        exit(0);
    } else {
        waitpid($pid, 0);
    }

    # Check that the child calls succeeded.
    is($?, 0, 'Child setpag and unlog succeeded');

    # Check that we still have tokens.
    ok(has_tokens(), 'Parent process still has tokens');
}
