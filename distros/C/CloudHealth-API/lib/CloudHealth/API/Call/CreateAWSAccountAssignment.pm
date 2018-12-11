package CloudHealth::API::Call::CreateAWSAccountAssignment;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int/;

  has owner_id => (is => 'ro', isa => Str, required => 1);
  has customer_id => (is => 'ro', isa => Int, required => 1);
  has payer_account_owner_id => (is => 'ro', isa => Str, required => 1);

  sub _body_params {
    [
      { name => 'owner_id' },
      { name => 'customer_id' },
      { name => 'payer_account_owner_id' },
    ]
  }
  sub _query_params { [ ] }
  sub _url_params { [ ] }
  sub _method { 'POST' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/aws_account_assignments' }

1;
