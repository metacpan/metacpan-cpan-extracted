use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use JSON;

{
    package App;
    use Dancer2;
    set serializer => 'JSON';

    post '/namecheck.:format' => sub {
        my $post_params = params('body');
        return $post_params;
    };

}
{
    package RESTApp;
    use Dancer2;
    use Dancer2::Plugin::REST;

    prepare_serializer_for_format;

    post '/namecheck.:format' => sub {
        my $post_params = params('body');
        return $post_params;
    };

}
my $req = HTTP::Request->new(POST => "/namecheck.json");
$req->header("Content-Type"=>"application/json");
my $json='{"item":1,"type":"test"}';
$req->content($json);

subtest '$restapp', \&test_app, RESTApp->to_app;
subtest '$app',     \&test_app, App->to_app;

done_testing;

sub test_app {
    my $app = shift;

    is ref $app => 'CODE', 'Got app' ;

    my $test = Plack::Test->create($app);
    my $res=$test->request($req);
    is( $res->code, 200, '[POST: Check Name  ] ' );
    is_deeply( from_json( $res->content ), from_json($json), "Check If response JSON matches Input");
}


