package DBIx::OnlineDDL::Helper::MySQL;

our $AUTHORITY = 'cpan:GSG';
# ABSTRACT: Private OnlineDDL helper for MySQL-specific code
use version;
our $VERSION = 'v1.1.1'; # VERSION

use v5.10;
use Moo;

extends 'DBIx::OnlineDDL::Helper::Base';

use Types::Standard qw( Bool );

use DBI::Const::GetInfoType;
use DBIx::ParseError::MySQL;
use List::Util qw( first );
use Sub::Util  qw( set_subname );

use namespace::clean;  # don't export the above

#pod =encoding utf8
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a private helper module for any MySQL-specific code.  B<As a private module, any
#pod methods or attributes here are subject to change.>
#pod
#pod You should really be reading documentation for L<DBIx::OnlineDDL>.  Or, if you want to
#pod create a helper module for a different RDBMS, read the docs for
#pod L<DBIx::OnlineDDL::Helper::Base>.
#pod
#pod =cut

sub dbms_uses_global_fk_namespace { 1 }
sub child_fks_need_adjusting      { 1 }
sub null_safe_equals_op           { '<=>' }

sub current_catalog_schema {
    my $self = shift;

    my ($schema) = $self->dbh->selectrow_array('SELECT DATABASE()');
    return (undef, $schema);
}

has is_galera_cluster => (
    is   => 'lazy',
    isa  => Bool,
);

sub _build_is_galera_cluster {
    my $self = shift;

    my ($name, $val) = $self->dbh->selectrow_array("SHOW GLOBAL STATUS LIKE 'wsrep_cluster_size'");
    return $val && int($val) && $val > 1;
}

sub insert_select_stmt {
    my ($self, $column_list_str) = @_;

    my $dbh = $self->dbh;

    my $id_name_quote = $dbh->quote_identifier( $self->copy_opts->{id_name} );

    my $orig_table_name_quote = $dbh->quote_identifier($self->table_name);
    my $new_table_name_quote  = $dbh->quote_identifier($self->new_table_name);

    # Use INSERT IGNORE to ignore dupe key errors.  The LOCK IN SHARE MODE write-locks
    # the source rows until they are copied.  If anything needs to make any changes after
    # that, the triggers will cover those.
    return join("\n",
        "INSERT IGNORE INTO $new_table_name_quote",
        "    ($column_list_str)",
        "SELECT",
        "    $column_list_str",
        "FROM $orig_table_name_quote",
        "WHERE $id_name_quote BETWEEN ? AND ?",
        "LOCK IN SHARE MODE"
    );
}

sub post_connection_stmts {
    my $self = shift;

    # Initialize these cached attributes
    $self->mmver;
    $self->is_galera_cluster;

    my $db_timeouts = $self->db_timeouts;
    return (
        # Use the right database, just in case it's not in the DSN.
        "USE ".$self->dbh->quote_identifier($self->vars->{schema}),

        # Foreign key constraints should not interrupt the process.  Nor should they be
        # checked when trying to add or remove them.  This would cause a simple FK DDL
        # to turn into a long-running operation on pre-existing tables.
        'SET SESSION foreign_key_checks=0',

        # DB timeouts
        'SET SESSION wait_timeout='.$db_timeouts->{session},
        'SET SESSION lock_wait_timeout='.$db_timeouts->{lock_db},
        'SET SESSION innodb_lock_wait_timeout='.$db_timeouts->{lock_row},
    );
}

sub is_error_retryable {
    my ($self, $error) = @_;
    return DBIx::ParseError::MySQL->new($error)->is_transient;
}

sub create_table_sql {
    my ($self, $table_name) = @_;

    my $table_name_quote = $self->dbh->quote_identifier($table_name);

    return $self->dbh_runner(run => set_subname '_create_table_sql', sub {
        # SHOW CREATE TABLE reports two columns, so might as well pull it out by name
        local $_->{FetchHashKeyName} = 'NAME_uc';
        $_->selectrow_hashref("SHOW CREATE TABLE $table_name_quote")->{'CREATE TABLE'};
    });
}

