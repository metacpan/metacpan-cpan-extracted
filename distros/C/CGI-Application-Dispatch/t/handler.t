use strict;
use warnings;
use Test::More;

my $COUNT;
BEGIN { $COUNT = 0 };

eval { require Apache::Test };
if($@) {
    plan(skip_all => 'Apache::Test is not installed');
} else {
    require Apache::Test;
    require Apache::TestRequest;
    Apache::Test->import(qw(have_lwp need_module :withtestmore));
    Apache::TestRequest->import(qw(GET POST));
    plan(tests => $COUNT, need_module('Apache::TestMB'), have_lwp());
}

my $response;
my $content;

BEGIN { $COUNT += 2 }

# PATH_INFO is translated correctly
{
    $response = GET('/app1/module_name/rm1');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'Module::Name->rm1', 'PATH_INFO translated');
}

BEGIN { $COUNT += 2 }

# prefix is added correctly
{
    $response = GET('/app2/module_name/rm1');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm1', 'prefix added');
}

BEGIN { $COUNT += 2 }

# grab the RM correctly from the PATH_INFO
{
    $response = GET('/app2/module_name/rm2');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm2', 'extract RM form PATH_INFO');
}

BEGIN { $COUNT += 4 }

# CGIAPP_DISPATCH_DEFAULT is used correctly
{

    # no extra path
    $response = GET('/app3');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm2');

    # only a '/' as the path_info
    $response = GET('/app3/');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm2', 'CGIAPP_DISPATCH_DEFAULT used');
}

BEGIN { $COUNT += 2 }

# override translate_module_name()
{
    $response = GET('/app4/something_strange');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm1', 'override translate_module_name()');
}

BEGIN { $COUNT += 8 }

# cause errors
{

    # non existant module
    $response = GET('/app2/asdf/rm1');
    ok($response->is_error);
    cmp_ok($response->code, 'eq', '404', 'not found - no module');

    # poorly written module
    $response = GET('/app2/module_bad/rm1');
    ok($response->is_error);
    cmp_ok($response->code, 'eq', '500', 'server error: module doesnt compile');

    # non existant run mode
    $response = GET('/app2/module_name/rm6');
    ok($response->is_error);
    cmp_ok($response->code, 'eq', '404', 'not found: no run mode');

    # invalid characters
    $response = GET('/app2/module;_bad');
    ok($response->is_error);
    cmp_ok($response->code, 'eq', '400', 'server error: invalid characters');
}

BEGIN { $COUNT += 27 }

# dispatch table via a subclass
{
    $response = GET('/app5/module_name');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm1', 'matched :app');
    contains_string($content, 'hum=electra_200');

    $response = GET('/app5/module_name/rm2');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm2', 'matched :app/:rm');
    contains_string($content, 'hum=electra_200');

    $response = GET('/app5/module_name/rm3/stuff');
    ok($response->is_success);
    $content = $response->content;
    contains_string(
        $content,
        'MyApp::Module::Name->rm3 my_param=stuff',
        'matched :app/:rm/:my_param'
    );
    contains_string($content, 'hum=electra_200');

    $response = GET('/app5/module_name/bar/stuff');
    ok($response->is_success);
    $content = $response->content;
    contains_string(
        $content,
        'MyApp::Module::Name->rm3 my_param=stuff',
        'matched :app/bar/:my_param'
    );
    contains_string($content, 'hum=electra_200');

    $response = GET('/app5/foo/bar');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm2', 'matched foo/bar');
    contains_string($content, 'hum=electra_200');

    $response = GET('/app5/module_name/foo');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm3 my_param=', 'missing optional');
    contains_string($content, 'hum=electra_200');

    $response = GET('/app5/module_name/foo/weird%20stuff');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm3 my_param=weird stuff', 'present optional');
    contains_string($content, 'hum=electra_200');

    $response = GET('/app5');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm1', 'empty default');
    contains_string($content, 'hum=electra_200');

    $response = GET('/app5/');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Name->rm1', 'empty default');
    contains_string($content, 'hum=electra_200');
}

BEGIN { $COUNT += 14 }

# http method dispatching
{
    $response = GET('/http_method/module_rest/rm1');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Rest->rm1_GET', 'auto_rest GET');

    $response = POST('/http_method/module_rest/rm1');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Rest->rm1_POST', 'auto_rest POST');

    $response = POST('/http_method/module_rest/rm2');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Rest->rm2_post', 'auto_rest_lc POST');

    $response = GET('/http_method/module_rest/rm3');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Rest->get_rm3', 'HTTP method in rule');

    $response = GET('/http_method/module_rest/rm4');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Rest->rm4', 'non-auto_rest GET');
    lacks_string($content, 'MyApp::Module::Rest->rm4_GET', 'non-auto_rest GET');

    $response = POST('/http_method/module_rest/rm4');
    ok($response->is_success);
    $content = $response->content;
    contains_string($content, 'MyApp::Module::Rest->rm4', 'non-auto_rest POST');
    lacks_string($content, 'MyApp::Module::Rest->rm4_POST', 'non-auto_rest POST');
}

sub contains_string {
    my ($str, $substr, $diag) = @_;
    if(index($str, $substr) != -1) {
        ok(1);
    } else {
        ok(0);
    }
}

sub lacks_string {
    my ($str, $substr, $diag) = @_;
    if(index($str, $substr) != -1) {
        ok(0);
    } else {
        ok(1);
    }
}
