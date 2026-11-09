package DBIO::Sybase::DDL;
# ABSTRACT: Generate Sybase ASE DDL from DBIO Result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp ();
use Exporter 'import';
use DBIO::Exception;
use DBIO::Sybase::Quote qw(quote_ident);

our @EXPORT_OK = qw(sybase_column_type sybase_default_clause);

# ASE datatypes that take no length or precision.
our $NO_LENGTH_TYPE = qr/\A(?:
    (?:unsigned\s+)?(?:tiny|small|big)?int(?:eger)? | u(?:tiny|small|big)?int
  | real | money | smallmoney | bit | image | text | unitext | sysname | longsysname
  | date | time | bigtime | bigdatetime | datetime | smalldatetime
)\z/x;



sub install_ddl {
  my ($class, $schema) = @_;
  my @stmts;
  my @view_stmts;
  my %seen_table;
  my %seen_view;
  my @fk_sources;

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $result_class = $source->result_class;
    my $table_name = $source->name;

    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = ref $table_name eq 'SCALAR' ? $$table_name : $table_name;
      next if ref $vname || $seen_view{$vname}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;', quote_ident($vname), $def;
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd', emitted
    # unquoted) or an inline subquery source; deref the former, skip the latter.
    if (ref $table_name eq 'SCALAR') {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
    }
    next if ref $table_name;

    # Several result sources can map to one physical table; emit it once.
    next if $seen_table{$table_name}++;
    push @fk_sources, [ $table_name, $source ];

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      _check_column_type($table_name, $col_name, $info);
      my $type = sybase_column_type($info->{data_type}, $info->{size});
      my $def = sprintf '  %s %s', quote_ident($col_name), $type;

      # ASE's column definition is
      #   column_name datatype [default ...] [{identity | null | not null}]
      # (karr k47): the default comes BEFORE the nullability -- `NOT NULL
      # DEFAULT 'x'` is Msg 156 on ASE 16.0 SP02 -- and identity, null and
      # not null are alternatives. So an IDENTITY column is the attribute
      # alone: never nullable, and its value is the server's, not a default.
      if ($info->{is_auto_increment}) {
        push @col_defs, $def
          . _identity_clause($type, $info->{data_type}, $col_name, $table_name);
        next;
      }

      $def .= sybase_default_clause($info->{default_value}, $info->{data_type}, $col_name);

      # ADR 0043: a missing is_nullable means NOT NULL, matching what
      # DBIO::Schema::Type::canonical_column already claims (not_null => 1).
      # The old gate -- "defined && !" -- emitted nothing for a missing key, so
      # the deployed column was nullable while the compiled model said NOT NULL,
      # and target_from_compiled diffs diverged on exactly that axis.
      #
      # A nullable column is spelled NULL, never left bare (karr k47): a bare
      # column takes the database's "allow nulls by default" option, which is
      # off in model and so in every fresh database -- the temp DB of
      # Deploy::diff included -- while the live database may have it on. The
      # same DDL then deployed two different columns.
      $def .= $info->{is_nullable} ? ' NULL' : ' NOT NULL';

      push @col_defs, $def;
    }

    # Primary key constraint
    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { quote_ident($_) } @pk_cols);
    }

    my $qualified = quote_ident($table_name);
    my $sql = sprintf "CREATE TABLE %s (\n%s\n);", $qualified, join(",\n", @col_defs);
    push @stmts, $sql;

    # Unique indexes (Sybase emits these as separate CREATE INDEX).
    # %unique_set answers "is this column set already unique" (sorted, as
    # the unique constraints are compared); %written_cols and %written_name
    # answer "is there an index over these columns in this order" and "is the
    # name taken" for the declared indexes below (karr k88).
    my %unique_set = (join("\0", sort @pk_cols) => 1);
    my (%written_cols, %written_name);
    $written_cols{ join "\0", @pk_cols } = 1 if @pk_cols;
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      if ($info->{is_unique} || $info->{is_single_unique_key}) {
        $unique_set{$col_name} = 1;
        my $iname = "${table_name}_${col_name}_idx";
        $written_cols{$col_name} = 1;
        $written_name{$iname} = [ $col_name ];
        push @stmts, sprintf 'CREATE UNIQUE INDEX %s ON %s (%s);',
          quote_ident($iname),
          $qualified,
          quote_ident($col_name);
      }
    }

    # The unique constraints of the source (add_unique_constraint), one
    # CREATE UNIQUE INDEX each, named after the constraint (karr k56) -- ASE
    # index names are per table. 'primary' is the key itself, and a column
    # set already unique (the key, a column flag above, an earlier constraint)
    # is not indexed twice.
    my %uniques = $source->unique_constraints;
    for my $uname (sort keys %uniques) {
      next if $uname eq 'primary';
      my @cols = @{ $uniques{$uname} };
      next if !@cols || $unique_set{ join "\0", sort @cols }++;
      $written_cols{ join "\0", @cols } = 1;
      $written_name{$uname} = [ @cols ];
      push @stmts, sprintf 'CREATE UNIQUE INDEX %s ON %s (%s);',
        quote_ident($uname), $qualified,
        join(', ', map { quote_ident($_) } @cols);
    }

    # The index declarations of the source (Cake idx, indices; ADR 0061 in
    # core, karr k88). ASE has no partial and no function index, so the
    # sybase block takes no key at all: the helper refuses an unknown key and
    # an entry that carries only another driver's block, naming the index.
    # What ASE cannot do is refused here as well, never written plainer: a
    # type other than unique, options, more than 31 key columns.
    for my $decl ($source->index_declarations_for('sybase', [])) {
      my $iname = $decl->{name};
      my @cols  = @{ $decl->{columns} };
      Carp::croak sprintf(
        "DBIO::Sybase: index '%s' on %s has type '%s', which ASE cannot "
          . 'build -- only a plain or a unique index exists (type => '
          . "'unique'); nothing plainer is written in its place",
        $iname, $table_name, $decl->{type},
      ) if defined $decl->{type} && $decl->{type} !~ /\Aunique\z/i;
      Carp::croak sprintf(
        "DBIO::Sybase: index '%s' on %s has options, which this DDL has no "
          . 'rendering for (fillfactor and the like are server settings of '
          . 'the index); nothing plainer is written in its place',
        $iname, $table_name,
      ) if defined $decl->{options}
        && (ref $decl->{options} ne 'HASH' || %{ $decl->{options} });
      Carp::croak sprintf(
        "DBIO::Sybase: index '%s' on %s has %d columns; ASE takes at most "
          . '31 key columns in an index',
        $iname, $table_name, scalar @cols,
      ) if @cols > 31;

      # The same name over the same columns is the index already written;
      # the same name over other columns is a different index that ASE
      # cannot hold beside it (names are per table).
      if (my $have = $written_name{$iname}) {
        next if join("\0", @$have) eq join("\0", @cols);
        Carp::croak sprintf(
          "DBIO::Sybase: index '%s' on %s is declared over (%s), but an "
            . "index of that name over (%s) is already written; ASE index "
            . 'names are per table',
          $iname, $table_name, join(', ', @cols), join(', ', @$have),
        );
      }
      # A second index over the columns of a unique one already written, in
      # that order, is a duplicate (as dbio-sqlite karr k79) and is not
      # written. Only unique indexes are remembered: a plain index never
      # swallows a unique declaration over the same columns.
      next if $written_cols{ join "\0", @cols };
      $written_cols{ join "\0", @cols } = 1 if $decl->{unique};
      $written_name{$iname} = [ @cols ];
      push @stmts, sprintf 'CREATE %sINDEX %s ON %s (%s);',
        $decl->{unique} ? 'UNIQUE ' : '', quote_ident($iname), $qualified,
        join(', ', map { quote_ident($_) } @cols);
    }
  }

  # Foreign keys, after every CREATE TABLE (karr k54): cd references track and
  # track references cd in the shared test schema, so no table order would do.
  for my $pair (@fk_sources) {
    my ($table_name, $source) = @$pair;
    push @stmts, map { _fk_statement($table_name, $_) }
      _table_foreign_keys($schema, $source, \%seen_table);
  }

  return join "

