package DBIO::PostgreSQL::Result;
# ABSTRACT: PostgreSQL-specific Result component for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Base';

use DBIO::PostgreSQL::ResultSet ();
use DBIO::PostgreSQL::Util ();

# karr k40: pgvector columns inflate/deflate by default. Loading the
# InflateColumn::Vector component here makes declaring a vector/halfvec/
# sparsevec column the whole opt-in — the same way this class already
# promotes resultset_class for those columns. Opt out per column with
# inflate_pgvector => 0.
__PACKAGE__->load_components('PostgreSQL::InflateColumn::Vector');

# karr k65: tsvector columns inflate/deflate by default, same opt-in-by-
# declaration model. Unlike Vector this carries no resultset_class promotion
# (that is pgvector/nearest_neighbors-specific). Opt out per column with
# inflate_tsvector => 0.
__PACKAGE__->load_components('PostgreSQL::InflateColumn::TSVector');

__PACKAGE__->mk_classdata('_pg_schema_name');
__PACKAGE__->mk_classdata('_pg_indexes' => {});
__PACKAGE__->mk_classdata('_pg_triggers' => {});
__PACKAGE__->mk_classdata('_pg_rls');
__PACKAGE__->mk_classdata('_pg_check_constraints' => {});
__PACKAGE__->mk_classdata('_pg_extra_ddl' => []);
__PACKAGE__->mk_classdata('_pg_fk_constraints_from_rels' => 1);
__PACKAGE__->mk_classdata('_pg_unique_options' => {});



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
  return DBIO::PostgreSQL::Util::quote_qualified(
    ($schema ? $schema : ()), $table,
  );
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


sub pg_unique_options {
  my ($class, $name, $options) = @_;
  if (defined $name) {
    $class->throw_exception('pg_unique_options takes the name of a UNIQUE constraint and a hash of options')
      unless defined $options && ref $options eq 'HASH';
    $class->_pg_unique_options({ %{ $class->_pg_unique_options }, $name => { %$options } });
  }
  return { map { $_ => { %{ $class->_pg_unique_options->{$_} } } } keys %{ $class->_pg_unique_options } };
}


sub pg_fk_constraints_from_rels {
  my ($class, $bool) = @_;
  if (defined $bool) {
    $class->_pg_fk_constraints_from_rels($bool);
  }
  return $class->_pg_fk_constraints_from_rels;
}


sub register_column {
  my ($class, $column, $info, @rest) = @_;
  $class->next::method($column, $info, @rest);

  # Single pgvector-type detection site: reuse the shared helper from the
  # InflateColumn::Vector component (loaded above), so promotion and inflation
  # share one regex with identical whitespace tolerance (karr k61).
  my ($type) = $class->_pgvector_type_info($info->{data_type});
  return unless $type;

  my $rs_class = $class->resultset_class;
  $class->resultset_class('DBIO::PostgreSQL::ResultSet')
    if $rs_class && !$rs_class->isa('DBIO::PostgreSQL::ResultSet');

  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Result - PostgreSQL-specific Result component for DBIO

=head1 VERSION

version 0.900004

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
generated DDL. The name is taken exactly -- C<pg_schema('AppData')> is the
schema C<AppData>, not C<appdata> -- see
L<DBIO::PostgreSQL::DDL/"NAMES AND VALUES">.

=head2 pg_qualified_table

    my $fqn = $class->pg_qualified_table;  # e.g. 'auth.users'

Returns the fully-qualified table name C<schema.table>, or just C<table> if no
PostgreSQL schema has been set. The result is an SQL name: each part is
written by the server's own rule (L<DBIO::PostgreSQL::Util/quote_ident>), bare
where it is plain lower case and no key word, in double quotes otherwise --
C<auth.users>, C<auth."UserAccount">, C<"Auth".users> -- so it can stand in a
statement as it is.

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
        using     => 'ivfflat',
        columns   => ['embedding'],
        opclasses => { embedding => 'vector_l2_ops' },
        with      => { lists => 100 },
    });
    __PACKAGE__->pg_index('idx_users_embedding_cos' => {
        using     => 'hnsw',
        columns   => ['embedding'],
        opclasses => { embedding => 'vector_cosine_ops' },
        with      => { m => 16, ef_construction => 64 },
    });

    my $def = $class->pg_index('idx_users_tags');

Get or set the definition for a named PostgreSQL index. The definition hashref
accepts:

=over 4

=item C<columns> - ArrayRef of column names

=item C<using> - index access method (C<btree>, C<gin>, C<gist>, C<brin>, C<hash>, C<hnsw>, C<ivfflat>, etc.), SQL written as given

