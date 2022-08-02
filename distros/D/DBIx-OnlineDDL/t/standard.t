#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test::OnlineDDL;

############################################################

my $CHUNK_SIZE = $CDTEST_MASS_POPULATE ? 5000 : 3;
my $dbms_name  = CDTest->dbms_name;

############################################################

onlineddl_test 'No-op copy' => 'Track' => sub {
    my $cd_schema  = shift;
    my $track_rsrc = $cd_schema->source('Track');
    my $dbh        = $cd_schema->storage->dbh;

    # Constructor
    my $online_ddl = DBIx::OnlineDDL->new(
        rsrc => $track_rsrc,
        # purposely not adding any (useful) coderef_hooks
        coderef_hooks => { before_triggers => sub {} },

        copy_opts => {
            chunk_size => $CHUNK_SIZE,
        },
    );

    is $online_ddl->table_name,     'track',      'Figured out table_name';
    is $online_ddl->new_table_name, '_track_new', 'Figured out new_table_name';

    my $helper = $online_ddl->_helper;
    my $mmver  = $helper->mmver;

    my $orig_table_track_sql  = $helper->create_table_sql('track');
    my $orig_table_lyrics_sql = $helper->create_table_sql('lyrics');  # has FK pointing to track

    try_ok { $online_ddl->execute } 'Execute works';

    is $online_ddl->copy_opts->{id_name}, 'trackid', 'Figured out PK';

    my $new_table_track_sql  = $helper->create_table_sql('track');
    my $new_table_lyrics_sql = $helper->create_table_sql('lyrics');

    # Remove AUTO_INCREMENT information
    $orig_table_track_sql  =~ s/ AUTO_INCREMENT=\K\d+/###/;
    $orig_table_lyrics_sql =~ s/ AUTO_INCREMENT=\K\d+/###/;
    $new_table_track_sql   =~ s/ AUTO_INCREMENT=\K\d+/###/;
    $new_table_lyrics_sql  =~ s/ AUTO_INCREMENT=\K\d+/###/;

    is $new_table_track_sql,  $orig_table_track_sql,  'New table SQL for `track` matches the old one';
    SKIP: {
        skip "MySQL versions below 5.7 cannot fix the index problem", 1 if $dbms_name eq 'MySQL' && $mmver < 5.007;
        is $new_table_lyrics_sql, $orig_table_lyrics_sql, 'New table SQL for `lyrics` matches the old one';
    };
};

onlineddl_test 'Existing triggers' => 'Track' => sub {
    my $cd_schema  = shift;
    my $track_rsrc = $cd_schema->source('Track');
    my $dbh        = $cd_schema->storage->dbh;

    # Constructor (another no-op)
    my $online_ddl = DBIx::OnlineDDL->new(
        rsrc => $track_rsrc,
        coderef_hooks => { before_triggers => sub {} },
        copy_opts => {
            chunk_size => $CHUNK_SIZE,
        },
    );

    my $helper = $online_ddl->_helper;
    my $mmver  = $helper->mmver;

    # Add a few new triggers
    my (@trigger_sql, @trigger_qnames);
    foreach my $trigger_type (qw< INSERT UPDATE DELETE >) {
        my $trigger_name = $helper->find_new_trigger_identifier(
            "track_oddltest_".lc($trigger_type)
        );
        my $trigger_qname = $dbh->quote_identifier($trigger_name);
        my $table_qname   = $dbh->quote_identifier('track');

        push @trigger_sql, join("\n",
            "CREATE TRIGGER $trigger_qname BEFORE $trigger_type ON $table_qname FOR EACH ROW",
            'BEGIN',

            # SQLite doesn't like empty procedures in its triggers.  MySQL is fine with them, but doesn't like
            # returning a result set from a trigger.
            ($dbms_name eq 'SQLite' ? 'SELECT 1;' : ''),

            'END'
        );
        push @trigger_qnames, $trigger_qname;
    }

    try_ok {
        $online_ddl->dbh_runner_do(@trigger_sql);
    } 'Triggers created';

    my $should_execute = $dbms_name eq 'MySQL' && $mmver >= 5.007;

    if ($should_execute) {
        try_ok { $online_ddl->execute } 'Execute works';
    }
    else {
        like(
            dies { $online_ddl->execute },
            qr<Found conflicting triggers>,
            'Execute dies due to triggers',
        );
    }

    # Get rid of the triggers
    try_ok {
        $online_ddl->dbh_runner_do( map { "DROP TRIGGER IF EXISTS $_" } @trigger_qnames );
    } 'Triggers dropped';
};

