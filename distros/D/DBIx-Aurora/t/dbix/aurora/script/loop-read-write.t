use strict;
use warnings;
use Test::More ($ENV{RUN_LOOP_READ_WRITE} ? () : (skip_all => 'set hosts into RUN_LOOP_READ_WRITE env var'));
use DBIx::Aurora;
use Time::HiRes;

my @hosts = split /,/, $ENV{RUN_LOOP_READ_WRITE};

my $args = sub {
    my ($database, $hosts) = @_;
    return (
        TEST => {
            instances => [
                map {
                    my $dsn = "dbi:mysql:database=$database;host=$_;port=3306";
                    [
                        [ $dsn, "awsuser", "awspassword",
                            {
                                RaiseError => 1,
                                AutoCommit => 0,
                                mysql_connect_timeout => 1,
                                mysql_write_timeout   => 1,
                                mysql_read_timeout    => 1,
                            }
                        ],
                        {}
                    ]
                } @$hosts
            ],
            opts => { }
        }
    )
};

sleep 1;

DBIx::Aurora->new($args->(mysql => \@hosts))->test->writer(sub {
    shift->do("CREATE DATABASE IF NOT EXISTS test");
});

my $aurora = DBIx::Aurora->new($args->(test => \@hosts));
$aurora->test->writer(sub {
    shift->do(<<SQL);
CREATE TABLE IF NOT EXISTS users (
    user_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name    VARCHAR(64)  NOT NULL,
    PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL
});

sleep 1;

my $counter = {
    writer_success => 0,
    writer_failure => 0,
    reader_success => 0,
    reader_failure => 0,
};

my $id = 1;
while (1) {
    $id++;
    my $name = rand;

    my $rv = eval { $aurora->test->writer(sub { shift->do("INSERT INTO users(name) VALUES(?)", undef, $name) }) };
    if (my $e = $@) {
        $counter->{writer_failure}++;
    } else {
        $counter->{writer_success}++;
    }

    my $row = eval { $aurora->test->reader(sub { shift->selectrow_hashref("SELECT * FROM users WHERE user_id = ?", {}, $id) }) };
    if (my $e = $@) {
        $counter->{reader_failure}++;
    } else {
        $counter->{reader_success}++;
    }

    printf "\r[%10.05f] <Writer> Success: %10d Failure: %10d <Reader> Success: %10d Failure: %10d ",
        Time::HiRes::time, @$counter{qw/ writer_success writer_failure reader_success reader_failure /};
    Time::HiRes::sleep 0.1;
}

ok 1;

done_testing;

