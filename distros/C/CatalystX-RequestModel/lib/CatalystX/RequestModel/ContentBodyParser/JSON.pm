package CatalystX::RequestModel::ContentBodyParser::JSON;

use warnings;
use strict;
use CatalystX::RequestModel::Utils::InvalidJSON;

use base 'CatalystX::RequestModel::ContentBodyParser';

sub content_type { 'application/json' }

sub default_attr_rules { 
  my ($self, $attr_rules) = @_;
  return +{ flatten=>0, %$attr_rules };
}

sub new {
  my ($class, %args) = @_;
  my $self = bless \%args, $class;
  $self->{context} ||= $self->_parse_json_body;
  return $self;
}

sub _parse_json_body {
  my ($self) = @_;
  my $json = eval {
    $self->{ctx}->req->body_data;
  } || do {
    CatalystX::RequestModel::Utils::InvalidJSON->throw(parsing_error=>$@);
  };

  return $json;
}

1;

=head1 NAME

CatalystX::RequestModel::ContentBodyParser::JSON

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Given a valid JSON request body, parse it and inflate request models as defined or throw various
exceptions otherwise.  for example given the following nested request models:

    package Example::Model::API::AccountRequest;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';
    namespace 'person';
    content_type 'application/json';

    has username => (is=>'ro', property=>1);  
    has first_name => (is=>'ro', property=>1);
    has last_name => (is=>'ro', property=>1);
    has profile => (is=>'ro', property=>+{model=>'API::AccountRequest::Profile' });
    has person_roles => (is=>'ro', property=>+{ indexed=>1, model=>'API::AccountRequest::PersonRole' });
    has credit_cards => (is=>'ro', property=>+{ indexed=>1, model=>'API::AccountRequest::CreditCard' });

    __PACKAGE__->meta->make_immutable();

    package Example::Model::API::AccountRequest::Profile;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';

    has id => (is=>'ro', property=>1);
    has address => (is=>'ro', property=>1);
    has city => (is=>'ro', property=>1);
    has state_id => (is=>'ro', property=>1);
    has zip => (is=>'ro', property=>1);
    has phone_number => (is=>'ro', property=>1);
    has birthday => (is=>'ro', property=>1);
    has registered => (is=>'ro', property=>+{ boolean=>1 });

    __PACKAGE__->meta->make_immutable();

    package Example::Model::API::AccountRequest::PersonRole;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';

    has role_id => (is=>'ro', property=>1);

    __PACKAGE__->meta->make_immutable();

    package Example::Model::API::AccountRequest::CreditCard;

    use Moose;
    use CatalystX::RequestModel;

    extends 'Catalyst::Model';

    has id => (is=>'ro', property=>1);
    has card_number => (is=>'ro', property=>1);
    has expiration => (is=>'ro', property=>1);

    __PACKAGE__->meta->make_immutable();

And the following POSTed JSON request body:

    {
      "person":{
        "username": "jjn",
        "first_name": "john",
        "last_name": "napiorkowski",
        "profile": {
          "id": 1,
          "address": "1351 Miliary Road",
          "city": "Little Falls",
          "state_id": 7,
          "zip": "42342",
          "phone_number": 6328641827,
          "birthday": "2222-01-01",
          "registered": false        
        },
        "person_roles": [
          { "role_id": 1 },
          { "role_id": 2 }
        ],
        "credit_cards": [
          { "id":100, "card_number": 111222333444, "expiration": "2222-02-02" },
          { "id":200, "card_number": 888888888888, "expiration": "3333-02-02" },
          { "id":300, "card_number": 333344445555, "expiration": "4444-02-02" }
        ]
      }
    }

Will inflate a request model that provides:

    my $request_model = $c->model('API::AccountRequest');
    Dumper $request_model->nested_params;

    +{
      'person_roles' => [
                          {
                            'role_id' => 1
                          },
                          {
                            'role_id' => 2
                          }
                        ],
      'profile' => {
                     'address' => '1351 Miliary Road',
                     'birthday' => '2222-01-01',
                     'id' => 1,
                     'state_id' => 7,
                     'phone_number' => 6328641827,
                     'registered' => 0,
                     'zip' => '42342',
                     'city' => 'Little Falls'
                   },
      'credit_cards' => [
                          {
                            'card_number' => '111222333444',
                            'expiration' => '2222-02-02',
                            'id' => 100
                          },
                          {
                            'id' => 200,
                            'card_number' => '888888888888',
                            'expiration' => '3333-02-02'
                          },
                          {
                            'id' => 300,
                            'card_number' => '333344445555',
                            'expiration' => '4444-02-02'
                          }
                        ],
      'first_name' => 'john',
      'username' => 'jjn',
      'last_name' => 'napiorkowski' 
    };    

=head1 VALUE PARSER CONFIGURATION

This parser defines the following attribute properties which effect how a value is parsed.

=head2 flatten

Defaults to false.  If enabled it will flatten an array value to a scalar which is the value of the
last item in the list. Probably not useful in JSON, it's more of a hack for HTML Form posts, which
makes it hard to be consistent in array versus scalar values, but no reason to not offer the feature
if you need it.

=head2 always_array

Similar to C<flatten> but opposite, it forces a value into an array even if there's just one value.  Also
defaults to FALSE.

=head1 EXCEPTIONS

See L<CatalystX::RequestModel::ContentBodyParser> for inherited exceptions.

=head2 Invalid JSON Content Body

If the JSON in the request content body is invalid, we throw a L<CatalystX::RequestModel::Utils::InvalidJSON>
exception.

=head1 AUTHOR

See L<CatalystX::RequestModel>.
 
=head1 COPYRIGHT
 
See L<CatalystX::RequestModel>.

=head1 LICENSE
 
See L<CatalystX::RequestModel>.
 
=cut
