package DBIO::MySQL::Diff;
# ABSTRACT: Compare two introspected MySQL/MariaDB models

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Base';

use DBIO::MySQL::Diff::Table;
use DBIO::MySQL::Diff::Column;
use DBIO::MySQL::Diff::Index;
use DBIO::MySQL::Diff::ForeignKey;
use DBIO::MySQL::Diff::View;
use DBIO::MySQL::Diff::PrimaryKey qw(primary_key_columns);
use DBIO::MySQL::Adapter;
use DBIO::MySQL::DDL ();
use DBIO::MySQL::IndexType ();
use DBIO::MySQL::Identifier ();
use DBIO::Exception ();
use DBIO::Diff::Compare qw(changed_fk_fields);
use Scalar::Util 'refaddr';

my $ADAPTER = DBIO::MySQL::Adapter->new;



# Parse adapter native_type (e.g. "BIGINT", "CHAR(32)", "DECIMAL(10,2)") into
# the lowercase data_type + column_type pair that information_schema reports.
sub _native_to_mysql_types {
  my ($native) = @_;
  my $lc = lc $native;

  # BIGINT → bigint / bigint(20)
  return ('bigint', 'bigint(20)') if $lc eq 'bigint';

  # TINYINT(1) → tinyint / tinyint(1)
  return ('tinyint', 'tinyint(1)') if $lc eq 'tinyint(1)';

  # DOUBLE → double / double
  return ('double', 'double') if $lc eq 'double';

  # LONGTEXT → longtext / longtext
  return ('longtext', 'longtext') if $lc eq 'longtext';

  # LONGBLOB → longblob / longblob
  return ('longblob', 'longblob') if $lc eq 'longblob';

  # DATETIME → datetime / datetime
  return ('datetime', 'datetime') if $lc eq 'datetime';

  # CHAR(n) → char / char(n)
  if ($lc =~ /\Achar\((\d+)\)\z/) {
    return ('char', "char($1)");
  }

  # DECIMAL(p,s) → decimal / decimal(p,s)
  if ($lc =~ /\Adecimal\((\d+),(\d+)\)\z/) {
    return ('decimal', "decimal($1,$2)");
  }

  # DECIMAL(p) → decimal / decimal(p,0). MySQL and MariaDB both store DECIMAL(M)
  # as DECIMAL(M,0), and information_schema always reports both members back, so
  # the target has to spell the scale out: the adapter renders a precision-only
  # numeric as DECIMAL(p) since karr #41, and 'decimal(8)' never equals the
  # 'decimal(8,0)' the server answers with (karr #43).
  if ($lc =~ /\Adecimal\((\d+)\)\z/) {
    return ('decimal', "decimal($1,0)");
  }

  # Bare DECIMAL → decimal / decimal(10,0), MySQL's and MariaDB's documented
  # default precision/scale -- and what the server reports back for it (karr #43).
  return ('decimal', 'decimal(10,0)') if $lc eq 'decimal';

  # Fallback: lowercase as-is for both
  (my $bare = $lc) =~ s/\(.*//;
  return ($bare, $lc);
}

# Types whose charset/collation is NULL in information_schema (binary/numeric/datetime).
# Lives in DBIO::MySQL::Adapter as %NO_CHARSET, exposed via $ADAPTER->no_charset_for.

sub target_from_compiled {
  my ($class, $compiled) = @_;
  my (%tables, %columns);

  for my $tname (sort keys %{ $compiled->{tables} // {} }) {
    # the name comes from the schema: one that names nothing is refused as
    # install_ddl refuses it, and database.table is a table of another
    # database, which the diff does not read (karr k120)
    DBIO::MySQL::Identifier::check_table_name($tname);
    next if $tname =~ /\./;
    my $t = $compiled->{tables}{$tname};
    $tables{$tname} = { table_name => $tname };

    my @cols;
    # the position in the key is the order of the primary key of the schema
    my $pk_at = 0;
    my %pk_pos = map { $_ => ++$pk_at } @{ $t->{primary_key} // [] };
    for my $c (@{ $t->{columns} // [] }) {
      my ($data_type, $column_type) = _native_to_mysql_types($c->{native_type});

      # charset/collation: leave undef for binary/numeric types so that the
      # comparison (_norm returns '') equals the undef in the live introspect.
      # For text/char types the live DB will have a server-assigned charset;
      # we also leave undef here — see ESCALATION NOTE below.
      my ($charset, $collation) = (undef, undef);
      if ($ADAPTER->no_charset_for($c->{native_type})) {
        $charset = $collation = undef;   # already undef; explicit for clarity
      }

      # A portable schema prescribes a default only when it declares one; when it
      # does not, leave default_value undef so the always-on desired-state
      # contract in DBIO::Diff::Compare skips it and leaves whatever the live
      # column reports alone. The introspection reports undef as default_value
      # for a nullable column with no explicit DEFAULT clause (on MariaDB too,
      # see DBIO::MySQL::Introspect::Columns), so synthesising a literal string
      # 'NULL' here produced a phantom MODIFY of every such column against that
      # undef.
      my $not_null = ($c->{not_null} ? 1 : 0);
      my $default  = $c->{default};

      push @cols, {
        column_name       => $c->{column_name},
        data_type         => $data_type,
        column_type       => $column_type,
        not_null          => $not_null,
        default_value     => $default,
        is_pk             => ($c->{is_pk} ? 1 : 0),
        pk_position       => $pk_pos{ $c->{column_name} },
        is_auto_increment => ($c->{auto_increment} ? 1 : 0),
        character_set     => $charset,
        collation         => $collation,
      };
    }
    $columns{$tname} = \@cols;
  }

  # ESCALATION NOTE: MySQL/MariaDB assigns character_set and collation from the
  # database/server defaults to every text-family column (CHAR, VARCHAR, TEXT,
  # LONGTEXT, …). A portable schema does not prescribe charset/collation, so
  # target_from_compiled cannot derive these values from the schema alone.
  # changed_column_fields() compares character_set and collation; leaving them undef in
  # the target produces phantom diffs for text columns whenever the live DB
  # reports a non-null charset (e.g. utf8mb4 / utf8mb4_uca1400_ai_ci on MariaDB
  # 11.8). This is a design question for the controller: should the desired-state
  # diff ignore attributes the target leaves unspecified?

  return {
    tables       => \%tables,
    columns      => \%columns,
    indexes      => {},
    foreign_keys => {},
  };
}

# A foreign key of the target that carries no name (a model made by hand; the
# introspection always names) gets the fixed name install_ddl would give it,
# and the foreign keys of the whole model are named together, so two that would
# meet in one name are told apart as in install_ddl
# (DBIO::MySQL::DDL::foreign_key_names, karr k106). Returns the target itself
# when every foreign key has a name, else a copy; the model of the caller is
# not changed.
sub _named_target {
  my ($target) = @_;
  my $by_table = $target->{foreign_keys} // {};
  my @unnamed = map { my $t = $_; map { [ $t, $_ ] } grep { !defined $_->{constraint_name} } @{ $by_table->{$t} } }
    sort keys %$by_table;
  return $target unless @unnamed;

  my @names = DBIO::MySQL::DDL::foreign_key_names(map { +{ %{ $_->[1] }, table => $_->[0] } } @unnamed);
  my %name_of; @name_of{ map { "$_->[1]" } @unnamed } = @names;
  return { %$target, foreign_keys => { map {
    my $t = $_;
    ($t => [ map { defined $_->{constraint_name} ? $_ : { %$_, constraint_name => $name_of{"$_"} } } @{ $by_table->{$t} } ])
  } keys %$by_table } };
}

sub _build_operations {
  my ($self) = @_;
  my @other = $self->_other_database_operations;
  my @views = DBIO::MySQL::Diff::View->diff($self->source->{tables}, $self->target->{tables});

  # A view is no table (karr k79): everything below works on models without
  # their views, the views have operations of their own. The drops stand at
  # the head of the diff, before the constraints, the tables and the columns
  # the view may read; the creates at its end, once all of them are what the
  # target says.
  local $self->{source} = DBIO::MySQL::Diff::View::model_without_views($self->{source});
  local $self->{target} = _named_target(DBIO::MySQL::Diff::View::model_without_views($self->{target}));
  my $ops = $self->_build_operations_for_target;
  return [
    @other,
    (grep { $_->action eq 'drop' } @views),
    @$ops,
    (grep { $_->action ne 'drop' } @views),
  ];
}

# The operations on the tables of other databases (karr k122): one diff per
# database, over the models in other_databases, every operation marked with its
# database. They come before the operations on the current database -- nothing
# in another database reads from this one (a key across databases is refused),
# but a view here may read from there.
sub _other_database_operations {
  my ($self) = @_;
  my ($source, $target) = map { $_->{other_databases} // {} } $self->source, $self->target;
  my %option = map { $_ => $self->{$_} } grep { !/\A(?:source|target|operations)\z/ } keys %$self;
  my $empty = sub { +{ tables => {}, columns => {}, indexes => {}, foreign_keys => {} } };
  my %seen;
  return map {
    my $database = $_;
    my $diff = ref($self)->new(%option,
      source => $source->{$database} // $empty->(), target => $target->{$database} // $empty->());
    map { $_->database($database); $_ } @{ $diff->operations };
  } grep { !$seen{$_}++ } sort(keys %$source), sort(keys %$target);
}


sub summary {
  my ($self) = @_;
  return join "\n", map {
    my $line = $_->summary;
    $_->can('database') && defined $_->database ? "$line (database " . $_->database . ')' : $line;
  } @{ $self->operations };
}

sub _build_operations_for_target {
  my ($self) = @_;
  my @ops;

  # The index operations are split around the column changes (karr k80). An
  # index is dropped while every column it is over is still there: the server
  # takes an index along with the last column it was over, so a DROP INDEX
  # after that DROP COLUMN names an index that is gone (1091), and MariaDB
  # refuses to drop one column of a unique key over several (1072). An index is
  # created once its columns are what the target says: added, and of the type
  # they are to have. A changed index is a drop and a create, one on each side.
  my @index_ops = DBIO::MySQL::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
    $self->source->{tables},  $self->target->{tables},
  );
  my @fk_ops = DBIO::MySQL::Diff::ForeignKey->diff(
    $self->source->{foreign_keys}, $self->target->{foreign_keys},
    $self->source->{tables},       $self->target->{tables},
  );

  # The foreign keys come around all of it (karr k94): a constraint that
  # leaves is dropped before the tables and the indexes, because the server
  # refuses to drop the table a constraint references and the index it needs
  # while it is there; one that arrives is added after the indexes.
  push @ops, grep { $_->action eq 'drop' } @fk_ops;

  # The foreign keys that need the primary key of a table that changes or goes
  # as their index are dropped here as well and added again after the key
  # (karr k107); one the target declares over a key it no longer has is refused.
  my @pk_ops = DBIO::MySQL::Diff::PrimaryKey->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  my ($pk_fk_drops, $pk_fk_adds) = $self->_pk_foreign_keys(\@pk_ops, \@index_ops);
  push @ops, @$pk_fk_drops;

  # A foreign key of a new table that needs an index the same diff creates, or
  # whose columns one covers, is not written into the CREATE TABLE but added
  # after the index (karr k81, karr k92).
  my ($inline_fks, @deferred_fks) = $self->_split_inline_foreign_keys(\@index_ops);

  # The key of an AUTO_INCREMENT column outside the primary key of a new table
  # stands in its CREATE TABLE, not after it (karr k107).
  my $inline_indexes;
  ($inline_indexes, @index_ops) = $self->_split_inline_indexes(@index_ops);

  # The new tables are created parents first, as install_ddl does, and the
  # foreign keys that close a cycle are added after everything else (karr k106).
  my ($table_order, @cycle_fks) = $self->_order_new_tables($inline_fks);
  push @deferred_fks, @cycle_fks;

  my @table_ops = DBIO::MySQL::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $inline_fks, $inline_indexes,
    $self->source->{columns}, $self->source->{foreign_keys},
  );
  push @ops,
    (sort { $table_order->{ $a->table_name } <=> $table_order->{ $b->table_name } }
      grep { $_->action eq 'create' } @table_ops),
    grep { $_->action ne 'create' } @table_ops;
  my @column_ops = DBIO::MySQL::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  my @drop_ops   = grep { $_->action eq 'drop' } @index_ops;
  my @create_ops = grep { $_->action ne 'drop' } @index_ops;

  # An AUTO_INCREMENT column that is not the primary key has to have a key, and
  # the server refuses the DROP INDEX of its only one (1075), whether the
  # column goes or only loses the attribute. Such a column is written without
  # AUTO_INCREMENT first -- the MODIFY the diff has for it anyway, or one made
  # for a column that leaves -- and the DROP INDEX follows (karr k80).
  my %under_drop;
  for my $op (@drop_ops) {
    $under_drop{ $op->table_name }{$_} = 1 for @{ $op->index_info->{columns} // [] };
  }
  my (@release, @rest);
  for my $op (@column_ops) {
    my $old = $op->old_info;
    my $col = $op->column_name;
    if ($op->action ne 'add'
          && $old && $old->{is_auto_increment} && !$old->{is_pk}
          && $under_drop{ $op->table_name }{$col}) {
      if ($op->action eq 'modify' && !$op->new_info->{is_auto_increment}) {
        push @release, $op;
        next;
      }
      if ($op->action eq 'drop') {
        push @release, DBIO::MySQL::Diff::Column->new(
          action => 'modify', table_name => $op->table_name, column_name => $col,
          old_info => $old, new_info => { %$old, is_auto_increment => 0 },
        );
      }
    }
    push @rest, $op;
  }

  # An index a foreign key that stays needs is not dropped before the index
  # that takes its place exists (karr k81).
  my ($drops, $creates, $late_drops, $extra_fk_drops, $extra_fk_adds) = $self->_protect_foreign_key_indexes(
    \@drop_ops, \@create_ops, $inline_fks, $pk_fk_drops);

  # The primary keys of the tables in both models (karr k107): after the column
  # changes -- the columns of the key exist by then -- and before the indexes
  # that are created and the foreign keys that are added. Where a column of the
  # key gains AUTO_INCREMENT the MODIFY needs the key (the server refuses
  # AUTO_INCREMENT on a column that is no key), so the key comes first.
  my (@pk_first, @pk_early, @pk_after, @reacquire);
  for my $pk (@pk_ops) {
    my %in_key = map { $_ => 1 } @{ $pk->columns };
    my $gains = grep {
      $_->action eq 'modify' && $_->table_name eq $pk->table_name
        && $in_key{ $_->column_name }
        && $_->new_info->{is_auto_increment} && !$_->old_info->{is_auto_increment}
    } @rest;
    # A new AUTO_INCREMENT column of the key is added with it, in one statement:
    # the server refuses the column without its key.
    my @taken = grep {
      $_->action eq 'add' && $_->table_name eq $pk->table_name
        && $in_key{ $_->column_name } && $_->new_info->{is_auto_increment}
    } @rest;
    if (@taken) {
      my %taken = map { refaddr($_) => 1 } @taken;
      @rest = grep { !$taken{ refaddr $_ } } @rest;
      $pk->with_columns(\@taken);
    }
    if ($pk->action eq 'drop') {
      # A column of the key that stays AUTO_INCREMENT (it has a key of another
      # kind in the target) is released for the drop and gets the attribute
      # back once that key exists. One that loses the attribute has its MODIFY
      # among the column changes, before the key goes.
      my $table = $pk->table_name;
      my %now = map { $_->{column_name} => $_ } @{ $self->source->{columns}{$table} // [] };
      my %then = map { $_->{column_name} => $_ } @{ $self->target->{columns}{$table} // [] };
      for my $name (@{ $pk->old_columns }) {
        my ($old, $new) = ($now{$name}, $then{$name});
        next unless $old && $new && $old->{is_auto_increment} && $new->{is_auto_increment};
        my %released = (%$new, is_auto_increment => 0);
        push @pk_after, DBIO::MySQL::Diff::Column->new(
          action => 'modify', table_name => $table, column_name => $name,
          old_info => $old, new_info => \%released,
        );
        push @reacquire, DBIO::MySQL::Diff::Column->new(
          action => 'modify', table_name => $table, column_name => $name,
          old_info => \%released, new_info => $new,
        );
      }
    }
    # An AUTO_INCREMENT column that leaves the key, or does not stand first in
    # the new one, has to be a key of the table by another index when the
    # statement runs (the server refuses it with 1075): the UNIQUE index the
    # target has over it is created before the key (karr k107).
    if ($pk->action eq 'replace') {
      my $table = $pk->table_name;
      my @new = @{ $pk->columns };
      for my $col (@{ $self->target->{columns}{$table} // [] }) {
        my $name = $col->{column_name};
        next unless $col->{is_auto_increment};
        next unless grep { $_ eq $name } @{ $pk->old_columns };
        next if @new && $new[0] eq $name;
        my ($index) = grep {
          $_->table_name eq $table && (($_->index_info->{columns} // [])->[0] // '') eq $name
        } @$creates;
        next unless $index;
        push @pk_early, $index;
        $creates = [ grep { refaddr($_) != refaddr($index) } @$creates ];
      }
    }
    push @{ $gains ? \@pk_first : \@pk_after }, $pk;
  }

  push @ops, @release, @$extra_fk_drops, @$drops, @pk_first, @rest, @pk_early, @pk_after, @$late_drops;
  push @ops, @$creates, @reacquire;
  push @ops, grep { $_->action ne 'drop' } @fk_ops;
  push @ops, @$pk_fk_adds, @$extra_fk_adds;
  push @ops, @deferred_fks;

  return \@ops;
}

# The foreign keys a primary key operation (karr k107) has to take along, and
# the refusal. Returns two array refs of ForeignKey ops: the extra DROPs, which
# stand with the other foreign key drops, and the ADDs, which stand with the
# other foreign key adds. A foreign key is taken along when it stays as it is
# (a changed one or one that goes is dropped and added by the foreign key diff
# already, once), when it needs an index over columns the old key starts with
# -- the columns it references, in a table that points at this one, or its own
# columns, in this table -- and when neither the new key nor an index that stays
# starts with them: the server refuses the drop (MySQL 1553) or the key that
# does not start with them (MariaDB takes some of those, and the extra drop is
# harmless there). A foreign key the TARGET declares into the table over such
# columns, with no key and no index of the target that starts with them, has
# nothing to point at, and dies.
sub _pk_foreign_keys {
  my ($self, $pk_ops, $index_ops) = @_;
  my ($source, $target) = ($self->source, $self->target);
  my @changing = grep { $_->action ne 'add' } @$pk_ops;
  return ([], []) unless @changing;

  my $target_tables = $target->{tables} // {};
  my (@drops, @adds, %seen);

  for my $pk (@changing) {
    my $table = $pk->table_name;
    my $old   = { columns => $pk->old_columns };
    my $new   = { columns => $pk->columns };
    my %dropped = map { $_->index_name => 1 } grep { $_->table_name eq $table } @$index_ops;
    my @source_others = grep { ($_->{origin} // '') ne 'pk' && !$dropped{ $_->{index_name} // '' } }
      values %{ $source->{indexes}{$table} // {} };
    my @target_all = values %{ $target->{indexes}{$table} // {} };

    # the foreign keys of the target into this table
    for my $from (sort keys %{ $target->{foreign_keys} // {} }) {
      for my $fk (@{ $target->{foreign_keys}{$from} }) {
        next unless $fk->{to_table} eq $table;
        my $cols = $fk->{to_columns} // [];
        next unless _index_covers($old, $cols);
        next if _index_covers($new, $cols) || grep { _index_covers($_, $cols) } @target_all;
        DBIO::Exception->throw(sprintf
          "the primary key of %s is %s in the target, and the foreign key %s of %s references (%s) of it: the target has no key over those columns any more, and the server would refuse the constraint",
          $table, ($pk->action eq 'drop' ? 'gone' : 'composed differently (' . join(', ', @{ $pk->columns }) . ')'),
          defined $fk->{constraint_name} ? "'$fk->{constraint_name}'" : '(unnamed)', $from, join(', ', @$cols));
      }
    }

    my $served = sub {
      my ($cols) = @_;
      return _index_covers($new, $cols) || scalar grep { _index_covers($_, $cols) } @source_others;
    };

    for my $from (sort keys %{ $source->{foreign_keys} // {} }) {
      next unless exists $target_tables->{$from};
      my %target_fk = map { ($_->{constraint_name} // '') => $_ } @{ $target->{foreign_keys}{$from} // [] };
      for my $fk (@{ $source->{foreign_keys}{$from} }) {
        my @needs;
        push @needs, $fk->{to_columns}   if $fk->{to_table} eq $table;
        push @needs, $fk->{from_columns} if $from eq $table;
        next unless grep { _index_covers($old, $_) && !$served->($_) } @needs;
        my $stays = $target_fk{ $fk->{constraint_name} // '' };
        next if !$stays || changed_fk_fields($fk, $stays);
        next if $seen{ refaddr $fk }++;
        push @drops, DBIO::MySQL::Diff::ForeignKey->new(
          action => 'drop', table_name => $from, replaced => 1,
          constraint_name => $fk->{constraint_name}, fk_info => $fk);
        push @adds, DBIO::MySQL::Diff::ForeignKey->new(
          action => 'add', table_name => $from,
          constraint_name => $fk->{constraint_name}, fk_info => $fk);
      }
    }
  }
  return (\@drops, \@adds);
}

# Do the first columns of an index ($index, an introspected index hash) have
# the columns of a foreign key, in their order? FULLTEXT and SPATIAL indexes
# are no key for a foreign key.
sub _index_covers {
  my ($index, $columns) = @_;
  return 0 if ($index->{index_type} // '') =~ /FULLTEXT|SPATIAL/i;
  my @have = @{ $index->{columns} // [] };
  return 0 if !@$columns || @have < @$columns;
  for my $i (0 .. $#$columns) {
    return 0 unless defined $have[$i] && $have[$i] eq $columns->[$i];
  }
  return 1;
}

# Of the index creates, those that belong in the CREATE TABLE of a new table:
# for each AUTO_INCREMENT column that is not in the primary key, the first index
# the target has over it as its first column. Returns a hashref table =>
# [ { index_name, index_info } ] and the ops that are left.
sub _split_inline_indexes {
  my ($self, @index_ops) = @_;
  my $source_tables = $self->source->{tables} // {};
  my (%inline, %taken, @rest);
  for my $op (@index_ops) {
    my $table = $op->table_name;
    if ($op->action eq 'create' && !exists $source_tables->{$table}) {
      my $info = $op->index_info;
      my ($first) = @{ $info->{columns} // [] };
      my ($class_kw) = DBIO::MySQL::IndexType::index_type_split($info->{index_type});
      if (defined $first && !$class_kw && !$taken{$table}{$first}
          && grep { $_->{column_name} eq $first && $_->{is_auto_increment} && !$_->{is_pk} }
               @{ $self->target->{columns}{$table} // [] }) {
        $taken{$table}{$first} = 1;
        push @{ $inline{$table} }, { index_name => $op->index_name, index_info => $info };
        next;
      }
    }
    push @rest, $op;
  }
  return (\%inline, @rest);
}

# The target foreign keys of the tables the diff creates, split into those the
# CREATE TABLE of the table carries (a hashref table => [ fks ]) and those
# that are added after the indexes (the list of ADD ops). A foreign key is
# deferred when it references columns that the primary key of the referenced
# table does not start with and an index the diff creates does: at CREATE TABLE
# time that index is not there, and the server refuses the constraint (1822 on
# MySQL, errno 150 on MariaDB) (karr k81). It is deferred as well when an index
# the diff creates on the new table covers its own columns (karr k92).
sub _split_inline_foreign_keys {
  my ($self, $index_ops) = @_;
  my $source_tables = $self->source->{tables} // {};
  my $target        = $self->target;

  my %created_index;
  push @{ $created_index{ $_->table_name } }, $_->index_info
    for grep { $_->action eq 'create' } @$index_ops;

  my (%inline, @deferred);
  for my $table (sort keys %{ $target->{foreign_keys} // {} }) {
    my $fks = $target->{foreign_keys}{$table};
    if (exists $source_tables->{$table}) {
      $inline{$table} = $fks;     # not a table the diff creates: not looked at
      next;
    }
    for my $fk (@$fks) {
      my $to      = $fk->{to_table};
      my $columns = $fk->{to_columns} // [];
      my $by_pk = grep { ($_->{origin} // '') eq 'pk' && _index_covers($_, $columns) }
        values %{ $target->{indexes}{$to} // {} };
      unless ($by_pk) {
        my @pk = map { $_->{column_name} } grep { $_->{is_pk} } @{ $target->{columns}{$to} // [] };
        $by_pk = _index_covers({ columns => \@pk }, $columns);
      }
      my $waits = !$by_pk && grep { _index_covers($_, $columns) } @{ $created_index{$to} // [] };
      # An index the diff creates on the table itself over the columns of the
      # foreign key: in the CREATE TABLE the server makes an index of its own
      # for the constraint, and the CREATE INDEX after it is a second one over
      # the same columns. Added after the index, the constraint finds it there
      # (karr k92).
      $waits ||= grep { _index_covers($_, $fk->{from_columns} // []) } @{ $created_index{$table} // [] };
      if ($waits) {
        push @deferred, DBIO::MySQL::Diff::ForeignKey->new(
          action => 'add', table_name => $table,
          constraint_name => $fk->{constraint_name}, fk_info => $fk,
        );
      }
      else {
        push @{ $inline{$table} }, $fk;
      }
    }
  }
  return (\%inline, @deferred);
}

# The order of the tables the diff creates (core hands them over in name
# order, which puts a child before its parent): a hashref table => position,
# worked out by the rule install_ddl uses (DBIO::MySQL::DDL::order_by_foreign_keys).
# $inline_fks is changed in place: the foreign keys of a cycle that cannot stand
# in the CREATE TABLE are taken out and returned as ADD ops, to go after all
# tables and indexes.
sub _order_new_tables {
  my ($self, $inline_fks) = @_;
  my $source_tables = $self->source->{tables} // {};
  my @new = grep { !exists $source_tables->{$_} } sort keys %{ $self->target->{tables} // {} };

  my (%position, @held_ops);
  my $at = 0;
  for my $step (DBIO::MySQL::DDL::order_by_foreign_keys(
    [ map { { name => $_, fks => ($inline_fks->{$_} // []) } } @new ],
    sub { $_[0]{to_table} },
  )) {
    my $name = $step->{table}{name};
    $position{$name} = $at++;
    next unless @{ $step->{held} };
    $inline_fks->{$name} = $step->{inline};
    push @held_ops, map {
      DBIO::MySQL::Diff::ForeignKey->new(
        action => 'add', table_name => $name,
        constraint_name => $_->{constraint_name}, fk_info => $_,
      )
    } @{ $step->{held} };
  }
  return (\%position, @held_ops);
}

# Which index drops would leave a foreign key that stays without an index
# (1553), and what to do about it. Returns the index drops and the index
# creates, in the order they are written:
#   - the drop of an index a foreign key still needs, with no other index of
#     the table left over those columns, is preceded by the create of the
#     index that takes its place (one of the creates of this diff);
#   - when that index has the name of the dropped one (a changed index), the
#     two are one ALTER TABLE ... DROP INDEX, ADD INDEX;
#   - when the replacement is over columns the table does not have yet, the
#     whole of it is written where the creates are, and the column changes
#     come first -- unless a column of the dropped index leaves, which cannot
#     be put right and dies;
#   - when the primary key of the TARGET starts with the columns the foreign key
#     needs (the key grows by them, or a UNIQUE index becomes the key), that key
#     is the index that takes its place: the drop goes into a third list, which
#     the caller writes after the key operations (karr k107); but the index the
#     server made for the constraint itself is dropped by the server with the
#     key, so there the foreign key is dropped before the index and added again
#     after the key;
#   - no replacement dies, naming the index and the foreign key.
# Returns the drops, the creates, those late drops and the drops and adds of the
# foreign keys that go around an index the server drops itself.
# The foreign keys that count are those that are still there when the index is
# dropped: the ones of the source that the target keeps as they are, and those
# of the CREATE TABLEs (which come first). Constraints that are dropped or
# changed are dropped first; those that are added come after the creates.
sub _protect_foreign_key_indexes {
  my ($self, $drops, $creates, $inline_fks, $taken_along) = @_;
  my ($source, $target) = ($self->source, $self->target);

  # A foreign key the primary key operation drops and adds again (karr k107) is
  # not there when the indexes are dropped: nothing to protect.
  my %taken = map { refaddr($_->fk_info) => 1 } @{ $taken_along // [] };

  # The constraints there are when the first index is dropped, as
  # [ table, columns ]: each one needs an index on the referencing table over
  # its columns, and one on the referenced table.
  my @alive;
  my $target_tables = $target->{tables} // {};
  for my $table (sort keys %{ $source->{foreign_keys} // {} }) {
    next unless exists $target_tables->{$table};
    my %new = map { ($_->{constraint_name} // '') => $_ } @{ $target->{foreign_keys}{$table} // [] };
    for my $fk (@{ $source->{foreign_keys}{$table} }) {
      my $new = $new{ $fk->{constraint_name} // '' } or next;
      next if changed_fk_fields($fk, $new) || $taken{ refaddr $fk };
      push @alive, [ $table, $fk->{from_columns} ], [ $fk->{to_table}, $fk->{to_columns} ];
    }
  }
  for my $table (sort keys %$inline_fks) {
    next if exists( ($source->{tables} // {})->{$table} );
    push @alive, [ $table, $_->{from_columns} ], [ $_->{to_table}, $_->{to_columns} ]
      for @{ $inline_fks->{$table} };
  }

  my (%dropped, %before, %replace_drop, %remove_drop, %after, %replace_create, %remove_create, %late);
  my (@extra_drops, @extra_adds);
  $dropped{ $_->table_name }{ $_->index_name } = 1 for @$drops;

  for my $drop (@$drops) {
    my ($table, $info) = ($drop->table_name, $drop->index_info);
    my @need = grep { $_->[0] eq $table && _index_covers($info, $_->[1]) } @alive;
    next unless @need;

    my $wants = sub {
      my ($index, $need) = @_;
      return _index_covers($index, $need->[1]);
    };
    # The primary key is one of the surviving indexes.
    my @survivors = grep { !$dropped{$table}{ $_->{index_name} // '' } && $_->{index_name} ne $drop->index_name }
      values %{ $source->{indexes}{$table} // {} };
    push @survivors, { columns => [ primary_key_columns($source->{columns}{$table}) ] };

    my @open = grep {
      my $need = $_;
      !grep { $wants->($_, $need) } @survivors;
    } @need;
    next unless @open;

    # The key the target has is one of the indexes that are left, once the key
    # operation has been done: the drop waits for it. The foreign key needs
    # its index at every moment, so the index stays until the key is there --
    # unless a column of the index leaves with this diff, which cannot wait.
    my %stays = map { $_->{column_name} => 1 } @{ $target->{columns}{$table} // [] };
    my $target_key = { columns => [ primary_key_columns($target->{columns}{$table}) ] };
    if (!grep { !$wants->($target_key, $_) } @open
        and !grep { !$stays{$_} } @{ $info->{columns} // [] }) {
      # The index the server made for the constraint itself (the name of the
      # constraint, the columns of the foreign key) is dropped by the server
      # when the key that replaces it is created, and a DROP INDEX after the
      # key finds nothing: the foreign key is dropped before and added again
      # after, with the key (as for a key change that it needs), and the index
      # goes before it as ever.
      my %target_fk = map { ($_->{constraint_name} // '') => $_ } @{ $target->{foreign_keys}{$table} // [] };
      my @server_made = grep {
        my $fk = $_;
        !$taken{ refaddr $fk }
          && ($fk->{constraint_name} // '') eq $drop->index_name && !$info->{is_unique}
          && join("\0", @{ $fk->{from_columns} }) eq join("\0", @{ $info->{columns} // [] })
          && $target_fk{ $fk->{constraint_name} } && !changed_fk_fields($fk, $target_fk{ $fk->{constraint_name} })
      } @{ $source->{foreign_keys}{$table} // [] };
      if (@server_made && !grep {
        my $need = $_;
        !grep { join("\0", @{ $_->{from_columns} }) eq join("\0", @{ $need->[1] }) } @server_made
      } @open) {
        for my $fk (@server_made) {
          $taken{ refaddr $fk } = 1;
          push @extra_drops, DBIO::MySQL::Diff::ForeignKey->new(
            action => 'drop', table_name => $table, replaced => 1,
            constraint_name => $fk->{constraint_name}, fk_info => $fk);
          push @extra_adds, DBIO::MySQL::Diff::ForeignKey->new(
            action => 'add', table_name => $table,
            constraint_name => $fk->{constraint_name}, fk_info => $fk);
        }
        next;
      }
      $late{ refaddr $drop } = 1;
      next;
    }

    my ($replacement) = grep {
      my $create = $_;
      $create->table_name eq $table
        && !grep { !$wants->($create->index_info, $_) } @open;
    } @$creates;
    my $needed_by = join ', ', map { '(' . join(', ', @{ $_->[1] }) . ')' } @open;
    DBIO::Exception->throw(sprintf "DBIO::MySQL::Diff: the index %s on %s is dropped, and a foreign key over the columns %s of that table still needs one: no index of this diff takes its place, and the server refuses (1553)",
      $drop->index_name, $table, $needed_by)
      unless $replacement;

    next if $remove_create{ refaddr $replacement };    # moved for another drop already
    my %have = map { $_->{column_name} => 1 } @{ $source->{columns}{$table} // [] };
    my $early = !%have || !grep { !$have{$_} } @{ $replacement->index_info->{columns} };
    my $merge = $replacement->index_name eq $drop->index_name;

    if (!$early) {
      my %stay = map { $_->{column_name} => 1 } @{ $target->{columns}{$table} // [] };
      DBIO::Exception->throw(sprintf "DBIO::MySQL::Diff: the index %s on %s is dropped, a foreign key still needs one, its replacement is over columns the table does not have yet, and a column of the dropped index leaves: no order of the statements is valid",
        $drop->index_name, $table)
        if grep { !$stay{$_} } @{ $info->{columns} };
    }

    if ($merge) {
      my $op = DBIO::MySQL::Diff::Index->new(
        action => 'replace', table_name => $table, index_name => $drop->index_name,
        index_info => $replacement->index_info, old_index_info => $info,
      );
      if ($early) { $replace_drop{ refaddr $drop } = $op; $remove_create{ refaddr $replacement } = 1 }
      else        { $remove_drop{ refaddr $drop } = 1;    $replace_create{ refaddr $replacement } = $op }
    }
    elsif ($early) {
      push @{ $before{ refaddr $drop } }, $replacement;
      $remove_create{ refaddr $replacement } = 1;
    }
    else {
      $remove_drop{ refaddr $drop } = 1;
      push @{ $after{ refaddr $replacement } }, $drop;
    }
  }

  my @late = grep { $late{ refaddr $_ } } @$drops;
  my @drops = map {
    my $id = refaddr $_;
    $late{$id} ? ()
      : $replace_drop{$id} ? $replace_drop{$id}
      : $remove_drop{$id} ? ()
      : (@{ $before{$id} // [] }, $_)
  } @$drops;
  my @creates = map {
    my $id = refaddr $_;
    $remove_create{$id} ? ()
      : $replace_create{$id} ? $replace_create{$id}
      : ($_, @{ $after{$id} // [] })
  } @$creates;
  return (\@drops, \@creates, \@late, \@extra_drops, \@extra_adds);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff - Compare two introspected MySQL/MariaDB models

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::MySQL::Diff> compares two introspected MySQL/MariaDB models
(as produced by L<DBIO::MySQL::Introspect>) and produces a list of
structured diff operations.

    my $diff = DBIO::MySQL::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: the views that are dropped (or
dropped to be created again with a new definition), the foreign keys that are
dropped, tables, the indexes that are dropped, columns, the primary keys that
are added or changed or dropped (L<DBIO::MySQL::Diff::PrimaryKey>), the
indexes that are created, the foreign keys that are added, the views that are
created. A view is no table: it has operations of its own
(L<DBIO::MySQL::Diff::View>), is set aside from everything else, and a changed
definition is a C<DROP VIEW> and a C<CREATE VIEW> around all of it. Views are
created in the order of what they read, a view after the views it reads, and
dropped in the reverse order, the same order L<DBIO::MySQL::DDL/install_ddl>
creates them in (L<DBIO::MySQL::DDL/order_views>); views that read each other
in a cycle are refused with a L<DBIO::Exception> naming them. See
L<DBIO::MySQL::Diff::View/The order of the views>. The foreign keys that need
the old primary key of a table as their index are among the dropped ones and
among the added ones, around the key. An index is dropped while the columns it
is over are all still there, and created once they are what the target says;
an index that has changed is both, and its two statements stand on either side
of the column changes. The server refuses a table, a column or an index that a
constraint still needs, so the constraint goes first and comes last. Where a
foreign key that stays needs an index that is dropped, the index that takes
its place is created before the drop, and where a foreign key of a new table
needs an index that is created by the same diff, it is added after it, and not
in the C<CREATE TABLE>. So is a foreign key of a new table whose columns an
index the diff creates on that table covers: in the C<CREATE TABLE> the server
would make an index of its own for it, and the index of the diff would be a
second one over the same columns. See L<DBIO::MySQL::Diff::Index>.

An index that a foreign key needs, and that the target replaces by a primary
key (the key of a child grows by the column of its foreign key, a UNIQUE index
becomes the key), is counted by the target: the new key is the index that is left.
The index goes after the key operation -- the foreign key needs its index at
every moment. The one the server made for the constraint itself, named
like it and over its columns, is dropped by the server the moment a key that
can serve the constraint exists (a C<DROP INDEX> after that finds nothing,
measured on MySQL 8.0), so there the foreign key is dropped before the index and
added again after the key.

Foreign key indexes and the second diff: install and upgrade give
a constraint the fixed name C<< <table>_<columns>_fk >>, and the server names the
index it makes for a constraint after the constraint and uses an index that is
there already (measured on MySQL 8.0 and MariaDB 11.8; a C<DROP FOREIGN KEY>
leaves the index). So the index of an installed table, the index the upgrade
writes (C<CREATE INDEX> before C<ADD CONSTRAINT>) and the one the server makes
are one index with one name, and the diff after an upgrade has nothing to say; the
indexes of foreign keys are not left out of the comparison. A constraint the
server named C<< <table>_ibfk_N >> is dropped with its index and gets both under the
fixed name. An C<AUTO_INCREMENT> column that leaves the primary key has the UNIQUE
index of the target created before the key (L<DBIO::MySQL::Diff::PrimaryKey>).

The tables the diff creates come in foreign key order, a referenced table before
the one that references it, as L<DBIO::MySQL::DDL> creates them
(L<DBIO::MySQL::DDL/order_by_foreign_keys>); tables free of each other stay in
name order. A foreign key that closes a cycle between new tables is added with
C<ALTER TABLE> after all tables and indexes.

The collation of a table that exists is compared (C<table_collation>); a change
is C<ALTER TABLE ... CONVERT TO>, or a L<DBIO::Exception> where the data would not
provably survive, and the character set and collation of the columns of such a
table are then not compared. Which cases convert and which are
refused, with the measurements, is in L<DBIO::MySQL::Diff::Table/The collation of
an existing table>. A target from C<target_from_compiled> carries no table
collation and prescribes none.

=head2 Tables of other databases

A table named C<database.table> is compared in its database. The model of a
diff carries them apart from the tables of the current database, in
C<other_databases>, a hash of database name to a model of the same shape --
the tables of the schema that live there, and for the source nothing else of
that database (L<DBIO::MySQL::Deploy> builds both sides: the source
introspected in the other database, the target in a temporary database made
for it). Each such pair is diffed by a diff of its own, as the current
database's is, and its operations come I<first> in the list, each carrying
C<database>: the operation is written against C<`database`.`table`>, and
L</summary> names the database. A table of that database the schema does not
name is not in the models and is never dropped. C<target_from_compiled> builds
no such model: it leaves the table out.

=head1 METHODS

=head2 target_from_compiled

    my $target = DBIO::MySQL::Diff->target_from_compiled($compiled_model);

Translates the neutral model from L<DBIO::Schema::ModelCompiler> into the
MySQL/MariaDB introspect-shaped model that C<diff> consumes.

The compiled model uses C<native_type> (as produced by L<DBIO::MySQL::Adapter>,
e.g. C<BIGINT>, C<CHAR(32)>, C<TINYINT(1)>). This method maps those into the
exact lowercase C<data_type> and parameterised C<column_type> strings that
L<DBIO::MySQL::Introspect::Columns> returns from C<information_schema.columns>.

C<character_set> and C<collation> are left C<undef> on non-text columns (numeric,
binary, datetime) to match what MariaDB/MySQL reports for those types. For text
and char columns the server assigns a charset/collation from the database
default; since a portable schema does not prescribe a charset, those fields are
also left C<undef> in the target so the diff engine sees both sides as empty and
does not emit phantom changes. See ESCALATION NOTE in the source.

A table named C<database.table> is a table of another database
(L<DBIO::MySQL::DDL/install_ddl>): the diff reads the current
database alone, so the target leaves it out, and the live database is not
asked about it. A name that names nothing (two dots, an empty half) and a view
name with a dot are refused with a L<DBIO::Exception>
(L<DBIO::MySQL::Identifier/check_table_name>).

=head2 summary

The summary of the operations, one line each; an operation on a table of
another database is followed by C<(database NAME)>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
