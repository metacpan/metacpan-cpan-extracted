package DBIx::OnlineDDL::Helper::MySQL;

our $AUTHORITY = 'cpan:GSG';
# ABSTRACT: Private OnlineDDL helper for MySQL-specific code
use version;
our $VERSION = 'v0.930.1'; # VERSION

use v5.10;
use Moo;

extends 'DBIx::OnlineDDL::Helper::Base';

use Types::Standard qw( InstanceOf );

use DBI::Const::GetInfoType;
use Sub::Util qw( set_subname );

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

    # Disable /x flag to allow for whitespace within string, but turn it on for newlines
    # and comments.
    return $error =~ m<
        # Locks
        (?-x:deadlock found)|
        (?-x:wsrep detected deadlock/conflict)|
        (?-x:lock wait timeout exceeded)|

        # Connections
        (?-x:mysql server has gone away)|
        (?-x:lost connection to mysql server)|

        # Queries
        (?-x:query execution was interrupted)|

        # Failovers
        (?-x:wsrep has not yet prepared node for application use)
    >xi;
}

sub create_table_sql {
    my ($self, $table_name) = @_;

    my $table_name_quote = $self->dbh->quote_identifier($table_name);

    my $create_sql;
    $self->dbh_runner(run => set_subname '_create_table_sql', sub {
        $create_sql = $_->selectrow_hashref("SHOW CREATE TABLE $table_name_quote")->{'Create Table'};
    });

    return $create_sql;
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

sub has_triggers_on_table {
    my ($self, $table_name) = @_;

    return $self->dbh_runner(run => set_subname '_has_triggers_on_table', sub {
        $_->selectrow_array(
            'SELECT trigger_name FROM information_schema.triggers WHERE event_object_schema = DATABASE() AND event_object_table = ?',
            undef, $table_name
        );
    });
}

sub find_new_trigger_identifier {
    my ($self, $trigger_name) = @_;

    return $self->find_new_identifier(
        $trigger_name => sub {
            $_[0]->selectrow_array(
                'SELECT trigger_name FROM information_schema.triggers WHERE trigger_schema = DATABASE() AND trigger_name = ?',
                undef, $_[1]
            );
        },
    );
}

sub modify_trigger_dml_stmts {
    my ($self, $stmts) = @_;

    # Ignore errors
    $stmts->{delete_for_update} =~ s/^DELETE/DELETE IGNORE/;
    $stmts->{delete_for_update} =~ s/^DELETE/DELETE IGNORE/;
}

# Keep Base->analyze_table

sub swap_tables {
    my ($self, $new_table_name, $orig_table_name, $old_table_name) = @_;
    my $dbh = $self->dbh;

    my $new_table_name_quote  = $dbh->quote_identifier($new_table_name);
    my $orig_table_name_quote = $dbh->quote_identifier($orig_table_name);
    my $old_table_name_quote  = $dbh->quote_identifier($old_table_name);

    $self->dbh_runner_do(
        "RENAME TABLE $orig_table_name_quote TO $old_table_name_quote, $new_table_name_quote TO $orig_table_name_quote"
    );
}

### NOTE: The typical SQL in DBD::mysql is badly optimized for MySQL 5 and very large sets
### of databases/table/column combos.  Furthermore, the kludgy join to TABLE_CONSTRAINTS
### is entirely unnecessary.  See also: https://github.com/perl5-dbi/DBD-mysql/issues/326
sub foreign_key_info {
    my $self   = shift;
    my $dbh    = $self->dbh;
    my ($mver) = ($dbh->get_info($GetInfoType{SQL_DBMS_VER}) =~ /(\d+)\./);

    # MySQL 8's information_schema implementation isn't a complete dumpster fire of
    # in-memory jank, and totes won't send your precious DB server into a horrible
    # OOM death.  So, skip this noise in that case.
    #
    # More info: https://mysqlserverteam.com/mysql-8-0-improvements-to-information_schema/
    return $dbh->foreign_key_info(@_) if $mver >= 8;
    return if $mver < 5;  # not supported by OnlineDDL, anyway

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::OnlineDDL::Helper::MySQL - Private OnlineDDL helper for MySQL-specific code

=head1 VERSION

version v0.930.1

=head1 DESCRIPTION

This is a private helper module for any MySQL-specific code.  B<As a private module, any
methods or attributes here are subject to change.>

You should really be reading documentation for L<DBIx::OnlineDDL>.  Or, if you want to
create a helper module for a different RDBMS, read the docs for
L<DBIx::OnlineDDL::Helper::Base>.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2021 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
