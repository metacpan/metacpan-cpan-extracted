package DBIO::ClickHouse::DDL;
# ABSTRACT: Generate ClickHouse DDL from DBIO Result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Exception ();
use DBIO::ClickHouse::DDL::Emit qw(
  quote_ident quote_string column_def index_def create_table create_view
  engine_clause partition_by_clause primary_key_clause order_by_clause
  settings_clause split_table_name
);



sub install_ddl {
  my ($class, $schema, $opts) = @_;
  $opts ||= {};

  $class->_refuse_unbuildable($schema);

  my @stmts;
  my %seen_table;

  for my $source_name (sort $schema->sources) {
    my $source       = $schema->source($source_name);
    my $result_class = $source->result_class;

    # Views are emitted after all tables, below.
    next if $source->isa('DBIO::ResultSource::View');

    my $table_name = _resolve_table_name($source->name);

    # Virtual source whose name is inline SQL: nothing to create.
    next unless defined $table_name;

    # A table of another database is made there, and only by the install of
    # the schema itself: the scratch database of a diff leaves it out.
    my ($table_database, $table_short) = split_table_name($table_name);
    next if defined $table_database && $opts->{local_only};

    # Multiple Result classes may share one physical table; emit it once.
    next if $seen_table{$table_name}++;

    my @col_defs;
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      push @col_defs, column_def(
        name    => $col_name,
        type    => _clickhouse_column_type($info),
        default => _column_default($info)
      );
    }

    push @col_defs, _skipping_index_defs($source);

    my $opts = _table_options($result_class);

    # The sorting key defaults to the DBIO primary key. A source with neither
    # an explicit order_by nor a primary key gets ORDER BY tuple().
    my @order_by = defined $opts->{order_by}
      ? @{ $opts->{order_by} }
      : $source->primary_columns;

    my @clauses = (engine_clause($opts->{engine}));
    push @clauses, partition_by_clause($opts->{partition_by})
      if defined $opts->{partition_by};
    push @clauses, primary_key_clause(@{ $opts->{primary_key} })
      if defined $opts->{primary_key};
    push @clauses, order_by_clause(@order_by);
    my $settings = settings_clause($opts->{settings});
    push @clauses, $settings if defined $settings;

    push @stmts, create_table(
      (defined $table_database ? (database => $table_database) : ()),
      name    => $table_short,
      columns => \@col_defs,
      clauses => \@clauses
    );
  }

  # A view of another database is made there too, and only by the install of
  # the schema itself, like such a table.
  my @view_stmts;
  for my $pair ($class->_in_view_order($class->_declared_views($schema))) {
    my ($view_database, $view_short) = split_table_name($pair->[0]);
    next if defined $view_database && $opts->{local_only};
    push @view_stmts, create_view(
      (defined $view_database ? (database => $view_database) : ()),
      name       => $view_short,
      definition => $pair->[1],
    );
  }

  return join "\n\n", @stmts, @view_stmts;
}


