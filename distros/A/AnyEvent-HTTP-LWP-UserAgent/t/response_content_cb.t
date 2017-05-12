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

        if($cgi->url(-path_info=>1) =~ m,/error$,) {
            print "HTTP/1.0 404 Not found\r\n";
            print "Content-Type: text/plain\r\n";
            print "\r\n";
            print "404 Not found";
            return;
        }
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

plan tests => 12;

Test::TCP::test_tcp(
    server => sub {
        my $port = shift;
        my $server = HTTP::Server::Simple::Test->new($port);
        $server->run;
    },
    client => sub {
        my $port = shift;
        {
            my $ua = $pkg->new(cookie_jar => {});
            my $content = '';
            my $res = $ua->get("http://localhost:$port/", ':content_cb' => sub { $content .= $_[0] });
            ok $res->is_success, 'is_success';
            like $ua->cookie_jar->as_string, qr/test=abc/, '$ua->cookie_jar set';
            is $res->content, '', 'empty content';
            like $content, qr{<p>blahblahblha</p>}, 'valid callback';
        }
        {
            my $ua = $pkg->new(cookie_jar => {});
            my $res = $ua->get("http://localhost:$port/", ':content_cb' => sub { die 'Died by client'; });
            ok $res->is_success, 'is_success when client died';
            like $ua->cookie_jar->as_string, qr/test=abc/, '$ua->cookie_jar set when client died';
            is $res->content, '', 'empty content when client died';
            like $res->header('X-Died'), qr/Died by client/, 'X-Died: when client died';
            like $res->header('Client-Aborted'), qr/die/, 'Client-Aborted: when client died';
        }
        {
            my $ua = $pkg->new(cookie_jar => {});
            my $content = '';
            my $res = $ua->get("http://localhost:$port/error", ':content_cb' => sub { $content .= $_[0] });
            ok !$res->is_success, '!is_success when error';
            is $content, '', 'callback when error';
            is $res->content, '404 Not found', 'content when error';
        }
    },
);
