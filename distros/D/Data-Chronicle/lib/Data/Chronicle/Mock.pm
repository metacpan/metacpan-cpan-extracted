package Data::Chronicle::Mock;

=head1 NAME

Data::Chronicle::Mock - Mocking utility to test chronicle based scenarios

=cut

use 5.014;
use strict;
use warnings;

use DBIx::Connector;
use Test::PostgreSQL;
use Test::Mock::Redis;
use Data::Chronicle::Reader;
use Data::Chronicle::Writer;

# This is to resolve a compatibility issue between Test::Mock::Redis (where mget returns an array)
#   and RedisDB (where mget returns an arrayref).
use Test::MockModule;
my $mocked_mock_redis = Test::MockModule->new('Test::Mock::Redis');
$mocked_mock_redis->mock('mget', sub { return [$mocked_mock_redis->original('mget')->(@_)] });

our $VERSION = '0.19';    ## VERSION

=head3 C<< my $ch = get_mocked_chronicle(); >>

Creates a simulated chronicle connected to a temporary storage.

=cut

sub get_mocked_chronicle {
    my $redis = Test::Mock::Redis->new(server => 'whatever');

    my $pgsql = Test::PostgreSQL->new();
    my $dbic  = DBIx::Connector->new($pgsql->dsn);
    $dbic->mode('ping');
    my $stmt = qq(CREATE TABLE chronicle (
      id bigserial,
      timestamp TIMESTAMP DEFAULT NOW(),
      category VARCHAR(255),
      name VARCHAR(255),
      value TEXT,
      PRIMARY KEY(id),
      CONSTRAINT search_index UNIQUE(category,name,timestamp)
    ););

    {
        local $SIG{__WARN__} = sub { };
        $dbic->run(sub { $_->do($stmt) });
    }

    my $chronicle_r = Data::Chronicle::Reader->new(
        cache_reader => $redis,
        dbic         => $dbic
    );

    my $chronicle_w = Data::Chronicle::Writer->new(
        cache_writer => $redis,
        dbic         => $dbic,
        ttl          => 86400
    );

    #we need to store a reference to $pgsql or else, as soon as this method
    #is returned, it will be destroyed and connection will be lost.
    $chronicle_r->meta->add_attribute(
        dummy => (
            accessor => 'dummy',
        ));

    $chronicle_w->meta->add_attribute(
        dummy => (
            accessor => 'dummy',
        ));

    $chronicle_r->dummy($pgsql);
    $chronicle_w->dummy($pgsql);

    return ($chronicle_r, $chronicle_w);
}

1;
