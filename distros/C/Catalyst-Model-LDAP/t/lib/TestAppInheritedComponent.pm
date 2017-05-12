package TestAppInheritedComponent;

use strict;
use warnings;
use Catalyst;

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'TestAppInheritedComponent',
    'Model::LDAP' => {
        host             => 'ldap.ufl.edu',
        base             => 'ou=People,dc=ufl,dc=edu',
        connection_class => 'TestAppInheritedComponent::Model::LDAP::Connection',
        entry_class      => 'TestAppInheritedComponent::Model::LDAP::Entry',
    },
);

__PACKAGE__->setup;

1;
