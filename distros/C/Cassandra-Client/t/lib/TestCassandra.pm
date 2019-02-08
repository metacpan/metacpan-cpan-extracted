package TestCassandra;
use 5.010;
use strict;
use warnings;

use Cassandra::Client;

sub is_ok {
    return !!$ENV{CASSANDRA_HOST};
}

sub new {
    my ($class, %args)= @_;
    return Cassandra::Client->new(
        contact_points   => [split /,/, $ENV{CASSANDRA_HOST}],
        username         => $ENV{CASSANDRA_USER},
        password         => $ENV{CASSANDRA_AUTH},
        tls              => $ENV{CASSANDRA_TLS},
        port             => $ENV{CASSANDRA_PORT},
        anyevent         => ((rand() < 0.5) ? 1 : 0),
        protocol_version => ((rand() < 0.5) ? 4 : 3),
        %args
    );
}

1;
