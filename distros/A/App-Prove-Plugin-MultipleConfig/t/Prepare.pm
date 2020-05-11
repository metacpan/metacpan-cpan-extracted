package t::Prepare;

use warnings;
use strict;

use Redis;

sub prepare {
    my ($self, $config) = @_;
    my $conf = do $config;

    my $uri = $conf->{DB}->{uri};
    $uri =~ s/database=.+?;/database=mysql;/; # use mysql table
    my $dbh = DBI->connect($uri, $conf->{DB}->{username}, $conf->{DB}->{password},
        {'RaiseError' => 1}
    );
    $self->prepare_db($dbh);
    $dbh->disconnect();

    my $redis = Redis->new ( server => $conf->{REDIS}->{server});
    $self->prepare_redis($redis);
}

sub prepare_db {
    my ($self, $dbh) = @_;
    $dbh->do("GRANT SELECT ON *.* TO 'readonly'\@'%' IDENTIFIED BY 'readonly'") or die $dbh->errstr;

    for my $db_name (qw/test_db/) {
        $dbh->do("CREATE DATABASE IF NOT EXISTS ${db_name}") or die $dbh->errstr;
        $dbh->do("USE ${db_name}") or die $dbh->errstr;
        $dbh->do("CREATE TABLE IF NOT EXISTS example (id INTEGER, name VARCHAR(20))");
    }
}

sub prepare_redis {
    my ($self, $redis) = @_;
    $redis->flushall();
}

1;
