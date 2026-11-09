package DBIO::Oracle::DDL;
# ABSTRACT: Generate Oracle DDL from DBIO Result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Oracle::Type;
use DBIO::Oracle::Identifier;


# Every identifier is written quoted, exactly as the result class spells it
# (karr k42): the storage quotes with sql_quote_char '"' and so asks the
# dictionary for the lower-case name, while an unquoted CREATE folds it to
# upper case. DBIO::SQL::Util::_quote_ident leaves a simple name unquoted and
# is therefore the wrong tool here.
sub _q {
  my ($name) = @_;
  $name =~ s/"/""/g;
  return qq{"$name"};
}

# A table name that holds a dot is schema.table (karr k58): the table lives in
# that schema, which on Oracle is a user. Schema and table are quoted apart,
# each as spelled -- "OWNX"."item", never "OWNX.item".
sub _qt { DBIO::Oracle::Identifier::quote_table($_[0]) }

# A name in the schema of the table whose key is $table: sequence, trigger,
# index.
sub _qin { DBIO::Oracle::Identifier::quote_in(@_) }

# Records an object of the install in $objects. A name of the connected
# user's schema goes to $objects->{$type}; one in another schema ('schema.x',
# $name still qualified) to $objects->{schema}{$schema}{$type} by its bare
# name, which is how the cleanup finds it. $index_table, for an index, is the
# bare table it is on.
sub _note_object {
  my ($objects, $type, $name, $index_table) = @_;
  my ($schema, $bare) = DBIO::Oracle::Identifier::split_table($name);
  my $slot = defined $schema ? \@{ $objects->{schema}{$schema}{$type} } : \@{ $objects->{$type} };
  push @$slot, defined $index_table ? [ $bare, $index_table ] : $bare;
  return;
}

