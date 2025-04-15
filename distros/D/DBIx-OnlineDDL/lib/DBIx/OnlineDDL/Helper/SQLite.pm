package DBIx::OnlineDDL::Helper::SQLite;

our $AUTHORITY = 'cpan:GSG';
# ABSTRACT: Private OnlineDDL helper for SQLite-specific code
use version;
our $VERSION = 'v1.1.0'; # VERSION

use v5.10;
use Moo;

extends 'DBIx::OnlineDDL::Helper::Base';

use Types::Standard qw( InstanceOf );

use Sub::Util qw( set_subname );

use namespace::clean;  # don't export the above

#pod =encoding utf8
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a private helper module for any SQLite-specific code.  B<As a private module, any
#pod methods or attributes here are subject to change.>
#pod
#pod You should really be reading documentation for L<DBIx::OnlineDDL>.  Or, if you want to
#pod create a helper module for a different RDBMS, read the docs for
#pod L<DBIx::OnlineDDL::Helper::Base>.
#pod
#pod =cut

sub dbms_uses_global_fk_namespace { 0 }
sub child_fks_need_adjusting      { 0 }
sub null_safe_equals_op           { 'IS' }

sub current_catalog_schema {
    my $self = shift;

    my $databases = $self->dbh->selectall_hashref('PRAGMA database_list', 'seq');
    my $schema = $databases->{0}{name};  # probably 'main'
    return (undef, $schema);
}

sub insert_select_stmt {
    my ($self, $column_list_str) = @_;

    my $dbh = $self->dbh;

    my $id_name_quote = $dbh->quote_identifier( $self->copy_opts->{id_name} );

    my $orig_table_name_quote = $dbh->quote_identifier($self->table_name);
    my $new_table_name_quote  = $dbh->quote_identifier($self->new_table_name);

    # Use INSERT OR IGNORE to ignore dupe key errors
    return join("\n",
        "INSERT OR IGNORE INTO $new_table_name_quote",
        "    ($column_list_str)",
        "SELECT",
        "    $column_list_str",
        "FROM $orig_table_name_quote",
        "WHERE $id_name_quote BETWEEN ? AND ?",
    );
}

sub post_connection_stmts {
    my $self = shift;

    my $db_timeouts = $self->db_timeouts;
    my @stmts = (
        # See FK comment in MySQL module.  FKs in SQLite are a per-connection enabled
        # feature, so this is always a "session" command.
        'PRAGMA foreign_keys = OFF',

        # DB timeouts
        'PRAGMA busy_timeout = '.int($db_timeouts->{lock_file} * 1_000),  # busy_timeout uses ms
    );

    # SQLite version 3.25.0 fixes table renames to also rename references to the table,
    # ie: child FKs.  Since SQLite doesn't yet have an DDL statement for renaming the FKs
    # back to the old name, setting this PRAGMA variable is the only option.
    #
    # Also, while this change was introduced in 3.25.0, it seems to only manifest itself
    # when the driver reports version 3.26.0, possibly due to how their production
    # releases work.
    push @stmts, 'PRAGMA legacy_alter_table = ON' if $self->mmver >= 3.026;

    return @stmts;
}

sub is_error_retryable {
    my ($self, $error) = @_;

    # Disable /x flag to allow for whitespace within string, but turn it on for newlines
    # and comments.
    return $error =~ m<
        # Locks
        (?-x:database( table)? is locked)|

        # Connections
        (?-x:attempt to [\w\s]+ on inactive database handle)|

        # Queries
        (?-x:query aborted)|
        (?-x:interrupted)
    >xi;
}

sub create_table_sql {
    my ($self, $table_name) = @_;

    my $create_sql;
    $self->dbh_runner(run => set_subname '_create_table_sql', sub {
        ($create_sql) = $_->selectrow_array('SELECT sql FROM sqlite_master WHERE name = ?', undef, $table_name);
    });

    return $create_sql;
}

# Keep Base->rename_fks_in_table_sql (not used)

sub has_conflicting_triggers_on_table {
    my ($self, $table_name) = @_;

    return $self->dbh_runner(run => set_subname '_has_triggers_on_table', sub {
        $_->selectrow_array(
            'SELECT name FROM sqlite_master WHERE type = ? AND tbl_name = ?',
            undef, 'trigger', $table_name
        );
    });
}

# Always zero; multiple triggers per table/type aren't allowed
sub has_triggers_on_table_to_be_copied { 0 }

sub find_new_trigger_identifier {
    my ($self, $trigger_name) = @_;

    return $self->find_new_identifier(
        $trigger_name => sub {
            $_[0]->selectrow_array(
                'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
                undef, 'trigger', $_[1]
            );
        },
    );
}

# Keep Base->modify_trigger_dml_stmts (nothing changed)

sub analyze_table {
    my ($self, $table_name) = @_;
    my $table_name_quote = $self->dbh->quote_identifier($table_name);
    $self->dbh_runner_do("ANALYZE $table_name_quote");
}

# Keep Base->swap_tables (has transactional DDL)

# Keep the trigger methods (not used)

# Keep the other FK methods (not used)

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::OnlineDDL::Helper::SQLite - Private OnlineDDL helper for SQLite-specific code

=head1 VERSION

version v1.1.0

=head1 DESCRIPTION

This is a private helper module for any SQLite-specific code.  B<As a private module, any
methods or attributes here are subject to change.>

You should really be reading documentation for L<DBIx::OnlineDDL>.  Or, if you want to
create a helper module for a different RDBMS, read the docs for
L<DBIx::OnlineDDL::Helper::Base>.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2025 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
