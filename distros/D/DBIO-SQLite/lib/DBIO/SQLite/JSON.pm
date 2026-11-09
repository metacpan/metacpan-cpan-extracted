package DBIO::SQLite::JSON;
# ABSTRACT: JSON path expression helpers for DBIO::SQLite queries

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::SQLite::JSON::Op ();

use Exporter 'import';
our @EXPORT_OK = qw(json);

sub json {
  my ($col) = @_;
  return DBIO::SQLite::JSON::Op->new( col => $col );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::JSON - JSON path expression helpers for DBIO::SQLite queries

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::SQLite::JSON qw(json);

  # Equality on an extracted text value
  $rs->search( json('me.data')->get_text('$.status')->eq('active') );
  # WHERE (me.data ->> ?) = ?          bind: '$.status', 'active'

  # The portable json_extract() function form
  $rs->search( json('me.data')->extract('$.status')->eq('active') );
  # WHERE (json_extract(me.data, ?)) = ?

  # The -> operator, yielding a JSON value
  $rs->search( json('me.data')->get('$.meta')->is_not_null );
  # WHERE (me.data -> ?) IS NOT NULL

  # Numeric comparisons, NULL checks, LIKE
  $rs->search( json('me.stats')->get_text('$.score')->gt(100) );
  $rs->search( json('me.data')->get_text('$.avatar')->is_null );
  $rs->search( json('me.data')->get_text('$.name')->like('John%') );

  # ORDER BY / SELECT
  $rs->search( {}, { order_by => json('me.data')->get_text('$.total')->as_order } );
  $rs->search( {}, { select   => [ json('me.data')->extract('$.status')->as_select('status') ] } );

=head1 DESCRIPTION

Provides the C<json()> helper that builds JSON path-extraction expressions for
SQLite columns. It exposes the three SQLite extraction forms:

=over 4

=item * C<json_extract(col, path)> — the portable function (JSON1 extension,
SQLite 3.9+), via L<DBIO::SQLite::JSON::Op/extract>.

=item * C<<< col -> path >>> — the C<< -> >> operator (SQLite 3.38+), yielding a
B<JSON> value, via L<DBIO::SQLite::JSON::Op/get>.

=item * C<<< col ->> path >>> — the C<<< ->> >>> operator (SQLite 3.38+),
yielding a B<text / SQL> value, via L<DBIO::SQLite::JSON::Op/get_text>.

=back

In every form the path is bound as a placeholder, so it is never a SQL-injection
surface. The comparison methods on the returned operator object
(L<DBIO::SQLite::JSON::Op>) turn an extraction into a condition fragment suitable
for C<search()>.

=head1 METHODS

=head2 json

  use DBIO::SQLite::JSON qw(json);

  my $expr = json($column);

Returns a L<DBIO::SQLite::JSON::Op> object bound to C<$column>. Chain a selector
method on it to choose the extraction form and the JSON path, then a comparison
or consumption method to produce a fragment for C<search()>:

  json('me.data')->extract('$.status')    # json_extract(me.data, ?)
  json('me.data')->get('$.status')        # me.data -> ?    (JSON value)
  json('me.data')->get_text('$.status')   # me.data ->> ?   (text/SQL value)

C<$column> may include a table alias prefix (e.g. C<'me.data'>) and is emitted
verbatim — pass an identifier, not user input. The JSON B<path> always travels
as a placeholder bind, never interpolated into the SQL.

=head1 SEE ALSO

=over 4

=item * L<DBIO::SQLite::JSON::Op> — operator object returned by C<json()>, with the selector and comparison methods

=item * L<DBIO::SQLite::SQLMaker> — SQLite SQL generation

=item * L<DBIO::SQLite::Storage> — SQLite storage layer

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
