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

our $VERSION = '0.21';    ## VERSION

{
    # We need to store the Test::PostgreSQL handle somewhere to prevent
    # premature destruction of the database.
    package Data::Chronicle::Mock::Connector;    ## no critic
    use strict;
    use warnings;
    use parent qw/DBIx::Connector/;

    sub testdb {
        my $self = shift;
        if (@_) {
            $self->{' p g s q l '} = shift;
        }
        return $self->{' p g s q l '};
    }
}

# This is to resolve a compatibility issue between Test::Mock::Redis (where mget returns an array)
#   and RedisDB (where mget returns an arrayref).
use Test::MockModule;
my $mocked_mock_redis = Test::MockModule->new('Test::Mock::Redis');
$mocked_mock_redis->mock('mget', sub { return [$mocked_mock_redis->original('mget')->(@_)] });

=head3 C<< my $ch = get_mocked_chronicle(); >>

Creates a simulated chronicle connected to a temporary storage.

=cut

sub get_mocked_chronicle {
    my $redis = Test::Mock::Redis->new(server => 'whatever');

    my $pgsql = Test::PostgreSQL->new();
    my $dbic  = Data::Chronicle::Mock::Connector->new($pgsql->dsn);
    $dbic->testdb($pgsql);
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

    return ($chronicle_r, $chronicle_w);
}

1;
