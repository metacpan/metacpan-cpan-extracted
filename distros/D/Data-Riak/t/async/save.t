use strict;
use warnings;
use AnyEvent;
use Try::Tiny;
use Test::More 0.89;
use Test::Fatal;
use Test::Data::Riak;

BEGIN {
    skip_unless_riak;
    use_ok('Data::Riak::Link');
}

use Data::Riak::Async;

my $riak = async_riak_transport;
my $bucket_name = create_test_bucket_name;
my $bucket = $riak->bucket( $bucket_name );

{
    my $cv = AE::cv;
    $bucket->add('foo', 'bar', {
        links => [
            Data::Riak::Link->new(
                bucket => $bucket->name,
                riaktag => 'buddy',
                key => 'baz'
            ),
        ],
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    $cv->recv;
}

my $foo = do {
    my $cv = AE::cv;
    $bucket->get('foo', {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });
    $cv->recv;
};

my $new_foo = $foo->add_link(Data::Riak::Link->new(
    bucket => $bucket->name,
    riaktag => 'buddy',
    key => 'qux',
));

{
    my $cv = AE::cv;
    $new_foo->save(
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    );
    $cv->recv;
}

my $server_foo = do {
    my $cv = AE::cv;
    $bucket->get('foo', {
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });
    $cv->recv;
};

is(scalar @{$server_foo->links}, '3', '... two manual links plus the "up"');

remove_test_bucket($bucket);

done_testing;


