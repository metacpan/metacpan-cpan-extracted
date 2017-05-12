use strict;
use Test::More;
use AnyEvent::HTTP::LWP::UserAgent;
use AnyEvent;

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

        if($cgi->url(-path_info=>1) =~ m,/redirected$,) {

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
        } else {
            print "HTTP/1.0 301 Moved Permanently\r\n";
            print "Location: ",$cgi->url(-path_info=>1),"redirected\r\n";
            print "\r\n";
            print <<__HTML__;
<html>
  <head>
    <title>Test Web Page</title>
  </head>
  <body>
    <a href="/redirected">Redirected to</p>
  </body>
</html>
__HTML__
        }
    }
}

plan tests => 14;

my $cv = AE::cv;
my %tests = (
	DELETE => 'AnyEvent::HTTP::LWP::UserAgent::delete_async',
	GET    => 'AnyEvent::HTTP::LWP::UserAgent::get_async',
	HEAD   => 'AnyEvent::HTTP::LWP::UserAgent::head_async',
	POST   => 'AnyEvent::HTTP::LWP::UserAgent::post_async',
	PUT    => 'AnyEvent::HTTP::LWP::UserAgent::put_async',
);

Test::TCP::test_tcp(
    server => sub {
        my $port = shift;
        my $server = HTTP::Server::Simple::Test->new($port);
        $server->run;
    },
    client => sub {
        my $port = shift;

        $cv->begin;
        for my $test (keys %tests) {
# We do not share $ua because of cookie_jar separation
            my $ua = AnyEvent::HTTP::LWP::UserAgent->new(cookie_jar => {});
            $ua->requests_redirectable([$test]);

            $cv->begin;
            my $method = $tests{$test};
            $ua->$method("http://localhost:$port/")->cb(sub {
                my $res = shift->recv;
                ok $res->is_success;
                like $ua->cookie_jar->as_string, qr/test=abc/, $test . ': $ua->cookie_jar set';
                is $res->base, 'http://www.example.com/', $test . ': $res->base set' if $test ne 'HEAD';
                $cv->end;
            });
        }
        $cv->end;

        $cv->recv;
    },
);
