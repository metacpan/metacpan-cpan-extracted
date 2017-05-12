use strict;use warnings;
use Data::Dumper;
use lib '../lib';
use lib 'lib';
use Consul::Simple::Test;
use Test::More qw(no_plan);

use_ok 'Consul::Simple', 'loaded Consul::Simple';
Consul::Simple::Test::init_tests();

eval {
    ok my $c = Consul::Simple->new(kv_prefix => 'CPANTest'), 'recurse-delete: instance created';
    ok $c->KVPut('foo/bar', 'one'), 'recurse-delete: first PUT succeeded';
    ok $c->KVPut('foo/fuz', { two => 2 }), 'recurse-delete: second PUT succeeded';
    ok $c->KVDelete('', recurse => 1), 'recurse-delete: recursive delete succeeded';
    eval {
        my @nothing_ret = $c->KVGet('', recurse => 1);
        ok not (scalar @nothing_ret), 'recurse-delete: operation correctly returned nothing';
    };
    ok((not $@), 'recurse-delete: inner: no exception thrown');
};
ok((not $@), 'recurse-delete: outer: no exception thrown');
