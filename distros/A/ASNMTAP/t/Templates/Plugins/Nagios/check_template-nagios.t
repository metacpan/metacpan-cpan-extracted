#!/usr/bin/env perl -w -I ..
#
# ... Tests via check_template-nagios.pl
#
# $Id: check_template-nagios.t, v 1.0 2006/02/01 Alex Peeters Exp $
#

use strict;
use Test;
use ASNMTAP::Asnmtap::Plugins::NPTest;

use vars qw($tests);
BEGIN {$tests = 5; plan tests => $tests}

my $t;
my $prefix = '../plugins/nagios/templates';
my $plugin = 'check_template-nagios.pl';

if ( -x "$prefix/$plugin" ) {
  $t += checkCmd( "$prefix/$plugin -V", 3, "/$plugin/");
  $t += checkCmd( "$prefix/$plugin -h", 3);
  $t += checkCmd( "$prefix/$plugin", [0, 1, 2], "/OKIDO/");
} else {
  $t += skipMissingCmd( "$prefix/$plugin", $tests );
}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);
