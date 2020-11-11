package HideModule;
use strict;
use warnings;

my %hide;

sub import {
  shift;
  @hide{@_} = ();
  my $hook = \&_hook;
  for my $i (reverse 0 .. $#INC) {
    if (ref $INC[$i] eq ref $hook && $INC[$i] == $hook) {
      splice @INC, $i, 1;
    }
  }
  unshift @INC, $hook;
}

sub _hook {
  my (undef, $file) = @_;
  if (exists $hide{$file}) {
    die sprintf 'Can\'t locate %s in @INC (Hidden Module) at %s line %s.', $file, (caller)[1,2];
  }
  return;
}

1;
