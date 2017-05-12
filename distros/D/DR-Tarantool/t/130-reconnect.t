#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use constant PLAN => 17;

BEGIN {
    use Test::More;
    use DR::Tarantool::StartTest;

    unless (DR::Tarantool::StartTest::is_version('1.5.2', 1)) {

        plan skip_all => 'Incorrect tarantool version';
    } else {
        plan tests => PLAN;
    }
}




use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool::StartTest';
    use_ok 'DR::Tarantool::SyncClient';
    use_ok 'File::Spec::Functions';
    use_ok 'File::Basename', 'dirname';
    use_ok 'AnyEvent';
}

sub pause($) {
    my $t = shift;
    my $cv = AE::cv;
    my $tmr;
    $tmr = AE::timer $t, 0, sub {
        undef $tmr;
        $cv->send;
    };
    $cv->recv;
}

my $cfg_dir = catfile dirname(__FILE__), 'test-data';
ok -d $cfg_dir, 'directory with test data';
my $tcfg = catfile $cfg_dir, 'llc-easy2.cfg';
ok -r $tcfg, $tcfg;
my $tnt = run DR::Tarantool::StartTest( cfg => $tcfg );

ok $tnt->started, 'tarantool is started';


my $client = DR::Tarantool::SyncClient->connect(
    port    => $tnt->primary_port,
    spaces  => {}
);
my $client2 = DR::Tarantool::SyncClient->connect(
    port    => $tnt->primary_port,
    spaces  => {},
    reconnect_period    => .1,
    reconnect_always    => 1,
);

ok $client->ping, 'ping';
ok $client2->ping, 'client2->ping';
$tnt->kill(-9);
ok !$tnt->started, 'tarantool is not started';
ok !$client->ping, 'does not ping';
ok !$client->ping, 'does not ping';
ok !$client2->ping, 'does not client2->ping';
ok !$client2->ping, 'does not client2->ping';

$tnt->restart;
ok $tnt->started, 'tarantool  is started';

pause .3;
ok $client2->ping, 'does not client2->ping';
