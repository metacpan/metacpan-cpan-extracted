package DBIO::MSSQL::DDL;
# ABSTRACT: Generate MSSQL DDL from DBIO Result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';
our @EXPORT_OK = qw(_mssql_column_type _quote_ident _quote_table _bare_table _schema_prefix _schemas_of _check_table_name _constraint_name _check_cascade_paths _check_constraint_names);

use Digest::SHA ();

use DBIO::Exception ();
use DBIO::Schema::Type ();
use DBIO::MSSQL::Adapter ();

my $ADAPTER = DBIO::MSSQL::Adapter->new;

# The reserved keywords of Transact-SQL (Microsoft's list). A name on it is
# bracketed, and so is a name that is not of the plain form. A capital needs
# no bracket: SQL Server keeps the case of a bare name exactly as written.
my %RESERVED = map { $_ => 1 } qw(
  ADD ALL ALTER AND ANY AS ASC AUTHORIZATION BACKUP BEGIN BETWEEN BREAK
  BROWSE BULK BY CASCADE CASE CHECK CHECKPOINT CLOSE CLUSTERED COALESCE
  COLLATE COLUMN COMMIT COMPUTE CONSTRAINT CONTAINS CONTAINSTABLE
  CONTINUE CONVERT CREATE CROSS CURRENT CURRENT_DATE CURRENT_TIME
  CURRENT_TIMESTAMP CURRENT_USER CURSOR DATABASE DBCC DEALLOCATE DECLARE
  DEFAULT DELETE DENY DESC DISK DISTINCT DISTRIBUTED DOUBLE DROP DUMP
  ELSE END ERRLVL ESCAPE EXCEPT EXEC EXECUTE EXISTS EXIT EXTERNAL FETCH
  FILE FILLFACTOR FOR FOREIGN FREETEXT FREETEXTTABLE FROM FULL FUNCTION
  GOTO GRANT GROUP HAVING HOLDLOCK IDENTITY IDENTITY_INSERT IDENTITYCOL
  IF IN INDEX INNER INSERT INTERSECT INTO IS JOIN KEY KILL LEFT LIKE
  LINENO LOAD MERGE NATIONAL NOCHECK NONCLUSTERED NOT NULL NULLIF OF OFF
  OFFSETS ON OPEN OPENDATASOURCE OPENQUERY OPENROWSET OPENXML OPTION OR
  ORDER OUTER OVER PERCENT PIVOT PLAN PRECISION PRIMARY PRINT PROC
  PROCEDURE PUBLIC RAISERROR READ READTEXT RECONFIGURE REFERENCES
  REPLICATION RESTORE RESTRICT RETURN REVERT REVOKE RIGHT ROLLBACK
  ROWCOUNT ROWGUIDCOL RULE SAVE SCHEMA SECURITYAUDIT SELECT
  SEMANTICKEYPHRASETABLE SEMANTICSIMILARITYDETAILSTABLE
  SEMANTICSIMILARITYTABLE SESSION_USER SET SETUSER SHUTDOWN SOME
  STATISTICS SYSTEM_USER TABLE TABLESAMPLE TEXTSIZE THEN TO TOP TRAN
  TRANSACTION TRIGGER TRUNCATE TRY_CONVERT TSEQUAL UNION UNIQUE UNPIVOT
  UPDATE UPDATETEXT USE USER VALUES VARYING VIEW WAITFOR WHEN WHERE WHILE
  WITH WITHIN WRITETEXT
);

# The one way a name is written, in the DDL and in the diff ops: bare when it
# is a plain identifier that is no reserved word, else in brackets
# with a closing bracket doubled. A dot is part of the name.
sub _quote_ident {
  my ($name) = @_;
  return $name if $name =~ /\A[a-z_][a-z0-9_]*\z/i && !$RESERVED{ uc $name };
  (my $q = $name) =~ s/\]/]]/g;
  return "[$q]";
}

# A table or view name is "table" (in dbo) or "schema.table" (karr k72): both
# parts are quoted on their own, so [my schema].t is the table t of the schema
# "my schema", never the table "my schema.t" of dbo. The model keys of
# DBIO::MSSQL::Introspect are written the same way (a table of dbo bare).
sub _quote_table {
  my ($name) = @_;
  return _quote_ident($name) unless $name =~ /\./;
  my ($schema, $table) = split /\./, $name, 2;
  return _quote_ident($schema) . '.' . _quote_ident($table);
}

# The table of a "schema.table" name; a bare name is itself. Constraint names
# are made from it: they live in the schema of their table.
sub _bare_table {
  my ($name) = @_;
  return $name =~ s/\A[^.]*\.//r;
}

# "schema." for a "schema.table" name, '' for a table of dbo: the prefix of a
# name in the namespace of that schema (constraints and objects share one).
sub _schema_prefix {
  my ($name) = @_;
  return $name =~ /\A([^.]*\.)/ ? $1 : '';
}

# The name a source gives its table or view, as the driver writes it. A name
# with a dot means schema.table in SQL Server and is made in that schema
# (karr k72); dbo.t is the table t of dbo, written bare, as the introspect
# keys it. A name with another number of dots (a database-qualified one) or an
# empty part is refused: the driver cannot create a table in another database.
sub _check_table_name {
  my ($name, $kind) = @_;
  return $name unless defined $name && !ref $name && $name =~ /\./;
  $kind //= 'table';
  my @part = split /\./, $name, -1;
  DBIO::Exception->throw("DBIO::MSSQL: $kind '$name' is refused: a name with a "
    . "dot means schema.table in SQL Server, with exactly one dot and a name on "
    . "both sides (a name qualified with a database cannot be created from "
    . "here)")
    unless @part == 2 && length $part[0] && length $part[1];
  return lc $part[0] eq 'dbo' ? $part[1] : $name;
}

# The schemas other than dbo that the tables and views of a schema class name
# (virtual views and inline SQL are no objects of the server), sorted. What
# the introspect has to read besides dbo, and what install_ddl creates.
sub _schemas_of {
  my ($schema) = @_;
  my %seen;
  for my $source_name ($schema->sources) {
    my $source = $schema->source($source_name);
    next if _is_virtual_view($source);
    my $name = _resolve_table_name($source->name, _is_view($source) ? 'view' : 'table');
    next unless defined $name && $name =~ /\A([^.]+)\./;
    $seen{$1} = 1;
  }
  return sort keys %seen;
}

sub _is_view { $_[0]->isa('DBIO::ResultSource::View') }

# A virtual view is a subquery in the FROM clause, no object of the server:
# nothing is deployed for it and its name is nobody's business.
sub _is_virtual_view {
  my ($s) = @_;
  return _is_view($s) && $s->can('is_virtual') && $s->is_virtual ? 1 : 0;
}