sub _refuse_unbuildable {
  my ($class, $schema) = @_;

  my (@problems, %seen);
  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    if ($source->isa('DBIO::ResultSource::View')) {
      my $view = _resolve_table_name($source->name);
      push @problems, sprintf
        "view '%s' is refused: a view name is view or database.view, with "
        . "both halves given and one dot", $view
        if defined $view && !$source->is_virtual && !$seen{"view $view"}++
          && $view =~ /\./ && $view !~ /\A[^.]+\.[^.]+\z/;
      next;
    }
    my $table = _resolve_table_name($source->name);
    next unless defined $table;
    next if $seen{$table}++;

    push @problems, sprintf
      "table '%s' is refused: a table name is table or database.table, with "
      . "both halves given and one dot", $table
      if $table =~ /\./ && $table !~ /\A[^.]+\.[^.]+\z/;

    # A refusal names the table's columns with it: the text is then the one
    # place that shows which of them the refusal sits on, and every problem of
    # the table stands in the same exception.
    my $columns = join ', ', $source->columns;

    for my $col ($source->columns) {
      my $info = $source->column_info($col);

      push @problems, sprintf
        "table '%s' (columns %s): column '%s' is auto-increment, which ClickHouse cannot "
        . "build -- it has no auto-increment and no identity column "
        . "(https://clickhouse.com/docs/sql-reference/statements/create/table); "
        . "supply the key yourself or declare it data_type => 'uuid', "
        . "is_auto_increment => 1, which gets DEFAULT generateUUIDv4()",
        $table, $columns, $col
        if $info->{is_auto_increment} && !_is_uuid_type($info);

      push @problems, sprintf
        "table '%s' (columns %s): column '%s': size '%s' on type 'bit' is refused: "
        . "ClickHouse has no BIT type, so the width would be lost "
        . "(https://clickhouse.com/docs/sql-reference/data-types); "
        . "use UInt8/UInt16/UInt32/UInt64 or Bool, or a native type spelled out",
        $table, $columns, $col, ref $info->{size} ? join(',', @{ $info->{size} }) : $info->{size}
        if lc($info->{data_type} // '') eq 'bit' && defined $info->{size};
    }

    my %unique = $source->can('unique_constraints') ? $source->unique_constraints : ();
    for my $name (sort grep { $_ ne 'primary' } keys %unique) {
      push @problems, sprintf
        "table '%s' (columns %s): unique constraint '%s' on (%s) cannot be enforced -- "
        . "ClickHouse has no unique constraint and does not check a key before "
        . "inserting (https://clickhouse.com/docs/guides/developer/deduplication); "
        . "deduplicate with ReplacingMergeTree through clickhouse_table instead",
        $table, $columns, $name, join ', ', @{ $unique{$name} };
    }

    for my $rel (sort $source->relationships) {
      my $info = $source->relationship_info($rel);
      next unless $info && $info->{attrs} && $info->{attrs}{is_foreign_key_constraint};
      my $cond = $info->{cond};
      my @cols = ref $cond eq 'HASH'
        ? sort map { s/^self\.//r } values %$cond
        : ();
      push @problems, sprintf
        "table '%s' (columns %s): relationship '%s' (column %s) is a foreign key constraint, "
        . "which ClickHouse cannot create -- its CREATE TABLE has no foreign key "
        . "clause (https://clickhouse.com/docs/sql-reference/statements/create/table); "
        . "declare the relationship with is_foreign_key_constraint => 0",
        $table, $columns, $rel, join(', ', @cols) || '?';
    }
  }
  return unless @problems;

  DBIO::Exception->throw(
    "DBIO::ClickHouse::DDL refuses to install, no statement was executed:\n"
    . join("\n", map { "  - $_" } @problems)
  );
}


sub qualified_tables {
  my ($class, $schema) = @_;
  my (@out, %seen);
  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    next if $source->isa('DBIO::ResultSource::View');
    my $name = _resolve_table_name($source->name);
    next unless defined $name && $name =~ /\A[^.]+\.[^.]+\z/;
    my ($database) = split_table_name($name);
    push @out, [ $name, $database ] unless $seen{$name}++;
  }
  for my $pair ($class->_declared_views($schema)) {
    my $name = $pair->[0];
    next unless $name =~ /\A[^.]+\.[^.]+\z/;
    my ($database) = split_table_name($name);
    push @out, [ $name, $database ] unless $seen{$name}++;
  }
  return @out;
}


