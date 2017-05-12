use strict;
use Test::More;
use Asset::File;
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

        if($cgi->url(-path_info=>1) =~ m,/error$,) {
            print "HTTP/1.0 404 Not found\r\n";
            print "Content-Type: text/plain\r\n";
            print "\r\n";
            print "404 Not found";
            return;
        }

        my $body = 
         "a" x 1024  . "b"  x 1024 .
         "c" x 1024  . "d"  x 1024 . 
         "e" x 1024  . "f"  x 1024 . 
         "g" x 1024  . "h"  x 1024;

        my %map = (
            'bytes=1024-2047' => "b" x 1024,
            'bytes=2048-3071' => "c" x 1024, 
            'bytes=3072-4095' => "d" x 1024,
            'bytes=4096-5119' => "e" x 1024,
            'bytes=5120-6143' => "f" x 1024,
            'bytes=6144-7167' => "g" x 1024,
            'bytes=7168-8191' => "h" x 1024,
        );
        my $len = length($body);
        my $range = $cgi->http('HTTP_RANGE');
        if ( !$range ) {
            print "HTTP/1.0 200 OK\r\n";
            print "Content-Type: application/octet-stream\r\n";
            print "Content-Length: ". $len . "\r\n";
            print "\r\n";
            print $body;
            print "\r\n";
        }
        else {
            if ( $map{$range} ) {
                $body = $map{$range};
                $range =~ s/=/ /g;
                print "HTTP/1.1 206 Partial Content\r\n";
                print "Content-Type: application/octet-stream\r\n";
                print "Content-Range: $range/$len\r\n";
                print "\r\n";
                print $body;
                print "\r\n"; 
            }
            else {
                print "HTTP/1.1 416 Requested Range Not Satisfiable\r\n";
                print "Content-Type: application/octet-stream\r\n";
                print "Content-Range: */$len\r\n";
                print "\r\n";
                print "\r\n"; 
            }

        }
    }
}

my @md5_list = ( 
    'c9a34cfc85d982698c6ac89f76071abd',
    'bbe6402cdc9b7e2036fc97e9a91726cd',
    '2363e5e6343a2f2afd1e0c733f2b10f4',
    '6451d26b2442429e7d9f7f472f6fae8d',
    'ced8f043d5a2d74811d2345f6324e06d',
    '6abe902730178d76716023af0b3202df',
    'a66182077e11ece2d75e7e1662c2a302',
    'abf9f630a4c28da131b81e8e5c3ceb37'
);

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
             
            unlink $path;
            my $cv = AE::cv;
            my $MultiDown = AnyEvent::MultiDownload->new(
                url   => "http://localhost:$port/",
                path  => $path, 
                digest => "Digest::MD5",
                block_size => 1 * 1024, # 1k
                on_block_finish => sub {
                    my ($hdr, $block_ref, $md5) = @_;
                    is $block_ref->{size}, 1024, "block size";
                    is $md5, $md5_list[$block_ref->{block}], $block_ref->{block} ." block md5";
                    $md5 eq $md5_list[$block_ref->{block}];
                },
                on_finish => sub {
                    my $len = shift;
                    is $len, 8192, "file length";
                    $cv->send;
                },
                on_error => sub {
                    my $error = shift;
                    $cv->send;
                }
            )->start;
            $cv->recv;

            ok -s $path, "file exist";
            my $asset = Asset::File->new(path => $path );
            is $asset->md5sum, 'a4f2b77f836d654db22c14bdbf603038', "file md5";
            unlink $path;
        }
    },
);

done_testing();
