package ClearCase::ForceLockSudo;

use warnings;
use strict;

our $VERSION = '0.03';
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(funlocklt flocklt);
our @forcelock = qw(sudo /opt/rational/clearcase/bin/cleartool);

sub funlocklt($$) {
  my ($lt, $vob) = @_;
  return system(@forcelock, 'unlock', "lbtype:$lt\@$vob");
}
sub flocklt($$;$$) {
  my ($lt, $vob, $rep, $nusers) = @_;
  my @fargs = (@forcelock, 'lock');
  push @fargs, '-replace' if $rep;
  push @fargs, '-nusers', $nusers if $nusers;
  return system(@fargs, "lbtype:$lt\@$vob");
}

1;
