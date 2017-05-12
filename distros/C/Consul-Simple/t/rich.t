use strict;use warnings;
use Data::Dumper;
use lib '../lib';
use lib 'lib';
use Consul::Simple::Test;
use Test::More qw(no_plan);

use_ok 'Consul::Simple', 'loaded Consul::Simple';
Consul::Simple::Test::init_tests();

eval {
    ok my $c = Consul::Simple->new(kv_prefix => 'CPANTest'), 'rich: instance created';
    ok $c->KVPut('foo',{ hi => 'there', this => [1,2,3] }), 'rich: PUT succeeded';
    eval {
        ok my @ret = $c->KVGet('foo'), 'rich: GET succeeded';
        ok my $value = $ret[0]->{Value}, 'rich: Value returned';
        ok ref $value eq 'HASH', 'rich: returned Value is correct type';
        ok $value->{hi} eq 'there', 'rich: returned Value first key is correct';
        ok $value->{this}[0] == 1, 'rich: returned Value second key first value is correct';
        ok $value->{this}[1] == 2, 'rich: returned Value second key second value is correct';
        ok $value->{this}[2] == 3, 'rich: returned Value second key third value is correct';
    };
    ok((not $@), 'rich: inner: no exception thrown');
    ok my $ret = $c->KVDelete('foo'), 'rich: DELETE succeeded';
};
ok((not $@), 'rich: outer: no exception thrown');
