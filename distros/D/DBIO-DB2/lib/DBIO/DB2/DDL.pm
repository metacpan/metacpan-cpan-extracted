package DBIO::DB2::DDL;
# ABSTRACT: Generate DB2 DDL from DBIO Result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp 'croak';

use DBIO::Exception;
use Scalar::Util ();

use DBIO::DB2::Type qw(_db2_column_type _db2_mapped_type);

use Exporter 'import';

our @EXPORT_OK = qw(
  _fk_constraint_clause _db2_quote_ident _db2_default_literal
  _db2_identity_clause _unique_constraint_clause _table_unique_constraints
  _refuse_nullable_unique _index_is_duplicate
  _db2_quote_table _split_table_name
);

# DB2-specific identifier quoter: ALWAYS quotes (unlike
# DBIO::SQL::Util::_quote_ident, which is the PostgreSQL-correct helper that
# leaves simple names bare -- correct there because unquoted folds to
# lowercase, wrong on DB2 where unquoted folds to UPPERCASE). The driver is a
# quote-everything driver (sql_quote_char '"', pinned in
# t/50-results-exist.t), so every name this driver emits -- tables, columns,
# indexes, FK targets, constraint names -- must be wrapped in double-quotes,
# otherwise the installed schema lives on as ARTIST while the SQLMaker queries
# "artist" -> SQL0204N (karr k28, followup to karr k26). Embedded `"` is
# escaped as `""` per the SQL standard.
sub _db2_quote_ident {
  my ($name) = @_;
  # undef (e.g. constraint_name from an incomplete FK hash) would silently
  # emit a warning-level empty "" -- croak early instead (karr k32).
  croak 'DBIO::DB2::DDL::_db2_quote_ident: undef identifier (caller: '
      . (caller(1) || '?') . ')' unless defined $name;
  $name =~ s/"/""/g;
  return qq{"$name"};
}

# A table name written "schema.table" (karr k57, maintainer decision) is the table
# in that schema, not one table with a dot in its name: split at the dot. Db2
# makes a schema that is missing when the first table of it is created (implicit
# schema creation). The compare deploy of the diff reads one schema and leaves a
# qualified table out (DBIO::DB2::Deploy::_split_qualify_ddl).
sub _split_table_name {
  my ($name) = @_;
  return $name =~ /\A([^."]+)\.([^."]+)\z/ ? ($1, $2) : (undef, $name);
}

sub _db2_quote_table {
  my ($schema, $table) = _split_table_name($_[0]);
  return defined $schema
    ? _db2_quote_ident($schema) . '.' . _db2_quote_ident($table)
    : _db2_quote_ident($table);
}

# Default-value renderer for install_ddl: turns the default_value of a RESULT
# CLASS -- a Perl value -- into the SQL text of a DEFAULT clause (karr k32).
# install_ddl used to write every non-ref default as an unescaped string
# literal: an apostrophe broke out of the quotes, a semicolon inside it cut the
# statement in two at the splitter, DEFAULT '13' on an INTEGER column was rejected with
# SQL0574N.
#
# It is NOT for the diff op classes, which called it too until karr k41. Their
# default_value comes out of SYSCAT.COLUMNS.DEFAULT and is the SQL text
# already -- 'new' with its quotes, 'it''s' with the apostrophe doubled -- so
# running it through here quoted it a second time: DEFAULT '''it''''s'''. The
# server took that, the column's default was then the text 'it''s' itself, and
# every later diff asked to set it again. DBIO::DB2::Diff::Table and
# DBIO::DB2::Diff::Column write the catalog text as it is. Rules:
#   * SCALAR ref  -> raw SQL expression (DBIC idiom \'CURRENT TIMESTAMP'),
#                    emitted bare -- the user opted out of literal rendering.
#   * the column's type is a character type (CHAR, VARCHAR, CLOB, GRAPHIC,
#     VARGRAPHIC, DBCLOB, LONG VARCHAR, ... and the aliases the type map
#     resolves to them, text, json) -> single-quoted string literal,
#     whatever the value looks like: '00000' on a CHAR(5) keeps its zeros,
#     'USER' and 'NULL' are text, not the register and not NULL (karr k46).
#   * numeric     -> bare literal (DEFAULT 13, not DEFAULT '13').
#   * NULL and the DB2 special registers (CURRENT DATE, CURRENT TIMESTAMP,
#     ...) -> bare function calls.
#   * everything else -> single-quoted string literal, embedded single-quotes
#     doubled ('').
sub _db2_default_literal {
  my ($value, $data_type) = @_;
  return $$value if ref $value eq 'SCALAR';
  return _db2_quote_string($value) if _db2_is_character_type($data_type);
  return $value if $value =~ /\A[+-]?\d+(?:\.\d+)?\z/;
  return $value if $value =~ /\A(?:NULL|CURRENT[\s_]+\w+|(?:SESSION|SYSTEM)_USER|USER)\z/i;
  return _db2_quote_string($value);
}

