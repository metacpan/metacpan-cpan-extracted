package DBIO::Introspect::Base;
# ABSTRACT: Base class for DBIO driver introspectors

use strict;
use warnings;

our $VERSION = '0.900004';

our $CONTRACT_VERSION = '1.2';



sub contract_version { $CONTRACT_VERSION }


sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}


sub dbh { $_[0]->{dbh} }


sub model { $_[0]->{model} //= $_[0]->_build_model }

sub _build_model {
  my ($self) = @_;
  die ref($self) . '::_build_model not implemented';
}


sub _aggregate_by {
  my ($class, $rows, $key_field) = @_;
  my %result;
  for my $row (@{ $rows // [] }) {
    my $key = $row->{$key_field} // next;
    push @{ $result{$key} }, $row;
  }
  return \%result;
}


sub _aggregate_by_ordered {
  my ($class, $rows, $key_field) = @_;
  my @order;
  my %index;
  for my $row (@{ $rows // [] }) {
    my $key = $row->{$key_field} // next;
    unless (exists $index{$key}) {
      $index{$key} = scalar @order;   # 0-based slot for this key
      push @order, [ $key, [] ];
    }
    push @{ $order[ $index{$key} ][1] }, $row;
  }
  return \@order;
}


sub table_keys {
  my ($self) = @_;
  return [ sort keys %{ $self->model->{tables} || {} } ];
}


sub table_columns {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} || [];
  return [ map { $_->{column_name} } @$cols ];
}


sub table_columns_info {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} || [];
  my %info;
  # The primary key is folded into is_nullable, the way the
  # driver introspectors that override this method already did. It states what
  # DBIO's model holds -- the row's identity cannot be NULL -- and not what the
  # engine would refuse; ClickHouse and SQLite both permit a key column to hold
  # NULL under the conditions the POD above names. An engine that permits it
  # overrides this method (ClickHouse does); there is no flag here. ADR 0038.
  for my $col (@$cols) {
    $info{ $col->{column_name} } = {
      data_type     => $col->{data_type},
      is_nullable   => (($col->{not_null} || $col->{is_pk}) ? 0 : 1),
      default_value => $col->{default_value},
      (defined $col->{size} ? (size => $col->{size}) : ()),
      (exists $col->{is_auto_increment}
        ? (is_auto_increment => $col->{is_auto_increment}) : ()),
    };
  }
  return \%info;
}


sub table_pk_info {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} || [];
  return [
    map  { $_->{column_name} }
    sort { ($a->{pk_position} || 0) <=> ($b->{pk_position} || 0) }
    grep { $_->{is_pk} } @$cols
  ];
}


sub table_uniq_info {
  my ($self, $key) = @_;
  my $model = $self->model;

  if (exists $model->{unique_constraints}) {
    return $model->{unique_constraints}{$key} || [];
  }

  my $indexes = $model->{indexes}{$key} || {};
  my @uniq;
  for my $name (sort keys %$indexes) {
    my $idx = $indexes->{$name};
    next unless $idx->{is_unique};
    next if ($idx->{origin} || '') eq 'pk';
    next if uc($name) eq 'PRIMARY';
    push @uniq, [ $name => $idx->{columns} ];
  }
  return \@uniq;
}


sub table_fk_info {
  my ($self, $key) = @_;
  my $fks = $self->model->{foreign_keys}{$key} || [];
  return [
    map {
      +{
        local_columns  => $_->{from_columns},
        remote_table   => $_->{to_table},
        remote_schema  => undef,
        remote_columns => $_->{to_columns},
        attrs          => {
          on_delete => $_->{on_delete},
          on_update => $_->{on_update},
        },
      }
    } @$fks
  ];
}


sub table_is_view {
  my ($self, $key) = @_;
  my $tbl = $self->model->{tables}{$key} || {};
  return ($tbl->{kind} || '') eq 'view' ? 1 : 0;
}


sub view_definition { return undef }


sub table_comment { return undef }


sub column_comment { return undef }


sub result_class_extra_statements { return () }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Introspect::Base - Base class for DBIO driver introspectors

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Base class for the driver-specific introspectors
(L<DBIO::PostgreSQL::Introspect>, L<DBIO::SQLite::Introspect>,
L<DBIO::MySQL::Introspect>). Provides C<new>, the C<dbh> accessor, and the
lazy C<model> builder. Subclasses must implement C<_build_model>.

