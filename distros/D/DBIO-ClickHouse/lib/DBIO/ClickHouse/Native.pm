package DBIO::ClickHouse::Native;
# ABSTRACT: Turn DBIO schemas and rows into ClickHouse::Encoder input

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Base';

use Scalar::Util ();
use DBIO::Exception ();
use DBIO::ClickHouse::DDL ();


sub columns_for {
  my ($class, $thing, %opts) = @_;

  my @unknown = grep { $_ ne 'columns' } sort keys %opts;
  $class->throw_exception(
    'columns_for(): unknown option' . (@unknown > 1 ? 's ' : ' ')
    . join(', ', map { "'$_'" } @unknown)
  ) if @unknown;

  my $source = $class->_resolve_source($thing);

  my @names;
  if (defined $opts{columns}) {
    $class->throw_exception(
      "columns_for(): 'columns' must be an arrayref of column names")
      unless ref $opts{columns} eq 'ARRAY';
    $class->throw_exception(
      "columns_for(): 'columns' must not be empty")
      unless @{ $opts{columns} };
    @names = @{ $opts{columns} };
  }
  else {
    @names = $source->columns;
    $class->throw_exception(
      'columns_for(): ' . _source_label($source) . ' has no columns')
      unless @names;
  }

  my @columns;
  for my $name (@names) {
    $class->throw_exception(
      'columns_for(): ' . _source_label($source) . " has no column '$name'")
      unless defined $name && length $name && $source->has_column($name);

    push @columns,
      [$name, DBIO::ClickHouse::DDL->column_type($source->column_info($name))];
  }

  return \@columns;
}


sub rows_from {
  my ($class, $rows, $columns) = @_;

  my $next = $class->row_iterator($rows, $columns);

  my @out;
  while (defined(my $row = $next->())) {
    push @out, $row;
  }

  return \@out;
}


sub row_iterator {
  my ($class, $rows, $columns) = @_;

  $class->_assert_columns($columns);

  if (Scalar::Util::blessed($rows) && $rows->isa('DBIO::ResultSet')) {
    return sub {
      my $row = $rows->next;
      return undef unless defined $row;
      return $class->_row_values($row, $columns);
    };
  }

  if (ref $rows eq 'ARRAY') {
    my $i = 0;
    return sub {
      return undef if $i > $#{$rows};
      return $class->_row_values($rows->[$i++], $columns);
    };
  }

  $class->throw_exception(
    'row_iterator() needs a DBIO::ResultSet or an arrayref of rows, got '
    . _describe($rows));
}

# --- column list ------------------------------------------------------------

sub _assert_columns {
  my ($class, $columns) = @_;

  $class->throw_exception(
    'The column list must be a non-empty arrayref of [ name, type ] pairs, '
    . 'as returned by columns_for(), got ' . _describe($columns))
    unless ref $columns eq 'ARRAY' && @$columns;

  for my $pair (@$columns) {
    $class->throw_exception(
      'The column list must hold [ name, type ] pairs, got ' . _describe($pair))
      unless ref $pair eq 'ARRAY' && @$pair == 2
        && defined $pair->[0] && length $pair->[0]
        && defined $pair->[1] && length $pair->[1];
  }

  return;
}

# --- row conversion ---------------------------------------------------------

sub _row_values {
  my ($class, $row, $columns) = @_;

  my @values;
  for my $pair (@$columns) {
    my ($name, $type) = @$pair;
    # Scalar context on both calls: an undef value must stay one element of
    # the row, not collapse out of the list.
    my $raw = $class->_raw_value($row, $name);
    my $value = $class->_checked_value($name, $type, $raw);
    push @values, $value;
  }

  return \@values;
}

# The deflated value of one column. For a result object that means
# get_column(), which is DBIO's deflation path -- a value that was set through
# an InflateColumn accessor is deflated here and nowhere else. A plain hashref
# (DBIO::ResultClass::HashRefInflator, or data the caller assembled) is taken
# as-is; there is no result object to deflate through.
sub _raw_value {
  my ($class, $row, $name) = @_;

  if (Scalar::Util::blessed($row)) {
    $class->throw_exception(
      'Each row must be a DBIO result object or a hashref; a ' . ref($row)
      . ' object has no get_column()')
      unless $row->can('get_column');

    # get_column() on a column that was never selected returns undef, which
    # would export as a NULL the row never had. Refuse instead.
    $class->throw_exception(
      "Column '$name' was not fetched into this " . ref($row) . ' -- exporting '
      . 'it would write a value the row does not have. Select the column, or '
      . 'leave it out of the column list')
      if $row->can('has_column_loaded') && !$row->has_column_loaded($name);

    return $row->get_column($name);
  }

  if (ref $row eq 'HASH') {
    $class->throw_exception("Row hashref has no key '$name'")
      unless exists $row->{$name};
    return $row->{$name};
  }

  $class->throw_exception(
    'Each row must be a DBIO result object or a hashref, got '
    . _describe($row));
}

