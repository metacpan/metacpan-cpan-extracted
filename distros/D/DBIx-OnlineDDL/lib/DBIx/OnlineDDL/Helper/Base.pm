package DBIx::OnlineDDL::Helper::Base;

our $AUTHORITY = 'cpan:GSG';
# ABSTRACT: Private OnlineDDL helper for RDBMS-specific code
use version;
our $VERSION = 'v0.920.1'; # VERSION

use v5.10;
use Moo;

use Types::Standard qw( InstanceOf );

use DBI::Const::GetInfoType;
use Sub::Util qw( set_subname );

use namespace::clean;  # don't export the above

#pod =encoding utf8
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a private helper module for any RDBMS-specific code.  B<As a private module, any
#pod methods or attributes here are subject to change.>
#pod
#pod You should really be reading documentation for L<DBIx::OnlineDDL>.  The documentation
#pod here is mainly to benefit any developers who might want to create their own subclass
#pod module for their RDBMS and submit it to us.  Or fix bugs with the existing helpers.
#pod
#pod =cut

#pod =head1 PRIVATE ATTRIBUTES
#pod
#pod =head2 online_ddl
#pod
#pod Points back to the parent L<DBIx::OnlineDDL>.  This comes with a bunch of handles to be
#pod able to call common methods with fewer keystrokes.
#pod
#pod =cut

has online_ddl => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::OnlineDDL'],
    required => 1,
    weak_ref => 1,
    handles  => {
        vars                => '_vars',
        dbh                 => 'dbh',
        table_name          => 'table_name',
        new_table_name      => 'new_table_name',
        copy_opts           => 'copy_opts',
        db_timeouts         => 'db_timeouts',
        dbh_runner          => 'dbh_runner',
        dbh_runner_do       => 'dbh_runner_do',
        find_new_identifier => '_find_new_identifier',
        fk_to_sql           => '_fk_to_sql',
    },
);

# Other "handles"
sub dbms_name { shift->vars->{dbms_name}    }  # used for die errors only
sub progress  { shift->vars->{progress_bar} }

#pod =head1 PRIVATE CLASS "ATTRIBUTES"
#pod
#pod =head2 dbms_uses_global_fk_namespace
#pod
#pod If true, OnlineDDL will rename the FKs in the new table to make sure they don't conflict,
#pod and rename them back after the swap.
#pod
#pod =cut

sub dbms_uses_global_fk_namespace { 0 }

#pod =head2 child_fks_need_adjusting
#pod
#pod If true, OnlineDDL will call helper methods to adjust FKs bound to child tables.
#pod
#pod =cut

sub child_fks_need_adjusting { 0 }

#pod =head2 null_safe_equals_op
#pod
#pod This is the operator that the DB uses for NULL-safe equals comparisons.  It would match
#pod this truth table:
#pod
#pod        0 <op> 0    --> TRUE
#pod        0 <op> 1    --> FALSE
#pod        0 <op> NULL --> FALSE (instead of NULL)
#pod     NULL <op> NULL --> TRUE  (instead of NULL)
#pod
#pod The ANSI SQL version is C<IS NOT DISTINCT FROM>, but others RDBMS typically use something
#pod less bulky.
#pod
#pod =cut

sub null_safe_equals_op { 'IS NOT DISTINCT FROM' }

#pod =head1 PRIVATE HELPER METHODS
#pod
#pod As the base module, all of these methods will use ANSI SQL, since there is no assumption
#pod of the type of RDBMS used yet.  Some of these methods may just immediately die, as there
#pod may not be a (safe) standard way of doing that task.
#pod
#pod =head2 current_catalog_schema
#pod
#pod     ($catalog, $schema) = $helper->current_catalog_schema;
#pod
#pod Figure out the currently-selected catalog and schema (database name) from the database.
#pod
#pod =cut

sub current_catalog_schema {
    my $self = shift;

    # Try to guess from the DSN parameters
    my %dsn = map { /^(.+)=(.+)$/; lc($1) => $2; } (split /\;/, $self->dbh->{Name});
    my $catalog = $dsn{catalog};
    my $schema  = $dsn{database} // $dsn{schema};

    return ($catalog, $schema);
}

