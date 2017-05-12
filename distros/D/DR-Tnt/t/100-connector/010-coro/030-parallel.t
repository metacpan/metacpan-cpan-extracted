#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib t/lib);

use Test::More tests    => 12;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::Client::Coro';
    use_ok 'DR::Tnt::Test';
    tarantool_version_check(1.6);
    use_ok 'Coro';
    use_ok 'AnyEvent';
    use_ok 'Coro::AnyEvent';
}


my $ti = start_tarantool
    -lua    => 't/100-connector/lua/easy.lua';
isa_ok $ti => DR::Tnt::Test::TntInstance::, 'tarantool';

diag $ti->log unless
    ok $ti->is_started, 'test tarantool started';

sub LOGGER {
    my ($level, $message) = @_;
    return unless $ENV{DEBUG};
    my $now = POSIX::strftime '%F %T', localtime;
    note "$now [$level] $message";
}

my $c = DR::Tnt::Client::Coro->new(
    host            => 'localhost',
    port            => $ti->port,
    user            => 'testrwe',
    password        => 'test',
    logger          => \&LOGGER,
    hashify_tuples  => 1,
);
isa_ok $c => DR::Tnt::Client::Coro::, 'connector created';
for (+note 'ping') {
    is $c->ping, 1, 'ping';
}

my @f;

my %done;

my $started = AnyEvent::now();

push @f => (async{ $c->call_lua(sleep => 1); $done{shift()} = 1; } 1);

for (2 .. 500) {
    push @f => (async{ $c->call_lua(sleep => rand .2); $done{shift()} = 1; } $_);
}
Coro::AnyEvent::sleep 0.1;

push @f => (async{ $c->call_lua(sleep => 1); $done{shift()} = 1; } 501);

for (502 .. 1000) {
    push @f => (async{ $c->call_lua(sleep => rand .2); $done{shift()} = 1; } $_);
}
$_->join for @f;
is_deeply \%done => { map { ($_, 1) } 1 .. 1000 }, 'done hash';

my $time = AnyEvent::now()- $started;
cmp_ok $time, '>=', 1, 'more than 1 sec total';
cmp_ok $time, '<=', 1.2, 'less than 1.5 sec total';
