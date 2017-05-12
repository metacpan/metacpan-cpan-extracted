# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
package t::dbh;
use strict;
use warnings;
use Carp;

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};
  $ref->{'stack'} = [];
  bless $ref, $class;

  for my $m (keys %{$ref->{'mock'}}) {
    my $v = $ref->{'mock'}->{$m};
    $m =~ s/\s+/ /smxg;
    $ref->{'mock'}->{$m} = $v;
  }

  return $ref;
}

sub prepare {
  my ($self, $stmt) = @_;
  $self->{'ptr'} = 0;
  push @{$self->{'stack'}}, $stmt;
  return $self;
}

sub prepare_cached {
  my $self = shift;
  return $self->prepare(@_);
}

sub execute {
  my $self = shift;
  push @{$self->{'stack'}}, \@_;
  return;
}

sub rollback {
}

sub commit {
}

sub finish {
  my $self = shift;
  pop @{$self->{'stack'}};
  pop @{$self->{'stack'}};
  $self->{'ptr'} = 0;
  return;
}

sub disconnect {
}

sub do {
}

sub fetchrow_hashref {
  my $self = shift;
  my $args = $self->{'stack'}->[-1];
  my $stmt = $self->{'stack'}->[-2];
  my $data = $self->mockfetch($stmt, @{$args});
  if($self->{'ptr'}+1 > scalar @{$data}) {
    return;
  }

  my $v = $data->[$self->{'ptr'}];
  $self->{'ptr'}++;
  return $v;
}

sub selectall_arrayref {
  my $self = shift;
  return $self->mockfetch(@_);
}

sub mockfetch {
  my ($self, $query, @params) = @_;
  $query    =~ s/\s+/ /smxg;
  my $merge = $query . ':' . join q(,), @params;
  $merge    =~ s/(ARRAY|HASH|GLOB)\(0x[\da-z]+\)//smxg;

  if(!$self->{'mock'}->{$merge}) {
    croak "No mock data for $merge";
  }
  return $self->{'mock'}->{$merge};
}

1;
