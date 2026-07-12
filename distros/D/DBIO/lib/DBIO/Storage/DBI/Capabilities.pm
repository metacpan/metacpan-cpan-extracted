package DBIO::Storage::DBI::Capabilities;
# ABSTRACT: Two-tier capability probing for DBI storage drivers

use strict;
use warnings;

use base 'DBIO::Storage';
use mro 'c3';
use namespace::clean;

our $CONTRACT_VERSION = '1.1';


sub contract_version { $CONTRACT_VERSION }

my @capabilities = (qw/
  insert_returning
  insert_returning_bound

  multicolumn_in

  placeholders
  typeless_placeholders

  join_optimizer

  transactional_ddl
  supports_if_exists
/);
__PACKAGE__->mk_group_accessors( dbms_capability => map { "_supports_$_" } @capabilities );
__PACKAGE__->mk_group_accessors( use_dbms_capability => map { "_use_$_" } (@capabilities ) );

# on by default, not strictly a capability (pending rewrite)
__PACKAGE__->_use_join_optimizer (1);
sub _determine_supports_join_optimizer { 1 };

# transactional_ddl and supports_if_exists are engine-specific facts. The
# default _determine_supports_* returns 0 (conservative: do not assume the
# engine is transactional / has the IF [NOT] EXISTS syntax until the driver
# says so). Drivers override via _use_X or _determine_supports_X.
sub _determine_supports_transactional_ddl { 0 }
sub _determine_supports_supports_if_exists { 0 }

sub set_use_dbms_capability {
  $_[0]->set_inherited ($_[1], $_[2]);
}

sub get_use_dbms_capability {
  my ($self, $capname) = @_;

  my $use = $self->get_inherited ($capname);
  return defined $use
    ? $use
    : do { $capname =~ s/^_use_/_supports_/; $self->get_dbms_capability ($capname) }
  ;
}

sub set_dbms_capability {
  $_[0]->_dbh_details->{capability}{$_[1]} = $_[2];
}

sub get_dbms_capability {
  my ($self, $capname) = @_;

  my $cap = $self->_dbh_details->{capability}{$capname};

  unless (defined $cap) {
    if (my $meth = $self->can ("_determine$capname")) {
      $cap = $self->$meth ? 1 : 0;
    }
    else {
      $cap = 0;
    }

    $self->set_dbms_capability ($capname, $cap);
  }

  return $cap;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::Capabilities - Two-tier capability probing for DBI storage drivers

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Capability detection for L<DBIO::Storage::DBI>. Uses a two-tier accessor
system:

A driver or user may define C<_use_X>, which blindly without any checks says
"(do not) use this capability" (C<use_dbms_capability> is an C<inherited>-type
accessor).

If C<_use_X> is undef, C<_supports_X> is queried. This is a simple-style
accessor which calls C<_determine_supports_X> and stores the return in a
slot on the storage object that is wiped on every C<$dbh> reconnection
(reconnection is not guaranteed to land on the same RDBMS version).
C<_determine_supports_X> does not need to exist on a driver — the runtime
C<< ->can >>-checks for it before calling.

The default capability list is below; drivers add their own with
C<< __PACKAGE__->mk_group_accessors(dbms_capability => '_supports_X') >>.

=head1 CONTRACT VERSION

This class exposes an independent compatibility version, distinct from
C<$VERSION> (the dist version injected by L<Dist::Zilla>'s
C<VersionFromMainModule>):

    my $v = $class->contract_version;

C<$CONTRACT_VERSION> bumps when the capability-probing interface (the
C<_supports_*> / C<_use_*> accessors, the default capability list, or the
contract surface that drivers extend with new entries) changes. The dist
C<$VERSION> bumps on every release, but two core releases at the same contract
version remain wire-compatible. Out-of-tree drivers should record the contract
version they were last tested against and compare it against core's at load
time, warning (or strict-failing under C<DBIO_STRICT_CONTRACT>) when the shapes
have drifted. See F<docs/adr/> for the contract-version policy.

=head1 CAPABILITY LIST

The default capability set is the following. Drivers add their own with
C<< __PACKAGE__->mk_group_accessors(dbms_capability => '_supports_X') >>.

=over 4

=item C<insert_returning> / C<insert_returning_bound>

INSERT ... RETURNING support.

=item C<multicolumn_in>

Multi-column IN list optimisation.

=item C<placeholders> / C<typeless_placeholders>

Driver placeholder style.

=item C<join_optimizer>

Join-order hinting. On by default; not strictly a capability.

=item C<transactional_ddl> -- F02 / F10

True iff the engine runs DDL inside a normal transaction (i.e.
C<txn_do { do_ddl() }> is atomic). False if the engine forces an implicit
COMMIT on DDL (MySQL, Oracle, DB2, Sybase, Informix) or depends on
C<AutoCommit=on> for in-place rebuilds (SQLite). L<DBIO::Deploy::Base> uses
this to decide whether to wrap a multi-statement DDL loop in
C<< $storage->txn_do >>; L<DBIO::DeploymentHandler> uses it to decide
whether the whole upgrade can run atomically. Drivers register their
engine value via C<< __PACKAGE__->_use_transactional_ddl(0|1) >> (in the
driver's storage class) or by defining C<_determine_supports_transactional_ddl>.

=item C<supports_if_exists> -- F12

True iff the engine / diff emitter can use C<IF [NOT] EXISTS> in DDL
(C<CREATE TABLE IF NOT EXISTS>, C<DROP TABLE IF EXISTS>,
C<ALTER TABLE ... ADD COLUMN IF NOT EXISTS>). False on engines that do
not parse the syntax (older MySQL / MariaDB before 10.0.2, some SQLite
builds, others). L<DBIO::Diff::Op::should_emit_if_exists> probes this
to decide whether to emit guarded DDL. Drivers register their engine
value via C<< __PACKAGE__->_use_supports_if_exists(0|1) >> or by defining
C<_determine_supports_supports_if_exists>.

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
