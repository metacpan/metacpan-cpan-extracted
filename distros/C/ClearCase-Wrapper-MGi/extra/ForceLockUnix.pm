package ClearCase::ForceLockUnix;

use warnings;
use strict;

our $VERSION = '0.02';
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(funlocklt flocklt);
our $forcelock = '/usr/bin/locklbtype';

sub funlocklt($$) {
  my ($lt, $vob) = @_;
  return system($forcelock, '--unlock', '--vob', $vob, '--lbtype', $lt);
}
sub flocklt($$;$$) {
  my ($lt, $vob, $rep, $nusers) = @_;
  my @fargs = ($forcelock, '--vob', $vob);
  push @fargs, '--replace' if $rep;
  push @fargs, '--nusers', $nusers if $nusers;
  return system(@fargs, '--lbtype', $lt);
}

1;
