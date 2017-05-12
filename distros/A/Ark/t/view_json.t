use strict;
use warnings;
use Test::Requires 'JSON';
use Test::More;
use FindBin;

{
    package TestApp;
    use Ark;

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub no_status :Local {
        my ($self, $c) = @_;

        $c->stash->{json}{test} = 1;
        $c->forward( $c->view('JSON') );
    }

    sub has_status :Local {
        my ($self, $c) = @_;

        $c->stash->{json}{status} = 200;
        $c->stash->{json}{test}   = 1;

        $c->forward( $c->view('JSON') );
    }


    package TestApp::View::JSON;
    use Ark 'View::JSON';

    has "+expose_stash" => (default => "json");
    has "+status_code_field" => (default => "status");
}


use Ark::Test 'TestApp',
    components => [qw/Controller::Root View::JSON/];

my $decoder = JSON->new;

{
    my ($res, $c) = ctx_request(GET => '/no_status');
    my $json = $decoder->decode($res->content);

    is_deeply $json, {test => 1};
    ok !$c->res->header("X-JSON-Status");
}

{
    my ($res, $c) = ctx_request(GET => '/has_status');
    my $json = $decoder->decode($res->content);

    is_deeply $json, {test => 1, status => 200};
    is $c->res->header("X-API-Status"), 200;
}

done_testing;
