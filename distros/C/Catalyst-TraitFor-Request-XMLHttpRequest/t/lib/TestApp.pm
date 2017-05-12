package TestApp;
our $VERSION = '0.01';

use Moose;
use namespace::autoclean;

extends 'Catalyst';

use CatalystX::RoleApplicator;
__PACKAGE__->apply_request_class_roles(qw(
    Catalyst::TraitFor::Request::XMLHttpRequest
));

__PACKAGE__->setup;

1;
