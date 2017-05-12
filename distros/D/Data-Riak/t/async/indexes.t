use strict;
use warnings;
use Test::More 0.89;

use Test::Data::Riak;

BEGIN {
    skip_unless_riak;
    skip_unless_leveldb_backend;
}

use AnyEvent;
use Data::Riak::Async;
use Data::Riak::Async::Bucket;

my $riak = async_riak_transport;

my $bucket_name = create_test_bucket_name;
my $bucket = Data::Riak::Async::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

{
    my $cv = AE::cv;
    $bucket->count({
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is $cv->recv, 0, 'No keys in the bucket';
}

my $foo_user_data = '{"username":"foo","email":"foo@example.com","name_first":"Foo","name_last":"Fooly"';
my $bar_user_data = '{"username":"bar","email":"bar@example.com","name_first":"Bar","name_last":"Barly"';
my $baz_user_data = '{"username":"baz","email":"baz@example.net","name_first":"Baz","name_last":"Barly"';

{
    my @cvs;
    my $get_cbs = sub {
        my $cv = AE::cv;
        push @cvs, $cv;
        (cb => sub { $cv->send(@_) }, error_cb => sub { $cv->croak(@_) });
    };

    $bucket->add(
        'foo-uuid',
        $foo_user_data,
        {
            indexes => [
                { field => 'email_bin', values => [ 'foo@example.com', 'example.com' ]},
                { field => 'username_bin', values => [ 'foo' ]},
                { field => 'name_bin', values => [ 'Foo', 'Fooly', 'Foo Fooly' ]}
            ],
            $get_cbs->(),
        },
    );

    $bucket->add(
        'bar-uuid',
        $bar_user_data,
        {
            indexes => [
                { field => 'email_bin', values => [ 'bar@example.com', 'example.com' ]},
                { field => 'username_bin', values => [ 'bar' ]},
                { field => 'name_bin', values => [ 'Bar', 'Barly', 'Bar Barly' ]}
            ],
            $get_cbs->(),
        },
    );

    $bucket->add(
        'baz-uuid',
        $baz_user_data,
        {
            indexes => [
                { field => 'email_bin', values => [ 'baz@example.net', 'example.net' ]},
                { field => 'username_bin', values => [ 'baz' ]},
                { field => 'name_bin', values => [ 'Baz', 'Barly', 'Baz Barly' ]}
            ],
            $get_cbs->(),
        },
    );

    $_->recv for @cvs;
}

{
    my $cv = AE::cv;
    $bucket->pretty_search_index({
        field    => 'email_bin',
        values   => 'example.com',
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is_deeply $cv->recv, [ 'bar-uuid', 'foo-uuid' ],
        '... example.com search returns the expected results';
}

{
    my $cv = AE::cv;
    $bucket->pretty_search_index({
        field    => 'username_bin',
        values   => 'baz',
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is_deeply $cv->recv, [ 'baz-uuid' ],
        '... username search for baz returns the expected results';
}

{
    my $cv = AE::cv;
    $bucket->pretty_search_index({
        field    => 'name_bin',
        values   => 'Foo Fooly',
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is_deeply $cv->recv, [ 'foo-uuid' ],
        '... name search returns the expected results';
}

{
    my $cv = AE::cv;
    $bucket->pretty_search_index({
        field    => 'name_bin',
        values   => 'Barly',
        cb       => sub { $cv->send(@_) },
        error_cb => sub { $cv->croak(@_) },
    });

    is_deeply $cv->recv, [ 'bar-uuid', 'baz-uuid' ],
        '... last name search returns the expected results';
}

remove_test_bucket($bucket);

done_testing;