# What Oracle cannot hold is refused here, as a DBIO exception that names the
# table and the column, before any statement is built (core ADR 0060, karr
# k56): the server's answer to each of them is an error of its own
# (ORA-00902, ORA-25716, ORA-03060), or, for a dot in a table name, a table
# nobody can reach. The names are the ones of the declaration.
sub _refuse_unsupported {
  my ($source, $table_name, $literal) = @_;
  my @cols = $source->columns;

  # one message for every offending name, so that it names them all
  my @bad;
  push @bad, "the table name '$table_name'" if !$literal && $table_name =~ /["\0]/;
  push @bad, map { "the column name '$_'" } grep { /["\0]/ } @cols;
  $source->throw_exception(sprintf
    "%s: %s hold%s a double quote or NUL character; Oracle refuses that in any identifier, "
    . "quoted or not (ORA-25716) -- refused, nothing is installed",
    $table_name, join(' and ', @bad), (@bad == 1 ? 's' : ''))
    if @bad;

  $source->throw_exception(sprintf
    "%s: the table name is schema-qualified (schema.table) but a half of it is empty; "
    . "refused -- a table in another schema is written schema.table, the dot is not part of a name",
    $table_name)
    if !$literal && $table_name =~ /\./ && !($table_name =~ /\A[^.]+\.[^.]/s);

  for my $col (@cols) {
    my $type = $source->column_info($col)->{data_type};
    next unless defined $type;
    # compared as it means: letter case, blanks and a trailing (n) or (a,b)
    # are not part of the type
    (my $kind = lc $type) =~ s/\s+/ /g;
    $kind =~ s/\A | \z//g;
    $kind =~ s/ ?\(.*\)\z//s;
    $source->throw_exception(sprintf
      "%s: column '%s' is of type %s, which has no counterpart on Oracle (Oracle has no "
      . "%s type); the driver refuses it rather than write a type the server rejects",
      $table_name, $col, $type, $kind)
      if $kind eq 'enum' || $kind eq 'set';
    $source->throw_exception(sprintf
      "%s: column '%s' is of type %s, which has no counterpart on Oracle (Oracle has no BIT "
      . "type); the driver refuses it rather than write a type the server rejects",
      $table_name, $col, $type)
      if $kind =~ /\A(?:bit(?: varying)?|varbit)\z/;
  }
  return;
}


sub install_ddl {
  my ($class, $schema) = @_;
  return $class->_build($schema, {});
}


sub declared_objects {
  my ($class, $schema) = @_;
  my $objects = {};
  $class->_build($schema, $objects);
  return $objects;
}


sub foreign_schemas {
  my ($class, $schema) = @_;
  return sort keys %{ $class->declared_objects($schema)->{schema} || {} };
}

sub _build {
  my ($class, $schema, $objects) = @_;
  my @stmts;
  my @view_stmts;
  my %seen_table;
  my %seen_view;
  my @fk_sources;

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $table_name = $source->name;

    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = ref $table_name eq 'SCALAR' ? $$table_name : $table_name;
      next if ref $vname || $seen_view{$vname}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;', _qt($vname), $def;
      _note_object($objects, 'view', $vname);
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd', emitted
    # unquoted) or an inline subquery source; deref the former, skip the latter.
    my $literal_name;
    if (ref $table_name eq 'SCALAR') {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
      $literal_name = 1;
    }
    next if ref $table_name;

    _refuse_unsupported($source, $table_name, $literal_name);

    # Several result sources can map to one physical table; emit it once.
    next if $seen_table{$table_name}++;

    # Detect autoincrement columns
    my @autoinc_cols;
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      push @autoinc_cols, $col_name if $info->{is_auto_increment};
    }

    # Column definitions
    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      # a type the mapping refuses (float of a precision Oracle does not have)
      # is refused with the table and the column of the declaration
      my $type = eval {
        DBIO::Oracle::Type::map_dbio_type_to_oracle($info->{data_type}, size => $info->{size});
      };
      unless (defined $type) {
        (my $why = "$@") =~ s/\s+\z//;
        $source->throw_exception(sprintf "%s: column '%s': %s", $table_name, $col_name, $why);
      }
      my $def = sprintf '  %s %s', _q($col_name), $type;

      if ($info->{is_auto_increment}) {
        # SERIAL/BIGSERIAL mapped to NUMBER + sequence (type already set)
      }

      # DEFAULT before NOT NULL: Oracle's column definition is
      # "datatype [DEFAULT expr] [inline_constraint ...]" and it refuses the
      # other order.
      if (defined $info->{default_value} && !$info->{is_auto_increment}) {
        $def .= ' DEFAULT ' . DBIO::Oracle::Type::render_default_value($info->{default_value});
      }

      $def .= ' NOT NULL' if !$info->{is_nullable};

      push @col_defs, $def;
    }

    # The canonical index declarations of the source (Cake idx, indices;
    # ADR 0061 in core, karr k51). The helper refuses an entry that carries
    # only another driver's block and an unknown key in the oracle block;
    # its message is passed through. An empty oracle block is the plain
    # index. type (other than unique) and options have no counterpart here
    # and are refused, never written as a plainer index.
    my @declared;
    if ($source->can('index_declarations_for')) {
      for my $decl ($source->index_declarations_for('oracle', [qw(expression)])) {
        if (defined $decl->{type} && $decl->{type} !~ /^unique$/i) {
          $source->throw_exception(sprintf
            "%s: index '%s': type '%s' has no Oracle counterpart; refused, not written as a plainer index",
            $table_name, $decl->{name}, $decl->{type});
        }
        if (defined $decl->{options}) {
          $source->throw_exception(sprintf
            "%s: index '%s': options are not supported by the Oracle DDL; refused, not dropped silently",
            $table_name, $decl->{name});
        }
        push @declared, $decl;
      }
    }

    # The unique constraints of the source (add_unique_constraint, Cake
    # uniq; karr k46), the primary one excepted: it is the PRIMARY KEY below.
    # A table-level constraint makes Oracle create the unique index of the
    # same name. An index declaration of the same name, or over exactly the
    # columns of a constraint, is refused (below) rather than left to the
    # server (ORA-01408) or let to displace the constraint. A column set that
    # is already the primary key or an earlier constraint is not written
    # again -- Oracle refuses it (ORA-02261).
    my (@unique_defs, @unique_names);
    {
      my %seen;
      $seen{ join "\0", sort @pk_cols } = 1 if @pk_cols;
      my %uc = $source->unique_constraints;
      for my $uc_name (sort keys %uc) {
        next if $uc_name eq 'primary';
        my @cols = @{ $uc{$uc_name} };
        next unless @cols;
        my $cname = DBIO::Oracle::Identifier::shorten($uc_name);
        for my $decl (@declared) {
          my $own = ($decl->{driver} || {})->{oracle} || {};
          my $same_name = $decl->{name} eq $cname || $decl->{name} eq $uc_name;
          my $same_cols = !defined $own->{expression}
            && join("\0", @{ $decl->{columns} || [] }) eq join("\0", @cols);
          next unless $same_name || $same_cols;
          $source->throw_exception(sprintf
            "%s: refused, index '%s' %s unique constraint '%s' (%s); Oracle holds one index "
            . "there (ORA-01408) -- declare the key once, as the unique constraint or as the index",
            $table_name, $decl->{name},
            ($same_name ? 'has the name of' : 'is over the columns of'),
            $uc_name, join(', ', @cols));
        }
        next if $seen{ join "\0", sort @cols }++;
        push @unique_names, $cname;
        push @unique_defs, sprintf '  CONSTRAINT %s UNIQUE (%s)',
          _q($cname), join(', ', map { _q($_) } @cols);
      }
    }

    # Primary key constraint
    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _q($_) } @pk_cols);
    }

    push @col_defs, @unique_defs;

    # A literal table name (\'cd') is the user's own SQL and stays as given,
    # which is what the storage writes for it as well.
    my $qualified = $literal_name ? $table_name : _qt($table_name);
    my ($tschema, $bare) = $literal_name
      ? (undef, $table_name) : DBIO::Oracle::Identifier::split_table($table_name);
    my $sql = sprintf "CREATE TABLE %s (\n%s\n);", $qualified, join(",\n", @col_defs);
    push @stmts, $sql;
    my $own_table = $literal_name ? uc $table_name : $bare;
    _note_object($objects, "table", $literal_name ? $own_table : $table_name);
    # a unique constraint is backed by the index of its name
    _note_object($objects, "index", defined $tschema ? "$tschema.$_" : $_, $own_table) for @unique_names;

    # Sequences for autoincrement columns, each with the BEFORE INSERT
    # trigger that fills the column from it (karr k42). The storage finds the
    # sequence of a column by reading exactly that trigger (ALL_TRIGGERS),
    # so a create() without RETURNING can read the key back. The trigger
    # leaves a value the caller gave alone.
    for my $col_name (@autoinc_cols) {
      my $seq_name = DBIO::Oracle::Identifier::shorten("${bare}_${col_name}_seq");
      push @stmts, sprintf "CREATE SEQUENCE %s;", _qin($table_name, $seq_name);
      _note_object($objects, "sequence", defined $tschema ? "$tschema.$seq_name" : $seq_name);
      my $trg_name = DBIO::Oracle::Identifier::shorten("${bare}_${col_name}_trg");
      _note_object($objects, "trigger", defined $tschema ? "$tschema.$trg_name" : $trg_name);
      push @stmts, sprintf
        "CREATE OR REPLACE TRIGGER %s\n"
      . "BEFORE INSERT ON %s FOR EACH ROW WHEN (new.%s IS NULL)\n"
      . "BEGIN\n"
      . "  SELECT %s.NEXTVAL INTO :new.%s FROM DUAL;\n"
      . "END;",
        _qin($table_name, $trg_name), $qualified, _q($col_name),
        _qin($table_name, $seq_name), _q($col_name);
    }

    # The declared name is the user's and is used as given; Oracle itself
    # refuses one that is too long.
    for my $decl (@declared) {
      my $own = ($decl->{driver} || {})->{oracle} || {};
      my $cols = defined $own->{expression}
        ? $own->{expression}
        : join ', ', map { _q($_) } @{ $decl->{columns} };
      push @stmts, sprintf 'CREATE %sINDEX %s ON %s (%s);',
        $decl->{unique} ? 'UNIQUE ' : '', _qin($table_name, $decl->{name}),
        $qualified, $cols;
      _note_object($objects, "index", defined $tschema ? "$tschema.$decl->{name}" : $decl->{name}, $own_table);
    }

    push @fk_sources, [ $table_name, $source, $qualified ];
  }

  # Foreign keys, after every CREATE TABLE (karr k42): a table may refer to
  # one that sorts after it, or to itself, so no table order would do.
  for my $triple (@fk_sources) {
    my ($table_name, $source, $qualified) = @$triple;
    push @stmts, map {
      sprintf 'ALTER TABLE %s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s (%s)%s;',
        $qualified, _q($_->{constraint_name}),
        join(', ', map { _q($_) } @{ $_->{from_columns} }),
        $_->{to_qualified},
        join(', ', map { _q($_) } @{ $_->{to_columns} }),
        $_->{actions};
    } _table_foreign_keys($schema, $source, \%seen_table);
  }

  return join "

