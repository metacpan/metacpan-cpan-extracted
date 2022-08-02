package Example::Model::API::AccountRequest;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';
namespace 'person';
content_type 'application/json';

has username => (is=>'ro', property=>1);  
has first_name => (is=>'ro', property=>1);
has last_name => (is=>'ro', property=>1);
has profile => (is=>'ro', property=>+{model=>'::Profile' });
has person_roles => (is=>'ro', property=>+{ indexed=>1, model=>'API::AccountRequest::PersonRole' });
has credit_cards => (is=>'ro', property=>+{ indexed=>1, model=>'::CreditCard' });

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
