package CloudHealth::API::Call::GetAllCustomers;
  use Moo;
  use MooX::StrictConstructor;

  sub _query_params { [ ] }
  sub _url_params { [ ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/customers' }

1;
