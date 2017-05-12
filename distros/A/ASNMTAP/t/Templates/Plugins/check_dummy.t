#!/usr/bin/env perl -w -I ..
#
# ... Tests via check_dummy.pl
#
# $Id: check_dummy.t, v 1.0 2006/02/01 Alex Peeters Exp $
#

use strict;
use Test;
use ASNMTAP::Asnmtap::Plugins::NPTest;

use vars qw($tests);
BEGIN {$tests = 8; plan tests => $tests}

my $t;
my $prefix = '../plugins/templates';
my $plugin = 'check_dummy.pl';

if ( -x "$prefix/$plugin" ) {
  $t += checkCmd( "$prefix/$plugin -V", 3, "/$plugin/");
  $t += checkCmd( "$prefix/$plugin -h", 3);
  $t += checkCmd( "$prefix/$plugin -r 0", 0);
  $t += checkCmd( "$prefix/$plugin -r 1", 1);
  $t += checkCmd( "$prefix/$plugin -r 2", 2);
  $t += checkCmd( "$prefix/$plugin -r 3", 3);
  $t += checkCmd( "$prefix/$plugin -r 4", 3);
} else {
  $t += skipMissingCmd( "$prefix/$plugin", $tests );
}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);