sub _db2_quote_string {
  my ($value) = @_;
  $value =~ s/'/''/g;
  return "'$value'";
}

# True when the data_type of a result class column is a character type, by the
# name _db2_column_type maps it to ('text' -> VARCHAR). No type (undef) is
# not a character type: the caller did not say.
sub _db2_is_character_type {
  my ($data_type) = @_;
  return 0 unless defined $data_type && length $data_type;
  my $mapped = uc _db2_mapped_type($data_type);
  $mapped =~ s/\s*\(.*\z//s;
  return $mapped =~ /\A(?:CHAR|CHARACTER|VARCHAR|CHAR VARYING|CHARACTER VARYING|LONG VARCHAR|CLOB|CHARACTER LARGE OBJECT|GRAPHIC|VARGRAPHIC|LONG VARGRAPHIC|DBCLOB|NCHAR|NVARCHAR|NCLOB)\z/ ? 1 : 0;
}

# The identity clause of an auto-increment column, in one place for the two
# producers of a CREATE TABLE: install_ddl and DBIO::DB2::Diff::Table. The
# second one left it out, so a table created by upgrade had a plain NOT NULL
# primary key and refused every insert that did not bring its own id
# (SQL0407N, karr k41).
sub _db2_identity_clause {
  return 'GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1)';
}




sub current_schema {
  my ($dbh) = @_;
  my ($current_schema) = $dbh->selectrow_array('VALUES CURRENT SCHEMA');
  $current_schema =~ s/\s+$// if defined $current_schema;
  return $current_schema;
}

# The CURRENT SCHEMA of a schema object's connection, undef where there is none (a
# class, a storage that cannot connect, a handle that gives no answer). A schema connected
# but not used yet connects here.
sub _connection_schema {
  my ($schema) = @_;
  return undef unless Scalar::Util::blessed($schema);
  my $name = eval {
    my $storage = $schema->storage;
    $storage ? current_schema($storage->dbh) : undef;
  };
  return (defined $name && length $name) ? $name : undef;
}


sub qualified_tables {
  my ($class, $schema) = @_;
  my @pairs;
  for my $moniker (sort $schema->sources) {
    my $source = $schema->source($moniker);
    next if $source->isa('DBIO::ResultSource::View');
    my $name = _resolve_table_name($source->name);
    next unless defined $name;
    my ($s) = _split_table_name($name);
    push @pairs, [ $name, $s ] if defined $s;
  }
  my %seen;
  return sort { $a->[0] cmp $b->[0] } grep { !$seen{ $_->[0] }++ } @pairs;
}

sub install_ddl {
  my ($class, $schema, $view_schema, $opt) = @_;
  $opt //= {};
  # The compare deploy of the diff reads one schema at a time (karr k57):
  # local_only leaves out the tables named schema.table, only_schema => S keeps
  # the tables of S, under their own names (no qualifier, the key targets in S
  # bare), and no view.
  $view_schema //= _connection_schema($schema);

  my @stmts;
  my %seen_table;
  my %view_def;

  for my $source_name (_topo_sort_sources($schema)) {
    my $source       = $schema->source($source_name);
    my $result_class = $source->result_class;
    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if defined $opt->{only_schema};
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = _resolve_table_name($source->name);
      next if !defined $vname || exists $view_def{$vname};
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      $view_def{$vname} = $def;
      next;
    }

    my $table_name   = _resolve_table_name($source->name);

    next unless defined $table_name;
    next if $seen_table{$table_name}++;
    my ($qualifier, $bare) = _split_table_name($table_name);
    next if $opt->{local_only} && defined $qualifier;
    if (defined $opt->{only_schema}) {
      next unless defined $qualifier && $qualifier eq $opt->{only_schema};
      $table_name = $bare;
    }

    my ($table_schema) = _split_table_name($table_name);
    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _db2_column_type($info, undef, "$table_name.$col_name");

      my $def = sprintf '  %s %s', _db2_quote_ident($col_name), $type;

      # Absent is_nullable means NOT NULL: core's canonical_column reads a
      # missing key as not_null => 1 (ADR 0043), so a bare `defined && !`
      # guard would deploy such columns as nullable.
      $def .= ' NOT NULL' if !$info->{is_nullable};

      if ($info->{is_auto_increment}) {
        # DB2 uses GENERATED ALWAYS AS IDENTITY for auto-increment
        $def .= ' ' . _db2_identity_clause();
      }
      elsif (defined $info->{default_value}) {
        $def .= ' DEFAULT ' . _db2_default_literal($info->{default_value}, $info->{data_type});
      }

      push @col_defs, $def;
    }

    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _db2_quote_ident($_) } @pk_cols);
    }

    # Named inline UNIQUE constraints of the source (karr k39, ADR 0009). Db2
    # makes an index of the same name behind each; the introspector reads the
    # pair as the constraint, so the diff neither drops nor doubles the index.
    for my $uc (_table_unique_constraints($source, $table_name)) {
      push @col_defs, '  ' . _unique_constraint_clause(@$uc);
    }

    # Named inline foreign keys derived from belongs_to relationships. DB2
    # enforces RI, so the install DDL must carry them; the deterministic name
    # (fk_<table>_<from_cols>) makes the constraint round-trip with a stable
    # identity for the name-based diff in DBIO::DB2::Diff::ForeignKey.
    for my $fk (_table_foreign_keys($schema, $source)) {
      if (defined $opt->{only_schema}) {
        my ($fq, $fbare) = _split_table_name($fk->{to_table});
        $fk = { %$fk, to_table => $fbare } if defined $fq && $fq eq $opt->{only_schema};
      }
      push @col_defs, '  ' . _fk_constraint_clause($fk);
    }

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);",
      _db2_quote_table($table_name), join(",\n", @col_defs);

    # Standalone indexes. Db2 does not create an index on a column sequence that
    # an index already covers (SQL0605W, state 42S11, no object made), so such an
    # entry is not written (karr k47, ADR 0010). What covers it, in the order the
    # server meets it: the primary key, the UNIQUE constraints, then the
    # indexes of this loop in name order.
    # Two sources of indexes: the db2_indexes hash written by hand, and the
    # canonical declarations of the result source (Cake idx, add_index_declaration;
    # ADR 0061 in core, karr k57). A canonical declaration of the same name wins.
    my %indexes;
    if ($result_class->can('db2_indexes')) {
      my $hand = $result_class->db2_indexes;
      $indexes{$_} = $hand->{$_} for keys %$hand;
    }
    # index_declarations_for refuses an entry that carries only another driver's
    # block, and an unknown key in the db2 block (this driver has none). What core
    # can express and Db2 cannot is refused here, never written as a plainer index.
    for my $decl ($source->index_declarations_for('db2', [])) {
      my $where = sprintf "DBIO::DB2::DDL: table '%s': index '%s' (%s) is refused",
        $table_name, $decl->{name}, join(', ', @{ $decl->{columns} // [] });
      DBIO::Exception->throw("$where: type '$decl->{type}' has no Db2 counterpart and is not written as a plainer index")
        if defined $decl->{type} && $decl->{type} !~ /\Aunique\z/i;
      DBIO::Exception->throw("$where: options are not supported by the Db2 DDL and are not dropped silently")
        if defined $decl->{options};
      $indexes{ $decl->{name} } = { columns => $decl->{columns}, unique => $decl->{unique} };
    }
    if (%indexes) {
      my @existing;
      push @existing, [ [ @pk_cols ], 1 ] if @pk_cols;
      push @existing, map { [ $_->[1], 1 ] }
        _table_unique_constraints($source, $table_name);
      for my $idx_name (sort keys %indexes) {
        my $idx = $indexes{$idx_name};
        my @cols = @{ $idx->{columns} // [] };
        next if _index_is_duplicate(\@cols, $idx->{unique}, \@existing);
        push @existing, [ \@cols, $idx->{unique} ? 1 : 0 ];
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';
        my $columns = join ', ', map { _db2_quote_ident($_) } @cols;
        my $sql = sprintf 'CREATE %sINDEX %s ON %s (%s)',
          $unique,
          (defined $table_schema ? _db2_quote_ident($table_schema) . '.' : '') . _db2_quote_ident($idx_name),
          _db2_quote_table($table_name), $columns;
        push @stmts, "$sql;";
      }
    }
  }

  # The views go in the order of what they read (karr k54), as the diff creates
  # them; a cycle throws before the script is returned.
  my @view_stmts = map { sprintf 'CREATE VIEW %s AS %s;', _db2_quote_ident($_), $view_def{$_} }
    order_views(\%view_def, $view_schema);

  return join "

", @stmts, @view_stmts;
}


my %CLAUSE_END = map { $_ => 1 } qw(
  SELECT WHERE GROUP HAVING ORDER FETCH LIMIT OFFSET UNION INTERSECT EXCEPT WINDOW FOR WITH OPTIMIZE
);

sub _view_tokens {
  my ($text) = @_;
  my @tok;
  pos($text) = 0;
  while (pos($text) < length $text) {
    if    ($text =~ /\G\s+/gc) { }
    elsif ($text =~ m{\G/\*.*?\*/}gcs) { }
    elsif ($text =~ /\G--[^\n]*/gc) { }
    elsif ($text =~ /\G"((?:[^"]|"")*)"/gc) {
      (my $n = $1) =~ s/""/"/g;
      push @tok, [ id => $n ];
    }
    elsif ($text =~ /\G'(?:[^']|'')*'/gcs) { push @tok, [ str => '' ] }
    elsif ($text =~ /\G([\w\$#@]+)/gc) { push @tok, [ word => $1 ] }
    elsif ($text =~ /\G([().,])/gc) { push @tok, [ p => $1 ] }
    elsif ($text =~ /\G./gcs) { push @tok, [ other => '' ] }
  }
  return @tok;
}

sub _tok_is_name { return $_[0] && ($_[0][0] eq 'id' || $_[0][0] eq 'word') }
sub _tok_is_p    { return $_[0] && $_[0][0] eq 'p' && $_[0][1] eq $_[1] }
sub _tok_name    { return $_[0][0] eq 'word' ? uc $_[0][1] : $_[0][1] }

# The header of one CTE, $i at its name: name, optional column list, AS, and the
# opening parenthesis of the body. Returns ($name, $index_of_that_parenthesis), or
# the empty list when it does not read that way.
sub _cte_header {
  my ($tok, $i) = @_;
  return unless _tok_is_name($tok->[$i]);
  my $name = _tok_name($tok->[$i++]);
  if (_tok_is_p($tok->[$i], '(')) {
    my $depth = 0;
    while ($i < @$tok) {
      my $x = $tok->[$i++];
      $depth++ if _tok_is_p($x, '(');
      last if _tok_is_p($x, ')') && !--$depth;
    }
  }
  return unless $tok->[$i] && $tok->[$i][0] eq 'word' && uc $tok->[$i][1] eq 'AS';
  return unless _tok_is_p($tok->[$i + 1], '(');
  return ($name, $i + 1);
}

# The reads of a definition as [ $qualifier_or_undef, $name ] pairs, in order of
# appearance, without repeats, the names of CTEs left out (see view_reads).
sub _view_reads_q {
  my ($def) = @_;
  return () unless defined $def && length $def;
  my @tok = _view_tokens($def);
  my (@reads, %seen);

  # One frame per pair of parentheses. expect: the next token stands where a
  # table is named; from: a comma does the same; select: this frame holds a
  # SELECT, so its FROM is a table list (a FROM inside TRIM(...) is not); cte: the
  # CTE names this frame's WITH clauses define; cte_body: the next parenthesis is
  # the body of a CTE; cte_pending: a CTE body has just closed, a comma may bring
  # the next one.
  my @frames = ({ expect => 0, from => 0, select => 1, cte => {} });
  my $is_cte = sub { my ($n) = @_; return scalar grep { $_->{cte}{$n} } @frames };
  my $i = 0;
  while ($i < @tok) {
    my ($type, $val) = @{ $tok[$i] };
    my $f = $frames[-1];
    delete $f->{cte_pending} if $f->{cte_pending} && !($type eq 'p' && $val eq ',');
    if ($type eq 'p' && $val eq '(') {
      push @frames, {
        expect => $f->{expect}, from => $f->{expect}, select => 0, cte => {},
        ($f->{cte_body} ? (cte_parent => $f) : ()),
      };
      delete $f->{cte_body};
      $f->{expect} = 0;
      $i++;
      next;
    }
    if ($type eq 'p' && $val eq ')') {
      if (@frames > 1) {
        my $done = pop @frames;
        $frames[-1]{cte_pending} = 1 if $done->{cte_parent};
      }
      $i++;
      next;
    }
    if ($type eq 'p' && $val eq ',') {
      if ($f->{cte_pending}) {
        delete $f->{cte_pending};
        my ($name, $open) = _cte_header(\@tok, $i + 1);
        DBIO::Exception->throw('DBIO::DB2::DDL: a comma after a WITH clause body is not followed by '
          . 'a readable common table expression (name, optional column list, AS, body); the view '
          . 'cannot be ordered by what it reads') unless defined $name;
        $f->{cte}{$name} = 1;
        $f->{cte_body} = 1;
        $i = $open;
        next;
      }
      $f->{expect} = $f->{from} ? 1 : 0;
      $i++;
      next;
    }
    if ($type eq 'word') {
      my $kw = uc $val;
      if ($kw eq 'WITH') {
        my $n = $i + 1;
        $n++ if $tok[$n] && $tok[$n][0] eq 'word' && uc $tok[$n][1] eq 'RECURSIVE';
        if (_tok_is_name($tok[$n]) && $tok[$n + 1]
            && (_tok_is_p($tok[$n + 1], '(') || ($tok[$n + 1][0] eq 'word' && uc $tok[$n + 1][1] eq 'AS'))) {
          my ($name, $open) = _cte_header(\@tok, $n);
          DBIO::Exception->throw(sprintf 'DBIO::DB2::DDL: the WITH clause names "%s" but is not a readable '
            . 'common table expression (name, optional column list, AS, body); the view cannot be '
            . 'ordered by what it reads', _tok_name($tok[$n])) unless defined $name;
          $f->{cte}{$name} = 1;
          $f->{cte_body} = 1;
          @$f{qw(from expect)} = (0, 0);
          $i = $open;
          next;
        }
      }
      if ($kw eq 'FROM' && $f->{select}) {
        my $prev = $i && $tok[$i - 1][0] eq 'word' ? uc $tok[$i - 1][1] : '';
        @$f{qw(from expect)} = (1, 1) unless $prev eq 'DISTINCT';
        $i++;
        next;
      }
      if ($kw eq 'JOIN' && $f->{from}) { $f->{expect} = 1; $i++; next }
      if ($CLAUSE_END{$kw}) {
        $f->{select} = 1 if $kw eq 'SELECT';
        @$f{qw(from expect)} = (0, 0);
        $i++;
        next;
      }
    }
    if ($f->{expect} && ($type eq 'id' || $type eq 'word')) {
      # a (possibly qualified) name; the last part is the table, the one before it
      # the schema
      my @part = (_tok_name($tok[$i]));
      $i++;
      while ($i + 1 < @tok && _tok_is_p($tok[$i], '.') && _tok_is_name($tok[$i + 1])) {
        push @part, _tok_name($tok[$i + 1]);
        $i += 2;
      }
      my $name = pop @part;
      my $qual = @part ? $part[-1] : undef;
      my $call = $i < @tok && _tok_is_p($tok[$i], '(');
      unless ($call || (!defined $qual && $is_cte->($name)) || $seen{ ($qual // '') . "\0" . $name }++) {
        push @reads, [ $qual, $name ];
      }
      $f->{expect} = 0;
      next;
    }
    $f->{expect} = 0;
    $i++;
  }
  return @reads;
}

sub view_reads {
  my ($def, $schema) = @_;
  my (@names, %seen);
  for my $r (_view_reads_q($def)) {
    my ($qual, $name) = @$r;
    next if defined $schema && defined $qual && $qual ne $schema;
    push @names, $name unless $seen{$name}++;
  }
  return @names;
}


sub view_dependencies {
  my ($set, $name, $def, $schema) = @_;
  my %in = map { $_ => 1 } @$set;
  my %by_fold;
  push @{ $by_fold{ lc $_ } }, $_ for @$set;

  my %dep;
  for my $r (_view_reads_q($def)) {
    my ($qual, $read) = @$r;
    my $to = $in{$read} ? $read
           : (@{ $by_fold{ lc $read } // [] } == 1 ? $by_fold{ lc $read }[0] : undef);
    if (defined $qual) {
      if (defined $schema) {
        next unless $qual eq $schema;
      }
      else {
        DBIO::Exception->throw(sprintf
          'DBIO::DB2::DDL: the view %s reads %s.%s, and %s is a view of the same set; without the '
          . 'schema the views are created in (not known here) it cannot be decided whether that is '
          . 'this view or one of another schema, so no order is given. Write the read without the '
          . 'qualifier, or give the schema',
          _db2_quote_ident($name), _db2_quote_ident($qual), _db2_quote_ident($read), _db2_quote_ident($to))
          if defined $to && $to ne $name;
        next;
      }
    }
    $dep{$to} = 1 if defined $to && $to ne $name;
  }
  return sort keys %dep;
}


sub order_views {
  my ($defs, $schema) = @_;
  my @names = sort keys %$defs;

  my %reads;
  for my $v (@names) {
    $reads{$v} = [ view_dependencies(\@names, $v, $defs->{$v}, $schema) ];
  }

  my (%out, @order);
  my @todo = @names;
  while (@todo) {
    my ($pick) = grep { my $v = $_; !grep { !$out{$_} } @{ $reads{$v} } } @todo;
    unless (defined $pick) {
      my @cycle = grep {
        my $v = $_;
        my (%seen, @walk);
        @walk = @{ $reads{$v} };
        my $found;
        while (defined(my $n = shift @walk)) {
          if ($n eq $v) { $found = 1; last }
          next if $seen{$n}++;
          push @walk, @{ $reads{$n} };
        }
        $found;
      } @todo;
      DBIO::Exception->throw(sprintf
        'DBIO::DB2::DDL: the views %s read each other in a cycle (%s), no order creates them',
        join(', ', map { _db2_quote_ident($_) } @cycle),
        join('; ', map { my $v = $_; sprintf '%s reads %s', _db2_quote_ident($v),
          join(', ', map { _db2_quote_ident($_) } grep { my $r = $_; grep { $_ eq $r } @cycle } @{ $reads{$v} }) } @cycle));
    }
    @todo = grep { $_ ne $pick } @todo;
    $out{$pick} = 1;
    push @order, $pick;
  }
  return @order;
}

# True when Db2 would answer CREATE [UNIQUE] INDEX over @$columns with SQL0605W
# instead of making the index: an index of the same columns in the same order is
# already there ($existing = [ [ \@columns, $is_unique ], ... ] -- primary key,
# UNIQUE constraints and indexes alike). Measured live (Db2 12.1.5): a
# non-unique index is a duplicate of any such index, a UNIQUE one only of a
# unique one -- CREATE UNIQUE INDEX over the columns of a non-unique index is
# made, beside it. A different order or a longer/shorter sequence is no duplicate.
sub _index_is_duplicate {
  my ($columns, $unique, $existing) = @_;
  return 0 unless @{ $columns || [] };
  my $key = join "\0", @$columns;
  for my $e (@{ $existing || [] }) {
    next unless join("\0", @{ $e->[0] }) eq $key;
    return 1 if $e->[1] || !$unique;
  }
  return 0;
}

# The unique constraints of a source as [ $name, \@columns ] pairs in name
# order, 'primary' (set_primary_key's, already PRIMARY KEY) left out. Db2 refuses
# a UNIQUE constraint over a nullable column (SQL0542N), so one is refused here
# with table and column named, before any statement runs. A column without
# is_nullable is NOT NULL (ADR 0043), as in the column loop of install_ddl.
sub _table_unique_constraints {
  my ($source, $table_name) = @_;
  return unless $source->can('unique_constraints');
  my %uniques = $source->unique_constraints;
  my @out;
  for my $name (sort keys %uniques) {
    next if $name eq 'primary';
    my @cols = @{ $uniques{$name} };
    _refuse_nullable_unique($table_name, $name,
      [ grep { $source->column_info($_)->{is_nullable} } @cols ]);
    push @out, [ $name, \@cols ];
  }
  return @out;
}

# Croaks naming table, constraint and the nullable columns, when there are any.
sub _refuse_nullable_unique {
  my ($table, $name, $nullable) = @_;
  return unless @$nullable;
  croak sprintf
    'DBIO::DB2::DDL: UNIQUE constraint "%s" on table "%s" includes nullable column%s %s; '
    . 'Db2 refuses it (SQL0542N). Declare the column NOT NULL (leave is_nullable out), '
    . 'or use a unique db2_indexes entry instead',
    $name, $table, (@$nullable > 1 ? 's' : ''),
    join(', ', map { qq{"$_"} } @$nullable);
}

# CONSTRAINT <name> UNIQUE (<cols>) -- the one clause shape, for install_ddl and
# DBIO::DB2::Diff::Table (inline, indented there) and
# DBIO::DB2::Diff::UniqueConstraint (ALTER TABLE ... ADD <clause>).
sub _unique_constraint_clause {
  my ($name, $columns) = @_;
  return sprintf 'CONSTRAINT %s UNIQUE (%s)', _db2_quote_ident($name),
    join(', ', map { _db2_quote_ident($_) } @$columns);
}

sub _resolve_table_name {
  my ($name) = @_;
  return $name unless ref $name;
  return undef unless ref $name eq 'SCALAR';
  my $v = $$name;
  return undef unless defined $v;
  return $v if $v =~ /\A\w+\z/;
  return undef;
}

# Deterministic constraint name for an FK, derived from the owning table and
# its local columns: fk_<table>_<col1>_<col2>. Stable across the live DB and
# the throwaway compare schema (both built from this same DDL), which is what
# makes the name-based FK diff sound (ADR 0005).
sub _fk_constraint_name {
  my ($table, $from_cols) = @_;
  return join '_', 'fk', $table, @$from_cols;
}

# Single source of truth for the inline foreign-key clause shape (ADR 0005):
#   CONSTRAINT <name> FOREIGN KEY (<from>) REFERENCES <to>(<to_cols>)
#   [ON DELETE <rule>] [ON UPDATE <rule>]
# Returned WITHOUT leading indent and WITHOUT an ALTER TABLE ... ADD prefix, so
# install_ddl (inline, indented), DBIO::DB2::Diff::Table (inline, indented) and
# DBIO::DB2::Diff::ForeignKey (ALTER TABLE ... ADD <clause>) all render the same
# body. NO ACTION rules are suppressed (DB2's implicit default). The name comes
# straight from the model -- callers must NOT regenerate it.
sub _fk_constraint_clause {
  my ($fk) = @_;
  my $sql = sprintf 'CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)',
    _db2_quote_ident($fk->{constraint_name}),
    join(', ', map { _db2_quote_ident($_) } @{ $fk->{from_columns} }),
    _db2_quote_table($fk->{to_table}),
    join(', ', map { _db2_quote_ident($_) } @{ $fk->{to_columns} });
  $sql .= " ON DELETE $fk->{on_delete}"
    if $fk->{on_delete} && $fk->{on_delete} ne 'NO ACTION';
  $sql .= " ON UPDATE $fk->{on_update}"
    if $fk->{on_update} && $fk->{on_update} ne 'NO ACTION';
  return $sql;
}

# Collect the named foreign keys for one source, derived from its belongs_to
# relationships. Mirrors the column extraction in DBIO::MySQL::DDL: a FK cond
# is { "foreign.<refcol>" => "self.<localcol>" }.
sub _table_foreign_keys {
  my ($schema, $source) = @_;

  my $table_name = _resolve_table_name($source->name);
  my @fks;
  my %seen_name;

  for my $rel ($source->relationships) {
    my $info = $source->relationship_info($rel);
    next unless $info && $info->{attrs}
             && $info->{attrs}{is_foreign_key_constraint};

    my $foreign = $info->{class};
    my $fs = eval { $schema->source($foreign) }
          // eval { $schema->source($foreign =~ s/.*:://r) };
    next unless $fs;

    my $cond = $info->{cond};
    next unless ref $cond eq 'HASH';

    my (@from, @to);
    for my $foreign_col (sort keys %$cond) {
      my $fcol = $foreign_col;
      $fcol =~ s/^foreign\.//;
      my $self_col = $cond->{$foreign_col};
      $self_col =~ s/^self\.//;
      push @to,   $fcol;
      push @from, $self_col;
    }
    next unless @from;

    my $foreign_name = _resolve_table_name($fs->name);
    next unless defined $foreign_name;

    # The deterministic name keys on the local columns, so two relationships
    # over the same column(s) would collide (DB2 rejects a duplicate constraint
    # name, and the name-based diff needs one identity per name). Keep the
    # first; a single FK per column-set is the normal case and is untouched.
    my $name = _fk_constraint_name((_split_table_name($table_name))[1], \@from);
    next if $seen_name{$name}++;

    my $attrs = $info->{attrs} || {};
    push @fks, {
      constraint_name => $name,
      from_columns    => \@from,
      to_table        => $foreign_name,
      to_columns      => \@to,
      on_delete       => $attrs->{on_delete},
      on_update       => $attrs->{on_update},
    };
  }

  return @fks;
}

sub _topo_sort_sources {
  my ($schema) = @_;

  my %deps;
  my %by_table;
  my @sources = sort $schema->sources;

  for my $name (@sources) {
    my $s = $schema->source($name);
    my $t = _resolve_table_name($s->name);
    next unless defined $t;
    $by_table{$t} //= $name;
  }

  for my $name (@sources) {
    my $s = $schema->source($name);
    next unless defined _resolve_table_name($s->name);
    $deps{$name} ||= {};
    for my $rel ($s->relationships) {
      my $info = $s->relationship_info($rel);
      next unless $info && $info->{attrs}
               && $info->{attrs}{is_foreign_key_constraint};
      my $foreign = $info->{class};
      my $fs = eval { $schema->source($foreign) }
            // eval { $schema->source($foreign =~ s/.*:://r) };
      next unless $fs;
      my $ft = _resolve_table_name($fs->name);
      next unless defined $ft;
      my $owner = $by_table{$ft};
      next unless $owner;
      next if $owner eq $name;
      $deps{$name}{$owner} = 1;
    }
  }

  my @out;
  my %visited;
  my $visit;
  $visit = sub {
    my ($n) = @_;
    return if $visited{$n}++;
    for my $d (sort keys %{ $deps{$n} || {} }) {
      $visit->($d);
    }
    push @out, $n;
  };
  $visit->($_) for @sources;
  return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::DDL - Generate DB2 DDL from DBIO Result classes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::DB2::DDL> generates a DB2 DDL script from a L<DBIO::Schema>
class hierarchy. It is the desired-state side of the test-deploy-and-
compare strategy used by L<DBIO::DB2::Deploy>.

    my $ddl = DBIO::DB2::DDL->install_ddl($schema_class_or_instance);

The output is plain SQL, suitable for executing one statement at a time
against a fresh DB2 database. Emits C<CREATE TABLE> (inline columns,
primary key, named C<UNIQUE> and named C<FOREIGN KEY> constraints) and
C<CREATE INDEX>.

The C<unique_constraints> of a source are emitted as
C<CONSTRAINT "name" UNIQUE ("col", ...)> inside C<CREATE TABLE>, under the
name the source gives them (ADR 0009). A constraint over a nullable column is
refused with a C<croak> naming table and column: Db2 answers it with SQL0542N.

Foreign keys are emitted as B<named> inline constraints
(C<CONSTRAINT fk_E<lt>tableE<gt>_E<lt>colsE<gt> FOREIGN KEY ...>) with a
deterministic name derived from the relationship. DB2 enforces referential
integrity, so the install DDL must carry the FKs; the deterministic name
gives the live database and the throwaway compare schema the same stable
constraint identity, which is what makes the name-based FK diff in
L<DBIO::DB2::Diff::ForeignKey> sound (see ADR 0005). New-table FKs are also
rendered inline by L<DBIO::DB2::Diff::Table> on the diff path.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::DB2::DDL->install_ddl($schema);

Returns the full installation DDL as a single string.

An optional second argument names the schema the views are created in, as the catalog
holds it (C<DB2INST1>). L<DBIO::DB2::Deploy> passes the connection's C<CURRENT SCHEMA>.
Without it the schema is the C<CURRENT SCHEMA> of the connection of C<$schema> (a schema
object, whose storage connects if it has not yet; L</current_schema>), the install's target schema. A view
that reads a view of the set through a qualifier equal to it (C<DB2INST1.v>) reads that
view, as it would unqualified; through another qualifier it reads a view of another schema
and depends on nothing. Where the schema is not known (a class, no connection, no answer)
such a qualified read of a view of the set is refused: the order cannot be decided
(L</order_views>).

=head2 current_schema

    my $schema_name = DBIO::DB2::DDL::current_schema($dbh);

The C<CURRENT SCHEMA> of the handle, right-trimmed (the register is C<CHAR(128)>,
space-padded; the catalog holds names unpadded). The one place that reads it:
L<DBIO::DB2::Deploy> and L</install_ddl> both ask here.

=head2 qualified_tables

    my @pairs = DBIO::DB2::DDL->qualified_tables($schema);   # [ 'other.t', 'other' ], ...

The tables of the schema named C<schema.table> (not the views), with their
schema, sorted by name. L<DBIO::DB2::Deploy> reads these schemas, the
declared tables of them only, besides the current one.

=head2 view_reads

    my @names = DBIO::DB2::DDL::view_reads($view_definition);
    my @names = DBIO::DB2::DDL::view_reads($view_definition, $schema);

The names a view definition reads as a table or view: every name that stands
where a C<FROM> or a C<JOIN> (or a comma in a C<FROM> list) expects a table,
in a subquery, a derived table or a join group as much as at the top, in order
of appearance, without repeats.

A name is returned as the catalog holds it: a quoted name (C<"x">) as written,
an unquoted one upper-case, which is what Db2 folds it to. The text is split
into names, words, strings and comments first, so a name inside a string
literal or a comment reads nothing; a quoted identifier is never a keyword; a
name followed by C<(> is a call (C<TABLE(f(1))>), not a table; the C<FROM> of
C<TRIM>, C<EXTRACT> and C<SUBSTRING> and of C<IS DISTINCT FROM> opens no table
list. It reads text, not the server, because L</install_ddl> has no database to
ask, and it is the one detection for the install and the diff.

B<Common table expressions>. The names a C<WITH> clause defines
(C<WITH a AS (...), b (x, y) AS (...) SELECT ...>) are not read as views: a
C<FROM a> that means such a name is no dependency, whether or not a view C<a>
exists. A name is a CTE from its own definition on (so a recursive one reads
itself as the CTE), in the select the C<WITH> belongs to and in everything nested
in it; a body that reads a name defined only after it, or a qualified name, reads a
table or view. The reads inside the bodies count as any other. C<WITH UR> and
C<WITH CHECK OPTION> are no CTE. A C<WITH> that starts like a CTE but is not
one that can be read (a missing C<AS>, a missing body) throws a
L<DBIO::Exception>: the order it would give cannot be trusted.

B<A schema qualifier> (C<s.name>). Without C<$schema> every read is returned by its
name, the qualifier dropped: the list is then what the definition may depend on, and
it is L</order_views> that refuses what it cannot decide (below). With C<$schema>, the
name of the schema the views are created in as the catalog holds it (C<DB2INST1>), a
read qualified with another schema is not returned: it is no view of this set. A
qualifier equal to C<$schema> counts as no qualifier. The qualifier is compared as the
catalog holds it, like the names: an unquoted one upper-case, a quoted one as written.

Still not recognised, so that the server may refuse the statement: a view read
through a synonym or an alias, a view named in a dynamic way.

=head2 view_dependencies

    my @names = DBIO::DB2::DDL::view_dependencies(\@set, $name, $definition, $schema);

The views of C<@set> (names) the view C<$name> with C<$definition> reads, sorted, never
the view itself: what L</view_reads> returns, matched against the set (a name as
written, else without regard to case when exactly one view of the set has that name
that way -- an unquoted read is the upper-case name, the views of this driver are
written in quotes). It is the one decision shared by L</order_views> and by
L<DBIO::DB2::Diff::View>.

A read qualified with a schema is a dependency when C<$schema> is given and the
qualifier is that schema, and none when it is another schema (the view of
another schema is not one of the set). Without C<$schema> the qualifier cannot be
judged: if the name of such a read is a view of the set it throws a
L<DBIO::Exception> naming the view and the read, before any statement has been
written, because dropping the qualifier would order by a view that may be another one,
and keeping it may leave out a real dependency. A qualified read of a name that is no
view of the set is no dependency either way.

=head2 order_views

    my @names = DBIO::DB2::DDL::order_views(\%definitions);
    my @names = DBIO::DB2::DDL::order_views(\%definitions, $schema);

The order in which a set of views is created, shared by the install
(L</install_ddl>) and by the diff (L<DBIO::DB2::Diff::View>).
C<%definitions> maps a view name to its definition (SQL text, or undef for a
view that reads nothing). A view goes after the views of the set it reads
(L</view_dependencies>); of the views free to go the first by name is next, so views
free of each other stay in name order. A read of the view itself, of a name
that is no view of the set, of a CTE of that name (L</view_reads>) or of a view of another
schema is no dependency. The drop order is this one reversed: a view goes before the
views it reads.

C<$schema> is the schema the views are created in (see L</view_dependencies>). The
install does not know it and the diff takes it from the live model; without it, a
qualified read of a name that is a view of the set is refused with a
L<DBIO::Exception> instead of being guessed at (ADR 0011 addendum).

When the views read each other in a cycle no order creates them, and the call
throws a L<DBIO::Exception> naming the views on the cycle, before any statement
has been written.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
