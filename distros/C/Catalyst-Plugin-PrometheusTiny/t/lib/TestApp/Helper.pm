package TestApp::Helper;

use warnings;
use strict;

use Test::More;
use Test::Deep;

use HTTP::Request::Common;
use Plack::Test;
use TestApp;

sub get_metrics {
    my ( $test, $endpoint ) = @_;

    my $res = $test->request( GET $endpoint );
    return [ grep { $_ !~ /^#/ } split /\n/, $res->content ];
}

sub run {
    my ( $config, $endpoint, $expect ) = @_;

    TestApp->config( 'Plugin::PrometheusTiny' => $config );
    TestApp->setup;
    my $app  = TestApp->psgi_app;
    my $test = Plack::Test->create($app);

    my $got = get_metrics( $test, $endpoint );
    cmp_deeply $got, [], "We start with no metrics"
      or diag explain $got;

    ok my $res = $test->request( GET "/" ), "GET /";
    is $res->content, "Hello World", "... and content is as expected";

    $got = get_metrics( $test, $endpoint );
    cmp_deeply $got,
      $expect,
      "... and metrics are as expected"
      or diag explain $got;
}

1;
