use strict;
use warnings;
use Test::More 0.89;
use Test::Fatal;

use Test::Data::Riak;

BEGIN {
    skip_unless_riak;
}

use Try::Tiny;
use AnyEvent;
use Data::Riak::Async;
use Data::Riak::Async::Bucket;

my $riak = async_riak_transport;

my $bucket_name = create_test_bucket_name;
my $bucket = $riak->bucket( $bucket_name );

my $link = Data::Riak::Link->new(
    bucket  => $bucket_name,
    key     => 'foo',
    riaktag => 'buddy'
);
isa_ok $link, 'Data::Riak::Link';

{
    my $cv = AE::cv;
    $riak->resolve_link($link, {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    my $e = exception { $cv->recv };
    isa_ok $e, 'Data::Riak::Exception::ObjectNotFound';
}

{
    my $cv = AE::cv;
    $bucket->add('foo', 'bar', {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });
    $cv->recv;
}

{
    my $cv = AE::cv;
    $riak->resolve_link($link, {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    my $result = $cv->recv;
    isa_ok $result, 'Data::Riak::Result';
    is $result->key, 'foo', '... got the result we expected';
}

remove_test_bucket($bucket);

done_testing;
