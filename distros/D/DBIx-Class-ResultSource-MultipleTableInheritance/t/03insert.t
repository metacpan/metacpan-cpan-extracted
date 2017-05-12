use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 4;
use Test::Exception;
use CafeInsertion;

BEGIN {
    $ENV{DBIC_TRACE} = 0;
}

my ( $dsn, $user, $pass )
    = @ENV{ map {"DBICTEST_PG_${_}"} qw/DSN USER PASS/ };
SKIP: {
    skip 'Set $ENV{DBICTEST_PG_(DSN|USER|PASS)} to run this test (NOTE: This test drops and creates some tables)', 4 unless $dsn && $user;

    my $schema = CafeInsertion->connect( $dsn, $user, $pass );
    $schema->storage->ensure_connected;
    $schema->storage->_use_insert_returning(0);
    $schema->storage->dbh->{Warn} = 0;

    my $dir = "t/sql";    # tempdir(CLEANUP => 0);
    $schema->create_ddl_dir( ['PostgreSQL'], 0.1, $dir );
    $schema->deploy( { add_drop_table => 1, add_drop_view => 1 } );

    isa_ok(
        $schema->source('Sumatra'),
        'DBIx::Class::ResultSource::View',
        "My MTI class also"
    );

    my ( $drink, $drink1 );

    lives_ok {
        $drink = $schema->resultset('Sumatra')->create(
            {   sweetness => 4,
                fat_free  => 1,
                aroma     => 'earthy',
                flavor    => 'great'
            }
        );
    }
    "I can call a create on a view sumatra";

    lives_ok {
        $drink1 = $schema->resultset('Coffee')->create( { flavor => 'aaight', } );
    }
    "I can do it for the other view, too";

    my $sqlt_object = $schema->{sqlt};
    is_deeply(
        [ map { $_->name } $sqlt_object->get_views ],
        [   qw/
                coffee
                sumatra
                /
        ],
        "SQLT view order triumphantly matches our order."
    );
}
