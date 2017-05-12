package TestApp;
use Moose;
use namespace::autoclean;

extends 'Catalyst';

use Catalyst;
use CatalystX::RoleApplicator;

__PACKAGE__->apply_request_class_roles(qw/
    Catalyst::TraitFor::Request::ProxyBase
/);

__PACKAGE__->setup;

1;

