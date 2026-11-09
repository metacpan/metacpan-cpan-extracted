package DBIO::ClickHouse::Introspect::Util;
# ABSTRACT: ClickHouse type-string parser shared by the introspect submodules

use strict;
use warnings;

our $VERSION = '0.900004';



# Portable spelling for each ClickHouse base type. Where the DDL type map is
# many-to-one (real/float -> Float32, double/double precision -> Float64,
# datetime/timestamp -> DateTime64(3)) this picks the representative; every
# entry here still renders back to the key it came from.
my %BASE_TYPE = (
  Int8    => 'tinyint',
  Int16   => 'smallint',
  Int32   => 'integer',
  Int64   => 'bigint',
  Float32 => 'real',
  Float64 => 'double precision',
  String  => 'text',
  Date32  => 'date',
  Bool    => 'boolean',
  UUID    => 'uuid',
);

my %UNSIGNED_BASE_TYPE = (
  UInt8  => 'tinyint',
  UInt16 => 'smallint',
  UInt32 => 'integer',
  UInt64 => 'bigint',
);

# Decimal32/64/128/256(S) are fixed-precision aliases; system.columns normally
# reports the canonical Decimal(P, S), but a server that echoes the alias back
# must still land on the same [precision, scale].
my %DECIMAL_ALIAS_PRECISION = (
  32 => 9,
  64 => 18,
  128 => 38,
  256 => 76,
);

sub normalize_type {
  my ($class, $raw) = @_;

  my $type = defined $raw ? $raw : '';
  $type =~ s/\A\s+//;
  $type =~ s/\s+\z//;

  my %info = (native_type => $type, is_nullable => 0, extra => {});
  return { %info, data_type => '' } unless length $type;

  # LowCardinality is the outermost wrapper the DDL layer emits, and the only
  # order ClickHouse accepts: LowCardinality(Nullable(T)).
  if (defined(my $inner = _unwrap('LowCardinality', $type))) {
    $info{extra}{low_cardinality} = 1;
    $type = $inner;
  }

  if (defined(my $inner = _unwrap('Nullable', $type))) {
    $info{is_nullable} = 1;
    $type = $inner;
  }

  my $base = $class->_base_type($type);

  $info{data_type} = $base->{data_type};
  $info{size} = $base->{size} if defined $base->{size};
  $info{extra} = { %{ $info{extra} }, %{ $base->{extra} || {} } };

  return \%info;
}

sub _base_type {
  my ($class, $type) = @_;

  # Array(T): the portable DBIO/DBIC spelling is a trailing "[]".
  if (defined(my $inner = _unwrap('Array', $type))) {
    my $n = $class->normalize_type($inner);

    # The DDL layer refuses to wrap a composite type in Nullable /
    # LowCardinality, so an element type carrying either cannot be rebuilt
    # from "<T>[]" plus flags. Keep the whole type verbatim -- it round-trips
    # through the DDL layer's pass-through for parameterized types.
    return { data_type => $type }
      if $n->{is_nullable} || $n->{extra}{low_cardinality};

    return {
      data_type => $n->{data_type} . '[]',
      (defined $n->{size} ? (size => $n->{size}) : ()),
      extra => $n->{extra},
    };
  }

  # FixedString(N) is opt-in on the DDL side and must stay opt-in here, or a
  # regenerated schema would silently turn every char column into FixedString.
  return { data_type => 'char', size => 0 + $1, extra => { fixed_string => 1 } }
    if $type =~ /\AFixedString\(\s*([0-9]+)\s*\)\z/;

  return { data_type => 'decimal', size => [ 0 + $1, 0 + $2 ] }
    if $type =~ /\ADecimal\(\s*([0-9]+)\s*,\s*([0-9]+)\s*\)\z/;

  return {
    data_type => 'decimal',
    size => [ $DECIMAL_ALIAS_PRECISION{$1}, 0 + $2 ],
  } if $type =~ /\ADecimal(32|64|128|256)\(\s*([0-9]+)\s*\)\z/;

  return $class->_datetime64_type($type, 0 + $1, $2)
    if $type =~ /\ADateTime64\(\s*([0-9]+)\s*(?:,\s*'([^']*)'\s*)?\)\z/;

  return $class->_enum_type($type, $1)
    if $type =~ /\AEnum(?:8|16)\((.*)\)\z/s;

  return { data_type => $BASE_TYPE{$type} }
    if exists $BASE_TYPE{$type};

  return { data_type => $UNSIGNED_BASE_TYPE{$type}, extra => { unsigned => 1 } }
    if exists $UNSIGNED_BASE_TYPE{$type};

  # Everything else (IPv6, Int128, Point, Map(...), Tuple(...), bare Date /
  # DateTime) passes through verbatim, which is what the DDL layer does with a
  # natively-spelled data_type in the other direction.
  return { data_type => $type };
}

