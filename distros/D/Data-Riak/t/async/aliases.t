use strict;
use warnings;
use Test::More 0.89;

use Test::Data::Riak;

BEGIN {
    skip_unless_riak;
}

use Try::Tiny;
use AnyEvent;
use Data::Riak::Async;
use Data::Riak::Async::HTTP;

my $riak = async_riak_transport;

my $bucket_name = create_test_bucket_name;
my $bucket_name2 = create_test_bucket_name;

my $bucket = Data::Riak::Async::Bucket->new({
    name => $bucket_name,
    riak => $riak,
});

my $bucket2 = Data::Riak::Async::Bucket->new({
    name => $bucket_name2,
    riak => $riak,
});

{
    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (cb => sub { $cv->send(@_) }, error_cb => sub { $cv->croak(@_) });
    };

    $_->count({ $get_cbs->() }) for $bucket, $bucket2;
    is $_, 0, 'No keys in the bucket'
        for map { $_->recv } @cvs;
}

my $foo_user_data = '{"username":"foo","email":"foo@example.com"';

{
    my $cv = AE::cv;
    $bucket->add('123456', $foo_user_data, {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });
    $cv->recv;
}

{
    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (cb => sub { $cv->send(@_) }, error_cb => sub { $cv->croak(@_) });
    };

    $bucket->create_alias({
        key => '123456',
        as  => 'foo',
        $get_cbs->(),
    });

    $bucket->create_alias({
        key => '123456',
        as  => 'foo',
        in  => $bucket2,
        $get_cbs->(),
    });

    $_->recv for @cvs;
}

{

    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (cb => sub { $cv->send(@_) }, error_cb => sub { $cv->croak(@_) });
    };

    $bucket->get('123456', { $get_cbs->() });
    $bucket->resolve_alias('foo', { $get_cbs->() });
    $bucket2->resolve_alias('foo', { $get_cbs->() });

    my ($obj, $resolved_obj, $resolved_across_buckets_obj) =
        map { $_->recv } @cvs;

    is $obj->value, $foo_user_data, "Calling for foo's data by ID works";
    is $resolved_obj->value, $foo_user_data,
        "Calling for foo's data by alias works";
    is $resolved_across_buckets_obj->value, $foo_user_data,
        "Calling for foo's data by a cross-bucket alias works";

}

remove_test_bucket($bucket, $bucket2);

done_testing;
