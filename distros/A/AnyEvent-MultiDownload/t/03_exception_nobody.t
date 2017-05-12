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
                url   => "http://localhost:$port/timeout",
                path  => "$path", 
                timeout => 1,
                retry_interval => 1,
                max_retries => 1,
                on_finish => sub {
                    my $len = shift;
                    $cv->send;
                },
                on_error => sub {
                    my ($error, $hdr) = @_;
                    is $hdr->{Status}, 596, 'no body'; 
                    $cv->send;
                }
            )->start;
            $cv->recv;

            unlink $path;
        }
    },
);

done_testing();
