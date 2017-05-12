package TestStat::1pid;

use strict;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);
use POSIX qw/getppid/;

sub cmdline {
  open my $f, "/proc/$$/cmdline";
  local $/;
  my $rc=<$f>;
  $rc=~s/\0+$//;
  $rc=~s/\0/ /g;
  return $rc;
}

sub handler {
  my $r=shift;

  $r->print( getppid.":$$:".cmdline );

  return Apache2::Const::OK;
}

1;

__DATA__

SetHandler modperl
PerlResponseHandler TestStat::1pid
