package DBIO::MySQL::DDL;
# ABSTRACT: Generate MySQL/MariaDB DDL from DBIO Result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp qw/croak/;
use Digest::SHA ();

use DBIO::Exception ();

use DBIO::Schema::Type ();
use DBIO::MySQL::Adapter ();
use DBIO::MySQL::Identifier qw(quote_ident check_table_name split_table_name quote_table);
use DBIO::MySQL::DefaultValue qw(default_sql);
use DBIO::MySQL::IndexType ();

my $ADAPTER = DBIO::MySQL::Adapter->new;



sub default_charset   { 'utf8mb4' }
sub default_collation { 'utf8mb4_unicode_ci' }

my %FK_ACTION = map { $_ => 1 } ('NO ACTION', 'RESTRICT', 'CASCADE', 'SET NULL', 'SET DEFAULT');

# The longest name of a constraint on MySQL and MariaDB.
my $MAX_NAME = 64;


sub foreign_key_name {
  my ($table, @cols) = @_;
  my $name = join '_', $table, @cols, 'fk';
  return $name if length $name <= $MAX_NAME;
  my $hash = substr Digest::SHA::sha1_hex($name), 0, 8;
  return substr($name, 0, $MAX_NAME - 9) . "_$hash";
}


sub foreign_key_names {
  my @fk = @_;
  my $key  = sub { join "\x1e", $_[0]{table}, join("\x1f", @{ $_[0]{from_columns} }),
    $_[0]{to_table}, join("\x1f", @{ $_[0]{to_columns} }) };
  my $full = sub { join "\x1e", $key->($_[0]), map { uc($_[0]{$_} // '') } qw/on_update on_delete/ };

  my (%distinct, @distinct);                    # identity => fk, in first-seen order
  for my $fk (@fk) {
    my $id = $full->($fk);
    next if $distinct{$id};
    $distinct{$id} = $fk;
    push @distinct, $id;
  }

  my %by_name;                                  # lc(plain name) => [ identity ... ]
  push @{ $by_name{ lc foreign_key_name($distinct{$_}{table}, @{ $distinct{$_}{from_columns} }) } }, $_
    for @distinct;

  my %name;
  for my $id (@distinct) {
    my $fk    = $distinct{$id};
    my $plain = foreign_key_name($fk->{table}, @{ $fk->{from_columns} });
    my @group = @{ $by_name{ lc $plain } };
    if (@group == 1) { $name{$id} = $plain; next }
    my %four; $four{ $key->($distinct{$_}) }++ for @group;
    my $hash = substr Digest::SHA::sha1_hex($four{ $key->($fk) } > 1 ? $id : $key->($fk)), 0, 8;
    $name{$id} = (length "${plain}_$hash" <= $MAX_NAME ? $plain : substr($plain, 0, $MAX_NAME - 9)) . "_$hash";
  }
  return map { $name{ $full->($_) } } @fk;
}

# The columns of a foreign key in the order of the key of the target: InnoDB
# takes the referenced list only in the order of an index (any other order is
# "Missing index"). The primary key is asked first, then the unique constraints
# by name; the first whose column set is the referenced one gives the order,
# the pairing with the referencing columns kept. None: as given (sorted by the
# target names); one column: nothing to order.
sub _order_by_target_key {
  my ($foreign, $from, $to) = @_;
  return ($from, $to) if @$to < 2;
  my %pair; @pair{@$to} = @$from;
  my $want = join "\0", sort @$to;
  my @keys = ([ $foreign->primary_columns ]);
  if ($foreign->can('unique_constraints')) {
    my %uniques = $foreign->unique_constraints;
    push @keys, $uniques{$_} for grep { $_ ne 'primary' } sort keys %uniques;
  }
  for my $key (@keys) {
    next unless @$key == @$to && join("\0", sort @$key) eq $want;
    return ([ map { $pair{$_} } @$key ], [ @$key ]);
  }
  return ($from, $to);
}

# ' ON DELETE CASCADE' for the on_delete / on_update attribute of a belongs_to.
# Any case and spacing is taken; NO ACTION (the server's default) and an unset
# value write nothing; a word that is no foreign key action throws here
# instead of reaching the server as a syntax error; SET DEFAULT throws too.
sub _fk_action {
  my ($source, $rel, $attr, $clause, $value) = @_;
  # '' is "the database's default" (DBIO::Relationship::Base): as if unset
  return '' unless defined $value && $value =~ /\S/;
  (my $action = uc $value) =~ s/^\s+|\s+$//g;
  $action =~ s/[\s_]+/ /g;
  $source->throw_exception(sprintf
    "relationship '%s' of %s declares %s => '%s', which is no foreign key action "
    . "(known: NO ACTION, RESTRICT, CASCADE, SET NULL, SET DEFAULT)",
    $rel, $source->source_name, $attr, $value)
    unless $FK_ACTION{$action};
  return '' if $action eq 'NO ACTION';
  $source->throw_exception(sprintf
    "relationship '%s' of %s declares %s => '%s': MySQL and MariaDB accept SET DEFAULT "
    . "but never run it (the server acts as RESTRICT), so it is refused",
    $rel, $source->source_name, $attr, $value)
    if $action eq 'SET DEFAULT';
  return " $clause $action";
}


sub order_by_foreign_keys {
  my ($tables, $to_of) = @_;
  my %is_ours = map { $_->{name} => 1 } @$tables;
  my (%out, @steps);
  my @todo = @$tables;
  while (@todo) {
    my ($pick) = grep {
      my $t = $_;
      !grep { my $to = $to_of->($_); $to ne $t->{name} && $is_ours{$to} && !$out{$to} } @{ $t->{fks} };
    } @todo;
    $pick //= _first_in_cycle(\@todo, $to_of, \%is_ours, \%out) // $todo[0];
    @todo = grep { $_ != $pick } @todo;

    my (@inline, @held);
    for my $fk (@{ $pick->{fks} }) {
      my $to = $to_of->($fk);
      push @{ $to ne $pick->{name} && $is_ours{$to} && !$out{$to} ? \@held : \@inline }, $fk;
    }
    $out{ $pick->{name} } = 1;
    push @steps, { table => $pick, inline => \@inline, held => \@held };
  }
  return @steps;
}

# Of the tables left, the first that lies on a cycle of the foreign keys still
# open. Breaking the cycle at a table that merely waits on one would hold
# back its foreign keys for nothing.
sub _first_in_cycle {
  my ($todo, $to_of, $is_ours, $out) = @_;
  my %waits_on;
  for my $t (@$todo) {
    $waits_on{ $t->{name} } = [ grep { $_ ne $t->{name} && $is_ours->{$_} && !$out->{$_} }
      map { $to_of->($_) } @{ $t->{fks} } ];
  }
  for my $t (@$todo) {
    my (%seen, @walk);
    @walk = @{ $waits_on{ $t->{name} } };
    while (defined(my $n = shift @walk)) {
      return $t if $n eq $t->{name};
      next if $seen{$n}++;
      push @walk, @{ $waits_on{$n} // [] };
    }
  }
  return;
}


my %CLAUSE_END = map { $_ => 1 } qw(
  SELECT WHERE GROUP HAVING ORDER LIMIT UNION INTERSECT EXCEPT WINDOW FOR INTO PROCEDURE LOCK
);

sub _view_tokens {
  my ($text) = @_;
  my @tok;
  pos($text) = 0;
  while (pos($text) < length $text) {
    if    ($text =~ /\G\s+/gc) { }
    elsif ($text =~ m{\G/\*.*?\*/}gcs) { }
    elsif ($text =~ /\G(?:--(?=\s|\z)|#)[^\n]*/gc) { }
    elsif ($text =~ /\G`((?:[^`]|``)*)`/gc) {
      (my $n = $1) =~ s/``/`/g;
      push @tok, [ id => $n ];
    }
    elsif ($text =~ /\G'(?:[^'\\]|\\.|'')*'/gcs) { push @tok, [ str => '' ] }
    elsif ($text =~ /\G"(?:[^"\\]|\\.|"")*"/gcs) { push @tok, [ str => '' ] }
    elsif ($text =~ /\G([\w\$]+)/gc) { push @tok, [ word => $1 ] }
    elsif ($text =~ /\G([().,])/gc) { push @tok, [ p => $1 ] }
    elsif ($text =~ /\G./gcs) { push @tok, [ other => '' ] }
  }
  return @tok;
}

sub view_reads {
  my ($def) = @_;
  return () unless defined $def && length $def;
  my @tok = _view_tokens($def);
  my (@reads, %seen);

  # One frame per pair of parentheses. expect: the next token stands where a
  # table is named; from: a comma does the same; select: this frame holds a
  # SELECT, so its FROM is a table list (a FROM inside TRIM(...) is not).
  my @frames = ({ expect => 0, from => 0, select => 1 });
  my $i = 0;
  while ($i < @tok) {
    my ($type, $val) = @{ $tok[$i] };
    my $f = $frames[-1];
    if ($type eq 'p' && $val eq '(') {
      push @frames, { expect => $f->{expect}, from => $f->{expect}, select => 0 };
      $f->{expect} = 0;
      $i++;
      next;
    }
    if ($type eq 'p' && $val eq ')') {
      pop @frames if @frames > 1;
      $i++;
      next;
    }
    if ($type eq 'p' && $val eq ',') {
      $f->{expect} = $f->{from} ? 1 : 0;
      $i++;
      next;
    }
    if ($type eq 'word') {
      my $kw = uc $val;
      if ($kw eq 'FROM' && $f->{select}) { @$f{qw(from expect)} = (1, 1); $i++; next }
      if (($kw eq 'JOIN' || $kw eq 'STRAIGHT_JOIN') && $f->{from}) { $f->{expect} = 1; $i++; next }
      if ($CLAUSE_END{$kw}) {
        $f->{select} = 1 if $kw eq 'SELECT';
        @$f{qw(from expect)} = (0, 0);
        $i++;
        next;
      }
    }
    if ($f->{expect} && ($type eq 'id' || $type eq 'word')) {
      # a (possibly qualified) name; the last part is the table
      my $name = $val;
      $i++;
      while ($i + 1 < @tok && $tok[$i][0] eq 'p' && $tok[$i][1] eq '.' && ($tok[$i + 1][0] eq 'id' || $tok[$i + 1][0] eq 'word')) {
        $name = $tok[$i + 1][1];
        $i += 2;
      }
      my $call = $i < @tok && $tok[$i][0] eq 'p' && $tok[$i][1] eq '(';
      push @reads, $name unless $call || $seen{$name}++;
      $f->{expect} = 0;
      next;
    }
    $f->{expect} = 0;
    $i++;
  }
  return @reads;
}


sub order_views {
  my ($defs) = @_;
  my @names = sort keys %$defs;
  my %by_fold;
  push @{ $by_fold{ lc $_ } }, $_ for @names;

  my %reads;
  for my $v (@names) {
    my %dep;
    for my $r (view_reads($defs->{$v})) {
      my $to = exists $defs->{$r} ? $r
             : (@{ $by_fold{ lc $r } // [] } == 1 ? $by_fold{ lc $r }[0] : undef);
      $dep{$to} = 1 if defined $to && $to ne $v;
    }
    $reads{$v} = [ sort keys %dep ];
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
        'DBIO::MySQL::DDL: the views %s read each other in a cycle (%s), no order creates them',
        join(', ', map { quote_ident($_) } @cycle),
        join('; ', map { my $v = $_; sprintf '%s reads %s', quote_ident($v),
          join(', ', map { quote_ident($_) } grep { my $r = $_; grep { $_ eq $r } @cycle } @{ $reads{$v} }) } @cycle));
    }
    @todo = grep { $_ ne $pick } @todo;
    $out{$pick} = 1;
    push @order, $pick;
  }
  return @order;
}




sub qualified_tables {
  my ($class, $schema) = @_;
  my (@out, %seen);
  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    next if $source->isa('DBIO::ResultSource::View');
    my $name = $source->name;
    $name = $$name if ref $name eq 'SCALAR';
    next if ref $name || $name =~ /\s|\(/;
    my ($database) = split_table_name($name);
    push @out, [ $name, $database ] if defined $database && !$seen{$name}++;
  }
  return @out;
}

sub drop_ddl {
  my ($class, $schema) = @_;

  my (%view_def, @tables, %seen);
  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $name   = $source->name;
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      next if ref $name;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      $view_def{$name} = $def;
      next;
    }
    $name = $$name if ref $name eq 'SCALAR';
    next if ref $name || $name =~ /\s|\(/;
    push @tables, $name unless $seen{$name}++;
  }

  return join "\n\n",
    (map { sprintf 'DROP VIEW IF EXISTS %s;', quote_ident($_) } reverse order_views(\%view_def)),
    (map { sprintf 'DROP TABLE IF EXISTS %s;', quote_table($_) } @tables);
}


