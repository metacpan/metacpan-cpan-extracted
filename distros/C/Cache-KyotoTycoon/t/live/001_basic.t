use strict;
use warnings;
use Test::More;
use Cache::KyotoTycoon;
use t::Util;
use Data::Dumper;

test_kt(
    sub {
        my $port = shift;
        my $kt = Cache::KyotoTycoon->new(port => $port);
        subtest 'set, get, remove' => sub {
            is $kt->get("test"), undef, 'not found';
            $kt->set("test", 'ok', 60);
            is $kt->get("test"), "ok";
            my ($v, $xt) = $kt->get("test");
            is $v, 'ok';
            ok defined($xt), 'xt is defined value';
            cmp_ok abs($xt-time()-60), '<', 5;
            is $kt->remove("test", 'ok'), 1;
            is $kt->get("test"), undef;
            is $kt->remove("test", 'ok'), 0;
        };
        subtest 'binary' => sub {
            is $kt->get("te\x00st"), undef, 'not found';
            $kt->set("te\x00st", "o\x015\x00k");
            is $kt->get("te\x00st"), "o\x015\x00k";
        };
        subtest 'add' => sub {
            is $kt->add("add_t1", 'ok'), 1;
            is $kt->get("add_t1"), "ok";
            is $kt->add("add_t1", 'ng'), 0;
            is $kt->get("add_t1"), "ok";
        };
        subtest 'replace' => sub {
            is $kt->replace("rep_t1", 'ok'), 0;
            is $kt->get("rep_t1"), undef;
            $kt->set("rep_t1", 'ng');
            is $kt->replace("rep_t1", 'ok'), 1;
            is $kt->get("rep_t1"), 'ok';
        };
        subtest 'append' => sub {
            $kt->append("app_t1", 'o1');
            is $kt->get("app_t1"), 'o1';
            $kt->append("app_t1", 'o2');
            is $kt->get("app_t1"), 'o1o2';
        };
        subtest 'increment' => sub {
            is $kt->increment('inc_t1', "25"), 25;
            is $kt->increment('inc_t1', "11"), 36;
            is 0+$kt->increment_double('inc_t2', "2.5"), 2.5;
            is 0+$kt->increment_double('inc_t2', "1.1"), 3.6;
        };
        subtest 'cas' => sub {
            is $kt->cas('cas_t1', "a", "b"), 0;
            is $kt->cas('cas_t1', undef, "b"), 1;
            is $kt->cas('cas_t1', "a", "b"), 0;
            is $kt->cas('cas_t1', undef, "c"), 0;
            is $kt->cas('cas_t1', "b", "c"), 1;
            is $kt->cas('cas_t1', "b", undef), 0;
            is $kt->cas('cas_t1', "c", undef), 1;
            is $kt->get('cas_t1'), undef, 'removed';
        };
        subtest 'match' => sub {
            is scalar keys %{$kt->match_prefix('inc')}, 2;
            is scalar keys %{$kt->match_regex('^inc', 1)}, 1;
            is scalar keys %{$kt->match_similar('inc_t1')}, 2;
        };
        subtest 'bulk' => sub {
            $kt->clear;
            is $kt->set_bulk({a => 1, b => 2, c => 3}), 3;
            is_deeply scalar($kt->get_bulk([qw/a b c d/])), {a => 1, b => 2, c => 3};
            is $kt->remove_bulk([qw/a b c d/]), 3;
        };
        done_testing;
    },
);