# SQL Server keeps constraint names and object names (tables, views) in one
# namespace per schema: a constraint called like a table fails with Msg 2714,
# also when the name was chosen on purpose. Found before the server is asked
# (karr k71). $objects: { name => 1 } of the tables and views that are
# created; $constraints: [ { table, name, kind, label, columns } ], the label
# naming the declaration ("unique constraint", "relationship 'x'"). $objects is
# keyed by the names as the model keys them (schema.table, a table of dbo
# bare) and a constraint is judged against the objects of the schema of its
# table. The names are compared as written (a case insensitive collation would also see
# 'Artist' and 'artist' as one name).
sub _check_constraint_names {
  my ($objects, $constraints) = @_;
  for my $c (@$constraints) {
    # the namespace is the schema's: the object of the same schema
    next unless $objects->{ _schema_prefix($c->{table}) . $c->{name} };
    DBIO::Exception->throw(sprintf
      "DBIO::MSSQL: table '%s': %s '%s' (%s) is refused: the name is also the "
      . "name of a table or view of this deploy, and SQL Server keeps constraint "
      . "and object names in one namespace (Msg 2714). Name the constraint "
      . "differently",
      $c->{table}, $c->{label}, $c->{name}, join(', ', @{ $c->{columns} }));
  }
  return;
}

# The most characters of an identifier in SQL Server.
my $MAX_NAME = 128;

# The name of a constraint this driver makes up: PREFIX_table_col1_col2. One
# function for install_ddl and everything else that names one, so install and
# diff agree. A name over 128 characters is cut and ends in 8 hex digits of the
# SHA-1 of the full name, so two long names that start alike stay apart.
sub _constraint_name {
  my ($prefix, $table, @cols) = @_;
  # named after the bare table: the constraint lives in the schema of the table
  my $name = join '_', $prefix, _bare_table($table), @cols;
  return $name if length $name <= $MAX_NAME;
  my $hash = substr Digest::SHA::sha1_hex($name), 0, 8;
  return substr($name, 0, $MAX_NAME - 9) . "_$hash";
}


# The char-family types whose Transact-SQL grammar has the unbounded form:
# varchar [ ( n | max ) ], nvarchar [ ( n | max ) ], varbinary [ ( n | max ) ].
# The fixed-length char [ ( n ) ], nchar [ ( n ) ] and binary [ ( n ) ] have no
# (max), which is why _mssql_column_type cannot honour a -1 on them (karr k28).
my %MAX_LENGTH_TYPE = map { $_ => 1 } qw(varchar nvarchar varbinary);

# SQL standard spellings (normalised, see _normalize_type) and the SQL Server
# type each one is a synonym of.
my %TYPE_ALIAS = (
  'character'                  => 'char',
  'char varying'               => 'varchar',
  'character varying'          => 'varchar',
  'national char'              => 'nchar',
  'national character'         => 'nchar',
  'nchar varying'              => 'nvarchar',
  'national char varying'      => 'nvarchar',
  'national character varying' => 'nvarchar',
  'binary varying'             => 'varbinary',
);

# Lower case, blanks folded to one, "(n)" or "(p,s)" taken off: the type name
# and the parameter apart.
sub _normalize_type {
  my ($type) = @_;
  my $n = lc $type;
  $n =~ s/\A\s+|\s+\z//g;
  $n =~ s/\s+/ /g;
  my $param;
  $param = $1 if $n =~ s/\s*\(\s*([^)]*?)\s*\)\z//;
  return ($n, $param);
}