onlineddl_test 'Add column' => 'Track' => sub {
    my $cd_schema  = shift;
    my $track_rsrc = $cd_schema->source('Track');

    # Constructor
    my $online_ddl = DBIx::OnlineDDL->new(
        rsrc => $track_rsrc,
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

        copy_opts => {
            chunk_size => $CHUNK_SIZE,
        },
    );

    try_ok { $online_ddl->execute } 'Execute works';

    # Verify the column exists
    my $dbh     = $cd_schema->storage->dbh;
    my $vars    = $online_ddl->_vars;
    my $catalog = $vars->{catalog};
    my $schema  = $vars->{schema};

    my %cols = %{ $dbh->column_info( $catalog, $schema, 'track', '%' )->fetchall_hashref('COLUMN_NAME') };
    like(
        $cols{test_column},
        {
            TABLE_CAT        => $catalog,
            TABLE_SCHEM      => $schema,
            TABLE_NAME       => 'track',
            COLUMN_NAME      => 'test_column',
            COLUMN_SIZE      => 100,
            TYPE_NAME        => 'VARCHAR',
            IS_NULLABLE      => 'YES',
            NULLABLE         => 1,
            ORDINAL_POSITION => 7,
        },
        'New column exists in table',
    );
};

onlineddl_test 'Add column + title change' => 'Track' => sub {
    my $cd_schema  = shift;
    my $track_rsrc = $cd_schema->source('Track');

    # Constructor
    my $online_ddl = DBIx::OnlineDDL->new(
        rsrc => $track_rsrc,
        coderef_hooks => {
            before_triggers => sub {
                my $oddl = shift;
                my $dbh  = $oddl->dbh;
                my $name = $oddl->new_table_name;

                my $qname = $dbh->quote_identifier($name);
                my $qcol  = $dbh->quote_identifier('test_column');
                my $qidx  = $dbh->quote_identifier('track_cd_title');

                $oddl->dbh_runner_do(
                    "ALTER TABLE $qname ADD COLUMN $qcol VARCHAR(100) NULL",

                    # SQLite can't DROP on an ALTER TABLE, but isn't bothered by the breaking of
                    # a unique index (for some reason)
                    ($dbms_name eq 'SQLite' ? () :
                        "ALTER TABLE $qname DROP INDEX $qidx"
                    )
                );
            },
            before_swap => sub {
                my $oddl = shift;
                my $dbh  = $oddl->dbh;
                my $name = $oddl->new_table_name;

                my $qname = $dbh->quote_identifier($name);

                DBIx::BatchChunker->construct_and_execute(
                    chunk_size => $CHUNK_SIZE,
                    process_past_max => 1,

                    dbic_storage => $oddl->rsrc->storage,
                    min_stmt => "SELECT MIN(trackid) FROM $qname",
                    max_stmt => "SELECT MAX(trackid) FROM $qname",
                    stmt     => join( ' ',
                        'UPDATE',
                        $dbh->quote_identifier($name),
                        'SET title =',
                        $dbh->quote('This is the song that never ends'),
                        'WHERE trackid BETWEEN ? AND ?',
                    ),
                );
            },
        },

        copy_opts => {
            chunk_size => $CHUNK_SIZE,
        },
    );

    try_ok { $online_ddl->execute } 'Execute works';

    # Verify the column exists
    my $dbh     = $cd_schema->storage->dbh;
    my $vars    = $online_ddl->_vars;
    my $catalog = $vars->{catalog};
    my $schema  = $vars->{schema};

    my %cols = %{ $dbh->column_info( $catalog, $schema, 'track', '%' )->fetchall_hashref('COLUMN_NAME') };
    like(
        $cols{test_column},
        {
            TABLE_CAT        => $catalog,
            TABLE_SCHEM      => $schema,
            TABLE_NAME       => 'track',
            COLUMN_NAME      => 'test_column',
            COLUMN_SIZE      => 100,
            TYPE_NAME        => 'VARCHAR',
            IS_NULLABLE      => 'YES',
            NULLABLE         => 1,
            ORDINAL_POSITION => 7,
        },
        'New column exists in table',
    );
};

