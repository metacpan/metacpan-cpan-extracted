#!perl
use strict;
use warnings;

warn "loading";

sub {
  unshift @{ $_[0]->{install} }, q{bash -c '[[ -n $SPELL ]] && time sudo apt-get install $SPELL; true'};

  for my $inc (@{ $_[0]->{matrix}->{include}} ) {
    if ( $inc->{perl} eq "5.21" ) {
      $inc->{env} .= ' SPELL=aspell';
    }
    if ( $inc->{perl} eq "5.8" ) {
      $inc->{env} .= ' SPELL=ispell';
    }
    if ( $inc->{perl} eq "5.10" ) {
      $inc->{env} .= ' SPELL=hunspell';
    }
    if ( $inc->{perl} eq "5.12" ) {
      $inc->{env} .= ' SPELL=spell';
    }
  }
  $_[0]->{sudo} = 'required';
}
