#!/usr/bin/env perl

use warnings;
use strict;

BEGIN {
    $ENV{API_MIKROTIK_CONNTIMEOUT} = 0.5;
    $ENV{MOJO_NO_TLS}              = 1;
}

use FindBin;
use lib './';
use lib "$FindBin::Bin/lib";

use API::MikroTik;
use API::MikroTik::Mockup;
use Mojo::IOLoop;
use Test::More;

plan skip_all => 'Mojolicious v7.54+ required for this test.'
    unless API::MikroTik->PROMISES;

my $mockup = API::MikroTik::Mockup->new();
my $port   = Mojo::IOLoop->acceptor($mockup->server)->port;
my $api    = API::MikroTik->new(
    user     => 'test',
    password => 'tset',
    host     => '127.0.0.1',
    port     => $port,
    tls      => 1,
);

my $p = $api->cmd_p('/resp');
isa_ok $p, 'Mojo::Promise', 'right result type';

# connection errors
my ($err, $res);
$p->catch(sub { ($err, $res) = @_ })->finally(sub { Mojo::IOLoop->stop() });
Mojo::IOLoop->start();
like $err, qr/IO::Socket::SSL/, 'connection error';
ok !$res, 'no error attributes';
$api->tls(0);

# error
$api->cmd_p('/err')->catch(sub { ($err, $res) = @_ })
    ->finally(sub { Mojo::IOLoop->stop() });
Mojo::IOLoop->start();
is $err, 'random error', 'right error';
is_deeply $res, [{message => 'random error', category => 0}],
    'right error attributes';

# request
$api->cmd_p('/resp')->then(sub { $res = $_[0] })
    ->finally(sub { Mojo::IOLoop->stop() });
Mojo::IOLoop->start();
is_deeply $res, _gen_result(), 'right result';

done_testing();

sub _gen_result {
    my $attr = API::MikroTik::Mockup::_gen_attr(@_);
    return [$attr, $attr];
}

