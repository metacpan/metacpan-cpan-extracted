use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);
use Mojo::Server::PSGI;

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');
my $psgi = Mojo::Server::PSGI->new(app => $t->app)->to_psgi_app;

for my $case (['/app/doc','/doc',200], ['/app/(','/(',404]) {
    my ($uri,$path,$status) = @$case;
    open my $in, '<', \'';
    my $res = $psgi->({
        REQUEST_METHOD => 'GET', SCRIPT_NAME => '/app',
        REQUEST_URI => $uri, PATH_INFO => $path, QUERY_STRING => '',
        SERVER_NAME => 'localhost', SERVER_PORT => 80, HTTP_HOST => 'localhost',
        SERVER_PROTOCOL => 'HTTP/1.1', 'psgi.url_scheme' => 'http',
        'psgi.input' => $in, 'psgi.errors' => \*STDERR,
    });
    is $res->[0], $status, "GET $uri under PSGI returns $status";
}

done_testing();