", @stmts, @view_stmts;
}

# True when $target (the table a belongs_to points at) has a has_many back to
# $table over the same column pairs with cascade_delete: the other side of
# the belongs_to, which is what Relationship::Base describes as the
# autodetection of on_delete.
sub _cascading_has_many {
  my ($target, $table, $from, $to) = @_;
  my $want = join "\0", sort map { "$from->[$_]\t$to->[$_]" } 0 .. $#$from;
  for my $rel ($target->relationships) {
    my $info = $target->relationship_info($rel) or next;
    next unless $info->{attrs} && $info->{attrs}{cascade_delete};
    next unless ref $info->{cond} eq 'HASH';
    my $other = eval { $target->related_source($rel) } or next;
    my $oname = $other->name;
    $oname = $$oname if ref $oname eq 'SCALAR';
    next unless !ref $oname && $oname eq $table;
    my @pairs;
    for my $k (keys %{ $info->{cond} }) {
      my ($f) = $k =~ /\Aforeign\.(\w+)\z/ or next;
      my ($s) = ($info->{cond}{$k} // '') =~ /\Aself\.(\w+)\z/ or next;
      push @pairs, "$f\t$s";    # our column, the target's column
    }
    return 1 if (join "\0", sort @pairs) eq $want;
  }
  return 0;
}

sub _source_table {
  my ($source) = @_;
  my $name = $source->name;
  return ref $name eq 'SCALAR' ? $$name : $name;
}

sub _fk_on_delete {
  my ($source, $rel, $action) = @_;
  return '' unless defined $action && length $action;
  return ' ON DELETE ' . uc $action if $action =~ /\A(?:cascade|set null)\z/i;
  return '' if $action =~ /\A(?:no action|restrict)\z/i;
  $source->throw_exception(sprintf
    "%s: relationship '%s': on_delete '%s' has no Oracle counterpart (ON DELETE takes CASCADE and SET NULL); "
    . "refused, not left out silently", _source_table($source), $rel, $action);
}

sub _fk_on_update {
  my ($source, $rel, $action) = @_;
  return '' unless defined $action && length $action;
  return '' if $action =~ /\A(?:no action|restrict)\z/i;
  $source->throw_exception(sprintf
    "%s: relationship '%s': on_update '%s' has no Oracle counterpart (Oracle has no ON UPDATE); "
    . "refused, not left out silently", _source_table($source), $rel, $action);
}

# The FK constraints of one source, from its relationships marked
# is_foreign_key_constraint (belongs_to sets it unless told otherwise), the
# signal the other drivers' DDL reads too. A relationship is left out when it
# cannot be one constraint:
#
# - its condition is not plain 'foreign.x' => 'self.y' pairs (a coderef);
# - its target table is not part of this deploy (%$deployed): not in the
#   schema, a view, or an inline subquery source;
# - its target columns are neither the target's primary key nor one of its
#   unique constraints (Oracle refuses a reference without a key behind it,
#   ORA-02270, and a belongs_to may legitimately join on any column).
#
# Two relationships over the same columns to the same target are one
# constraint. Pairs are ordered by the target's key order, so a composite
# reference matches its key. The name is fk_<table>_<columns>_<target>,
# shortened to the 30 characters of Identifier::shorten like every generated
# name. ON DELETE and DEFERRABLE follow the relationship (see POD).
sub _table_foreign_keys {
  my ($schema, $source, $deployed) = @_;
  return unless $source->can('relationships');
  my $table_name = $source->name;
  $table_name = $$table_name if ref $table_name eq 'SCALAR';
  my (@fks, %named);

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
    my $to_literal = ref $to_table eq 'SCALAR';
    $to_table = $$to_table if $to_literal;
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
    my $key = join "\0", @from, '->', $to_table, @to;
    # The actions the belongs_to declares (karr k42); on_delete that it does
    # not declare at all is read off the has_many on the other side.
    my $attrs = $info->{attrs};
    my $on_delete = exists $attrs->{on_delete}
      ? $attrs->{on_delete}
      : _cascading_has_many($fs, $table_name, \@from, \@to) ? 'CASCADE' : undef;
    my $actions = _fk_on_delete($source, $rel, $on_delete)
      . _fk_on_update($source, $rel, $attrs->{on_update})
      . ($attrs->{is_deferrable} ? ' DEFERRABLE' : '');

    # The name is made of the table, the columns and the target, so that two
    # keys over the same columns to different tables do not meet in one name
    # (ORA-02264). Two relationships to the same target with other actions
    # would still need one name twice: refused, not dropped.
    my $cname = DBIO::Oracle::Identifier::shorten(join '_', 'fk',
      (DBIO::Oracle::Identifier::split_table($table_name))[1], @from,
      $to_literal ? $to_table : (DBIO::Oracle::Identifier::split_table($to_table))[1]);
    if (defined(my $earlier = $named{$cname})) {
      next if $earlier->[0] eq $key . $actions;
      $source->throw_exception(sprintf
        "%s: refused, relationships '%s' and '%s' declare the foreign key on (%s) to %s twice with "
        . "other actions; Oracle holds one constraint of a name -- declare one of them",
        $table_name, $earlier->[1], $rel, join(', ', @from), $to_table);
    }
    $named{$cname} = [ $key . $actions, $rel ];

    push @fks, {
      constraint_name => $cname,
      from_columns    => \@from,
      to_qualified    => ($to_literal ? $to_table : _qt($to_table)),
      to_columns      => \@to,
      actions         => $actions,
    };
  }
  return @fks;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::DDL - Generate Oracle DDL from DBIO Result classes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Oracle::DDL> generates Oracle DDL from the DBIO schema class hierarchy.
It is what L<DBIO::Oracle::Deploy> runs as its C<install>.

    my $ddl = DBIO::Oracle::DDL->install_ddl($schema);
    # CREATE TABLE ...; CREATE SEQUENCE ...; CREATE INDEX ...;

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::Oracle::DDL->install_ddl($schema);

Returns the full installation DDL as a single string. C<$schema> may be
a connected schema instance or a schema class name.

=head2 declared_objects

    my $objects = DBIO::Oracle::DDL->declared_objects($schema);
    # { table => [...], view => [...], sequence => [...], trigger => [...],
    #   index => [ [ name, table ], ... ],
    #   schema => { OWNX => { table => [...], sequence => [...], ... } } }

The names, as the dictionary holds them, of the objects L</install_ddl> writes
for C<$schema>, taken while the statements are built, so that a generated
name (the shortened sequence and trigger names) is the one in the statements
and not a second computation of it. A name written unquoted (a literal table
name, C<< \'cd' >>) is given in upper case, as Oracle folds it. Throws what
L</install_ddl> throws for a declaration it refuses. The caller that needs to
know what an install created (the cleanup of
L<DBIO::Oracle::Test::Conformance>) reads it here.

The objects of a table in another schema (a source C<OWNX.item>) are
not in the lists above but under C<schema>, by schema and then by type, with
the bare names (the C<index> pairs hold the bare table too).

=head2 foreign_schemas

    my @schemas = DBIO::Oracle::DDL->foreign_schemas($schema);

The schemas (users) that the table names of the install qualify, as
they spell them, sorted: the C<OWNX> of a source C<OWNX.item>. Empty when no table or view is schema-qualified.
L<DBIO::Oracle::Deploy/install> asks the server for each of them before the
first statement. Throws what L</install_ddl> throws for a declaration it
refuses.

=head1 INDEX DECLARATIONS

The canonical index declarations of a result source (L<DBIO::Cake> C<idx>,
C<indices>, C<< ->indices >> of L<DBIO::ResultSourceProxy>; ADR 0061 in core)
are written as C<CREATE [UNIQUE] INDEX name ON table (columns);> after
the table. The declared name is used as given. A declaration of the same
name as a unique constraint, or over exactly the columns of one (in that
order), is refused with an exception naming both, because Oracle holds one
index there (ORA-01408) and neither would be the declared one; declare the key
once. A function-based index (C<expression>) is not on the columns.

The C<oracle> block takes one key: C<expression>, a function-based index,
whose text stands in the parentheses instead of the column list. It is the
user's own SQL and is not quoted for them: a column spelled in lower case
has to be written C<"quoted"> in it (C<LOWER("title")>), because the table
is created with quoted names. There is no
C<where>: Oracle has no partial index, and the key is refused as unknown. A
C<type> other than C<unique> and any C<options> are refused with an
exception, never written as a plainer index.

=head1 IDENTIFIERS, AUTO-INCREMENT, FOREIGN KEYS

Every table, column, sequence, trigger, constraint and index name is written
double-quoted, with the spelling of the result class. The storage
quotes with C<sql_quote_char> C<"> and so asks the dictionary for that
spelling; an unquoted name would have been folded to upper case, and the
schema that was just installed could not read it (ORA-00942). A table given
as a literal scalar reference (C<< \'cd' >>) is the user's own SQL and stays as
given, as the storage writes it.

Because the names are quoted, a C<view_definition> and any literal SQL (a
function-based index C<expression>, a literal table name) must quote a
lower-case or mixed-case name itself: C<SELECT "title" FROM "cd"> -- unquoted
Oracle reads the name as upper case and finds nothing (ORA-00942).

A column marked C<is_auto_increment> gets C<CREATE SEQUENCE table_column_seq>
and a C<BEFORE INSERT> trigger C<table_column_trg>, C<< WHEN (new.col IS NULL) >>,
that fills the column with C<NEXTVAL> (an explicit value is left alone). The
storage finds the sequence of such a column by reading exactly that trigger in
C<ALL_TRIGGERS>, so C<create> without C<RETURNING> can read the key back. The
C<CREATE TRIGGER> text ends in C<END;>; core's splitter, told the dialect
C<oracle> by C<_ddl_sql_dialect> of L<DBIO::Oracle::Storage>, keeps that
semicolon when the statement is run.

Foreign keys come last, one C<ALTER TABLE ... ADD CONSTRAINT fk_table_columns_target
FOREIGN KEY (...) REFERENCES ...> each, after every C<CREATE TABLE> (a table may
refer to one that sorts after it, or to itself). They are read from the
relationships marked C<is_foreign_key_constraint> (C<belongs_to> sets it by
default); C<ON DELETE> and C<DEFERRABLE> follow them (below). A relationship whose condition is not plain
column pairs, whose target is not a table of the deploy, or whose target
columns are neither the target's primary key nor one of its unique constraints
yields no constraint. Names are shortened to Oracle's 30 characters like every
generated name.

=head2 ON DELETE, ON UPDATE, DEFERRABLE

The C<on_delete>, C<on_update> and C<is_deferrable> attributes of the
C<belongs_to> are written as declared, as the other drivers do:

    __PACKAGE__->belongs_to(owner => 'MyApp::DB::Result::Owner', 'owner_id',
      { on_delete => 'SET NULL', is_deferrable => 1 });

    # ... FOREIGN KEY ("owner_id") REFERENCES "owner" ("id") ON DELETE SET NULL DEFERRABLE

=over 4

=item * An C<on_delete> that the C<belongs_to> does not declare at all is
detected as L<DBIO::Relationship::Base> describes it: when the target has a
C<has_many> back over the same columns with C<cascade_delete> (its default),
the key is C<ON DELETE CASCADE>. Without that the ORM, which deletes the parent
first and the children after, runs into ORA-02292 on every cascading
C<< $row->delete >>. C<< on_delete => undef >> or C<''> switches this off.
A C<cascade_copy> does not turn into C<ON UPDATE CASCADE>.

=item * Oracle knows C<ON DELETE CASCADE> and C<ON DELETE SET NULL> only.
C<NO ACTION> and C<RESTRICT> are Oracle's behaviour already and write no
clause; any other C<on_delete> (C<SET DEFAULT>) is refused with an exception.

=item * Oracle has no C<ON UPDATE>. A declared C<on_update> other than
C<NO ACTION> or C<RESTRICT> is refused with an exception, never left out
silently.

=item * A true C<is_deferrable> writes C<DEFERRABLE> (initially immediate),
what C<with_deferred_fk_checks> needs.

=item * Two relationships to the same target over the same columns with
different actions would need one constraint name twice and are refused.

=back

=head1 TABLES IN ANOTHER SCHEMA

A source named C<schema.table> (C<< __PACKAGE__->table('OWNX.item') >>) is a
table in the schema C<OWNX>; on Oracle a schema is a user. The text before the
first dot is the schema, the rest the table, and each is quoted exactly as
spelled, like every name here: C<"OWNX"."item">. The schema is the name the
dictionary holds, so a user made unquoted is written in upper case. Every
statement of the table carries it: C<CREATE TABLE>, the sequence and the
trigger of an auto-increment column (C<"OWNX"."item_id_seq">,
C<"OWNX"."item_id_trg">, the trigger reading C<"OWNX"."item_id_seq".NEXTVAL>),
the indexes (C<CREATE INDEX "OWNX"."idx" ON "OWNX"."item">) and the foreign
keys, which may point from one schema to another in either direction
(C<REFERENCES "OWNX"."parent">). Generated names are made from the bare table
name. A unique constraint lives in the table and is not qualified.

The schema is not created: the user has to exist, which
L<DBIO::Oracle::Deploy/install> checks before the first statement and refuses
with a DBIO exception naming the user when it does not. This class only writes
the statements. The connected user needs the C<ANY> privileges to write into
another user's schema (C<CREATE ANY TABLE>, C<ALTER ANY TABLE> for the foreign
keys, C<CREATE ANY INDEX>, C<CREATE ANY SEQUENCE>, C<CREATE ANY TRIGGER>; the
server answers ORA-01031 without them).
A foreign key to a table of another schema also needs the C<REFERENCES>
privilege of the owner of the referencing table on the parent; that is the
server's business, not checked here.

