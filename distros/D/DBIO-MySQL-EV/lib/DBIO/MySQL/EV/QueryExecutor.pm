package DBIO::MySQL::EV::QueryExecutor;
# ABSTRACT: Query execution wrapper for DBIO MySQL async storage

use strict;
use warnings;

use Future;
use Carp 'croak';


sub new {
  my ($class, %args) = @_;
  croak 'pool is required' unless $args{pool};

  my $debug = $args{debug} // $ENV{DBIO_TRACE} // 0;

  bless {
    pool  => $args{pool},
    debug => $debug,
  }, $class;
}


sub execute {
  my ($self, $mdb, $sql, $bind) = @_;
  $bind //= [];

  $self->_debug_query($sql, $bind) if $self->{debug};

  my $f = Future->new;

  # EV::MariaDB::query($sql, $cb) does NOT accept bind values — passes a
  # bind arrayref to it is silently dropped. When the SQL has placeholders
  # we MUST route through prepare + execute; otherwise the bind values
  # never reach the server and the query fails with a SQL syntax error on
  # the '?' placeholders (or, worse, runs with whatever the previous
  # prepared statement's binds were — silent corruption). Empty binds
  # stay on the cheap query() path.
  my $on_result = sub {
    my ($rows, $err) = @_;
    if ($err) {
      $f->fail($err);
    } else {
      $f->done(ref $rows eq 'ARRAY' ? @$rows : $rows);
    }
  };

  if (@$bind) {
    $mdb->prepare($sql, sub {
      my ($stmt, $perr) = @_;
      if ($perr) {
        $f->fail($perr);
        return;
      }
      $mdb->execute($stmt, $bind, $on_result);
    });
  }
  else {
    $mdb->query($sql, $on_result);
  }

  # Mirror the sync storage's bind-clearing contract: the sync path wipes
  # bind values from its pool once $dbh->execute(@bind) returns. The async
  # bind arrayref outlives `execute` (it is referenced by the issuing CRUD
  # frame and, on a real connection, by the in-flight query handle), so
  # clear it when the future settles — never on the issuing side, which
  # would corrupt the bind values of a still-pending query. This both frees
  # the payload (no per-pool retention proportional to total binds issued)
  # and prevents a re-issued query on the same handle from reading stale
  # binds while a previous future is pending.
  $f->on_ready(sub { @$bind = () });

  return $f;
}

sub _debug_query {
  my ($self, $sql, $bind) = @_;
  my $bind_str = join(', ', map { defined $_ ? "'$_'" : 'NULL' } @$bind);
  warn "$sql: $bind_str\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV::QueryExecutor - Query execution wrapper for DBIO MySQL async storage

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Wraps a connection pool and provides a single C<execute($conn, $sql, $bind)>
interface for query execution. Handles bind attribute policy and returns
a L<Future> with the result rows.

Separated from Storage to allow independent testing of query execution
logic from connection pooling and transaction orchestration.

=head1 METHODS

=head2 execute

  my $future = $executor->execute($mdb, $sql, $bind);

Execute a query on a given L<EV::MariaDB> connection. Returns a L<Future>
that resolves with the result rows (array or arrayref).

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
