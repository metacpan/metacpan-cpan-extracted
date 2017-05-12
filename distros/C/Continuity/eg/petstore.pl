#!/usr/bin/perl

use strict;
use lib '../lib';
use Continuity;

my $server = Continuity->new(
    port => 8080,
);

sub main {
  my $request = shift->next;

  my $store = PetStore->new;
  $store->main;
}

package GuiComponent;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}



package Cart;

sub new {
  my $class = shift;
  my $self = {
    items => [],
  };
  bless $self, $class;
  return $self;
}

sub add_item {
  my ($self, $item) = @_;
  push @{$self->{items}}, $item;
}

sub remove_item {
  my ($self, $item) = @_;
  $self->{items} = [ grep { $_ != $item } @{$self->{items}} ];
}