#pod =head2 insert_select_stmt
#pod
#pod     $insert_select_stmt = $helper->insert_select_stmt($column_list_str);
#pod
#pod Return an C<INSERT...SELECT> statement to copy rows from the old table to the new, in
#pod such a way that doesn't cause "duplicate row" errors.  This is used by
#pod L<DBIx::BatchChunker> for the copy operation, so it will need C<BETWEEN ? AND ?>
#pod placeholders.
#pod
#pod =cut

sub insert_select_stmt {
    my ($self, $column_list_str) = @_;

    my $dbh = $self->dbh;

    my $orig_table_name = $self->table_name;
    my $new_table_name  = $self->new_table_name;

    my $orig_table_name_quote = $dbh->quote_identifier($orig_table_name);
    my $new_table_name_quote  = $dbh->quote_identifier($new_table_name);

    my $id_name = $self->copy_opts->{id_name};
    my $old_full_id_name_quote = $dbh->quote_identifier(undef, $orig_table_name, $id_name);
    my $new_full_id_name_quote = $dbh->quote_identifier(undef, $new_table_name,  $id_name);

    # A generic JOIN solution
    return join("\n",
        "INSERT INTO $new_table_name_quote",
        "($column_list_str)",
        "SELECT",
        "    $column_list_str",
        "FROM",
        "    $orig_table_name_quote",
        "    LEFT JOIN $new_table_name_quote ON (".join(" = ", $old_full_id_name_quote, $new_full_id_name_quote).")",
        "WHERE",
        "    $old_full_id_name_quote BETWEEN ? AND ? AND",
        "    $new_full_id_name_quote IS NULL",
    );
}

#pod =head2 post_connection_stmts
#pod
#pod     @stmts = $helper->post_connection_stmts;
#pod
#pod These are the SQL statements to run right after a C<$dbh> re-connect, typically session
#pod variable set statements.
#pod
#pod =cut

sub post_connection_stmts {
    # No statements by default
    return;
}

#pod =head2 is_error_retryable
#pod
#pod     $bool = $helper->is_error_retryable($error);
#pod
#pod Returns true if the specified error string (or exception object from DBIC/D:C:R) is
#pod retryable.  Retryable errors generally fall under the categories of: lock contentions,
#pod lost DB connections, and query interruptions.
#pod
#pod =cut

sub is_error_retryable {
    warn sprintf "Not sure how to inspect DB errors for %s systems!", shift->dbms_name;
    return 0;
}

#pod =head2 create_table_sql
#pod
#pod     $sql = $helper->create_table_sql($table_name);
#pod
#pod Get the C<CREATE TABLE> SQL statement for the specified table.  This is RDBMS-specific,
#pod since C<information_schema> isn't always available and usually doesn't house all of the
#pod details, anyway.
#pod
#pod =cut

sub create_table_sql {
    die sprintf "Not sure how to create a new table for %s systems!", shift->dbms_name;
}

#pod =head2 rename_fks_in_table_sql
#pod
#pod     $sql = $helper->rename_fks_in_table_sql($table_name, $sql)
#pod         if $helper->dbms_uses_global_fk_namespace;
#pod
#pod Given the C<CREATE TABLE> SQL, return the statement with the FKs renamed.  This should
#pod use C<find_new_identifier> to find a valid name.
#pod
#pod Only used if L</dbms_uses_global_fk_namespace> is true.
#pod
#pod =cut

sub rename_fks_in_table_sql {
    my ($self, $table_name, $table_sql) = @_;

    # Don't change it by default
    return $table_sql;
}

#pod =head2 has_triggers_on_table
#pod
#pod     die if $helper->has_triggers_on_table($table_name);
#pod
#pod Return true if triggers exist on the given table.  This is a fail-safe to make sure the
#pod table is trigger-free prior to the operation.
#pod
#pod =cut

sub has_triggers_on_table {
    die sprintf "Not sure how to check for table triggers for %s systems!", shift->dbms_name;
}

#pod =head2 find_new_trigger_identifier
#pod
#pod     $trigger_name = $helper->find_new_trigger_identifier($trigger_name);
#pod
#pod Return a free trigger identifier to use in the new trigger, using the inputted name as a
#pod base.  This should use C<find_new_identifier> to find a valid name.
#pod
#pod =cut

sub find_new_trigger_identifier {
    die sprintf "Not sure how to check for table triggers for %s systems!", shift->dbms_name;
}