=item C<opclasses> - HashRef of column name to operator class, emitted after
the column name in the key list (C<< USING hnsw (embedding vector_cosine_ops) >>).
The operator class is SQL and is written as given, with whatever follows it
there (C<gist_trgm_ops(siglen=32)>, C<text_pattern_ops DESC NULLS LAST>).
Only name the columns that need a non-default operator class; the rest are
emitted bare and PostgreSQL picks the access method's default. B<pgvector's
C<hnsw> has no default operator class for C<vector>>, so an C<hnsw> index
B<must> name one (C<vector_l2_ops>, C<vector_cosine_ops>,
C<vector_ip_ops>, or the C<halfvec_*> / C<sparsevec_*> / C<bit_*> variants)
or C<CREATE INDEX> is rejected. C<ivfflat> defaults to C<vector_l2_ops> on a
C<vector> column, so there only another class has to be named. Naming
C<vector_l2_ops> on C<ivfflat> is accepted, but as the default it is not
printed by C<pg_get_indexdef>, so an introspected index reports no operator
class for it. For an C<expression> index the operator
class goes inside the expression string instead.

=item C<where> - partial index predicate (SQL expression string)

=item C<expression> - expression index expression (replaces C<columns>)

=item C<include> - ArrayRef of non-key payload columns for a covering index,
emitted as C<< INCLUDE (nickname) >> after the key list. The columns are
stored in the index but not part of its key, so an index-only scan can
answer a query without touching the table. Supported by C<btree> (and, from
PostgreSQL 11 on, C<gist>); other access methods reject it.

=item C<with> - storage parameter hashref (e.g. C<{ lists =E<gt> 100 }> for ivfflat); keys and values are SQL, written as given (C<key = value>)

=item C<unique> - boolean, emits C<CREATE UNIQUE INDEX>

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
(C<INSERT>/C<UPDATE>/C<DELETE>/C<TRUNCATE>), C<execute> (the function to
call), and C<for_each> (C<ROW>, the default, or C<STATEMENT>).

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

A policy that reads a session setting, as C<app.current_user_id> above, is fed
by the application with C<set_config('app.current_user_id', ?, false)> on the
connection it is about to use. On the C<future_io> transport the session of a
borrow is its own: when a borrow ends, the pool connection is reset
(C<DISCARD ALL>, then the connect actions again; see
L<DBIO::PostgreSQL::Storage::Async/The session of a borrow>), so a setting of
one borrow is empty in the next one. Set it in the transaction that runs the
statements it governs, with C<set_config(..., true)> or C<SET LOCAL>. Session
advisory locks are released by the reset as well.

Get or set the Row Level Security configuration for this table. The hashref
accepts:

=over 4

=item C<enable> - boolean, generates C<ENABLE ROW LEVEL SECURITY>

=item C<force> - boolean, generates C<FORCE ROW LEVEL SECURITY>

=item C<policies> - hashref of policy name to policy definition (C<for>,
C<roles>, C<using>, C<with_check>, C<restrictive>). C<restrictive> true writes
C<CREATE POLICY ... AS RESTRICTIVE>, which narrows what the permissive
policies let through; absent or false the policy is permissive, as before. The
diff reads the kind off the database (C<permissive> of
L<DBIO::PostgreSQL::Introspect::Policies>) and writes it when it creates a
policy; it does not yet notice a policy whose kind changed under an unchanged
name. C<roles> is an ArrayRef of role names for the policy's C<TO> list; each
is taken exactly, like every other name (a C<AppUser> role is C<"AppUser">).
C<PUBLIC>, C<CURRENT_USER>, C<CURRENT_ROLE> and C<SESSION_USER> are written as
the key words they are. C<using> and C<with_check> are SQL expressions and are
written as given.

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
      'ALTER TABLE my_site ADD CONSTRAINT my_site_paypal_account_id_fkey'
      . ' FOREIGN KEY (paypal_account_id) REFERENCES my_paypal_account (id)'
      . ' ON DELETE RESTRICT',
    );

Appends raw SQL statements to be emitted after the table, indexes, triggers,
and RLS DDL. Used for cross-table FKs that DBIO::PostgreSQL::DDL does not
auto-generate from C<belongs_to> (see L</pg_fk_constraints_from_rels>, on by
default, for the setting that does). Each call appends; arrayrefs are flattened.

=head2 pg_unique_options

    __PACKAGE__->add_unique_constraint(users_email_key => ['email']);
    __PACKAGE__->pg_unique_options(users_email_key => {
        deferrable         => 1,
        initially_deferred => 1,
    });
    my $options = $class->pg_unique_options;    # { name => { ... } }

Options of a UNIQUE constraint of this class, by the name
C<add_unique_constraint> gave it: C<deferrable> and C<initially_deferred>,
written by the install as C<DEFERRABLE INITIALLY IMMEDIATE> or C<DEFERRABLE
INITIALLY DEFERRED> behind the column list, and by the upgrade.
Without options a constraint is not deferrable. C<initially_deferred> without
C<deferrable>, another option, and the options of a name that is no UNIQUE
constraint of the class are refused when the install script is written
(L<DBIO::PostgreSQL::DDL>). A call replaces the options of that name; the
accessor returns a copy of all of them.

