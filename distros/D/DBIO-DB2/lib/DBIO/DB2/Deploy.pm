package DBIO::DB2::Deploy;
# ABSTRACT: Deploy and upgrade DB2 schemas via test-deploy-and-compare

use strict;
use warnings;

use base 'DBIO::Deploy::Base';

use DBIO::DB2::DDL;
use DBIO::SQL::Util ();


# --- class-name hooks for DBIO::Deploy::Base -------------------------------

sub _ddl_class       { 'DBIO::DB2::DDL'        }
sub _introspect_class { 'DBIO::DB2::Introspect' }
sub _diff_class      { 'DBIO::DB2::Diff'       }


sub _new_introspect {
  my ($self, $dbh, $schema) = @_;
  return $self->_introspect_class->new(
    dbh => $dbh,
    (defined $schema ? (schema => $schema) : ()),
  );
}


sub _introspect_current {
  my ($self) = @_;
  my $dbh = $self->_dbh;
  # CURRENT SCHEMA is CHAR(128), space-padded; right-trim before use.
  my ($current_schema) = $dbh->selectrow_array('VALUES CURRENT SCHEMA');
  $current_schema =~ s/\s+$// if defined $current_schema;
  return $self->_new_introspect($dbh, $current_schema)->model;
}


sub _build_target_model {
  my ($self) = @_;
  my $dbh         = $self->_dbh;
  # Must start with a letter and be uppercase: DB2 rejects a leading-underscore
  # unquoted identifier (CREATE SCHEMA _dbio_test_<pid> => SQL20521N), and SYSCAT
  # stores schema names uppercased, so a lowercase name would never match the
  # introspect filter (WHERE tabschema = ?). $$ is digits, so DBIO_TEST_<pid> is a
  # valid bare uppercase identifier that round-trips through SYSCAT unchanged.
  my $test_schema = 'DBIO_TEST_' . $$;

  # Defensively clear a same-named schema leaked by a crashed prior run (or an
  # earlier same-pid call whose teardown was skipped) so CREATE SCHEMA cannot
  # collide (SQL0601N). _drop_test_schema is best-effort and copes with a
  # populated schema.
  my ($exists) = $dbh->selectrow_array(
    'SELECT 1 FROM syscat.schemata WHERE schemaname = ?', undef, $test_schema,
  );
  $self->_drop_test_schema($dbh, $test_schema) if $exists;

  $dbh->do("CREATE SCHEMA $test_schema");

  my $model = eval {
    my $ddl = $self->_ddl_class->install_ddl($self->schema);
    for my $stmt ($self->_split_qualify_ddl($ddl, $test_schema)) {
      $dbh->do($stmt);
    }
    return $self->_new_introspect($dbh, $test_schema)->model;
  };

  $self->_drop_test_schema($dbh, $test_schema, $model);
  die $@ if $@ and not $model;

  return $model;
}

# Tear down the throwaway compare schema. DB2's DROP SCHEMA ... RESTRICT only
# succeeds on an EMPTY schema, but by this point the schema holds the deployed
# tables, so the schema must be emptied first. SYSPROC.ADMIN_DROP_SCHEMA can drop
# a populated schema, but it requires the SYSTOOLSPACE tablespace, which does not
# exist on a stock DB2 instance (SQL0443N "... SYSTOOLSPACE tablespace does not
# exist"); when it is missing the call fails, the schema is NOT dropped, and the
# next CREATE SCHEMA in the same process collides (SQL0601N). So we tear the
# schema down with plain DDL + catalog lookups, robust on any DB2: drop the FK
# constraints first (so inter-table FK dependencies don't block table drops),
# then the tables (indexes drop with their table) and any views, then the now
# empty schema. Best-effort throughout -- each statement is its own eval so one
# failure does not abort teardown; the caller re-raises only the model-build
# error (when no model was produced). Catalog names match $test_schema verbatim:
# it is the uppercase DBIO_TEST_<pid>, which is how SYSCAT stores it.
sub _drop_test_schema {
  my ($self, $dbh, $test_schema, $model) = @_;
  local $dbh->{FetchHashKeyName} = 'NAME_lc';   # DBD::DB2 upper-cases hashref keys

  # 1. Drop FK constraints owned by tables in the schema (type 'F'), so the
  #    referenced tables can then be dropped in any order.
  my $fks = $dbh->selectall_arrayref(
    q{SELECT tabname, constname FROM syscat.tabconst WHERE tabschema = ? AND type = 'F'},
    { Slice => {} }, $test_schema,
  );
  for my $fk (@{ $fks || [] }) {
    eval {
      local $dbh->{PrintError} = 0;
      $dbh->do("ALTER TABLE $test_schema.$fk->{tabname} DROP FOREIGN KEY $fk->{constname}");
    };
  }

  # 2. Drop tables (indexes drop with them) and any views.
  my $tables = $dbh->selectall_arrayref(
    q{SELECT tabname FROM syscat.tables WHERE tabschema = ? AND type = 'T'},
    { Slice => {} }, $test_schema,
  );
  for my $t (@{ $tables || [] }) {
    eval { local $dbh->{PrintError} = 0; $dbh->do("DROP TABLE $test_schema.$t->{tabname}") };
  }
  my $views = $dbh->selectall_arrayref(
    q{SELECT tabname FROM syscat.tables WHERE tabschema = ? AND type = 'V'},
    { Slice => {} }, $test_schema,
  );
  for my $v (@{ $views || [] }) {
    eval { local $dbh->{PrintError} = 0; $dbh->do("DROP VIEW $test_schema.$v->{tabname}") };
  }

  # 3. Drop the now-empty schema.
  eval { local $dbh->{PrintError} = 0; $dbh->do("DROP SCHEMA $test_schema RESTRICT") };
  return;
}

