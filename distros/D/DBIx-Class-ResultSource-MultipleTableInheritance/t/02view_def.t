use strict;
use warnings;
use lib 't/lib';
use File::Temp;
use Test::More tests => 5;
use Test::Exception;
use LoadTest;

BEGIN {
    $ENV{DBIC_TRACE} = 0;
}

my ( $dsn, $user, $pass )
    = @ENV{ map {"DBICTEST_PG_${_}"} qw/DSN USER PASS/ };

SKIP: {
    skip 'Set $ENV{DBICTEST_PG_(DSN|USER|PASS)} to run this test (NOTE: This test drops and creates some tables)', 5 unless $dsn && $user;

    dies_ok { LoadTest->source('Foo')->view_definition }
    "Can't generate view def without connected schema";

    my $schema = LoadTest->connect( $dsn, $user, $pass );
    $schema->storage->ensure_connected;
    $schema->storage->dbh->{Warn} = 0;

    my $dir = "t/sql";    # tempdir(CLEANUP => 0);

    lives_ok { $schema->create_ddl_dir( ['PostgreSQL'], 0.1, $dir ) }
    "It's OK to create_ddl_dir";
    lives_ok {
        $schema->deploy( { add_drop_table => 1, add_drop_view => 1, } );
    }
    "It's also OK to deploy the schema";

    isa_ok(
        $schema->source('Bar'),
        'DBIx::Class::ResultSource::View',
        "My MTI class also"
    );

    my $sqlt_object = $schema->{sqlt};

    is_deeply(
        [ map { $_->name } $sqlt_object->get_views ],
        [   qw/
                foo
                bar
                /
        ],
        "SQLT view order triumphantly matches our order."
    );
}
