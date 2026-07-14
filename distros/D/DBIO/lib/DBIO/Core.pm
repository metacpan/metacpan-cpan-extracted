package DBIO::Core;
# ABSTRACT: Standard base class for DBIO result classes

use strict;
use warnings;

use base qw/DBIO::Base/;

__PACKAGE__->load_components(qw/
  Timestamp
  Relationship
  InflateColumn
  PK
  Row
  ResultSourceProxy
/);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Core - Standard base class for DBIO result classes

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use base 'DBIO::Core';

  __PACKAGE__->table('artists');
  __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1 },
      name => { data_type => 'varchar', size => 100 },
      bio  => { data_type => 'text', is_nullable => 1 },
      created_at => {
          data_type     => 'timestamp',
          set_on_create => 1,
      },
      updated_at => {
          data_type     => 'timestamp',
          set_on_create => 1,
          set_on_update => 1,
      },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(artist_name => ['name']);
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artist_id');
  1;

PostgreSQL-specific example:

  package MyApp::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('InflateColumn::DateTime');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
      id => {
          data_type          => 'uuid',
          retrieve_on_insert => 1,
      },
      name => { data_type => 'varchar', size => 100 },
      role => {
          data_type   => 'enum',
          extra       => { list => [qw( admin moderator user guest )] },
          is_nullable => 1,
      },
      metadata => {
          data_type        => 'jsonb',
          default_value    => '{}',
          serializer_class => 'JSON',
      },
      embedding => { data_type => 'vector', size => 1536 },
      tags      => { data_type => 'text[]', is_nullable => 1 },
      created_at => {
          data_type     => 'timestamp',
          set_on_create => 1,
      },
      updated_at => {
          data_type     => 'timestamp',
          set_on_create => 1,
          set_on_update => 1,
      },
      deleted_at => {
          data_type   => 'timestamp',
          is_nullable => 1,
      },
  );
  __PACKAGE__->set_primary_key('id');
  1;

See F<t/53-test-schema-fixtures.t> for a runnable example.

=head1 DESCRIPTION

L<DBIO::Core> is the normal base class for vanilla DBIO result classes. It
collects the standard row, relationship, primary-key, and table-definition
behavior that most applications want in every result class.

This is the most verbose but most explicit style. For shorter alternatives,
see L<DBIO::Candy> (import-based sugar with hashrefs) or L<DBIO::Cake>
(DDL-like DSL).

The bundled components currently are:

=over 4

=item L<DBIO::InflateColumn>

=item L<DBIO::Relationship> (See also L<DBIO::Relationship::Base>)

=item L<DBIO::PK>

=item L<DBIO::Row>

=item L<DBIO::ResultSourceProxy> (See also L<DBIO::ResultSource>)

=back

=head1 COMMON COLUMN OPTIONS

These options work in C<add_columns> regardless of which style you use:

=over 4

=item C<data_type> -- the SQL column type (C<'integer'>, C<'varchar'>, C<'jsonb'>, etc.)

=item C<size> -- type size (e.g. C<100> for C<varchar(100)>, C<1536> for C<vector(1536)>)

=item C<is_nullable> -- set to C<1> for nullable columns (default: C<0>)

=item C<is_auto_increment> -- set to C<1> for auto-increment columns

=item C<default_value> -- Perl scalar or C<\$sql_literal> for SQL defaults

=item C<set_on_create> -- set to C<1> to auto-populate on INSERT (e.g. timestamps)

=item C<set_on_update> -- set to C<1> to auto-populate on UPDATE (e.g. C<updated_at>)

=item C<retrieve_on_insert> -- set to C<1> to fetch the DB-generated value after INSERT (e.g. UUIDs)

=item C<serializer_class> -- e.g. C<'JSON'> for automatic JSON inflate/deflate

=item C<is_foreign_key> -- set to C<1> to mark as a foreign key

=back

For a broader tour of what a result class can do, see
L<DBIO::Manual::ResultClass>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
