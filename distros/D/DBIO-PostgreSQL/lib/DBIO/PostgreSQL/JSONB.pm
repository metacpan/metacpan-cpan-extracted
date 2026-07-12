package DBIO::PostgreSQL::JSONB;
# ABSTRACT: JSONB path expression helpers for DBIO::PostgreSQL queries

use strict;
use warnings;

use DBIO::PostgreSQL::JSONB::Op ();

use Exporter 'import';
our @EXPORT_OK = qw(jsonb);

sub jsonb {
  my ( $col, @path ) = @_;
  return DBIO::PostgreSQL::JSONB::Op->new( col => $col, path => \@path );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::JSONB - JSONB path expression helpers for DBIO::PostgreSQL queries

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  use DBIO::PostgreSQL::JSONB qw(jsonb);

  # Equality — single key
  $rs->search( jsonb('me.data', 'status')->eq('active') );
  # WHERE (me.data->>'status') = ?

  # Equality — nested path
  $rs->search( jsonb('me.config', 'theme', 'color')->eq('dark') );
  # WHERE (me.config#>>'{theme,color}') = ?

  # Inequality
  $rs->search( jsonb('me.data', 'role')->ne('guest') );
  # WHERE (me.data->>'role') != ?

  # Numeric comparisons (value extracted as text — cast in SQL if needed)
  $rs->search( jsonb('me.stats', 'score')->gt(100) );
  $rs->search( jsonb('me.stats', 'score')->ge(100) );
  $rs->search( jsonb('me.stats', 'score')->lt(50)  );
  $rs->search( jsonb('me.stats', 'score')->le(50)  );

  # Pattern matching
  $rs->search( jsonb('me.data', 'name')->like('John%')   );
  $rs->search( jsonb('me.data', 'name')->ilike('%smith%') );

  # NULL checks
  $rs->search( jsonb('me.data', 'avatar')->is_null     );
  $rs->search( jsonb('me.data', 'email')->is_not_null  );

  # ORDER BY
  $rs->search( {}, { order_by => jsonb('me.score', 'total')->as_order } );
  $rs->search( {}, { order_by => { -desc => jsonb('me.score', 'total')->as_order } } );

  # Combined with containment operators from DBIO::PostgreSQL::SQLMaker:
  $rs->search([
    jsonb('me.data', 'status')->eq('published'),
    { 'me.data' => { '@>' => { featured => \1 } } },
  ]);

=head1 DESCRIPTION

Provides the C<jsonb()> helper function that builds text-extraction path
expressions for PostgreSQL JSONB columns. The generated SQL uses C<<< ->> >>>
(single-level) or C<<< #>> >>> (multi-level) to extract a text value, which
can then be compared with standard SQL operators.

This module covers the path-extraction side of JSONB querying. The comparison
methods themselves live on L<DBIO::PostgreSQL::JSONB::Op>, the operator object
returned by C<jsonb()>.

For containment and key-existence operators (C<<< @> >>>, C<?>, etc.) see
L<DBIO::PostgreSQL::SQLMaker>, which handles those transparently in
C<search()> without any extra import.

=head1 METHODS

=head2 jsonb

  use DBIO::PostgreSQL::JSONB qw(jsonb);

  my $expr = jsonb($column, @path);

Returns a L<DBIO::PostgreSQL::JSONB::Op> object representing a text-extraction
path into a JSONB column. Call a comparison method on the returned object to
produce a condition fragment suitable for passing to C<search()>.

C<$column> may include a table alias prefix (e.g. C<'me.data'>).

  # Single-level: uses ->>
  jsonb('me.data', 'status')        # (me.data->>'status')

  # Multi-level: uses #>>
  jsonb('me.config', 'theme', 'color')  # (me.config#>>'{theme,color}')

Path elements containing single quotes are escaped with standard SQL
C<''> doubling.

=head1 SEE ALSO

=over 4

=item * L<DBIO::PostgreSQL::JSONB::Op> — operator object returned by C<jsonb()>, with all the comparison methods

=item * L<DBIO::PostgreSQL::SQLMaker> — JSONB operator support (C<<< @> >>>, C<?>, etc.)

=item * L<DBIO::PostgreSQL::Storage> — PostgreSQL storage layer

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
