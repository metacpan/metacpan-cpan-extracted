#!/usr/bin/env perl -w -I ..
#
# ... Tests via check_template-WebTransact.pl
#
# $Id: check_template-WebTransact.t, v 1.0 2006/02/01 Alex Peeters Exp $
#

use strict;
use Test;
use ASNMTAP::Asnmtap::Plugins::NPTest;

use vars qw($tests);
BEGIN {$tests = 4; plan tests => $tests}

my $t;
my $prefix = '../plugins/templates';
my $plugin = 'check_template-WebTransact.pl';

if ( -x "$prefix/$plugin" ) {
  $t += checkCmd( "$prefix/$plugin -V", 3, "/$plugin/");
  $t += checkCmd( "$prefix/$plugin -h", 3);

  my $ASNMTAP_PROXY = ( exists $ENV{ASNMTAP_PROXY} ) ? $ENV{ASNMTAP_PROXY} : undef;

  unless ( defined $ASNMTAP_PROXY and ( $ASNMTAP_PROXY eq '0.0.0.0' or $ASNMTAP_PROXY eq '' ) ) {
    my $proxy = ($ASNMTAP_PROXY ? "--proxy='$ASNMTAP_PROXY'" : '');

    $t += checkCmd( "$prefix/$plugin $proxy", [0, 1, 2, 3]);
  } else {
    $t += skipMissingCmd( "ASNMTAP_PROXY", ($tests - 3) );
  }
} else {
  $t += skipMissingCmd( "$prefix/$plugin", $tests );
}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);
