use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestApp;
    use Dancer2;

    get '/' => sub {
        session salute  => "Hello world!";
        template salute => {};
    };
}

my $test = Plack::Test->create( TestApp->to_app );
my $res = $test->request( GET '/' );
ok $res->is_success, "GET '/' successful";
like $res->content,  qr{Hello world}, "we got the session contents back";

done_testing;
