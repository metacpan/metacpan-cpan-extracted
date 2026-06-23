package DBIO::PostgreSQL::Age::Storage;
# ABSTRACT: PostgreSQL storage with Apache AGE graph support

use strict;
use warnings;

use base 'DBIO::PostgreSQL::Storage';

use JSON::MaybeXS ();

my $JSON = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

__PACKAGE__->register_driver('Pg' => __PACKAGE__);


sub connect_call_load_age {
  my $self = shift;
  $self->_do_query(q{LOAD 'age'});
  $self->_do_query(q{SET search_path = ag_catalog, "$user", public});
}


sub create_graph {
  my ($self, $name) = @_;
  $self->dbh->do('SELECT * FROM ag_catalog.create_graph(?)', undef, $name);
}


sub drop_graph {
  my ($self, $name, $cascade) = @_;
  $self->dbh->do(
    'SELECT * FROM ag_catalog.drop_graph(?, ?)',
    undef, $name, $cascade ? 1 : 0,
  );
}


sub cypher {
  my ($self, $graph, $query, $columns, $params) = @_;

  my ($sql, $bind) = $self->_cypher_sql_bind($graph, $query, $columns, $params);

  return $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    return $dbh->selectall_arrayref($sql, { Slice => {} }, @$bind);
  });
}

# Build the AGE cypher() SQL and its bind values. Pure (no DB) so the SQL
# generation can be unit-tested offline; cypher() wraps this with execution.
sub _cypher_sql_bind {
  my ($self, $graph, $query, $columns, $params) = @_;

  # Apache AGE requires the graph name to be a string literal in the
  # cypher() call -- it cannot be passed as a bind parameter. Validate the
  # name as a plain identifier so we can safely inline it.
  $graph =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
    or $self->throw_exception("Invalid AGE graph name '$graph'");

  my $col_spec = join ', ', map { "$_ agtype" } @$columns;

  my @bind;
  if ($params && %$params) {
    push @bind, $JSON->encode($params);
  }
  my $param_slot = @bind ? ', ?' : '';
  my $sql = "SELECT * FROM cypher('$graph', \$\$\n$query\n\$\$${param_slot}) AS ($col_spec)";

  return ($sql, \@bind);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Age::Storage - PostgreSQL storage with Apache AGE graph support

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  # Loaded automatically via DBIO::PostgreSQL::Age component.
  # Use connect_call_load_age to initialize AGE on each connection:

  MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'load_age' },
  );

  my $storage = $schema->storage;

  $storage->create_graph('social');

  my $rows = $storage->cypher(
    'social',
    $$ MATCH (a:Person {name: $name})-[:KNOWS]->(b) RETURN b.name $$,
    ['friend'],
    { name => 'Alice' },
  );

  $storage->drop_graph('social', 1);  # cascade

=head1 DESCRIPTION

Extends L<DBIO::PostgreSQL::Storage> with Apache AGE graph database support.
Provides connection initialization, graph lifecycle management, and Cypher
query execution.

All result columns from C<cypher()> are declared as C<agtype> — Apache AGE's
JSON-superset type that represents vertices, edges, paths, and scalar values.
Values are returned as strings and can be decoded with a JSON parser.

=head1 METHODS

=head2 connect_call_load_age

  { on_connect_call => 'load_age' }

Connection callback that loads the Apache AGE shared library into the session
and sets C<search_path> to include C<ag_catalog>. Must be called before any
graph operations.

=head2 create_graph

  $storage->create_graph('social');

Creates a new Apache AGE graph with the given name.

=head2 drop_graph

  $storage->drop_graph('social');
  $storage->drop_graph('social', 1);  # cascade

Drops the named graph. Pass a true second argument to cascade the drop to all
vertices and edges within the graph.

=head2 cypher

  my $rows = $storage->cypher(
    'social',
    $$ MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name $$,
    [qw( person friend )],
  );

  # With Cypher parameters:
  my $rows = $storage->cypher(
    'social',
    $$ MATCH (n:Person {name: $name}) RETURN n $$,
    ['node'],
    { name => 'Alice' },
  );

Executes a Cypher query against the named graph. C<$columns> is an arrayref
of result column names; all are declared as C<agtype>. Returns an arrayref
of hashrefs with one key per column.

An optional C<$params> hashref is JSON-encoded and passed as AGE's third
argument to C<cypher()> for parameterized queries.

=seealso

=over 4

=item * L<DBIO::PostgreSQL::Age> - Schema component that activates this storage

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
