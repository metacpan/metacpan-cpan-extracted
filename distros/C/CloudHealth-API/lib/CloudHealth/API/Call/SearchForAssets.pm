package CloudHealth::API::Call::SearchForAssets;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int Bool/;

  has name => (is => 'ro', isa => Str, required => 1);
  has query => (is => 'ro', isa => Str, required => 1);
  has include => (is => 'ro', isa => Str);
  has api_version => (is => 'ro', isa => Int, default => 2);
  has fields => (is => 'ro', isa => Str);
  has page => (is => 'ro', isa => Int);
  has per_page => (is => 'ro', isa => Int);
  has is_active => (is => 'ro', isa => Bool);

  sub _query_params { [
    { name => 'name' },
    { name => 'query' },
    { name => 'include' },  
    { name => 'api_version' },  
    { name => 'fields' },  
    { name => 'page' },  
    { name => 'per_page' },  
    { name => 'is_active' },  
  ] }
  sub _url_params { [ ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/api/search' }

1;
