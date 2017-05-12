use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 5;
use Test::Exception;
use NoSequenceSalad;

BEGIN {
    $ENV{DBIC_TRACE} = 0;
}
my ( $dsn, $user, $pass )
    = @ENV{ map {"DBICTEST_PG_${_}"} qw/DSN USER PASS/ };

SKIP: {
    skip 'Set $ENV{DBICTEST_PG_(DSN|USER|PASS)} to run this test (NOTE: This test drops and creates some tables)', 5 unless $dsn && $user;

    my $schema = NoSequenceSalad->connect( $dsn, $user, $pass );
    $schema->storage->ensure_connected;
    $schema->storage->dbh->{Warn} = 0;
    $schema->storage->_use_insert_returning(0);

    my $dir = "t/sql";    # tempdir(CLEANUP => 0);
    $schema->create_ddl_dir( ['PostgreSQL'], 0.1, $dir );

    lives_ok { $schema->deploy( { add_drop_table => 1, add_drop_view => 1 } ) }
    "I can deploy the schema";

    isa_ok(
        $schema->source('Mesclun'),
        'DBIx::Class::ResultSource::View',
        "My MTI class also"
    );

    my ( $bowl_of_salad, $bowl_of_salad1 );

    lives_ok {
        $bowl_of_salad = $schema->resultset('Mesclun')
            ->create( { acidity => 4, spiciness => '10', fresh => 0, } );
    }
    "I can call a create on a view mesclun";

    lives_ok {
        $bowl_of_salad1 = $schema->resultset('Salad')->create( { fresh => 1 } );
    }
    "I can do it for the other view, too";

    my $sqlt_object = $schema->{sqlt};

    is_deeply(
        [ map { $_->name } $sqlt_object->get_views ],
        [   qw/
                salad
                mesclun
                /
        ],
        "SQLT view order triumphantly matches our order."
    );
}
