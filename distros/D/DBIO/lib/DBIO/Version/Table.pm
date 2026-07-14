package DBIO::Version::Table;
# ABSTRACT: Result class for the schema versions table
use base 'DBIO::Core';
use strict;
use warnings;

__PACKAGE__->table('dbio_schema_versions');

__PACKAGE__->add_columns(
  version => {
    data_type   => 'VARCHAR',
    is_nullable => 0,
    size        => 10,
  },
  installed => {
    data_type   => 'VARCHAR',
    is_nullable => 0,
    size        => 20,
  },
);

__PACKAGE__->set_primary_key('version');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Version::Table - Result class for the schema versions table

=head1 VERSION

version 0.900002

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
