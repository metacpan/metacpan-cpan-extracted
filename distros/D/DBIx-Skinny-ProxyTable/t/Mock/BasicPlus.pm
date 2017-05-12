package Mock::BasicPlus;
use DBIx::Skinny connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

# you can run test with MYSQL if set env SKINNY_MYSQL_DSN.
my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};
if ( $dsn ) {
    __PACKAGE__->connect_info(+{dsn => $dsn, username => $username, password => $password });
}

use DBIx::Skinny::Mixin modules => [qw(ProxyTable)];

sub setup_test_db {
    my $self = shift;
    for my $table ( qw/ used_log / ) {
        $self->do(sprintf(q{
            DROP TABLE IF EXISTS %s;
        }, $table));
    }
    $self->do(q{
        CREATE TABLE used_log (
            id   INT,
            used_on  DATE,
            count           INT
        )
    });
}

sub creanup_test_db {
}

1;