#pod =head2 modify_trigger_dml_stmts
#pod
#pod     $helper->modify_trigger_dml_stmts( \%trigger_dml_stmts );
#pod
#pod Given the DML SQL statements to be plugged into the triggers, mutate the statements,
#pod tailored to the RDBMS.  The input is a hashref of SQL statements for the following keys:
#pod
#pod     replace            # used in the INSERT/UPDATE triggers
#pod     delete_for_update  # used in the UPDATE trigger
#pod     delete_for_delete  # used in the DELETE trigger
#pod
#pod Since it's already a reference, this method will mutate the SQL strings.
#pod
#pod =cut

sub modify_trigger_dml_stmts {
    my $self = shift;

    # Don't change them by default
    return @_;
}

#pod =head2 analyze_table
#pod
#pod     $helper->analyze_table($table_name);
#pod
#pod Run the DDL statement to re-analyze the table, typically C<ANALYZE TABLE>.
#pod
#pod =cut

sub analyze_table {
    my ($self, $table_name) = @_;
    my $table_name_quote = $self->dbh->quote_identifier($table_name);
    $self->dbh_runner_do("ANALYZE TABLE $table_name_quote");
}

#pod =head2 swap_tables
#pod
#pod     $helper->swap_tables($new_table_name, $orig_table_name, $old_table_name);
#pod
#pod Runs the SQL to swap the tables in a safe and atomic manner.  The default ANSI SQL
#pod solution is to run two C<ALTER TABLE> statements in a transaction, but only if the RDBMS
#pod supports transactional DDL.
#pod
#pod =cut

sub swap_tables {
    my ($self, $new_table_name, $orig_table_name, $old_table_name) = @_;
    my $dbh = $self->dbh;

    # If the RDBMS actually has a value for SQL_TXN_CAPABLE, and it's not SQL_TC_ALL,
    # then it really doesn't support transactional DDL.
    my $txn_capable = $dbh->get_info( $GetInfoType{SQL_TXN_CAPABLE} );
    my $sql_tc_all  = $DBI::Const::GetInfo::ODBC::ReturnValues{SQL_TXN_CAPABLE}{SQL_TC_ALL};
    if (defined $txn_capable && $txn_capable != $sql_tc_all) {
        die sprintf "Not sure how to swap tables for %s systems!", shift->dbms_name;
    }

    my $new_table_name_quote  = $dbh->quote_identifier($new_table_name);
    my $orig_table_name_quote = $dbh->quote_identifier($orig_table_name);
    my $old_table_name_quote  = $dbh->quote_identifier($old_table_name);

    $self->dbh_runner(txn => set_subname '_table_swap', sub {
        $dbh = $_;
        $dbh->do("ALTER TABLE $orig_table_name_quote RENAME TO $old_table_name_quote");
        $dbh->do("ALTER TABLE $new_table_name_quote RENAME TO $orig_table_name_quote");
    });
}

#pod =head2 remove_fks_from_child_tables_stmts
#pod
#pod     @stmts = $helper->remove_fks_from_child_tables_stmts if $helper->child_fks_need_adjusting;
#pod
#pod Return a list of statements needed to remove FKs from the child tables.  These will be
#pod run through L<DBIx::OnlineDDL/dbh_runner_do>.
#pod
#pod Only used if L</child_fks_need_adjusting> is true.
#pod
#pod =cut

sub remove_fks_from_child_tables_stmts {
    my $self    = shift;
    my $dbh     = $self->dbh;
    my $fk_hash = $self->vars->{foreign_keys}{definitions};

    my @stmts;
    foreach my $tbl_fk_name (sort keys %{$fk_hash->{child}}) {
        my $fk = $fk_hash->{child}{$tbl_fk_name};

        # Ignore self-joined FKs
        next if $fk->{fk_table_name} eq $self->table_name || $fk->{fk_table_name} eq $self->new_table_name;

        # ANSI SQL, of course
        push @stmts, join(' ',
            'ALTER TABLE',
            $dbh->quote_identifier( $fk->{fk_table_name} ),
            'DROP CONSTRAINT',
            $dbh->quote_identifier( $fk->{fk_name} ),
        );
    }

    return @stmts;
}

