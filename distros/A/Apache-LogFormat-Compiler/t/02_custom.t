use strict;
use warnings;
use HTTP::Request::Common;
require "./t/Req2PSGI.pm";
t::Req2PSGI->import();
use Test::More;
use Apache::LogFormat::Compiler;

{
    my $log_handler = Apache::LogFormat::Compiler->new(q!%{%S}t %{x-res-test}o %{x-req-test}i!);
    ok($log_handler);
    my $log = $log_handler->log_line(
        t::Req2PSGI::req_to_psgi(GET "/", 'X-Req-Test'=>'foo'),
        [200,['X-Res-Test'=>'bar'],[q!OK!]],
        2,
        1_000_000
    );
    like $log, qr!^\[\d{2}\] bar foo$!;
}

{
    my $log_handler = Apache::LogFormat::Compiler->new(q!%{Content-Length}i %{Content-Type}i %{Content-Type}o %{Content-Length}o!);
    ok($log_handler);
    my $log = $log_handler->log_line(
        t::Req2PSGI::req_to_psgi(POST "/", ["bar", "baz"]),
        [200,['Content-Type' => 'text/plain', 'Content-Length', 2 ],[q!OK!]],
        2,
        1_000_000
    );
    is $log, q!7 application/x-www-form-urlencoded text/plain 2!."\n";
}


done_testing();
