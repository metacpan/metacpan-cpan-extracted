package DBIO::Oracle::Storage::WhereJoins;
# ABSTRACT: Oracle joins in WHERE syntax support (instead of ANSI).

use strict;
use warnings;

use base qw( DBIO::Oracle::Storage );
use mro 'c3';

__PACKAGE__->sql_maker_class('DBIO::Oracle::SQLMaker::Joins');


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Storage::WhereJoins - Oracle joins in WHERE syntax support (instead of ANSI).

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

L<DBIO::Oracle::Storage> subclass for Oracle databases older than version
9.0 that do not support standard ANSI C<JOIN ... ON> syntax.

Instead of:

    SELECT x FROM y JOIN z ON y.id = z.id

This storage generates:

    SELECT x FROM y, z WHERE y.id = z.id

Left and right outer joins are supported via Oracle's C<(+)> syntax. Full
outer joins are not supported because Oracle requires a C<UNION> of left and
right joins, which cannot be constructed at the WHERE-clause stage.

DBIO autodetects the Oracle version and uses this storage automatically for
pre-9.0 servers. See L<DBIO::Oracle::SQLMaker::Joins> for the SQL generation
details.

=head1 SEE ALSO

=over

=item * L<DBIO::Oracle::Storage> - Parent Oracle storage class

=item * L<DBIO::Oracle::SQLMaker::Joins> - SQL maker implementing WHERE-join syntax

=item * L<DBIO::Oracle> - Oracle schema component

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
