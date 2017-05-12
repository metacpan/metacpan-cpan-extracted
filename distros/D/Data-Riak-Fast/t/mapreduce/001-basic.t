#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Data::Riak::Fast;

use Data::Riak::Fast;
use Data::Riak::Fast::Bucket;

skip_unless_riak;

my $riak = Data::Riak::Fast->new(transport => Data::Riak::Fast::HTTP->new);

# Implement the example from the Riak docs.
# http://wiki.basho.com/MapReduce.html#MapReduce-via-the-HTTP-API

my $bucket_name = create_test_bucket_name;

my $bucket = Data::Riak::Fast::Bucket->new({
    name => $bucket_name,
    riak => $riak
});

my $text1 = "
Alice was beginning to get very tired of sitting by her sister on the
bank, and of having nothing to do: once or twice she had peeped into the
book her sister was reading, but it had no pictures or conversations in
it, 'and what is the use of a book,' thought Alice 'without pictures or
conversation?'
";

my $text2 = "
So she was considering in her own mind (as well as she could, for the
hot day made her feel very sleepy and stupid), whether the pleasure
of making a daisy-chain would be worth the trouble of getting up and
picking the daisies, when suddenly a White Rabbit with pink eyes ran
close by her.
";

my $text3 = "
The rabbit-hole went straight on like a tunnel for some way, and then
dipped suddenly down, so suddenly that Alice had not a moment to think
about stopping herself before she found herself falling down a very deep
well.
";

$bucket->add('p1', $text1);
$bucket->add('p2', $text2);
$bucket->add('p5', $text3);

# setup some data for the tests

my $MAP_REDUCE_RESULTS = {
    'dipped' => 1, 'on' => 2, 'alice' => 3, 'ran' => 1, 'day' => 1, 'own' => 1, 'deep' => 1,
    'trouble' => 1, 'what' => 1, 'conversations' => 1, 'bank' => 1, 'moment' => 1,
    'daisies' => 1, 'but' => 1, 'some' => 1, 'with' => 1, 'suddenly' => 3, 'and' => 5,
    'of' => 5, 'do' => 1, 'into' => 1, 'is' => 1, 'found' => 1, 'she' => 4, 'herself' => 2,
    'stupid' => 1, 'to' => 3, 'making' => 1, 'think' => 1, 'her' => 5, 'when' => 1,
    'it' => 2, 'sleepy' => 1, 'hole' => 1, 'tunnel' => 1, 'then' => 1, 'reading' => 1,
    'hot' => 1, 'thought' => 1, 'the' => 8, 'made' => 1, 'way' => 1, 'a' => 6, 'would' => 1,
    'no' => 1, 'twice' => 1, 'like' => 1, 'white' => 1, 'or' => 3, 'went' => 1, 'in' => 2,
    'could' => 1, 'sitting' => 1, 'down' => 2, 'about' => 1, 'before' => 1, 'so' => 2,
    'once' => 1, 'very' => 3, 'sister' => 2, 'for' => 2, 'by' => 2, 'chain' => 1, 'be' => 1,
    'daisy' => 1, 'feel' => 1, 'whether' => 1, 'eyes' => 1, 'mind' => 1, 'pink' => 1, 'up' => 1,
    'having' => 1, 'considering' => 1, 'conversation' => 1, 'close' => 1, 'pleasure' => 1,
    'use' => 1, 'straight' => 1, 'picking' => 1, 'tired' => 1, 'peeped' => 1, 'get' => 1,
    'had' => 3, 'beginning' => 1, 'without' => 1, 'getting' => 1, 'well' => 2, 'as' => 2,
    'was' => 3, 'rabbit' => 2, 'book' => 2, 'pictures' => 2, 'falling' => 1, 'nothing' => 1,
    'stopping' => 1, 'worth' => 1, 'not' => 1, 'that' => 1,
};

my $MAP_SOURCE = q[
    function(v) {
      var m = v.values[0].data.toLowerCase().match(/\w*/g);
      var r = [];
      for(var i in m) {
        if(m[i] != '') {
          var o = {};
          o[m[i]] = 1;
          r.push(o);
        }
      }
      return r;
    }
];

my $REDUCE_SOURCE = q[
function(v) {
  var r = {};
  for(var i in v) {
    for(var w in v[i]) {
      if(w in r) r[w] += v[i][w];
      else r[w] = v[i][w];
    }
  }
  return [r];
}
];

sub test_map_reduce {
    my $mr = shift;

    my $results = $mr->mapreduce;
    isa_ok($results, 'Data::Riak::Fast::ResultSet');

    my $result = $results->first;
    isa_ok($result, 'Data::Riak::Fast::Result');

    isa_ok($result->content_type, 'HTTP::Headers::ActionPack::MediaType');
    is($result->content_type->type, 'application/json', '... got the right content type');

    my $value = JSON::XS->new->decode( $result->value );
    is_deeply(
        $value,
        [ $MAP_REDUCE_RESULTS ],
        '... got the expected results'
    );
}

# test with buckets and keys specified
test_map_reduce(
    Data::Riak::Fast::MapReduce->new({
        riak => $riak,
        inputs => [ [ $bucket_name, "p1" ], [ $bucket_name, "p2" ], [ $bucket_name, "p5" ] ],
        phases => [
          Data::Riak::Fast::MapReduce::Phase::Map->new(
              language => 'javascript',
              source => $MAP_SOURCE
          ),
          Data::Riak::Fast::MapReduce::Phase::Reduce->new(
              language => 'javascript',
              source => $REDUCE_SOURCE
          )
        ]
    })
);

# test with just a bucket name
test_map_reduce(
    Data::Riak::Fast::MapReduce->new({
        riak => $riak,
        inputs => $bucket_name,
        phases => [
            Data::Riak::Fast::MapReduce::Phase::Map->new(
                language => 'javascript',
                source => $MAP_SOURCE
            ),
            Data::Riak::Fast::MapReduce::Phase::Reduce->new(
                language => 'javascript',
                source => $REDUCE_SOURCE
            )
        ]
    })
);

{
    my $mr = Data::Riak::Fast::MapReduce->new({
        riak => $riak,
        inputs => $bucket_name,
        phases => [
            Data::Riak::Fast::MapReduce::Phase::Map->new(
                language => 'javascript',
                source => $MAP_SOURCE
            ),
            Data::Riak::Fast::MapReduce::Phase::Reduce->new(
                language => 'javascript',
                source => $REDUCE_SOURCE
            )
        ]
    });

    my $results = $mr->mapreduce( chunked => 1 );
    isa_ok($results, 'Data::Riak::Fast::ResultSet');

    my $result = $results->first;
    isa_ok($result, 'Data::Riak::Fast::Result');

    isa_ok($result->content_type, 'HTTP::Headers::ActionPack::MediaType');
    is($result->content_type->type, 'application/json', '... got the right content type');

    my $value = JSON::XS->new->decode( $result->value );
    is_deeply(
        $value,
        {
            phase => 1,
            data => [ $MAP_REDUCE_RESULTS ],
        },
        '... got the expected results'
    );
}


remove_test_bucket($bucket);

done_testing;







