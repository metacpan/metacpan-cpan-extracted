package DBIO::Replicated::DebugProxy;
# ABSTRACT: Prefix trace output with replicated backend identity

use strict;
use warnings;

our $VERSION = '0.900004';

use Scalar::Util 'reftype';
use DBIO::Util ();
use namespace::clean;


sub new {
  my ($class, %args) = @_;
  return bless {
    backend => $args{backend},
    target  => $args{target},
  }, $class;
}

sub backend { $_[0]->{backend} }
sub target  { $_[0]->{target} }


sub callback { shift->target->callback(@_) }
sub debugfh  { shift->target->debugfh(@_) }
sub silence  { shift->target->silence(@_) }
sub print    { shift->target->print(@_) }
sub txn_begin    { shift->target->txn_begin(@_) }
sub txn_commit   { shift->target->txn_commit(@_) }
sub txn_rollback { shift->target->txn_rollback(@_) }
sub svp_begin    { shift->target->svp_begin(@_) }
sub svp_release  { shift->target->svp_release(@_) }
sub svp_rollback { shift->target->svp_rollback(@_) }


sub query_start {
  my ($self, $sql, @bind) = @_;
  return $self->target->query_start($self->_decorate_sql($sql), @bind);
}

sub query_end {
  my ($self, $sql, @bind) = @_;
  return $self->target->query_end($self->_decorate_sql($sql), @bind);
}

sub _decorate_sql {
  my ($self, $sql) = @_;

  my $info = eval { $self->backend->storage->_dbi_connect_info };
  $info = [] unless ref $info eq 'ARRAY';
  my $dsn = eval { $self->backend->dsn };
  $dsn ||= $info->[0];

  # the backend is named by its DSN: never the password in it (karr k297)
  $dsn = DBIO::Util::mask_connect_secrets($dsn, [ $dsn, @{$info}[1 .. $#$info] ]);

  my $kind = uc($self->backend->kind || 'backend');
  my ($op, $rest) = (($sql =~ m/^(\w+)(.+)$/), 'NOP', ' NO SQL');

  return do {
    if ((reftype($dsn) || '') ne 'CODE' && defined $dsn) {
      "$op [DSN_$kind=$dsn]$rest";
    }
    elsif (my $id = eval { $self->backend->id }) {
      "$op [$kind=$id]$rest";
    }
    else {
      "$op [$kind]$rest";
    }
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated::DebugProxy - Prefix trace output with replicated backend identity

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

A trace (C<debugobj>) wrapper installed per backend by
L<DBIO::Replicated::Backend/install_debug_proxy>. It forwards everything to
the real trace object, but rewrites the SQL passed to C<query_start> and
C<query_end> so it names the backend it ran on: C<SELECT [DSN_REPLICANT=...] ...>
when the DSN is known, else C<SELECT [REPLICANT=$id] ...>, else just the
kind. A password in the DSN is shown as C<***>.

=head1 METHODS

=head2 new

  my $proxy = DBIO::Replicated::DebugProxy->new(
    backend => $backend,
    target  => $debugobj,
  );

=head2 backend

The L<DBIO::Replicated::Backend> whose identity is added to the SQL.

=head2 target

The real trace object everything is forwarded to.

=head2 callback

=head2 debugfh

=head2 silence

=head2 print

=head2 txn_begin

=head2 txn_commit

=head2 txn_rollback

=head2 svp_begin

=head2 svp_release

=head2 svp_rollback

Forwarded unchanged to L</target>.

=head2 query_start

=head2 query_end

Forwarded to L</target> with the SQL prefixed by the backend's identity, as
described above.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