#pod =head2 rename_fks_back_to_original_stmts
#pod
#pod     @stmts = $helper->rename_fks_back_to_original_stmts if $helper->dbms_uses_global_fk_namespace;
#pod
#pod Return a list of statements needed to rename the FKs back to their original names.  These will be
#pod run through L<DBIx::OnlineDDL/dbh_runner_do>.
#pod
#pod Only used if L</dbms_uses_global_fk_namespace> is true.
#pod
#pod =cut

sub rename_fks_back_to_original_stmts {
    my $self    = shift;
    my $dbh     = $self->dbh;
    my $fks     = $self->vars->{foreign_keys};
    my $fk_hash = $fks->{definitions};

    my $table_name = $self->table_name;

    my @stmts;
    foreach my $tbl_fk_name (sort keys %{$fk_hash->{parent}}) {
        my $fk = $fk_hash->{parent}{$tbl_fk_name};

        my $changed_fk_name = $fk->{fk_name};
        my $orig_fk_name    = $fks->{orig_names}{"$table_name.$changed_fk_name"};

        unless ($orig_fk_name) {
            $self->progress->message("WARNING: Did not find original FK name for $table_name.$changed_fk_name!");
            next;
        }

        # _fk_to_sql uses this directly, so just change it at the $fk hashref
        $fk->{fk_name} = $orig_fk_name;

        push @stmts, join("\n",
            "ALTER TABLE ".$dbh->quote_identifier($table_name),
            "    DROP CONSTRAINT ".$dbh->quote_identifier( $changed_fk_name ).',',
            "    ADD CONSTRAINT ".$self->fk_to_sql($fk)
        );
    }

    return @stmts;
}

#pod =head2 add_fks_back_to_child_tables_stmts
#pod
#pod     @stmts = $helper->add_fks_back_to_child_tables_stmts if $helper->child_fks_need_adjusting;
#pod
#pod Return a list of statements needed to add FKs back to the child tables.  These will be
#pod run through L<DBIx::OnlineDDL/dbh_runner_do>.
#pod
#pod Only used if L</child_fks_need_adjusting> is true.
#pod
#pod =cut

