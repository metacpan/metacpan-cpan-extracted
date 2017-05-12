package TestAppInheritedComponent::Model::LDAP::Connection;

use strict;
use warnings;
use base qw/Catalyst::Model::LDAP::Connection/;

sub blarg {
    shift->search(@_);
}

1;