sub rename_fks_in_table_sql {
    my ($self, $table_name, $table_sql) = @_;

    my $dbh = $self->dbh;

    # Since MySQL uses a global namespace for foreign keys, these will have to be renamed
    my $iq_chars = $dbh->get_info( $GetInfoType{SQL_IDENTIFIER_QUOTE_CHAR} ) || '`';
    $iq_chars .= '"';  # include ANSI quotes

    my $iqre     = '['.quotemeta($iq_chars).']';
    my $noniq_re = '[^'.quotemeta($iq_chars).'\s]';

    my @fk_names = ($table_sql =~ /CONSTRAINT ${iqre}(${noniq_re}+)${iqre} FOREIGN KEY/ig);

    foreach my $fk_name (@fk_names) {
        my $new_fk_name = $self->find_new_identifier(
            "_${fk_name}" => set_subname '_fk_name_finder', sub {
                $_[0]->selectrow_array(
                    'SELECT table_name FROM information_schema.key_column_usage WHERE '.join(' AND ',
                        'constraint_schema = DATABASE()',
                        'constraint_name = ?',
                        # This is required for MySQL 5 server table cache optimization in the EXPLAIN plan
                        'table_schema = DATABASE()',
                    ), undef, $_[1]
                );
            },
        );
        $self->vars->{foreign_keys}{orig_names}{"$table_name.$new_fk_name"} = $fk_name;

        my $fk_name_re = quotemeta $fk_name;
        $table_sql =~ s/(?<=CONSTRAINT ${iqre})$fk_name_re(?=${iqre} FOREIGN KEY)/$new_fk_name/;
    }

    return $table_sql;
}

sub has_conflicting_triggers_on_table {
    my ($self, $table_name) = @_;
    my $mmver = $self->mmver;

    # Multiple triggers aren't allowed in MySQL 5.6
    if ($mmver < 5.007) {
        return $self->dbh_runner(run => set_subname '_has_triggers_on_table', sub {
            $_->selectrow_array(
                'SELECT trigger_name FROM information_schema.triggers WHERE event_object_schema = DATABASE() AND event_object_table = ?',
                undef, $table_name
            );
        });
    }
    # MySQL 5.7+ allows them, so look for anything that looks like a leftover OnlineDDL
    # trigger name.
    else {
        return $self->dbh_runner(run => set_subname '_has_onlineddl_triggers_on_table', sub {
            $_->selectrow_array(
                'SELECT trigger_name FROM information_schema.triggers WHERE '.join(' AND ',
                    'event_object_schema = DATABASE()',
                    'event_object_table = ?',
                    'trigger_name LIKE ?',
                ), undef, $table_name, "\%${table_name}\\_onlineddl\\_\%"
            );
        });
    }
}

sub has_triggers_on_table_to_be_copied {
    my ($self, $table_name) = @_;
    my $mmver = $self->mmver;
    # Multiple triggers aren't allowed on MySQL 5.6, so there's nothing to copy
    return 0 if $mmver < 5.007;

    # Look for anything that isn't a leftover OnlineDDL trigger name.
    return $self->dbh_runner(run => set_subname '_has_non_onlineddl_triggers_on_table', sub {
        $_->selectrow_array(
            'SELECT trigger_name FROM information_schema.triggers WHERE '.join(' AND ',
                'event_object_schema = DATABASE()',
                'event_object_table = ?',
                'trigger_name NOT LIKE ?',
            ), undef, $table_name, "\%${table_name}\\_onlineddl\\_\%"
        );
    });
}

sub find_new_trigger_identifier {
    my ($self, $trigger_name) = @_;

    return $self->find_new_identifier(
        $trigger_name => sub {
            $_[0]->selectrow_array(
                'SELECT trigger_name FROM information_schema.triggers WHERE event_object_schema = DATABASE() AND trigger_name = ?',
                undef, $_[1]
            );
        },
    );
}

sub modify_trigger_dml_stmts {
    my ($self, $stmts) = @_;

    # Ignore errors
    $stmts->{delete_for_update} =~ s/^DELETE/DELETE IGNORE/;
    $stmts->{delete_for_delete} =~ s/^DELETE/DELETE IGNORE/;
}

# Keep Base->analyze_table

