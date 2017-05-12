#!/usr/bin/perl
#
# Copyright 2000 M-J. Dominus and the Mad Hungarian Software Works 
# Unauthorized distribution strictly prohibited
#

package ArrayHashMonster;
$VERSION = '0.02';

sub new {
  my ($pack, $acode, $hcode) = @_;
  my $hash = new ArrayHashMonster::Siphuncle;
  my @a;
  tie @a => $pack, $hash, $acode, $hcode;
  \@a;
}

sub TIEARRAY {
  my ($pack, $hash, $acode, $hcode) = @_;
  my $flag  = undef;
  my $self = {FLAG => \$flag, HASH => $hash, ACODE => $acode, HCODE => $hcode};
  (tied %$hash)->set_flag(\$flag);
  bless $self => $pack;
}

sub FETCH {
  my ($self, $key) = @_;
  print "ARRAY FETCH on $self with key $key; flag is $ {$self->{FLAG}}\n"
    if $::DEBUG;
  return $self->{HASH} if $key == 0;
  if (defined $ {$self->{FLAG}}) {
    my $rv = $self->{HCODE}->($ {$self->{FLAG}});
    undef $ {$self->{FLAG}};
    return $rv;
  } else {
    return $self->{ACODE}->($key);
  }
}

package ArrayHashMonster::Siphuncle;

sub new {
  my ($pack) = @_;
  my %h;
  tie %h => $pack;
  return \%h;
}

sub set_flag {
  my ($self, $flagref) = @_;
  $self->{FLAG} = $flagref;
}

sub TIEHASH {
  my ($pack) = @_;
  my $self = {FLAG => undef};
  bless $self => $pack;
}

sub FETCH {
  my ($self, $key) = @_;
  print "HASH FETCH on $self with key $key\n" if $::DEBUG;
  ${$self->{FLAG}} = $key;
  return 1;
}

1;
