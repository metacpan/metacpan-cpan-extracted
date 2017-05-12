package TestApp;

use Moose;
use CatalystX::RoleApplicator;
use namespace::autoclean;

extends 'Catalyst';

__PACKAGE__->setup(qw/
    Browser
/);

1;
