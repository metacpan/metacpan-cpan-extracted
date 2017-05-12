use strict;
use warnings;
use CGI;
use CGI::Emulate::PSGI;
use Test::More;

my $handler = CGI::Emulate::PSGI->handler(
    sub {
        ok ! exists $ENV{HTTP_PROXY};
        print "Content-Type: text/html; charset=utf-8\r\n";
        print "Content-Length: 4\r\n";
        print "\r\n";
        print "KTKR";
    }
);

my $input = "";
open my $in, '<', \$input;
open my $errors, '>', \my $err;
my $res = $handler->(
    +{
        'psgi.input'   => $in,
        REMOTE_ADDR    => '192.168.1.1',
        REQUEST_METHOD => 'GET',
        HTTP_PROXY     => 'localhost:3128',
        'psgi.errors'  => $errors,
    }
);


is $res->[0], 200;
my $headers = +{@{$res->[1]}};


done_testing;