sub _checked_value {
  my ($class, $name, $type, $value) = @_;

  if (!defined $value) {
    return undef if _accepts_undef($type);

    $class->throw_exception(
      "Column '$name' is undef but its ClickHouse type is '$type', which "
      . 'cannot hold a NULL -- the encoder would silently write the type\'s '
      . 'zero value instead. Declare the column is_nullable so the type '
      . 'becomes Nullable(...), or keep the row out of the export');
  }

  if (my $ref = ref $value) {
    $class->throw_exception(
      "Column '$name' holds a $ref object, which reached here undeflated. "
      . 'ClickHouse::Encoder does not dispatch through ->epoch; it takes the '
      . "value's string or numeric conversion, and for '$type' that is "
      . 'silently wrong (a DateTime outside UTC loses its offset, a numeric '
      . "column gets the leading digits of the stringification). Give the "
      . 'column its inflator/deflator (e.g. '
      . "load_components('InflateColumn::DateTime')) so that get_column() "
      . 'hands back the stored value')
      if Scalar::Util::blessed($value);

    $class->throw_exception(
      "Column '$name' holds a $ref reference, which no ClickHouse type accepts")
      unless $ref eq 'ARRAY' || $ref eq 'HASH';

    $class->throw_exception(
      "Column '$name' holds a $ref reference, but its ClickHouse type '$type' "
      . 'takes a plain scalar')
      unless _accepts_reference($type);

    return $value;
  }

  $class->throw_exception(
    "Column '$name' has the composite type '$type', which ClickHouse::Encoder "
    . 'takes as a Perl reference, but the value is the plain scalar '
    . _abbreviate($value) . '. Composite columns do not survive the MySQL wire '
    . 'protocol -- ClickHouse hands them back as their text rendering, not as '
    . 'a Perl structure -- so they can only be exported from rows you built '
    . 'yourself. See DBIO::ClickHouse::Native, "Composite types are a one-way '
    . 'street"')
    if _requires_reference($type);

  return $value;
}

# --- type predicates --------------------------------------------------------
#
# These read the rendered ClickHouse type string, which is the only thing the
# encoder is configured with. They deliberately do NOT re-derive anything from
# column_info: DBIO::ClickHouse::DDL::column_type is the one type authority,
# and a caller may legitimately pass a column list that came from
# ClickHouse::Encoder->for_table instead.

# Types whose encoder input is a Perl reference -- an arrayref or a hashref --
# rather than a scalar. Object('json') is the pre-24.8 spelling of JSON; the
# geo names are ClickHouse's own aliases over Tuple/Array.
my $COMPOSITE_TYPE = qr/\A(?:
    Array | Map | Tuple | Nested | Variant | JSON | Object
  | Point | Ring | LineString | MultiLineString | Polygon | MultiPolygon
)\b/x;

# Dynamic takes a scalar leaf OR an array of them, so it is in neither the
# "must be a reference" nor the "must be a scalar" camp.
my $ANY_SHAPE_TYPE = qr/\ADynamic\b/;