sub swap_tables {
    my ($self, $new_table_name, $orig_table_name, $old_table_name) = @_;
    my $dbh   = $self->dbh;
    my $mmver = $self->mmver;

    # Galera MySQL 8 has the potential to enter a bad MDL BF-BF conflict state, if the
    # cluster is under enough load to make synchronous replication fall a bit behind and
    # a RENAME TABLE statement is ran.  This workaround makes a broad assumption that the
    # bug is some sort of race condition between the statements that make updates to the
    # table, and the RENAME TABLE statement.  Thus, we give replication a chance to catch
    # up first before we execute the RENAME TABLE statement.
    #
    # More info: https://perconadev.atlassian.net/browse/PXC-4512

    if ($mmver >= 8 && $self->is_galera_cluster) {
        $self->progress->message("    Sleeping for 5 seconds");
        sleep 5;
    }

    my $new_table_name_quote  = $dbh->quote_identifier($new_table_name);
    my $orig_table_name_quote = $dbh->quote_identifier($orig_table_name);
    my $old_table_name_quote  = $dbh->quote_identifier($old_table_name);

    $self->dbh_runner_do(
        "RENAME TABLE $orig_table_name_quote TO $old_table_name_quote, $new_table_name_quote TO $orig_table_name_quote"
    );
}

sub get_trigger_data {
    my ($self, $table_name) = @_;
    my $mmver = $self->mmver;
    # Multiple triggers aren't allowed on MySQL 5.6, so there's nothing to copy
    return 0 if $mmver < 5.007;

    # Look for anything that isn't a leftover OnlineDDL trigger name.
    $self->dbh_runner(run => set_subname '_non_onlineddl_triggers_on_table', sub {
        local $_->{FetchHashKeyName} = 'NAME_lc';
        $self->vars->{existing_triggers} = $_->selectall_hashref(
            'SELECT * FROM information_schema.triggers WHERE '.join(' AND ',
                'event_object_schema = DATABASE()',
                'event_object_table = ?',
                'trigger_name NOT LIKE ?',
            ), 'trigger_name', undef, $table_name, "\%${table_name}\\_onlineddl\\_\%"
        );
    });
}

### NOTE: The typical SQL in DBD::mysql is badly optimized for MySQL 5 and very large sets
### of databases/table/column combos.  Furthermore, the kludgy join to TABLE_CONSTRAINTS
### is entirely unnecessary.  See also: https://github.com/perl5-dbi/DBD-mysql/issues/326
sub foreign_key_info {
    my $self  = shift;
    my $dbh   = $self->dbh;
    my $mmver = $self->mmver;

    # MySQL 8's information_schema implementation isn't a complete dumpster fire of
    # in-memory jank, and totes won't send your precious DB server into a horrible
    # OOM death.  So, skip this noise in that case.
    #
    # More info: https://mysqlserverteam.com/mysql-8-0-improvements-to-information_schema/
    return $dbh->foreign_key_info(@_) if $mmver >= 8;
    return if $mmver < 5;  # not supported by OnlineDDL, anyway

    my (
        $pk_catalog, $pk_schema, $pk_table,
        $fk_catalog, $fk_schema, $fk_table,
    ) = @_;

    my $sql = <<'EOF';
SELECT
   NULL AS PKTABLE_CAT,
   REFERENCED_TABLE_SCHEMA AS PKTABLE_SCHEM,
   REFERENCED_TABLE_NAME AS PKTABLE_NAME,
   REFERENCED_COLUMN_NAME AS PKCOLUMN_NAME,
   TABLE_CATALOG AS FKTABLE_CAT,
   TABLE_SCHEMA AS FKTABLE_SCHEM,
   TABLE_NAME AS FKTABLE_NAME,
   COLUMN_NAME AS FKCOLUMN_NAME,
   ORDINAL_POSITION AS KEY_SEQ,
   NULL AS UPDATE_RULE,
   NULL AS DELETE_RULE,
   CONSTRAINT_NAME AS FK_NAME,
   NULL AS PK_NAME,
   NULL AS DEFERABILITY,
   NULL AS UNIQUE_OR_PRIMARY
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
EOF

    ### XXX: This breaks OnlineDDL's re-applying of cross-database FKs in foreign child
    ### tables.  But, without this fix, MySQL has to scan all databases to find them.
    ### Again, this is no longer a problem with MySQL 8.
    $fk_schema //= $pk_schema;

    my @where;
    my @bind;

    if (defined $pk_schema) {
        push @where, 'REFERENCED_TABLE_SCHEMA = ?';
        push @bind, $pk_schema;
    }

    if (defined $pk_table) {
        push @where, 'REFERENCED_TABLE_NAME = ?';
        push @bind, $pk_table;
    }

    if (defined $fk_schema) {
        push @where, 'TABLE_SCHEMA = ?';
        push @bind,  $fk_schema;
    }

    if (defined $fk_table) {
        push @where, 'TABLE_NAME = ?';
        push @bind,  $fk_table;
    }

    if (@where) {
        $sql .= "\nWHERE ";
        $sql .= join ' AND ', @where;
    }
    $sql .= "\nORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION";

    # NOTE: This FetchHashKeyName setting is consistent with how DBI's *_info methods column names work.
    local $dbh->{FetchHashKeyName} = 'NAME_uc';
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);

    return $sth;
}

