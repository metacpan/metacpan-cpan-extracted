package CloudHealth::API::Call::UpdateAWSAccountAssignment;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int/;

  has id => (is => 'ro', isa => Int, required => 1);
  has owner_id => (is => 'ro', isa => Str, required => 1);
  has customer_id => (is => 'ro', isa => Int, required => 1);
  has payer_account_owner_id => (is => 'ro', isa => Str, required => 1);

  sub _body_params { [
    { name => 'owner_id' },
    { name => 'customer_id' },
    { name => 'payer_account_owner_id' },
  ] }
  sub _query_params { [ ] }
  sub _url_params { [ 
    { name => 'id' },
  ] }
  sub _method { 'PUT' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/aws_account_assignments/:id' }

1;
