package CloudHealth::API::Call::CreatePartnerCustomer;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Int Str Dict Maybe ArrayRef/;

  has name => (is => 'ro', isa => Str, required => 1);
  has address => (is => 'ro', isa => Dict[street1 => Str, street2 => Str, city => Str, state => Str, zipcode => Int, country => Str], required => 1);
  has classification => (is => 'ro', isa => Str);
  has trial_expiration_date => (is => 'ro', isa => Str);
  has billing_contact => (is => 'ro', isa => Str);
  has partner_billing_configuration => (is => 'ro', isa => Dict[enabled => Str, folder => Maybe[Str]]);
  has tags => (is => 'ro', isa => ArrayRef[Dict[key => Str, value => Str]]);

  sub _body_params { [
    { name => 'name' },
    { name => 'address' },
    { name => 'classification' },
    { name => 'trial_expiration_date' },
    { name => 'billing_contact' },
    { name => 'partner_billing_configuration' },
    { name => 'tags' },
  ] }
  sub _query_params { [ ] }
  sub _url_params { [ ] }
  sub _method { 'POST' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/customers' }

1;