sub install_ddl {
  my ($class, $schema) = @_;

  my @stmts;
  my %seen_table;
  my @view_stmts;
  my %seen_view;
  my %seen_constraint;
  my @constraints;
  my %schemas;

  for my $source_name (_topo_sort_sources($schema)) {
    my $source       = $schema->source($source_name);
    my $result_class = $source->result_class;
    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = _resolve_table_name($source->name, 'view');
      next if !defined $vname || $seen_view{$vname}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      $schemas{$1} = 1 if $vname =~ /\A([^.]+)\./;
      push @view_stmts, [ $vname, $def ];
      next;
    }

    my $table_name   = _resolve_table_name($source->name);

    # Virtual / view source whose name is inline SQL: skip here.
    next unless defined $table_name;

    # Multiple Result classes may share one physical table.
    next if $seen_table{$table_name}++;
    $schemas{$1} = 1 if $table_name =~ /\A([^.]+)\./;

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _mssql_column_type($info, $table_name, $col_name);

      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;

      $def .= ' NOT NULL' if !$info->{is_nullable};

      if ($info->{is_auto_increment}) {
        $def .= ' IDENTITY(1,1)';
      } elsif (defined $info->{default_value}) {
        $def .= ' DEFAULT ' . _default_literal($info->{default_value}, $type, $table_name, $col_name);
      }

      push @col_defs, $def;
    }

    if (@pk_cols) {
      # Named: unnamed, the server gives the key a random name
      # (PK__table__<hash>) in every database, and the diff has nothing to
      # address a key it adds by. The same name, PK_<table>, is what
      # DBIO::MSSQL::Diff writes (karr k74).
      my $pk_name = _constraint_name('PK', $table_name);
      push @constraints, { table => $table_name, name => $pk_name,
        label => 'primary key', columns => \@pk_cols };
      push @col_defs, sprintf '  CONSTRAINT %s PRIMARY KEY (%s)',
        _quote_ident($pk_name),
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    # The columns that are unique already: the primary key and every unique
    # constraint. A plain index over exactly these columns is a second one for
    # the lookups the server's own index serves (see "Indexes").
    my %covered;
    $covered{ join "\0", @pk_cols } = 1 if @pk_cols;

    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        # Named: unnamed, the server gives the constraint a random name
        # (UQ__table__<hash>) in every database it is installed into, and the
        # diff of two databases then sees two different indexes. The name is
        # the declared one (core names an undeclared one <table>_<columns>).
        # The name core makes up for an undeclared one, <table>_<columns>, is
        # an object name that a table can have as well (the table user and
        # unique(email) against a table user_email): it gets its own prefix,
        # as the foreign keys have theirs. A name the declaration chose stays.
        my $cname = $uname eq $source->name_unique_constraint($cols)
          ? _constraint_name('UQ', $table_name, @$cols)
          : $uname;
        my $ckey = _schema_prefix($table_name) . $cname;
        DBIO::Exception->throw(sprintf
          "DBIO::MSSQL: table '%s': unique constraint '%s' (%s) is refused: it "
          . "has the name of one on another table, and SQL Server holds "
          . "constraint names once per schema",
          $table_name, $cname, join(', ', @$cols))
          if $seen_constraint{$ckey} && $seen_constraint{$ckey} ne $table_name;
        $seen_constraint{$ckey} = $table_name;
        push @constraints, { table => $table_name, name => $cname,
          label => 'unique constraint', columns => $cols };
        $covered{ join "\0", @$cols } = 1;
        push @col_defs, sprintf '  CONSTRAINT %s UNIQUE (%s)',
          _quote_ident($cname),
          join(', ', map { _quote_ident($_) } @$cols);
      }
    }

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);",
      _quote_table($table_name), join(",\n", @col_defs);

    # Standalone indexes: the ones written by hand with mssql_indexes, and
    # the canonical declarations of the result source (Cake idx, indices;
    # ADR 0061 in core, karr k66). A canonical declaration of the same name
    # wins over the hand-written one.
    my %indexes;
    if ($result_class->can('mssql_indexes')) {
      my $hand = $result_class->mssql_indexes;
      $indexes{$_} = $hand->{$_} for keys %$hand;
    }
    # The helper refuses an entry that carries only another driver's block
    # and an unknown key in the own block (core k333); its message is passed
    # through. An empty own block is the plain index.
    for my $decl ($source->index_declarations_for('mssql', ['kind', 'where'])) {
      # type (other than unique) and options have no counterpart here and
      # are refused, never written as a plainer index (ADR 0061).
      if (defined $decl->{type} && $decl->{type} !~ /^unique$/i) {
        DBIO::Exception->throw(sprintf
          "DBIO::MSSQL: table '%s': index '%s' (%s) is refused: type '%s' has "
          . "no SQL Server counterpart and is not written as a plainer index",
          $table_name, $decl->{name}, join(', ', @{ $decl->{columns} // [] }),
          $decl->{type});
      }
      if (defined $decl->{options}) {
        DBIO::Exception->throw(sprintf
          "DBIO::MSSQL: table '%s': index '%s' (%s) is refused: options are "
          . "not supported by the SQL Server DDL and are not dropped silently",
          $table_name, $decl->{name}, join(', ', @{ $decl->{columns} // [] }));
      }
      my $own = ($decl->{driver} || {})->{mssql} || {};
      $indexes{ $decl->{name} } = {
        columns => $decl->{columns},
        unique  => $decl->{unique},
        kind    => $own->{kind},
        (exists $own->{where} ? (where => $own->{where}) : ()),
      };
    }
    {
      my $has_clustered = 0;
      for my $idx_name (sort keys %indexes) {
        my $idx = $indexes{$idx_name};
        my $kind = $idx->{kind} // '';
        DBIO::Exception->throw(sprintf
          "DBIO::MSSQL: table '%s': index '%s' (%s) is refused: invalid kind "
          . "'%s' -- expected 'clustered' or 'nonclustered'",
          $table_name, $idx_name, join(', ', @{ $idx->{columns} // [] }), $kind)
          if length $kind && $kind ne 'clustered' && $kind ne 'nonclustered';
        # A filter (karr k76) is a predicate string; the server accepts it in
        # a form of its own and refuses a filter on a clustered index (it
        # would not hold every row), so that is refused here.
        my $where = $idx->{where};
        if (exists $idx->{where}) {
          DBIO::Exception->throw(sprintf
            "DBIO::MSSQL: table '%s': index '%s' (%s) is refused: where must "
            . "be a non-empty SQL predicate string",
            $table_name, $idx_name, join(', ', @{ $idx->{columns} // [] }))
            if !defined $where || ref $where || $where !~ /\S/;
          DBIO::Exception->throw(sprintf
            "DBIO::MSSQL: index '%s' on table '%s' is refused: a filter "
          . "(where) on a clustered index (SQL Server allows a filter on "
          . "nonclustered indexes only)", $idx_name, $table_name)
            if $kind eq 'clustered';
          $where =~ s/^\s+|\s+$//g;
        }
        # Same columns in the same order as the primary key or a unique
        # constraint: the server keeps an index for those, a second one is a
        # duplicate -- plain or declared unique. A CLUSTERED one is another
        # object (it fixes the physical order, which the nonclustered
        # constraint index does not), and a filtered one holds fewer rows
        # (and may be unique where the constraint is not), so both are written.
        next if $kind ne 'clustered' && !defined $where
          && $covered{ join "\0", @{ $idx->{columns} // [] } };
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';
        if ($kind eq 'clustered') {
          # A PRIMARY KEY is CLUSTERED unless written NONCLUSTERED, and a
          # table has one clustered index: the server refuses the second
          # (Msg 1902). Refused here, before the server, not rewritten into
          # a NONCLUSTERED key (that would change the key type of existing
          # users; a maintainer question).
          DBIO::Exception->throw(sprintf
            "DBIO::MSSQL: index '%s' on table '%s' is refused: kind "
          . "'clustered' collides with the clustered PRIMARY KEY of the "
          . "table (SQL Server allows one clustered index per table, "
          . "Msg 1902); declare the index nonclustered, or the table "
          . "without a primary key", $idx_name, $table_name)
            if @pk_cols;
          DBIO::Exception->throw(sprintf
            "DBIO::MSSQL: index '%s' on table '%s' is refused: a second "
          . "clustered index (SQL Server allows one per table, Msg 1902)",
            $idx_name, $table_name)
            if $has_clustered++;
        }
        my $kind_sql = $kind eq 'clustered' ? 'CLUSTERED ' : $kind eq 'nonclustered' ? 'NONCLUSTERED ' : '';
        my $columns = join ', ',
          map { _quote_ident($_) } @{ $idx->{columns} // [] };
        my $sql = sprintf 'CREATE %s%sINDEX %s ON %s (%s)',
          $unique, $kind_sql, _quote_ident($idx_name),
          _quote_table($table_name), $columns;
        $sql .= " WHERE $where" if defined $where;
        push @stmts, "$sql;";
      }
    }
  }

  push @stmts, _foreign_key_stmts($schema, \%seen_table, \@constraints);

  _check_constraint_names({ %seen_table, %seen_view }, \@constraints);

  # A schema a table or view names is created before the first object, each
  # CREATE SCHEMA a statement of its own: it has to be the first of its batch,
  # and the statements run one by one. dbo is always there.
  my @schema_stmts = map { sprintf 'CREATE SCHEMA %s;', _quote_ident($_) } sort keys %schemas;

  return join "

", @schema_stmts, @stmts, _order_view_statements(@view_stmts);
}

# CREATE VIEW statements, a view after the views its text names (a word that is
# the bare name of another view of the deploy), otherwise in the order given.
# The text is all there is to go by here; the diff orders by what the server
# recorded (karr k82). A cycle is left to the server to refuse.
sub _order_view_statements {
  my (@views) = @_;
  my %by = map { $_->[0] => $_ } @views;
  my (@out, %state);
  my $visit; $visit = sub {
    my ($v) = @_;
    return if $state{ $v->[0] }++;
    for my $other (@views) {
      next if $other == $v;
      (my $bare = _bare_table($other->[0])) =~ s/(\W)/\\$1/g;
      $visit->($other) if $v->[1] =~ /(?<![\w\@#\$])\[?$bare\]?(?![\w\@#\$])/i;
    }
    push @out, $v;
  };
  $visit->($_) for @views;
  return map { sprintf 'CREATE VIEW %s AS %s;', _quote_table($_->[0]), $_->[1] } @out;
}

# FOREIGN KEY constraints of the belongs_to relationships (karr k71, ADR 0060
# case family ddl-fk-*). Written as ALTER TABLE ... ADD CONSTRAINT after every
# CREATE TABLE, so the order of the tables does not matter. The name is
# FK_<table>_<columns>, the key of the constraint in the diff (ADR 0021); the
# actions are the on_delete / on_update the relationship declares, as declared
# (none: no clause, NO ACTION). A relationship with
# is_foreign_key_constraint => 0 writes none.
my %FK_ACTION = map { $_ => 1 } ('CASCADE', 'SET NULL', 'SET DEFAULT', 'NO ACTION');

sub _fk_action {
  my ($event, $action, $rel_name, $table_name) = @_;
  my $uc = _fk_action_word($event, $action, $rel_name, $table_name);
  return defined $uc ? " $event $uc" : '';
}

# The action as SQL Server writes it, or undef when none is declared.
sub _fk_action_word {
  my ($event, $action, $rel_name, $table_name) = @_;
  return undef unless defined $action && length $action;
  my $uc = uc $action;
  $uc =~ s/\s+/ /g;
  # SQL Server has no RESTRICT; its NO ACTION is checked at the end of the
  # statement, without deferral -- the same behaviour, so the same constraint
  # (core's own test schema declares RESTRICT).
  $uc = 'NO ACTION' if $uc eq 'RESTRICT';
  DBIO::Exception->throw(sprintf
    "DBIO::MSSQL: table '%s': relationship '%s' is refused: %s %s is not an "
    . "action of SQL Server (CASCADE, SET NULL, SET DEFAULT, NO ACTION)",
    $table_name, $rel_name, $event, $action)
    unless $FK_ACTION{$uc};
  return $uc;
}

sub _fk_column_pairs {
  my ($cond) = @_;
  return unless ref $cond eq 'HASH';
  my %self_to_foreign;
  for my $key (keys %$cond) {
    my $val = $cond->{$key};
    return if ref $key || ref $val;
    return unless $key =~ /^foreign\.([^.]+)$/;
    my $f_col = $1;
    return unless $val =~ /^self\.([^.]+)$/;
    $self_to_foreign{$1} = $f_col;
  }
  return unless %self_to_foreign;
  my @self_cols = sort keys %self_to_foreign;
  return (\@self_cols, [ map { $self_to_foreign{$_} } @self_cols ]);
}

# The order of the columns of a foreign key is the order of the key it
# references (karr k73). Measured: SQL Server takes the referenced list only
# in the exact order of a primary key, unique constraint or unique index of the
# target (Msg 1776 otherwise) and the pairing with the referencing columns as
# written. The primary key is asked first, then the unique constraints by name;
# the first whose column set equals the referenced columns gives the order.
# None: the order stays as _fk_column_pairs made it (sorted by the referencing
# names; the server decides). One column: nothing to order.
sub _order_by_referenced_key {
  my ($foreign, $self_cols, $foreign_cols) = @_;
  return ($self_cols, $foreign_cols) if !$foreign || @$foreign_cols < 2;
  my %pair; @pair{@$foreign_cols} = @$self_cols;
  my $want = join "\0", sort @$foreign_cols;
  my @keys = ([ $foreign->primary_columns ]);
  if ($foreign->can('unique_constraints')) {
    my %uniques = $foreign->unique_constraints;
    push @keys, $uniques{$_} for grep { $_ ne 'primary' } sort keys %uniques;
  }
  for my $key (@keys) {
    next unless @$key == @$foreign_cols && join("\0", sort @$key) eq $want;
    return ([ map { $pair{$_} } @$key ], [ @$key ]);
  }
  return ($self_cols, $foreign_cols);
}

sub _foreign_key_stmts {
  my ($schema, $seen_table, $constraints) = @_;
  my (@stmts, %fk_seen, @cascade);

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    next if _is_view($source);
    my $table_name = _resolve_table_name($source->name);
    next unless defined $table_name;
    # several Result classes of one table: the first one wrote it, and
    # declares the keys
    next if ($fk_seen{ "\0table" }{$table_name}++);

    for my $rel_name (sort $source->relationships) {
      my $info  = $source->relationship_info($rel_name);
      my $attrs = $info->{attrs} || {};
      next unless $attrs->{is_depends_on} && $attrs->{is_foreign_key_constraint};

      my ($self_cols, $foreign_cols) = _fk_column_pairs($info->{cond});
      next unless $self_cols;

      my $foreign = eval { $source->related_source($rel_name) };
      ($self_cols, $foreign_cols) = _order_by_referenced_key($foreign, $self_cols, $foreign_cols);
      my $f_table = $foreign && !_is_virtual_view($foreign)
        ? _resolve_table_name($foreign->name, _is_view($foreign) ? 'view' : 'table')
        : undef;
      # A view, or a source that is inline SQL, has no table to reference.
      # Skipped, not refused, although the server would refuse a key to a
      # view: belongs_to sets is_foreign_key_constraint => 1 itself when the
      # class does not say (core, BelongsTo.pm), so a key to a view that
      # nobody asked for cannot be told from one that was -- and the shared
      # test schema of the family declares exactly that (Track to
      # Year1999CDs). A class that wants none says is_foreign_key_constraint => 0.
      next if $foreign && (_is_view($foreign) || !defined $f_table);
      DBIO::Exception->throw(sprintf
        "DBIO::MSSQL: table '%s': relationship '%s' is refused: it is declared "
        . "as a foreign key to %s, which is not part of this deploy -- "
        . "register the class with the schema, or set "
        . "is_foreign_key_constraint => 0",
        $table_name, $rel_name, $info->{class})
        unless defined $f_table && $seen_table->{$f_table};

      my $actions = _fk_action('ON DELETE', $attrs->{on_delete}, $rel_name, $table_name)
                  . _fk_action('ON UPDATE', $attrs->{on_update}, $rel_name, $table_name);

      my $fk_name = _constraint_name('FK', $table_name, @$self_cols);
      my $fk_key  = join "\0", $f_table, @$foreign_cols, $actions;
      if (my $earlier = $fk_seen{$table_name}{$fk_name}) {
        # the same key declared twice is one constraint
        next if $earlier->[0] eq $fk_key;
        DBIO::Exception->throw(sprintf
          "DBIO::MSSQL: table '%s': relationships '%s' and '%s' are refused: "
          . "they declare the foreign key on (%s) twice, as constraint %s, "
          . "with another target or other actions; the server holds one "
          . "constraint of a name -- declare one of them",
          $table_name, $earlier->[1], $rel_name, join(', ', @$self_cols), $fk_name);
      }
      $fk_seen{$table_name}{$fk_name} = [ $fk_key, $rel_name ];
      push @$constraints, { table => $table_name, name => $fk_name,
        label => "foreign key of relationship '$rel_name'", columns => $self_cols };

      push @cascade, {
        table     => $table_name,
        label     => "relationship '$rel_name'",
        from_cols => $self_cols,
        to_table  => $f_table,
        to_cols   => $foreign_cols,
        on_delete => _fk_action_word('ON DELETE', $attrs->{on_delete}, $rel_name, $table_name) // 'NO ACTION',
        on_update => _fk_action_word('ON UPDATE', $attrs->{on_update}, $rel_name, $table_name) // 'NO ACTION',
      };

      push @stmts, sprintf
        'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s (%s)%s;',
        _quote_table($table_name), _quote_ident($fk_name),
        join(', ', map { _quote_ident($_) } @$self_cols),
        _quote_table($f_table),
        join(', ', map { _quote_ident($_) } @$foreign_cols),
        $actions;
    }
  }
  _check_cascade_paths(\@cascade);
  return @stmts;
}

# What SQL Server refuses with Msg 1785 ("may cause cycles or multiple cascade
# paths"), found before the server is asked. Measured on SQL Server 2022
# (t/95-ddl-refusals-names-live.t); NO ACTION is never refused.
#
# An FK whose action is CASCADE, SET NULL or SET DEFAULT hands an event of its
# parent on to its child: a DELETE of the parent either deletes the child
# (CASCADE) or updates the child's key columns (SET NULL / SET DEFAULT); an
# UPDATE of a referenced column updates the child's key columns. An update of
# columns passes on only through the FKs that reference one of those columns.
# From every table and each of the two events (delete, update) the chain of
# those hand-overs is followed, and refused is
#
#   - a foreign key that references its own table with any action (SET NULL
#     as well: measured), and a chain that comes back to a key it went
#     through (a cycle);
#   - a table reached by two different chains from one start (two keys from one
#     table to the same parent with actions, or a diamond: also when one of the
#     chains ends in SET NULL).
#
# (The table the chain starts on counts as reached once already.)
#
# Not refused, measured: two keys to one parent when one of them is NO ACTION;
# DELETE CASCADE on one key and UPDATE CASCADE on the other (other events); a
# cycle of SET NULL keys whose update reaches no referenced column; a diamond
# whose legs are SET NULL on columns nothing references.
#
# $fks: [ { table, label, from_cols, to_table, to_cols, on_delete, on_update } ]
# with the actions as words ('NO ACTION' for none). The label names the key in
# the message (the relationship, or the constraint of a diff).
sub _check_cascade_paths {
  my ($fks) = @_;
  my %by_parent;
  push @{ $by_parent{ $_->{to_table} } }, $_ for @$fks;

  my $refuse = sub {
    my ($fk, $why) = @_;
    DBIO::Exception->throw(sprintf
      "DBIO::MSSQL: table '%s': foreign key (%s) to '%s' (%s) is refused: SQL "
      . "Server rejects it with Msg 1785 (%s). Declare NO ACTION on one of the "
      . "keys involved, or is_foreign_key_constraint => 0",
      $fk->{table}, join(', ', @{ $fk->{from_cols} }), $fk->{to_table},
      $fk->{label}, $why);
  };

  # a key that references its own table with an action
  for my $fk (@$fks) {
    next unless $fk->{table} eq $fk->{to_table};
    next if $fk->{on_delete} eq 'NO ACTION' && $fk->{on_update} eq 'NO ACTION';
    $refuse->($fk, 'a table cannot cascade onto itself');
  }

  for my $root (sort keys %by_parent) {
    for my $event ('delete', 'update') {
      # the table the event starts on counts as reached: a chain that comes
      # back to it (a SET NULL key back to a table whose rows a CASCADE
      # deletes) is refused too, measured
      my %reached = ($root => 1);
      my $walk;
      $walk = sub {
        my ($table, $ev, $cols, $path) = @_;
        for my $fk (sort { $a->{table} cmp $b->{table}
                           || join(',', @{ $a->{from_cols} }) cmp join(',', @{ $b->{from_cols} }) }
                    @{ $by_parent{$table} || [] }) {
          my $action;
          if ($ev eq 'delete') {
            $action = $fk->{on_delete};
          } else {
            my %hit = map { $_ => 1 } @{ $fk->{to_cols} };
            next if $cols && !grep { $hit{$_} } @$cols;
            $action = $fk->{on_update};
          }
          next if $action eq 'NO ACTION';
          $refuse->($fk, 'a cycle of cascading keys')
            if grep { $_ == $fk } @$path;
          $refuse->($fk, $fk->{table} eq $root
              ? "the chain comes back to table '$root'"
              : "more than one cascading path reaches table '$fk->{table}' "
                . "from table '$root'")
            if $reached{ $fk->{table} }++;
          $walk->($fk->{table},
            ($ev eq 'delete' && $action eq 'CASCADE') ? 'delete' : 'update',
            $fk->{from_cols}, [ @$path, $fk ]);
        }
      };
      $walk->($root, $event, undef, []);
    }
  }
  return;
}

# The default as SQL. A scalar reference is an expression and written as it
# is; a number is written bare; anything else is a string literal -- national
# (N'...') for a national type, the quote doubled. A digit string with a
# leading zero is a string, not the number it looks like.
#
# A string that is no number on a numeric or bit type (int, bigint, smallint,
# tinyint, decimal, numeric, float, real, money, smallmoney, bit) is refused
# (karr k71): written as a literal, the server converts at CREATE TABLE or
# not, and a default such as 'GETDATE()' meant as an expression fails only at
# the first INSERT. The same holds for date/time types (datetime, datetime2,
# smalldatetime, date, time, datetimeoffset), measured live in t/99: the server
# takes any string at CREATE TABLE and fails at the INSERT (Msg 22007/22018).
# A string there must begin like a date literal (2020-01-01, 20200101) or, for
# time and the datetime types, a time (hh:mm[:ss[.f]]); anything else is
# refused.
sub _default_literal {
  my ($dv, $type, $table_name, $col_name) = @_;
  return $$dv if ref $dv eq 'SCALAR';
  # true and false are the booleans of the family; a bit column holds 1 and 0
  return $dv =~ /true/i ? 1 : 0
    if $type =~ /\Abit\b/i && $dv =~ /\A\s*(?:true|false)\s*\z/i;
  return $dv if $dv =~ /\A[+-]?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?\z/;
  if ($type =~ /\A(?:int|integer|bigint|smallint|tinyint|bit)\b/i
      && $dv =~ /\A\s*[+-]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)[eE][+-]?[0-9]+\s*\z/) {
    DBIO::Exception->throw(sprintf
      "DBIO::MSSQL: default for column '%s' of table '%s' is refused: '%s' is "
    . "written with an exponent, which the server does not take as an integer "
    . "for column type %s; write the number out (%s)",
      $col_name // '?', $table_name // '?', $dv, $type,
      sprintf('%.0f', $dv));
  }
  if ($type =~ /\A(?:int|integer|bigint|smallint|tinyint|decimal|numeric|float|real|money|smallmoney|bit)\b/i
      && $dv !~ /\A\s*[+-]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][+-]?[0-9]+)?\s*\z/) {
    DBIO::Exception->throw(sprintf
      "DBIO::MSSQL: default for column '%s' of table '%s' is refused: the "
    . "string '%s' is a literal, and column type %s is not a string type; "
    . "an expression is written as a scalar reference (\\'GETDATE()')",
      $col_name // '?', $table_name // '?', $dv, $type);
  }
  if ($type =~ /\A(?:datetime2|datetimeoffset|datetime|smalldatetime|date|time)\b/i) {
    my $date = qr/[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{8}/;
    my $time = qr/[0-9]{1,2}:[0-9]{2}(?::[0-9]{2}(?:\.[0-9]+)?)?/;
    my $ok = $type =~ /\Adate\b/i ? $dv =~ /\A\s*$date(?:[T ]|\s*\z)/
           : $type =~ /\Atime\b/i ? $dv =~ /\A\s*$time/
           :                        $dv =~ /\A\s*(?:$date(?:[T ]|\s*\z)|$time)/;
    DBIO::Exception->throw(sprintf
      "DBIO::MSSQL: default for column '%s' of table '%s' is refused: the "
    . "string '%s' does not look like a date or time literal for column type "
    . "%s, and the server would take it at CREATE TABLE and fail at the first "
    . "INSERT; an expression is written as a scalar reference (\\'GETDATE()')",
      $col_name // '?', $table_name // '?', $dv, $type) unless $ok;
  }
  (my $q = $dv) =~ s/'/''/g;
  my $n = $type =~ /\A(?:nchar|nvarchar|ntext)\b/i ? 'N' : '';
  return "$n'$q'";
}

sub _resolve_table_name {
  my ($name, $kind) = @_;
  return _check_table_name($name, $kind) unless ref $name;
  return undef unless ref $name eq 'SCALAR';
  my $v = $$name;
  return undef unless defined $v;
  return $v if $v =~ /\A\w+\z/;
  return undef;
}

sub _topo_sort_sources {
  my ($schema) = @_;

  my %deps;
  my %by_table;
  my @sources = sort $schema->sources;

  for my $name (@sources) {
    my $s = $schema->source($name);
    next if _is_virtual_view($s);
    my $t = _resolve_table_name($s->name, _is_view($s) ? 'view' : 'table');
    next unless defined $t;
    $by_table{$t} //= $name;
  }

  for my $name (@sources) {
    my $s = $schema->source($name);
    next if _is_virtual_view($s);
    next unless defined _resolve_table_name($s->name, _is_view($s) ? 'view' : 'table');
    $deps{$name} ||= {};
    for my $rel ($s->relationships) {
      my $info = $s->relationship_info($rel);
      next unless $info && $info->{attrs}
               && $info->{attrs}{is_foreign_key_constraint};
      my $foreign = $info->{class};
      my $fs = eval { $schema->source($foreign) }
            // eval { $schema->source($foreign =~ s/.*:://r) };
      next unless $fs && !_is_virtual_view($fs);
      my $ft = _resolve_table_name($fs->name, _is_view($fs) ? 'view' : 'table');
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

sub _mssql_column_type {
  my ($info, $table, $column) = @_;
  my $type = $info->{data_type} // 'nvarchar';

  # What SQL Server cannot hold is refused here, loudly, rather than written
  # as SQL the server rejects or silently as another column (karr k71). The
  # one function serves install_ddl and the diff ops. $table and $column only
  # name the place in the message.
  my $where = join ', ',
    (defined $table  ? "table '$table'"   : ()),
    (defined $column ? "column '$column'" : ());
  $where = " ($where)" if length $where;

  # The type as the guards below compare it: lower case, blanks folded, a
  # "(n)" taken off. Without it 'ENUM', 'enum(a,b)', 'bit(8)' and the
  # spellings of the character types slipped past an exact comparison.
  my ($base, $param) = _normalize_type($type);

  if ($base eq 'enum') {
    DBIO::Exception->throw("DBIO::MSSQL: type 'enum'$where is refused: SQL Server has no enum "
        . "type. Declare a varchar column (with a CHECK constraint), or "
        . "another type");
  }
  if ($base eq 'bit' || $base eq 'bool' || $base eq 'boolean') {
    my $n = $param // (ref $info->{size} eq 'ARRAY' ? $info->{size}[0] : $info->{size});
    DBIO::Exception->throw("DBIO::MSSQL: size '$n' on type '$base'$where is refused: bit has "
        . "no length in SQL Server (a single 0/1 value). Declare it without "
        . "a size, or use a binary or integer type for wider values")
      if defined $n and $n ne '1';
    $type = $base;
  }

  # the SQL standard spellings of the character and binary types: the native
  # type, and the length they were given stays
  if (my $native = $TYPE_ALIAS{$base}) {
    $type = $native;
    if (defined $param) {
      # a parameter is a length or max; anything else (a precision and scale,
      # a word) was thrown away and the bare type, one character, written
      DBIO::Exception->throw("DBIO::MSSQL: type '$info->{data_type}'$where is "
          . "refused: '$param' is neither a length nor max")
        unless $param =~ /\A(?:\d+|max)\z/i;
      my $plen = lc $param eq 'max' ? -1 : $param + 0;
      my $size = ref $info->{size} eq 'ARRAY' ? $info->{size}[0] : $info->{size};
      if (defined $size) {
        DBIO::Exception->throw("DBIO::MSSQL: type '$info->{data_type}'$where is "
            . "refused: the type says $param and size says $size; declare one "
            . "of them")
          unless "$size" =~ /\A\s*-?\d+\s*\z/ && $size + 0 == $plen;
      } else {
        $info = { %$info, size => $plen };
      }
    }
  }

  # Pre-parameterized types pass through (e.g. varchar(255), numeric(10,2)).
  return $type if $type =~ /\(.+\)$/;

  # Portable base types: delegate to the adapter (single source of truth,
  # shared shape with DBIO::MySQL / DBIO::PostgreSQL). Introspected live
  # types arrive as dialect names (int, nvarchar, datetime, ...) which are
  # not base-type names, so they fall through to the alias map below.
  if (DBIO::Schema::Type::is_base_type(lc $type)) {
    my $canon = eval { DBIO::Schema::Type::canonical_column('_', $info) };
    return $ADAPTER->to_native($canon) if $canon;
  }

  # Dialect / alias names only (the eight base-type names are handled
  # above). Maps legacy and cross-engine spellings to MSSQL natives.
  my %type_map = (
    # integers
    tinyint   => 'tinyint',
    smallint  => 'smallint',
    int       => 'int',
    bigint    => 'bigint',
    serial    => 'int',
    bigserial => 'bigint',

    # floats / decimals
    real              => 'real',
    float             => 'float',
    'double precision'=> 'float',
    decimal           => 'numeric',

    # strings
    string     => 'nvarchar',
    varchar    => 'nvarchar',
    ntext      => 'ntext',

    # booleans
    bool    => 'bit',

    # blobs
    bytea      => 'varbinary',
    tinyblob   => 'varbinary',
    mediumblob => 'varbinary',
    longblob   => 'varbinary',
    binary     => 'binary',
    varbinary  => 'varbinary',

    # temporal
    date        => 'date',
    time        => 'time',
    datetime    => 'datetime',
    timestamptz => 'datetimeoffset',
    'timestamp with time zone' => 'datetimeoffset',
    smalldatetime => 'smalldatetime',
  );

  my $mapped = $type_map{ lc $type } // $type;

  # decimal/numeric: size is a [precision, scale] arrayref, not a scalar
  # length, so it needs its own branch rather than the char-family regex
  # below. Mirrors DBIO::MSSQL::Adapter::to_native's rendering for the
  # 'numeric' base type (karr k17).
  if ($mapped eq 'numeric') {
    my $size = $info->{size};
    if (ref $size eq 'ARRAY') {
      my ($p, $s) = @$size;
      return "numeric($p,$s)" if defined $p && defined $s;
      return "numeric($p)" if defined $p;
    }
    return $mapped;
  }

  # Append length to types that take one (char/varchar/binary families).
  #
  # Every type here takes exactly ONE scalar length in T-SQL -- char[(n)],
  # varchar[(n|max)], nchar[(n)], nvarchar[(n|max)], binary[(n)],
  # varbinary[(n|max)] -- so an arrayref size has one member that can mean
  # anything: the width. Read it, rather than let the reference numify to its
  # (always positive) address, pass the guard and stringify into the type name
  # as nvarchar(ARRAY(0x...)). Same "first member is the width" reading the
  # numeric branch above has had since karr k17; a size that names no width
  # ([], [undef]) falls through exactly as the scalar form does (karr k27).
  #
  # The widths a caller can state are not one case (karr k28):
  #
  #   n >= 1  a length. Emitted as given, and tested first so that the shapes
  #           this branch does not judge -- a non-ARRAY reference, a string
  #           that is not a number -- keep behaving exactly as they did before
  #           (form checking for column info is core's, karr k150).
  #   -1      the (max) marker, and the ordinary deploy-path value rather than
  #           an exotic import: INFORMATION_SCHEMA reports the unbounded
  #           variants as CHARACTER_MAXIMUM_LENGTH = -1 and
  #           DBIO::MSSQL::Introspect::Columns passes that straight through as
  #           `size`. It has to be rendered BACK as (max), because omitting the
  #           length does not mean "unbounded" in a T-SQL column definition --
  #           with n omitted it means LENGTH 1 (and 30 in CAST/CONVERT). The
  #           old fallthrough therefore recreated every introspected (max)
  #           column as a one-character column: valid SQL, wrong column, silent
  #           until the first INSERT truncates.
  #   0, <-1  nothing at all. T-SQL lengths start at 1 and there is no second
  #           marker, so the caller has stated a width that cannot exist. There
  #           is no right rendering to pick -- bare would be the one-character
  #           column this ticket is about -- so refuse, the way
  #           DBIO::MSSQL::Adapter::to_native refuses a base type it has no
  #           native for.
  #
  # An ABSENT size (undef, missing, or an arrayref naming no width) keeps
  # falling through to the bare type: nothing was prescribed, so nothing is
  # emitted and the dialect default stands. Only a STATED width that cannot
  # exist is refused -- declining to misrepresent an intent is not the same as
  # demanding one.
  #
  # (max) is not available on every type in the regex, so the -1 is only
  # honoured for the three that have it (%MAX_LENGTH_TYPE). SQL Server can
  # never report -1 for char/nchar/binary -- a fixed-length column always
  # reports its real n -- and neither rendering would be right if it did.
  if ($mapped =~ /^(?:n?char|n?varchar|binary|varbinary)$/i) {
    my $size = ref $info->{size} eq 'ARRAY' ? $info->{size}[0] : $info->{size};
    if (defined $size) {
      return "$mapped($size)" if $size > 0;
      if ($size =~ /^\s*[-+]?\d+\s*$/) {
        return "$mapped(max)" if $size == -1 && $MAX_LENGTH_TYPE{lc $mapped};
        DBIO::Exception->throw("DBIO::MSSQL: size '$size' on type "
            . "'$mapped'$where is refused: not a valid length"
            . ($MAX_LENGTH_TYPE{lc $mapped}
                ? ' (lengths start at 1; -1 is the (max) marker)'
                : " (lengths start at 1; $mapped has no (max) form)"));
      }
    }
  }

  return $mapped;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::DDL - Generate MSSQL DDL from DBIO Result classes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::MSSQL::DDL> generates a MSSQL DDL script from a L<DBIO::Schema>
class hierarchy. It is the desired-state side of the test-deploy-and-
compare strategy used by L<DBIO::MSSQL::Deploy>.

    my $ddl = DBIO::MSSQL::DDL->install_ddl($schema_class_or_instance);

The output is plain SQL, suitable for executing one statement at a time
against a fresh MSSQL database. Emits C<CREATE TABLE> (inline columns,
primary key, unique) and C<CREATE INDEX>, and the foreign keys of the
C<belongs_to> relationships as C<ALTER TABLE ... ADD CONSTRAINT> (see below).

=head2 Foreign keys

Every C<belongs_to> over plain C<foreign.col =E<gt> self.col> pairs becomes
one C<FOREIGN KEY> constraint named C<FK_E<lt>tableE<gt>_E<lt>columnsE<gt>>,
written after all C<CREATE TABLE> statements, with the C<on_delete> and
C<on_update> of the relationship (C<CASCADE>, C<SET NULL>, C<SET DEFAULT>,
C<NO ACTION>; C<RESTRICT> is written as C<NO ACTION>, which SQL Server
checks immediately as well; any other word is refused). Two relationships over the same
columns with the same target and actions are one constraint; with another
target or other actions they are refused. A target that is a view or inline SQL is skipped (not
refused: C<belongs_to> sets C<is_foreign_key_constraint> to 1 itself, so a key to
a view that was not asked for cannot be told from one that was, and the shared
test schema of the family has one; say C<is_foreign_key_constraint =E<gt> 0> to
make that explicit); a table outside the
deploy is refused; C<is_foreign_key_constraint =E<gt> 0> writes none. A condition that
is no plain column pair is skipped. Column names are written quoted, so a name
with a blank or a hyphen works.

A name over 128 characters (the most SQL Server holds) is cut to 128 and ends in
8 hex digits of the SHA-1 of the full name (C<_constraint_name>, the one
function that names C<FK_> and C<UQ_> constraints).

=head3 Cascades SQL Server refuses

SQL Server rejects a foreign key that "may cause cycles or multiple cascade
paths" (Msg 1785). The driver refuses these before the server is asked,
naming table and relationship (C<_check_cascade_paths>, also run by
L<DBIO::MSSQL::Diff> over the target model when it adds a key). A key whose
action is CASCADE, SET NULL or SET DEFAULT passes the DELETE or UPDATE of its
parent on to its child, and is refused when it references its own table, when a
chain of such keys comes back to a key or to the table it started on, or when
two different chains reach the same table. NO ACTION (and RESTRICT, which is
written as NO ACTION) is never refused. The rule was measured on SQL Server
2022 (F<t/95-ddl-refusals-names-live.t>), including what it lets through: two keys
to one parent when one is NO ACTION, DELETE CASCADE on one key and UPDATE CASCADE
on the other, a cycle of SET NULL keys, a diamond whose legs are SET NULL on
columns nothing references.

=head2 Table names and schemas

A table or view name with a dot, C<schema.table>, is made in that schema:
C<CREATE TABLE schema.table>, both parts quoted on their own. A schema the
classes name and the database lacks is created, by a C<CREATE SCHEMA> that is
a statement of its own, written before the first table (SQL Server wants it
first in its batch; the statements run one by one). C<dbo.t> is the table C<t>
of C<dbo>, written without the schema, as L<DBIO::MSSQL::Introspect> keys it.
Indexes, unique constraints, primary and foreign keys of such a table are made
in its schema and named after the bare table (C<PK_t>, C<FK_t_col>,
C<UQ_t_col>): SQL Server keeps constraint names once per schema, so C<one.t>
and C<two.t> may both have a C<PK_t>. A foreign key may cross the border in
both directions. A name with two or more dots (a database-qualified one) or an
empty part is refused: the driver cannot create objects in another database. A
schema is never dropped, also when no class names it any more.

=head2 Names in one namespace

SQL Server keeps the names of constraints and of objects (tables, views) in one
namespace per schema (Msg 2714). A constraint named like a table or view of the
deploy -- C<FK_...>, C<UQ_...> or a unique name the declaration chose -- is
refused before the server is asked, by C<install_ddl> and by the diff over its
target model, per schema. The shared test schema of core declares one
(C<< add_unique_constraint(artist =E<gt> ...) >> on the table C<artist>). Names
are compared as written. A virtual view is not deployed and takes no name.

=head2 Types and defaults

A parameter of a standard type spelling (C<character varying(10)>) must be a
length or C<max>, and must agree with C<size> when both are given; anything
else is refused. A C<true>/C<false> default on C<bit> is written C<1>/C<0>; a
number with an exponent (C<1e5>) on an integer type or C<bit> is refused.

=head2 Unique constraints

Every unique constraint of the result source is written as
C<CONSTRAINT E<lt>nameE<gt> UNIQUE (...)> with the name of the declaration
(C<< unique =E<gt> [ name =E<gt> [cols] ] >>; core names an undeclared one
C<E<lt>tableE<gt>_E<lt>columnsE<gt>>, and that one is written as
C<UQ_E<lt>tableE<gt>_E<lt>columnsE<gt>> because a table can have the name
C<E<lt>tableE<gt>_E<lt>columnsE<gt>> -- the table C<user> with C<unique(email)>
and a table C<user_email> -- and SQL Server holds constraint and table names in
one namespace; a name the declaration chose is kept). Unnamed, the server makes up a name
per database and the diff of two databases sees two different indexes. SQL
Server holds constraint names once per schema: the same name on two tables is
refused.

=head2 Indexes

C<CREATE INDEX> comes from two declarations: C<mssql_indexes>
(L<DBIO::MSSQL::Result>) and the index declaration of the result source that
C<idx> of L<DBIO::Cake> and C<indices> write (C<index_declarations>, ADR 0061
in core). The latter gives name, columns and C<unique>, and its own
C<< driver => { mssql => { kind => 'clustered' | 'nonclustered', where => '...' } } >>
block gives the index kind and the filter; an empty C<< mssql => {} >> is the
plain index. Where both
declarations use the same name, the canonical declaration wins. An entry that
carries only another driver's block, an unknown key in the own block and a
C<kind> other than C<clustered> or
C<nonclustered> are refused with an exception naming the index, never written
as a plainer one. So are an index C<type> other than C<unique> and any
C<options> of the declaration: SQL Server has no counterpart written here, and
they are not dropped silently.

An index over exactly the columns, in that order, of the primary key or of a
unique constraint of the same table is not written, plain or declared
C<unique>: the server keeps an index for those, and a second one is a
duplicate. One with C<< kind =E<gt> 'clustered' >> is written: it fixes the
physical order of the table, which the nonclustered constraint index does not.
But a table with a primary key has its clustered index already (the key is
C<CLUSTERED> as written here), and SQL Server allows one per table (Msg 1902):
a declared C<clustered> index on such a table, and a second one on any table,
are refused with an exception naming table and index, before the server sees
them. A clustered index on a table without a primary key stays valid.

C<where> (the same key in a C<mssql_indexes> entry and in the own block of the
canonical declaration) makes a B<filtered index>:
C<CREATE [UNIQUE] INDEX ... (cols) WHERE E<lt>predicateE<gt>>, the predicate
written as given (SQL Server accepts only simple comparisons joined by C<AND>,
C<IN> and C<IS [NOT] NULL> there; it parses the predicate, the driver does not).
An empty or non-string C<where> and a filter on a C<clustered> index (the server
refuses that) are refused with an exception naming the index. A filtered index
over exactly the columns of the key or of a unique constraint is written, being
another object than the one the server keeps (an unfiltered one is still left
out). L<DBIO::MSSQL::Diff::Index> compares and replaces on a changed filter.
The diff builds its desired model from this DDL (through
L<DBIO::MSSQL::Deploy>) and refuses the same.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::MSSQL::DDL->install_ddl($schema);

Returns the full installation DDL as a single string.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