=head1 ATTRIBUTES

=head2 dbh

The connected C<DBI> database handle. Required.

=head1 METHODS

=head2 contract_version

    my $v = $class->contract_version;

Returns C<$CONTRACT_VERSION>, the compatibility version of this base class's
public interface -- independent of the dist C<$VERSION> and unaffected by a
release that changes no contract shape. See L</CONTRACT VERSION> above and
ADR 0024.

=head2 new

    my $intro = $class->new(dbh => $dbh);

Blesses the argument hash directly; no validation. C<dbh> is required.

=head2 model

The introspected database model hashref. Built lazily on first access via
C<_build_model>, which every driver subclass implements (the base
version dies). The shape varies by driver.

=head2 _aggregate_by

    my $by_table = $class->_aggregate_by(\@rows, 'table_name');

Groups a flat array of row hashrefs into C<{ $key_value => [\%row, ...] }>.
Preserves row order within each group. The C<\@rows> arrayref is left
unmodified; a row whose key field is C<undef> is skipped.

=head2 _aggregate_by_ordered

    my $groups = $class->_aggregate_by_ordered(\@rows, 'constraint_name');
    for my $pair (@$groups) {
      my ($key, $group_rows) = @$pair;
      ...
    }

Like L</_aggregate_by>, but returns an ArrayRef of C<[ $key, [\%row, ...] ]>
pairs in B<first-seen key order>, so callers that need deterministic group
ordering (e.g. composite foreign-key columns, which must keep their declared
local/remote pairing) do not have to reimplement the grouping. Row order
within each group is preserved. Rows whose key field is C<undef> are skipped.

=head2 table_keys

Returns an ArrayRef of opaque table-key strings (typically C<schema.table>
or just C<table>). These are passed as C<$key> to all other contract methods.
Default: the sorted bare table names from the canonical C<tables> section.

=head2 table_columns

    my \@names = $intro->table_columns($key);

Ordered list of column names for C<$key>. Default: the C<column_name> of each
entry in the canonical C<columns> section, in declaration order.

=head2 table_columns_info

    my $info = $intro->table_columns_info($key);

Hashref C<{ col_name => { data_type, size, is_nullable, default_value,
is_auto_increment, ... } }>. Default: built from the canonical C<columns>
section -- C<size> and C<is_auto_increment> are included only when present on
the column.

C<is_nullable> is C<0> when the column carries C<not_null> B<or> when it is
part of the primary key (C<is_pk>), and C<1> otherwise. C<not_null> answers a
different question -- whether the column carries a C<NOT NULL> attribute --
and engines keep the primary-key constraint separate from that attribute, so
SQLite's C<PRAGMA table_info> reports C<notnull = 0> for a key column.

The fold is a statement about B<DBIO's model>, not a claim about what the
engine would refuse: C<is_pk> marks the column L</table_pk_info> names as the
row's identity, and an identity that can be NULL is not usable in the Row
layer. A key column is therefore C<< is_nullable => 0 >> however the model
spells its attribute, and the two contract methods cannot disagree about the
same column -- both read C<is_pk> off the same hashref. A model that carries
no C<is_pk> is unaffected.

That choice has a real cost on an engine that B<does> permit NULL in a key
column: the base reports C<< is_nullable => 0 >> for a column that holds
NULLs, L<DBIO::Generate> bakes it into the regenerated result class, and a
redeploy emits a stricter column than the one introspected. The escape is a
driver B<override of this method> -- which is what L<DBIO::ClickHouse::Introspect>
does deliberately, reading nullability out of the type string where ClickHouse
actually writes it. Two engines are known to permit it, both only under
precise conditions:

=over 4

=item * B<ClickHouse>, when the table is created with C<< SETTINGS
allow_nullable_key = 1 >>. MergeTree refuses a C<Nullable> column in the
sorting key only while that setting sits at its default C<0>.

