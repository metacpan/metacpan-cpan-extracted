#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test::OnlineDDL;

############################################################

my $CHUNK_SIZE = $CDTEST_MASS_POPULATE ? 5000 : 3;
my $dbms_name  = CDTest->dbms_name;

############################################################

my $blank_schema = CDTest->init_schema( no_connect => 1 );
my @source_names =
    grep { !$blank_schema->source($_)->isa('DBIx::Class::ResultSource::View') }  # no views
    $blank_schema->sources
;

foreach my $source_name (sort @source_names) {
    my %copy_opts = (
        chunk_size => $CHUNK_SIZE,
    );

    # Avoid warnings for multi-column PKs by adding the first column ourselves
    if ($source_name =~ /\wTo[A-Z]/) {
        $copy_opts{id_name} = ($blank_schema->source($source_name)->primary_columns)[0];
    }

    onlineddl_test 'No-op', $source_name, sub {
        my $cd_schema  = shift;
        my $rsrc       = $cd_schema->source($source_name);
        my $table_name = $rsrc->name;

        # Constructor
        my $online_ddl = DBIx::OnlineDDL->new(
            rsrc => $rsrc,
            # purposely not adding any (useful) coderef_hooks
            coderef_hooks => { before_triggers => sub {} },

            copy_opts => \%copy_opts,
        );

        is $online_ddl->table_name,     $table_name,          'Figured out table_name';
        is $online_ddl->new_table_name, "_${table_name}_new", 'Figured out new_table_name';

        my $helper = $online_ddl->_helper;

        my $orig_table_sql = $helper->create_table_sql($table_name);

        try_ok { $online_ddl->execute } 'Execute works';

        my $new_table_sql  = $helper->create_table_sql($table_name);

        # Remove AUTO_INCREMENT information
        $orig_table_sql =~ s/ AUTO_INCREMENT=\K\d+/###/;
        $new_table_sql  =~ s/ AUTO_INCREMENT=\K\d+/###/;

        if ($dbms_name eq 'MySQL') {
            # This can sometimes disappear in MySQL 8, since it considers utf8mb4 the default
            $orig_table_sql =~ s/ CHARACTER SET utf8mb4//g;
            $new_table_sql  =~ s/ CHARACTER SET utf8mb4//g;
        }

        is $new_table_sql, $orig_table_sql,  "New table SQL for `$table_name` matches the old one" or do {
            diag "NEW: $new_table_sql";
            diag "OLD: $orig_table_sql";
        };

        # Verify post-connection variables are still active even after some disconnections.  It
        # seems to be rather hard to query certain SQLite PRAGMA settings, however, so we'll skip
        # the checks for SQLite.
        my $dbh = $cd_schema->storage->dbh;
        if ($dbms_name eq 'MySQL') {
            my $db_timeouts  = $online_ddl->db_timeouts;
            my $session_vals = $dbh->selectrow_hashref(
                'SELECT @@foreign_key_checks AS fk_checks, @@wait_timeout AS timeout_session, '.
                '@@lock_wait_timeout AS timeout_lock_db, @@innodb_lock_wait_timeout AS timeout_lock_row'
            );
            is $session_vals, {
                fk_checks => 0,
                map {; "timeout_$_" => $db_timeouts->{$_} } qw< session lock_db lock_row >
            }, "Session values looks right";
        }
    };

    onlineddl_test 'Add column', $source_name, sub {
        my $cd_schema  = shift;
        my $rsrc       = $cd_schema->source($source_name);
        my $table_name = $rsrc->name;

        # Constructor
        my $online_ddl = DBIx::OnlineDDL->new(
            rsrc => $rsrc,
            coderef_hooks => {
                before_triggers => sub {
                    my $oddl = shift;
                    my $dbh  = $oddl->dbh;
                    my $name = $oddl->new_table_name;

                    my $qname = $dbh->quote_identifier($name);
                    my $qcol  = $dbh->quote_identifier('test_column');

                    $oddl->dbh_runner_do("ALTER TABLE $qname ADD COLUMN $qcol VARCHAR(100) NULL");
                },
            },
            copy_opts => \%copy_opts,
        );

        try_ok { $online_ddl->execute } 'Execute works';

        # Verify the column exists
        my $dbh     = $cd_schema->storage->dbh;
        my $vars    = $online_ddl->_vars;
        my $catalog = $vars->{catalog};
        my $schema  = $vars->{schema};

        my %cols = %{ $dbh->column_info( $catalog, $schema, $table_name, '%' )->fetchall_hashref('COLUMN_NAME') };
        like(
            $cols{test_column},
            {
                TABLE_CAT        => $catalog,
                TABLE_SCHEM      => $schema,
                TABLE_NAME       => $table_name,
                COLUMN_NAME      => 'test_column',
                COLUMN_SIZE      => 100,
                TYPE_NAME        => 'VARCHAR',
                IS_NULLABLE      => 'YES',
                NULLABLE         => 1,
                ORDINAL_POSITION => (scalar $rsrc->columns + 1),
            },
            'New column exists in table',
        );
    };
}

############################################################

done_testing;
