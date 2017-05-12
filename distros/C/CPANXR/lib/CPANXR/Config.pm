# $Id: Config.pm,v 1.4 2003/09/28 08:09:30 clajac Exp $

package CPANXR::Config;
use Config::Simple;

use strict;

my $Config = undef;

sub _init {
  $Config = Config::Simple->new("/etc/cpanxr.conf");
}

sub get {
  shift;
  _init() unless(defined $Config);

  return $Config->param($_[0]);
}


1;