=item * B<SQLite>, for any C<PRIMARY KEY> on a rowid table other than the
B<rowid alias> itself. This is SQLite's documented, deliberately-kept bug (see
"The PRIMARY KEY" in L<https://sqlite.org/lang_createtable.html>): C<CREATE
TABLE t (name TEXT PRIMARY KEY)> accepts C<INSERT INTO t (name) VALUES (NULL)>
repeatedly, and the NULLs do not even collide with one another. SQLite states
the exclusions itself -- it allows the NULL "unless the column is an INTEGER
PRIMARY KEY or the table is a WITHOUT ROWID table or a STRICT table or the
column is declared NOT NULL".

B<The declared type does not identify the alias>, and reading the rule as
"C<INTEGER> means no NULL" is wrong twice over. Only the exact declared type
C<INTEGER> makes a rowid alias, so C<id INT PRIMARY KEY> is an ordinary
indexed column with integer affinity -- and stores NULL. And a column-level
C<PRIMARY KEY DESC> is documented as not producing an alias either, so
C<id INTEGER PRIMARY KEY DESC> stores NULL as well, while the table-constraint
spelling C<PRIMARY KEY(id DESC)> does produce one. C<PRAGMA table_info> reports
C<type=INTEGER notnull=0 pk=1> for the alias and the C<DESC> non-alias alike.

The exact separator is C<PRAGMA index_list>: SQLite materialises every primary
key as an automatic C<origin = 'pk'> index B<except> the rowid alias, which is
the rowid itself and needs no index. On a rowid table, "declares a key but has
no C<pk>-origin index" is therefore the alias, with no parsing of the stored
C<CREATE TABLE> text. L<DBIO::SQLite::Introspect> overrides this method on
exactly that test.

A C<WITHOUT ROWID> table needs no case of its own: SQLite reports
C<notnull = 1> for its key columns itself, so the fold changes nothing there.

=back

B<A driver that takes this escape will make L</table_pk_info> and
C<is_nullable> disagree, and the Row layer says so.> That is the intended
outcome, not a defect in the override: introspection reports what the engine
really stores, L<DBIO::Generate> writes C<< is_nullable => 1 >> into the
generated result class, and L<DBIO::ResultSource/set_primary_key> then
C<carp>s that the key includes a nullable column and that Result-object
operations will fail. The warning is correct -- it is the same model statement
this fold is made of -- and arriving at load time is the point: the user learns
that the foreign table is not usable as a DBIO source when they load it, not
when a row cannot be found later.

Deciding this in the model rather than behind a capability flag: ADR 0038.

=head2 table_pk_info

    my \@pk_cols = @{ $intro->table_pk_info($key) };

Ordered list of primary key column names. Default: the C<is_pk> columns from
the canonical C<columns> section, ordered by C<pk_position> (composite keys
keep their declared order).

=head2 table_uniq_info

    my \@constraints = @{ $intro->table_uniq_info($key) };

List of C<[ $constraint_name, \@col_names ]> pairs. Default: the canonical
C<unique_constraints> section for C<$key> if that section exists; otherwise
derived from the C<indexes> section (unique indexes, skipping primary-key
backed ones and any index literally named C<PRIMARY>).

=head2 table_fk_info

    my \@fks = @{ $intro->table_fk_info($key) };

Each FK is a hashref:

    {
      local_columns  => [qw/author_id/],
      remote_table   => 'authors',
      remote_schema  => 'public',   # may be undef
      remote_columns => [qw/id/],   # may be [] (use remote PK)
      attrs          => {},
    }

Default: built from the canonical C<foreign_keys> section. C<remote_schema> is
always C<undef> (single-schema), and C<attrs> carries C<on_delete> /
C<on_update>.

=head2 table_is_view

Returns true if C<$key> is a view rather than a base table. Default: true when
the canonical C<tables> entry has C<< kind => 'view' >>.

=head2 view_definition

SQL text of the view definition, or C<undef>.

=head2 table_comment

Comment string for the table, or C<undef>.

=head2 column_comment

Comment string for a column, or C<undef>.

=head2 result_class_extra_statements

    my @stmts = $intro->result_class_extra_statements($key);

