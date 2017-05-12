package Mock::Trigger;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};
use DBIx::Skinny::Mixin modules => [
    qw/BulkInsertWithTrigger/,
];

sub setup_test_db {
    my $class = shift;
    $class->do(q{
        CREATE TABLE mock_trigger_pre (
            id   INT,
            name TEXT
        )
    });
    $class->do(q{
        CREATE TABLE mock_trigger_post (
            id   INT,
            name TEXT
        )
    });
    $class->do(q{
        CREATE TABLE mock_trigger_post_delete (
            id   INT,
            name TEXT
        )
    });
}

1;

