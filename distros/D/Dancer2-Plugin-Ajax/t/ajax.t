use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common qw<GET POST DELETE PUT>;

{
    package AjaxApp;
    use Dancer2;
    use Dancer2::Plugin::Ajax;

    set plugins => { 'Ajax' => { content_type => 'application/json' } };

    ajax '/test' => sub {
        "{some: 'json'}";
    };

    get '/test' => sub {
        "some text";
    };

    ajax '/another/test' => sub {
        "{more: 'json'}";
    };

    ajax ['put', 'delete', 'get'] => "/more/test" => sub {
        "{some: 'json'}";
    };
}

my $test = Plack::Test->create( AjaxApp->to_app );

subtest 'Ajax with POST' => sub {
    my $res = $test->request(
        POST '/test',
            'X-Requested-With' => 'XMLHttpRequest'
    );

    is( $res->content, q({some: 'json'}), 'ajax works with POST' );
    is( $res->content_type, 'application/json', 'ajax content type' );
};

is(
    $test->request( GET '/test', 'X-Requested-With' => 'XMLHttpRequest' )
         ->content,
    q({some: 'json'}),
    'ajax works with GET',
);

is(
    $test->request(
        GET '/more/test',
            'X-Requested-With' => 'XMLHttpRequest',
    )->content,
    q({some: 'json'}),
    'ajax works with GET on multi-method route',
);

is(
    $test->request(
        PUT '/more/test',
            'X-Requested-With' => 'XMLHttpRequest'
    )->content,
    q({some: 'json'}),
    'ajax works with PUT on multi-method route',
);

is(
    $test->request(
        DELETE '/more/test',
            'X-Requested-With' => 'XMLHttpRequest'
    )->content,
    q({some: 'json'}),
    'ajax works with DELETE on multi-method route',
);

is(
    $test->request(
        POST '/more/test',
            'X-Requested-With' => 'XMLHttpRequest'
    )->code,
    404,
    'ajax multi-method route only valid for the defined routes',
);

is(
    $test->request( POST '/another/test' )->code,
    404,
    'ajax route passed for non-XMLHttpRequest',
);

    # GitHub #143 - response content type not munged if ajax route passes
subtest 'GH #143: response content with ajax route' => sub {
    my $res = $test->request( GET '/test' );
    is $res->code, 200, 'ajax route passed for non-XMLHttpRequest';
    is $res->content, 'some text', 'ajax route has proper content for GET without XHR';
    is $res->content_type, 'text/html', 'content type on non-XMLHttpRequest not munged';
};

done_testing;
