use warnings;
use strict;
use lib 'lib', 't/lib';

use Test::More;
use Test::Deep;

use HTTP::Request::Common;
use Plack::Test;
use TestApp;

my @cases = (
    {
        name   => 'default config',
        expect =>
          superbagof('http_requests_total{code="200",method="GET"} 1'),
    },
    {
        name     => 'set endpoint in config',
        config   => { endpoint => '/testme' },
        endpoint => '/testme',
        expect   =>
          superbagof('http_requests_total{code="200",method="GET"} 1'),
    },
);

my $get_metrics = sub {
    my ( $test, $endpoint ) = @_;

    my $res = $test->request( GET "/metrics" );
    return [ grep { $_ !~ /^#/ } split /\n/, $res->content ];
};

my $app  = TestApp->psgi_app;
my $test = Plack::Test->create($app);

for my $case (@cases) {

    subtest $case->{name} => sub {
        TestApp->config->{'Plugin::PrometheusTiny'} = $case->{config}
          if $case->{config};
        TestApp->prometheus->clear;

        my $got = $get_metrics->( $test, $case->{endpoint} || '/metrics' );
        cmp_deeply $got, [], "We start with no metrics"
          or diag explain $got;

        ok my $res = $test->request( GET "/" ), "GET /";
        is $res->content, "Hello World", "... and content is as expected";

        $got = $get_metrics->( $test, $case->{endpoint} || '/metrics' );
        cmp_deeply $got, $case->{expect}, "... and metrics are as expected"
          or diag explain $got;
    };
}

done_testing;