# Internal: rewrite CREATE/DROP TABLE/INDEX statements emitted by
# DBIO::DB2::DDL so they target $schema instead of the live one. The
# regex pass is conservative -- DBIO::DB2::DDL emits a known shape --
# so we trade a small fragility for not duplicating DDL rendering.
#
# The inline FK clause from _fk_constraint_clause is
#   CONSTRAINT <name> FOREIGN KEY (<from>) REFERENCES <reftable>(<cols>)
# where <reftable> is UNQUALIFIED. Without rewriting it too, a child table
# deployed into the test schema would resolve its REFERENCES against CURRENT
# SCHEMA (the live schema) and cross-reference the live parent. So we also
# qualify the REFERENCES target to the test schema. The CONSTRAINT name itself
# is schema-scoped in DB2 (it lives in the test table's schema), so it cannot
# collide with the live constraint of the same name and is left untouched.
sub _split_qualify_ddl {
  my ($self, $ddl, $test_schema) = @_;
  my @stmts = DBIO::SQL::Util::_split_statements($ddl);
  for my $stmt (@stmts) {
    next if $stmt =~ /^\s*--/;
    $stmt =~ s/\bCREATE TABLE (\w+)/CREATE TABLE $test_schema.$1/g;
    $stmt =~ s/\bDROP TABLE (\w+)/DROP TABLE $test_schema.$1/g;
    $stmt =~ s/\bCREATE INDEX (\w+) ON (\w+)/CREATE INDEX $test_schema.$1 ON $test_schema.$2/g;
    $stmt =~ s/\bDROP INDEX (\w+)/DROP INDEX $test_schema.$1/g;
    $stmt =~ s/\bREFERENCES (\w+)\(/REFERENCES $test_schema.$1(/g;
  }
  return @stmts;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Deploy - Deploy and upgrade DB2 schemas via test-deploy-and-compare

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::DB2::Deploy> orchestrates schema deployment and upgrades for
DB2 using the test-deploy-and-compare strategy, parallel to
L<DBIO::SQLite::Deploy> and L<DBIO::PostgreSQL::Deploy>.

For upgrades it:

=over 4

=item 1. Introspects the live database via C<SYSCAT>

=item 2. Deploys the desired schema (from DBIO classes) into a temporary
         schema in the same DB (DB2 requires an existing database; only
         a schema can be throwaway)

=item 3. Introspects the database after deployment

=item 4. Computes the diff between the two models using L<DBIO::DB2::Diff>

=back

C<install>/C<diff>/C<apply>/C<upgrade> and the dbh/schema accessors come
from L<DBIO::Deploy::Base>; this class supplies the three class-name hooks
(L</_ddl_class>, L</_introspect_class>, L</_diff_class>), the
L</_new_introspect> factory that threads a target schema into the
introspector, and the genuinely DB2-specific L</_build_target_model> that
splices the desired schema into a throwaway C<CREATE SCHEMA> block.

    my $deploy = DBIO::DB2::Deploy->new(
        schema => MyApp::DB->connect("dbi:DB2:database=mydb"),
    );
    $deploy->install;                       # fresh
    my $diff = $deploy->diff;              # or step-by-step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                      # convenience

=head1 METHODS

=head2 _new_introspect

    my $intro = $self->_new_introspect($dbh);
    my $intro = $self->_new_introspect($dbh, $schema);

Factory for the introspector. The optional C<$schema> selects the DB2
schema to introspect (defaults to the introspector's own default, used
when introspecting the live C<schema()>).

=head2 _introspect_current

    my $source_model = $self->_introspect_current;

The introspected model of the live (source) database. Overrides the
L<DBIO::Deploy::Base> default, which introspects with no schema arg and so
falls back to L<DBIO::DB2::Introspect>'s C<USER> default -- a schema DB2
connections do not actually use (e.g. C<db2inst1> has CURRENT SCHEMA
C<DB2INST1>), making the source model come back empty and diff/upgrade
phantom-create the whole schema.

Resolves the connection's CURRENT SCHEMA (the schema where C<install_ddl>'s
unqualified objects land) and threads it into the source introspector, so the
high-level diff/upgrade path compares against the live objects rather than an
empty model.

=head2 _build_target_model

    my $target_model = $self->_build_target_model;

DB2-specific target model construction:

=over 4

=item 1. C<CREATE SCHEMA DBIO_TEST_<pid>> in the same database

=item 2. Re-emit the install DDL with every C<CREATE/DROP TABLE/INDEX>
         statement schema-qualified to the test schema (DBIO::DB2::DDL
         does not auto-qualify)

=item 3. Introspect the test schema

=item 4. Drop the (now populated) test schema on the way out, even on failure
         (via L</_drop_test_schema>, which copes with a non-empty schema)

=back

Returns the introspected model hashref for the test schema, suitable as
the C<target> of L<DBIO::DB2::Diff>.

=seealso

=over 4

=item * L<DBIO::DB2> - schema component

=item * L<DBIO::DB2::DDL> - generates DDL

=item * L<DBIO::DB2::Introspect> - reads live database state

=item * L<DBIO::DB2::Diff> - compares two introspected models

=item * L<DBIO::Deploy::Base> - shared install/apply/upgrade orchestration

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
