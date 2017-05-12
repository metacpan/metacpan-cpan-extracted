#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 45;
use Encode qw(decode encode);


my $temp_dir;

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'Coro::Twiggy';
    use_ok 'File::Temp', 'tempdir';
    use_ok 'File::Path', 'rmtree';
    use_ok 'File::Spec::Functions', 'catfile';
    use_ok 'Coro';
    use_ok 'Coro::AnyEvent';
    use_ok 'Coro::Handle';
    use_ok 'AnyEvent::Socket';
    use_ok 'AnyEvent';


}

$temp_dir = tempdir;
ok -d $temp_dir, "-d $temp_dir";
my $socket = catfile $temp_dir, 'socket';

{
my $server = Coro::Twiggy->new(host => 'unix/', port => $socket);
isa_ok $server => 'Coro::Twiggy';

for( 1 .. 10 ) {
    Coro::AnyEvent::sleep 0.1;
    last if -S $socket;
}

ok -S $socket, "-S $socket - socket was opened";


tcp_connect 'unix/', $socket, Coro::rouse_cb;
my $cs = unblock +(Coro::rouse_wait)[0];
ok $cs, 'connected to server';
print $cs "GET / HTTP/1.0\015\012\015\12";
my $resp;
{ local $/; $resp = <$cs> }
ok $resp, "response";
like $resp, qr{^HTTP/1\.[01]\s+503}, 'code';
like $resp, qr{no registered PSGI service}, 'message';

my $env;
$server->register_service(sub { ($env) = @_; });

tcp_connect 'unix/', $socket, Coro::rouse_cb;
$cs = unblock +(Coro::rouse_wait)[0];
ok $cs, 'connected to server';
print $cs "GET / HTTP/1.0\015\012\015\12";
{ local $/; $resp = <$cs> }
ok $resp, "response";
like $resp, qr{^HTTP/1\.[01]\s+500}, 'code';
like $resp, qr{application have to return an ARRAYREF}, 'message';
ok $env, 'PSGI application was called';

$env = undef;
$server->register_service(sub { ($env) = @_; ['abc'] });
tcp_connect 'unix/', $socket, Coro::rouse_cb;
$cs = unblock +(Coro::rouse_wait)[0];
ok $cs, 'connected to server';
print $cs "GET / HTTP/1.0\015\012\015\12";
{ local $/; $resp = <$cs> }
ok $resp, "response";
like $resp, qr{^HTTP/1\.[01]\s+500}, 'code';
like $resp, qr{wrong response}, 'message';
ok $env, 'PSGI application was called';

$env = undef;
$server->register_service(sub {
    ($env) = @_;
    [200, ['Content-Type', 'text/plain'], ['test passed']]
});
tcp_connect 'unix/', $socket, Coro::rouse_cb;
$cs = unblock +(Coro::rouse_wait)[0];
ok $cs, 'connected to server';
print $cs "GET / HTTP/1.0\015\012\015\12";
{ local $/; $resp = <$cs> }
ok $resp, "response";
like $resp, qr{^HTTP/1\.[01]\s+200}, 'code';
like $resp, qr{test passed}, 'message';
ok $env, 'PSGI application was called';

my $started = AnyEvent::now();
$env = undef;
$server->register_service(sub {
    ($env) = @_;
    Coro::AnyEvent::sleep .5;
    [200, ['Content-Type', 'text/plain'], ['test passed']]
});
tcp_connect 'unix/', $socket, Coro::rouse_cb;
$cs = unblock +(Coro::rouse_wait)[0];
ok $cs, 'connected to server';
print $cs "GET / HTTP/1.0\015\012\015\12";
{ local $/; $resp = <$cs> }
ok $resp, "response";
like $resp, qr{^HTTP/1\.[01]\s+200}, 'code';
like $resp, qr{test passed}, 'message';
ok $env, 'PSGI application was called';
my $delay = AnyEvent::now() - $started;
cmp_ok $delay, '>=', 0.5, 'async process took more that 0.5 seconds';


$server->register_service(sub { die "привет" });
tcp_connect 'unix/', $socket, Coro::rouse_cb;
$cs = unblock +(Coro::rouse_wait)[0];
ok $cs, 'connected to server';
print $cs "GET / HTTP/1.0\015\012\015\12";
{ local $/; $resp = <$cs> }
ok $resp, "response";
ok eval { utf8::decode $resp }, 'response was decoded';
like $resp, qr{^HTTP/1\.[01]\s+500}, 'code';
like $resp, qr{привет at}, 'message';
ok $env, 'PSGI application was called';

}

Coro::AnyEvent::sleep 0.5;

my ($resp, $env);
tcp_connect 'unix/', $socket, Coro::rouse_cb;
my $cs = Coro::rouse_wait;
ok !$cs, 'Socket was closed';

END {
    if ($temp_dir) {
        rmtree $temp_dir;
        ok !-d $temp_dir, "!-d $temp_dir";
    }
}
