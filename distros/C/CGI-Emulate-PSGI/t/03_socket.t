use strict;
use warnings;
use CGI;
use CGI::Emulate::PSGI;
use IO::Socket::INET;
use Test::More;

my $handler = CGI::Emulate::PSGI->handler(
    sub {
        my $sock = IO::Socket::INET->new('localhost:34343');
        print "Content-Type: text/html\n\nHello";
    }
);

open my $input, "<", \"";
open my $errors, ">", \my $err;

for (1..2) {
    my $res = $handler->({
        'psgi.input'   => $input,
        REMOTE_ADDR    => '192.168.1.1',
        REQUEST_METHOD => 'GET',
        'psgi.errors'  => $errors,
    });

    is $res->[0], 200;
    is_deeply $res->[2], [ 'Hello' ];
}

done_testing;
