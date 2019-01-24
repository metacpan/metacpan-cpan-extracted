# $Id: TestShellDiag.pm 71 2019-01-15 01:46:34Z stro $

package TestShellDiag;
use strict;
use warnings;
use Test::More ();

use CPAN;

# CPAN FrontEnd (default: CPAN::Shell) prints some information to STDOUT, which
# can brake TAP output and mark some tests as out-of-sequence. To avoid this
# problem, myprint and mywarn should be silenced.

$CPAN::FrontEnd = 'TestShellDiag';

sub myprint {
  return Test::More::diag(splice(@_, 1));
}

sub mywarn {
  return Test::More::diag(splice(@_, 1));
}
