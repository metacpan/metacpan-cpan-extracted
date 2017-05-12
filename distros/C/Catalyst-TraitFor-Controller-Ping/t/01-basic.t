use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use Catalyst::Test('AppTest');

{
    my ($response, $c) = ctx_request('/ping');
    is($response->code, 200, 'default ping response code');

    $c->controller('Root')->_set_model_method('some_other_method');
}

{
    my ($response, $c) = ctx_request('/ping');
    is($response->code, 500, 'error out when model method dies');
    $c->controller('Root')->_clear_model_method();
}

{
    my ($response, $c) = ctx_request('/ping');
    is($response->code, 200, 'no model method');
    $c->controller('Root')->_clear_model_name();
}

{
    my ($response, $c) = ctx_request('/ping');
    is($response->code, 200, 'no model');
    $c->controller('Root')->_set_model_name('WTF');
}

{
    my ($response, $c) = ctx_request('/ping');
    is($response->code, 500, 'unknown model method');
}

done_testing();
