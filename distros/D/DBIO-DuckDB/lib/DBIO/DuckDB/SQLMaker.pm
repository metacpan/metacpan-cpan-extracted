package DBIO::DuckDB::SQLMaker;
# ABSTRACT: DuckDB-specific SQL generation for DBIO

use strict;
use warnings;

use base qw( DBIO::SQLMaker );


# DuckDB does not support SELECT ... FOR UPDATE in its SQL dialect.
# When using the Quack extension, writes are serialized server-side, but
# FOR UPDATE remains unsupported in DuckDB's query language regardless.
sub _lock_select () { '' }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::SQLMaker - DuckDB-specific SQL generation for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

DuckDB-specific subclass of L<DBIO::SQLMaker>. DuckDB's SQL dialect is
PostgreSQL-flavored: double-quoted identifiers, standard C<LIMIT ? OFFSET ?>,
C<RETURNING>, C<::> casts, C<ILIKE>, rich types. This class just turns off
the bits DuckDB doesn't do:

=over 4

=item * C<SELECT ... FOR UPDATE> is not supported by DuckDB -- disabled.

=back

All other SQL generation is inherited unchanged from L<DBIO::SQLMaker>,
which already defaults to C<LIMIT ? OFFSET ?> pagination.

This class is set as the C<sql_maker_class> by L<DBIO::DuckDB::Storage> and
is not normally instantiated directly.

=seealso

=over

=item * L<DBIO::SQLMaker> - Base SQL generation class

=item * L<DBIO::DuckDB::Storage> - Storage driver that uses this SQL maker

=item * L<DBIO::DuckDB> - Top-level DuckDB schema component

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
