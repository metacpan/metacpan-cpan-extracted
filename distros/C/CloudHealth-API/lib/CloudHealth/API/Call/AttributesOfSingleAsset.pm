package CloudHealth::API::Call::AttributesOfSingleAsset;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int Bool/;

  has asset => (is => 'ro', isa => Str, required => 1);

  sub _query_params { [ ] }
  sub _url_params { [ 
    { name => 'asset' }
  ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/api/:asset' }

1;
