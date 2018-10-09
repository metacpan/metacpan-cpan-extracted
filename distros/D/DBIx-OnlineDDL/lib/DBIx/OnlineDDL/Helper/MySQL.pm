package DBIx::OnlineDDL::Helper::MySQL;

our $AUTHORITY = 'cpan:GSG';
our $VERSION   = '0.90';

use v5.10;
use Moo;

extends 'DBIx::OnlineDDL::Helper::Base';

use Types::Standard qw( InstanceOf );

use DBI::Const::GetInfoType;
use Sub::Util qw( set_subname );

use namespace::clean;  # don't export the above

=encoding utf8

=head1 NAME

DBIx::OnlineDDL::Helper::MySQL - Private OnlineDDL helper for MySQL-specific code

=head1 VERSION

version 0.90

=head1 DESCRIPTION

This is a private helper module for any MySQL-specific code.  B<As a private module, any
methods or attributes here are subject to change.>

You should really be reading documentation for L<DBIx::OnlineDDL>.  Or, if you want to
create a helper module for a different RDBMS, read the docs for
L<DBIx::OnlineDDL::Helper::Base>.

=cut

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
        (?-x:Lost connection to mysql server)|

        # Queries
        (?-x:query execution was interrupted)
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
    my $iqre = $dbh->get_info( $GetInfoType{SQL_IDENTIFIER_QUOTE_CHAR} ) || '`';
    $iqre = quotemeta $iqre;

    my @fk_names = ($table_sql =~ /CONSTRAINT ${iqre}([^$iqre\s]+)${iqre} FOREIGN KEY/ig);

    foreach my $fk_name (@fk_names) {
        my $new_fk_name = $self->find_new_identifier(
            "_${fk_name}" => set_subname '_fk_name_finder', sub {
                $_[0]->selectrow_array(
                    'SELECT table_name FROM information_schema.key_column_usage WHERE constraint_schema = DATABASE() AND constraint_name = ?',
                    undef, $_[1]
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

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Grant Street Group

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
