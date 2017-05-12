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
use File::Temp;

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

plan tests => 7;

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
            my $temp = File::Temp->new;
            my $res = $ua->get("http://localhost:$port/", ':content_file' => $temp->filename);
            ok $res->is_success, 'is_success';
            like $ua->cookie_jar->as_string, qr/test=abc/, '$ua->cookie_jar set';
            is $res->content, '', 'empty content';
            {
                local $/;
                open my $fh, '<', $temp;
                like <$fh>, qr{<p>blahblahblha</p>}, 'valid file';
                close $fh;
            }
        }
        {
            my $ua = $pkg->new(cookie_jar => {});
            my $temp = File::Temp->new;
            my $res = $ua->get("http://localhost:$port/error", ':content_file' => $temp->filename);
            ok !$res->is_success, '!is_success when error';
            is $res->content, '404 Not found', 'content when error';
            {
                local $/;
                open my $fh, '<', $temp;
                is <$fh>, '', 'file when error';
                close $fh;
            }
        }
    },
);
