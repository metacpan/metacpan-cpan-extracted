package CloudHealth::API::Call::CreatePerspectiveSchema;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Bool HashRef/;

  has include_version => (is => 'ro', isa => Bool);
  has schema => (is => 'ro', isa => HashRef, required => 1);

  sub _body_params { [
    { name => 'schema' },
  ] }
  sub _query_params { [ 
    { name => 'include_version' },
  ] }
  sub _url_params { [ ] }
  sub _method { 'POST' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/perspective_schemas/' }

1;
