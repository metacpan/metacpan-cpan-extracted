package DBIO::MySQL::Async::QueryExecutor;
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
  $mdb->query($sql, sub {
    my ($rows, $err) = @_;
    if ($err) {
      $f->fail($err);
    } else {
      $f->done(ref $rows eq 'ARRAY' ? @$rows : $rows);
    }
  });

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

DBIO::MySQL::Async::QueryExecutor - Query execution wrapper for DBIO MySQL async storage

=head1 VERSION

version 0.900000

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
