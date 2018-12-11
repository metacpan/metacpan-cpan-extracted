package CloudHealth::API::Call::RetrieveAllPerspectives;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int Bool/;

  has active_only => (is => 'ro', isa => Bool);

  sub _query_params { [ 
    { name => 'active_only' }
  ] }
  sub _url_params { [ ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/perspective_schemas' }

1;
