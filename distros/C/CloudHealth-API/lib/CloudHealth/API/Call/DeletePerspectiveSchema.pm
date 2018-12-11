package CloudHealth::API::Call::DeletePerspectiveSchema;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Bool HashRef Int/;

  has perspective_id => (is => 'ro', isa => Int, required => 1);
  has hard_delete => (is => 'ro', isa => Bool);
  has force => (is => 'ro', isa => Bool);

  sub _query_params { [
    { name => 'hard_delete' }, 
    { name => 'force' }, 
  ] }
  sub _url_params { [
    { name => 'perspective_id', location => 'perspective-id' }
  ] }
  sub _method { 'DELETE' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/perspective_schemas/:perspective-id' }

1;
