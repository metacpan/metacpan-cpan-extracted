package DBIO::Oracle::Introspect;
# ABSTRACT: Introspect an Oracle database via all_* views

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Introspect::Base';


use DBIO::Oracle::Introspect::Tables ();
use DBIO::Oracle::Introspect::Columns ();
use DBIO::Oracle::Introspect::Indexes ();
use DBIO::Oracle::Introspect::ForeignKeys ();
use DBIO::Oracle::Introspect::Keys ();
use DBIO::Oracle::Introspect::Views ();


sub schema { $_[0]->{schema} //= $_[0]->_default_schema }


sub schemas { $_[0]->{schemas} //= [] }

sub _default_schema {
  my ($self) = @_;
  my ($schema) = $self->dbh->selectrow_array('SELECT USER FROM DUAL');
  return $schema;
}

sub _build_model {
  my ($self) = @_;
  my $own    = $self->schema;
  my $model  = $self->_schema_model($own);

  # The tables of the other schemas are named schema.table (karr k58); every
  # section of the model keeps one key per table.
  my %seen = ($own => 1);
  for my $other (grep { !$seen{$_}++ } @{ $self->schemas }) {
    my $m = $self->_schema_model($other);
    for my $section (qw(tables columns indexes foreign_keys primary_keys unique_constraints views)) {
      $model->{$section}{"$other.$_"} = $m->{$section}{$_}
        for keys %{ $m->{$section} || {} };
    }
    # likewise a view names the views it rests on (karr k65)
    for my $key (keys %{ $m->{views} || {} }) {
      my $v = $model->{views}{"$other.$key"};
      $_ = $_ =~ /\A\Q$own\E\.(.+)\z/s ? $1 : /\./ ? $_ : "$other.$_"
        for @{ $v->{depends_on} || [] };
    }
    for my $key (keys %{ $m->{tables} }) {
      for my $fk (@{ $model->{foreign_keys}{"$other.$key"} || [] }) {
        $fk->{from_table} = "$other.$key";
        # ForeignKeys names a table of the schema it reads bare and one of
        # another schema as owner.table. Here the key of a table of $other
        # is other.table, and the key of one in the connected user's schema
        # is its bare name.
        $fk->{to_table} = $fk->{to_table} =~ /\A\Q$own\E\.(.+)\z/s ? $1
          : $fk->{to_table} =~ /\./ ? $fk->{to_table}
          : "$other.$fk->{to_table}";
      }
    }
  }
  return $model;
}

# The model of one schema, keyed by the bare table names.
sub _schema_model {
  my ($self, $schema) = @_;
  my $dbh = $self->dbh;

  my $tables  = DBIO::Oracle::Introspect::Tables->fetch($dbh, $schema);
  my $columns = DBIO::Oracle::Introspect::Columns->fetch($dbh, $schema, $tables);
  my $indexes = DBIO::Oracle::Introspect::Indexes->fetch($dbh, $schema, $tables);
  my $fks     = DBIO::Oracle::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);
  my $keys    = DBIO::Oracle::Introspect::Keys->fetch($dbh, $schema, $tables);
  my $views   = DBIO::Oracle::Introspect::Views->fetch($dbh, $schema, $tables);

  # Primary key membership is also marked on the columns (is_pk, pk_position),
  # the way the other drivers' models carry it and the way
  # DBIO::Oracle::Diff::Table reads it for a CREATE TABLE.
  for my $table (keys %{ $keys->{primary} || {} }) {
    my @pk = @{ $keys->{primary}{$table} || [] };
    my %pos; @pos{@pk} = 1 .. @pk;
    for my $col (@{ $columns->{$table} || [] }) {
      next unless exists $pos{ $col->{column_name} };
      $col->{is_pk}       = 1;
      $col->{pk_position} = $pos{ $col->{column_name} };
    }
  }

  return {
    tables             => $tables,
    columns            => $columns,
    indexes            => $indexes,
    foreign_keys       => $fks,
    primary_keys       => $keys->{primary},
    unique_constraints => $keys->{unique},
    views              => $views,
  };
}


sub table_columns_info {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} // [];
  # The primary key is folded into is_nullable, the way core's base now does
  # (core k126); membership is read from the primary_keys section via
  # table_pk_info.
  my %pk = map { $_ => 1 } @{ $self->table_pk_info($key) };
  my %info;
  for my $col (@$cols) {
    my %col_info = (
      data_type   => $col->{data_type},
      is_nullable => ($col->{not_null} || $pk{ $col->{column_name} }) ? 0 : 1,
    );
    $col_info{size}              = $col->{size}          if defined $col->{size};
    $col_info{default_value}     = $col->{default_value} if exists $col->{default_value};
    $col_info{is_auto_increment} = 1                     if $col->{is_auto_increment};
    $col_info{sequence}          = $col->{sequence}      if defined $col->{sequence};
    $info{ $col->{column_name} } = \%col_info;
  }
  return \%info;
}


sub table_pk_info {
  my ($self, $key) = @_;
  return $self->model->{primary_keys}{$key} // [];
}


sub table_fk_info {
  my ($self, $key) = @_;
  my $fks = $self->model->{foreign_keys}{$key} // [];
  return [
    map {
      {
        local_columns  => $_->{from_columns},
        remote_table   => $_->{to_table},
        remote_schema  => undef,
        remote_columns => $_->{to_columns},
        attrs          => {
          on_delete     => $_->{on_delete},
          on_update     => $_->{on_update},
          is_deferrable => $_->{is_deferrable} ? 1 : 0,
        },
      }
    } @$fks
  ];
}


