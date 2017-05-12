use strict;
use warnings;
use Test::More 0.89;

use Test::Data::Riak;

BEGIN {
    skip_unless_riak;
}

use AnyEvent;
use Data::Riak::Async;
use Data::Riak::Async::HTTP;

my $riak = async_riak_transport;

my $bucket = $riak->bucket(create_test_bucket_name);
isa_ok $bucket, 'Data::Riak::Async::Bucket';

my $cv = AE::cv;
$bucket->count({
    cb       => sub { $cv->send(@_) },
    error_cb => sub { $cv->croak(@_) },
});
is $cv->recv, 0;

done_testing;
