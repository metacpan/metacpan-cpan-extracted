use strict;use warnings;
use Data::Dumper;
use lib '../lib';
use lib 'lib';
use Consul::Simple::Test;
use Test::More qw(no_plan);

use_ok 'Consul::Simple', 'loaded Consul::Simple';
Consul::Simple::Test::init_tests();

eval {
    ok my $c = Consul::Simple->new(kv_prefix => 'CPANTest'), 'recurse: instance created';
    ok $c->KVPut('foo/bar', 'one'), 'recurse: first PUT succeeded';
    ok $c->KVPut('foo/fuz', { two => 2 }), 'recurse: second PUT succeeded';
    eval {
        ok my @ret = $c->KVGet('foo/bar'), 'recurse: first GET succeeded';
        ok $ret[0]->{Value} eq 'one', 'recurse: first GET has correct value';
        ok @ret = $c->KVGet('foo/fuz'), 'recurse: second GET succeeded';
        ok $ret[0]->{Value}->{two} == 2, 'recurse: second GET has correct value';
        ok my @rets = $c->KVGet('foo', recurse => 1), 'recurse: recursive GET succeeded';
        ok scalar @rets == 2, 'recurse: as expected, two documents came back';
        ok $rets[0]->{Value} eq 'one', 'recurse: first document value is "one"';
        ok $rets[0]->{Key} eq 'CPANTest/foo/bar', 'recurse: first document key is "CPANTest/foo/bar"';
        ok $rets[1]->{Value}->{two} == 2, 'recurse: second document value is { two => 2}';
        ok $rets[1]->{Key} eq 'CPANTest/foo/fuz', 'recurse: second document key is "CPANTest/foo/fuz"';
    };
    ok((not $@), 'recurse: inner: no exception thrown');
    ok my $ret = $c->KVDelete('foo'), 'recurse: DELETE succeeded';
};
ok((not $@), 'recurse: outer: no exception thrown');
