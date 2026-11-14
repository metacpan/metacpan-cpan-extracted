package DBIO::Diff::Base;
# ABSTRACT: Base class for DBIO driver diff orchestrators

use strict;
use warnings;

our $VERSION = '0.900005';

our $CONTRACT_VERSION = '1.3';



sub contract_version { $CONTRACT_VERSION }


sub new { my ($class, %args) = @_; bless \%args, $class }


sub diff_options { () }

sub source { $_[0]->{source} }


sub target { $_[0]->{target} }


sub operations { $_[0]->{operations} //= $_[0]->_build_operations }


sub _build_operations {
  my ($self) = @_;
  die ref($self) . '::_build_operations not implemented';
}


sub has_changes {
  my ($self) = @_;
  return scalar @{ $self->operations } > 0;
}


sub as_sql {
  my ($self) = @_;
  return join "\n", map { $_->as_sql } @{ $self->operations };
}


sub summary {
  my ($self) = @_;
  return join "\n", map { $_->summary } @{ $self->operations };
}


sub classify {
  my ($self) = @_;

  my $ops = $self->operations;
  my %counts = (additive => 0, changing => 0, destructive => 0);
  my @refused;

  for my $op (@$ops) {
    my $action = $op->can('action') ? $op->action : undef;
    $action //= '';

    if ($action eq 'refuse') {
      push @refused, $op->summary;
    }
    elsif ($action eq 'create' || $action eq 'add' || $action eq 'add_value') {
      $counts{additive}++;
    }
    elsif ($action eq 'drop') {
      if (_op_is_destructive($op)) { $counts{destructive}++ }
      else                         { $counts{changing}++ }
    }
    else {
      $counts{changing}++;
    }
  }

  my $result = {
    has_changes => (@$ops ? 1 : 0),
    class       => undef,
    counts      => undef,
    refused     => \@refused,
  };
  return $result if @refused;

  my $class = 'none';
  for my $c (qw(additive changing destructive)) {
    $class = $c if $counts{$c};
  }
  @$result{qw(class counts)} = ($class, \%counts);
  return $result;
}

# A drop is destructive unless it is the first half of a drop plus create.
sub _op_is_destructive {
  my ($op) = @_;
  return !($op->can('replaced') && $op->replaced);
}


sub destructive_operations {
  my ($self) = @_;
  return grep {
    my $op = $_;
    my $action = $op->can('action') ? ($op->action // '') : '';
    ($action eq 'drop' && _op_is_destructive($op))
      || ($op->can('lossy') && $op->lossy)
  } @{ $self->operations };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Diff::Base - Base class for DBIO driver diff orchestrators

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

Base class for driver-specific diff orchestrators
(L<DBIO::PostgreSQL::Diff>, L<DBIO::SQLite::Diff>, L<DBIO::MySQL::Diff>).
Provides the full public interface; subclasses implement only
C<_build_operations>.

=head1 ATTRIBUTES

=head2 source

The current (live) database model hashref. Required.

=head2 target

The desired (deployed from DBIO classes) database model hashref. Required.

=head2 operations

ArrayRef of diff operation objects. Built lazily. Each object must respond to
C<as_sql> and C<summary>.

=head1 METHODS

=head2 contract_version

    my $v = $class->contract_version;

Returns C<$CONTRACT_VERSION>, the compatibility version of this base class's
public interface -- independent of the dist C<$VERSION> and unaffected by a
release that changes no contract shape. See L</CONTRACT VERSION> above and
ADR 0024.

=head2 new

    my $diff = $class->new(source => $source_model, target => $target_model);

Blesses the argument hash directly; no validation. C<source> and C<target>
are the two canonical model hashrefs (see L<DBIO::Introspect::Base/CANONICAL
MODEL>) to compare.

=head2 diff_options

    my @names = $class->diff_options;

The names of the options this diff class takes in C<new> beside C<source>,
C<target> and C<extensions>. The default is the empty list. A driver whose diff
class reads an option (C<foreign_keys_not_valid> on PostgreSQL) returns its name
here; L<DBIO::Deploy::Base/diff> hands a caller's options on only when they are
listed and throws on any other key.

=head2 has_changes

    if ($diff->has_changes) { ... }

Returns true if there is at least one diff operation.

=head2 as_sql

    my $sql = $diff->as_sql;

Returns all diff operations concatenated as a SQL migration script.

=head2 summary

    my $text = $diff->summary;

Returns a human-readable summary of all diff operations.

=head2 classify

    my $c = $diff->classify;
    # { has_changes => 1, class => 'changing',
    #   counts  => { additive => 1, changing => 2, destructive => 0 },
    #   refused => [] }

Classifies the diff by what it does to what already exists. Always returns
a hash reference with these keys, which are part of the documented
interface:

=over 4

=item has_changes

1 if there is at least one operation, else 0 (as L</has_changes>).

=item class

One of C<none> (no operations), C<additive>, C<changing> or C<destructive>
-- the highest severity among the operations, in the order
destructive E<gt> changing E<gt> additive. C<undef> when any operation
refuses (see C<refused>): a run that refuses has no classification.

=item counts

Hash reference C<< { additive => N, changing => N, destructive => N } >>,
one count per operation. C<undef> when any operation refuses.

=item refused

Array reference of the C<summary> texts of the operations whose C<action>
is C<refuse>; empty when nothing refuses. This is the only key that is
filled for a refusing run besides C<has_changes> (ADR 0060).

=back

Each operation is read through its C<action> (an operation without an
C<action> method counts as C<undef>):

=over 4

=item C<refuse>

Goes to C<refused>, see above.

=item C<create>, C<add>, C<add_value>

additive.

=item C<drop>

destructive -- unless the operation answers true to C<replaced>, the first
half of a drop plus create of the same object, which is changing.

=item anything else

(C<alter>, C<modify>, C<change>, C<update>, C<replace>, C<move>, C<own>,
C<enable_rls>, C<disable_rls>, C<set_persistence>, no action, an unknown
action) is changing: the conservative reading of an operation not known to
be additive.

=back

Counting is per operation, so a C<replaced> pair counts once as changing
(the drop) and once as additive (the create); the class is the maximum, here
changing. A pair that a driver emits as drop plus create without marking the
drop C<replaced> (the SQLite index and view rebuild) counts as destructive,
conservatively.

=head2 destructive_operations

    my @ops = $diff->destructive_operations;

Returns the operations a run must be released for, in diff order: every
operation L</classify> counts as destructive (a C<drop> that is not the first
half of a drop plus create) and every operation that reports a possibly lossy
change through the optional operation method C<lossy>.

An operation may define C<lossy>. It answers true when the change it writes can
lose or alter stored data although it is not a drop -- a column type change
whose implicit cast can round or truncate is the typical case. An operation
without the method is not lossy. L<DBIO::Deploy::Base/apply> runs a diff with
such an operation only with C<< allow_destructive => 1 >>, as it does for a
destructive one. L</classify> is not affected: a lossy operation keeps the
class of its C<action>.

=head1 CONTRACT VERSION

This class exposes an independent compatibility version, distinct from
C<$VERSION> (the dist version injected by L<Dist::Zilla>'s
C<VersionFromMainModule>):

    my $v = $class->contract_version;

C<$CONTRACT_VERSION> bumps when the diff orchestrator's public interface
(C<source>, C<target>, C<operations>, C<has_changes>, C<as_sql>,
C<summary>, C<classify>, C<destructive_operations>) or the operation-object contract (L<DBIO::Diff::Op>) changes.
The dist C<$VERSION> bumps on every release, but two core releases at the
same contract version remain wire-compatible. Out-of-tree drivers should
record the contract version they were last tested against and compare it
against core's at load time, warning (or strict-failing under
C<DBIO_STRICT_CONTRACT>) when the shapes have drifted. See F<docs/adr/>
for the contract-version policy.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
