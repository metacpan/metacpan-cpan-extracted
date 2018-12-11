package CloudHealth::API::Call::GetExternalID;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int Bool/;

  has id => (is => 'ro', isa => Str, required => 1);

  sub _query_params { [ ] }
  sub _url_params { [  
    { name => 'id' }
  ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/aws_accounts/:id/generate_external_id' }

1;
