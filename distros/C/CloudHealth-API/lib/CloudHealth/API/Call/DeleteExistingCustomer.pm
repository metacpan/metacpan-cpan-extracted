package CloudHealth::API::Call::DeleteExistingCustomer;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Int/;

  has customer_id => (is => 'ro', isa => Int, required => 1);

  sub _query_params { [ ] }
  sub _url_params { [
    { name => 'customer_id' },
  ] }
  sub _method { 'DELETE' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/customers/:customer_id' }

1;
