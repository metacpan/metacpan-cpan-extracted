use strict;
use warnings;
use HTTP::Request::Common;
require "./t/Req2PSGI.pm";
t::Req2PSGI->import();
use Test::More;
use Apache::LogFormat::Compiler;

{
    my $log_handler = Apache::LogFormat::Compiler->new(
        q!%z %{HTTP_X_FORWARDED_FOR|REMOTE_ADDR}Z!,
        char_handlers => +{
            'z' => sub {
                my ($env,$req) = @_;
                ok($env);
                ok($req);
                return $env->{HTTP_X_REQ_TEST};
            },
        },
        block_handlers => +{
            'Z' => sub {
                my ($block,$env,$req) = @_;
                is($block, 'HTTP_X_FORWARDED_FOR|REMOTE_ADDR');
                ok($env);
                ok($req);
                return $block;
            },
        },
    );
    ok($log_handler);
    my $log = $log_handler->log_line(
        t::Req2PSGI::req_to_psgi(GET "/", 'X-Req-Test'=>'foo'),
        [200,['X-Res-Test'=>'bar'],[q!OK!]],
        2,
        1_000_000
    );
    is $log, q!foo HTTP_X_FORWARDED_FOR|REMOTE_ADDR!."\n";
}

done_testing();


