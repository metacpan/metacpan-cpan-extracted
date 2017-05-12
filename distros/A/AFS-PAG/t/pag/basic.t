#!/usr/bin/perl
#
# Tests for basic AFS::PAG functionality.
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
use strict;
use warnings;

use lib 't/lib';

use Test::RRA qw(use_prereq);
BEGIN { use_prereq('IPC::System::Simple', qw(capturex systemx)) }

# Establish the plan now that we know we're continuing.
use Test::More tests => 6;

# Load the module.
BEGIN { use_ok('AFS::PAG', qw(hasafs haspag setpag unlog)) }

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

# If k_hasafs returns false, we can't run any other tests.
SKIP: {
    if (!hasafs()) {
        skip 'AFS not available', 5;
    }

    # See if we already have tokens.  If so, we can do some other tests.
    my $had_tokens = has_tokens();
    ok(setpag(), 'k_setpag succeeds');
    ok(haspag(), '...and we are now in a PAG');

    # If we had tokens, check to see if k_setpag hides them.
  SKIP: {
        if (!$had_tokens) {
            skip 'cannot check token hiding without existing tokens', 1;
        }
        ok(!has_tokens(), '...and hides existing tokens');
    }

    # Try to obtain tokens with aklog and test unlog.
    my $status = eval { systemx('aklog') };
  SKIP: {
        if ($@ || $status != 0 || !has_tokens()) {
            skip 'aklog cannot obtain tokens, cannot test unlog', 2;
        }
        ok(unlog(),       'unlog succeeds');
        ok(!has_tokens(), '...and we no longer have tokens');
    }
}
