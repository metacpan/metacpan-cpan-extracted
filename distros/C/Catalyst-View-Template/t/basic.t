use strict; use warnings; use utf8;
use Test::More;

use lib 't/lib';

use Catalyst::Test 'MyApp';

plan tests => my $num_tests;

my $response;

BEGIN { $num_tests += 3 }
isa_ok my $tt = MyApp->view, 'Catalyst::View::Template', 'MyApp->view';
ok $tt->render( 'MyApp', 'test', { message => 'hello' }, \my $output ), 'render() succeeds';
is $output, 'hello', '... with the expected return value';

BEGIN { $num_tests += 3 }
ok $response = request( '/test_render?template=specified&param=parameterized' ), 'Parameter request';
ok $response->is_success, '... succeeds';
is $response->content, 'parameterized test in '.MyApp->config->{'name'}, '... with the expected content';

BEGIN { $num_tests += 3 }
my $message = 'Dynamic message';
ok $response = request( "/test_msg?msg=$message" ), 'Dynamic message request';
ok $response->is_success, '... succeeds';
is $response->content, $message, '... with the expected content';

BEGIN { $num_tests += 3 }
ok $response = request( '/test_render?template=non_existant_template' ), 'Request with non-existent template';;
is 403, $response->code, '... fails';
is $response->content, 'file error - non_existant_template.tt: not found', '... with the expected content';

my $have_encoding = MyApp->can('encoding') && MyApp->can('clear_encoding');

BEGIN { $num_tests += 4 }
SKIP: {
	skip 'No UTF-8 tests on older Catalyst', 4 unless $have_encoding;
	ok $response = request( '/♥' ), 'Unicode path request';
	is $response->code, 200, '... succeeds';
	is $response->content_charset, 'UTF-8', '... with the expected response charset';
	is $response->decoded_content, "<p>Heart literal ♥</p><p>Heart variable ♥♥♥</p>\n", '... and the expected body';
}

my @view;
BEGIN { $num_tests += 6 * ( @view = qw( PkgConfig AppConfig TemplateClass ) ) }
for my $view ( @view ) {
	ok $response = request( "/test?view=$view" ), "$view request";
	ok $response->is_success, '... succeeds';
	is $response->content, MyApp->config->{'default_message'}, '... with the expected content';

	my $message = scalar localtime;
	ok $response = request( "/test?view=$view&message=$message" ), "$view request with message";
	ok $response->is_success, '... succeeds';
	is $response->content, $message, '... with the expected content';
}

BEGIN { $num_tests += 3 }
ok $response = request( '/test_alt_content_type' ), 'Alternative content type request';
ok $response->is_success, '... succeeds';
my $encoding = $have_encoding && MyApp->encoding;
my $con_type = 'text/plain' . ( $encoding ? '; charset=' . $encoding->mime_name : '' );
my $descript = '... with the expected content type' . ( $encoding ? ' and charset' : '' );
is $response->header('Content-Type'), $con_type, $descript;

BEGIN { $num_tests += 3 }
ok $response = request( '/test_dynamic_path?view=DynamicPath' ), 'Dynamic path request with additional path';
ok $response->is_success, '... succeeds';
is $response->content, 'Hello from alt_root', '... with the expected content';

BEGIN { $num_tests += 3 }
ok $response = request( "/test?view=DynamicPath" ), 'Dynamic path request without additional path';
ok $response->is_success, '... succeeds';
is $response->content, MyApp->config->{'default_message'}, '... with the expected content';
