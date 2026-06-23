package DBIO::PostgreSQL::Result;
# ABSTRACT: PostgreSQL-specific Result component for DBIO

use strict;
use warnings;

use base 'DBIO::Base';

__PACKAGE__->mk_classdata('_pg_schema_name');
__PACKAGE__->mk_classdata('_pg_indexes' => {});
__PACKAGE__->mk_classdata('_pg_triggers' => {});
__PACKAGE__->mk_classdata('_pg_rls');
__PACKAGE__->mk_classdata('_pg_check_constraints' => {});
__PACKAGE__->mk_classdata('_pg_extra_ddl' => []);



sub pg_schema {
  my ($class, $name) = @_;
  if (defined $name) {
    $class->_pg_schema_name($name);
  }
  return $class->_pg_schema_name;
}


sub pg_qualified_table {
  my ($class) = @_;
  my $schema = $class->_pg_schema_name;
  my $table = $class->table;
  return $schema ? "${schema}.${table}" : $table;
}


sub pg_index {
  my ($class, $name, $def) = @_;
  if ($def) {
    my $indexes = { %{ $class->_pg_indexes } };
    $indexes->{$name} = $def;
    $class->_pg_indexes($indexes);
  }
  return $class->_pg_indexes->{$name};
}


sub pg_indexes {
  my ($class) = @_;
  return { %{ $class->_pg_indexes } };
}


sub pg_trigger {
  my ($class, $name, $def) = @_;
  if ($def) {
    my $triggers = { %{ $class->_pg_triggers } };
    $triggers->{$name} = $def;
    $class->_pg_triggers($triggers);
  }
  return $class->_pg_triggers->{$name};
}


sub pg_triggers {
  my ($class) = @_;
  return { %{ $class->_pg_triggers } };
}


sub pg_rls {
  my ($class, $def) = @_;
  if ($def) {
    $class->_pg_rls($def);
  }
  return $class->_pg_rls;
}


sub pg_check_constraint {
  my ($class, $name, $def) = @_;
  if (defined $def) {
    my $entry = ref $def eq 'HASH' ? { %$def } : { definition => $def };
    $entry->{constraint_name} //= $name;
    my $checks = { %{ $class->_pg_check_constraints } };
    $checks->{$name} = $entry;
    $class->_pg_check_constraints($checks);
  }
  return $class->_pg_check_constraints->{$name};
}


sub pg_check_constraints {
  my ($class) = @_;
  return { %{ $class->_pg_check_constraints } };
}