# Nullable is the type wrapper; LowCardinality nests outside it.
sub _unwrap {
  my ($type) = @_;
  $type =~ s/\A\s+//;
  $type =~ s/\ALowCardinality\(\s*//;
  $type =~ s/\ANullable\(\s*//;
  return $type;
}

sub _accepts_undef {
  my ($type) = @_;
  return 1 if $type =~ /\A\s*(?:LowCardinality\(\s*)?Nullable\(/;
  # A Variant arm and a Dynamic value both carry their own null discriminator.
  return 1 if _unwrap($type) =~ /\A(?:Variant\b|Dynamic\b)/;
  return 0;
}

sub _requires_reference {
  my ($type) = @_;
  return _unwrap($type) =~ $COMPOSITE_TYPE ? 1 : 0;
}

sub _accepts_reference {
  my ($type) = @_;
  my $inner = _unwrap($type);
  return ($inner =~ $COMPOSITE_TYPE || $inner =~ $ANY_SHAPE_TYPE) ? 1 : 0;
}

# --- diagnostics ------------------------------------------------------------

sub _source_label {
  my ($source) = @_;
  my $name = $source->source_name;
  return "source '$name'" if defined $name && length $name;
  $name = $source->result_class;
  return "result class '$name'" if defined $name && length $name;
  return 'the result source';
}

sub _describe {
  my ($thing) = @_;
  return 'undef' unless defined $thing;
  return ref($thing) . ' object' if Scalar::Util::blessed($thing);
  return 'a ' . ref($thing) . ' reference' if ref $thing;
  return 'the plain scalar ' . _abbreviate($thing);
}

sub _abbreviate {
  my ($value) = @_;
  $value = substr($value, 0, 40) . '...' if length $value > 43;
  $value =~ s/\s+/ /g;
  return "'$value'";
}

# --- source resolution ------------------------------------------------------

sub _resolve_source {
  my ($class, $thing) = @_;

  $class->throw_exception(
    'columns_for() needs a ResultSource, a ResultSet, a result object or a '
    . 'result class name, got ' . _describe($thing))
    if !defined $thing || (!ref($thing) && !length $thing);

  if (Scalar::Util::blessed($thing)) {
    return $thing if $thing->isa('DBIO::ResultSource');
    return $thing->result_source
      if $thing->isa('DBIO::ResultSet') || $thing->isa('DBIO::Row');

    $class->throw_exception(
      'columns_for(): cannot get a ResultSource out of a ' . ref($thing)
      . ' object');
  }

  $class->throw_exception(
    'columns_for() needs a ResultSource, a ResultSet, a result object or a '
    . 'result class name, got ' . _describe($thing))
    if ref $thing;

  # A result class name. Load it, so that a name coming from configuration
  # works, then insist on the accessor rather than guessing at the class.
  if (!$thing->can('result_source_instance')) {
    eval { $class->ensure_class_loaded($thing); 1 }
      or $class->throw_exception("columns_for(): cannot load '$thing': $@");
  }

  $class->throw_exception(
    "columns_for(): '$thing' is not a DBIO result class -- it has no "
    . 'result_source_instance')
    unless $thing->can('result_source_instance');

  my $source = $thing->result_source_instance;
  $class->throw_exception(
    "columns_for(): result class '$thing' has no result source. Was table() "
    . 'called on it?')
    unless $source;

  return $source;
}

# DBIO::Base deliberately has no throw_exception -- a component must not
# install one, which would shadow the result class's. This class is never
# mixed into anything, so it carries its own, the same way
# DBIO::SQLMaker::ClassicExtensions does.
sub throw_exception { DBIO::Exception->throw($_[1]) }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Native - Turn DBIO schemas and rows into ClickHouse::Encoder input

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    use DBIO::ClickHouse::Native;
    use ClickHouse::Encoder;   # yours to load, never ours -- see below

    # 1. The column list, straight out of the DBIO source
    my $cols = DBIO::ClickHouse::Native->columns_for($schema->source('Hit'));
    # [ ['id','UUID'], ['url','String'], ['hits','UInt32'],
    #   ['snapshot','Nullable(Int32)'], ['ts','Nullable(DateTime64(3))'] ]

    # 2. The rows, in that column order, deflated
    my $rows = DBIO::ClickHouse::Native->rows_from(
      $schema->resultset('Hit')->search({ hits => { '>' => 100 } }), $cols
    );

    # 3. Hand both to ClickHouse::Encoder. Note the port: 8123 is the HTTP
    #    interface, a different channel from the driver's MySQL wire on 9004.
    my $resp = ClickHouse::Encoder->insert_http(
      host    => '127.0.0.1',
      port    => 8123,
      table   => 'dbio_test_hit',
      columns => $cols,
      rows    => $rows
    );
    die "insert failed (status $resp->{status}): $resp->{content}"
      unless $resp->{success};

A large export should not be materialized. L</row_iterator> returns exactly
the coderef C<< ClickHouse::Encoder->stream >> pulls from:

    my $enc  = ClickHouse::Encoder->new(columns => $cols);
    my $iter = DBIO::ClickHouse::Native->row_iterator($rs, $cols);

    open my $fh, '|-', 'clickhouse-client',
      '--query', 'insert into dbio_test_hit format native' or die $!;
    $enc->stream($iter, sub { print {$fh} $_[0] }, batch_size => 10_000);
    close $fh or die 'clickhouse-client failed';

=head1 DESCRIPTION

C<DBIO::ClickHouse::Native> translates between two data representations: the
DBIO side (a L<DBIO::ResultSource> and its rows) and the input
L<ClickHouse::Encoder> takes (an arrayref of C<[$name, $type]> pairs, plus
rows as arrayrefs in that column order). It produces plain Perl data
structures and nothing else.

B<It is not a transport, and it never loads ClickHouse::Encoder.> There is no
C<use>, no C<require>, and no runtime probe for it anywhere in this module
(F<t/50-native.t> asserts that via C<%INC>; only the optional
F<t/51-native-encoder.t> loads the encoder); you load the encoder yourself and drive C<encode> / C<insert_http>
/ C<bulk_inserter> from your own code. That is what keeps the dependency a
C<suggests> rather than a C<requires> -- see
F<docs/adr/0007-native-format-export-bridge.md> -- and it is why this layer
does not collide with L<ADR 0001|DBIO::ClickHouse::Storage>: the MySQL wire
protocol on port 9004 remains this driver's only transport, and the Native
format goes out over a channel DBIO has no part in.

B<It is one-way: DBIO to encoder.> There is deliberately no counterpart that
turns C<< ClickHouse::Encoder->decode_rows >> output back into a
C<< $rs->populate >>. Reading already comes back over the MySQL wire, so the
Native format would buy no throughput on that side, and supporting it would
duplicate the value-conversion rules below for a much narrower case.

=head2 The column list is B<our> truth, not the table's

L</columns_for> answers "what type would this distribution B<deploy> for this
column" -- it is L<DBIO::ClickHouse::DDL/column_type>, the same renderer
behind C<CREATE TABLE> and the diff. If the target table was created by this
distribution's deploy, the two agree by construction.

If it was not -- created by hand, by another tool, or by an older version of
your schema -- it can differ, and B<the Native format is typed>: a
C<UInt32> column list against an C<Int64> table column is a wrong-width block,
which is a server error at best. When the live table is the authority, ask it
instead:

    my $enc = ClickHouse::Encoder->for_table('dbio_test_hit', host => 'db');

C<for_table> runs C<describe table> and builds the encoder from the answer.
You can still use L</rows_from> with C<< $enc->columns >> as the column list.

=head2 Composite types are a one-way street

C<Array(T)>, C<Map(K, V)>, C<Tuple(...)>, C<JSON>, C<Variant(...)> and the geo
aliases need a Perl B<reference> per value. This distribution happily
I<renders> those types at deploy time, but reading such a column back over the
MySQL wire protocol yields a B<string> -- ClickHouse's text rendering of the
value, C<['perl','db']> -- not an arrayref. There is no round trip.

So a composite column can only be exported from rows you built yourself. This
module does not paper over that with heuristic string splitting; when
L</rows_from> meets a composite column holding a plain scalar it throws,
naming the column and the reason. The encoder would refuse the value too
(C<Expected arrayref for Array type>) -- what is added here is the diagnosis,
because the interesting question is not that the value is a string but why.
See L</LIMITATIONS>.

=head2 Values are deflated, not inflated

Rows go through L<DBIO::Row/get_column>, which B<is> DBIO's deflation path: a
value set through an C<InflateColumn> accessor is deflated there and handed
back in its stored form. A C<DateTime> object from
L<DBIO::InflateColumn::DateTime> therefore arrives as the C<YYYY-MM-DD
HH:MM:SS> string the storage's datetime parser produced -- which is what a
C<DateTime>, C<DateTime64(P)>, C<Date> or C<Date32> column in
L<ClickHouse::Encoder> parses. Rows read from the database are already in that
form, because that is what the MySQL wire hands over.

What this module does B<not> do is convert values itself. If a blessed object
reaches it, deflation did not happen, and it throws rather than passing it on.
That is not a formality. C<ClickHouse::Encoder> does not dispatch through
C<< ->epoch >>; it takes the value's string or numeric conversion, so an
object encodes to something -- usually to something wrong, and quietly.
Measured against C<ClickHouse::Encoder> 0.02 with a
C<< DateTime->new(..., time_zone => 'Europe/Berlin') >>:

=over 4

=item * into C<DateTime>: the object stringifies to ISO 8601 B<without> a zone
marker, so it is read as UTC and the encoded epoch is off by the zone's
offset. No error, wrong timestamp.

=item * into C<Int64> or C<Float64>: 2026 -- the leading digits of
C<2026-08-11T12:00:00>. No error.

=item * into C<Decimal(10, 2)>: 202600. No error.

=back

The fix is on the DBIO side: register the inflator/deflator for the column.

Passing the stored value through untouched is not merely tidy, it is load
bearing. A C<Decimal*> column arrives from the DBD as a B<string>, and
C<ClickHouse::Encoder> parses a decimal string digit by digit and scales it
exactly, where a decimal B<number> goes through a C<double> and is lossy past
2^53. Numifying a value on its way here -- in this module or in your own code
-- silently drops digits.

=head1 METHODS

=head2 columns_for

    my $cols = DBIO::ClickHouse::Native->columns_for($source);
    my $cols = DBIO::ClickHouse::Native->columns_for($source,
                 columns => [qw( id ts kind )]);

Returns an arrayref of C<[$name, $type]> pairs for
C<< ClickHouse::Encoder->new(columns => $cols) >>. C<$type> comes from
L<DBIO::ClickHouse::DDL/column_type>.

The first argument may be a L<DBIO::ResultSource>, a L<DBIO::ResultSet>, a
result object, or a result class name (loaded on demand). Anything else
throws rather than being guessed at.

Without C<columns> every column of the source is emitted, in the source's own
order. With C<columns> only the named ones are, B<in the order given> -- the
list you pass is the block layout, so it is also the order L</rows_from>
produces. An unknown column name throws.

=head2 rows_from

    my $rows = DBIO::ClickHouse::Native->rows_from($rs, $cols);
    my $rows = DBIO::ClickHouse::Native->rows_from(\@results, $cols);

Returns an arrayref of arrayrefs -- one per row, values in C<$cols> order --
ready for C<< $enc->encode($rows) >>, C<< insert_http(rows => $rows) >> or
C<< $bi->push_many($rows) >>.

C<$cols> is required and is normally what L</columns_for> returned; passing it
explicitly is what makes the encoder and the rows provably agree on the block
layout. The first argument is a L<DBIO::ResultSet> (consumed with C<next>,
exactly like a C<while> loop would) or an arrayref of rows; a row is either a
DBIO result object or a plain hashref, so a resultset switched to
C<DBIO::ResultClass::HashRefInflator> works and is the faster path for a large
export.

This slurps the whole result into memory. For a big export use
L</row_iterator> instead.

Throws on anything it cannot export truthfully: a column the row never
fetched, a C<NULL> in a column whose type is not C<Nullable>, a blessed value
(see L</Values are deflated, not inflated>), or a composite column holding a
plain scalar (see L</Composite types are a one-way street>).

=head2 row_iterator

    my $iter = DBIO::ClickHouse::Native->row_iterator($rs, $cols);
    while (defined(my $row = $iter->())) { ... }

Same conversion as L</rows_from>, one row at a time: returns a coderef that
yields the next row arrayref and C<undef> when the source is exhausted. That
is precisely the iterator contract C<< $enc->stream(\&iter, \&writer) >>
expects, so an export of any size can go straight into the encoder's streaming
path without ever holding more than one batch.

=head1 LIMITATIONS

=over 4

=item * B<No decode side.> DBIO to encoder only; see L</DESCRIPTION>.

=item * B<Composite columns cannot be read back out of ClickHouse.>
C<Array>, C<Map>, C<Tuple>, C<JSON>, C<Variant> and the geo types come back
over the MySQL wire as their text rendering. Export them from data you built
in Perl; L</rows_from> throws rather than guessing at a string.

=item * B<The column list is this distribution's deploy truth.> Use
C<< ClickHouse::Encoder->for_table >> when the live table is the authority.

=item * B<Nothing here validates against the server.> The types are rendered
from schema metadata; whether the target table matches is found out at insert
time, by the encoder or by ClickHouse.

=back

=head1 SEE ALSO

=over 4

=item * L<ClickHouse::Encoder> - the consumer; an optional dependency this
module never loads

=item * L<DBIO::ClickHouse::DDL/column_type> - the type renderer behind
L</columns_for>

=item * L<DBIO::ClickHouse::Storage> - the MySQL-wire transport this bridge
sits beside, not on

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
