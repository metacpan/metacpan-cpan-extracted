use strict;
use warnings;
BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
                         skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

use Test::More;
use Test::Exception;
use AnyEvent::Riak;

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};
sub _client {
    my $cv_c = AE::cv;
    my $client = AnyEvent::Riak->new( host => $host, port => $port,
      on_connect => sub { $cv_c->send }, on_connect_error => sub { $cv_c->croak($_[1]) } );
    $cv_c->recv;
    $client;
}


# plan tests => 4;

subtest "connection" => sub {
    plan tests => 1;
    ok(_client(), "client created");
};

subtest "put" => sub {
    plan tests => 1; my $c = _client();

    my $cv = AE::cv;
    $c->put({ bucket => '_test_bucket', key => 'bar', return_body => 1,
              content => { value => "plop", content_type => 'text/plain' } },
            sub { $cv->send($_[0]) } );
    my $res = $cv->recv();
    is($res->{content}->[0]->{value}, "plop");
};

subtest "get" => sub {
    plan tests => 1; my $c = _client();

    my $cv = AE::cv;
    $c->get({ bucket => '_test_bucket', key => 'bar' },
            sub { $cv->send($_[0]) } );
    my $res = $cv->recv();
    is($res->{content}->[0]->{value}, "plop");
};

subtest "get_bucket" => sub {
    plan tests => 1; my $c = _client();

    my $cv = AE::cv;
    $c->get_bucket({ bucket => 'bucket_name' },
                   sub { $cv->send($_[0]) } );
    my $res = $cv->recv();
    ok(defined $res->{props}->{basic_quorum});
};

subtest "set_bucket" => sub {
    plan tests => 1; my $c = _client();

    my $cv = AE::cv;
    $c->set_bucket({ bucket => '_test_bucket',
                     props => { r => 1 }
                   },
                   sub { $cv->send($_[0]) } );
    my $res = $cv->recv();
    is($res, 1);
};

subtest "reset_bucket" => sub {
    plan tests => 1; my $c = _client();

    my $cv = AE::cv;
    $c->reset_bucket({ bucket => '_test_bucket' },
                     sub { $cv->send($_[0]) } );
    my $res = $cv->recv();
    is($res, 1);
};

subtest "get_bucket_type" => sub {
    plan tests => 1; my $c = _client();

    my $cv = AE::cv;
    $c->get_bucket_type({ type => 'default' },
                     sub { $cv->send($_[0]) } );
    my $res = $cv->recv();
    ok(defined $res->{props}->{basic_quorum});
};

 #    print STDERR Dumper(\@_); use Data::Dumper;

    # print STDERR Dumper($res); use Data::Dumper;

done_testing;

# END {

#     diag "\ncleaning up...";
#     my $client = Riak::Client->new(
#         host => $host, port => $port,
#     );
#     my $another_client = Riak::Client->new(
#         host => $host, port => $port,
#     );

#     my $c = 0;
#     foreach my $bucket (@buckets_to_cleanup) {
#         $client->get_keys($bucket => sub{
#                               my $key = $_; # also in $_[0]
#                               # { local $| = 1; print "."; }
#                               $c++;
#                               $another_client->del($bucket => $key);
#                           });
#     }

#     diag "done (deleted $c keys).";

# }
