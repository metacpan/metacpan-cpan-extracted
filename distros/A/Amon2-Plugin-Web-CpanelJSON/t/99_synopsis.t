use strict;
use warnings;
use Test::More;
use Test::Requires qw(
    Amon2::Lite
);

{
    package MyApp;
    use Amon2::Lite;
    use Cpanel::JSON::XS::Type;
    use HTTP::Status qw(:constants);

    __PACKAGE__->load_plugins(qw/Web::CpanelJSON/);

    use constant HelloWorld => {
        message => JSON_TYPE_STRING,
    };

    get '/' => sub {
        my $c = shift;
        return $c->render_json(+{ message => 'HELLO!' }, HelloWorld, HTTP_OK);
    };
}

use Plack::Test;
use HTTP::Request::Common;

my $app = MyApp->to_app();
test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "/");

    is $res->code, 200;
    is $res->content, '{"message":"HELLO!"}';
};

done_testing;