=head1 REFUSALS

What Oracle cannot hold is refused with a DBIO exception before any statement
is built (core ADR 0060), naming the table and, where there is one,
the column (or, for a relationship, the relationship) of the declaration; the
text says "refus" (refuses, refused). The server would answer each of them with
an error of its own, or, for the dot, create something nobody can reach.

=over 4

=item * a column of type C<enum> or C<set> -- Oracle has no such type;

=item * a column of type C<bit> (C<bit varying>, C<varbit>) -- Oracle has no BIT
type. The type is compared as it means, not as it is spelled: letter case,
blanks and a trailing C<(n)> do not matter (C<' ENUM'>, C<bit(8)>, C<bit
varying (8)>);

=item * a table or column name with a double quote or a NUL character -- Oracle
takes any other character in a quoted name, a space included, but never
these (ORA-25716);

=item * a schema-qualified table name with an empty half (C<.t>, C<x.>) -- a
name with a dot is C<schema.table> (see L</TABLES IN ANOTHER SCHEMA>), and
neither half may be empty. A literal table name (C<< \'other.t' >>) is the
user's own SQL and not checked;

=item * an index declaration over exactly the columns of a unique constraint,
or of its name (see L</INDEX DECLARATIONS>);

=item * an index of a type other than C<unique>, an index with C<options>, an
C<on_delete> or C<on_update> Oracle does not have, two relationships to one key
with other actions (see L</ON DELETE, ON UPDATE, DEFERRABLE>), and a C<float>
of a precision other than a whole number from 1 to 126.

