package DBIO::PostgreSQL::Age;
# ABSTRACT: Apache AGE graph database support for DBIO::PostgreSQL
our $VERSION = '0.900000';

use strict;
use warnings;


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::PostgreSQL::Age::Storage');
  return $self->next::method(@info);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Age - Apache AGE graph database support for DBIO::PostgreSQL

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL::Age');

  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'load_age' },
  );

  $schema->storage->create_graph('social');

  my $rows = $schema->storage->cypher(
    'social',
    $$ MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name $$,
    [qw( person friend )],
  );

=head1 DESCRIPTION

L<DBIO::PostgreSQL::Age> integrates L<Apache AGE|https://age.apache.org/>
graph database support into L<DBIO::PostgreSQL>. Apache AGE is a PostgreSQL
extension that adds openCypher graph query capabilities via the C<cypher()>
SQL function.

Loading this component sets L<DBIO::Schema/storage_type> to
L<DBIO::PostgreSQL::Age::Storage>, which extends the standard PostgreSQL
storage with graph lifecycle management and Cypher query execution.

=head1 METHODS

=head2 connection

Overrides L<DBIO/connection> to set C<+DBIO::PostgreSQL::Age::Storage>
as C<storage_type>.

=head1 CONNECTION SETUP

Apache AGE requires C<LOAD 'age'> and C<SET search_path = ag_catalog, ...>
on each database connection before any graph operations. Use the C<load_age>
connection callback:

  MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'load_age' },
  );

=seealso

=over 4

=item * L<DBIO::PostgreSQL> - Base PostgreSQL driver component

=item * L<DBIO::PostgreSQL::Age::Storage> - Storage class with graph methods

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
