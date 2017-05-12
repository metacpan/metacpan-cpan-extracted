#!/usr/bin/env perl -w -I ..
#
# ... Tests via check_template-mail-xml-fingerprint-xml-monitoring.pl
#
# $Id: check_template-mail-xml-fingerprint-xml-monitoring.t, v 1.0 2006/03/18 Alex Peeters Exp $
#

use strict;
use Test;
use ASNMTAP::Asnmtap::Plugins::NPTest;

use vars qw($tests);
BEGIN {$tests = 3; plan tests => $tests}

my $t;
my $prefix = '../plugins/templates';
my $plugin = 'check_template-mail-xml-fingerprint-xml-monitoring.pl';

if ( -x "$prefix/$plugin" ) {
  $t += checkCmd( "$prefix/$plugin -V", 3, "/$plugin/");
  $t += checkCmd( "$prefix/$plugin -h", 3);
} else {
  $t += skipMissingCmd( "$prefix/$plugin", $tests );
}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);