sub view_definition {
  my ($self, $key) = @_;
  return undef unless $self->table_is_view($key);

  my $dbh = $self->dbh;
  local $dbh->{LongReadLen} = 1_000_000;
  local $dbh->{LongTruncOk} = 0;

  my ($text) = $dbh->selectrow_array(
    'SELECT text FROM all_views WHERE owner = ? AND view_name = ?',
    undef, $self->schema, $key,
  );
  return undef unless defined $text;
  $text =~ s/^\s+//;
  $text =~ s/\s+\z//;
  $text =~ s/\s*;\s*\z//;
  return $text;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Introspect - Introspect an Oracle database via all_* views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Oracle::Introspect> reads the live state of an Oracle database
via the C<all_*> data dictionary views (C<all_tables>, C<all_tab_columns>,
C<all_indexes>, C<all_constraints>, etc.). Its models are what
L<DBIO::Oracle::Diff> compares. L<DBIO::Oracle::Deploy> does not drive that
comparison: its C<diff> and C<upgrade> read the live schema and a temporary user through this class.

    my $intro = DBIO::Oracle::Introspect->new(
        dbh => $dbh,
        schema => 'MYUSER',
    );
    my $model = $intro->model;

Model shape:

    {
        tables       => { $name => { ... } },
        columns      => { $table => [ { ... }, ... ] },   # primary key columns carry is_pk and pk_position
        indexes      => { $table => { $name => { ... } } },
        foreign_keys => { $table => [ { ... }, ... ] },
        primary_keys => { $table => [ $col, ... ] },
        unique_constraints => { $table => [ [ $name => \@cols ], ... ] },
        views        => { $view => { view_name => $view, definition => $sql, columns => \@names, depends_on => \@views } },
    }

C<views> holds the defining query of each view (from
C<all_views.text>, see L<DBIO::Oracle::Introspect::Views>), which
L<DBIO::Oracle::Diff> writes C<CREATE OR REPLACE VIEW> from; the view itself
is in C<tables> with C<kind> C<view>.

The Oracle introspection is built on the C<all_*> data dictionary views,
providing sequence detection via trigger inspection, LOB type handling,
and other Oracle-specific behaviors.

=head1 ATTRIBUTES

=head2 schema

Schema (user) name to introspect. Defaults to the current connected user
(via C<SELECT USER FROM DUAL>).

=head2 schemas

ArrayRef of further schemas (users) to read besides L</schema>; by
default none. Their tables, columns, indexes and keys are in the model under
the key C<schema.table> -- the schema exactly as the dictionary holds it, then
a dot, then the table -- the name a source with a table in another schema
(C<< table('OWNX.item') >>) has, and the name L<DBIO::Oracle::Diff> writes as
C<"OWNX"."item">. The entry of such a table in C<tables> keeps its bare
C<table_name> and its C<schema>. A foreign key reports the table it points to
by that key: C<schema.table> for a table of another schema, the bare name for
one of L</schema>. The connected user reads another schema through the
C<all_*> views, i.e. as far as it may see it. A schema that does not exist
simply has no tables. Everything else (the sequence of a column is
C<schema.sequence> as before) is unchanged.

    my $model = DBIO::Oracle::Introspect->new(
        dbh => $dbh, schemas => ['OWNX'],
    )->model;

=head1 METHODS

=head2 table_columns_info

    my \%info = %{ $intro->table_columns_info($key) };

Hashref of normalized per-column metadata. The Oracle override adds the
C<sequence> field (populated from BEFORE INSERT trigger inspection) on top of
the canonical C<data_type> / C<size> / C<is_nullable> / C<default_value> /
C<is_auto_increment> fields. C<is_nullable> is C<0> when the column carries
C<not_null> or is a primary key column; key membership is checked via
L</table_pk_info>.

=head2 table_pk_info

    my \@pk_cols = @{ $intro->table_pk_info($key) };

Ordered list of primary key column names, read from the C<primary_keys>
section of the model (keyed by table, in the order of the constraint). The
columns carry C<is_pk> and C<pk_position> as well; the dedicated section is
what this method reads.

=head2 table_fk_info

    my \@fks = @{ $intro->table_fk_info($key) };

Each FK is a hashref in the normalized contract shape. The Oracle
override adds C<is_deferrable> to C<attrs> -- the canonical
implementation drops it, and the Oracle storage layer (C<ALTER SESSION
SET CONSTRAINTS = DEFERRED>) needs to know whether a constraint is
DEFERRABLE.

=head2 view_definition

SQL text of the view definition, or C<undef>. Read from C<all_views> (a
C<LONG> column, so C<LongReadLen> is raised for the fetch).

=head1 NORMALIZED CONTRACT

The canonical L<DBIO::Introspect::Base> contract methods
(C<table_keys>, C<table_columns>, C<table_uniq_info>, C<table_is_view>)
are inherited unchanged -- the Oracle model uses bare table names as keys
and a C<unique_constraints> section, both of which match the canonical
shape. The four methods below override the base to surface Oracle-specific
data that the canonical model would drop.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::Oracle::Deploy> - install, and diff and upgrade, which compare through this class

=item * L<DBIO::Oracle::Diff> - compares two models produced by this class

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