=head2 pg_fk_constraints_from_rels

    __PACKAGE__->pg_fk_constraints_from_rels(0);
    my $bool = $class->pg_fk_constraints_from_rels;

Get or set whether L<DBIO::PostgreSQL::DDL> should auto-generate
C<FOREIGN KEY> constraints from this class's C<belongs_to> relationships.
Defaults to true: a result class that sets nothing gets its foreign keys, and
switches them off for itself with C<< pg_fk_constraints_from_rels(0) >>. A
single relationship is left out with C<< is_foreign_key_constraint => 0 >> in
its attributes (core sets it to 1 on every C<belongs_to> that does not say
otherwise), so that no key is written for it, and a C<belongs_to> to a class
that is not loaded or a table outside the deploy that declares it no longer
refuses the install. L</pg_extra_ddl> remains the
always-available manual alternative (and the only option for constraints
C<belongs_to> can't express).

When true (the default), every C<belongs_to> on this class whose join condition reduces
to plain column equality (one or more C<< foreign.col => self.col >>
pairs and nothing else, which is what an unadorned
C<< __PACKAGE__->belongs_to(rel => 'Class', 'fk_col') >> declaration
produces) gets a named
C<ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY> statement, emitted by
C<install_ddl> only after every table in the deploy has been created.
The C<on_delete> and C<on_update> attributes of the C<belongs_to> are written
as declared, C<ON DELETE CASCADE> and the like. Two relationships over the same
columns to the same table with the same actions are one constraint and are
written once; with other actions, or to another table, they are refused, as
the constraint is named after its table and columns. An action
other than NO ACTION, RESTRICT, CASCADE, SET NULL or SET DEFAULT (in any case)
is refused, naming the relationship.

The upgrade creates the same constraint, under the same name, on a table it
creates or one that lacks it, drops and creates it again when its columns,
target or actions change, and drops a foreign key the schema does not declare
(L<DBIO::PostgreSQL::Diff::ForeignKey>).

The attributes C<deferrable> and C<initially_deferred> of the C<belongs_to>
make the key C<DEFERRABLE INITIALLY IMMEDIATE> or C<DEFERRABLE INITIALLY
DEFERRED>, written behind the actions, by the install and by the upgrade.
Neither is the default: a relationship that names neither gets a key that is
not deferrable. C<initially_deferred> without C<deferrable> is refused, as
PostgreSQL refuses a constraint that is C<INITIALLY DEFERRED> and C<NOT
DEFERRABLE>. A key that changes its timing is dropped and created again.

A C<belongs_to> with a complex condition (a coderef, or a hash with
anything other than a plain column on each side) is skipped -- with a
SQL comment recording which relationship and why, never silently -- since
its join can't be expressed as a plain-column C<FOREIGN KEY>.

A C<belongs_to> that targets a class that is not loaded, or a table that is
not part of the schema deploy, is B<refused>: the script is not written, and
the exception, C<refusing to write the install DDL: ...>, names the table, the
relationship and the class. The class asked for a foreign key to a table that
will not be there; a comment would leave the database without it. Switch it
off (C<0>) for a class whose relationships are not meant to become
constraints, or whose target is outside the deploy.

The comment of a skipped condition reads C<-- skipped FK for rel NAME: REASON>
and is a piece of the
script of its own, closed by a semicolon on the next line: skipping one
foreign key leaves out that foreign key and nothing behind it. A deploy does
not show the comment -- it runs the statements and passes over the notes --
so a skipped relationship is seen in the script
(L<DBIO::PostgreSQL/pg_install_ddl>), not in the outcome of an install.

=head2 register_column

Hooks into the column registration chain. When a column declares a pgvector
data type (C<vector>, C<halfvec> or C<sparsevec>, with or without a
dimension), the result source's C<resultset_class> is promoted to
L<DBIO::PostgreSQL::ResultSet>, so its resultsets carry
L<DBIO::PostgreSQL::ResultSet/nearest_neighbors>. Declaring the column is
the whole opt-in; no other class needs to be named.

The promotion is guarded: a C<resultset_class> that already inherits from
C<DBIO::PostgreSQL::ResultSet> is left alone, so a custom resultset that
subclasses it keeps its own methods. A custom C<resultset_class> that does
B<not> inherit from it is replaced -- subclass
C<DBIO::PostgreSQL::ResultSet> if you need both.

A C<bit> column queried with Hamming/Jaccard distance is not auto-detected
(C<bit> is a general PostgreSQL type, not a pgvector one); set
C<resultset_class> by hand for those.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL> - the schema component (Database layer)

=item * L<DBIO::PostgreSQL::PgSchema> - the PgSchema layer for enums, types, functions

=item * L<DBIO::PostgreSQL::DDL> - generates DDL from result class metadata

=item * L<DBIO::PostgreSQL::ResultSet> - the resultset class a pgvector column promotes to

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
