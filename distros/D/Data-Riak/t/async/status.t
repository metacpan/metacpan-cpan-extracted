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

my $cv = AE::cv;
$riak->status({
    cb       => sub { $cv->send(@_) },
    error_cb => sub { $cv->croak(@_) },
});

is ref $cv->recv, 'HASH';

done_testing;
