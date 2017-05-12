#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

my $LE = $] > 5.01 ? '<' : '';

use constant PLAN       => 17;
use Test::More;
BEGIN {
    use Test::More;
    use DR::Tarantool::StartTest;

    unless (DR::Tarantool::StartTest::is_version('1.5.2')) {

        plan skip_all => 'Incorrect tarantool version';
    } else {
        eval "use Coro";
        plan skip_all => "Coro isn't installed" if $@;
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
    use_ok 'DR::Tarantool', ':constant';
    use_ok 'DR::Tarantool::CoroClient';
    use_ok 'File::Spec::Functions', 'catfile';
    use_ok 'File::Basename', 'dirname', 'basename';
    use_ok 'Coro';
    use_ok 'AnyEvent';
    use_ok 'Coro::AnyEvent';
}

my $cfg_dir = catfile dirname(__FILE__), 'test-data';
ok -d $cfg_dir, 'directory with test data';
my $tcfg = catfile $cfg_dir, 'llc-easy2.cfg';
ok -r $tcfg, $tcfg;

my $tnt = run DR::Tarantool::StartTest( cfg => $tcfg );

SKIP: {

    skip "tarantool isn't installed", PLAN - 10 unless $tnt->started;

    my $c1 = DR::Tarantool::CoroClient->connect(
        port => $tnt->primary_port, spaces => {}
    );
    my $c2 = DR::Tarantool::CoroClient->connect(
        port => $tnt->primary_port, spaces => {}
    );

    ok $c1->ping, 'ping';
    ok $c2->ping, 'ping';


    my $sid1 =
        $c1->call_lua(
            'box.dostring', [ 'return tostring(box.session.id())' ]
        )->raw(0);
    my $sid2 =
        $c1->call_lua(
            'box.dostring', [ 'return tostring(box.session.id())' ]
        )->raw(0);
    my $sid3 =
        $c2->call_lua(
            'box.dostring', [ 'return tostring(box.session.id())' ]
        )->raw(0);
    my $sid4 =
        $c2->call_lua(
            'box.dostring', [ 'return tostring(box.session.id())' ]
        )->raw(0);
    is $sid1, $sid2, 'sids are equal';
    is $sid3, $sid4, 'sids are equal';
    isnt $sid1, $sid3, 'sids are not equal';


    $c1->call_lua('box.dostring',
    [
        q[
            sessions = {}
            box.session.on_disconnect(
                function()
                    table.insert(sessions, tostring(box.session.id()))
                end
            )
        ]
    ]
    );

    $c2->_llc->disconnect;
    $c2->_llc->connect;
    Coro::AnyEvent::sleep 0.5;

    my $dsid = $c1->call_lua('box.dostring', [ 'return sessions' ])->raw(0);
    is $sid3, $dsid, 'disconnect sid';
    isnt $sid1, $dsid, 'disconnect sid';

}
