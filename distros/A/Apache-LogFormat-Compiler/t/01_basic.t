use strict;
use warnings;
use HTTP::Request::Common;
require "./t/Req2PSGI.pm";
t::Req2PSGI->import();
use Test::More;
use Apache::LogFormat::Compiler;

{
    my $log_handler = Apache::LogFormat::Compiler->new();
    ok($log_handler);
    my $log = $log_handler->log_line(
        t::Req2PSGI::req_to_psgi(GET "/"),
        [200,[],[q!OK!]],
        2,
    );
    like $log, 
        qr!^[a-z0-9\.]+ - - \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\] "GET / HTTP/1\.1" 200 2 "-" "-"$!;
};

{
    my $log_handler = Apache::LogFormat::Compiler->new(
        '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i" %D'
    );
    ok($log_handler);
    my $log = $log_handler->log_line(
        t::Req2PSGI::req_to_psgi(GET "/"),
        [200,[],[q!OK!]],
        2,
    );
    like $log, 
        qr!^[a-z0-9\.]+ - - \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\] "GET / HTTP/1\.1" 200 2 "-" "-" -$!;
};


{
    my $log_handler = Apache::LogFormat::Compiler->new(
        '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i" %D %T'
    );
    ok($log_handler);
    my $log = $log_handler->log_line(
        t::Req2PSGI::req_to_psgi(GET "/"),
        [200,[],[q!OK!]],
        2,
        1_000_000,
        time()
    );
    like $log, 
        qr!^[a-z0-9\.]+ - - \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\] "GET / HTTP/1\.1" 200 2 "-" "-" 1000000 1$!;
};


{
    my $log_handler = Apache::LogFormat::Compiler->new(
        '%m %U %q %H'
    );
    ok($log_handler);
    my $log = $log_handler->log_line(
        t::Req2PSGI::req_to_psgi(GET "/foo?bar=baz"),
        [200,[],[q!OK!]],
        2,
        1_000_000,
        time()
    );
    like $log, 
        qr!^GET /foo \?bar=baz HTTP/1\.1$!
};


done_testing();