sub add_fks_back_to_child_tables_stmts {
    my $self    = shift;
    my $dbh     = $self->dbh;
    my $fk_hash = $self->vars->{foreign_keys}{definitions};

    my @stmts;
    foreach my $tbl_fk_name (sort keys %{$fk_hash->{child}}) {
        my $fk = $fk_hash->{child}{$tbl_fk_name};

        # Ignore self-joined FKs
        next if $fk->{fk_table_name} eq $self->table_name || $fk->{fk_table_name} eq $self->new_table_name;

        $self->dbh_runner_do(join ' ',
            "ALTER TABLE",
            $dbh->quote_identifier( $fk->{fk_table_name} ),
            "ADD CONSTRAINT",
            $self->fk_to_sql($fk),
        );
    }

    return @stmts;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::OnlineDDL::Helper::Base - Private OnlineDDL helper for RDBMS-specific code

=head1 VERSION

version v0.920.1

=head1 DESCRIPTION

This is a private helper module for any RDBMS-specific code.  B<As a private module, any
methods or attributes here are subject to change.>

You should really be reading documentation for L<DBIx::OnlineDDL>.  The documentation
here is mainly to benefit any developers who might want to create their own subclass
module for their RDBMS and submit it to us.  Or fix bugs with the existing helpers.

=head1 PRIVATE ATTRIBUTES

=head2 online_ddl

Points back to the parent L<DBIx::OnlineDDL>.  This comes with a bunch of handles to be
able to call common methods with fewer keystrokes.

=head1 PRIVATE CLASS "ATTRIBUTES"

=head2 dbms_uses_global_fk_namespace

If true, OnlineDDL will rename the FKs in the new table to make sure they don't conflict,
and rename them back after the swap.

=head2 child_fks_need_adjusting

If true, OnlineDDL will call helper methods to adjust FKs bound to child tables.

=head2 null_safe_equals_op

This is the operator that the DB uses for NULL-safe equals comparisons.  It would match
this truth table:

       0 <op> 0    --> TRUE
       0 <op> 1    --> FALSE
       0 <op> NULL --> FALSE (instead of NULL)
    NULL <op> NULL --> TRUE  (instead of NULL)

The ANSI SQL version is C<IS NOT DISTINCT FROM>, but others RDBMS typically use something
less bulky.

=head1 PRIVATE HELPER METHODS

As the base module, all of these methods will use ANSI SQL, since there is no assumption
of the type of RDBMS used yet.  Some of these methods may just immediately die, as there
may not be a (safe) standard way of doing that task.

=head2 current_catalog_schema

    ($catalog, $schema) = $helper->current_catalog_schema;

Figure out the currently-selected catalog and schema (database name) from the database.

=head2 insert_select_stmt

    $insert_select_stmt = $helper->insert_select_stmt($column_list_str);

Return an C<INSERT...SELECT> statement to copy rows from the old table to the new, in
such a way that doesn't cause "duplicate row" errors.  This is used by
L<DBIx::BatchChunker> for the copy operation, so it will need C<BETWEEN ? AND ?>
placeholders.

=head2 post_connection_stmts

    @stmts = $helper->post_connection_stmts;

These are the SQL statements to run right after a C<$dbh> re-connect, typically session
variable set statements.

=head2 is_error_retryable

    $bool = $helper->is_error_retryable($error);

Returns true if the specified error string (or exception object from DBIC/D:C:R) is
retryable.  Retryable errors generally fall under the categories of: lock contentions,
lost DB connections, and query interruptions.

=head2 create_table_sql

    $sql = $helper->create_table_sql($table_name);

Get the C<CREATE TABLE> SQL statement for the specified table.  This is RDBMS-specific,
since C<information_schema> isn't always available and usually doesn't house all of the
details, anyway.

=head2 rename_fks_in_table_sql

    $sql = $helper->rename_fks_in_table_sql($table_name, $sql)
        if $helper->dbms_uses_global_fk_namespace;

Given the C<CREATE TABLE> SQL, return the statement with the FKs renamed.  This should
use C<find_new_identifier> to find a valid name.

Only used if L</dbms_uses_global_fk_namespace> is true.

=head2 has_triggers_on_table

    die if $helper->has_triggers_on_table($table_name);

Return true if triggers exist on the given table.  This is a fail-safe to make sure the
table is trigger-free prior to the operation.

=head2 find_new_trigger_identifier

    $trigger_name = $helper->find_new_trigger_identifier($trigger_name);

Return a free trigger identifier to use in the new trigger, using the inputted name as a
base.  This should use C<find_new_identifier> to find a valid name.

=head2 modify_trigger_dml_stmts

    $helper->modify_trigger_dml_stmts( \%trigger_dml_stmts );

Given the DML SQL statements to be plugged into the triggers, mutate the statements,
tailored to the RDBMS.  The input is a hashref of SQL statements for the following keys:

    replace            # used in the INSERT/UPDATE triggers
    delete_for_update  # used in the UPDATE trigger
    delete_for_delete  # used in the DELETE trigger

Since it's already a reference, this method will mutate the SQL strings.

=head2 analyze_table

    $helper->analyze_table($table_name);

Run the DDL statement to re-analyze the table, typically C<ANALYZE TABLE>.

=head2 swap_tables

    $helper->swap_tables($new_table_name, $orig_table_name, $old_table_name);

Runs the SQL to swap the tables in a safe and atomic manner.  The default ANSI SQL
solution is to run two C<ALTER TABLE> statements in a transaction, but only if the RDBMS
supports transactional DDL.

=head2 remove_fks_from_child_tables_stmts

    @stmts = $helper->remove_fks_from_child_tables_stmts if $helper->child_fks_need_adjusting;

Return a list of statements needed to remove FKs from the child tables.  These will be
run through L<DBIx::OnlineDDL/dbh_runner_do>.

Only used if L</child_fks_need_adjusting> is true.

=head2 rename_fks_back_to_original_stmts

    @stmts = $helper->rename_fks_back_to_original_stmts if $helper->dbms_uses_global_fk_namespace;

Return a list of statements needed to rename the FKs back to their original names.  These will be
run through L<DBIx::OnlineDDL/dbh_runner_do>.

Only used if L</dbms_uses_global_fk_namespace> is true.

=head2 add_fks_back_to_child_tables_stmts

    @stmts = $helper->add_fks_back_to_child_tables_stmts if $helper->child_fks_need_adjusting;

Return a list of statements needed to add FKs back to the child tables.  These will be
run through L<DBIx::OnlineDDL/dbh_runner_do>.

Only used if L</child_fks_need_adjusting> is true.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2020 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
