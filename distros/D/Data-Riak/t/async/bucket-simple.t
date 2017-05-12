#!/usr/bin/env perl

use strict;
use warnings;

use Try::Tiny;

use Test::Fatal;
use Test::More;
use Test::Data::Riak;

use AnyEvent;
use Data::Riak::Async;
use Data::Riak::Async::HTTP;
use Data::Riak::Async::Bucket;

skip_unless_riak;

my $riak = async_riak_transport;

my $bucket_name = create_test_bucket_name;

my $bucket = Data::Riak::Async::Bucket->new({
    name => $bucket_name,
    riak => $riak,
});

{
    my $cv = AE::cv;
    $bucket->count({
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });
    is $cv->recv, 0, 'No keys in the bucket';
}

{
    my $cv = AE::cv;
    my $props = $bucket->props({
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is ref $cv->recv, 'HASH', '... got back a HASH ref';
}

{
    my $cv = AE::cv;
    $bucket->add('foo', 'bar', {
        cb       => sub { $cv->send },
        error_cb => sub { $cv->croak(@_) },
    });
    $cv->recv;
}

my $obj = do {
    my $cv = AE::cv;
    $bucket->get('foo', {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });
    $cv->recv;
};

is $obj->value, 'bar', 'Check the value immediately after insertion';
is $obj->key, 'foo', 'Name property is inflated correctly';
is $obj->bucket_name, $bucket_name, 'Bucket name property is inflated correctly';

{
    my $cv = AE::cv;
    $bucket->get(foo => {
        accept   => 'application/json',
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    my $e = exception { $cv->recv };
    ok $e, 'asking for an incompatible content type fails';
    isa_ok $e, 'Data::Riak::Exception::ClientError';
    is $e->transport_response->code, 406,
        'asking for an incompatible content type fails with a 406';
}

{
    my $cv = AE::cv;
    $bucket->list_keys({
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is_deeply $cv->recv, ['foo'], '... got the keys we expected';
}

{
    my $cv = AE::cv;
    $bucket->count({
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is $cv->recv, 1, 'One key in the bucket';
}

{
    my $cv = AE::cv;
    $bucket->remove('foo', {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });
    $cv->recv;
}

{
    my $cv = AE::cv;
    $bucket->get('foo', {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    my $e = exception { $cv->recv };
    isa_ok $e, 'Data::Riak::Exception::ObjectNotFound';
    like $e, qr/Object not found/;
    isa_ok $e->request, 'Data::Riak::Request::GetObject';
    is $e->request->bucket_name, $bucket_name;
    is $e->request->key, 'foo';
    is $e->transport_response->code, "404",
        "Calling for a value that doesn't exist returns 404";
}

{
    sleep 5;
    my $cv = AE::cv;
    $bucket->remove('foo', {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });
    my $res;
    is exception { $res = $cv->recv }, undef,
        'removing a non-existent key is non-fatal';
    ok !$res->first->has_vector_clock, 'no vclock when removing missing keys';
}

{
    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (cb => sub { $cv->send(@_) }, error_cb => sub { $cv->croak(@_) })
    };

    $bucket->add('bar' => 'value of bar', {
        links => [
            Data::Riak::Link->new(
                bucket  => $bucket_name,
                riaktag => 'buddy',
                key     => 'foo',
            ),
        ],
        $get_cbs->(),
    });

    $bucket->add('baz', 'value of baz', {
        links => [
            $bucket->create_link(
                riaktag => 'buddy',
                key     => 'foo',
            ),
        ],
        $get_cbs->(),
    });

    $bucket->add('foo', 'value of foo', {
        links => [
            $bucket->create_link({
                riaktag => 'not a buddy',
                key     => 'bar',
            }),
            $bucket->create_link({
                riaktag => 'not a buddy',
                key     => 'baz',
            }),
        ],
        $get_cbs->(),
    });

    $_->recv for @cvs;
}

{

    my $cv = AE::cv;
    $bucket->list_keys({
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is_deeply [sort @{ $cv->recv }], ['bar', 'baz', 'foo'],
        '... got the keys we expected';
}

{
    my $cv = AE::cv;
    $bucket->count({
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is $cv->recv, 3, 'Three keys in the bucket';
}

{
    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (cb => sub { $cv->send(@_) }, error_cb => sub { $cv->croak(@_) });
    };

    $bucket->get($_, { $get_cbs->() }) for qw(foo bar baz);
    my ($foo, $bar, $baz) = map { $_->recv } @cvs;

    is $foo->value, 'value of foo', 'correct value for foo';
    is $bar->value, 'value of bar', 'correct value for bar';
    is $baz->value, 'value of baz', 'correct value for baz';
}

{
    my $cv = AE::cv;
    $bucket->linkwalk('foo', [[ 'not a buddy', '_' ]], {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    my $resultset = $cv->recv;
    isa_ok $resultset, 'Data::Riak::ResultSet';
    is @{$resultset->results}, 2, 'Got two Riak::Results back from linkwalking foo';
}

{
    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (cb => sub { $cv->send(@_) }, error_cb => sub { $cv->croak(@_) });
    };

    $bucket->linkwalk(
        'foo', [[ 'not a buddy', '_' ]],
        { $get_cbs->() },
    );

    $bucket->linkwalk(
        'bar', [ [ 'buddy', '_' ], [ $bucket_name, 'not a buddy', '_' ] ],
        { $get_cbs->() },
    );

    my ($resultset, $dw_results) = map { $_->recv } @cvs;

    is scalar $dw_results->all, 2, 'Got two Riak::Results back from linkwalking bar';
}

{
    my $cv = AE::cv;
    $riak->_buckets({
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    ok +(grep { $_ eq $bucket_name } @{ $cv->recv }),
       '_buckets lists our new bucket';
}

remove_test_bucket($bucket);

done_testing;