Optional hook for driver-specific emitter statements. Each element is an
arrayref C<[ $method_name, @args ]> which L<DBIO::Generate> emits as
C<__PACKAGE__->method_name(@args)>. The method name is a Perl identifier.
A plain string argument is emitted as a string literal; an argument that is
Perl code is a scalar reference (C<\"code">); any other reference is
serialised as a literal. Defaults to an empty list.

=head1 CONTRACT VERSION

This class exposes an independent compatibility version, distinct from
C<$VERSION> (the dist version injected by L<Dist::Zilla>'s
C<VersionFromMainModule>):

    my $v = $class->contract_version;

C<$CONTRACT_VERSION> bumps when the L</CANONICAL MODEL> shape or the normalized
contract methods (L</table_keys>, L</table_columns>, L</table_columns_info>,
L</table_pk_info>, L</table_uniq_info>, L</table_fk_info>, L</table_is_view>,
L</view_definition>, L</table_comment>, L</column_comment>,
L</result_class_extra_statements>) changes. The dist C<$VERSION> bumps on
every release, but two core releases at the same contract version remain
wire-compatible. Out-of-tree drivers should record the contract version they
were last tested against and compare it against core's at load time, warning
(or strict-failing under C<DBIO_STRICT_CONTRACT>) when the shapes have
drifted. See F<docs/adr/> for the contract-version policy.

=head1 CANONICAL MODEL

The hashref returned by L</model> is the substrate every contract method reads.
Its shape varies by driver, but there is one B<canonical> shape -- the
un-qualified, single-database shape shared by the single-schema drivers
(MySQL, Firebird, SQLite). The default contract implementations below are
written against it, so any driver whose C<_build_model> produces this shape
inherits a working contract for free. Drivers that diverge (PostgreSQL:
schema-qualified keys, case normalization, enum/identity/generated columns)
override the methods they need.

The canonical model has up to five top-level sections, each a hashref keyed by
B<table name> (bare, un-qualified):

=over 4

=item * C<tables> -- C<< { $table => { table_name => $table, kind => 'table'|'view' } } >>

=item * C<columns> -- C<< { $table => [ \%column, ... ] } >> in declaration
order. Each column: C<column_name>, C<data_type> (bare SQL type), C<size>
(C<undef>, a scalar length, or a C<[precision, scale]> pair), C<not_null>
(C<0>/C<1>), C<default_value> (or C<undef>), C<is_pk> / C<pk_position>
(primary-key membership and 1-based ordinal), and optionally
C<is_auto_increment>.

=item * C<indexes> -- C<< { $table => { $index_name => { is_unique, columns => [...], origin, index_type } } } >>.
C<origin> is C<'pk'> for a primary-key-backed index (skipped by
L</table_uniq_info>). C<index_type> is B<optional> -- the engine's index access
method / class (C<BTREE>, C<FULLTEXT>, C<SPATIAL>, C<HASH>; PostgreSQL
C<gin>/C<gist>/C<brin>/C<spgist>) -- carried only by drivers that introspect
and render it. It participates in the canonical index comparison
(L<DBIO::Diff::Compare/changed_index_fields>) as a I<bilateral> field: a type
change is a real diff only when B<both> the live and desired sides carry a
type, so a driver that leaves it C<undef> (the default) never produces a
phantom index migration for it. See ADR 0052.

=item * C<unique_constraints> -- (optional) C<< { $table => [ [ $name, \@cols ], ... ] } >>.
When present, it is the authoritative source for L</table_uniq_info>; when
absent, unique constraints are derived from the C<indexes> section.

=item * C<foreign_keys> -- C<< { $table => [ \%fk, ... ] } >>. Each FK:
C<from_columns>, C<to_table>, C<to_columns>, C<on_update>, C<on_delete>, and
optionally C<constraint_name> -- the live, server-assigned constraint name,
carried by drivers that can introspect it so the diff/deploy layer can prefer
the real name for FK C<DROP>/C<ALTER> instead of a generated one. C<constraint_name>
is FK metadata, not a compared attribute. See ADR 0021.

=back

=head1 NORMALIZED CONTRACT

Subclasses that are used as a generation source for L<DBIO::Generate>
implement these methods. The first seven ship B<default implementations> that
read the L</CANONICAL MODEL>; a single-schema driver inherits them unchanged
and a divergent driver overrides what it needs. The remaining four return safe
defaults.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