onlineddl_test 'Drop column' => 'Track' => sub {
    plan skip_all => 'SQLite cannot drop columns' if $dbms_name eq 'SQLite';

    my $cd_schema  = shift;
    my $track_rsrc = $cd_schema->source('Track');

    # Constructor
    my $online_ddl = DBIx::OnlineDDL->new(
        rsrc => $track_rsrc,
        coderef_hooks => {
            before_triggers => sub {
                my $oddl = shift;
                my $dbh  = $oddl->dbh;
                my $name = $oddl->new_table_name;

                my $qname = $dbh->quote_identifier($name);
                my $qcol  = $dbh->quote_identifier('last_updated_at');

                $oddl->dbh_runner_do("ALTER TABLE $qname DROP COLUMN $qcol");
            },
        },

        copy_opts => {
            chunk_size => $CHUNK_SIZE,
        },
    );

    try_ok { $online_ddl->execute } 'Execute works';

    # Verify the column doesn't exist
    my $dbh     = $cd_schema->storage->dbh;
    my $vars    = $online_ddl->_vars;
    my $catalog = $vars->{catalog};
    my $schema  = $vars->{schema};

    my %cols = %{ $dbh->column_info( $catalog, $schema, 'track', '%' )->fetchall_hashref('COLUMN_NAME') };

    ok(!exists $cols{last_updated_at}, 'Column dropped in table', $cols{last_updated_at});
};

onlineddl_test 'Drop PK' => 'Track' => sub {
    plan skip_all => 'SQLite cannot drop columns' if $dbms_name eq 'SQLite';

    my $cd_schema  = shift;
    my $track_rsrc = $cd_schema->source('Track');

    # Constructor
    my $online_ddl = DBIx::OnlineDDL->new(
        rsrc => $track_rsrc,
        coderef_hooks => {
            before_triggers => sub {
                my $oddl = shift;
                my $dbh  = $oddl->dbh;
                my $name = $oddl->new_table_name;

                my $qname = $dbh->quote_identifier($name);
                my $qcol  = $dbh->quote_identifier('trackid');

                $oddl->dbh_runner_do("ALTER TABLE $qname DROP COLUMN $qcol");

                my $fk_hash = $oddl->dbh_runner(run => sub {
                    # Need to also drop the FK on lyrics
                    return $oddl->_fk_info_to_hash( $oddl->_helper->foreign_key_info(
                        $oddl->_vars->{catalog}, $oddl->_vars->{schema}, $oddl->table_name,
                        undef, undef, undef
                    ) );
                });

                $oddl->dbh_runner_do(join ' ',
                    'ALTER TABLE',
                    $dbh->quote_identifier('lyrics'),
                    'DROP',
                    # MySQL uses 'FOREIGN KEY' on DROPs, and everybody else uses 'CONSTRAINT' on both
                    ($dbms_name eq 'MySQL' ? 'FOREIGN KEY' : 'CONSTRAINT'),
                    $dbh->quote_identifier( (values %$fk_hash)[0]->{fk_name} ),
                );
            },
        },

        copy_opts => {
            chunk_size => $CHUNK_SIZE,
        },
    );

    try_ok { $online_ddl->execute } 'Execute works';

    # Verify the column doesn't exist
    my $dbh     = $cd_schema->storage->dbh;
    my $vars    = $online_ddl->_vars;
    my $catalog = $vars->{catalog};
    my $schema  = $vars->{schema};

    my %cols = %{ $dbh->column_info( $catalog, $schema, 'track', '%' )->fetchall_hashref('COLUMN_NAME') };

    ok(!exists $cols{trackid}, 'PK column dropped in table', $cols{trackid});
};

############################################################

done_testing;
