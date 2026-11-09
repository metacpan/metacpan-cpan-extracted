package DBIO::PostgreSQL::DDL;
# ABSTRACT: Generate PostgreSQL DDL from DBIO schema classes

use strict;
use warnings;

our $VERSION = '0.900004';

use Scalar::Util ();
use DBIO::PostgreSQL::Util qw(
  quote_ident quote_qualified quote_literal quote_role
  create_schema_if_missing
  type_takes_modifier type_with_modifier
  connection_search_path deferrable_clause
);
use DBIO::Schema::Type ();
use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::Adapter ();
use DBIO::PostgreSQL::Introspect ();

my $ADAPTER = DBIO::PostgreSQL::Adapter->new;








sub install_ddl {
  my ($class, $schema, %opts) = @_;
  my $control   = $opts{extension_control_schemas} // {};
  my $installed = $opts{extension_installed_schemas} // {};
  my @stmts;
  my @views;
  my %view_of_class;
  my %seen_table;
  my %seen_view;
  my %enum_type;

  # 1. Extensions. One that names a schema is created WITH SCHEMA. The
  #    schema must be one pg_schemas declares (or public): a deploy sees no
  #    other, and creating one the declaration does not name would be an
  #    interface of its own (karr k120, point 8). It is created here, ahead of
  #    the extension, and left out of step 2 -- step 2 comes later.
  #
  #    Every extension is created WITH SCHEMA (karr k141): an unqualified
  #    CREATE EXTENSION lands in the first schema of the session's search_path
  #    (ag_catalog after the activation of age; the namespace on a connection
  #    with the connect key schema, karr k128), and an extension is the
  #    database's, not that schema's. The schema is the declared one; else
  #    the one the control file of the extension fixes, where the caller
  #    knows it (extension_control_schemas, read from the server by the
  #    deploy); else public. For a fixed schema the statement is written
  #    without the clause: the server installs the extension there whatever
  #    the search_path, creates the schema as part of the extension when it
  #    is missing, and refuses WITH SCHEMA for a schema that does not exist
  #    yet (a deploy restricted by pg_schemas does not create it either).
  my %created_ns;
  my $ext_schemas = _schema_decl($schema, 'pg_extension_schemas') // {};
  my @declared_ns = _schema_decl($schema, 'pg_schemas');
  my @extensions  = _schema_decl($schema, 'pg_extensions');
  my $namespace   = _connection_namespace($schema);
  _refuse_namespace_declarations($schema, $namespace) if defined $namespace;
  # A schema a connection with the connect key creates is looked up in
  # pg_namespace first: CREATE SCHEMA IF NOT EXISTS needs CREATE on the
  # database even for a namespace that is there (karr k131, d).
  my $create_schema = sub {
    defined $namespace
      ? create_schema_if_missing($_[0]) . ';'
      : sprintf('CREATE SCHEMA IF NOT EXISTS %s;', quote_ident($_[0]));
  };
  for my $ext (@extensions) {
    my $ns    = $ext_schemas->{$ext};
    my $fixed = $control->{$ext};
    refuse_control_schema($ext, $ns, $fixed)
      if defined $ns && defined $fixed && $ns ne $fixed;
    my $from_control = !defined $ns && defined $fixed;
    # Neither declared nor fixed: the schema the database under diff holds it
    # in, where the caller knows it (karr k144); else public.
    my $from_database = !defined $ns && !defined $fixed && defined $installed->{$ext};
    $ns //= $fixed // $installed->{$ext} // 'public';
    die sprintf
      "refusing to write the install DDL: extension %s would be created in "
      . "schema %s, the namespace this connection works in (connect key "
      . "schema). An extension belongs to the database and is not installed "
      . "into the namespace of one connection; name another schema for it, "
      . "pg_extensions(%s => { schema => ... }).\n",
      $ext, $ns, $ext
      if defined $namespace && $ns eq $namespace;
    if ($from_control) {
      push @stmts, sprintf 'CREATE EXTENSION IF NOT EXISTS %s;', quote_ident($ext);
      next;
    }
    die sprintf
      "refusing to write the install DDL: extension %s is declared in schema "
      . "%s, which pg_schemas does not declare (%s). A schema an extension "
      . "names has to be one the deploy manages; add '%s' to pg_schemas. "
      . "Declaring pg_schemas makes the deploy restricted: it drops no "
      . "extension unless built with manage_extensions_when_restricted.\n",
      $ext, $ns, (@declared_ns ? join(', ', @declared_ns) : 'none declared'), $ns
      if $ns ne 'public' && !$from_database && !grep { $_ eq $ns } @declared_ns;
    if ($ns ne 'public' and !$created_ns{$ns}++) {
      push @stmts, $create_schema->($ns);
    }
    push @stmts, sprintf 'CREATE EXTENSION IF NOT EXISTS %s WITH SCHEMA %s;',
      quote_ident($ext), quote_ident($ns);
  }

  # 1b. The namespace of the connection, and its search_path: from here on
  #     an unqualified name is created in the namespace. Created first,
  #     because the server puts an unqualified object into the first schema
  #     of the path that exists -- without the namespace that is the one
  #     behind it, and nothing says so. Set here, in the script, because the
  #     temporary database of a diff is reached by a connection of its own.
  my $connection_path;
  if (defined $namespace) {
    push @stmts, $create_schema->($namespace)
      unless $namespace eq 'public' or $created_ns{$namespace}++;
    $connection_path = sprintf 'SET search_path TO %s;', join ', ',
      map { quote_ident($_) }
      connection_search_path($namespace, \@extensions, $ext_schemas, [], $control);
    push @stmts, $connection_path;
  }

  # 2. Schemas (namespaces)
  for my $ns (_namespaces($schema)) {
    next if $ns eq 'public'; # public always exists
    next if $created_ns{$ns}; # created ahead of the extension that names it
    push @stmts, $create_schema->($ns);
  }

  # 3. Types from PgSchema classes
  for my $ns (_namespaces($schema)) {
    my $pg_schema_class = _schema_decl($schema, pg_schema_class => $ns);
    next unless $pg_schema_class;

    # Enums
    for my $def (@{ $pg_schema_class->_pg_enum_defs }) {
      my ($name, $values) = @$def;
      my $vals = join ', ', map { quote_literal($_) } @$values;
      push @stmts, sprintf "CREATE TYPE %s AS ENUM (%s);",
        quote_qualified($ns, $name), $vals;
    }

    # Composite types
    for my $def (@{ $pg_schema_class->_pg_type_defs }) {
      my ($name, $fields) = @$def;
      my @attrs;
      for my $fname (sort keys %$fields) {
        push @attrs, sprintf '  %s %s', quote_ident($fname), $fields->{$fname};
      }
      push @stmts, sprintf "CREATE TYPE %s AS (\n%s\n);",
        quote_qualified($ns, $name), join(",\n", @attrs);
    }

    # Functions
    for my $def (@{ $pg_schema_class->_pg_function_defs }) {
      my ($name, $sql) = @$def;
      push @stmts, $sql;
    }
  }

  # 3b. Auto-generate CREATE TYPE for Cake-style enum columns
  #     (data_type => 'enum' with extra->{list} but no pg_enum_type)
  {
    my @sources = $schema->sources;
    for my $source_name (sort @sources) {
      my $source = $schema->source($source_name);
      my $result_class = $source->result_class;
      my $table_name = $source->name;

      # Only real tables carry enum columns worth a CREATE TYPE; views and
      # subquery sources (scalar-ref name) have no backing table.
      next if $source->isa('DBIO::ResultSource::View') || ref $table_name;

      my $pg_schema_name = $result_class->can('pg_schema')
        ? $result_class->pg_schema : undef;

      for my $col_name ($source->columns) {
        my $info = $source->column_info($col_name);
        next unless ($info->{data_type} // '') eq 'enum';
        next if $info->{pg_enum_type};                       # already declared via PgSchema
        next unless $info->{extra} && $info->{extra}{list};  # need values

        # Generate a type name: {table}_{column}_enum, in the schema of the
        # table -- the last of the table's name parts gets the suffix.
        my @type_parts = _relation_parts($pg_schema_name, $table_name);
        $type_parts[-1] .= "_${col_name}_enum";
        my $type = quote_qualified(@type_parts);

        my $vals = join ', ', map { quote_literal($_) } @{ $info->{extra}{list} };
        push @stmts, sprintf "CREATE TYPE %s AS ENUM (%s);", $type, $vals;

        # The column below is of exactly this type. Remembered here, not
        # written into the column info: install_ddl reads the schema, and a
        # pg_enum_type left behind made the next call skip this CREATE TYPE.
        $enum_type{$source_name}{$col_name} = $type;
      }
    }
  }

  # 4. Tables from Result classes
  my @sources = $schema->sources;
  for my $source_name (sort @sources) {
    my $source = $schema->source($source_name);
    my $result_class = $source->result_class;

    my $table_name = $source->name;
    my $pg_schema_name;
    if ($result_class->can('pg_schema')) {
      $pg_schema_name = $result_class->pg_schema;
    }

    # Views: CREATE VIEW comes after all tables and their foreign keys (6.
    # below); skip virtual views. Which view a result class is, is noted for
    # every one of them: that is what a deploy_depends_on names.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      next if ref $table_name && ref $table_name ne 'SCALAR';
      my $vqual = _relation_sql($pg_schema_name, $table_name);
      $view_of_class{$result_class} //= $vqual;
      if (my $earlier = $seen_view{$vqual}) {
        $source->throw_exception(sprintf
          "refusing to write the install DDL: the view %s is declared by two "
          . "sources, %s (%s) and %s (%s); the server holds one view of a "
          . "name -- declare it once",
          $vqual, $earlier->[0], $earlier->[1], $source_name, $result_class);
      }
      $seen_view{$vqual} = [ $source_name, $result_class ];
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      push @views, {
        relation   => $vqual,
        class      => $result_class,
        depends_on => [ _view_depends_on($source) ],
        sql        => sprintf('CREATE VIEW %s AS %s', $vqual, $def),
      };
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd') or an inline
    # subquery source; the former is written as given, the latter skipped.
    next if ref $table_name eq 'SCALAR' && $$table_name =~ /\s|\(/;
    next if ref $table_name && ref $table_name ne 'SCALAR';

    my $qualified = _relation_sql($pg_schema_name, $table_name);

    # Multiple result sources can map to one physical table; emit it once.
    next if $seen_table{$qualified}++;

    # Column definitions
    my @col_defs;
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = $enum_type{$source_name}{$col_name} // _pg_column_type($info, (ref $table_name ? $source_name : $table_name) . ".$col_name");
      my $def = sprintf '  %s %s', quote_ident($col_name), $type;
      $def .= ' NOT NULL' if !$info->{is_nullable};
      if ($info->{is_auto_increment} && $type !~ /^(?:big)?serial$/) {
        # DBIO convention: auto-increment columns are GENERATED ALWAYS AS
        # IDENTITY unless the user explicitly opts into BY DEFAULT via
        # extra->{identity} = 'd'. ALWAYS prevents accidental client-side
        # inserts, matches the DBIx::Class::ResultSource default, and is
        # what DBIO::PostgreSQL::Diff::target_from_compiled synthesizes
        # (so the round-trip diff against the introspected source is
        # empty for the default schema).
        my $kind = DBIO::PostgreSQL::Introspect->identity_kind(
          $info->{extra} && $info->{extra}{identity}
        ) // 'ALWAYS';
        $def .= " GENERATED $kind AS IDENTITY";
      }
      elsif (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        if (ref $dv eq 'SCALAR') {
          $def .= " DEFAULT $$dv";
        } else {
          $def .= ' DEFAULT ' . quote_literal($dv);
        }
      }
      push @col_defs, $def;
    }

    # Primary key
    my @pk = $source->primary_columns;
    if (@pk) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { quote_ident($_) } @pk);
    }

    # Unique constraints declared via add_unique_constraint / Cake's `unique`.
    # The 'primary' constraint is auto-added by set_primary_key and already
    # emitted above as PRIMARY KEY, so it must be skipped here.
    my %unique_options = $result_class->can('pg_unique_options')
      ? %{ $result_class->pg_unique_options } : ();
    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $oname (sort keys %unique_options) {
        $source->throw_exception(sprintf
          "refusing to write the install DDL: pg_unique_options of %s names '%s', "
          . "which is no UNIQUE constraint of the table",
          $table_name, $oname) unless $oname ne 'primary' && $uniques{$oname};
      }
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        push @col_defs, sprintf '  CONSTRAINT %s UNIQUE (%s)%s',
          quote_ident($uname),
          join(', ', map { quote_ident($_) } @$cols),
          _unique_timing($source, $table_name, $uname, $unique_options{$uname});
      }
    }

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);",
      $qualified, join(",\n", @col_defs);

    # Indexes: the ones written by hand with pg_index, and the canonical
    # declarations of the result source (Cake idx, indices; ADR 0061 in
    # core, karr k124). A canonical declaration of the same name wins over
    # the hand-written one. Its name, columns and unique are the entry's own;
    # the rest -- using, expression, opclasses, include, with, where -- is
    # its driver->{pg} block. A schema is bound to one driver, so what the
    # DDL would not write is refused (karr k129): options, a type other than
    # unique, an entry with only another driver's block, a key the pg block
    # does not know. An own, empty pg block is the plain index.
    {
      my %indexes;
      if ($result_class->can('pg_indexes')) {
        my $hand = $result_class->pg_indexes;
        $indexes{$_} = $hand->{$_} for keys %$hand;
      }
      my @declared = $source->can('index_declarations_for')
        ? $source->index_declarations_for('pg',
            [qw(where using with expression include opclasses)])
        : ();
      for my $decl (@declared) {
        $source->throw_exception(sprintf
          "index '%s' of %s: options are not read by the PostgreSQL driver; "
          . "declare what the index needs in its pg => { ... } block",
          $decl->{name}, $source->name)
          if defined $decl->{options};
        $source->throw_exception(sprintf
          "index '%s' of %s: type '%s' is not read by the PostgreSQL driver; "
          . "only type => 'unique' is (or unique => 1); "
          . "use pg => { using => ... } for an access method",
          $decl->{name}, $source->name, $decl->{type})
          if defined $decl->{type} and $decl->{type} !~ /\A unique \z/xi;
        $indexes{ $decl->{name} } = {
          %{ $decl->{driver}{pg} || {} },
          columns => $decl->{columns},
          ($decl->{unique} ? (unique => 1) : ()),
        };
      }
      my $indexes = \%indexes;

      # The columns of every unique constraint of the table, written above as
      # a CONSTRAINT ... UNIQUE line, which the server backs with an index of
      # its own. An index over exactly those columns, in that order, with the
      # default access method and nothing else, is a second one for the same
      # lookups and is not written, plain or declared unique (karr k127). An
      # expression, a predicate, another access method, an operator class,
      # INCLUDE columns or storage parameters make it another object.
      my %uniq_cols;
      if ($source->can('unique_constraints')) {
        my %uniques = $source->unique_constraints;
        for my $uname (keys %uniques) {
          next if $uname eq 'primary';
          $uniq_cols{ join "\0", @{ $uniques{$uname} } } = 1;
        }
      }

      for my $idx_name (sort keys %$indexes) {
        my $idx = $indexes->{$idx_name};
        next if $uniq_cols{ join "\0", @{ $idx->{columns} // [] } }
          && !defined $idx->{expression} && !$idx->{where}
          && (!defined $idx->{using} || lc $idx->{using} eq 'btree')
          && !($idx->{include} && @{ $idx->{include} })
          && !($idx->{with} && %{ $idx->{with} })
          && !grep { defined && length } values %{ $idx->{opclasses} || {} };
        my $using = $idx->{using} ? " USING $idx->{using}" : '';
        my $columns;
        if ($idx->{expression}) {
          $columns = $idx->{expression};
        } else {
          # Per-column operator class, appended after the column name.
          # Mandatory for pgvector hnsw: it has no default opclass for vector,
          # so USING hnsw (embedding) alone is rejected by PostgreSQL. ivfflat
          # defaults to vector_l2_ops; there it selects any other distance.
          my $opclasses = $idx->{opclasses} || {};
          $columns = join(', ', map {
            defined $opclasses->{$_} && length $opclasses->{$_}
              ? quote_ident($_) . " $opclasses->{$_}" : quote_ident($_)
          } @{ $idx->{columns} // [] });
        }
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';
        my $sql = sprintf 'CREATE %sINDEX %s ON %s%s (%s)',
          $unique, quote_ident($idx_name), $qualified, $using, $columns;
        # Non-key payload columns of a covering index. They follow the key
        # list and precede WITH/WHERE, which is the only order PostgreSQL
        # accepts.
        if ($idx->{include} && @{ $idx->{include} }) {
          $sql .= ' INCLUDE (' . join(', ', map { quote_ident($_) } @{ $idx->{include} }) . ')';
        }
        if ($idx->{with}) {
          my @with_parts;
          for my $k (sort keys %{ $idx->{with} }) {
            $source->throw_exception(sprintf
              "refusing to write the install DDL: index '%s' of %s: a key of with is a "
              . "storage parameter name (letters, digits, underscores, one optional dot)",
              $idx_name, $source->name)
              unless $k =~ /\A[A-Za-z_][A-Za-z0-9_\$]*(?:\.[A-Za-z_][A-Za-z0-9_\$]*)?\z/;
            push @with_parts, "$k = $idx->{with}{$k}";
          }
          $sql .= ' WITH (' . join(', ', @with_parts) . ')';
        }
        $sql .= " WHERE $idx->{where}" if $idx->{where};
        push @stmts, "$sql;";
      }
    }

    # Triggers
    if ($result_class->can('pg_triggers')) {
      my $triggers = $result_class->pg_triggers;
      for my $trg_name (sort keys %$triggers) {
        my $trg = $triggers->{$trg_name};
        my $for_each = uc($trg->{for_each} || 'ROW');
        $source->throw_exception(sprintf
          "refusing to write the install DDL: trigger '%s' of %s: for_each is ROW or STATEMENT",
          $trg_name, $source->name)
          unless $for_each eq 'ROW' || $for_each eq 'STATEMENT';
        push @stmts, sprintf 'CREATE TRIGGER %s %s %s ON %s FOR EACH %s EXECUTE FUNCTION %s;',
          quote_ident($trg_name), $trg->{when}, $trg->{event},
          $qualified, $for_each, $trg->{execute};
      }
    }

    # RLS
    if ($result_class->can('pg_rls') && $result_class->pg_rls) {
      my $rls = $result_class->pg_rls;
      if ($rls->{enable}) {
        push @stmts, sprintf 'ALTER TABLE %s ENABLE ROW LEVEL SECURITY;', $qualified;
      }
      if ($rls->{force}) {
        push @stmts, sprintf 'ALTER TABLE %s FORCE ROW LEVEL SECURITY;', $qualified;
      }
      if ($rls->{policies}) {
        for my $pol_name (sort keys %{ $rls->{policies} }) {
          my $pol = $rls->{policies}{$pol_name};
          my $sql = sprintf 'CREATE POLICY %s ON %s',
            quote_ident($pol_name), $qualified;
          $sql .= ' AS RESTRICTIVE' if $pol->{restrictive};
          my $for = uc($pol->{for} || 'ALL');
          $source->throw_exception(sprintf
            "refusing to write the install DDL: policy '%s' of %s: for is SELECT, INSERT, UPDATE, DELETE or ALL",
            $pol_name, $source->name)
            unless $for =~ /\A(?:SELECT|INSERT|UPDATE|DELETE|ALL)\z/;
          $sql .= " FOR $for" if $for ne 'ALL';
          if ($pol->{roles} && @{ $pol->{roles} }) {
            $sql .= sprintf ' TO %s', join(', ', map { quote_role($_) } @{ $pol->{roles} });
          }
          $sql .= sprintf ' USING (%s)', $pol->{using} if $pol->{using};
          $sql .= sprintf ' WITH CHECK (%s)', $pol->{with_check} if $pol->{with_check};
          push @stmts, "$sql;";
        }
      }
    }

    # CHECK constraints
    if ($result_class->can('pg_check_constraints')) {
      my $checks = $result_class->pg_check_constraints;
      for my $name (sort keys %$checks) {
        my $entry = $checks->{$name};
        my $expr  = $entry->{definition};
        $expr = "CHECK ($expr)" unless $expr =~ /^\s*CHECK\b/i;
        push @stmts, sprintf 'ALTER TABLE %s ADD CONSTRAINT %s %s;',
          $qualified, quote_ident($name), $expr;
      }
    }

    # Raw trailing DDL (e.g. cross-table FKs, unless the class opts into
    # pg_fk_constraints_from_rels below)
    if ($result_class->can('pg_extra_ddl')) {
      my $extra = $result_class->pg_extra_ddl;
      push @stmts, @$extra;
    }
  }

  # 5. Foreign key constraints from belongs_to (on by default, off per result
  #    class via pg_fk_constraints_from_rels(0) -- see pg_extra_ddl for
  #    the always-available manual alternative). Run as its own pass, after
  #    every CREATE TABLE above, so cross-table references always resolve
  #    regardless of source-iteration order.
  my %fk_seen;
  for my $source_name (sort @sources) {
    my $source = $schema->source($source_name);
    my $result_class = $source->result_class;
    next unless $result_class->can('pg_fk_constraints_from_rels')
      && $result_class->pg_fk_constraints_from_rels;
    next if $source->isa('DBIO::ResultSource::View');

    my $table_name = $source->name;
    next if ref $table_name && ref $table_name ne 'SCALAR';

    my $pg_schema_name = $result_class->can('pg_schema') ? $result_class->pg_schema : undef;
    my $qualified = _relation_sql($pg_schema_name, $table_name);
    $table_name = $$table_name if ref $table_name;

    for my $rel_name (sort $source->relationships) {
      my $info = $source->relationship_info($rel_name);

      # attrs->{accessor} is not a reliable belongs_to marker: it is only
      # 'filter' when the relationship name happens to equal an FK column
      # name, and plain 'single' otherwise -- indistinguishable there from
      # has_one/might_have. attrs->{is_depends_on} is hardcoded 1 only by
      # DBIO::Relationship::BelongsTo (0 for has_one/might_have/has_many;
      # this is the same signal DBIO::ResultSource's own _pk_depends_on and
      # DBIO::ResultSet use to recognize FK-owning relationships).
      next unless $info->{attrs}{is_depends_on};

      # A belongs_to sets is_foreign_key_constraint to 1 unless told otherwise;
      # a relationship that declares it 0 (or any false value) is no key.
      next if exists $info->{attrs}{is_foreign_key_constraint}
        && !$info->{attrs}{is_foreign_key_constraint};

      my ($self_cols, $foreign_cols) = _fk_column_pairs($info->{cond});
      unless ($self_cols) {
        push @stmts, _note("skipped FK for rel $rel_name: non-column condition");
        next;
      }

      my $f_class = $info->{source};

      # A belongs_to declared with an explicit hashref condition skips
      # ensure_class_loaded, so the foreign class may never have been loaded
      # at all. The class that asked for the foreign key declared a target
      # that is not there: that is refused, not noted (karr k120).
      unless ($f_class->can('table')) {
        $source->throw_exception(sprintf
          "refusing to write the install DDL: relationship '%s' of %s is "
          . "declared as a foreign key (pg_fk_constraints_from_rels) to class "
          . "%s, which is not loaded -- load the class, set "
          . "is_foreign_key_constraint => 0 on the relationship, or leave "
          . "pg_fk_constraints_from_rels off for the class",
          $rel_name, $table_name, $f_class);
      }

      my $f_pg_schema = $f_class->can('pg_schema') ? $f_class->pg_schema : undef;
      my $f_qualified = _relation_sql($f_pg_schema, $f_class->table);

      unless ($seen_table{$f_qualified}) {
        $source->throw_exception(sprintf
          "refusing to write the install DDL: relationship '%s' of %s is "
          . "declared as a foreign key (pg_fk_constraints_from_rels) to "
          . "table %s of class %s, which is not part of this schema deploy "
          . "-- register the class with the schema, set "
          . "is_foreign_key_constraint => 0 on the relationship, or leave "
          . "pg_fk_constraints_from_rels off for the class",
          $rel_name, $table_name, $f_qualified, $f_class);
      }

      # The actions the belongs_to declares, as declared; none declared is
      # no clause and the server's default (karr k127).
      my $actions = join '', map {
        _fk_action($source, $table_name, $rel_name, $_->[0], $info->{attrs}{ $_->[1] })
      } [ 'ON DELETE', 'on_delete' ], [ 'ON UPDATE', 'on_update' ];
      $actions .= _timing_clause($source, "relationship '$rel_name' of $table_name",
        { map { defined $info->{attrs}{$_} ? ($_ => $info->{attrs}{$_}) : () } qw( deferrable initially_deferred ) },
        qw( deferrable initially_deferred ));

      # The name is made of the table and the columns. Two relationships over
      # one key with the same actions are one constraint and are written
      # once; with other actions, or to another table, they would need one
      # name twice, which the server refuses -- so the driver does, before
      # it writes anything (karr k127).
      my $fk_name = join('_', $table_name, @$self_cols, 'fkey');
      my $fk_key  = join "\0", $f_qualified, @$foreign_cols, lc $actions;
      if (defined(my $earlier = $fk_seen{$qualified}{$fk_name})) {
        next if $earlier->[0] eq $fk_key;
        $source->throw_exception(sprintf
          "refusing to write the install DDL: relationships '%s' and '%s' of %s "
          . "declare the foreign key on (%s) twice, as constraint %s, with "
          . "another target or other actions; the server holds one "
          . "constraint of a name -- declare one of them",
          $earlier->[1], $rel_name, $table_name, join(', ', @$self_cols), $fk_name);
      }
      $fk_seen{$qualified}{$fk_name} = [ $fk_key, $rel_name ];

      push @stmts, sprintf 'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s (%s)%s;',
        $qualified, quote_ident($fk_name),
        join(', ', map { quote_ident($_) } @$self_cols),
        $f_qualified,
        join(', ', map { quote_ident($_) } @$foreign_cols),
        $actions;
    }
  }

  # 6. Views, each behind the views its deploy_depends_on names. Here and not
  #    at the end: a view without a pg_schema is created where the session
  #    puts it, like a table without one, under the path of the session --
  #    where the tables it was declared next to are (karr k120).
  push @stmts, map { $_->{sql} } _views_in_dependency_order(\@views, \%view_of_class);

  # 7. Settings
  my $settings = _schema_decl($schema, 'pg_settings');
  if ($settings && %$settings) {
    push @stmts, map { _setting_sql($_, $settings->{$_}) } sort keys %$settings;
  }

  # 8. No search path. The script does not end with SET search_path: the
  #    statement would set the path of the session that runs it, the
  #    caller's, and nothing above needs it -- every object is created
  #    before. pg_search_path is not written (karr k121, P13); its entries
  #    are still checked, so a declaration that was refused stays refused.
  #    A connection that names its namespace has its path at step 1b, for
  #    the temporary database of a diff.
  _search_path_entry($_) for defined $connection_path ? () : _schema_decl($schema, 'pg_search_path');

  return join("\n\n", map { _terminated($_) } @stmts) . "\n";
}


# Ask the schema for one of the schema-level declarations of the
# DBIO::PostgreSQL component (pg_extensions, pg_schemas, pg_schema_class,
# pg_settings, pg_search_path). A schema that does not load the component has
# none of them -- deploy_async hands install_ddl such a schema on a connection
# opened with { async => ... } and no load_components('PostgreSQL')
# (dbio-postgresql-ev k36) -- and is answered by the component class itself:
# its defaults, so "not loaded" and "loaded, nothing declared" produce the
# same DDL by construction rather than by a second copy of the defaults here
# (karr k82). Per method, like the result-class can() checks in install_ddl.
# DBIO::PostgreSQL::Deploy asks its own pg_extensions/pg_schemas through this
# too, fully qualified, so both paths share one fallback (karr k87).
# The namespaces the script writes: the declared pg_schemas in declaration
# order, then -- name order -- a bound one no list names (a binding alone
# declares nothing and restricts nothing; only pg_schemas does).
sub _namespaces {
  my ($schema) = @_;
  my @declared = _schema_decl($schema, 'pg_schemas');
  my %have = map { $_ => 1 } @declared;
  my $bound = _schema_decl($schema, '_pg_schema_classes') // {};
  return (@declared, sort grep { !$have{$_} && defined $bound->{$_} } keys %$bound);
}


sub refuse_control_schema {
  my ($ext, $declared, $fixed) = @_;
  die sprintf
    "refusing to write the install DDL: extension %s is declared in schema "
    . "%s, but its control file fixes schema %s and the server installs it "
    . "nowhere else. Declare pg_extensions(%s => { schema => '%s' }) or no "
    . "schema.\n",
    $ext, $declared, $fixed, $ext, $fixed;
}


sub control_schemas_sql {
  my (@names) = @_;
  return q{SELECT v.name, v.schema
    FROM pg_catalog.pg_available_extension_versions v
    JOIN pg_catalog.pg_available_extensions a
      ON a.name = v.name AND a.default_version = v.version
    WHERE v.name IN (} . join(', ', map { quote_literal($_) } @names)
    . q{) AND v.schema IS NOT NULL};
}


sub check_control_schemas {
  my ($schema, $fixed) = @_;
  my $given = _schema_decl($schema, 'pg_extension_schemas') // {};
  for my $name (_schema_decl($schema, 'pg_extensions')) {
    refuse_control_schema($name, $given->{$name}, $fixed->{$name})
      if defined $given->{$name} && defined $fixed->{$name}
        && $given->{$name} ne $fixed->{$name};
  }
  return;
}

sub _schema_decl {
  my ($schema, $method, @args) = @_;
  my $from = $schema->can($method) ? $schema : 'DBIO::PostgreSQL';
  return $from->$method(@args);
}

# The namespace the connection of $schema works in: what its connect info
# gave as schema (core ADR 0065), or undef -- for a connection without the
# key, a schema that is not connected and a schema class. It is a fact of
# the connection and is read from the storage, never from the class: the
# same class is connected for several namespaces at once.
# DBIO::PostgreSQL::Deploy asks through this too.
sub _connection_namespace {
  my ($schema) = @_;
  my $storage = $schema->can('storage') ? $schema->storage : undef;
  return undef
    unless Scalar::Util::blessed($storage) && $storage->can('connection_schema');
  return $storage->connection_schema;
}

# On a connection that names its namespace the class names none: what it
# declares is written without a schema and lands where the connection works.
# A declaration that names a namespace of its own -- a pg_schema_class
# binding, the pg_schema of a result class, a source name that carries its
# schema -- says something else, and which of the two is meant is nobody's to
# guess: refused, naming both.
sub _refuse_namespace_declarations {
  my ($schema, $namespace) = @_;

  my $bound = _schema_decl($schema, '_pg_schema_classes') // {};
  for my $ns (sort grep { defined $bound->{$_} } keys %$bound) {
    die sprintf
      "refusing to write the install DDL: pg_schema_class binds schema %s to "
      . "%s, and this connection works in the namespace %s (connect key "
      . "schema). A schema class that names its namespaces is not installed "
      . "over a connection that names one: connect without the key, or leave "
      . "the binding out of the class.\n",
      $ns, $bound->{$ns}, $namespace;
  }

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $result_class = $source->result_class;
    my $name = $source->name;
    my $pg_schema = $result_class->can('pg_schema') ? $result_class->pg_schema : undef;

    die sprintf
      "refusing to write the install DDL: source %s (%s) declares pg_schema "
      . "%s, and this connection works in the namespace %s (connect key "
      . "schema). A source that names its schema is not installed over a "
      . "connection that names one: connect without the key, or leave the "
      . "pg_schema out of the class.\n",
      $source_name, $result_class, $pg_schema, $namespace
      if defined $pg_schema && length $pg_schema;

    die sprintf
      "refusing to write the install DDL: source %s (%s) is the table %s, a "
      . "name that carries its schema, and this connection works in the "
      . "namespace %s (connect key schema). A source that names its schema "
      . "is not installed over a connection that names one: connect without "
      . "the key, or name the table without a schema.\n",
      $source_name, $result_class, $name, $namespace
      if !ref $name && $name =~ /\./;
  }

  return;
}

# One piece of the script with the semicolon that ends it -- one, and where
# it does end the piece. install_ddl passes everything it has collected
# through here, so what is "a statement of the script" is said once.
#
# Declared SQL (pg_function, pg_extra_ddl, a view definition, an index's
# where) comes with or without a semicolon and may close with a line comment.
# A semicolon written behind that comment is part of the comment: the piece
# has no end then and runs into the statement after it -- for the server
# reading the script as one piece (psql -f, a single do()), and for the
# deploy, whose splitter reads a comment as the server does
# (DBIO::SQL::Util::_split_statements since core k326; the one before cut at
# every semicolon, in a comment or not, and was the only reader that did not
# notice). There the semicolon goes on a line of its own, which ends the
# piece for all of them.
sub _terminated {
  my ($sql) = @_;
  $sql =~ s/\A\s+//;
  $sql =~ s/[\s;]+\z//;
  return $sql . ($sql =~ /--[^\n]*\z/ ? "\n;" : ';');
}

# A note for whoever reads the script, as a piece of its own: a line comment,
# which _terminated closes with a semicolon on the next line. Read as one
# piece (psql -f, a single do()) that is an empty statement. The deploy sends
# the server no such piece, under either of its two ways of reading a script:
#
#   - since core k326 the splitter reads comments: it takes one off the
#     statement it stands ahead of and delivers no piece that holds nothing
#     else. There the note would be harmless without a semicolon of its own;
#   - before that DBIO::Deploy::Base::_execute_ddl cut at every semicolon and
#     left out each piece that began with "--". Without its own semicolon
#     the note was the head of the statement behind it, and that statement
#     was left out with it: the next foreign key, the settings, the
#     search_path (karr k120).
#
# The text is kept to one line, since past a line break it would be SQL for
# every reader. A semicolon in it is written out for the second reading
# alone, which cut the note there and ran the rest of it as a statement.
sub _note {
  my ($text) = @_;
  $text =~ s/\s*[\r\n]+\s*/ /g;
  $text =~ s/;/<semicolon>/g;
  return "-- $text";
}

# One entry of pg_search_path. An entry is a name and is written by the rule
# of every other name, quote_ident -- so MySchema stays MySchema. $user is the
# one entry that is no name: it stands for the schema of the session's role
# and is written as it is. An entry the user has quoted already would be
# quoted twice into another schema, so it is refused with the way out.
sub _search_path_entry {
  my ($entry) = @_;
  die sprintf
    "refusing to write the install DDL: pg_search_path entry %s is not a "
    . "name. Entries are schema names; write each as a plain string.\n",
    defined $entry && !ref $entry ? "'$entry'" : (defined $entry ? 'a reference' : 'undef')
    unless defined $entry && !ref $entry && length $entry && $entry !~ /\0/;
  return $entry if $entry eq '$user';
  _refuse_quoted_name('pg_search_path entry', $entry, substr($entry, 1, -1),
    'Entries are names', 'another schema')
    if $entry =~ /\A"/;
  return quote_ident($entry);
}

# One key of pg_settings, as SQL. A key is a name by the rule of
# pg_search_path, and a dotted one is a dotted name, as the server's grammar
# reads it (var_name: ColId, then '.' ColId): each part is written by
# quote_ident for itself, so app.current_user_id stays bare and DateStyle
# becomes "DateStyle". A part the user has quoted already is refused, as an
# entry of pg_search_path is.
sub _setting_key {
  my ($key) = @_;
  my @parts = defined $key && !ref $key && $key !~ /\0/ ? split(/\./, $key, -1) : ();
  die sprintf
    "refusing to write the install DDL: pg_settings key %s is not a name. "
    . "Keys are parameter names, parts joined by a dot; write each part as "
    . "a plain, non-empty string.\n",
    defined $key && !ref $key ? "'$key'" : (defined $key ? 'a reference' : 'undef')
    if !@parts || grep { !length } @parts;
  _refuse_quoted_name('pg_settings key', $key, $key =~ tr/"//dr,
    'Keys are names', 'another parameter')
    if grep { /\A"/ } @parts;
  return join '.', map { quote_ident($_) } @parts;
}

# A name a declaration gives that is in double quotes already: quoting it by
# the rule of every name would make another name of it.
sub _refuse_quoted_name {
  my ($what, $name, $unquoted, $are, $into) = @_;
  die sprintf
    "refusing to write the install DDL: %s %s is already quoted. %s and are "
    . "quoted by the driver, which would quote it a second time into %s; "
    . "write the name without quotes (%s).\n",
    $what, $name, $are, $into, $unquoted;
}

# One entry of pg_settings as a statement. A setting is stored on a database
# with ALTER DATABASE <name> SET, which takes a name and nothing that stands
# for "this one"; the script is written without a connection and also runs in
# the temporary database of Deploy->diff, so it cannot hold that name. The
# server is asked for it where the statement runs: a DO block builds the
# ALTER DATABASE around current_database().
#
# The key is a name (_setting_key) and goes into the statement as SQL (%s),
# handed to format() as a literal; the value is a literal (%L).
#
# The block is dollar-quoted with a tag its text does not contain, so a value
# cannot end it; and it is one piece for the deploy, whose splitter has read
# dollar quoting before it read anything else that could hold a semicolon
# (literals and comments since core k326).
sub _setting_sql {
  my ($key, $value) = @_;
  my $body = sprintf
    "BEGIN\n  EXECUTE format('ALTER DATABASE %%I SET %%s = %%L', current_database(), %s, %s);\nEND",
    quote_literal(_setting_key($key)), quote_literal($value);

  my ($tag, $n) = ('dbio', 0);
  $tag = 'dbio' . ++$n while index($body, "\$$tag\$") >= 0;
  return "DO \$$tag\$\n$body\n\$$tag\$";
}

# The result classes a view source names in deploy_depends_on. A class
# declaration hands DBIO::ResultSource::View->new an arrayref, which makes a
# hash of it; set on the source afterwards it stays what it was given.
sub _view_depends_on {
  my ($source) = @_;
  my $on = $source->deploy_depends_on;
  return sort keys %$on if ref $on eq 'HASH';
  return sort @$on      if ref $on eq 'ARRAY';
  return defined $on && !ref $on ? ($on) : ();
}

# The views in the order they can be created: each behind the views its
# deploy_depends_on names, and otherwise in the order they came in (that of
# their source names). $view_of_class says which view a result class is. A
# class that is no view of this script orders nothing -- a table is there
# before every view, and what the schema does not deploy is not the script's
# to create.
#
# deploy_depends_on is all there is to go by: a view definition is SQL as
# given, and which relations it reads only the server can say.
sub _views_in_dependency_order {
  my ($views, $view_of_class) = @_;
  my %state = (
    view  => { map { $_->{relation} => $_ } @$views },
    class => $view_of_class,
    done  => {},
    path  => [],
    order => [],
  );
  _visit_view(\%state, $_) for @$views;
  return @{ $state{order} };
}

sub _visit_view {
  my ($state, $view) = @_;
  my $relation = $view->{relation};
  return if $state->{done}{$relation};

  # Met again on the way down from itself: the views from there to here need
  # one another in a circle.
  my $path = $state->{path};
  my ($from) = grep { $path->[$_]{relation} eq $relation } 0 .. $#$path;
  _refuse_view_circle(@{$path}[ $from .. $#$path ]) if defined $from;

  push @$path, $view;
  for my $class (@{ $view->{depends_on} }) {
    my $on = $state->{view}{ $state->{class}{$class} // '' } or next;
    _visit_view($state, $on);
  }
  pop @$path;

  $state->{done}{$relation} = 1;
  push @{ $state->{order} }, $view;
}

sub _refuse_view_circle {
  my (@circle) = @_;
  my @needs = map {
    "$circle[$_]{relation} needs $circle[ ($_ + 1) % @circle ]{relation}"
  } 0 .. $#circle;
  die join "\n",
    'refusing to write the install DDL: deploy_depends_on runs in a circle through '
      . join(', ', map { "view $_->{relation} ($_->{class})" } @circle),
    '',
    'A view is created behind the views its deploy_depends_on names. As declared,',
    join(', ', @needs) . '.',
    'No order creates these views, and PostgreSQL has no view that reads itself. No',
    'script was written.',
    '',
    'Take out of a deploy_depends_on the class of a view that view does not read.',
    '';
}

# The names a relation is made of: the pg_schema of its result class, if it
# has one, then the source name taken apart at the name separator. That is
# how the SQL maker reads a source name for a query -- table('auth.users') is
# "auth"."users" there -- so the DDL arrives at the relation the queries read.
sub _relation_parts {
  my ($pg_schema_name, $name) = @_;
  return (($pg_schema_name ? $pg_schema_name : ()), split /\./, $name);
}

# A relation as it stands in a statement: every part of _relation_parts an
# identifier of its own. A scalar-ref source name is literal SQL -- the SQL
# maker writes it unquoted as well -- and stays as given.
sub _relation_sql {
  my ($pg_schema_name, $name) = @_;
  return quote_qualified(_relation_parts($pg_schema_name, $name))
    unless ref $name eq 'SCALAR';
  return join '.', ($pg_schema_name ? quote_ident($pg_schema_name) : ()), $$name;
}

sub _pg_column_type {
  my ($info, $context) = @_;
  my $type = $info->{data_type};

  # Handle enum types
  if ($type eq 'enum' && $info->{pg_enum_type}) {
    return $info->{pg_enum_type};
  }

  # Handle composite types
  if ($type eq 'composite' && $info->{pg_type_name}) {
    return $info->{pg_type_name};
  }

  # Handle arrays
  return $type if $type =~ /\[\]$/;

  # Handle parameterized types (varchar(N), numeric(P,S), vector(N))
  return $type if $type =~ /\(.+\)$/;

  # Portable base types: delegate to the adapter (single source of truth).
  # The canonical column carries a size for char and numeric only, so the
  # declared one goes along here: the adapter writes it where the native type
  # takes a modifier -- a timestamp's precision -- and nowhere else.
  if (DBIO::Schema::Type::is_base_type(lc $type)) {
    my $canon = DBIO::Schema::Type::canonical_column('_', $info);
    $canon->{size} = $info->{size} unless exists $canon->{size};
    return $ADAPTER->to_native($canon, $context);
  }

  # Legacy PG-dialect aliases: pass through as their native PG names
  my %type_map = (
    bigint            => 'bigint',
    smallint          => 'smallint',
    serial            => 'serial',
    bigserial         => 'bigserial',
    varchar           => 'character varying',
    float             => 'double precision',
    real              => 'real',
    date              => 'date',
    'timestamp with time zone' => 'timestamp with time zone',
    timestamptz       => 'timestamp with time zone',
    uuid              => 'uuid',
    json              => 'json',
    jsonb             => 'jsonb',
    bytea             => 'bytea',
    inet              => 'inet',
    cidr              => 'cidr',
    macaddr           => 'macaddr',
    tsvector          => 'tsvector',
    tsquery           => 'tsquery',
    xml               => 'xml',
    money             => 'money',
    interval          => 'interval',
    point             => 'point',
    line              => 'line',
    lseg              => 'lseg',
    box               => 'box',
    path              => 'path',
    polygon           => 'polygon',
    circle            => 'circle',
  );

  my $native = $type_map{$type} // $type;

  # Honor the `size` column-info attribute (DBIO::Core: "the length of your
  # column, if it is a column type that can have a size restriction";
  # DBIO::ResultSource: an ArrayRef selects precision/scale for decimal
  # types). Which type takes one, and where it is written, is the rule of
  # DBIO::PostgreSQL::Util -- every built-in type with a type modifier under
  # each of its names, and the pgvector types (karr k56, k58, k116). The
  # portable base types above reach the same rule through the adapter.
  #
  # Every other type keeps going without its size: a built-in one has no
  # modifier (integer(11) is a syntax error), and of a type nobody here
  # knows nothing can be said.
  return type_with_modifier($native, $info->{size}, $context)
    if type_takes_modifier($native);

  return $native;
}

# The timing clause of a UNIQUE constraint from the options of
# pg_unique_options, or of a FOREIGN KEY from the attributes of its belongs_to
# ($what names the one for the refusal). Not declared is no clause. Another
# option than deferrable and initially_deferred (@known), and
# initially_deferred without deferrable, are refused here, not left to the
# server (karr k147).
sub _timing_clause {
  my ($source, $what, $options, @known) = @_;
  $options //= {};
  if (my @unknown = grep { my $k = $_; !grep { $k eq $_ } @known } sort keys %$options) {
    $source->throw_exception(sprintf
      "refusing to write the install DDL: %s declares the option '%s', which is none of %s",
      $what, $unknown[0], join(', ', @known));
  }
  $source->throw_exception(sprintf
    "refusing to write the install DDL: %s declares initially_deferred without deferrable; "
    . "PostgreSQL has no constraint that is INITIALLY DEFERRED and NOT DEFERRABLE",
    $what) if $options->{initially_deferred} && !$options->{deferrable};
  return deferrable_clause($options->{deferrable}, $options->{initially_deferred});
}

sub _unique_timing {
  my ($source, $table_name, $name, $options) = @_;
  return _timing_clause($source, "pg_unique_options of constraint '$name' of $table_name",
    $options, qw( deferrable initially_deferred ));
}

# The " ON DELETE x" / " ON UPDATE x" tail of a FOREIGN KEY: the action the
# belongs_to declares, as declared. Not declared -- absent, undef, '' -- is
# no clause. The word is one of the five PostgreSQL has, in any case; another
# is refused here, naming the relationship, and not left to be a syntax error
# of the statement, or text that reaches the script (karr k140).
sub _fk_action {
  my ($source, $table_name, $rel_name, $event, $action) = @_;
  return '' unless defined $action && length $action;
  (my $word = uc $action) =~ s/\s+/ /g;
  unless (grep { $word eq $_ } 'NO ACTION', 'RESTRICT', 'CASCADE', 'SET NULL', 'SET DEFAULT') {
    (my $attr = lc $event) =~ tr/ /_/;
    $source->throw_exception(sprintf
      "refusing to write the install DDL: relationship '%s' of %s declares %s => '%s', "
      . "which is no action of a foreign key; PostgreSQL knows NO ACTION, RESTRICT, "
      . "CASCADE, SET NULL, SET DEFAULT",
      $rel_name, $table_name, $attr, $action);
  }
  return " $event $action";
}

# Reduce a belongs_to relationship_info condition to the column lists a
# plain FOREIGN KEY can express. Returns ($self_cols, $foreign_cols), both
# arrayrefs ordered self-column-name-sorted for determinism, or an empty
# list if $cond is anything other than a hashref of plain
# 'foreign.col' => 'self.col' pairs (e.g. a coderef or a hash with an
# expression on either side) -- add_relationship already enforces the
# foreign./self. prefixes, so the only real-world "complex" case is a
# non-hash condition.
sub _fk_column_pairs {
  my ($cond) = @_;
  return unless ref $cond eq 'HASH';

  my %self_to_foreign;
  for my $key (keys %$cond) {
    my $val = $cond->{$key};
    return if ref $key || ref $val;
    return unless $key =~ /^foreign\.(\w+)$/;
    my $f_col = $1;
    return unless $val =~ /^self\.(\w+)$/;
    $self_to_foreign{$1} = $f_col;
  }
  return unless %self_to_foreign;

  my @self_cols = sort keys %self_to_foreign;
  return (\@self_cols, [ map { $self_to_foreign{$_} } @self_cols ]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::DDL - Generate PostgreSQL DDL from DBIO schema classes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::PostgreSQL::DDL> generates PostgreSQL DDL statements directly from
DBIO schema and result classes, without going through SQL::Translator. This
produces correct, PostgreSQL-native SQL that preserves all PostgreSQL-specific
features.

The generated DDL is used by L<DBIO::PostgreSQL::Deploy/install> for fresh
installs and by the test-deploy side of L<DBIO::PostgreSQL::Deploy/diff> for
upgrade diffing. Reach for this class directly when you want the raw SQL text;
use L<DBIO::PostgreSQL::Deploy> when you want database orchestration.

=head1 METHODS

=head2 install_ddl

    my $sql = DBIO::PostgreSQL::DDL->install_ddl($schema);

Generates a complete PostgreSQL DDL script for the connected schema object.

This call asks no server, so it does not know the control file of an
extension. An extension whose control file fixes its schema (C<age> in
C<ag_catalog>, C<postgis_topology> in C<topology>, C<postgis_tiger_geocoder>
in C<tiger>) must name that schema here, in
C<< pg_extensions(age => { schema => 'ag_catalog' }) >>; one that names none
is written C<WITH SCHEMA public>, which the server refuses for such an
extension. L<DBIO::PostgreSQL::Deploy> has a server: it passes the fixed
schemas as the option C<extension_control_schemas> (a hash of extension name
to schema), so its install and the temporary database of its diff need no
declaration; a declared schema other than the fixed one is refused. For the
temporary database of a diff it passes a second option,
C<extension_installed_schemas> (extension name to schema): the schema the
database under diff holds an extension in. An extension that is neither
declared with a schema nor fixed by its control file is created there instead
of in C<public>, so that a column of one of its types has the same type name
on both sides. That schema is the database's, not a declaration:
C<pg_schemas> need not name it, and it is created (C<CREATE SCHEMA IF NOT
EXISTS>, not for C<public>) ahead of the extension. The declared schema and
the fixed one win over it.

The script is ordered to satisfy dependencies:

=over 4

=item 1. C<CREATE EXTENSION IF NOT EXISTS ... WITH SCHEMA> statements, one per
extension -- the schema L<DBIO::PostgreSQL/pg_extensions> names for it (after
the C<CREATE SCHEMA> of that schema, which must be declared by C<pg_schemas>
unless it is C<public>); else, from the option C<extension_installed_schemas>,
the one the database holds it in; else C<public>. An extension whose control
file fixes a schema, passed by the caller as C<extension_control_schemas>, is
written without the clause: the server installs it in that schema, creating
it, and refuses C<WITH SCHEMA> for one that does not exist yet

=item 2. C<CREATE SCHEMA IF NOT EXISTS> statements (skipping C<public>); on a connection that names its namespace each is a DO block that creates the schema only where C<pg_namespace> lacks it

=item 3. Enum types, composite types, and functions from L<DBIO::PostgreSQL::PgSchema> subclasses

=item 4. C<CREATE TABLE> statements with columns, primary keys, indexes, triggers, and RLS from L<DBIO::PostgreSQL::Result> classes

=item 5. C<FOREIGN KEY> constraints from C<belongs_to> relationships (on by default, off per class with C<pg_fk_constraints_from_rels(0)>, per relationship with C<< is_foreign_key_constraint => 0 >>, see L<DBIO::PostgreSQL::Result/pg_fk_constraints_from_rels>), emitted only after every table above has been created; one to a class that is not loaded or to a table outside the deploy is refused unless it says C<< is_foreign_key_constraint => 0 >>

=item 6. C<CREATE VIEW> for the non-virtual L<DBIO::ResultSource::View> sources, each behind the views its C<deploy_depends_on> names (see L</VIEWS>)

=item 7. One C<DO> block per entry of C<pg_settings>, which stores it on the database the script runs in (see L<DBIO::PostgreSQL/pg_settings>)

=back

The script does not end with C<SET search_path>, and nothing in it writes
L<DBIO::PostgreSQL/pg_search_path>: that list is the path of the
connections of the schema, set by the storage when each one opens
(L<DBIO::PostgreSQL::Storage/_apply_connection_schema>). A C<SET> would change the
C<search_path> of the session that runs the script -- for
L<DBIO::PostgreSQL::Deploy/install> the connection of the application -- and
nothing needs it: every object is created before where the end of the script
would have put it. The entries of C<pg_search_path> are still checked
(see L</"NAMES AND VALUES">), so a declaration refused before is refused now.

Returns the DDL as a single string with statements separated by blank lines.
Every piece of it ends in its own semicolon -- on a line of its own where the
declared SQL closes with a C<--> comment. A semicolon behind such a comment
on the same line belongs to the comment for everything that reads the script
as SQL: the server when it gets it as one piece (C<psql -f>, a single
C<< $dbh->do >>), and L<DBIO::PostgreSQL::Deploy>, which cuts it into
statements by the same reading (L<DBIO::Deploy::Base/_execute_ddl>). The
statement would have no end and run into the one after it.

A foreign key that item 5 skips -- only a C<belongs_to> whose condition is no
column equality -- leaves a note in the script,
C<-- skipped FK for rel ...>, which is such a piece too: a comment with a
semicolon of its own behind it. The deploy does not send it to the server and
runs the statement after it; read as one piece it is an empty statement.

What else the declared SQL may hold -- a comment line ahead of a statement, a
semicolon inside a string literal -- is the deploy's to read; see
L<DBIO::Deploy::Base/_execute_ddl> for what it reads and what it does not.
The body of a function or a procedure has to come dollar-quoted: a
C<BEGIN ATOMIC ... END> body is cut at its semicolons, and the install fails
on the server with a syntax error.

The schema need not load the L<DBIO::PostgreSQL> component. Items 1, 2, 3 and 7
come from the component's schema-level declarations; a schema without
them is given the component's own defaults, so it deploys exactly what a
component-loaded schema that declares nothing deploys.
This is the shape L<DBIO::Storage::Async/deploy_async> meets on a connection
opened with C<< { async => ... } >> and no C<load_components('PostgreSQL')>.

A schema connected with the connect key C<schema> gets the script of its
namespace: see L</A CONNECTION THAT NAMES ITS NAMESPACE>.

The schema is only read: nothing is written into its sources, and a second
call returns the same script.

See L</"NAMES AND VALUES"> for how names and values are written.

=head2 refuse_control_schema

    DBIO::PostgreSQL::DDL::refuse_control_schema($extension, $declared, $fixed);

Dies with the refusal for an extension whose declared schema is not the one
its control file fixes (C<pg_available_extension_versions.schema>): naming the
extension and both schemas. The server would refuse the C<CREATE EXTENSION>
(C<must be installed in schema ...>); this is said before any statement.

=head2 control_schemas_sql

    my $sql = DBIO::PostgreSQL::DDL::control_schemas_sql(@extensions);

The question to a server for the schemas the control files of the given
extensions fix: C<pg_catalog.pg_available_extension_versions>,
column C<schema>, for the version C<CREATE EXTENSION> installs, the default
one. Rows of C<(name, schema)>, only for an extension that has a fixed
schema. The names are written into the statement as literals, so it carries no
placeholder and goes out over any transport. Asked by
L<DBIO::PostgreSQL::Deploy/_extension_control_schemas> (over its connection) and
by L<DBIO::PostgreSQL::Storage::Async/deploy_async> (over a pooled one).

=head2 check_control_schemas

    DBIO::PostgreSQL::DDL::check_control_schemas($schema, \%fixed);

Dies with L</refuse_control_schema> for the first declared extension (in
declaration order) whose declared schema (L<DBIO::PostgreSQL/pg_extensions>) is
not the one C<%fixed> -- extension name to the schema its control file fixes --
holds for it. Nothing else is checked.

=head1 NAMES AND VALUES

Every name a declaration gives -- schema, table, view, column, index, trigger,
policy, constraint, enum and composite type, extension -- is written as an
identifier by the server's own rule
(L<DBIO::PostgreSQL::Util/quote_ident>): bare when it is plain lower case and
no key word, in double quotes otherwise. So C<user> and C<order> can be
columns, and a C<MixedCase> table is created as C<MixedCase>, which is the
name the queries ask for -- they quote every identifier. Written bare it
would be folded to C<mixedcase>.

A source name is taken apart at its dots the way the SQL maker takes it apart
for a query: C<< table('auth.users') >> is the table C<users> in the schema
C<auth>, each name quoted for itself. A C<pg_schema> goes in front. A
scalar-ref source name (C<< table(\'cd') >>) is literal SQL and is written as
given.

The roles of a policy (C<roles> in L<DBIO::PostgreSQL::Result/pg_rls>) are
names too, except C<PUBLIC>, C<CURRENT_USER>, C<CURRENT_ROLE> and
C<SESSION_USER>, which stand for a role and are written as given
(L<DBIO::PostgreSQL::Util/quote_role>).

A string C<default_value>, an enum value and a C<pg_settings> value are
written as string literals with an embedded apostrophe doubled
(L<DBIO::PostgreSQL::Util/quote_literal>).

The entries of C<pg_search_path> are names, checked by the same rule
(C<$user> excepted, which stands for the role's schema); none is written,
the script holds no such statement; the storage sets the declared path on
every connection instead (L<DBIO::PostgreSQL/pg_search_path>). The keys of
C<pg_settings> are names too, and a dotted key is a dotted name, each part
written by that rule for itself: C<app.current_user_id> stays bare,
C<DateStyle> is written C<"DateStyle">. A name already in double quotes -- an
entry, or a part of a key -- is refused, naming the unquoted form, rather
than quoted a second time into another name.

What a declaration documents as SQL is written as given: an index's C<where>,
C<expression>, C<using>, the values of C<with> and operator classes, a
policy's C<using> and C<with_check>, a trigger's C<when>, C<event> and
C<execute>, a CHECK constraint's definition, a C<< default_value => \'...' >>,
every type string (C<data_type>, C<pg_enum_type>, C<pg_type_name>, the field
types of a composite type), C<pg_extra_ddl>, a function's and a view's SQL.
None of it is checked; the server judges it. A name inside such a string that
needs quotes has to carry them.

Four declarations are not SQL and are checked: a column's C<size> (digits, or
two numbers of digits joined by a comma), a trigger's C<for_each> (C<ROW> or
C<STATEMENT>), a policy's C<for> (C<SELECT>, C<INSERT>, C<UPDATE>, C<DELETE>
or C<ALL>; upper or lower case) and the keys of an index's C<with>, which are
storage parameter names (letters, digits, underscores, one optional dot) and
written as given. A declaration
that breaks the rule is refused naming the option and the object, not the value.

The enum type generated for a column with C<< extra => { list => [...] } >>
and no C<pg_enum_type> is named C<{table}_{column}_enum> and lives in the
schema of its table.

=head1 COLUMN TYPES AND SIZE

A column's C<data_type> names its PostgreSQL type and is written as given
(an C<enum> or C<composite> column names it in C<pg_enum_type> or
C<pg_type_name>). The eight portable base types of L<DBIO::Schema::Type> are
the exception: C<integer>, C<text>, C<char>, C<boolean>, C<numeric>,
C<double>, C<blob> and C<timestamp> are deployed as
L<DBIO::PostgreSQL::Adapter> resolves them -- C<integer> as C<bigint>,
C<timestamp> as C<timestamptz>. C<varchar>, C<timestamptz> and C<float> are
written by their long names (C<character varying>, C<timestamp with time
zone>, C<double precision>).

A column's C<size> is written as the type's modifier, for every type that
takes one and under each of its names
(L<DBIO::PostgreSQL::Util/type_takes_modifier>), where the server's grammar
wants it (L<DBIO::PostgreSQL::Util/type_with_modifier>):

    { data_type => 'character', size => 10 }             # character(10)
    { data_type => 'varchar',   size => 255 }            # character varying(255)
    { data_type => 'bit',       size => 8 }              # bit(8)
    { data_type => 'varbit',    size => 8 }              # varbit(8)
    { data_type => 'decimal',   size => [ 10, 2 ] }      # decimal(10,2)
    { data_type => 'numeric',   size => 10 }             # numeric(10)
    { data_type => 'time',      size => 0 }              # time(0)
    { data_type => 'timestamp', size => 3 }              # timestamptz(3)
    { data_type => 'timestamp with time zone', size => 3 }
                                                         # timestamp(3) with time zone
    { data_type => 'interval',  size => 3 }              # interval(3)
    { data_type => 'vector',    size => 1536 }           # vector(1536)

A scalar is the one value the type takes, or the first of them -- the
precision of a C<numeric>; an arrayref names them in order. A C<size> that is
any other reference is refused.

A C<size> beside a type B<without> a modifier is not written. PostgreSQL has
no C<integer(11)> -- it is a syntax error -- and C<< data_type => 'integer',
size => 11 >> is what a schema carried over from another engine is full of;
such a column is deployed as its type alone.

Neither is a C<size> beside a type this distribution does not know (an
extension's other than pgvector's, a domain) or beside an array type. Write
the modifier into the C<data_type> there, which is taken as it stands:
C<< data_type => 'geometry(Point,4326)' >>, C<< data_type => 'varchar(10)[]' >>.

=head1 INDEXES

C<CREATE INDEX> comes from two declarations: C<pg_index>
(L<DBIO::PostgreSQL::Result/pg_index>) and the index declaration of the result
source that C<idx> of L<DBIO::Cake> and C<indices> write
(C<index_declarations>, ADR 0061 in core). The latter gives name, columns and
C<unique>, and its own C<< driver => { pg => {...} } >> block gives C<using>,
C<expression>, C<opclasses>, C<include>, C<with> and C<where>. Where both use
the same name, the canonical declaration wins. A schema is bound to one
driver, so what this driver does not write is refused, and the install DDL is
not written: C<options>, a C<type> other than C<unique>, an entry that carries
only another driver's block (such as C<< sqlite => { where => ... } >>), and a
key the C<pg> block does not know. An empty C<< pg => {} >> block is the plain
index of the columns and C<unique>.

The declaration is read from the source itself, not from the C<pg_indexes>
method the core derives from it for the transition.

An index over exactly the columns, in that order, of a unique constraint of
the same table is not written, plain or declared C<unique>: the C<CONSTRAINT
... UNIQUE> line has the index the server keeps for it, and a second one is a
duplicate. An index with an expression, a C<where>, another
access method, operator classes, C<include> columns or storage parameters is
another object and is written. A database installed before this has the
duplicate; an upgrade drops it by name.

=head1 VIEWS

A L<DBIO::ResultSource::View> source that is not virtual and has a
C<view_definition> is created with C<CREATE VIEW>, behind every table and
foreign key. A view without a C<pg_schema> is therefore created where the
session puts it (the first existing schema of its C<search_path>), like a
table without one; L<DBIO::PostgreSQL/pg_search_path> is not written into the
script, it is the path of the connections.

Among themselves the views come in the order of their source names, except
that a view stands behind every view its
L<deploy_depends_on|DBIO::ResultSource::View/deploy_depends_on> names:

    package MyApp::DB::Result::Top;
    __PACKAGE__->table_class('DBIO::ResultSource::View');
    __PACKAGE__->table('a_top');
    __PACKAGE__->result_source_instance->view_definition('SELECT id FROM z_base');
    __PACKAGE__->result_source_instance->deploy_depends_on(
        ['MyApp::DB::Result::Base'],              # the view z_base
    );

That declaration is all there is to go by: a definition is SQL as given, and
which relations it reads only the server knows. A view on a view that does
not declare it is created in the order of the names and, when that is the
wrong one, fails on the server with C<relation ... does not exist>.

A class C<deploy_depends_on> names that is no view of this script -- a table,
a virtual view, a class the schema does not hold -- orders nothing.

B<Refused>, with C<refusing to write the install DDL: ...> and no script:
views whose C<deploy_depends_on> run in a circle, the message naming the views
and their classes; and a view that two sources declare (the same relation
name in the same C<pg_schema>), whether or not both carry a definition and
whether or not it is the same one -- the message names the view and both
sources with their result classes.

=head1 A CONNECTION THAT NAMES ITS NAMESPACE

A schema connected with the connect key C<schema> works in one namespace, and
the script written for it installs into that namespace
(L<DBIO::PostgreSQL/ONE SCHEMA CLASS IN SEVERAL NAMESPACES>):

    my $schema = MyApp::DB->connect($dsn, $user, $pass, { schema => 'tenant_a' });
    print DBIO::PostgreSQL::DDL->install_ddl($schema);

    CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;

    DO $dbio$
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = 'tenant_a') THEN
        CREATE SCHEMA tenant_a;
      END IF;
    END
    $dbio$;

    SET search_path TO tenant_a, public;

    CREATE TABLE things (
      ...
    );

The script carries itself. It installs into the namespace over the connection
it was written for, over a connection that was never given the path -- the
temporary database of L<DBIO::PostgreSQL::Deploy/diff> -- and as a file given
to C<psql -f>.

=over 4

=item *

Every extension is created C<WITH SCHEMA>: the schema it names in
L<DBIO::PostgreSQL/pg_extensions>, C<public> where it names none. An
extension belongs to the database, and without the clause the server would
put it into the first schema of the C<search_path>.

=item *

The namespace is created (not C<public>), and so is the schema of an extension,
each only where C<pg_namespace> does not have it (a DO block with the lookup,
L<DBIO::PostgreSQL::Util/create_schema_if_missing>): C<CREATE SCHEMA> asks for
C<CREATE> on the database even when the schema is there, so a role that may
use a namespace made for it could not install. It is created
ahead of everything that is written without a schema. PostgreSQL creates an
unqualified object in the first schema of the C<search_path> that exists and
passes over one that does not: with the namespace missing, the tables would be
created in the schema behind it and nothing would say so.

=item *

C<SET search_path TO> the path of the connection
(L<DBIO::PostgreSQL::Util/connection_search_path>): the namespace, then the
schemas of the declared extensions. It stands behind C<CREATE SCHEMA> and
ahead of the first object, and is not repeated at the end. It is the one
C<SET search_path> a script holds: the temporary database of a diff is reached
by a connection of its own and has no other way to learn the namespace, and
on the connection the script was written for it sets what the connection has
already. L<DBIO::PostgreSQL/pg_search_path> is not read.

=item *

Tables, indexes, views, foreign keys and the types of enum columns are
written as on every connection: without a schema, since the class names none.

=back

B<Refused>, with C<refusing to write the install DDL: ...> and no script,
each naming what was declared and the namespace of the connection:

=over 4

=item *

an extension whose schema -- the one it names, or C<public> -- is the
namespace;

=item *

a L<DBIO::PostgreSQL/pg_schema_class> binding;

=item *

a source whose result class declares a
L<pg_schema|DBIO::PostgreSQL::Result/pg_schema>, and one whose name carries
its schema (C<< table('auth.users') >>).

=back

The entries of L<DBIO::PostgreSQL/pg_schemas> refuse nothing; each is created
as a schema, as on every connection.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL> - schema component that calls C<pg_install_ddl>

=item * L<DBIO::PostgreSQL::Deploy> - uses C<install_ddl> for fresh installs and diff

=item * L<DBIO::PostgreSQL::PgSchema> - source of enum, type, and function definitions

=item * L<DBIO::PostgreSQL::Result> - source of table, index, trigger, and RLS definitions

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
