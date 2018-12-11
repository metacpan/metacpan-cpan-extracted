package CloudHealth::API::Call::RetrievePerspectiveSchema;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int Bool/;

  has include_version => (is => 'ro', isa => Bool);
  has perspective_id => (is => 'ro', isa => Str, required => 1);

  sub _query_params { [ 
    { name => 'include_version' },
  ] }
  sub _url_params { [ 
    { name => 'perspective_id', location => 'perspective-id' }
  ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/perspective_schemas/:perspective-id' }

1;