", @stmts, @view_stmts;
}

# One ALTER TABLE ... ADD CONSTRAINT per FK. No ON DELETE / ON UPDATE: ASE has
# no declarative referential actions (Msg 156 on 16.0, for NO ACTION as well),
# a reference always restricts -- which is what Introspect reports (NO ACTION)
# for both sides. A declared action other than NO ACTION never gets here:
# _table_foreign_keys refuses it (karr k91), so nothing is silently dropped.
sub _fk_statement {
  my ($table_name, $fk) = @_;
  return sprintf 'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s (%s);',
    quote_ident($table_name), quote_ident($fk->{constraint_name}),
    join(', ', map { quote_ident($_) } @{ $fk->{from_columns} }),
    quote_ident($fk->{to_table}),
    join(', ', map { quote_ident($_) } @{ $fk->{to_columns} });
}

# The FK constraints of one source, from its relationships marked
# is_foreign_key_constraint (belongs_to sets it unless told otherwise) -- the
# signal DBIO::MySQL::DDL, DBIO::SQLite::DDL and DBIO::MSSQL::DDL read too. A
# relationship is left out when it cannot be one ASE constraint:
#
# - its condition is not plain 'foreign.x' => 'self.y' pairs (a coderef);
# - its target table is not part of this deploy (%$deployed): not in the
#   schema, a view, or an inline subquery source;
# - its target columns are neither the target's primary key nor one of its
#   unique constraints -- ASE refuses a reference without a unique index
#   behind it, and a belongs_to may legitimately join on any column.
#
# A relationship that does become a constraint and declares an on_delete or
# on_update other than NO ACTION (CASCADE, SET NULL, SET DEFAULT, RESTRICT, any
# unknown word) is refused, checked before the de-duplication below so the
# second relationship over the same columns is refused too (karr k91). What
# does not become a constraint is not looked at.
#
# Two relationships over the same columns to the same target (cd.artist and
# cd.very_long_artist_relationship) are one constraint. Pairs are ordered by
# the target's key order, so a composite reference matches its key; the name
# fk_<table>_<cols> is DBIO::Sybase::Diff::ForeignKey's generated name.
sub _table_foreign_keys {
  my ($schema, $source, $deployed) = @_;
  my $table_name = $source->name;
  $table_name = $$table_name if ref $table_name eq 'SCALAR';
  my (@fks, %seen);

  for my $rel (sort $source->relationships) {
    my $info = $source->relationship_info($rel);
    next unless $info && $info->{attrs} && $info->{attrs}{is_foreign_key_constraint};
    my $cond = $info->{cond};
    next unless ref $cond eq 'HASH' && %$cond;

    my @pairs;
    for my $key (keys %$cond) {
      my $val = $cond->{$key};
      next if ref $val;
      my ($to)   = $key =~ /\Aforeign\.(\w+)\z/ or next;
      my ($from) = $val =~ /\Aself\.(\w+)\z/    or next;
      push @pairs, [ $from, $to ];
    }
    next unless @pairs == keys %$cond;

    my $fs = eval { $schema->source($info->{source}) }
      // eval { $schema->source($info->{class}) }
      // eval { $schema->source(($info->{source} // '') =~ s/.*:://r) }
      or next;
    next if $fs->isa('DBIO::ResultSource::View');
    my $to_table = $fs->name;
    $to_table = $$to_table if ref $to_table eq 'SCALAR';
    next if ref $to_table || !$deployed->{$to_table};

    my @key = $fs->primary_columns;
    my %pos;
    @pos{@key} = (0 .. $#key);
    @pairs = sort { ($pos{ $a->[1] } // 1e9) <=> ($pos{ $b->[1] } // 1e9)
      || $a->[1] cmp $b->[1] } @pairs;

    my $to_set = join "\0", sort map { $_->[1] } @pairs;
    my %uniques = $fs->unique_constraints;
    next unless grep { join("\0", sort @$_) eq $to_set } values %uniques;

    my @from = map { $_->[0] } @pairs;
    my @to   = map { $_->[1] } @pairs;
    _check_fk_action("relationship '$rel'", $table_name, 'ON DELETE', $info->{attrs}{on_delete}, \@from);
    _check_fk_action("relationship '$rel'", $table_name, 'ON UPDATE', $info->{attrs}{on_update}, \@from);
    next if $seen{ join "\0", @from, '->', $to_table, @to }++;
    push @fks, {
      constraint_name => join('_', 'fk', $table_name, @from),
      from_columns    => \@from,
      to_table        => $to_table,
      to_columns      => \@to,
    };
  }
  return @fks;
}

# What ASE cannot hold is refused before the server is asked (karr k97),
# naming table and column, instead of passing on Msg 2715 (no ENUM type) or
# writing something plainer than the declaration: a size on BIT would be
# dropped without a word, and a nullable BIT is Msg 2718 (ASE keeps no NULL
# flag for a bit).
sub _check_column_type {
  my ($table_name, $col_name, $info) = @_;
  my $declared = lc($info->{data_type} // '');
  DBIO::Exception->throw(sprintf
    "DBIO::Sybase: table '%s', column '%s': type 'enum' is refused: ASE has no enum "
      . "type (Msg 2715). Declare a varchar column",
    $table_name, $col_name) if $declared eq 'enum';

  return unless sybase_column_type($declared, $info->{size}) eq 'BIT';
  my $size = ref $info->{size} eq 'ARRAY' ? $info->{size}[0] : $info->{size};
  DBIO::Exception->throw(sprintf
    "DBIO::Sybase: table '%s', column '%s': size '%s' on type '%s' is refused: bit "
      . "has no length in ASE",
    $table_name, $col_name, $size, $info->{data_type})
    if defined $size && length $size;
  DBIO::Exception->throw(sprintf
    "DBIO::Sybase: table '%s', column '%s': NULL in a bit column is refused: ASE "
      . "cannot hold NULL in a BIT column (Msg 2718). Declare it is_nullable => 0",
    $table_name, $col_name) if $info->{is_nullable} && !$info->{is_auto_increment};
}

# Throws unless $value is no action: undef, '' or NO ACTION (case and
# whitespace ignored). Shared with DBIO::Sybase::Diff::ForeignKey::Create.
# $what names the relationship (DDL) or the constraint (Diff).
sub _check_fk_action {
  my ($what, $table_name, $event, $value, $columns) = @_;
  return unless defined $value;
  (my $norm = uc $value) =~ s/\s+/ /g;
  $norm =~ s/\A | \z//g;
  return if $norm eq '' || $norm eq 'NO ACTION';
  DBIO::Exception->throw(sprintf(
    "DBIO::Sybase: %s on table %s%s declares %s %s, but ASE has no referential "
      . 'actions (Msg 156, not even NO ACTION is accepted as syntax); the '
      . 'action is refused and the reference always restricts. Drop the action '
      . 'from the relationship (or set it to NO ACTION) -- nothing is written in '
      . 'its place',
    $what, $table_name,
    ( $columns && @$columns ? ' (column ' . join(', ', @$columns) . ')' : '' ),
    $event, $value,
  ));
}


sub sybase_column_type {
  my ($data_type, $size) = @_;
  my $type = lc($data_type // 'varchar');

  # Integer types. The logical name carries the width and nothing else: ASE has
  # had a native BIGINT since 15.0, so a column declared `bigint` is deployed
  # as 64 bits rather than narrowed to INT -- a narrowing that stayed silent
  # until the first value over 2^31-1. `serial` is the 32-bit auto-increment
  # variant (DBIO::Cake lists serial/bigserial/smallserial as three widths,
  # mirroring integer/bigint/smallint), so it maps by width exactly like its
  # non-serial twin; IDENTITY is a column attribute in ASE, not a type, and
  # install_ddl appends it separately. These two lines were transposed until
  # karr k40, which also meant a deployed `serial` (BIGINT) read back from
  # the catalog as `bigint` and re-rendered as INT, so the diff never
  # converged against its own deployment.
  return 'INT' if $type eq 'integer' || $type eq 'serial';
  return 'SMALLINT' if $type eq 'smallint' || $type eq 'tinyint';
  return 'BIGINT' if $type eq 'bigint' || $type eq 'bigserial';

  # Character types
  #
  # VARCHAR and CHAR take exactly ONE scalar length in ASE, so an arrayref size
  # has one member that can mean anything: the width. Read it, rather than let
  # the reference numify to its memory address and render as
  # VARCHAR(94182096057624) -- a length the caller never wrote, emitted without
  # a warning (karr k33; dbio-mssql settled the identical blind spot in its
  # karr k27). That is the same "first member is the width" reading the numeric
  # branch below has always had. The most plausible origin of the shape is a
  # column retyped from numeric/decimal to varchar whose size => [p, s] was
  # left behind, which argues for keeping the width rather than refusing the
  # column. An arrayref naming no width ([], [undef]) falls through to the
  # historical default exactly as an absent size does, so every arrayref shape
  # renders identically to its scalar counterpart. This driver's own
  # introspection never produces an arrayref here (Introspect::Columns sets a
  # scalar size for char types), so the shape is hand-written column info.
  my $len = ref $size eq 'ARRAY' ? $size->[0] : $size;
  # `character` and `char varying` / `character varying` are the standard
  # spellings of CHAR and VARCHAR (karr k70). Passed through they lost their
  # size: `character` size 10 deployed as char(1), without an error.
  if ($type eq 'varchar' || $type eq 'nvarchar'
      || $type eq 'char varying' || $type eq 'character varying') {
    return sprintf 'VARCHAR(%d)', defined $len ? $len : 255;
  }
  if ($type eq 'char' || $type eq 'nchar' || $type eq 'character') {
    return sprintf 'CHAR(%d)', defined $len ? $len : 1;
  }
  # mediumtext is MySQL's; ASE has one text type (Msg 2715 passed through).
  return 'TEXT' if $type eq 'text' || $type eq 'long' || $type eq 'mediumtext';

  # Date/time types
  return 'DATETIME' if $type eq 'date' || $type eq 'timestamp' || $type eq 'datetime';
  return 'SMALLDATETIME' if $type eq 'smalldatetime';

  # Binary types
  return 'IMAGE' if $type eq 'bytea' || $type eq 'blob';
  return 'TEXT' if $type eq 'clob';

  # Numeric types
  if ($type eq 'numeric' || $type eq 'decimal') {
    return sprintf 'NUMERIC(%d,%d)', $size->[0], $size->[1] // 0 if ref $size eq 'ARRAY';
    return sprintf 'NUMERIC(%d,0)', $size if defined $size;
    return 'NUMERIC(18,6)';
  }
  return 'FLOAT' if $type eq 'float' || $type eq 'real';
  return 'DOUBLE PRECISION' if $type eq 'double precision' || $type eq 'double';

  # Boolean — Sybase has bit
  return 'BIT' if $type eq 'boolean';

  # GUID. ASE has no such type -- passed through, `UNIQUEIDENTIFIER` is Msg
  # 2715 "Can't find type" -- so the column holds the string form (karr k52):
  # 36 characters hyphenated, which also takes newid()'s 32. The width is the
  # type's own; a declared size does not move it.
  return 'VARCHAR(36)' if $type eq 'uniqueidentifier';

  # Pass through unknown types as-is (uppercase), with the size they were
  # given (karr k70): binary(n), varbinary(n), unichar(n), univarchar(n) and a
  # user-defined type lose their length otherwise and deploy as a length of 1.
  # The ASE types that take no length are left bare, so a hand-written
  # `int, size => 11` does not become INT(11).
  return uc($type) if $type =~ $NO_LENGTH_TYPE;
  my @args = grep { defined } (ref $size eq 'ARRAY' ? @$size : $size);
  return uc($type) unless @args;
  return sprintf '%s(%s)', uc($type), join ',', @args;
}


sub sybase_default_clause {
  my ($dv, $data_type, $column_name) = @_;
  return '' unless defined $dv;
  if (ref $dv eq 'SCALAR') {
    # CURRENT_TIMESTAMP is Msg 128 in an ASE DEFAULT; getdate() is its function.
    return ' DEFAULT getdate()' if $$dv =~ /\A\s*current_timestamp\s*\z/i;
    return " DEFAULT $$dv";
  }
  return '' if $dv eq 'null';
  if (_is_numeric_type($data_type)) {
    return " DEFAULT $dv" if _is_numeric_literal($dv);
    Carp::croak sprintf(
      'DBIO::Sybase: default_value %s of column %s is not a number, but its '
        . 'type %s takes a numeric default -- quoted, ASE stores it as a VARCHAR '
        . 'constant and every INSERT leaving the column out fails with Msg 257; '
        . 'write a number, or a SCALAR ref for an SQL expression',
      "'$dv'", $column_name // '(unnamed)', sybase_column_type($data_type),
    );
  }
  (my $lit = $dv) =~ s/'/''/g;
  return " DEFAULT '$lit'";
}

# True when a column of this logical/ASE type takes a numeric default. Read off
# what sybase_column_type renders, so a type mapped to a numeric SQL type here
# is numeric there too; the bare ASE names (MONEY, UINT, ...) pass through that
# mapping uppercased and are listed alongside.
sub _is_numeric_type {
  my ($data_type) = @_;
  return 0 unless defined $data_type;
  (my $sql = sybase_column_type($data_type)) =~ s/\(.*//s;
  return $sql =~ /\A(?:
      (?:UNSIGNED\s+)?(?:TINY|SMALL|BIG)?INT(?:EGER)?
    | U(?:TINY|SMALL|BIG)?INT
    | NUMERIC | DECIMAL | FLOAT | REAL | DOUBLE\ PRECISION
    | BIT | (?:SMALL)?MONEY
  )\z/x ? 1 : 0;
}

# The IDENTITY attribute of an is_auto_increment column, with its leading
# space -- or a refusal (karr k52). ASE takes the attribute on the integer
# types and NUMERIC(p,0) only (Msg 2764 "Identity field must be a numeric with
# a scale of 0", live: INT/SMALLINT/TINYINT/BIGINT/unsigned and NUMERIC(p,0)
# accepted; NUMERIC with a scale, DECIMAL, FLOAT, REAL, DOUBLE PRECISION, BIT,
# MONEY, SMALLMONEY and every character, date/time and binary type refused). So
# on a type KNOWN not to take it there is nothing to render: with it the server
# refuses the CREATE TABLE, without it the column deploys and the value the
# model expects from the server never comes.
#
# $sql_type is the column's rendered type (sybase_column_type), so a logical
# name is judged by what it deploys as (numeric/decimal without a size is
# NUMERIC(18,6), so refused). Three cases, deliberately:
#
# - an integer type or NUMERIC with scale 0: IDENTITY.
# - known not to take it (the lists below): croak.
# - anything else is a name this module does not know -- a user-defined
#   datatype, which may be numeric -- and passes with its IDENTITY.
#
# Called by DBIO::Sybase::Diff::Table::Create too: both emitters of the column
# grammar carry the one rule.
sub _identity_clause {
  my ($sql_type, $data_type, $column_name, $table_name) = @_;
  (my $base = $sql_type) =~ s/\(.*//s;
  my $refused = $base =~ /\A(?:
      (?:UNI)?(?:VAR)?CHAR | (?:UNI)?TEXT
    | (?:SMALL|BIG)?DATETIME | (?:BIG)?TIME | DATE
    | (?:VAR)?BINARY | IMAGE
    | FLOAT | REAL | DOUBLE\ PRECISION | BIT | (?:SMALL)?MONEY | DECIMAL
  )\z/x ? 1 : 0;
  # NUMERIC takes it with a scale of 0 only.
  $refused = 1 if !$refused && $base eq 'NUMERIC'
    && $sql_type =~ /\(\s*\d+\s*,\s*(\d+)\s*\)/ && $1 != 0;
  Carp::croak sprintf(
    'DBIO::Sybase: column %s of table %s is is_auto_increment, but its '
      . 'data_type %s is %s on ASE, and ASE takes IDENTITY on an integer '
      . 'or NUMERIC(p,0) column only (Msg 2764); if the value is generated '
      . 'some other way (a GUID, a function), declare the column with '
      . 'auto_nextval instead of is_auto_increment',
    $column_name // '(unnamed)', $table_name // '(unnamed)',
    $data_type // '(none)', $sql_type,
  ) if $refused;
  return ' IDENTITY';
}

# A numeric literal as ASE parses one in a DEFAULT: optional sign, digits with
# an optional fraction (or a fraction alone), optional exponent. Nothing else --
# no whitespace, no currency sign, no hex.
sub _is_numeric_literal {
  my ($v) = @_;
  return defined $v && !ref $v
    && $v =~ /\A[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?\z/ ? 1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::DDL - Generate Sybase ASE DDL from DBIO Result classes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Sybase::DDL> generates Sybase ASE DDL from the DBIO schema class hierarchy.
It is the desired-state side of the test-deploy-and-compare strategy used by
L<DBIO::Sybase::Deploy>.

    my $ddl = DBIO::Sybase::DDL->install_ddl($schema);
    # CREATE TABLE ...; CREATE INDEX ...;

Every name goes through L<DBIO::Sybase::Quote>: bare when it is a simple
identifier and no ASE keyword, in square brackets otherwise -- C<[dummy]>,
C<[key]>, C<[my col]>. The same holds for the C<DBIO::Sybase::Diff>
operations.

B<NOTE:> Sybase ASE does not support CHECK constraints in the same way as
other databases. Unique constraints -- a column's C<is_unique> flag as well as
the source's C<add_unique_constraint>s -- are emitted as unique indexes
instead, a constraint's index under the constraint's name.

=head2 Indexes

C<CREATE [UNIQUE] INDEX> also comes from the index declaration of the result
source that C<idx> of L<DBIO::Cake>, C<indices> and C<add_index_declaration>
write (ADR 0061 in core, C<index_declarations_for> of L<DBIO::ResultSource>).
It is written after the table's unique indexes and before the foreign keys.
The driver has no attribute of its own for hand-written indexes.

ASE has no partial and no function index, so the C<sybase> block of a
declaration takes no key: C<where>, C<expression> and any other key, a
declaration that carries only another driver's block (C<< pg => {...} >>
without C<< sybase => {} >>), a C<type> other than C<unique>, any C<options>,
and more than 31 key columns are refused with an exception naming the index --
never written as a plainer one. An empty C<< sybase => {} >> is the plain
index. The diff builds its desired model from this DDL and refuses the same.

An index over exactly the columns, in the same order, of a unique index
already written (a column's C<is_unique>, a unique constraint, the primary key)
is not written a second time. The same name over other columns is refused:
ASE index names are per table. An identifier's length is not checked here.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::Sybase::DDL->install_ddl($schema);

Returns the full installation DDL as a single string. C<$schema> may be
a connected schema instance or a schema class name.

The foreign keys come last, one C<ALTER TABLE ... ADD CONSTRAINT
fk_E<lt>tableE<gt>_E<lt>colsE<gt> FOREIGN KEY (...) REFERENCES ...> each,
after every C<CREATE TABLE> -- references may form a cycle. They are read from
the relationships marked C<is_foreign_key_constraint> (C<belongs_to> sets it
by default), without C<ON DELETE> / C<ON UPDATE>, which ASE does not have (Msg
156, for C<NO ACTION> as well). A relationship that becomes a constraint and
declares an C<on_delete> or C<on_update> other than C<NO ACTION> (undef and
the empty string mean none) -- C<CASCADE>, C<SET NULL>, C<SET DEFAULT>,
C<RESTRICT> or any other word -- is refused with a L<DBIO::Exception> naming
relationship, table, event and value, never installed as a plain reference.
The diff builds its desired model from this DDL and refuses the same. A
relationship that yields no constraint is not looked at. A relationship whose
condition is not plain column pairs, whose target table is not part of the
deploy, or whose target columns are neither the target's primary key nor one
of its unique constraints (ASE refuses a reference without a unique index
behind it) yields no constraint.

A column marked C<is_auto_increment> is rendered C<< <type> IDENTITY >>, the
attribute alone. ASE takes it on the integer types (C<INT>, C<SMALLINT>,
C<BIGINT>, the unsigned variants) and on C<NUMERIC(p,0)> only -- Msg 2764
"Identity field must be a numeric with a scale of 0" for the rest. So a column
whose type is known not to take it is refused with a C<croak> naming table,
column and type: C<NUMERIC> with a scale (and so C<numeric> /
C<decimal> without a size, which is C<NUMERIC(18,6)>), C<FLOAT>, C<DOUBLE
PRECISION>, C<BIT>, C<MONEY>, C<SMALLMONEY>, and everything
L</sybase_column_type> renders as C<VARCHAR>, C<CHAR>, C<TEXT>, C<DATETIME>,
C<SMALLDATETIME> or C<IMAGE> (C<uniqueidentifier> among them), plus the ASE
character, binary and date/time names that pass through it (C<unichar>,
C<univarchar>, C<unitext>, C<binary>, C<varbinary>, C<time>, C<bigdatetime>,
C<bigtime>). There is no statement to fall back to: without the attribute the
column would deploy and every insert relying on the server for its value would
fail. A column whose value comes from somewhere else (a GUID) is not an
identity column: the refusal points at C<auto_nextval>, the attribute for a
generated value, which renders no DDL here. A type name this module does not
know -- a user-defined datatype, which may well be numeric -- is not known to
refuse it and keeps its C<IDENTITY>.
L<DBIO::Sybase::Diff::Table> applies the same rule to a created table.

What ASE cannot hold at all is refused by C<install_ddl> as well, before the
server is asked, with a L<DBIO::Exception> naming table and column:
a column of type C<enum> (no such type, Msg 2715), a C<bit> or C<boolean> with a
C<size> (it has no length, and the size would be dropped without a word) and a
nullable one (ASE keeps no NULL flag for a bit, Msg 2718; declare
C<< is_nullable => 0 >>). C<double> is C<DOUBLE PRECISION>.

=head2 sybase_column_type

    my $sql_type = sybase_column_type($data_type, $size);

Maps a logical DBIO C<data_type> (+ optional C<size>) to its Sybase ASE
column type. C<$size> follows the DBIO convention: a scalar length for
C<varchar>/C<nvarchar>/C<char>/C<nchar>, or a C<[precision, scale]> arrayref
for C<numeric>/C<decimal>. When omitted, the historical fixed defaults
(255/1/18,6) apply. An arrayref handed to a character type is read for its
first member -- the single length those types take -- rather than numified to
its address. Shared by the DDL emitter and L<DBIO::Sybase::Diff::Table>
so both sides of the test-deploy-and-compare agree on type rendering.
Exportable on request.

C<uniqueidentifier> is C<VARCHAR(36)>, whatever C<$size> says: ASE
has no GUID type, and the column holds the string form -- 36 characters with
hyphens, which also takes the 32 of ASE's C<newid()>. The catalog reads it back
as C<varchar> with size 36, which renders the same.

C<character> is C<CHAR>, C<char varying> and C<character varying> are
C<VARCHAR>, with the length rules of those; C<mediumtext> is
C<TEXT>.

Any other name this map does not know is passed through uppercased, with the
C<$size> it was given -- C<binary> 16 is C<BINARY(16)>, an arrayref is written
comma-separated -- except the ASE datatypes that take no length (C<int>,
C<money>, C<bit>, C<date>, C<time>, ...), which stay bare: it may be an ASE
datatype not listed here or a user-defined one, and only the server can tell
(Msg 2715 if it is neither).

=head2 sybase_default_clause

    my $clause = sybase_default_clause($default_value, $data_type, $column_name);

Renders the C<DEFAULT> fragment for a column definition (with a leading
space), or the empty string when there is no default. A SCALAR ref is emitted
verbatim (SQL expression), except the bare C<current_timestamp>, which ASE
refuses in a C<DEFAULT> (Msg 128) and which is written C<getdate()>; the
literal string C<'null'> yields no clause.

Any other value is a literal, and the column's C<$data_type> decides how it is
spelled:

=over 4

=item * On a B<numeric> column -- every type L</sybase_column_type> renders as
C<INT>, C<SMALLINT>, C<BIGINT>, C<NUMERIC>, C<FLOAT>, C<DOUBLE PRECISION> or
C<BIT>, plus the ASE names C<int>, C<tinyint>, C<real>, C<money>,
C<smallmoney>, C<bit> and the unsigned integers (C<unsigned int> as written in
DDL, C<uint> / C<usmallint> / C<ubigint> as C<systypes> reports them) -- a value
that looks like a number (optional sign, digits with an optional fraction,
optional exponent) is emitted B<unquoted>, exactly as written. Quoted, ASE
accepts the C<CREATE TABLE> but keeps the default as a C<VARCHAR> constant, and
every C<INSERT> that leaves the column out fails: Msg 257 "Implicit conversion
from datatype 'VARCHAR' to 'NUMERIC' is not allowed" (live, ASE 16.0 SP02; the
same for C<BIT>).

A value on a numeric column that is B<not> a number -- C<'abc'>, C<''>,
C<'true'>, C<'$5'>, C<' 0'> -- is refused with a C<croak> naming column, value
and type. There is no correct rendering to fall back to: quoted it is the Msg
257 above, deployed without complaint and failing at the first defaulted
C<INSERT>; unquoted it is a syntax error or an identifier. Guessing a
conversion (C<'true'> to C<1>) would put a value in the schema nobody wrote. An
expression the schema author means -- C<\'$5.00'> -- is written as a SCALAR ref
and passes verbatim.

=item * On every other column (and with no C<$data_type>, which
L</sybase_column_type> reads as C<varchar>) the value is single-quoted, an
embedded C<'> doubled to C<''> -- the only escape a Transact-SQL string literal
has. C<'0'> on a character column is the string C<'0'>.

=back

C<$column_name> is used only in the refusal message.
L<DBIO::Sybase::Introspect::Columns> undoes exactly this rendering when it
reads the default back from C<syscomments>, so a literal round-trips unchanged.
Shared by the DDL emitter and the Diff table/column emitters so all of them
render defaults identically.
Exportable on request.

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::Sybase> - schema component

=item * L<DBIO::Sybase::Deploy> - uses this to generate DDL for deployment

=item * L<DBIO::Oracle::DDL> - sibling implementation

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