# DateTime64 is the only temporal type the DDL layer parameterizes, and only at
# precision 3 (the millisecond resolution every other DBIO driver's `timestamp`
# gives you). Any other precision, or any timezone other than UTC, has no
# portable spelling and is kept verbatim -- with the precision still exposed as
# `size` so callers do not have to re-parse the type string.
sub _datetime64_type {
  my ($class, $type, $precision, $timezone) = @_;

  my %extra = defined $timezone ? (timezone => $timezone) : ();

  return { data_type => 'datetime', size => $precision, extra => \%extra }
    if $precision == 3 && !defined $timezone;

  return { data_type => 'timestamptz', size => $precision, extra => \%extra }
    if $precision == 3 && defined $timezone && $timezone eq 'UTC';

  return { data_type => $type, size => $precision, extra => \%extra };
}

# Enum8('a' = 1, 'b' = 2). The DDL layer numbers members 1..N in declaration
# order, so only that exact numbering can be expressed as the portable
# `enum` + extra->{list}; anything else stays verbatim.
sub _enum_type {
  my ($class, $type, $body) = @_;

  my (@names, @values);
  for my $member ($class->split_top_level($body)) {
    return { data_type => $type }
      unless $member =~ /\A'((?:[^'\\]|\\.)*)'\s*=\s*(-?[0-9]+)\z/;
    push @names,  $class->unquote_string("'$1'");
    push @values, 0 + $2;
  }

  return { data_type => $type } unless @names;

  my $sequential = 1;
  for my $i (0 .. $#values) {
    next if $values[$i] == $i + 1;
    $sequential = 0;
    last;
  }

  return { data_type => 'enum', extra => { list => \@names } } if $sequential;

  return { data_type => $type, extra => { list => \@names } };
}


sub view_select {
  my ($class, $create) = @_;
  return undef unless defined $create && length $create;

  return undef unless $create =~ s/
    \A \s* CREATE \s+ (?: OR \s+ REPLACE \s+ )?
    (?: MATERIALIZED \s+ | LIVE \s+ | WINDOW \s+ )? VIEW \s+
    .*? \s AS \s+
  //xsi;

  $create =~ s/\s+\z//;
  $create =~ s/\s*;\s*\z//;
  return length($create) ? $create : undef;
}


sub split_top_level {
  my ($class, $string) = @_;
  return () unless defined $string && length $string;

  my @entries;
  my $current = '';
  my $depth   = 0;
  my $quoted  = 0;
  my $escaped = 0;

  for my $char (split //, $string) {
    if ($escaped) { $current .= $char; $escaped = 0; next }

    if ($quoted) {
      $current .= $char;
      $escaped = 1 if $char eq "\\";
      $quoted  = 0 if $char eq "'";
      next;
    }

    if ($char eq "'")                  { $quoted = 1 }
    elsif ($char eq '(' || $char eq '[') { $depth++ }
    elsif ($char eq ')' || $char eq ']') { $depth-- }
    elsif ($char eq ',' && $depth == 0) {
      push @entries, $current;
      $current = '';
      next;
    }

    $current .= $char;
  }
  push @entries, $current;

  return grep { length } map { my $e = $_; $e =~ s/\A\s+//; $e =~ s/\s+\z//; $e } @entries;
}


sub unquote_string {
  my ($class, $string) = @_;
  return undef unless defined $string;
  return undef unless $string =~ /\A'((?:[^'\\]|\\.)*)'\z/s;
  my $value = $1;
  $value =~ s/\\(.)/$1/gs;
  return $value;
}

