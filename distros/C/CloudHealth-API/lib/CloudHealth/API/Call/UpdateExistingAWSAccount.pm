package CloudHealth::API::Call::UpdateExistingAWSAccount;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int Bool Dict Optional ArrayRef/;

  has id => (is => 'ro', isa => Str, required => 1);

  has name => (is => 'ro', isa => Str);
  has authentication => (
    is => 'ro', required => 1,
    isa => Dict[
      protocol => Str,
      access_key => Optional[Str],
      secret_key => Optional[Str],
      assume_role_arn => Optional[Str],
      assume_role_external_id => Optional[Str],
    ]
  );
  has billing => (is => 'ro', isa => Dict[bucket => Str]);
  has cloudtrail => (
    is => 'ro',
    isa => Dict[
      enabled => Bool,
      bucket => Str,
      prefix => Optional[Str]
    ]
  );
  has aws_config => (
    is => 'ro',
    isa => Dict[
      enabled => Bool,
      bucket => Str,
      prefix => Optional[Str]
    ]
  );
  has cloudwatch => (
    is => 'ro',
    isa => Dict[enabled => Bool]
  );
  has tags => (
    is => 'ro',
    isa => ArrayRef[Dict[key => Str, value => Str]]
  );
  has hide_public_fields => (is => 'ro', isa => Bool);
  has region => (is => 'ro', isa => Str);

  sub _body_params { [
    { name => 'name' },
    { name => 'authentication' },
    { name => 'billing' },
    { name => 'cloudtrail' },
    { name => 'aws_config' },
    { name => 'cloudwatch' },
    { name => 'tags' },
    { name => 'hide_public_fields' },
    { name => 'region' },
  ] }
  sub _query_params { [ ] }
  sub _url_params { [
    { name => 'id' },
  ] }
  sub _method { 'PUT' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/aws_accounts/:id' }

1;
