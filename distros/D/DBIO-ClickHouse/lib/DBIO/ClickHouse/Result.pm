package DBIO::ClickHouse::Result;
# ABSTRACT: ClickHouse-specific Result component for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Base';

use DBIO::Exception ();

__PACKAGE__->mk_classdata('_clickhouse_table_options');


my %VALID_OPTION = map { $_ => 1 } qw(
  engine order_by primary_key partition_by settings
);

sub clickhouse_table {
  my ($class, $options) = @_;

  $class->_clickhouse_table_options(_clickhouse_validate_table_options($class, $options))
    if defined $options;

  my $stored = $class->_clickhouse_table_options;
  return $stored ? { %$stored } : undef;
}

sub _clickhouse_validate_table_options {
  my ($class, $options) = @_;

  _clickhouse_throw($class, 'clickhouse_table() expects a hashref of table options')
    unless ref $options eq 'HASH';

  my %clean;
  for my $key (sort keys %$options) {
    _clickhouse_throw($class, "clickhouse_table(): unknown option '$key'")
      unless $VALID_OPTION{$key};

    my $value = $options->{$key};
    next unless defined $value;

    if ($key eq 'engine' || $key eq 'partition_by') {
      _clickhouse_throw($class, "clickhouse_table(): '$key' must be a non-empty string")
        if ref $value || !length $value;
      $clean{$key} = $value;
    }
    elsif ($key eq 'order_by' || $key eq 'primary_key') {
      my @entries = ref $value eq 'ARRAY' ? @$value : ($value);
      for my $entry (@entries) {
        _clickhouse_throw($class,
          "clickhouse_table(): '$key' entries must be column names or scalar refs of raw SQL")
          if ref $entry && ref $entry ne 'SCALAR';
        _clickhouse_throw($class, "clickhouse_table(): '$key' entries must not be empty")
          if !ref $entry && !length $entry;
      }
      $clean{$key} = \@entries;
    }
    else {
      _clickhouse_throw($class, "clickhouse_table(): 'settings' must be a hashref")
        unless ref $value eq 'HASH';
      for my $name (sort keys %$value) {
        _clickhouse_throw($class,
          "clickhouse_table(): setting '$name' must be a scalar or scalar ref")
          if ref $value->{$name} && ref $value->{$name} ne 'SCALAR';
      }
      $clean{$key} = { %$value };
    }
  }

  return \%clean;
}

# Route errors through the result class's own throw_exception when the
# component is mixed into one (the family rule), and fall back to a plain
# DBIO::Exception when it is not -- DBIO::Base has no throw_exception, and a
# component must never install one, which would shadow the result class's.
sub _clickhouse_throw {
  my ($class, $message) = @_;
  return $class->throw_exception($message) if $class->can('throw_exception');
  DBIO::Exception->throw($message);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Result - ClickHouse-specific Result component for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::ClickHouse::Result> is a DBIO Result component that adds the
ClickHouse-native table metadata a C<CREATE TABLE> cannot do without: the
table engine and the MergeTree sorting key, plus the optional partition key,
primary key and engine settings. It is the counterpart to
L<DBIO::MySQL::Result> / L<DBIO::PostgreSQL::Result> and is read by
L<DBIO::ClickHouse::DDL> when generating install DDL.

Load it with:

    package MyApp::DB::Result::Event;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('ClickHouse::Result');

    __PACKAGE__->table('events');
    __PACKAGE__->add_columns(
      id   => { data_type => 'uuid',     is_auto_increment => 1 },
      ts   => { data_type => 'datetime', is_nullable => 0 },
      name => { data_type => 'varchar',  is_nullable => 0,
                extra => { low_cardinality => 1 } },
    );
    __PACKAGE__->set_primary_key('id');

    __PACKAGE__->clickhouse_table({
      engine       => 'ReplacingMergeTree(ts)',
      order_by     => ['ts', 'id'],
      partition_by => 'toYYYYMM(ts)',
      settings     => { index_granularity => 8192 },
    });

=head2 Why a Result component

The alternatives were a C<table_class> override and a bare class accessor on
the result class. A Result component is what the rest of the family already
uses for driver-native table metadata (C<mysql_engine>, C<pg_schema>,
C<sqlite_index>), it is opt-in per result class, and it keeps the DDL layer's
contract to a single duck-typed method call. L<DBIO::ClickHouse::DDL> reads
the options through C<< $result_class->can('clickhouse_table') >>, so a schema
that never loads this component is not broken by its absence -- every table
simply gets the default C<ENGINE = MergeTree> with C<ORDER BY> = primary key.

=head1 METHODS

=head2 clickhouse_table

    __PACKAGE__->clickhouse_table({
      engine       => 'MergeTree',
      order_by     => ['ts', 'id'],
      primary_key  => ['ts'],
      partition_by => 'toYYYYMM(ts)',
      settings     => { index_granularity => 8192 }
    });

    my $opts = $class->clickhouse_table;

Get or set this result class's ClickHouse table options. Returns a shallow
copy of the stored options, or C<undef> when none were declared. Recognised
keys:

=over 4

=item C<engine>

The table engine, emitted verbatim after C<ENGINE = >, so parameterized
engines work (C<'ReplacingMergeTree(version)'>). Defaults to C<MergeTree> in
the generated DDL when unset.

=item C<order_by>

The MergeTree sorting key, as a column name or an arrayref of them. Entries
are quoted as identifiers; pass a SCALAR ref for a raw expression
(C<< \'cityHash64(id)' >>). Defaults to the result class's primary key. An
explicit empty arrayref renders C<ORDER BY tuple()>, ClickHouse's spelling for
"no sorting key".

Note that in ClickHouse the sorting key B<is> the primary key -- there is no
separate index structure, and no uniqueness is implied or enforced.

=item C<primary_key>

Only needed when the primary key should be a strict B<prefix> of C<order_by>
(a coarser index over a finer sort order). Same value shape as C<order_by>.
When omitted, C<ORDER BY> alone defines the primary key, which is also how
ClickHouse renders it back.

=item C<partition_by>

A partition-key B<expression>, emitted verbatim (C<'toYYYYMM(ts)'>). It is not
quoted as an identifier, because a partition key is nearly always a function
call.

=item C<settings>

Engine settings as a hashref. Names are emitted bare and sorted; numeric-looking
values are emitted bare, SCALAR refs verbatim, everything else quoted.

=back

C<TTL> and C<SAMPLE BY> are not modelled yet.

Invalid options are rejected at class-definition time through
C<throw_exception>, so a typo fails when the result class is compiled rather
than when the DDL is deployed.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::DDL> - consumes C<clickhouse_table>

=item * L<DBIO::MySQL::Result> - the MySQL counterpart

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
