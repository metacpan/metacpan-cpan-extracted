package CloudHealth::API::Call::AssetsForSpecificCustomer;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Int Str/;

  has client_api_id => (is => 'ro', isa => Int, required => 1);
  has api_version => (is => 'ro', isa => Int, default => 2);
  has name => (is => 'ro', isa => Str, required => 1);

  sub _query_params { [
    { name => 'client_api_id' },  
    { name => 'api_version' },  
    { name => 'name' },  
  ] }
  sub _url_params { [ ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/api/search.json' }

1;
