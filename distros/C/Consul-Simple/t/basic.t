use strict;use warnings;
use Data::Dumper;
use lib '../lib';
use lib 'lib';
use Consul::Simple::Test;
use Test::More qw(no_plan);

use_ok 'Consul::Simple', 'loaded Consul::Simple';
Consul::Simple::Test::init_tests();

eval {
    ok my $c = Consul::Simple->new(), 'basic instance';
    ok $c->{consul_server}, 'basic instance invocation: consul_server set';
    ok $c->{consul_server} eq 'localhost', 'basic instance invocation: consul_server set correctly';
};
ok ((not $@), 'basic instance: no exception thrown');

eval {
    ok my $c = Consul::Simple->new(consul_server => 'foo'), 'instance with consul_server listed';
    ok $c->{consul_server}, 'instance invocation: consul_server set';
    ok $c->{consul_server} eq 'foo', 'instance invocation: consul_server set correctly';
};
ok((not $@), 'instance invocation: no exception thrown');

eval {
    ok my $c = Consul::Simple->new(kv_prefix => 'CPANTest'), 'basic PUT: instance created';
    ok $c->KVPut('foo','bar'), 'basic PUT: PUT succeeded';
    eval {
        ok my @ret = $c->KVGet('foo'), 'basic PUT: GET succeeded';
        ok $ret[0]->{Value}, 'basic PUT: Value returned';
        ok $ret[0]->{Value} eq 'bar', 'basic PUT: returned Value is correct';
    };
    ok((not $@), 'basic PUT: inner: no exception thrown');
    ok my $ret = $c->KVDelete('foo'), 'basic PUT: DELETE succeeded';
};
ok((not $@), 'basic PUT: outer: no exception thrown');
