use strict;
use Test::More;
use AnyEvent::HTTP::LWP::UserAgent;

BEGIN {
    eval q{ require Test::TCP } or plan skip_all => 'Could not require Test::TCP';
    eval q{ require HTTP::Server::Simple::CGI } or plan skip_all => 'Could not require HTTP::Server::Simple::CGI';
}

{
    package HTTP::Server::Simple::Test;
    our @ISA = 'HTTP::Server::Simple::CGI';

    sub print_banner { }

    sub handle_request {
        print "HTTP/1.0 200 OK\r\n";
        print "Content-Type: text/html\r\n";
        print "Set-Cookie: test=abc; path=/\r\n";
        print "\r\n";
        print <<__HTML__;
<html>
  <head>
    <title>Test Web Page</title>
    <base href="http://www.example.com/">
  </head>
  <body>
    <p>blahblahblha</p>
  </body>
</html>
__HTML__
    }
}

plan tests => 3;

Test::TCP::test_tcp(
    server => sub {
        my $port = shift;
        my $server = HTTP::Server::Simple::Test->new($port);
        $server->run;
    },
    client => sub {
        my $port = shift;
        my $ua = AnyEvent::HTTP::LWP::UserAgent->new(cookie_jar => {});
        my $res = $ua->get("http://localhost:$port/");
        ok $res->is_success;
        like $ua->cookie_jar->as_string, qr/test=abc/, '$ua->cookie_jar set';
        is $res->base, 'http://www.example.com/', '$res->base set';
    },
);
