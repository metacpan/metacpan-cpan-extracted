use Test::More import => ['!pass'];
use strict;
use warnings;

plan skip_all => 'LWP::UserAgent is needed to run this test'
  unless Dancer::ModuleLoader->load('LWP::UserAgent');
plan skip_all => 'Plack::Middleware::ConsoleLogger is needed to run this test'
  unless Dancer::ModuleLoader->load('Plack::Middleware::ConsoleLogger');

use Plack::Loader;
use Plack::Builder;
use Test::TCP;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $ua   = LWP::UserAgent->new;

        my $request = HTTP::Request->new(GET => "http://127.0.0.1:$port/");
        my $res = $ua->request($request);
        ok($res->is_success, "server responded");
        like($res->content, qr/this is a warning/, "log message send");
    },
    server => sub {
        my $port = shift;

        use Dancer ':syntax';

        setting apphandler => 'PSGI';
        setting port       => $port;
        setting access_log => 0;
        setting logger     => "PSGI";

        get '/' => sub {
            warning "this is a warning";
            return "<html><body>this is a test</body></html>";
        };

        my $app = sub {
            my $env     = shift;
            my $request = Dancer::Request->new(env => $env);
            Dancer->dance($request);
        };
        $app = builder { enable "ConsoleLogger"; $app };
        Plack::Loader->auto(port => $port)->run($app);
    },
);

done_testing;
