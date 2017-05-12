use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $ctx;
my $response;
ok((($response, $ctx) = ctx_request("/test_render?template=specified_template.tx&param=parameterized")), 'request ok');
is($response->content, "I should be a parameterized test in @{[TestApp->config->{name}]}", 'message ok');
my $view = $ctx->view('Xslate::Pkgconfig');
$view->content_charset('utf-8');
ok($view->xslate);
$view->suffix('.foo');
ok($view->xslate);
is($view->xslate->{'suffix'}, '.foo');
ok($ctx->view('Xslate::Appconfig')->xslate->{'verbose'} == 0, 'verbose is 0');
is($view->xslate->{'type'}, 'html');
is($ctx->view('Xslate::Appconfig')->xslate->{'type'}, 'text');

my $message = 'Dynamic message';

# ok(($response = request("/test_msg?msg=$message"))->is_success, 'request ok');
# is($response->content, "$message", 'message ok');

$response = request("/test_render?template=non_existant_template.xt");

is (403, $response->code, 'request returned error');
like($response->content, qr/Xslate: LoadError: Cannot find 'non_existant_template\.xt'/, 'Error from non-existant-template');

is(
  request('/test_expose_methods')->content,
  'hello abc world zzz def arg ok',
  'Got expect content for expose_methods test',
);

is(
  request('/test_expose_methods_coerced')->content,
  'hello abc world zzz def arg ok',
  'Got expect content for test_expose_methods_coerced test',
);

is
    request('/test_header_footer')->content,
    'header! content! footer!',
    'Got header/footer',
;

done_testing;