=back

A view definition is the user's own SQL and is not read by the driver: it is
sent as it is, and a table named in it unquoted, which Oracle reads in upper
case, is answered by the server with ORA-00942 (see L</IDENTIFIERS,
AUTO-INCREMENT, FOREIGN KEYS>). The definition therefore quotes the table
names it uses, as the driver created them.

The C<double> base type is C<BINARY_DOUBLE>, as C<double precision> is; the
blanks of C<double  precision> do not matter.

=head1 DECLARED OBJECTS

L</declared_objects> names what an install writes. The objects of a case
can be told from the others of the same user by it, which is what the cleanup
of L<DBIO::Oracle::Test::Conformance> relies on.

=head1 UNIQUE CONSTRAINTS

Every entry of C<< $source->unique_constraints >> but C<primary> (C<add_unique_constraint>,
Cake C<uniq>) is written as C<CONSTRAINT name UNIQUE (columns)> inside the
C<CREATE TABLE>, after the primary key; Oracle creates the unique index of the
same name. The name is shortened to 30 characters like every generated
name. A constraint over the same columns as the primary key or as an earlier
constraint is not written again, because Oracle refuses it (ORA-02261).

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::Oracle> - schema component

=item * L<DBIO::Oracle::Deploy> - uses this to generate DDL for deployment

=item * L<DBIO::PostgreSQL::DDL> - reference implementation

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
