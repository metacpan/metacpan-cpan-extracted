use strict;
use warnings;

use t::cotengtest;
use Test::More;

use DBIx::Sunny;

subtest use => sub {
    use_ok "Coteng";
};

subtest new => sub {
    my $coteng = Coteng->new({
        connect_info => {
            db_master => {
                dsn     => 'dbi:SQLite::memory:',
                user    => 'nobody',
                passwd  => 'nobody',
            },
            db_slave => {
                dsn     => 'dbi:SQLite::memory:',
                user    => 'nobody',
                passwd  => 'nobody',
            },
        },
    });

    if (ok $coteng) {
        isa_ok $coteng, "Coteng";
        is_deeply $coteng->{connect_info}{db_master}, {
            dsn     => 'dbi:SQLite::memory:',
            user    => 'nobody',
            passwd  => 'nobody',
        };
        is_deeply $coteng->{connect_info}{db_slave}, {
            dsn     => 'dbi:SQLite::memory:',
            user    => 'nobody',
            passwd  => 'nobody',
        };
    }
};

subtest db => sub {

    my $coteng = Coteng->new({
        connect_info => {
            db_master => {
                dsn => 'dbi:SQLite::memory:',
            },
            db_slave => {
                dsn => 'dbi:SQLite::memory:',
            },
        },
    });

    isa_ok $coteng->db('db_master'), 'Coteng';
    is $coteng->current_dbname, 'db_master';

    isa_ok $coteng->db('db_slave'),  'Coteng';
    is $coteng->current_dbname, 'db_slave';

};

subtest dbh => sub {

    subtest 'hash reference' => sub {
        my $coteng = Coteng->new({
            connect_info => {
                db_master => {
                    dsn => 'dbi:SQLite::memory:',
                },
                db_slave => {
                    dsn => 'dbi:SQLite::memory:',
                },
            },
        });
        isa_ok $coteng->dbh('db_master'), 'Coteng::DBI::db';
        isa_ok $coteng->dbh('db_slave'),  'Coteng::DBI::db';
    };

    subtest 'array reference' => sub {
        my $coteng = Coteng->new({
            connect_info => {
                db_master   => [ 'dbi:SQLite::memory:' ],
                db_slave    => [ 'dbi:SQLite::memory:' ],
            },
        });
        isa_ok $coteng->dbh('db_master'), 'Coteng::DBI::db';
        isa_ok $coteng->dbh('db_slave'),  'Coteng::DBI::db';
    };

};

my $coteng = Coteng->new({
    connect_info => {
        db_master => {
            dsn => "dbi:SQLite::memory:",
        },
    },
});
$coteng->current_dbname('db_master');
my $dbh = $coteng->dbh;
create_table($dbh);
local *Coteng::dbh = sub { $dbh };

subtest single => sub {
    my $id = insert_mock($dbh, name => "mock1");

    subtest 'without class, use hashref' => sub {
        my $row = $coteng->single(mock => {
            id => $id,
        });
        isa_ok $row, "HASH";
        is $row->{name}, "mock1";
    };

    subtest 'without class, use SQL::Maker::Condition' => sub {
        my $row = $coteng->single(mock =>
            SQL::Maker::Condition->new->add(id => $id)
        );
        isa_ok $row, "HASH";
        is $row->{name}, "mock1";
    };

    subtest 'with class' => sub {
        my $row = $coteng->single(mock => {
            id => $id,
        }, 'Coteng::Model::Mock');
        isa_ok $row, "Coteng::Model::Mock";
        is $row->name, "mock1";
    };
};

subtest search => sub {
    my $id = insert_mock($dbh, name => "mock2");

    subtest 'without class, use hashref' => sub {
        my $rows = $coteng->search(mock => {
            name => "mock2",
        });
        isa_ok $rows, "ARRAY";
        is scalar(@$rows), 1;
        isa_ok $rows->[0], "HASH";
    };

    subtest 'without class, use SQL::Maker::Condition' => sub {
        my $rows = $coteng->search(mock =>
            SQL::Maker::Condition->new->add(name => "mock2")
        );
        isa_ok $rows, "ARRAY";
        is scalar(@$rows), 1;
        isa_ok $rows->[0], "HASH";
    };

    subtest 'with class' => sub {
        my $rows = $coteng->search(mock => {
            id => $id,
        }, 'Coteng::Model::Mock');
        is scalar(@$rows), 1;
        isa_ok $rows->[0], "Coteng::Model::Mock";
        is $rows->[0]->name, "mock2";
    };
};

subtest fast_insert => sub {
    my $id = $coteng->fast_insert(mock => {
        name => "mock3",
    });

    my $row = $coteng->single(mock => {
        name => "mock3",
    });
    if (ok $row) {
        is $id, $row->{id};
    }
};

subtest insert => sub {
    my $row = $coteng->insert(mock => {
        name => "mock4",
    });

    my $found_row = $coteng->single(mock => {
        name => "mock4",
    });
    if (ok $found_row) {
        is_deeply $row, $found_row;
    }
};

subtest bulk_insert => sub {
    my $row = $coteng->bulk_insert(mock => [
        { name => "mock20" },
        { name => "mock21" },
    ]);

    my $found_row = $coteng->single(mock => {
        name => "mock20" ,
    });
    ok $found_row;
    $found_row = $coteng->single(mock => {
        name => "mock21",
    });
    ok $found_row;
};