sub pg_extra_ddl {
  my ($class, @stmts) = @_;
  if (@stmts) {
    my @flat = map { ref eq 'ARRAY' ? @$_ : $_ } @stmts;
    my $cur = [ @{ $class->_pg_extra_ddl }, @flat ];
    $class->_pg_extra_ddl($cur);
  }
  return [ @{ $class->_pg_extra_ddl } ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Result - PostgreSQL-specific Result component for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::PostgreSQL::Result> is a DBIO Result component that adds
PostgreSQL-native metadata to a result class: the PostgreSQL schema
(namespace) the table belongs to, custom indexes, triggers, and Row Level
Security (RLS) configuration.

Load it with:

    package MyApp::DB::Result::User;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');

    __PACKAGE__->pg_schema('auth');
    __PACKAGE__->table('users');

The schema name from C<pg_schema> is used by L<DBIO::PostgreSQL::DDL> to
qualify table names (e.g. C<auth.users>) in generated DDL.

=head1 METHODS

=head2 pg_schema

    __PACKAGE__->pg_schema('auth');
    my $name = $class->pg_schema;

Get or set the PostgreSQL schema (namespace) for this result class. When set,
L<DBIO::PostgreSQL::DDL> qualifies the table name as C<schema.table> in
generated DDL.

=head2 pg_qualified_table

    my $fqn = $class->pg_qualified_table;  # e.g. 'auth.users'

Returns the fully-qualified table name C<schema.table>, or just C<table> if no
PostgreSQL schema has been set.

=head2 pg_index

    __PACKAGE__->pg_index('idx_users_tags' => {
        using   => 'gin',
        columns => ['tags'],
    });
    __PACKAGE__->pg_index('idx_users_active' => {
        columns => ['role'],
        where   => "role != 'suspended'",
    });
    __PACKAGE__->pg_index('idx_users_embedding' => {
        using   => 'ivfflat',
        columns => ['embedding'],
        with    => { lists => 100 },
    });

    my $def = $class->pg_index('idx_users_tags');

Get or set the definition for a named PostgreSQL index. The definition hashref
accepts:

=over 4

=item C<columns> - ArrayRef of column names

=item C<using> - index access method (C<btree>, C<gin>, C<gist>, C<brin>, C<hash>, C<ivfflat>, etc.)

=item C<where> - partial index predicate (SQL expression string)

=item C<expression> - expression index expression (replaces C<columns>)

=item C<with> - storage parameter hashref (e.g. C<{ lists =E<gt> 100 }> for ivfflat)

=back

=head2 pg_indexes

    my $all = $class->pg_indexes;  # hashref of name => def

Returns a copy of all index definitions registered on this result class.

=head2 pg_trigger

    __PACKAGE__->pg_trigger('users_modified_at' => {
        when    => 'BEFORE',
        event   => 'UPDATE',
        execute => 'auth.update_modified_at()',
    });

    my $def = $class->pg_trigger('users_modified_at');

Get or set the definition for a named PostgreSQL trigger. The definition
hashref accepts C<when> (C<BEFORE>/C<AFTER>/C<INSTEAD OF>), C<event>
(C<INSERT>/C<UPDATE>/C<DELETE>/C<TRUNCATE>), and C<execute> (the function to
call).

=head2 pg_triggers

    my $all = $class->pg_triggers;  # hashref of name => def

Returns a copy of all trigger definitions registered on this result class.

=head2 pg_rls

    __PACKAGE__->pg_rls({
        enable   => 1,
        force    => 1,
        policies => {
            users_own_data => {
                for   => 'ALL',
                using => 'id = current_setting($$app.current_user_id$$)::uuid',
            },
        },
    });

    my $rls = $class->pg_rls;

Get or set the Row Level Security configuration for this table. The hashref
accepts:

=over 4

=item C<enable> - boolean, generates C<ENABLE ROW LEVEL SECURITY>

=item C<force> - boolean, generates C<FORCE ROW LEVEL SECURITY>

=item C<policies> - hashref of policy name to policy definition (C<for>, C<using>, C<with_check>)

=back

=head2 pg_check_constraint

    __PACKAGE__->pg_check_constraint('run_status_invariant' =>
      "(status IN ('Pending','Running','Done') AND error IS NULL)"
      . " OR status IN ('Blocked','Failed','Cancelled')"
    );
    __PACKAGE__->pg_check_constraint('idx_name' => {
      constraint_name => 'idx_name',
      definition      => 'CHECK (col > 0)',
      columns         => ['col'],
    });

    my $def = $class->pg_check_constraint('run_status_invariant');

Get or set a named CHECK constraint. Accepts either a plain string (the
CHECK predicate expression) or a hashref with C<constraint_name>,
C<definition> (which may already include C<CHECK>), and optional C<columns>.

=head2 pg_check_constraints

    my $all = $class->pg_check_constraints;

Returns a copy of all CHECK constraint definitions registered on this result class.

=head2 pg_extra_ddl

    __PACKAGE__->pg_extra_ddl(
      'ALTER TABLE goldmine_site ADD CONSTRAINT goldmine_site_paypal_account_id_fkey'
      . ' FOREIGN KEY (paypal_account_id) REFERENCES goldmine_paypal_account (id)'
      . ' ON DELETE RESTRICT',
    );

Appends raw SQL statements to be emitted after the table, indexes, triggers,
and RLS DDL. Used for cross-table FKs that DBIO::PostgreSQL::DDL does not
auto-generate from C<belongs_to>. Each call appends; arrayrefs are flattened.

=seealso

=over 4

=item * L<DBIO::PostgreSQL> - the schema component (Database layer)

=item * L<DBIO::PostgreSQL::PgSchema> - the PgSchema layer for enums, types, functions

=item * L<DBIO::PostgreSQL::DDL> - generates DDL from result class metadata

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