# MySQL uses 'FOREIGN KEY' on DROPs, for some reason
around 'remove_fks_from_child_tables_stmts' => sub {
    my $orig  = shift;
    my @stmts = $orig->(@_);

    return map { s/ DROP CONSTRAINT / DROP FOREIGN KEY /; $_ } @stmts;
};

around 'rename_fks_back_to_original_stmts' => sub {
    my $orig  = shift;
    my @stmts = $orig->(@_);

    return map { s/ DROP CONSTRAINT / DROP FOREIGN KEY /; $_ } @stmts;
};

# Keep Base->add_fks_back_to_child_tables_stmts (no DROPs on those)

# Look for default FK-created indexes that get mysteriously renamed after the FKs are
# recreated. (SM-3039)
sub post_fk_add_cleanup_stmts {
    my $self     = shift;
    my $dbh      = $self->dbh;
    my $mmver    = $self->mmver;
    my $vars     = $self->vars;
    my $catalog  = $vars->{catalog};
    my $schema   = $vars->{schema};
    my $idx_hash = $vars->{indexes}{definitions};

    my @stmts;
    foreach my $table_name (sort keys %$idx_hash) {
        my %old_idx_data = %{ $idx_hash->{$table_name} };
        my %new_idx_data = %{ $self->get_idx_hash($table_name) };

        foreach my $index_name (sort keys %old_idx_data) {
            next if $index_name eq 'PRIMARY';

            my $old_idx = $old_idx_data{$index_name};
            my $new_idx = $new_idx_data{$index_name};
            my $old_col_str = join ', ', @{$old_idx->{columns}};

            next if $new_idx &&
                $old_col_str eq join(', ', @{$new_idx->{columns}}) &&
                $old_idx->{unique} == $new_idx->{unique}
            ;

            # It failed one of the other checks?
            if ($new_idx) {
                my $conditional =
                    $old_idx->{unique} != $new_idx->{unique} ?
                    ($new_idx->{unique} ? "it is now UNIQUE" : "it is no longer UNIQUE") :
                    "its columns have changed (".join(', ', @{$new_idx->{columns}}).")"
                ;

                $self->progress->message( join "\n",
                    '',
                    "WARNING: Found index $table_name.$index_name ($old_col_str), but $conditional!",
                    "Please double-check that the indexes on the table are what you expect!",
                    '',
                );
                next;
            }

            # It looks like we have a mismatch at this point.  Try to find the renamed index.
            $new_idx = first {
                $_->{name} ne 'PRIMARY' &&
                $old_col_str eq join(', ', @{$_->{columns}}) &&
                $old_idx->{unique} == $_->{unique}
            } values %new_idx_data;

            # It disappeared?
            unless ($new_idx) {
                $self->progress->message( join "\n",
                    '',
                    "WARNING: Found index $table_name.$index_name ($old_col_str), which may have been renamed, but a matching index cannot be found!",
                    "Please double-check that the indexes on the table are what you expect!",
                    '',
                );
                next;
            }

            my $new_index_name = $new_idx->{name};

            # We can only rename in MySQL 5.7
            if ($mmver < 5.007) {
                $self->progress->message( join "\n",
                    '',
                    "WARNING: Found index $table_name.$index_name ($old_col_str), which was renamed to $new_index_name!",
                    "The index cannot safely renamed in MySQL $mmver, so you may need to DROP/ADD this",
                    "index a different way to correct the problem.",
                    '',
                );
                next;
            }

            # Finally, add a RENAME INDEX statement
            push @stmts, join(' ',
                "ALTER TABLE",
                $dbh->quote_identifier( $table_name ),
                "RENAME INDEX",
                $dbh->quote_identifier( $new_index_name ),
                "TO",
                $dbh->quote_identifier( $index_name ),
            );
        }
    }

    return @stmts;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::OnlineDDL::Helper::MySQL - Private OnlineDDL helper for MySQL-specific code

=head1 VERSION

version v1.1.1

=head1 DESCRIPTION

This is a private helper module for any MySQL-specific code.  B<As a private module, any
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