subtest update => sub {
    my $id = $coteng->fast_insert(mock => {
        name => "mock5",
    });

    my $updated_row_count = $coteng->update(mock => {
        name => "mock5-heyhey",
    }, { id => $id });

    my $found_row = $coteng->single(mock => {
        name => "mock5",
    });
    ok !$found_row;
    $found_row = $coteng->single(mock => {
        name => "mock5-heyhey",
    });
    ok $found_row;

    is $updated_row_count, 1;
};

subtest delete => sub {
    subtest 'when delete single rows' => sub {
        my $id = $coteng->fast_insert(mock => {
            name => "mock6",
        });

        my $deleted_row_count = $coteng->delete(mock => { id => $id });

        my $found_row = $coteng->single(mock => {
            id => $id,
        });
        ok !$found_row;
        is $deleted_row_count, 1;
    };

    subtest 'when delete multiple rows' => sub {
        my $id1 = $coteng->fast_insert(mock => {
            name => "mock7",
        });
        my $id2 = $coteng->fast_insert(mock => {
            name => "mock8",
        });
        my $deleted_row_count = $coteng->delete(mock => { id => [ $id1, $id2 ]});
        is $deleted_row_count, 2;

        my $found_row = $coteng->single(mock => {
            id => $id1,
        });
        ok !$found_row;
        $found_row = $coteng->single(mock => {
            id => $id2,
        });
        ok !$found_row;
    };
};

subtest single_named => sub {
    my $id = $coteng->fast_insert(mock => {
        name => "mock7",
    });

    subtest 'without class' => sub {
        my $row = $coteng->single_named(q[
            SELECT * FROM mock WHERE id = :id
        ], { id => $id });

        if (ok $row) {
            isa_ok $row, "HASH";
            is $row->{id}, $id;
        }
    };

    subtest 'with class' => sub {
        my $row = $coteng->single_named(q[
            SELECT * FROM mock WHERE id = :id
        ],{
            id => $id,
        }, 'Coteng::Model::Mock');

        if (ok $row) {
            isa_ok $row, "Coteng::Model::Mock";
            is $row->id, $id;
        }
    };
};

subtest single_by_sql => sub {
    my $id = $coteng->fast_insert(mock => {
        name => "mock8",
    });

    subtest 'without class' => sub {
        my $row = $coteng->single_by_sql(q[
            SELECT * FROM mock WHERE id = ?
        ], [ $id ]);

        if (ok $row) {
            isa_ok $row, "HASH";
            is $row->{id}, $id;
        }
    };

    subtest 'with class' => sub {
        my $row = $coteng->single_by_sql(q[
            SELECT * FROM mock WHERE id = ?
        ], [ $id ], "Coteng::Model::Mock");

        if (ok $row) {
            isa_ok $row, "Coteng::Model::Mock";
            is $row->id, $id;
        }
    };

    subtest 'when return value is empty' => sub {
        my $row = $coteng->single_by_sql(q[
            SELECT * FROM mock WHERE id = ?
        ], [ 1000000 ], "Coteng::Model::Mock");

        is $row, '';
    };
};

subtest search_named => sub {
    my $id = $coteng->fast_insert(mock => {
        name => "mock9",
    });

    subtest 'without class' => sub {
        my $rows = $coteng->search_named(q[
            SELECT * FROM mock WHERE id = :id
        ], { id => $id });

        isa_ok $rows, "ARRAY";
        is scalar(@$rows), 1;
        isa_ok $rows->[0], "HASH";
    };

    subtest 'with class' => sub {
        my $rows = $coteng->search_named(q[
            SELECT * FROM mock WHERE id = :id
        ], { id => $id }, "Coteng::Model::Mock");

        isa_ok $rows, "ARRAY";
        is scalar(@$rows), 1;
        isa_ok $rows->[0], "Coteng::Model::Mock";
    };
};

subtest search_by_sql => sub {
    my $id = $coteng->fast_insert(mock => {
        name => "mock10",
    });

    subtest 'without class' => sub {
        my $rows = $coteng->search_by_sql(q[
            SELECT * FROM mock WHERE id = ?
        ], [ $id ]);

        isa_ok $rows, "ARRAY";
        is scalar(@$rows), 1;
        isa_ok $rows->[0], "HASH";
    };

    subtest 'with class' => sub {
        my $rows = $coteng->search_by_sql(q[
            SELECT * FROM mock WHERE id = ?
        ], [ $id ], "Coteng::Model::Mock");

        isa_ok $rows, "ARRAY";
        is scalar(@$rows), 1;
        isa_ok $rows->[0], "Coteng::Model::Mock";
    };

    subtest 'when return value is empty' => sub {
        my $rows = $coteng->search_by_sql(q[
            SELECT * FROM mock WHERE id = ?
        ], [ 1000000 ], "Coteng::Model::Mock");

        is_deeply $rows, [];
    };
};

subtest count => sub {
    subtest 'when return value is not empty' => sub {
        my $id1 = $coteng->fast_insert(mock => {
            name => "mock20",
            delete_fg => 1,
        });
        my $id2 = $coteng->fast_insert(mock => {
            name => "mock21",
            delete_fg => 1,
        });
        my $cnt = $coteng->count('mock', '*', {
            delete_fg => 1,
        });

        is $cnt, 2;
    };
};

subtest execute => sub {
    $coteng->execute(q[
        INSERT INTO mock (name) VALUES (:name)
    ], { name => 'mock11' });

    my $found_row = $coteng->single(mock => {
        name => 'mock11',
    });
    is $found_row->{id}, $coteng->last_insert_id;
};

subtest txn_scope => sub {
    my $txn = $coteng->txn_scope();
    isa_ok $txn, "DBIx::TransactionManager::ScopeGuard";
    $txn->commit;
};

done_testing;
