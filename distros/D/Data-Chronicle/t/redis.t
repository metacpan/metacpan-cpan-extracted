use strict;
use warnings;

use Data::Chronicle::Writer;
use RedisDB;
use Date::Utility;
use Test::More;
use Test::Exception;
require Test::NoWarnings;

BEGIN {
    plan skip_all => 'needs TEST_REDIS=redis://localhost:6379' unless $ENV{TEST_REDIS};
}

my $data = {sample => 'data'};

subtest "Call Set after dropping the connection" => sub {

    my $connection = RedisDB->new(url => $ENV{TEST_REDIS});

    my $writer = Data::Chronicle::Writer->new(
        publish_on_set => 1,
        cache_writer   => $connection
    );
    # calling set() which will call mset() and put the flag `multi`
    $writer->set('namespace', 'category', $data, Date::Utility->new, 0);

    # Kill All Client Connections
    my @cmd = qw(redis-cli -p 6379 CLIENT KILL TYPE normal);
    for (1 .. 5) { system(@cmd); sleep(1); }

    # call set again after dropping the connection
    # check the connection will be recreated
    lives_ok(sub { $writer->set('namespace', 'category', $data, Date::Utility->new, 0) }, 'expecting to live');
};

Test::NoWarnings::had_no_warnings();
done_testing;
