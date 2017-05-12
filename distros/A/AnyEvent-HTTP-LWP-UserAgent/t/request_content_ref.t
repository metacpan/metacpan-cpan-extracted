use strict;
use Test::More;
my $pkg;
BEGIN {
    if(exists $ENV{USE_LWP}) {
        require LWP::UserAgent;
        $pkg = 'LWP::UserAgent';
    } else {
        require AnyEvent::HTTP::LWP::UserAgent;
        $pkg = 'AnyEvent::HTTP::LWP::UserAgent';
    }
}

BEGIN {
    eval q{ require Test::TCP } or plan skip_all => 'Could not require Test::TCP';
    eval q{ require HTTP::Server::Simple::CGI } or plan skip_all => 'Could not require HTTP::Server::Simple::CGI';
}

{
    package HTTP::Server::Simple::Test;
    our @ISA = 'HTTP::Server::Simple::CGI';

    sub print_banner { }

    sub handle_request {
        my ($self, $cgi) = @_;
        my $data = $cgi->param('PUTDATA');
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
    <p>$data</p>
  </body>
</html>
__HTML__
    }
}

plan tests => 4;

Test::TCP::test_tcp(
    server => sub {
        my $port = shift;
        my $server = HTTP::Server::Simple::Test->new($port);
        $server->run;
    },
    client => sub {
        my $port = shift;
        my @content = ('This', ' ', 'is', ' ', 'content.', '');
        my $ua = $pkg->new(cookie_jar => {});
        # For AnyEvent::HTTP::LWP::UserAgent, even if Content-Length is not specified, chunked encoding is NOT used.
        # For LWP::UserAgent, if Content-Length is not specified, chunked encoding is used.
        my $req = HTTP::Request->new('PUT', "http://localhost:$port/", ['Content-Type' => 'text/plain', 'Content-Length' => 16], sub { return shift @content });
        my $res = $ua->request($req);
        ok $res->is_success;
        like $ua->cookie_jar->as_string, qr/test=abc/, '$ua->cookie_jar set';
        is $res->base, 'http://www.example.com/', '$res->base set';
        like($res->content, qr{<p>This is content\.</p>}, 'content');
    },
);
