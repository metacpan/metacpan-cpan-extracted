package DBIO::SQLite::Util;
# ABSTRACT: Shared SQLite-specific helper functions for DBIO

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(column_is_nullable);



sub column_is_nullable {
  my ($not_null, $is_pk) = @_;
  return ($not_null || $is_pk) ? 0 : 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Util - Shared SQLite-specific helper functions for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Small helpers that capture SQLite-specific truths shared across the driver,
so the same rule is not re-encoded in several places.

=func column_is_nullable

    my $is_nullable = column_is_nullable($not_null, $is_pk);

The single source of truth for SQLite column nullability. A column is
logically NOT NULL when it is either declared C<NOT NULL> B<or> part of the
primary key -- C<PRAGMA table_info> reports PK columns as C<notnull=0> (the
PK constraint is separate from the NOT NULL attribute), but a PK column is
logically non-nullable. Returns C<1> when the column may hold NULL, C<0>
otherwise.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
