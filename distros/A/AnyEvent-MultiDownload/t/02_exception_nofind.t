use strict;
use Test::More;
use AnyEvent::MultiDownload;

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

        if($cgi->url(-path_info=>1) =~ m,/notfind$,) {
            print "HTTP/1.0 404 Not found\r\n";
            print "Content-Type: text/plain\r\n";
            print "\r\n";
            print "404 Not found";
            return;
        }
    }
}

Test::TCP::test_tcp(
    server => sub {
        my $port = shift;
        my $server = HTTP::Server::Simple::Test->new($port);
        $server->run;
    },
    client => sub {
        my $port = shift;
        {
            use AE;
            use AnyEvent::MultiDownload;
            my $path = '/tmp/multidownload.tmp';
             
            my $cv = AE::cv;
            my $MultiDown = AnyEvent::MultiDownload->new(
                url   => "http://localhost:$port/notfind",
                path  => "$path.1", 
                on_finish => sub {
                    my $len = shift;
                    $cv->send;
                },
                on_error => sub {
                    my ($error, $hdr) = @_;
                    is $error, 'Status: 404, Reason: Not found.', 'error info';
                    is $hdr->{Status}, 404, 'header 404'; 
                    $cv->send;
                }
            )->start;
            $cv->recv;

            unlink $path;
        }
    },
);

done_testing();