sub view_order {
  my ($class, $defs) = @_;
  my @names = sort keys %$defs;
  my %after;
  for my $name (@names) {
    my $text = _strip_sql_noise($defs->{$name});
    $after{$name} = [ grep { $_ ne $name && _reads_view($text, $_) } @names ];
  }
  my (@out, %state);
  my $visit; $visit = sub {
    my ($name, @path) = @_;
    return if ($state{$name} // 0) == 2;
    if (($state{$name} // 0) == 1) {
      my ($at) = grep { $path[$_] eq $name } 0 .. $#path;
      my @cycle = @path[$at .. $#path];
      DBIO::Exception->throw(sprintf
        'DBIO::ClickHouse refuses the views: they read each other in a cycle (%s), so no order '
        . 'exists to create them in; no statement was executed',
        join ', ', map { "`$_`" } sort @cycle);
    }
    $state{$name} = 1;
    $visit->($_, @path, $name) for @{ $after{$name} };
    $state{$name} = 2;
    push @out, $name;
  };
  $visit->($_) for @names;
  return @out;
}

# The text without string literals and comments, which hold no read.
sub _strip_sql_noise {
  my ($sql) = @_;
  $sql =~ s{/\*.*?\*/}{ }gs;
  $sql =~ s{--[^\n]*}{ }g;
  $sql =~ s{'(?:[^'\\]|\\.|'')*'}{''}gs;
  return $sql;
}

# Does the text read the view (FROM or JOIN, then the name)?
sub _reads_view {
  my ($text, $name) = @_;
  my $id = sub { my ($i) = @_; return '(?:`' . quotemeta($i) . '`|"' . quotemeta($i) . '"|(?<![\w`"])' . quotemeta($i) . '(?![\w`"]))' };
  my ($database, $short) = split_table_name($name);
  my $ref = defined $database
    ? $id->($database) . '\s*\.\s*' . $id->($short)
    : '(?:' . '(?:`[^`]+`|"[^"]+"|\w+)' . '\s*\.\s*)?' . $id->($short);
  return $text =~ /\b(?:FROM|JOIN)\s+(?:\(\s*)*$ref(?![\w`".(])/i ? 1 : 0;
}

# [name, definition] pairs put in view_order.
sub _in_view_order {
  my ($class, @pairs) = @_;
  my %def = map { @$_ } @pairs;
  return map { [ $_, $def{$_} ] } $class->view_order(\%def);
}


sub declared_views {
  my ($class, $schema, $opts) = @_;
  return { map { @$_ } grep { !($opts && $opts->{local_only}) || $_->[0] !~ /\./ }
    $class->_declared_views($schema) };
}

# [name, definition] pairs in source-name order, one per physical view.
sub _declared_views {
  my ($class, $schema) = @_;
  my (@views, %seen);
  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    next unless $source->isa('DBIO::ResultSource::View');
    next if $source->can('is_virtual') && $source->is_virtual;
    my $vname = _resolve_table_name($source->name);
    next if !defined $vname || $seen{$vname}++;
    my $def = $source->can('view_definition') ? $source->view_definition : undef;
    next unless defined $def && length $def;
    push @views, [ $vname, $def ];
  }
  return @views;
}


sub declared_settings {
  my ($class, $schema) = @_;
  my %settings;
  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    next if $source->isa('DBIO::ResultSource::View');
    my $table_name = _resolve_table_name($source->name);
    next unless defined $table_name;
    my $declared = _table_options($source->result_class)->{settings};
    $settings{$table_name} //= $declared
      if ref $declared eq 'HASH' && keys %$declared;
  }
  return \%settings;
}

# Canonical index declarations as rendered `INDEX ...` body lines. A skipping
# index needs a TYPE the engine will not default, so everything that cannot be
# said exactly is refused rather than degraded.
sub _skipping_index_defs {
  my ($source) = @_;

  my $label = $source->source_name // $source->name;
  $label = 'source' if ref $label;

  my $refuse = sub {
    my ($name, $why) = @_;
    $source->throw_exception("$label: index '$name': $why");
  };

  my @defs;
  for my $decl (sort { $a->{name} cmp $b->{name} }
                $source->index_declarations_for('clickhouse', [qw(type granularity expression)])) {
    my $name = $decl->{name};

    $refuse->($name, 'ClickHouse has no unique index (a data-skipping index '
      . 'enforces nothing)')
      if $decl->{unique};
    $refuse->($name, "index type '$decl->{type}' is not expressible; a "
      . 'ClickHouse index is clickhouse => { type => ..., granularity => ... }')
      if defined $decl->{type} && length $decl->{type} && lc $decl->{type} ne 'unique';
    $refuse->($name, 'the generic options are not expressible in ClickHouse; '
      . 'use clickhouse => { ... }')
      if ref $decl->{options} eq 'HASH'
        ? scalar keys %{ $decl->{options} }
        : (defined $decl->{options} && length $decl->{options});

    my $own = ($decl->{driver} || {})->{clickhouse};
    $refuse->($name, 'has no clickhouse => { type => ... } block; ClickHouse '
      . 'has no plain index and the TYPE cannot be invented')
      unless $own && defined $own->{type};

    my $type = $own->{type};
    $refuse->($name, "invalid type '$type'")
      unless !ref $type && $type =~ /\A\w+(?:\(.+\))?\z/s;

    my $gran = $own->{granularity};
    $refuse->($name, "granularity must be a positive integer, got '$gran'")
      if defined $gran && (ref $gran || $gran !~ /\A[1-9][0-9]*\z/);

    my $expr;
    if (defined $own->{expression}) {
      $expr = $own->{expression};
      $refuse->($name, 'expression must be a non-empty string')
        if ref $expr || !length $expr;
    }
    else {
      my @cols = @{ $decl->{columns} };
      for my $col (@cols) {
        $refuse->($name, "column '$col' is not a column of the source")
          unless $source->has_column($col);
      }
      $expr = @cols == 1
        ? quote_ident($cols[0])
        : '(' . join(', ', map { quote_ident($_) } @cols) . ')';
    }

    push @defs, index_def({
      index_name  => $name,
      expr        => $expr,
      type_full   => $type,
      granularity => $gran,
    });
  }

  return @defs;
}


sub column_type {
  my ($class, $info) = @_;
  return _clickhouse_column_type($info);
}

# Table options declared via DBIO::ClickHouse::Result's clickhouse_table,
# merged over the engine default. Harmless when the Result component was never
# loaded: the accessor simply is not there and every table gets plain
# MergeTree + ORDER BY <primary key>.
sub _table_options {
  my ($result_class) = @_;

  my %opts = (engine => 'MergeTree');
  return \%opts unless $result_class && $result_class->can('clickhouse_table');

  my $declared = $result_class->clickhouse_table;
  return \%opts unless ref $declared eq 'HASH';

  %opts = (%opts, %$declared);

  # The Result component normalizes these to arrayrefs; a result class that
  # rolls its own clickhouse_table might not.
  for my $key (qw(order_by primary_key)) {
    next unless defined $opts{$key};
    $opts{$key} = [$opts{$key}] unless ref $opts{$key} eq 'ARRAY';
  }

  return \%opts;
}

sub _resolve_table_name {
  my ($name) = @_;
  # Plain string: real table name.
  return $name unless ref $name;
  return undef unless ref $name eq 'SCALAR';
  # SCALAR ref: either a pointer to a plain identifier or inline SQL for a
  # virtual view. Word-only content is a real identifier; anything else
  # (whitespace, SELECT, parens) is virtual and is skipped.
  my $v = $$name;
  return undef unless defined $v;
  return $v if $v =~ /\A\w+\z/;
  return undef;
}

# DEFAULT fragment for a column, or undef for none.
sub _column_default {
  my ($info) = @_;

  if ($info->{is_auto_increment}) {
    # ClickHouse has no sequences and no identity columns. The one surrogate
    # identity it does offer natively is a generated UUID; any other
    # auto-increment column is refused by _refuse_unbuildable before this runs.
    return 'generateUUIDv4()' if _is_uuid_type($info);
    return undef;
  }

  return undef unless defined $info->{default_value};

  my $dv = $info->{default_value};
  return quote_string($dv) unless ref $dv eq 'SCALAR';

  # The portable spelling of "now". ClickHouse accepts it in a SELECT but
  # rejects the bare word as a DEFAULT (UNKNOWN_IDENTIFIER), so it is written
  # as the function; any other literal is the author's own SQL and stays.
  return 'now()' if $$dv =~ /\A\s*CURRENT_TIMESTAMP\s*\z/i;
  return $$dv;
}

sub _is_uuid_type {
  my ($info) = @_;
  return (($info->{data_type} // '') =~ /\A(?:uuid|guid|uniqueidentifier)\z/i) ? 1 : 0;
}

# Base type name (no Nullable / LowCardinality wrapping) for one column_info.
my %TYPE_MAP = (
  # signed integers -- widths follow the source dialect's width, not a
  # one-size-fits-all Int64
  tinyint   => 'Int8',
  smallint  => 'Int16',
  mediumint => 'Int32',
  int       => 'Int32',
  integer   => 'Int32',
  bigint    => 'Int64',
  serial    => 'Int32',
  bigserial => 'Int64',

  # floats -- ClickHouse has no unsized FLOAT
  real               => 'Float32',
  float              => 'Float32',
  double             => 'Float64',
  'double precision' => 'Float64',

  # strings: ClickHouse's String is an arbitrary-length byte string, so the
  # whole varchar/text/blob family collapses onto it
  text       => 'String',
  string     => 'String',
  varchar    => 'String',
  varchar2   => 'String',
  nvarchar   => 'String',
  char       => 'String',
  character  => 'String',
  nchar      => 'String',
  clob       => 'String',
  tinytext   => 'String',
  mediumtext => 'String',
  longtext   => 'String',
  ntext      => 'String',
  blob       => 'String',
  bytea      => 'String',
  binary     => 'String',
  varbinary  => 'String',
  tinyblob   => 'String',
  mediumblob => 'String',
  longblob   => 'String',
  json       => 'String',
  jsonb      => 'String',
  # an enum whose members were not declared has nothing to render as Enum8/16
  enum       => 'String',

  # temporal
  date      => 'Date32',
  datetime  => 'DateTime64(3)',
  timestamp => 'DateTime64(3)',
  timestamptz                => "DateTime64(3, 'UTC')",
  'timestamp with time zone' => "DateTime64(3, 'UTC')",
  time      => 'String',

  # misc
  boolean          => 'Bool',
  bool             => 'Bool',
  uuid             => 'UUID',
  guid             => 'UUID',
  uniqueidentifier => 'UUID',
  money            => 'Decimal(19, 4)'
);

# Native ClickHouse type names that the lowercased %TYPE_MAP lookup would
# otherwise swallow. A data_type spelled exactly the way ClickHouse spells the
# type itself is native and is never translated -- the same escape hatch the
# parameterized types (DateTime64(6), Map(String, UInt64)) already get,
# extended to the parameterless ones.
#
# Only names that COLLIDE with a %TYPE_MAP key belong here; every other native
# name (Int128, IPv6, Point) is unmapped and already falls through the lookup
# untouched. String / Bool / UUID render identically either way and are listed
# so the rule holds without exceptions; Date, DateTime, Time and JSON are the
# four where the map and the native name disagree and the native name wins.
#
# Add an entry whenever a new %TYPE_MAP key collides with a native ClickHouse
# type name that it does not itself render to.
my %NATIVE_TYPE = map { $_ => 1 } qw(String Bool UUID Date DateTime Time JSON);

my %UNSIGNED_INT = (
  Int8  => 'UInt8',
  Int16 => 'UInt16',
  Int32 => 'UInt32',
  Int64 => 'UInt64'
);

# A sizeless decimal cannot be rendered: ClickHouse has no bare Decimal, every
# Decimal carries (precision, scale). 38 is the widest precision that still
# fits Decimal128; 9 digits of scale is enough for currency and ratios alike.
my $DEFAULT_DECIMAL = 'Decimal(38, 9)';

sub _clickhouse_column_type {
  my ($info) = @_;

  my $type  = _clickhouse_base_type($info);
  my $extra = $info->{extra} // {};

  # Nullable(T): ClickHouse columns are NOT NULL by default and nullability is
  # part of the type, not a column constraint. Composite types cannot be
  # wrapped -- Nullable(Array(T)) is rejected by the server -- so an array
  # column stays as-is regardless of is_nullable.
  if ($info->{is_nullable}
      && $type !~ /\A(?:Nullable|LowCardinality|Array|Tuple|Map|Nested)\(/) {
    $type = "Nullable($type)";
  }

  # LowCardinality(T) is opt-in: it is a dictionary encoding that pays off for
  # low-distinct-count columns and hurts for high-cardinality ones, so it can
  # never be inferred from the portable metadata. Note the nesting order --
  # LowCardinality(Nullable(String)), not the other way round.
  if ($extra->{low_cardinality} && $type !~ /\ALowCardinality\(/) {
    $type = "LowCardinality($type)";
  }

  return $type;
}

sub _clickhouse_base_type {
  my ($info) = @_;

  my $type  = $info->{data_type} // 'String';
  my $extra = $info->{extra} // {};

  # Array(T): a trailing "[]" is the portable DBIO/DBIC spelling for an array
  # column (text[], integer[]).
  if ($type =~ /\A(.+?)\[\]\z/) {
    return sprintf 'Array(%s)',
      _clickhouse_base_type({ %$info, data_type => $1 });
  }

  # Escape hatch: a data_type that already carries parameters is a native
  # ClickHouse type spelled out by hand -- DateTime64(6), Decimal(20, 4),
  # Enum8('a' = 1) -- and is passed through untouched.
  return $type if $type =~ /\(.+\)\z/;

  # Same escape hatch for the parameterless native names, case-sensitively and
  # before any lowercasing or mapping: 'Date' and 'DateTime' would otherwise
  # hit the portable date => Date32 / datetime => DateTime64(3) entries and the
  # narrow types would be unreachable. The check sits ahead of the enum /
  # decimal / fixed_string branches too, so that "a native spelling is passed
  # through" holds without exceptions -- those branches key off portable
  # spellings that no native name shares.
  return $type if $NATIVE_TYPE{$type};

  my $lc = lc $type;

  # enum: DBIC's portable spelling carries the members in extra->{list}.
  if ($lc eq 'enum' && ref $extra->{list} eq 'ARRAY' && @{ $extra->{list} }) {
    return _enum_type(@{ $extra->{list} });
  }

  # decimal/numeric: size is [precision, scale], or a bare precision.
  if ($lc eq 'decimal' || $lc eq 'numeric') {
    my $size = $info->{size};
    return sprintf 'Decimal(%d, %d)', @{$size}[0, 1]
      if ref $size eq 'ARRAY' && @$size >= 2;
    return sprintf 'Decimal(%d, 0)', $size
      if defined $size && !ref $size && $size =~ /\A[0-9]+\z/;
    return $DEFAULT_DECIMAL;
  }

  # FixedString(N) is opt-in for char/binary columns, never inferred: it pads
  # with zero BYTES (not spaces) and returns the padding to the client, which
  # is not what a CHAR(N) column means anywhere else.
  if ($extra->{fixed_string} && defined $info->{size} && !ref $info->{size}) {
    return sprintf 'FixedString(%d)', $info->{size};
  }

  my $mapped = $TYPE_MAP{$lc};

  # Unknown types pass through verbatim so that native ClickHouse type names
  # (IPv6, Point, AggregateFunction(...)) can be used directly in data_type.
  return $type unless defined $mapped;

  return $UNSIGNED_INT{$mapped} if $extra->{unsigned} && $UNSIGNED_INT{$mapped};

  return $mapped;
}

# Enum8 holds Int8 values, Enum16 Int16 ones. Members are numbered 1..N in
# declaration order: deterministic, and stable when new members are appended
# (renumbering an existing member is a destructive ALTER in ClickHouse).
sub _enum_type {
  my (@members) = @_;
  my $kind = @members <= 127 ? 'Enum8' : 'Enum16';
  return sprintf '%s(%s)', $kind, join ', ',
    map { sprintf '%s = %d', quote_string($members[$_]), $_ + 1 } 0 .. $#members;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::DDL - Generate ClickHouse DDL from DBIO Result classes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::ClickHouse::DDL> generates a ClickHouse DDL script from a
L<DBIO::Schema> class hierarchy. It is the desired-state side of the
test-deploy-and-compare strategy the other DBIO drivers use.

    my $ddl = DBIO::ClickHouse::DDL->install_ddl($schema_class_or_instance);

The output is plain SQL, suitable for executing one statement at a time
against a fresh ClickHouse database. Every table is emitted with an explicit
engine and sorting key -- C<ENGINE = MergeTree> plus C<ORDER BY> defaulting to
the DBIO primary key -- because ClickHouse has no engine default that DBIO
could rely on. Per-table overrides come from L<DBIO::ClickHouse::Result>'s
C<clickhouse_table>.

All statement shape lives in L<DBIO::ClickHouse::DDL::Emit> so that this
module and the later diff renderers agree char-for-char.

=head2 What is deliberately NOT emitted

Foreign keys and unique constraints are not left out silently: a declaration that
asks for one is refused, see L</What install_ddl refuses>.

=over 4

=item * B<Foreign keys.> ClickHouse has no foreign key concept at all -- not
even a parsed-and-ignored one. See C<docs/adr/0004-no-foreign-keys.md>.

=item * B<Unique constraints.> Likewise absent; C<add_unique_constraint> is
schema metadata DBIO uses for lookups, and ClickHouse cannot enforce it. Use
C<ReplacingMergeTree> with the key in C<ORDER BY> if you want last-write-wins
deduplication.

=item * B<Auto-increment.> There are no sequences and no identity columns. An
C<is_auto_increment> column of a UUID-family type gets
C<DEFAULT generateUUIDv4()>; for any other type the flag is B<refused>
(see L</What install_ddl refuses>) -- it used to be ignored silently, which
built a table without the behaviour the declaration promised.

=item * B<Standalone indexes.> There is no C<CREATE INDEX>. ClickHouse's
data-skipping indexes are declared inline in C<CREATE TABLE>
(C<INDEX name expr TYPE ... GRANULARITY n>); see L</Data-skipping indexes>.

=back

=head2 Data-skipping indexes

The canonical index declarations of a result source (L<DBIO::Cake/idx>,
C<indices>, L<DBIO::ResultSource/add_index_declaration>; ADR 0061 in core) are
read with C<< index_declarations_for('clickhouse', [qw(type granularity
expression)]) >> and rendered inline in the C<CREATE TABLE> body, after the
columns, sorted by name, through L<DBIO::ClickHouse::DDL::Emit/index_def> --
the very function the diff renders an added index with.

    $source->add_index_declaration({
      name    => 'score_idx',
      columns => ['score'],
      driver  => { clickhouse => { type => 'minmax', granularity => 4 } },
    });
    # INDEX `score_idx` `score` TYPE minmax GRANULARITY 4

=over 4

=item * C<type> is required and passed verbatim (C<minmax>, C<set(100)>,
C<bloom_filter(0.01)>, ...). There is no plain index in ClickHouse, so a
declaration without a C<clickhouse> block, with an empty one or without
C<type> is refused: the type cannot be made up.

=item * C<granularity> is optional, a positive integer; omitted, the server
default stands.

=item * C<expression> is optional and emitted verbatim; without it the
indexed expression is the declared column (several columns become the tuple
C<(`a`, `b`)>).

=back

Refused loudly, naming the source and the index, never rendered as a simpler
index: C<unique> (ClickHouse has no unique index), a block holding only
another driver's keys, an unknown key in the block, a non-empty top-level
C<options> or a top-level C<type> other than C<unique>.

=head2 No hand-declared source

Unlike the other drivers, this one has no per-driver hand-written index
accessor (C<clickhouse_table> carries engine clauses only), so there is
nothing for a canonical declaration to win against.

=head2 Statement order

Tables are emitted in sorted-name order, before the views. Because no foreign
keys are emitted, there are no inter-table dependencies to satisfy, so the
alphabetical order is both sufficient and B<deterministic> -- the diff layer
depends on that stability. Views come last, each after the views its C<SELECT>
reads, otherwise by name (L</view_order>).

=head2 Type mapping

The portable C<data_type> of a column is mapped to a native ClickHouse type.
The interesting cases, and why they were decided that way:

=over 4

=item * B<Integers> map by width, not to one catch-all: C<tinyint> to C<Int8>,
C<smallint> to C<Int16>, C<int>/C<integer> to C<Int32>, C<bigint> to C<Int64>.
C<< extra => { unsigned => 1 } >> (the spelling DBIC's MySQL loader emits)
selects the C<UInt*> counterpart.

=item * B<Strings.> The whole varchar/char/text/blob family collapses onto
C<String>, ClickHouse's arbitrary-length byte string. There is no length limit
to enforce and no separate binary type, so C<size> is dropped.

=item * B<C<FixedString(N)> is opt-in>, via
C<< extra => { fixed_string => 1 } >> on a sized column -- never inferred from
C<char(N)>. C<FixedString> pads with zero B<bytes> rather than spaces and
hands the padding back to the client, so it does not mean what C<CHAR(N)>
means in any other engine. It is a storage optimization for genuinely
fixed-width binary keys (hashes, country codes), which is a decision only the
schema author can make.

=item * B<C<Decimal(P, S)>> comes straight from
C<< size => [precision, scale] >>. A sizeless C<decimal> cannot be rendered --
ClickHouse has no bare C<Decimal> -- so it falls back to C<Decimal(38, 9)>,
the widest precision still inside C<Decimal128>.

=item * B<C<date> maps to C<Date32>, not C<Date>.> C<Date> is two bytes and
starts at 1970-01-01, so it cannot hold a date of birth or any historical
date; C<Date32> covers 1900-2299. Correctness over two bytes per row. The
narrow type is reachable by spelling it natively --
C<< data_type => 'Date' >>, capital C<D> -- where the range is known to be
safe and the column is hot.

=item * B<C<datetime>/C<timestamp> map to C<DateTime64(3)>> --
millisecond precision. Plain C<DateTime> is second-resolution and capped at
2106; C<DateTime64(3)> matches what an ORM user gets from every other DBIO
driver's C<timestamp>. Spelling C<< data_type => 'DateTime' >> natively asks
for the second-resolution type. C<timestamptz> adds the zone the same way
ClickHouse does, inside the type: C<< DateTime64(3, 'UTC') >>.

=item * B<C<time> maps to C<String>.> ClickHouse gained C<Time>/C<Time64>
types only recently and behind an experimental setting, so there is no
portable native target; C<String> is lossless and round-trips. The native
C<< data_type => 'Time' >> is passed through for schemas running with that
setting enabled.

=item * B<C<boolean> maps to C<Bool>>, not C<UInt8>. C<Bool> is an alias for
C<UInt8> in the engine, but it is what C<SHOW CREATE TABLE> reports, which
keeps the desired-state DDL and the introspected model comparable.

=item * B<Enums.> C<< data_type => 'enum', extra => { list => [...] } >>
renders C<Enum8> for up to 127 members and C<Enum16> beyond, numbering members
C<1..N> in declaration order. Appending a member is then a non-destructive
change; reordering is not.

=item * B<Arrays.> A C<data_type> ending in C<[]> (C<text[]>) becomes
C<Array(T)>.

=item * B<C<Nullable(T)>> is derived from C<is_nullable> -- ClickHouse columns
are NOT NULL by default, and nullability lives in the type rather than in a
column constraint. Composite types are left alone: the server rejects
C<Nullable(Array(T))>.

=item * B<C<LowCardinality(T)>> is opt-in via
C<< extra => { low_cardinality => 1 } >>. It cannot be inferred, because it is
a win for low-distinct-count columns and a loss otherwise. It nests outside
nullability: C<LowCardinality(Nullable(String))>.

=item * B<Anything else passes through verbatim>, so a native ClickHouse type
name can be written straight into C<data_type> (C<IPv6>, C<Point>,
C<Map(String, UInt64)>). A C<data_type> that already carries parentheses is
likewise never rewritten.

=item * B<An exact native spelling is never translated.> The portable map is
consulted case-insensitively, so C<VARCHAR> and C<varchar> both render
C<String> -- but a C<data_type> spelled B<exactly> the way ClickHouse spells
the type itself, capitalization included, counts as native and is passed
through before the map is consulted at all. That is what makes the narrow
C<< data_type => 'Date' >> and C<< data_type => 'DateTime' >> above reachable
rather than being swallowed by the portable C<date> / C<datetime> entries. The
same rule makes C<< data_type => 'JSON' >> ClickHouse's semi-structured
C<JSON> type while C<< data_type => 'json' >> stays C<String>, and
C<< data_type => 'Time' >> the native C<Time> while C<< data_type => 'time' >>
stays C<String>.

Only seven names are affected -- C<String>, C<Bool>, C<UUID>, C<Date>,
C<DateTime>, C<Time>, C<JSON> -- because every other native name is absent
from the portable map and already passes through untouched. Note that the
native name wins over the C<extra> flags that pick a type: C<String> with
C<< extra => { fixed_string => 1 } >> is C<String>; ask for C<FixedString(N)>
through the portable C<char> spelling, or write C<FixedString(N)> out.

=back

Nullability is B<not> emitted as a C<NOT NULL> column constraint; it is part
of the rendered type. See L<DBIO::ClickHouse::DDL::Emit/column_def>.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::ClickHouse::DDL->install_ddl($schema);

Returns the full installation DDL as a single string, statements separated by
a blank line.

A source whose table is C<database.table> (C<< table('other.t') >>) is made in
that database: C<CREATE TABLE `other`.`t`> (L</qualified_tables>).
The optional second argument is a hash reference; C<< local_only => 1 >> leaves
those tables out, which is what the scratch database of a diff gets -- the diff
reads the current database alone.

=head2 qualified_tables

    my @pairs = DBIO::ClickHouse::DDL->qualified_tables($schema);   # ([ 'other.t', 'other' ], ...)

The tables and views of the schema whose name is C<database.table> or
C<database.view>, with their database, in source order and once each (a view
only when it is made, like L</install_ddl> does: not a virtual one, and one
with a definition). A virtual source and a name that names nothing are not
among them.

=head2 view_order

    my @names = DBIO::ClickHouse::DDL->view_order({ a => 'SELECT ... FROM b', b => '...' });

The names of the views of C<< { view_name =E<gt> $select_sql } >> in the order
they are written in: each view after the views its C<SELECT> reads, the others
by name. Dropping goes the other way round: C<reverse> of this.

The server resolves the tables of a view's C<SELECT> when the view is created,
so a view over a view that does not exist yet is C<UNKNOWN_TABLE> (measured,
25.3). Nothing the server records helps: C<system.tables.dependencies_table> is
empty for a plain view, and the views of an install do not exist yet anyway. The
only source is the text of the definition, read against the names of the views
given. That is a reading with limits:

=over 4

=item * a read is a name after C<FROM> or C<JOIN>, bare, in backticks or
qualified by a database (C<db.v>); a view whose name carries a database
(C<other.v>) is read by that qualified name only. Strings, comments and
everything else are not names: a column, an alias or a literal that spells a
view is not a read.

=item * a comma join (C<FROM a, v>) reads only the first name; write C<JOIN>.
A C<WITH> name that shadows a view still counts as a read of that view. A read
the text hides (a dynamic C<remote()>, a dictionary) is not seen.

=item * what is not seen is not ordered: the install then fails at the server,
as it did before, never silently differently.

=back

A cycle (C<a> reads C<b>, C<b> reads C<a>) is a L<DBIO::Exception> naming every
view in it, thrown before a statement is written.

=head2 declared_views

    my $views = DBIO::ClickHouse::DDL->declared_views($schema);

Returns C<< { view_name =E<gt> $select_sql } >> for every non-virtual view
source with a C<view_definition> -- exactly the views L</install_ddl> creates
(one selection, shared). The Diff cannot recover a definition from the
introspected model, so L<DBIO::ClickHouse::Deploy> hands these to it, which
renders the C<CREATE VIEW> of a view the upgrade has to create.

A view named C<database.view> is made in that database. The optional
second argument is a hash reference; C<< local_only => 1 >> leaves those views
out, which is what the diff gets: it reads the current database alone, so a
view of another database is installed and never compared, replaced or dropped.

=head2 declared_settings

    my $settings = DBIO::ClickHouse::DDL->declared_settings($schema);

Returns C<< { table_name =E<gt> \%settings } >> for every physical table whose
result class declares C<settings> through C<clickhouse_table>. The Diff cannot
recover them from the scratch database (C<engine_full> there also carries the
server's own defaults), so L<DBIO::ClickHouse::Deploy> hands the declared ones
to the Diff, which renders them into the C<CREATE TABLE> of a table the upgrade
creates.

=head2 column_type

    my $type = DBIO::ClickHouse::DDL->column_type($source->column_info($name));
    # 'LowCardinality(Nullable(String))'

Renders one DBIO C<column_info> hashref as the ClickHouse type string this
module would put in a C<CREATE TABLE>, wrappers and all. It is the single
public entry to L</Type mapping> above; C<install_ddl> and the diff both go
through the same code, so there is exactly one answer to "what type is this
column" in this distribution.

Exposed because it is useful outside DDL generation:
L<DBIO::ClickHouse::Native> needs the identical string to build the column
list C<< ClickHouse::Encoder->new >> takes, and a second type table would be a
second truth.

=head2 What install_ddl refuses

C<install_ddl> throws, before it renders a statement and so before any is
executed, when the declaration asks for something ClickHouse cannot build and
the table would otherwise be created without it (conformance DDL
list). Every offender is named, with table and column:

=over 4

=item * a C<UNIQUE> constraint other than the primary key. ClickHouse has no
unique constraint and does not check a key before inserting
(L<https://clickhouse.com/docs/guides/developer/deduplication>); a table that
accepts duplicates must not pass for one that does not. The way out is the
engine: C<ReplacingMergeTree> through C<clickhouse_table>.

=item * a relationship that is a foreign key constraint (a C<belongs_to> is
one unless declared with C<< is_foreign_key_constraint => 0 >>). The
C<CREATE TABLE> grammar has no foreign key clause
(L<https://clickhouse.com/docs/sql-reference/statements/create/table>); the
relationship keeps working for joins, prefetch and C<find> when it is declared
as no constraint.

=item * an C<is_auto_increment> column that is not a UUID. ClickHouse has no
auto-increment and no identity column
(L<https://clickhouse.com/docs/sql-reference/statements/create/table>); the
column is named in the error with the alternative, a C<uuid> column with
C<is_auto_increment> (C<DEFAULT generateUUIDv4()>).

=item * a C<bit> column with a size. ClickHouse has no C<BIT> type
(L<https://clickhouse.com/docs/sql-reference/data-types>); mapping C<bit(8)>
to a wider integer would lose the width without a word.

=item * a table or view name that names nothing: two dots or an empty half
(C<a.b.c>, C<.t>, C<db.>). A name C<database.table> or C<database.view> is made
in that database (L</qualified_tables>); the database must exist, which
L<DBIO::ClickHouse::Deploy/install> asks of the server before its first
statement.

=back

This replaces the silent omission of ADR 0004 for the first three; the
auto-increment and C<bit> refusals replace a silent ignore and a silent
widening.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::DDL::Emit> - the statement templates this module renders through

=item * L<DBIO::ClickHouse::Result> - the C<clickhouse_table> per-table options

=item * L<DBIO::ClickHouse::Storage> - the storage this DDL is deployed through

=item * L<DBIO::ClickHouse::Native> - the other consumer of L</column_type>

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
