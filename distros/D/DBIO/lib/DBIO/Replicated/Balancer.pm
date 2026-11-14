package DBIO::Replicated::Balancer;
# ABSTRACT: Base class for replicated read balancing

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::Base';
use Scalar::Util 'blessed';
use DBIO::Util ();
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


# A select with a lock attribute (for => 'update', 'shared', any defined value)
# takes its lock where the write goes: the master.
sub _has_lock_attribute {
  my ($args) = @_;
  return ref($args->[-1]) eq 'HASH' && defined $args->[-1]{for};
}

sub select {
  my $self = shift;
  my @args = @_;

  if (ref($args[-1]) eq 'HASH' && (my $forced_pool = $args[-1]->{force_pool})) {
    delete $args[-1]->{force_pool};
    return $self->_get_forced_pool($forced_pool)->select(@args);
  }
  elsif ($self->master->transaction_depth || _has_lock_attribute(\@args)) {
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
  elsif ($self->master->transaction_depth || _has_lock_attribute(\@args)) {
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

sub _select {
  my $self = shift;
  my @args = @_;

  if (ref($args[-1]) eq 'HASH' && (my $forced_pool = $args[-1]->{force_pool})) {
    delete $args[-1]->{force_pool};
    return $self->_get_forced_pool($forced_pool)->_select(@args);
  }
  elsif ($self->master->transaction_depth || _has_lock_attribute(\@args)) {
    return $self->master->_select(@args);
  }

  $self->increment_storage;
  return $self->current_replicant->_select(@args);
}

# The pre-rendered statement path (DBIO::Storage::DBI/_execute_rendered), which
# ResultSet::results_exist runs its EXISTS statement on. A read, so it routes
# like _select: master inside a transaction, a replicant otherwise. The
# statement carries no attrs hashref, so there is no force_pool key to honour.
sub _execute_rendered {
  my $self = shift;

  return $self->master->_execute_rendered(@_)
    if $self->master->transaction_depth;

  $self->increment_storage;
  return $self->current_replicant->_execute_rendered(@_);
}

# ADR 0040 section 6: the same statement path stopped one verb
# short (DBIO::Storage::DBI/_prepare_rendered), for an engine whose answer is
# an attribute of the PREPARED statement. It routes like the method it is half
# of. Not optional bookkeeping, for the reason spelled out under
# _explain_query below: a Balancer is not a storage and has no AUTOLOAD.
sub _prepare_rendered {
  my $self = shift;

  return $self->master->_prepare_rendered(@_)
    if $self->master->transaction_depth;

  $self->increment_storage;
  return $self->current_replicant->_prepare_rendered(@_);
}

# ADR 0040: DBIO::ResultSet::explain's whole operation, which the
# driver storage owns (DBIO::Storage::DBI/_explain_query). A read -- it plans a
# read query, and every statement it issues goes down _execute_rendered anyway
# -- so it routes like _select: master inside a transaction, a replicant
# otherwise. This forwarder is not optional bookkeeping: a Balancer is not a
# storage and has no AUTOLOAD, so a method listed in
# DBIO::Replicated::Storage's @reader_methods and missing here dies on the
# read handler.
sub _explain_query {
  my $self = shift;

  return $self->master->_explain_query(@_)
    if $self->master->transaction_depth;

  $self->increment_storage;
  return $self->current_replicant->_explain_query(@_);
}

sub _dbh_columns_info_for {
  my ($self, $dbh, $table) = @_;

  # Like select/select_single, route to master when inside a transaction so
  # we read the data the current transaction can actually see.
  # _dbh_columns_info_for is provided by base Storage::DBI with a fixed
  # ($self, $dbh, $table) signature, so it cannot honour force_pool like
  # select/select_single do; callers who need force_pool routing must drop
  # down to columns_info_for instead.
  if ($self->master->transaction_depth) {
    return $self->master->_dbh_columns_info_for($dbh, $table);
  }

  $self->increment_storage;
  return $self->current_replicant->_dbh_columns_info_for($dbh, $table);
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

  # a replicant is named after its DSN: never a password in it (karr k297)
  $self->master->throw_exception(
    "'" . DBIO::Util::mask_connect_secrets($forced_pool) . "' is not a named replicant."
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated::Balancer - Base class for replicated read balancing

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

Base class for the read balancers of L<DBIO::Replicated::Storage>. A
balancer answers every read: it picks a replicant from the
L<DBIO::Replicated::Pool> (via the subclass's L</next_storage>), falls back
to the master when no replicant is usable, and sends reads to the master
while a transaction is open there. C<auto_validate_every> (seconds) and
C<current_replicant> are plain read/write accessors.

=head1 METHODS

=head2 new

  my $balancer = $class->new(
    master              => $master_backend,
    pool                => $pool,
    auto_validate_every => 60,     # optional
  );

When a pool is given, picks the first C<current_replicant> right away.

=head2 master

Getter/setter for the master backend.

=head2 pool

Getter/setter for the L<DBIO::Replicated::Pool>.

=head2 next_storage

Returns the next replicant to read from, or nothing if none is usable. The
base class dies; every balancer subclass implements this.

=head2 next_storage_with_fallback

Re-validates the pool first if C<auto_validate_every> seconds have passed
since its last validation. Returns L</next_storage> if that yields a
replicant, else the master; each switch between replicant and master reads
is noted once on the master's trace object.

=head2 increment_storage

Sets C<current_replicant> to the result of L</next_storage_with_fallback>.

=head2 select

=head2 select_single

Route a read: with a C<force_pool> key in the trailing attributes hashref
(removed before the call) to that target -- a backend object, C<'master'>,
or the name of a replicant -- its DSN after C<dbi:Driver:> without the
C<password=> part (throws for an unknown name); inside a master
transaction, or when the attributes carry a lock (C<for> with any defined
value, C<'update'> and C<'shared'> among them), to the master; otherwise to
the next replicant (see
L</increment_storage>).

=head2 columns_info_for

Moves to the next replicant and asks it; unlike L</select> it neither honours
C<force_pool> nor routes to the master during a transaction.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
