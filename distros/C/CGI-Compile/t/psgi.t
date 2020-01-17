use Test::More;
use CGI::Compile;
use CGI;
use Test::Requires qw(CGI::Emulate::PSGI Plack::Test HTTP::Request::Common);

use CGI::Emulate::PSGI;
use Plack::Test;
use HTTP::Request::Common;

my $sub = CGI::Compile->compile("t/hello.cgi");
my $app = CGI::Emulate::PSGI->handler($sub);

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/?name=foo");
    is $res->content, "Hello foo counter=1";

    $res = $cb->(GET "http://localhost/?name=bar");
    is $res->content, "Hello bar counter=2";
};


done_testing;