sub install_ddl {
  my ($class, $schema, $opts) = @_;
  $opts ||= {};

  my %view_def;              # view name => definition, created in dependency order below
  my @tables;                # one entry per CREATE TABLE, in source-name order
  my %seen_table;
  my %seen_view;

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $result_class = $source->result_class;
    my $table_name   = $source->name;

    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = ref $table_name eq 'SCALAR' ? $$table_name : $table_name;
      next if ref $vname || $seen_view{$vname}++;
      check_table_name($vname, 'view');
      next if defined $opts->{database};
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      $view_def{$vname} = $def;
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd') or an inline
    # subquery source; deref the former, skip the latter. The literal name is
    # quoted like any other: it is one identifier here.
    if (ref $table_name eq 'SCALAR') {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
    }
    next if ref $table_name;
    check_table_name($table_name);

    # A table of another database is made there, and only by the install of
    # the schema itself: the temporary database of a diff leaves it out
    # (local_only), or a temporary database for one database alone (database).
    my ($table_database, $local_name) = split_table_name($table_name);
    next if defined $table_database && $opts->{local_only};

    # The temporary database of one other database (karr k122) gets that
    # database's tables, under the names they have there.
    if (defined $opts->{database}) {
      next unless defined $table_database && $table_database eq $opts->{database};
      $table_name = $local_name;
    }

    # Several result sources can map to one physical table; emit it once.
    next if $seen_table{$table_name}++;

    my @col_defs;
    my @fks;                 # foreign keys as foreign_key_names takes them (actions as ' ON DELETE ...' clauses)
    my @pk_cols = $source->primary_columns;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _mysql_column_type($info);

      my $def = sprintf '  %s %s', quote_ident($col_name), $type;
      $def .= ' NOT NULL' if !$info->{is_nullable};
      # AUTO_INCREMENT is for integers: on the string a GUID is stored as the
      # server refuses the table (1063), so the attribute is not written there
      # (karr k115). The value of such a column is generated by the storage.
      $def .= ' AUTO_INCREMENT'
        if $info->{is_auto_increment} && lc($info->{data_type} // '') ne 'uniqueidentifier';

      if (defined $info->{default_value}) {
        $def .= " DEFAULT " . default_sql($info->{default_value});
      }

      push @col_defs, $def;
    }

    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { quote_ident($_) } @pk_cols);
    }

    # Unique constraints
    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        push @col_defs, sprintf '  UNIQUE KEY %s (%s)',
          quote_ident($uname),
          join(', ', map { quote_ident($_) } @$cols);
      }
    }

    # Foreign keys derived from belongs_to relationships
    for my $rel ($source->relationships) {
      my $info = $source->relationship_info($rel);
      next unless $info && $info->{attrs} && $info->{attrs}{is_foreign_key_constraint};

      my $foreign = $info->{class};
      my $foreign_source = eval { $schema->source($foreign) }
        // eval { $schema->source($foreign =~ s/.*:://r) };
      next unless $foreign_source;

      # Neither server lets a foreign key reference a view (1824): the
      # relationship stays, the key is left out (karr k118).
      next if $foreign_source->isa('DBIO::ResultSource::View');

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
      my ($ordered_from, $ordered_to) = _order_by_target_key($foreign_source, \@from, \@to);
      @from = @$ordered_from;
      @to   = @$ordered_to;

      # A literal table name (\'cd') arrives as a scalar ref; deref it so
      # the FK references the table, not "SCALAR(0x...)".
      my $foreign_name = $foreign_source->name;
      $foreign_name = $$foreign_name if ref $foreign_name eq 'SCALAR';

      # A key between a table of another database and anything else is not
      # written, and not left out silently either (karr k120).
      if (!ref $foreign_name && (defined $table_database || defined +(split_table_name($foreign_name))[0])) {
        DBIO::Exception->throw(sprintf
          "DBIO::MySQL: the foreign key of %s to %s is refused: a table in "
          . "another database (database.table) takes part in it, and keys "
          . "across databases are not supported", $table_name, $foreign_name);
      }

      # ON UPDATE before ON DELETE, as the diff path writes them (Diff::ForeignKey).
      my $on_update = _fk_action($source, $rel, 'on_update', 'ON UPDATE', $info->{attrs}{on_update});
      my $on_delete = _fk_action($source, $rel, 'on_delete', 'ON DELETE', $info->{attrs}{on_delete});

      # Named below, once every table is known (foreign_key_names): the fixed
      # name is the one the diff writes as well, the server's own
      # (<table>_ibfk_N) goes by the position in the CREATE TABLE and differs
      # between an install and an upgrade.
      push @fks, {
        table => $table_name, from_columns => \@from, to_table => $foreign_name,
        to_columns => \@to, on_update => $on_update, on_delete => $on_delete,
      };
    }

    my $engine  = ($result_class->can('mysql_engine')  && $result_class->mysql_engine)  || 'InnoDB';
    my $charset = ($result_class->can('mysql_charset') && $result_class->mysql_charset) || default_charset();
    my $collate = ($result_class->can('mysql_collate') && $result_class->mysql_collate) || default_collation();

    my @index_stmts;
    my $entry = {
      name => $table_name, col_defs => \@col_defs, fks => \@fks,
      tail => sprintf(') ENGINE=%s DEFAULT CHARSET=%s COLLATE=%s;', $engine, $charset, $collate),
      index_stmts => \@index_stmts,
    };
    push @tables, $entry;

    # MySQL-specific indexes via mysql_indexes (parallel to pg_indexes)
    # plus the canonical declaration on the result source (idx / indices,
    # ADR 0061): its own mysql block carries `using`; a foreign-only entry or
    # an unknown key in the block is refused by index_declarations_for. On the
    # same name the canonical declaration wins over the hand-written one.
    {
      my $indexes = $result_class->can('mysql_indexes')
        ? { %{ $result_class->mysql_indexes } } : {};
      for my $decl ($source->index_declarations_for('mysql', ['using'])) {
        my $own = $decl->{driver} && $decl->{driver}{mysql} || {};
        $indexes->{ $decl->{name} } = {
          columns => $decl->{columns},
          unique  => $decl->{unique},
          (defined $own->{using} ? (using => $own->{using}) : ()),
        };
      }
      # The server takes an AUTO_INCREMENT column only as a key of the table at
      # CREATE TABLE time (1075 otherwise), so the first index that starts with
      # such a column outside the primary key stands in the CREATE TABLE, as the
      # diff writes it (karr k112, k107). A unique constraint over it is that
      # key already.
      my %auto_key = map { $_ => 1 }
        grep { $source->column_info($_)->{is_auto_increment} } grep { my $c = $_; !grep { $_ eq $c } @pk_cols } $source->columns;
      if ($source->can('unique_constraints')) {
        my %uniques = $source->unique_constraints;
        delete $auto_key{ $_->[0] } for grep { $_ && @$_ } map { $uniques{$_} } grep { $_ ne 'primary' } keys %uniques;
      }
      my %dup_of_unique;
      if ($source->can('unique_constraints')) {
        my %uniques = $source->unique_constraints;
        $dup_of_unique{ join "\x1f", @{ $uniques{$_} } } = 1
          for grep { $_ ne 'primary' && ref $uniques{$_} eq 'ARRAY' && @{ $uniques{$_} } } keys %uniques;
      }
      for my $idx_name (sort keys %$indexes) {
        my $idx = $indexes->{$idx_name};
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';

        # `using` names two different things in MySQL's CREATE INDEX grammar:
        # BTREE/HASH are index TYPES (trailing USING clause), FULLTEXT/SPATIAL
        # are index CLASSES (in front of INDEX). The split itself lives in
        # DBIO::MySQL::IndexType -- the single source of truth shared with the
        # migration-diff renderer (karr k52). Here we add the two schema-side
        # refusals the diff side does not need: an unrecognised `using` value
        # (RTREE included, which the server only ever picks itself for a SPATIAL
        # index and never accepts by name, karr k50), and the UNIQUE/class
        # collision.
        my $class_kw = '';
        my $type     = '';
        if (my $using = $idx->{using}) {
          ($class_kw, $type) = DBIO::MySQL::IndexType::index_type_split($using);

          croak "mysql_index '$idx_name': invalid using value '$using' -- "
            . 'MySQL accepts BTREE and HASH (rendered as a USING clause) '
            . 'and FULLTEXT and SPATIAL (rendered as the index class, '
            . 'CREATE FULLTEXT/SPATIAL INDEX)'
            unless defined $class_kw;

          # UNIQUE, FULLTEXT and SPATIAL share one grammar position in
          # CREATE [UNIQUE | FULLTEXT | SPATIAL] INDEX -- at most one may
          # appear. `unique => 1` here would concatenate the UNIQUE prefix
          # with the class keyword into `CREATE UNIQUE FULLTEXT INDEX ...`,
          # which no MySQL or MariaDB server accepts (karr k52). BTREE/HASH
          # are index types, a different position, so unique stays valid there.
          if (length $class_kw && $idx->{unique}) {
            (my $kw = $class_kw) =~ s/\s+\z//;
            croak "mysql_index '$idx_name': unique cannot be combined with "
              . "$kw -- UNIQUE, FULLTEXT and SPATIAL share one grammar position "
              . 'in CREATE [UNIQUE | FULLTEXT | SPATIAL] INDEX, so at most one '
              . 'may appear';
          }
        }

        # An index over exactly the columns of a unique constraint of the
        # table, in the same order, is a second index for the lookups the
        # UNIQUE key serves already, and is not written (karr k120). A
        # FULLTEXT or SPATIAL index is another kind of object.
        next if !length $class_kw && $dup_of_unique{ join "\x1f", @{ $idx->{columns} // [] } };

        my $cols = join ', ',
          map { quote_ident($_) } @{ $idx->{columns} // [] };
        my ($first) = @{ $idx->{columns} // [] };
        if (!length $class_kw && defined $first && delete $auto_key{$first}) {
          push @col_defs, sprintf '  %sKEY %s (%s)%s', $unique, quote_ident($idx_name), $cols, $type;
          next;
        }
        push @index_stmts, sprintf 'CREATE %s%sINDEX %s ON %s (%s)%s;',
          $unique, $class_kw, quote_ident($idx_name), quote_table($table_name),
          $cols, $type;
      }
    }
  }

  # The foreign keys get their names, all of them at once; an identical one is
  # written once.
  {
    my @all   = map { @{ $_->{fks} } } @tables;
    my @names = foreign_key_names(@all);
    my %by_ref; @by_ref{ map { "$_" } @all } = @names;
    for my $entry (@tables) {
      my %seen;
      my @unique;
      for my $fk (@{ $entry->{fks} }) {
        my $name = $by_ref{"$fk"};
        next if $seen{$name}++;       # one name is one foreign key: an identical one is written once
        push @unique, [ $fk->{to_table}, sprintf 'CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)%s',
          quote_ident($name),
          join(', ', map { quote_ident($_) } @{ $fk->{from_columns} }),
          quote_ident($fk->{to_table}),
          join(', ', map { quote_ident($_) } @{ $fk->{to_columns} }),
          $fk->{on_update} . $fk->{on_delete} ];
      }
      $entry->{fks} = \@unique;
    }
  }

  # The tables go out parents first (order_by_foreign_keys); the foreign keys
  # held back are added with ALTER TABLE once all tables and indexes exist.
  my (@stmts, @late);
  for my $step (order_by_foreign_keys(\@tables, sub { $_[0][0] })) {
    my ($pick, $inline, $held) = @$step{qw(table inline held)};
    push @stmts, sprintf "CREATE TABLE %s (\n%s\n%s",
      quote_table($pick->{name}),
      join(",\n", @{ $pick->{col_defs} }, map { "  $_->[1]" } @$inline),
      $pick->{tail};
    push @stmts, @{ $pick->{index_stmts} };
    push @late, map { sprintf 'ALTER TABLE %s ADD %s;', quote_table($pick->{name}), $_->[1] } @$held;
  }

  my @view_stmts = map { sprintf "CREATE VIEW %s AS %s;", quote_ident($_), $view_def{$_} } order_views(\%view_def);

  return join "

", @stmts, @late, @view_stmts;
}

sub _mysql_column_type {
  my ($info) = @_;
  my $type = $info->{data_type} // 'text';

  # Pre-parameterized types pass through
  return $type if $type =~ /\(.+\)$/;

  # Portable base types: delegate to the adapter (single source of truth).
  # canonical_column refuses a broken declaration (a size that is neither a
  # scalar nor an arrayref); that is the declaration's error and goes to the
  # caller, not into the alias path below (karr k96).
  if (DBIO::Schema::Type::is_base_type(lc $type)) {
    return $ADAPTER->to_native(DBIO::Schema::Type::canonical_column('_', $info));
  }

  # GUID. Neither MySQL nor MariaDB has such a type; the column holds the
  # string form, 36 characters hyphenated, as the rest of the family spells it
  # (dbio-sybase k52). The width is the type's own: a declared size does not
  # move it. What is introspected back is varchar(36), so a diff finds nothing
  # to change (karr k115).
  return 'varchar(36)' if lc $type eq 'uniqueidentifier';

  # ENUM and SET carry their members in extra => { list => [...] } (the
  # DBIx::Class spelling). Each member is a string literal of its own, written
  # like a default (apostrophe doubled, backslash doubled), so a member that
  # holds a quote is the member and not the end of the list (karr k120).
  if (lc($type) =~ /\A(?:enum|set)\z/) {
    my $list = ref $info->{extra} eq 'HASH' ? $info->{extra}{list} : undef;
    return "$type(" . join(',', map { DBIO::MySQL::DefaultValue::default_sql($_, 0) } @$list) . ')'
      if ref $list eq 'ARRAY' && @$list;
  }

  # Use size for varchar/varbinary/binary (non-base alias path).
  # All three take exactly ONE scalar length (VARCHAR(M), BINARY[(M)],
  # VARBINARY(M)), so an arrayref size would stringify the reference into the
  # type -- varchar(ARRAY(0x...)). Read its first element instead: the same
  # "first member is the width" reading `character` gets below, and a size
  # naming no width falls through to the legacy default (karr #37).
  if ($info->{size} && $type =~ /^(varchar|varbinary|binary)$/i) {
    my $size = ref $info->{size} eq 'ARRAY' ? $info->{size}[0] : $info->{size};
    return "$type($size)" if $size;
  }

  # Legacy / dialect alias names — only aliases, not the 8 base-type names
  my %type_map = (
    int        => 'int',
    bigint     => 'bigint',
    smallint   => 'smallint',
    tinyint    => 'tinyint',
    serial     => 'int',
    bigserial  => 'bigint',

    varchar    => 'varchar(255)',
    string     => 'text',
    clob       => 'longtext',

    float      => 'float',
    real       => 'double',
    'double precision' => 'double',
    decimal    => 'decimal(10,2)',

    bytea      => 'blob',

    # no such type here; DECIMAL(19,4) is what MONEY is on SQL Server (karr k115)
    money      => 'decimal(19,4)',

    date       => 'date',
    datetime   => 'datetime',
    time       => 'time',
    json       => 'json',
  );

  my $native = $type_map{ lc $type } // $type;

  # decimal/character are %ALIAS-only names (DBIO::Schema::Type) -- they never
  # reach the portable base-type path above, so the plain lookup above would
  # otherwise hardcode a size (decimal(10,2)) or drop it entirely (character).
  # Honor an explicit size the same way the portable path already does for
  # numeric/char, falling back to the legacy default only when size is absent.
  # decimal accepts every size shape a caller can write: [precision, scale],
  # a precision-only [precision], and a bare scalar precision. The last two
  # render decimal($p) -- MySQL's DECIMAL(M) is DECIMAL(M,0), and it is the
  # spelling DBIO::MSSQL::DDL::_mssql_column_type already uses for a
  # precision-only size, so this is not a third convention (karr #26).
  if (lc($type) eq 'decimal' && defined $info->{size}) {
    my ($precision, $scale) = ref $info->{size} eq 'ARRAY'
      ? @{ $info->{size} }
      : ($info->{size}, undef);
    if (defined $precision) {
      $native = defined $scale ? "decimal($precision,$scale)" : "decimal($precision)";
    }
  }
  elsif (lc($type) eq 'bit' && defined $info->{size}) {
    # BIT(M) is the number of bits; without the size the server makes BIT(1)
    # (karr k120).
    my $size = ref $info->{size} eq 'ARRAY' ? $info->{size}[0] : $info->{size};
    $native = "bit($size)" if defined $size;
  }
  elsif (lc($type) eq 'character' && defined $info->{size}) {
    # The mirror-image of the above: character takes a scalar length, so an
    # arrayref size would stringify the reference into the type name. Read
    # its first element -- the same "first member is the width" reading
    # decimal gives a precision-only arrayref.
    my $size = ref $info->{size} eq 'ARRAY' ? $info->{size}[0] : $info->{size};
    $native = "character($size)" if defined $size;
  }

  return $native;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::DDL - Generate MySQL/MariaDB DDL from DBIO Result classes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::MySQL::DDL> generates a MySQL DDL script from a L<DBIO::Schema>
class hierarchy. It is the desired-state side of the
test-deploy-and-compare strategy used by L<DBIO::MySQL::Deploy>.

    my $ddl = DBIO::MySQL::DDL->install_ddl($schema);

The generated DDL is plain SQL, one C<CREATE TABLE> per source. The tables
come in foreign key order, a referenced table before the one that
references it, and among tables free to go the one of the first source name
first, so the script is the same on every run. A foreign key that points to
itself is no dependency. Tables that reference each other in a cycle are
created with the foreign keys that close the cycle left out of their
C<CREATE TABLE>; those are added with C<ALTER TABLE ... ADD FOREIGN KEY>
after every table and index; the cycle is broken at the first table on it by
source name. A foreign key is written C<CONSTRAINT `name` FOREIGN KEY ...> with
the fixed name L</foreign_key_name> gives. Identical foreign keys (two
C<belongs_to> to one target over the same columns) are written once; different ones
that would get the same name all get a C<_E<lt>hash8E<gt>> suffix
(L</foreign_key_names>), nothing throws. The columns of a composite foreign key
stand in the order of the key of the target (primary key, then unique constraints
by name), the order InnoDB takes. A foreign key from a C<belongs_to> carries
C<ON UPDATE> and C<ON DELETE> from the C<on_update> and C<on_delete>
attributes of the relationship (C<NO ACTION>, C<RESTRICT>, C<CASCADE>,
C<SET NULL>, any case); C<NO ACTION>, an unset attribute and C<''> (the
database's default) write nothing, any other word throws. C<SET DEFAULT> throws as well: both
servers accept it and never run it (MySQL acts as C<RESTRICT>, MariaDB stores
C<RESTRICT>), so it is refused loudly rather than deployed as a promise the
database does not keep. A relationship whose target is a view
source (virtual or not) writes no foreign key, in the install and in the diff
alike: neither server lets a key reference a view (error 1824), and the
relationship itself stays valid, so a join over it works. The
introspection then sees none. Tables
default to C<ENGINE=InnoDB> and C<CHARSET=utf8mb4 COLLATE
utf8mb4_unicode_ci>. Result classes can override per-table via
C<mysql_engine>, C<mysql_charset>, C<mysql_collate> attributes.

Indexes come from two declarations: C<mysql_index> on the result class and
the canonical index declaration of the result source (C<idx>, C<indices>;
L<DBIO::ResultSource/index_declarations_for>), whose own C<mysql> block may
hold C<using>. On the same name the canonical declaration wins. An entry
that carries only another driver's block, or an unknown key in its
C<mysql> block, throws.

An index over exactly the columns of a unique constraint of the same table, in
the same order, is not written: the C<UNIQUE KEY> is that index already, and a
second one would only be a duplicate. Another column order, a
subset and a C<FULLTEXT> or C<SPATIAL> index are other objects and are written.

An C<enum> or C<set> column lists its members from C<< extra =E<gt> { list =E<gt>
[...] } >>, each as a string literal (apostrophe and backslash doubled), and a
C<bit> column keeps its C<size> (C<bit(8)>; without one the server makes
C<bit(1)>).

Every name the DDL carries -- of a table, a view, a column, a unique key, an
index, and the table and columns a foreign key references -- is written in
backticks, a backtick inside it doubled (L<DBIO::MySQL::Identifier>). So a
table may be called C<order> and a column C<key> or C<my-col>. A name is one
identifier: a dot in it is part of the name, not the separator of a
database-qualified one. Because of that a table or view name with a dot (C<<
table('db.t') >>, C<< table(\'db.t') >>) is refused with a L<DBIO::Exception>
and nothing is rendered, instead of creating a table literally called C<db.t>
that no query reaches; creating a table in another database is not supported
yet. A dot in a column name is fine. The definition of a view is the SQL the
result source declares and is written as it stands; the names inside it are
quoted by whoever wrote it.

=head1 METHODS

=head2 default_charset

The character set of a table that names none: C<utf8mb4>. The C<CREATE TABLE>
of L<DBIO::MySQL::Diff::Table> takes it from here as well, so a table an upgrade
creates is the table C<install_ddl> creates.

=head2 default_collation

The collation of a table that names none: C<utf8mb4_unicode_ci>, the same
source as L</default_charset>.

=head2 foreign_key_name

    my $name = DBIO::MySQL::DDL::foreign_key_name('child', 'parent_id');   # child_parent_id_fk

The name of a foreign key: C<< <table>_<columns>_fk >>, the columns in the order
of the key. One function for L</install_ddl> and for both ways the diff writes a
foreign key (L<DBIO::MySQL::Diff::Table>, L<DBIO::MySQL::Diff::ForeignKey>), so
an install and an upgrade end with the same constraint names and the diff after
the upgrade is empty. A name over 64 characters, the limit of the
servers, is cut and ends in 8 hex digits of the SHA-1 of the full name, so two
long names that start alike stay apart.

=head2 foreign_key_names

    my @names = DBIO::MySQL::DDL::foreign_key_names(
      { table => 'a_b', from_columns => ['c'],   to_table => 'p', to_columns => ['id'] },
      { table => 'a',   from_columns => ['b_c'], to_table => 'p', to_columns => ['id'] },
    );   # a_b_c_fk_1f2e3d4c, a_b_c_fk_9a8b7c6d

The names of a whole set of foreign keys (hashrefs with C<table>, C<from_columns>,
C<to_table>, C<to_columns> and, if there are any, C<on_delete> / C<on_update> as
written), one name per foreign key in the order given. This is the one place that
decides which foreign keys share a name, for L</install_ddl> and for the diff
(L<DBIO::MySQL::Diff>, for a model that carries no names), so both agree.

Foreign keys that are identical (table, columns, target, target columns, actions)
are one foreign key and get the same name; the caller writes it once. Different
foreign keys that would get the same L</foreign_key_name> (table C<a_b> column
C<c> and table C<a> column C<b_c>; one column that references two targets) ALL
get the fixed suffix C<_E<lt>hash8E<gt>>: 8 hex digits of the SHA-1 of table,
columns, target table and target columns; a name that grew over 64 characters is
cut before the suffix. The comparison ignores case, as the server does. Nothing
throws. Two foreign keys that differ only in their actions (same table, columns and
target) get the actions into the hash as well, else they would stay alike.

=head2 order_by_foreign_keys

    my @steps = DBIO::MySQL::DDL::order_by_foreign_keys(\@tables, sub { $_[0]{to_table} });

The order in which a set of new tables is created, shared by the install and
by the upgrade out of an empty database (L<DBIO::MySQL::Diff>).
C<@tables> are hashrefs with a C<name> and a list C<fks> of foreign keys of any
shape; the code ref names the table a foreign key references. Of the tables
whose parents are all out, the first in the order given goes next. A foreign
key to a table outside the set is no dependency, and neither is one to the
table itself. When every table left waits on another one (a cycle), the first
of them that lies on a cycle (not one that merely waits for a cycle) goes with the foreign keys to tables not yet out held back. Returns one
hash per table in creation order: C<table>, C<inline> (the foreign keys its
C<CREATE TABLE> carries) and C<held> (those to be added by C<ALTER TABLE> after
every table and index).

=head2 view_reads

    my @names = DBIO::MySQL::DDL::view_reads($view_definition);

The names a view definition reads as a table or view: every name that stands
where a C<FROM> or a C<JOIN> (or a comma in a C<FROM> list) expects a table,
in a subquery, a derived table or a join group as much as at the top, in
order of appearance, without repeats. A database qualifier (C<db.name>) is
dropped and only the name is returned. The caller keeps those that are views
of its own set (L</order_views>).

This is a reading of the text, not of the server, because
L</install_ddl> has no database to ask. It is the one detection for the
install and for the diff: the diff reads the definition the server hands back
(L<DBIO::MySQL::Introspect::Tables>), which is the same text in a fixed
spelling. It was measured (MySQL 8.0.30, MariaDB 11.8.9) against
C<information_schema.view_table_usage>, which MySQL 8 has and MariaDB does not
have at all (C<Unknown table 'view_table_usage'>), so it would have meant two
detections.

The text is split into names, words, strings and comments first: a name inside
a string literal (C<'from b'>) or a comment (C</* from b */>, C<-- b>,
C<# b>) reads nothing; a column, an alias or a function that bears the name of a
view reads nothing, because only the place after C<FROM>/C<JOIN>/the comma
counts; a name in backticks may be a keyword-like word or hold a dot (a dot
inside backticks is part of the name); the C<FROM> of C<TRIM>, C<EXTRACT> and
C<SUBSTRING> opens no table list, since it stands inside a call and no
C<SELECT> stands in that frame. A name followed by C<(> is a call
(C<JSON_TABLE(...)>), not a table. Keywords are matched without regard to case.

What it does not recognise, so that a view which reads another one through
any of these is still created in name order and the server may refuse the
statement:

=over 4

=item *

a view of another database. The qualifier is dropped, so C<other.b> counts as
C<b> when the set has a view C<b>. (It is a false edge, not a missed one.)

=item *

a CTE that bears the name of a view (C<WITH b AS (...) SELECT ... FROM b>) is
read as a read of the view C<b>.

=item *

a double-quoted word is a string, as the server reads it without
C<ANSI_QUOTES>; with that mode a view that names its tables in double quotes
is not recognised. The server rewrites to backticks, so the diff is not
affected.

=item *

an executable comment (C</*! ... */>) is a comment here, whatever the server
makes of it.

=item *

a view read in a statement the definition does not hold at the top (a view
body is one C<SELECT>; this is no limit).

=back

=head2 order_views

    my @names = DBIO::MySQL::DDL::order_views(\%definitions);

The order in which a set of views is created, shared by the install
(L</install_ddl>) and by the diff (L<DBIO::MySQL::Diff::View>).
C<%definitions> maps a view name to its definition (SQL text, or undef for a
view that reads nothing). A view goes after the views of the set it reads
(L</view_reads>); of the views free to go the first by name is next, so views
free of each other stay in name order. A read of the view itself, or of a name
that is no view of the set, is no dependency. The drop order is this one
reversed: a view goes before the views it reads.

When the views read each other in a cycle no order creates them, and the call
throws a L<DBIO::Exception> naming the views on the cycle, before any
statement has been written. A name is matched as written, else without regard
to case when exactly one view of the set has that name that way.

=head2 drop_ddl

    my $ddl = DBIO::MySQL::DDL->drop_ddl($schema);

The statements that take away what L</install_ddl> creates, for the
C<add_drop_table> re-deploy: C<DROP VIEW IF EXISTS> for every view
the install creates, a reader before the view it reads (the reverse of
L</order_views>), then C<DROP TABLE IF EXISTS> for every table, all names in
backticks as the install writes them. One string, the statements separated by a
blank line. A virtual view, a source with a computed name and a view without a
definition are no object of the database and stay out. The views have to go
first: the install says C<CREATE VIEW>, never C<CREATE OR REPLACE>, so a view
left behind fails the next install.

=head2 qualified_tables

    my @pairs = DBIO::MySQL::DDL->qualified_tables($schema);   # ([ 'other.t', 'other' ], ...)

The tables of the schema whose name is C<database.table>, with their database,
in source order and once each. A view, a virtual source and a computed name
are not among them.

=head2 install_ddl

    my $ddl = DBIO::MySQL::DDL->install_ddl($schema);
    my $ddl = DBIO::MySQL::DDL->install_ddl($schema, { local_only => 1 });
    my $ddl = DBIO::MySQL::DDL->install_ddl($schema, { database => 'other' });

Returns the full installation DDL as a single string. C<local_only> leaves out
the tables of other databases (the temporary database of a diff gets the tables
of the current database only). C<database> returns the tables of that one
database and nothing else, under the names they have in it: C<other.t> is made
as C<`t`>, for the temporary database a diff compares that database's tables
in; views are not among them.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
