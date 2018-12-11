package CloudHealth::API::Call::StatementsForAllCustomers;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Int/;

  has page => (is => 'ro', isa => Int);
  has per_page => (is => 'ro', isa => Int);
 
  sub _query_params { [
    { name => 'page' },
    { name => 'per_page' },  
  ] }
  sub _url_params { [ ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/customer_statements' }

1;
