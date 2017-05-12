use strict;
use warnings;
use Test::More 0.89;
use Test::Data::Riak;

use AnyEvent;
use Data::Riak::Async;

BEGIN {
    skip_unless_riak;
}

my $riak = async_riak_transport;

my $cv = AE::cv;
$riak->ping({
    cb       => sub { $cv->send(@_)  },
    error_cb => sub { $cv->croak(@_) },
});
ok $cv->recv, 'Riak server to test against';

done_testing;

