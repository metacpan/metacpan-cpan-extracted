package Catalyst::Plugin::PrometheusTiny::Test;
use lib 'lib';
use Moose;
with 'Catalyst::Plugin::PrometheusTiny';

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);
sub setup_components { }
sub setup_finalize   { }
sub finalize         { }

package main;

use Test::More;

use Test::Deep;
use Scalar::Util qw(refaddr);

subtest 'Prometheus::Tiny object is cached as expected' => sub {
    ok my $obj = Catalyst::Plugin::PrometheusTiny::Test->new(),
      "we can create our dummy catalyst class";

    ok my $prometheus = $obj->prometheus,
      "... and we can call its prometheus method";

    isa_ok $prometheus, 'Prometheus::Tiny::Shared', 'prometheus';

    ok my $prometheus2 = $obj->prometheus,
      "call prometheus method a second time";

    is refaddr($prometheus2), refaddr($prometheus),
      "... and we have the same Prometheus::Tiny::Shared object";
};

subtest 'test config merging of metrics' => sub {
    ok my $obj = Catalyst::Plugin::PrometheusTiny::Test->new(
        config => {
            'Plugin::PrometheusTiny' => {
                metrics => {
                    http_request_size_bytes => { buckets => [42] },
                    frobnicate              => {
                        help => 'Testing 1, 2, 3',
                        type => 'counter',
                    },
                },
            }
        }
      ),
      "we can create our dummy catalyst class";

    $obj->_clear_prometheus;
    $obj->prometheus->histogram_observe( 'http_request_size_bytes', 50 );

    is $obj->prometheus->format, q{# HELP frobnicate Testing 1, 2, 3
# TYPE frobnicate counter
# HELP http_request_duration_seconds Request durations in seconds
# TYPE http_request_duration_seconds histogram
# HELP http_request_size_bytes Request sizes in bytes
# TYPE http_request_size_bytes histogram
http_request_size_bytes_bucket{le="42"} 0
http_request_size_bytes_bucket{le="+Inf"} 1
http_request_size_bytes_count 1
http_request_size_bytes_sum 50
# HELP http_requests_total Total number of http requests processed
# TYPE http_requests_total counter
# HELP http_response_size_bytes Response sizes in bytes
# TYPE http_response_size_bytes histogram
}, "... and prometheus->format shows that metrics have merged correctly";

};

done_testing;
