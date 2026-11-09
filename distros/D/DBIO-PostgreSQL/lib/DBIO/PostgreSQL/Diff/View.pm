package DBIO::PostgreSQL::Diff::View;
# ABSTRACT: Diff operations for PostgreSQL views and materialized views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Diff::Column ();
use DBIO::PostgreSQL::Util qw(quote_qualified trim_end);

__PACKAGE__->mk_diff_accessors(qw(schema_name table_name table_info replaced));






my %KIND = (
  v => 'VIEW',
  m => 'MATERIALIZED VIEW',
);


sub is_view {
  my ($class, $info) = @_;
  return $info && $KIND{ $info->{kind} // '' } ? 1 : 0;
}

# The views among the entries of a tables section.
sub _views {
  my ($tables) = @_;
  return { map { $_ => $tables->{$_} } grep { __PACKAGE__->is_view($tables->{$_}) } keys %$tables };
}

# A definition as it is compared and written: pg_get_viewdef hands it back
# with a blank ahead of it and a semicolon after it.
sub _definition {
  my ($info) = @_;
  my $definition = $info->{view_definition} // '';
  $definition =~ s/\A\s+//;
  return trim_end($definition, ';');
}

# The keys of $views in the order of dependency: each after the views it
# stands on.
sub _in_dependency_order {
  my ($views) = @_;
  my (%seen, @order);
  my $visit;
  $visit = sub {
    my ($key) = @_;
    return if $seen{$key}++;
    $visit->($_) for sort grep { $views->{$_} } @{ $views->{$key}{depends_on} // [] };
    push @order, $key;
  };
  $visit->($_) for sort keys %$views;
  undef $visit;
  return @order;
}


# The closure of @todo over the views that stand on them.
sub _with_standing_on {
  my ($src, @todo) = @_;
  my %dependents;
  for my $key (keys %$src) {
    push @{ $dependents{$_} }, $key for @{ $src->{$key}{depends_on} // [] };
  }
  my %rebuilt;
  while (defined(my $key = shift @todo)) {
    next if $rebuilt{$key}++;
    push @todo, @{ $dependents{$key} // [] };
  }
  return \%rebuilt;
}

# The views whose definition differs in the target.
sub _changed_definition {
  my ($src, $tgt) = @_;
  return grep {
    $tgt->{$_}
      && $src->{$_}{kind} eq 'v' && $tgt->{$_}{kind} eq 'v'
      && _definition($src->{$_}) ne _definition($tgt->{$_})
  } keys %$src;
}

sub rebuilt {
  my ($class, $source, $target, $source_cols, $target_cols) = @_;
  my $src = _views($source // {});
  my $tgt = _views($target // {});

  my @todo = _changed_definition($src, $tgt);

  # A column that changes its type is the one change PostgreSQL does not make
  # under a view: the views that read it are rebuilt around it. Only views the
  # target has; one it does not have, and a materialized view, are refused
  # where the column is (Diff::Column).
  if ($source_cols && $target_cols) {
    my $reading = DBIO::PostgreSQL::Diff::Column->type_changed_readers(
      $source_cols, $target_cols, $source, $target);
    push @todo, grep {
      $tgt->{$_} && $src->{$_}{kind} eq 'v' && $tgt->{$_}{kind} eq 'v'
    } keys %$reading;
  }

  return _with_standing_on($src, @todo);
}


sub with_dependents {
  my ($class, $tables, @keys) = @_;
  my $views = _views($tables // {});

  my %dependents;
  for my $key (keys %$views) {
    push @{ $dependents{$_} }, $key for @{ $views->{$key}{depends_on} // [] };
  }

  my %found;
  while (defined(my $key = shift @keys)) {
    next if !$views->{$key} || $found{$key}++;
    push @keys, @{ $dependents{$key} // [] };
  }
  return grep { $found{$_} } reverse _in_dependency_order($views);
}


sub drop_sql {
  my ($class, $info) = @_;
  return sprintf 'DROP %s %s;', $KIND{ $info->{kind} },
    quote_qualified(@{$info}{qw( schema_name table_name )});
}


sub _name {
  my ($info) = @_;
  return "$info->{schema_name}.$info->{table_name}";
}

sub _refuse_changed_matview {
  my ($info) = @_;
  my $name = _name($info);
  die join "\n",
    "refusing to diff: materialized view $name has another definition in the target",
    '',
    'A materialized view cannot be given another definition in place: it has to be',
    'dropped and created again, which builds its data anew and takes the indexes on',
    'it with it. No statement was generated.',
    '',
    'Drop it yourself when that is acceptable,',
    '  DROP MATERIALIZED VIEW ' . quote_qualified(@{$info}{qw( schema_name table_name )}) . ';',
    'and diff again: the diff then creates it as the target has it, with the indexes',
    'the target has on it.',
    '';
}

sub _refuse_matview_on_rebuilt_view {
  my ($info, @views) = @_;
  my $name = _name($info);
  die join "\n",
    sprintf(
      'refusing to diff: materialized view %s stands on %s, which changes, and would have to be dropped and created again with it',
      $name, join(', ', map { "view $_" } @views),
    ),
    '',
    'A view with another definition is dropped and created again, and so is',
    'everything that reads it. For a materialized view that builds its data anew',
    'and takes the indexes on it with it. No statement was generated.',
    '',
    'Drop it yourself when that is acceptable,',
    '  DROP MATERIALIZED VIEW ' . quote_qualified(@{$info}{qw( schema_name table_name )}) . ';',
    'and diff again: the diff then creates it as the target has it, with the indexes',
    'the target has on it.',
    '';
}

sub _refuse_without_definition {
  my ($info, $in_database) = @_;
  DBIO::PostgreSQL::Diff::NoStatement->refuse_without_definition(
    kind        => lc $KIND{ $info->{kind} },
    name        => _name($info),
    in_database => $in_database,
    from        => 'pg_get_viewdef',
  );
}

sub _op {
  my ($class, $action, $info, @more) = @_;
  return $class->new(
    action      => $action,
    schema_name => $info->{schema_name},
    table_name  => $info->{table_name},
    table_info  => $info,
    @more,
  );
}

sub diff {
  my ($class, $source, $target, $source_cols, $target_cols) = @_;
  $source //= {};
  $target //= {};
  my $src = _views($source);
  my $tgt = _views($target);

  for my $key (sort keys %$tgt) {
    my ($old, $new) = ($src->{$key}, $tgt->{$key});
    next unless $old && $old->{kind} eq 'm' && $new->{kind} eq 'm';
    _refuse_changed_matview($new) if _definition($old) ne _definition($new);
  }

  my $rebuilt = $class->rebuilt($source, $target, $source_cols, $target_cols);
  for my $key (sort keys %$rebuilt) {
    next unless $src->{$key}{kind} eq 'm' && $tgt->{$key};
    _refuse_matview_on_rebuilt_view(
      $src->{$key}, grep { $rebuilt->{$_} } @{ $src->{$key}{depends_on} // [] },
    );
  }

  # What goes, each view ahead of the ones it stands on: the rebuilt ones to
  # stay where they are, the rest for the removals.
  my (@ahead, @gone);
  for my $key (reverse _in_dependency_order($src)) {
    if ($rebuilt->{$key}) {
      push @ahead, $class->_op(drop => $src->{$key}, replaced => 1);
    }
    elsif (!exists $target->{$key}) {
      push @gone, $class->_op(drop => $src->{$key});
    }
  }

  # What comes, each view after the ones it stands on: the views the source
  # does not have, and the rebuilt ones the target has.
  my @create;
  for my $key (_in_dependency_order($tgt)) {
    next if exists $source->{$key} && !$rebuilt->{$key};
    _refuse_without_definition($tgt->{$key}, exists $source->{$key})
      unless length _definition($tgt->{$key});
    push @create, $class->_op(create => $tgt->{$key});
  }

  return (@ahead, @create, @gone);
}


sub qualified_name {
  my ($self) = @_;
  return $self->schema_name . '.' . $self->table_name;
}


sub as_sql {
  my ($self) = @_;
  my $info   = $self->table_info // {};
  my $action = $self->action // '';
  my $kind   = $KIND{ $info->{kind} // '' };
  my $object = sprintf '%s %s', lc($kind // 'relation'),
    join '.', grep { defined } $self->schema_name, $self->table_name;

  DBIO::PostgreSQL::Diff::NoStatement->throw(
    $self, $object, 'its table_info is not a view or a materialized view',
  ) unless $kind;
  my $name = quote_qualified($self->schema_name, $self->table_name);

  if ($action eq 'create') {
    my $definition = _definition($info);
    DBIO::PostgreSQL::Diff::NoStatement->throw(
      $self, $object, 'its table_info has no definition',
    ) unless length $definition;
    return sprintf 'CREATE %s %s AS %s;', $kind, $name, $definition;
  }
  elsif ($action eq 'drop') {
    return sprintf 'DROP %s %s;', $kind, $name;
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object);
}


sub summary {
  my ($self) = @_;
  return sprintf '  %s%s: %s',
    ($self->action eq 'create' ? '+' : '-'),
    lc $KIND{ $self->table_info->{kind} }, $self->qualified_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::View - Diff operations for PostgreSQL views and materialized views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a diff operation on a view or a materialized view: C<CREATE VIEW>
/ C<CREATE MATERIALIZED VIEW> from the definition the catalog gives, or
C<DROP VIEW> / C<DROP MATERIALIZED VIEW>.

The model files views among the tables (L<DBIO::PostgreSQL::Introspect::Tables>,
C<kind> C<v> and C<m>), and this class reads them from there.
L<DBIO::PostgreSQL::Diff::Table> leaves them to it, and
L<DBIO::PostgreSQL::Diff::Column> has nothing to do for them: a view's columns
are what its definition says.

A view is compared by its definition (C<pg_get_viewdef>), like an index by its
(ADR 0003). One that differs is dropped and created again -- see L</diff>.

=head1 ATTRIBUTES

=head2 schema_name

The schema of the view.

=head2 table_name

The name of the view.

=head2 table_info

The view's entry in the C<tables> section of the model: C<kind>,
C<view_definition>, C<depends_on>.

=head2 replaced

True on a C<drop> that belongs to the rebuilding of views (L</rebuilt>) and
therefore stays ahead of the C<create>s that follow it, instead of going to
the removals (L<DBIO::PostgreSQL::Diff/ORDER OF OPERATIONS>): the drop of a
view this diff creates again, and the drop of one that goes for good but
stands on a view that is created again -- PostgreSQL does not drop a view
while another depends on it.

=head1 METHODS

=head2 is_view

    next if DBIO::PostgreSQL::Diff::View->is_view($tables->{$key});

True for an entry of the C<tables> section that is a view or a materialized
view, and so this class's to create and drop.

=head2 rebuilt

    my $rebuilt = DBIO::PostgreSQL::Diff::View->rebuilt(
        $source_tables, $target_tables, $source_columns, $target_columns);

The views of the source that have to make way for a change, as a hashref of
their keys: every view whose definition differs in the target, every view the
target has again that reads a column whose type changes in the target
(L<DBIO::PostgreSQL::Diff::Column/type_changed_readers>; only with the
C<columns> sections given), and every view and materialized view that stands
on one of those, directly or through another. L</diff> drops them all and
creates again the ones the target has -- but refuses where a materialized view
the target keeps is among them. L<DBIO::PostgreSQL::Diff::Trigger> asks for the
same set, because C<DROP VIEW> takes the triggers of a view with it.

A materialized view that reads a column whose type changes is not among them:
it is not built anew for that, and L<DBIO::PostgreSQL::Diff::Column/diff>
refuses the change.

=head2 with_dependents

    my @keys = DBIO::PostgreSQL::Diff::View->with_dependents($tables, @view_keys);

The views named, and every view and materialized view of C<$tables> that
stands on one of them, directly or through another -- in the order they can
be dropped, each ahead of the views it stands on.
L<DBIO::PostgreSQL::Diff::Column> names them as what has to go before a
column they read can change its type.

=head2 drop_sql

    my $sql = DBIO::PostgreSQL::Diff::View->drop_sql($tables->{$key});

C<DROP VIEW schema.name;> or C<DROP MATERIALIZED VIEW schema.name;> for a
view's entry in the C<tables> section: the statement a refusal names as the
way out.

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::View->diff($source_tables, $target_tables);

Compares the views and materialized views of two C<tables> sections.

One only the target has is created, one only the source has is dropped.

A column that changes its type under a view is the other cause: PostgreSQL does
not alter it while a view reads it, so every view of the database that reads
the column -- and every view that stands on those -- is dropped ahead of the
change and created again after it, from the target's definition.
L<DBIO::PostgreSQL::Diff> puts these drops ahead of the changes to tables and
columns, and C<Deploy::apply> runs the statements in one transaction. A
materialized view is not built anew for it, and a view only the database has
is not created again: L<DBIO::PostgreSQL::Diff::Column/diff> refuses the
change for either -- a materialized view that reads the column or stands on a
view that does -- and names it.

A view whose definition differs is dropped and created again: PostgreSQL has
no statement that changes a view to any other definition (C<CREATE OR REPLACE
VIEW> can only add columns at the end). Every view that stands on it has to be
out of the way for that, so those are dropped ahead of it and -- if the target
has them -- created again after it, the same definition or not. What is lost
with a view that is dropped is what the model does not hold: the privileges
granted on it, its comment, its options.

Among themselves the operations follow the dependency the model carries
(C<depends_on>), not the names: a view is created after the views it reads and
dropped before them.

Three things are refused, with C<refusing to diff: ...> and no statement:

=over 4

=item * a materialized view whose definition differs. Dropping and creating it
again builds its data anew and takes its indexes with it.

=item * a materialized view the target keeps, on a view that is dropped and
created again. It would have to be rebuilt with it, which builds its data
anew and takes its indexes with it. (For the type of a column a view reads,
L<DBIO::PostgreSQL::Diff::Column/diff> refuses it first, naming the column.)

=item * a view to create, or to create again, that the target model has no
definition for (L<DBIO::PostgreSQL::Diff::NoStatement>).

=back

A relation that is a view on one side and something else on the other is not
this class's to decide: L<DBIO::PostgreSQL::Diff::Table/diff> refuses it.

Nor is a materialized view to create whose name differs only in upper and
lower case from one to drop -- C<Totals> in the target, C<totals> in the
database. L<DBIO::PostgreSQL::Diff::Table/diff> refuses that as well, together
with the tables of that kind, because the drop takes the data and the indexes
(L<DBIO::PostgreSQL::Diff::CaseOnly>). A I<view> in two spellings is this
class's and is not refused: it is created under the one name and dropped
under the other, which loses what every view that is created again loses.

=head2 qualified_name

    my $fqn = $op->qualified_name;  # 'api.active_users'

The schema-qualified name as a reader sees it, unquoted. It is what
L</summary> prints and is not SQL.

=head2 as_sql

Returns C<CREATE VIEW schema.name AS ...;> or C<DROP VIEW schema.name;>, with
C<MATERIALIZED VIEW> for a materialized view.

Schema and view are identifiers by the server's rule
(L<DBIO::PostgreSQL::Util/quote_ident>). The definition is the server's own
text (C<pg_get_viewdef>) and is written as given, without the blank ahead of
it and the semicolon after it.

A C<DROP> has no C<CASCADE>: what stands on the view and is in the model has
been dropped ahead of it, and for anything else PostgreSQL refuses the
statement.

An operation whose C<table_info> is not a view's or a materialized view's
has no statement, nor has a C<create> without a definition or an C<action>
this class does not know: C<as_sql> dies
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>). L</diff> builds no such
operation; one built by hand can be.

=head2 summary

Returns a one-line description such as C<+view: api.active_users> or
C<-materialized view: public.totals>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
