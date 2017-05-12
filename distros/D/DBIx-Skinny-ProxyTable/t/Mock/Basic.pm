package Mock::Basic;
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
    for my $table ( qw/ access_log access_log_201001 access_log_201002 error_log error_log_20100101 hogehoge_log fugafuga_log ranking ranking_daily/ ) {
        $self->do(sprintf(q{
            DROP TABLE IF EXISTS %s;
        }, $table));
    }
    $self->do(q{
        CREATE TABLE access_log (
            id   INT,
            accessed_on  DATE,
            count           INT
        )
    });
    $self->do(q{
        CREATE TABLE error_log (
            id   INT,
            errored_on  DATE,
            count           INT
        )
    });
    $self->do(q{
        CREATE TABLE hogehoge_log (
            id   INT,
            hogehoged_on  DATE,
            count           INT
        )
    });
    $self->do(q{
        CREATE TABLE fugafuga_log (
            id   INT,
            fugafuga_log  DATE,
            count           INT
        )
    });
    $self->do(q{
        CREATE TABLE ranking (
            id   INT,
            rank INT,
            count INT,
            ranked_on DATE
        )
    });
}

sub creanup_test_db {
}

1;

