package DBIO::Replicated::Balancer;
# ABSTRACT: Base class for replicated read balancing

use strict;
use warnings;

use base 'DBIO::Base';
use Scalar::Util 'blessed';
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  auto_validate_every
  current_replicant
  _on_master
/);

sub new {
  my ($class, %args) = @_;
  my $self = bless {
    auto_validate_every => $args{auto_validate_every},
    current_replicant   => $args{current_replicant},
    _on_master          => 0,
    master              => $args{master},
    pool                => $args{pool},
  }, $class;

  $self->current_replicant($self->next_storage) if $self->pool;

  return $self;
}

sub master {
  my $self = shift;
  $self->{master} = $_[0] if @_;
  return $self->{master};
}

sub pool {
  my $self = shift;
  $self->{pool} = $_[0] if @_;
  return $self->{pool};
}

sub next_storage {
  die ref($_[0]) . ' must implement next_storage()';
}

sub next_storage_with_fallback {
  my ($self, @args) = @_;
  my $now = time;

  if (
    defined $self->auto_validate_every
      && ($self->auto_validate_every + $self->pool->last_validated) <= $now
  ) {
    $self->pool->validate_replicants;
  }

  if (my $next = $self->next_storage(@args)) {
    $self->master->debugobj->print("Moved back to slave\n") if $self->_on_master;
    $self->_on_master(0);
    return $next;
  }

  $self->master->debugobj->print("No Replicants validate, falling back to master reads.\n")
    unless $self->_on_master;

  $self->_on_master(1);
  return $self->master;
}

sub increment_storage {
  my $self = shift;
  $self->current_replicant($self->next_storage_with_fallback);
}

sub select {
  my $self = shift;
  my @args = @_;

  if (ref($args[-1]) eq 'HASH' && (my $forced_pool = $args[-1]->{force_pool})) {
    delete $args[-1]->{force_pool};
    return $self->_get_forced_pool($forced_pool)->select(@args);
  }
  elsif ($self->master->transaction_depth) {
    return $self->master->select(@args);
  }

  $self->increment_storage;
  return $self->current_replicant->select(@args);
}

sub select_single {
  my $self = shift;
  my @args = @_;

  if (ref($args[-1]) eq 'HASH' && (my $forced_pool = $args[-1]->{force_pool})) {
    delete $args[-1]->{force_pool};
    return $self->_get_forced_pool($forced_pool)->select_single(@args);
  }
  elsif ($self->master->transaction_depth) {
    return $self->master->select_single(@args);
  }

  $self->increment_storage;
  return $self->current_replicant->select_single(@args);
}

sub columns_info_for {
  my $self = shift;
  $self->increment_storage;
  return $self->current_replicant->columns_info_for(@_);
}

sub _get_forced_pool {
  my ($self, $forced_pool) = @_;

  if (blessed $forced_pool) {
    return $forced_pool;
  }
  elsif ($forced_pool eq 'master') {
    return $self->master;
  }
  elsif (my $replicant = $self->pool->replicants->{$forced_pool}) {
    return $replicant;
  }

  $self->master->throw_exception("'$forced_pool' is not a named replicant.");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated::Balancer - Base class for replicated read balancing

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