# Strip "Wrapper(...)" and return the inside, or undef when $type is not that
# wrapper applied to the whole string. The paren scan is quote-aware so that
# Enum8('a)b' = 1) does not confuse it.
sub _unwrap {
  my ($wrapper, $type) = @_;
  return undef unless $type =~ /\A\Q$wrapper\E\(/;

  my $open  = length $wrapper;
  my $close = _match_paren($type, $open);
  return undef unless $close == length($type) - 1;

  return substr $type, $open + 1, $close - $open - 1;
}

# Index of the ')' matching the '(' at $open, or -1.
sub _match_paren {
  my ($string, $open) = @_;

  my @chars   = split //, $string;
  my $depth   = 0;
  my $quoted  = 0;
  my $escaped = 0;

  for my $i ($open .. $#chars) {
    my $char = $chars[$i];
    if ($escaped) { $escaped = 0; next }

    if ($quoted) {
      $escaped = 1 if $char eq "\\";
      $quoted  = 0 if $char eq "'";
      next;
    }

    if    ($char eq "'") { $quoted = 1 }
    elsif ($char eq '(') { $depth++ }
    elsif ($char eq ')') { $depth--; return $i unless $depth }
  }

  return -1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Introspect::Util - ClickHouse type-string parser shared by the introspect submodules

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Leaf module holding the pure-data helpers shared by the C<system.*> readers
(L<DBIO::ClickHouse::Introspect::Tables>,
L<DBIO::ClickHouse::Introspect::Columns>,
L<DBIO::ClickHouse::Introspect::Indexes>) and by
L<DBIO::ClickHouse::Introspect> itself. None of these subs talk to the
database or hold state, so they are unit-testable without a server -- which
matters here more than in the other drivers, because ClickHouse has no
embedded mode and every live assertion costs a running server.

The centrepiece is L</normalize_type>, the B<inverse> of the type map in
L<DBIO::ClickHouse::DDL>. Everything in this module exists so that the
introspected model of a table the DDL layer created describes the same column
metadata the DDL layer started from -- otherwise the diff layer sees phantom
changes on every run.

=head2 Round-trip fidelity

C<normalize_type> is written so that feeding its result back through
C<DBIO::ClickHouse::DDL>'s C<_clickhouse_column_type> reproduces the native
type string it was given. Two cases cannot round-trip and are called out here
rather than hidden:

=over 4

=item * B<C<String> is many-to-one.> The DDL layer collapses the whole
varchar / char / text / blob / json family onto C<String>, so introspection
can only pick one representative. It picks C<text> (unsized, which C<String>
is). A schema that declared C<< varchar => 255 >> introspects back as
C<< text >> with no C<size>. This is only a phantom change if a desired-state
model is built B<directly> from C<column_info>; when the desired state is
produced by deploying the generated DDL and introspecting it (the family's
test-deploy-and-compare strategy) both sides normalize identically.

=item * B<Explicitly numbered enums.> C<DBIO::ClickHouse::DDL> numbers enum
members C<1..N> in declaration order. An C<Enum8> whose values are anything
else (starting at 0, sparse, reordered) cannot be expressed as
C<< data_type => 'enum' >>, so the whole type string is kept verbatim -- which
does round-trip, via the DDL layer's pass-through for parameterized types --
and the member names are still exposed in C<< extra->{list} >> for readers
that want them.

=back

Bare C<Date> and bare C<DateTime> used to be a third case: they are returned
verbatim here, and C<DBIO::ClickHouse::DDL> used to lowercase C<data_type>
before its type-map lookup and widen them to C<Date32> / C<DateTime64(3)>. It
now treats an exact native spelling as a passthrough, so they round-trip like
any other native name.

=head1 METHODS

=head2 normalize_type

    my $n = DBIO::ClickHouse::Introspect::Util->normalize_type('LowCardinality(Nullable(String))');
    # { native_type => 'LowCardinality(Nullable(String))',
    #   data_type   => 'text',
    #   is_nullable => 1,
    #   extra       => { low_cardinality => 1 } }

Parses one native ClickHouse type string (as C<system.columns.type> reports
it) into the portable DBIO column metadata that produced it. Always returns a
hashref with C<native_type>, C<data_type>, C<is_nullable> and C<extra>;
C<size> is present only when the type carries one.

The wrappers are peeled in the order L<DBIO::ClickHouse::DDL> nests them:
C<LowCardinality> outside C<Nullable> outside the base type. C<Array(T)> is
handled by the base-type parser, because C<Array> is not a nullability
wrapper -- it is the type.

Recognised shapes:

    Int8 Int16 Int32 Int64        -> tinyint smallint integer bigint
    UInt8 UInt16 UInt32 UInt64    -> same, extra => { unsigned => 1 }
    Float32 / Float64             -> real / double precision
    String                        -> text
    FixedString(N)                -> char, size N, extra => { fixed_string => 1 }
    Decimal(P, S)                 -> decimal, size [P, S]
    Decimal32/64/128/256(S)       -> decimal, size [9|18|38|76, S]
    Date32                        -> date
    DateTime64(3)                 -> datetime,    size 3
    DateTime64(3, 'UTC')          -> timestamptz, size 3, extra => { timezone }
    DateTime64(N[, 'TZ'])         -> verbatim,    size N, extra => { timezone }
    Bool                          -> boolean
    UUID                          -> uuid
    Enum8(...) / Enum16(...)      -> enum, extra => { list => [...] }
    Array(T)                      -> "<T>[]"
    anything else                 -> verbatim

Verbatim is not a failure mode: C<DBIO::ClickHouse::DDL> passes an unmapped
C<data_type> through untouched, so C<IPv6>, C<Int128>, C<Map(String, UInt64)>
and friends survive a full round trip unchanged.

=head2 view_select

    my $select = DBIO::ClickHouse::Introspect::Util->view_select($create_table_query);

The C<SELECT> of a view, cut out of the C<CREATE [MATERIALIZED] VIEW ... AS
SELECT ...> statement C<system.tables.create_table_query> holds (ClickHouse
has no C<view_definition> worth reading). Returns C<undef> for anything that
is not such a statement.

=head2 split_top_level

    my @entries = DBIO::ClickHouse::Introspect::Util->split_top_level("toYYYYMM(ts), id");
    # ('toYYYYMM(ts)', 'id')

Splits a comma-separated ClickHouse expression list on its B<top-level>
commas, ignoring commas nested in parentheses, brackets or single-quoted
string literals. Entries are trimmed and empty ones dropped.

This is what turns C<system.tables>' C<sorting_key> / C<partition_key> /
C<primary_key> strings and an C<Enum8> member list into usable lists -- a
plain C<split /,/> would break C<Decimal(10, 2)> and C<toYYYYMM(ts)> apart.

=head2 unquote_string

    my $value = DBIO::ClickHouse::Introspect::Util->unquote_string(q{'it\\'s'});
    # "it's"

The inverse of L<DBIO::ClickHouse::DDL::Emit/quote_string>: strips the
surrounding single quotes and unescapes backslash-escaped backslashes and
quotes. Returns C<undef> when C<$string> is not a single complete quoted
literal -- C<'a' || 'b'> is an expression, not a string default, and must not
be silently truncated to C<a>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::DDL> - the forward type map this module inverts

=item * L<DBIO::ClickHouse::Introspect> - the model builder that consumes these helpers

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
