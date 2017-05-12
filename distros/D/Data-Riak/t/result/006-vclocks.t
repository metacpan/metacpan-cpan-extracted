use strict;
use warnings;

use Test::More 0.89;
use Test::Fatal;
use Test::Data::Riak;

use Data::Riak;
use Data::Riak::Bucket;

skip_unless_riak;

my $riak = riak_transport;
my $bucket_name = create_test_bucket_name;

my $bucket = Data::Riak::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

my $bucket2 = Data::Riak::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

is(exception {
    $bucket->add('foo', 'bar')
}, undef, '... got no exception adding element to the bucket');

my $obj1 = $bucket->get('foo');
my $obj2 = $bucket->get('foo');

for my $obj ($obj1, $obj2) {
    isa_ok($obj, 'Data::Riak::Result');
    is($obj->value, 'bar', '... the value is bar');
}

is $obj1->vector_clock, $obj2->vector_clock, 'vector clocks match';

my $update1;
is exception { $update1 = $obj1->save_unless_modified(new_value => 'baz') },
    undef, 'first update succeeds';
isa_ok($update1, 'Data::Riak::Result');
is($update1->value, 'baz', '... the value is bar');

isnt $update1->vector_clock, $obj1->vector_clock,
    'new vector clock after update';

isa_ok exception { $obj2->save_unless_modified(new_value => 'moo') },
    Data::Riak::Exception::ConditionFailed::, 'second update fails';

is $bucket->get('foo')->value, 'baz', 'old value persisted';

done_testing;
