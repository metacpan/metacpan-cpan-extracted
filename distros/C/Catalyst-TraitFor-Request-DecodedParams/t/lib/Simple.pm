package Simple;

use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;
use CatalystX::RoleApplicator;

extends 'Catalyst';

__PACKAGE__->config(name => 'Simple');

__PACKAGE__->apply_request_class_roles(qw/
    Catalyst::TraitFor::Request::DecodedParams::JSON
/);

__PACKAGE__->setup;

1;
