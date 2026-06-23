package DBIO::SQLite::SQLMaker;
# ABSTRACT: SQLite-specific SQL generation for DBIO

use warnings;
use strict;

use base qw( DBIO::SQLMaker );


#
# SQLite does not understand SELECT ... FOR UPDATE
# Disable it here
sub _lock_select () { '' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::SQLMaker - SQLite-specific SQL generation for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

SQLite-specific subclass of L<DBIO::SQLMaker>. Disables C<SELECT ... FOR UPDATE>
locking syntax, which SQLite does not support. All other SQL generation is
inherited from L<DBIO::SQLMaker>.

This class is set as the C<sql_maker_class> by L<DBIO::SQLite::Storage> and
is not normally instantiated directly.

=seealso

=over

=item * L<DBIO::SQLMaker> - Base SQL generation class

=item * L<DBIO::SQLite::Storage> - Storage driver that uses this SQL maker

=item * L<DBIO::SQLite> - Top-level SQLite schema component

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
