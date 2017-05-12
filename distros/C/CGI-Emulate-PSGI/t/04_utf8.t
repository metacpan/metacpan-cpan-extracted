use strict;
use warnings;
use CGI;
use CGI::Emulate::PSGI;
use Test::More;

my $app = CGI::Emulate::PSGI->handler(
    sub {
        binmode STDOUT, ":utf8";
        print "Content-Type: text/html\r\n\r\n";
        print chr(4242);
    },
);

my $res = $app->({ REQUEST_METHOD => 'GET', 'psgi.input' => \*STDIN, 'psgi.errors' => \*STDERR });
is $res->[0], 200;
is_deeply $res->[2], [ "\xe1\x82\x92" ];

done_testing;

