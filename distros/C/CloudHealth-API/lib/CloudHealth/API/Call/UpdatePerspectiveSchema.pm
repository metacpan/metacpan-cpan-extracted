package CloudHealth::API::Call::UpdatePerspectiveSchema;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Bool HashRef Int/;

  has perspective_id => (is => 'ro', isa => Int, required => 1);
  has include_version => (is => 'ro', isa => Bool);
  has schema => (is => 'ro', isa => HashRef, required => 1);
  has allow_group_delete => (is => 'ro', isa => Bool);
  has check_version => (is => 'ro', isa => Int);

  sub _body_params { [
    { name => 'schema' },
  ] }
  sub _query_params { [ 
    { name => 'include_version' },
    { name => 'check_version' },
    { name => 'allow_group_delete' },
  ] }
  sub _url_params { [
    { name => 'perspective_id', location => 'perspective-id' }, 
  ] }
  sub _method { 'PUT' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/perspective_schemas/:perspective-id' }

1;
