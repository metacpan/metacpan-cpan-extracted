# $Id: TestShell.pm 42 2013-06-29 20:44:17Z stro $

package TestShell;
use strict;
use warnings;

use CPAN;

# CPAN FrontEnd (default: CPAN::Shell) prints some information to STDOUT, which
# can brake TAP output and mark some tests as out-of-sequence. To avoid this
# problem, myprint and mywarn should be silenced.

$CPAN::FrontEnd = 'TestShell';

sub myprint {
    return;
}

sub mywarn {
    return;
}