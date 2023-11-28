use Test2::V0;

use JSON qw/ from_json /;
use Dancer2::Serializer::JsonApi;

my $serializer =
  Dancer2::Serializer::JsonApi->new( log_cb => sub { warn @_ } );

my $data = [ 'thing' => { id => 2 } ];

my $serialized = $serializer->serialize($data);

like from_json($serialized),
  { jsonapi => { version => '1.0' },
    data    => { id      => 2, type => 'thing' },
  };

todo 'not implemented yet' => sub {
    is $serializer->deserialize($serialized) => $data;
};

done_testing;
